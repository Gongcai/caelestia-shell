pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState

    readonly property string username: GlobalConfig.dashboard.githubUsername
    readonly property string token: GlobalConfig.dashboard.githubToken
    readonly property bool signedIn: token !== ""

    property var profile: null
    property var repos: []
    property var contributions: [] // [{ date: "YYYY-MM-DD", level: 0-4, count: N }]
    property int totalContributions: -1
    property bool loading: false
    property string errorMessage: ""

    // Device flow login state
    property string userCode: ""
    property string deviceCode: ""
    property string verificationUri: ""
    property int pollIntervalMs: 5000
    property real loginExpiresAt: 0
    property bool loginInFlight: false

    // GitHub's classic green scale; level 0 stays a theme surface to blend with the card
    readonly property var levelColours: [
        Colours.tPalette.m3surfaceContainerHighest,
        "#9be9a8",
        "#40c463",
        "#30a14e",
        "#216e39"
    ]

    readonly property string cacheOwner: signedIn ? "@token" : username

    function saveCache(): void {
        if (!profile && repos.length === 0 && contributions.length === 0)
            return;
        cacheStorage.setText(JSON.stringify({
            owner: cacheOwner,
            profile: profile,
            repos: repos,
            contributions: contributions,
            totalContributions: totalContributions,
            savedAt: Date.now()
        }));
    }

    function loadCache(): void {
        try {
            const data = JSON.parse(cacheStorage.text());
            if (!data || data.owner !== cacheOwner)
                return;
            profile = data.profile ?? null;
            repos = data.repos ?? [];
            contributions = data.contributions ?? [];
            totalContributions = data.totalContributions ?? -1;
        } catch (e) {
            // Corrupt or missing cache, fetch fresh data instead
        }
    }

    readonly property int activeDays: {
        let count = 0;
        for (const day of contributions)
            if (day.count > 0)
                count++;
        return count;
    }

    function postForm(url, data, onDone): void {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", url);
        xhr.timeout = 15000;
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        xhr.setRequestHeader("Accept", "application/json");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE)
                onDone(xhr.status, xhr.responseText);
        };
        const body = Object.entries(data).map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`).join("&");
        xhr.send(body);
    }

    function post(url, data, onDone): void {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", url);
        xhr.timeout = 15000;
        if (signedIn)
            xhr.setRequestHeader("Authorization", `Bearer ${token}`);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("Accept", "application/json");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE)
                onDone(xhr.status, xhr.responseText);
        };
        xhr.send(JSON.stringify(data));
    }

    function fetch(url, onDone): void {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.timeout = 15000;
        if (signedIn)
            xhr.setRequestHeader("Authorization", `Bearer ${token}`);
        xhr.setRequestHeader("Accept", "application/vnd.github+json");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE)
                onDone(xhr.status, xhr.responseText);
        };
        xhr.send();
    }

    function levelForCount(count): int {
        if (count <= 0)
            return 0;
        if (count <= 3)
            return 1;
        if (count <= 6)
            return 2;
        if (count <= 10)
            return 3;
        return 4;
    }

    function refresh(): void {
        if (loading)
            return;

        if (signedIn) {
            refreshGraphql();
            return;
        }

        if (!username)
            return;

        loading = true;
        errorMessage = "";

        fetch(`https://api.github.com/users/${encodeURIComponent(username)}`, (status, body) => {
            if (status === 200) {
                try {
                    root.profile = JSON.parse(body);
                } catch (e) {
                    root.errorMessage = qsTr("Failed to parse profile data");
                }
            } else if (status === 404) {
                root.errorMessage = qsTr("User not found");
            } else if (status === 403) {
                root.errorMessage = qsTr("GitHub API rate limit reached, try again later");
            } else {
                root.errorMessage = qsTr("Failed to load profile (HTTP %1)").arg(status);
            }
            root.loading = false;
            root.saveCache();
        });

        fetch(`https://api.github.com/users/${encodeURIComponent(username)}/repos?sort=updated&per_page=6`, (status, body) => {
            if (status === 200) {
                try {
                    root.repos = JSON.parse(body).filter(repo => !repo.fork);
                    root.saveCache();
                } catch (e) {
                    // Keep previous repos
                }
            }
        });

        fetch(`https://github.com/users/${encodeURIComponent(username)}/contributions`, (status, body) => {
            if (status === 200) {
                const days = [];
                const pattern = /data-date="(\d{4}-\d{2}-\d{2})"[^>]*data-level="(\d)"/g;
                let match;
                while ((match = pattern.exec(body)) !== null)
                    days.push({ date: match[1], level: parseInt(match[2]), count: -1 });
                root.contributions = days;
                root.saveCache();
            }
        });
    }

    function refreshGraphql(): void {
        const query = `query {
            viewer {
                login
                name
                avatarUrl
                followers { totalCount }
                repositories(first: 6, orderBy: { field: UPDATED_AT, direction: DESC }, ownerAffiliations: OWNER, isFork: false) {
                    nodes {
                        name
                        description
                        stargazerCount
                        forkCount
                        url
                        primaryLanguage { name }
                    }
                }
                contributionsCollection {
                    contributionCalendar {
                        totalContributions
                        weeks {
                            contributionDays {
                                date
                                contributionCount
                            }
                        }
                    }
                }
            }
        }`;

        loading = true;
        errorMessage = "";

        post("https://api.github.com/graphql", { query }, (status, body) => {
            root.loading = false;
            if (status !== 200) {
                console.warn("[GithubTab] GraphQL request failed:", status, body);
                if (status === 401) {
                    root.errorMessage = qsTr("GitHub session expired, please sign in again");
                    GlobalConfig.dashboard.githubToken = "";
                } else {
                    let detail = "";
                    try {
                        detail = JSON.parse(body).message ?? "";
                    } catch (e) {
                    }
                    root.errorMessage = detail !== "" ? qsTr("Failed to load profile (HTTP %1): %2").arg(status).arg(detail) : qsTr("Failed to load profile (HTTP %1)").arg(status);
                }
                return;
            }

            try {
                const data = JSON.parse(body);
                if (data.errors) {
                    root.errorMessage = qsTr("GitHub API error");
                    return;
                }
                const viewer = data.data.viewer;
                root.profile = {
                    login: viewer.login,
                    name: viewer.name,
                    avatar_url: viewer.avatarUrl,
                    followers: viewer.followers.totalCount,
                    public_repos: -1
                };
                GlobalConfig.dashboard.githubUsername = viewer.login;

                root.repos = viewer.repositories.nodes.map(node => ({
                    name: node.name,
                    description: node.description,
                    html_url: node.url,
                    stargazers_count: node.stargazerCount,
                    forks_count: node.forkCount,
                    language: node.primaryLanguage?.name ?? ""
                }));

                const calendar = viewer.contributionsCollection.contributionCalendar;
                root.totalContributions = calendar.totalContributions;
                const days = [];
                for (const week of calendar.weeks) {
                    for (const day of week.contributionDays)
                        days.push({ date: day.date, count: day.contributionCount, level: root.levelForCount(day.contributionCount) });
                }
                root.contributions = days;
                root.saveCache();
            } catch (e) {
                root.errorMessage = qsTr("Failed to parse profile data");
            }
        });
    }

    function oauthErrorText(status, body): string {
        let detail = "";
        try {
            const data = JSON.parse(body);
            if (data.error_description)
                detail = data.error_description;
            else if (data.error)
                detail = data.error;
        } catch (e) {
            detail = body.slice(0, 120);
        }
        if (detail === "device_flow_disabled")
            return qsTr("Device flow is disabled for this app, enable it in the app's settings on GitHub");
        return detail !== "" ? qsTr("Failed to start sign-in (HTTP %1): %2").arg(status).arg(detail) : qsTr("Failed to start sign-in (HTTP %1)").arg(status);
    }

    function signIn(): void {
        const clientId = GlobalConfig.dashboard.githubClientId;
        if (clientId === "") {
            errorMessage = qsTr("Set your GitHub OAuth client ID in Dashboard settings first");
            return;
        }
        if (loginInFlight)
            return;

        loginInFlight = true;
        errorMessage = "";

        postForm("https://github.com/login/device/code", {
            client_id: clientId,
            scope: "read:user"
        }, (status, body) => {
            if (status !== 200) {
                root.loginInFlight = false;
                console.warn("[GithubTab] device code request failed:", status, body);
                root.errorMessage = root.oauthErrorText(status, body);
                return;
            }

            try {
                const data = JSON.parse(body);
                root.userCode = data.user_code;
                root.deviceCode = data.device_code;
                root.verificationUri = data.verification_uri;
                root.pollIntervalMs = (data.interval ?? 5) * 1000;
                root.loginExpiresAt = Date.now() + (data.expires_in ?? 900) * 1000;
                Qt.openUrlExternally(root.verificationUri);
                pollTimer.restart();
            } catch (e) {
                root.loginInFlight = false;
                root.errorMessage = qsTr("Failed to start sign-in");
            }
        });
    }

    function cancelSignIn(): void {
        pollTimer.stop();
        loginInFlight = false;
        userCode = "";
        deviceCode = "";
        verificationUri = "";
    }

    function pollForToken(): void {
        if (!loginInFlight || deviceCode === "")
            return;

        if (Date.now() > loginExpiresAt) {
            cancelSignIn();
            errorMessage = qsTr("Sign-in timed out, please try again");
            return;
        }

        postForm("https://github.com/login/oauth/access_token", {
            client_id: GlobalConfig.dashboard.githubClientId,
            device_code: deviceCode,
            grant_type: "urn:ietf:params:oauth:grant-type:device_code"
        }, (status, body) => {
            if (status !== 200)
                return;

            try {
                const data = JSON.parse(body);
                if (data.access_token) {
                    root.cancelSignIn();
                    GlobalConfig.dashboard.githubToken = data.access_token;
                } else if (data.error === "authorization_pending") {
                    // Keep polling
                } else if (data.error === "slow_down") {
                    root.pollIntervalMs += 5000;
                    pollTimer.interval = root.pollIntervalMs;
                } else if (data.error === "expired_token") {
                    root.cancelSignIn();
                    root.errorMessage = qsTr("Sign-in code expired, please try again");
                } else {
                    root.cancelSignIn();
                    root.errorMessage = qsTr("Sign-in failed");
                }
            } catch (e) {
                // Ignore malformed poll responses
            }
        });
    }

    function signOut(): void {
        GlobalConfig.dashboard.githubToken = "";
        GlobalConfig.dashboard.githubUsername = "";
        profile = null;
        repos = [];
        contributions = [];
        totalContributions = -1;
        errorMessage = "";
    }

    Component.onCompleted: refresh()

    onLoginInFlightChanged: screenState.dashboardGithubLogin = loginInFlight

    Component.onDestruction: screenState.dashboardGithubLogin = false

    Connections {
        target: GlobalConfig.dashboard

        function onGithubUsernameChanged(): void {
            if (root.signedIn)
                return;
            root.profile = null;
            root.repos = [];
            root.contributions = [];
            root.totalContributions = -1;
            root.refresh();
        }

        function onGithubTokenChanged(): void {
            if (root.signedIn)
                root.refresh();
        }
    }

    Timer {
        id: pollTimer

        interval: root.pollIntervalMs
        repeat: true
        onTriggered: root.pollForToken()
    }

    Timer {
        interval: 30 * 60 * 1000
        running: root.visible && (root.signedIn || root.username !== "")
        repeat: true
        triggeredOnStart: false
        onTriggered: root.refresh()
    }

    FileView {
        id: cacheStorage

        printErrors: false
        path: `${Paths.cache}/github.json`
        onLoaded: {
            // Apply the local cache only if no network response has landed yet
            if (!root.profile && root.repos.length === 0 && root.contributions.length === 0)
                root.loadCache();
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => cacheStorage.setText("{}"));
        }
    }

    implicitWidth: 840
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        // Header: avatar, name, stats
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            spacing: Tokens.spacing.medium

            StyledClippingRect {
                implicitWidth: 64
                implicitHeight: 64
                radius: 32
                color: Colours.tPalette.m3surfaceContainerHigh

                Image {
                    anchors.fill: parent
                    visible: root.profile
                    source: root.profile ? root.profile.avatar_url : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !root.profile
                    text: "person"
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.5).build()
                    color: Colours.palette.m3outline
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: root.profile?.name || (root.username !== "" ? root.username : qsTr("GitHub"))
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    visible: root.signedIn || root.username !== ""
                    text: root.loading && !root.profile ? qsTr("Loading...")
                        : root.errorMessage
                        || (root.profile
                            ? (root.profile.public_repos >= 0
                                ? qsTr("%1 repositories · %2 followers").arg(root.profile.public_repos).arg(root.profile.followers)
                                : qsTr("%1 followers").arg(root.profile.followers))
                            : qsTr("No data yet"))
                    font: Tokens.font.body.small
                    color: root.errorMessage !== "" ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    visible: !root.signedIn && root.username === ""
                    text: qsTr("Not signed in")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            StyledText {
                visible: root.totalContributions >= 0
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("%1 contributions in the last year").arg(root.totalContributions)
                font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                color: Colours.palette.m3secondary
                elide: Text.ElideRight
            }

            StyledText {
                visible: root.signedIn && root.totalContributions < 0 && root.activeDays > 0
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("%1 active days").arg(root.activeDays)
                font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                color: Colours.palette.m3secondary
            }

            IconButton {
                visible: root.signedIn || root.username !== ""
                type: IconButton.Tonal
                icon: "refresh"
                isRound: true
                onClicked: root.refresh()
            }

            IconButton {
                visible: root.signedIn
                type: IconButton.Tonal
                icon: "logout"
                isRound: true
                onClicked: root.signOut()
            }
        }

        // Device flow sign-in card
        StyledRect {
            Layout.fillWidth: true
            visible: root.loginInFlight
            implicitHeight: loginColumn.implicitHeight + Tokens.padding.extraLarge * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: loginColumn

                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Sign in to GitHub")
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Enter this code on %1").arg(root.verificationUri || "https://github.com/login/device")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.userCode
                    font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                    color: Colours.palette.m3primary
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    IconTextButton {
                        icon: "open_in_new"
                        text: qsTr("Open verification page")
                        type: IconTextButton.Tonal
                        onClicked: Qt.openUrlExternally(root.verificationUri)
                    }

                    IconTextButton {
                        icon: "close"
                        text: qsTr("Cancel")
                        type: IconTextButton.Tonal
                        onClicked: root.cancelSignIn()
                    }
                }
            }
        }

        // Setup card when not signed in and no username configured
        StyledRect {
            Layout.fillWidth: true
            visible: !root.signedIn && root.username === "" && !root.loginInFlight
            implicitHeight: setupColumn.implicitHeight + Tokens.padding.extraLarge * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: setupColumn

                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "code_blocks"
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.5).build()
                    color: Colours.palette.m3secondary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No GitHub account connected")
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Sign in to see your contributions, or set a username in Dashboard settings to view public data")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.errorMessage !== ""
                    text: root.errorMessage
                    font: Tokens.font.body.small
                    color: Colours.palette.m3error
                }

                IconTextButton {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "login"
                    text: qsTr("Sign in with GitHub")
                    type: IconTextButton.Filled
                    onClicked: root.signIn()
                }
            }
        }

        // Contribution graph
        StyledRect {
            Layout.fillWidth: true
            visible: root.contributions.length > 0
            implicitHeight: graphColumn.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: graphColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: qsTr("Contributions")
                        font: Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Row {
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Less")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        Repeater {
                            model: 5

                            delegate: Rectangle {
                                id: legendCell

                                required property int index

                                readonly property var levelColours: root.levelColours

                                implicitWidth: 11
                                implicitHeight: 11
                                radius: 3
                                color: levelColours[index]
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("More")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                // Week columns of day cells
                Row {
                    id: graphRow

                    readonly property var weeks: {
                        const weeks = [];
                        for (let i = 0; i + 6 < root.contributions.length; i += 7)
                            weeks.push(root.contributions.slice(i, i + 7));
                        return weeks;
                    }

                    spacing: 3

                    Repeater {
                        model: graphRow.weeks

                        delegate: Column {
                            id: weekColumn

                            required property var modelData

                            spacing: 3

                            Repeater {
                                model: weekColumn.modelData

                                delegate: Rectangle {
                                    id: dayCell

                                    required property var modelData

                                    readonly property var levelColours: root.levelColours

                                    implicitWidth: 11
                                    implicitHeight: 11
                                    radius: 3
                                    color: levelColours[modelData.level ?? 0]

                                    TapHandler {
                                        onTapped: Toaster.toast(dayCell.modelData.date, dayCell.modelData.count >= 0 ? qsTr("%1 contributions").arg(dayCell.modelData.count) : "", "calendar_today")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Repositories
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Tokens.spacing.medium
            rowSpacing: Tokens.spacing.medium

            Repeater {
                model: root.repos

                delegate: StyledRect {
                    id: repoCard

                    required property var modelData

                    readonly property var languageColours: ({
                        "C++": "#f34b7d",
                        "QML": "#41b783",
                        "JavaScript": "#f1e05a",
                        "TypeScript": "#3178c6",
                        "Python": "#3572A5",
                        "Rust": "#dea584",
                        "Go": "#00ADD8",
                        "C": "#555555",
                        "Shell": "#89e051",
                        "HTML": "#e34c26",
                        "CSS": "#563d7c",
                        "Java": "#b07219",
                        "Nix": "#7e7eff"
                    })

                    Layout.fillWidth: true
                    Layout.preferredHeight: width
                    implicitHeight: 260
                    radius: Tokens.rounding.extraLarge
                    color: Colours.tPalette.m3surfaceContainer

                    Item {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large

                        RowLayout {
                            id: titleRow

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "book_2"
                                fontStyle: Tokens.font.icon.builders.large.build()
                                color: Colours.palette.m3secondary
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: repoCard.modelData.name
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }
                        }

                        StyledText {
                            anchors.top: titleRow.bottom
                            anchors.topMargin: Tokens.spacing.small
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: footerRow.top
                            anchors.bottomMargin: Tokens.spacing.extraSmall
                            visible: repoCard.modelData.description
                            text: repoCard.modelData.description ?? ""
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignTop
                        }

                        RowLayout {
                            id: footerRow

                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: Tokens.spacing.extraSmall

                            Rectangle {
                                visible: repoCard.modelData.language
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 10
                                implicitHeight: 10
                                radius: 5
                                color: repoCard.languageColours[repoCard.modelData.language] ?? Colours.palette.m3outline
                            }

                            StyledText {
                                visible: repoCard.modelData.language
                                text: repoCard.modelData.language ?? ""
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                                Layout.maximumWidth: parent.width / 2
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            MaterialIcon {
                                Layout.alignment: Qt.AlignVCenter
                                text: "star"
                                fontStyle: Tokens.font.icon.builders.small.build()
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                text: repoCard.modelData.stargazers_count
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            MaterialIcon {
                                Layout.alignment: Qt.AlignVCenter
                                text: "call_split"
                                fontStyle: Tokens.font.icon.builders.small.build()
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                text: repoCard.modelData.forks_count
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }

                    TapHandler {
                        onTapped: Qt.openUrlExternally(repoCard.modelData.html_url)
                    }
                }
            }
        }
    }
}
