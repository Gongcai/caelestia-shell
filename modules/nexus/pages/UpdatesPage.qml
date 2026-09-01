pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property string newsFeed: "https://www.archlinux.org/feeds/news/"
    readonly property int newsCacheMs: 60 * 60 * 1000

    // [{ title, link, pubDate, description }]
    property var newsItems: []
    property real newsSavedAt: 0
    property bool newsLoading: false
    property string newsError: ""

    // [{ name, oldVer, newVer }]
    property var packages: []
    property bool checkSupported: true
    property bool checking: false
    property real lastChecked: 0

    readonly property string summaryText: {
        if (root.checking)
            return qsTr("Checking for updates...");
        if (!root.checkSupported)
            return qsTr("Install pacman-contrib to see pending updates");
        if (root.packages.length === 0)
            return qsTr("System is up to date");
        return qsTr("%1 package updates available").arg(root.packages.length);
    }

    function refresh(): void {
        root.refreshPackages();
        root.fetchNews(true);
    }

    function refreshPackages(): void {
        if (root.checking)
            return;
        root.checking = true;
        root.lastChecked = Date.now();
        // The wrapper detects a missing checkupdates binary without relying on exit codes
        checkProc.exec(["sh", "-c", "if command -v checkupdates >/dev/null 2>&1; then checkupdates; else echo __NO_CHECKUPDATES__; fi"]);
    }

    function applyCheckupdates(text: string): void {
        root.checking = false;
        if (text.includes("__NO_CHECKUPDATES__")) {
            root.checkSupported = false;
            return;
        }

        const pkgs = [];
        for (const line of text.trim().split("\n")) {
            const parts = line.split(" ");
            // Format: "name oldVersion -> newVersion"
            if (parts.length >= 4 && parts[2] === "->")
                pkgs.push({ name: parts[0], oldVer: parts[1], newVer: parts[3] });
        }
        root.packages = pkgs;
    }

    function fetchNews(force: bool): void {
        if (root.newsLoading)
            return;
        if (!force && root.newsItems.length > 0 && Date.now() - root.newsSavedAt < root.newsCacheMs)
            return;

        root.newsLoading = true;
        root.newsError = "";

        const xhr = new XMLHttpRequest();
        xhr.open("GET", root.newsFeed);
        xhr.timeout = 15000;
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.newsLoading = false;
            if (xhr.status !== 200) {
                root.newsError = qsTr("Failed to load news (HTTP %1)").arg(xhr.status);
                return;
            }
            const items = root.parseRss(xhr.responseText);
            if (items.length === 0) {
                root.newsError = qsTr("Failed to parse the news feed");
                return;
            }
            root.newsItems = items;
            root.newsSavedAt = Date.now();
            newsCache.setText(JSON.stringify({ savedAt: root.newsSavedAt, items }));
        };
        xhr.send();
    }

    function parseRss(xml: string): var {
        const items = [];
        const itemRe = /<item>([\s\S]*?)<\/item>/g;
        let m;
        while ((m = itemRe.exec(xml)) !== null) {
            const block = m[1];
            const title = root.rssField(block, "title");
            const link = root.rssField(block, "link");
            if (!title || !link)
                continue;
            items.push({
                title,
                link,
                pubDate: root.rssField(block, "pubDate"),
                description: root.htmlSnippet(root.rssField(block, "description"))
            });
        }
        return items;
    }

    function rssField(block: string, tag: string): string {
        const m = new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`).exec(block);
        return m ? root.decodeEntities(m[1].trim()) : "";
    }

    function decodeEntities(s: string): string {
        return s.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#39;|&apos;/g, "'").replace(/&amp;/g, "&");
    }

    function htmlSnippet(html: string): string {
        const text = html.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
        return text.length > 160 ? `${text.slice(0, 160)}…` : text;
    }

    function formatDate(pubDate: string): string {
        const d = new Date(pubDate);
        return isNaN(d.getTime()) ? pubDate : Qt.formatDate(d, "yyyy-MM-dd");
    }

    function loadNewsCache(): void {
        // A fresh fetch may have landed before the cache finished loading
        if (root.newsItems.length > 0)
            return;
        try {
            const data = JSON.parse(newsCache.text());
            if (Array.isArray(data.items))
                root.newsItems = data.items;
            root.newsSavedAt = data.savedAt ?? 0;
        } catch (e) {
            // Corrupt cache, fetch fresh data instead
        }
    }

    title: qsTr("Updates")

    Component.onCompleted: {
        root.refreshPackages();
        // Don't rely solely on the FileView callbacks, they can miss the first load
        root.fetchNews(false);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Process {
            id: checkProc

            stdout: StdioCollector {
                onStreamFinished: root.applyCheckupdates(text)
            }
        }

        FileView {
            id: newsCache

            printErrors: false
            path: `${Paths.cache}/arch-news.json`
            onLoaded: {
                root.loadNewsCache();
                root.fetchNews(false);
            }
            onLoadFailed: err => {
                if (err === FileViewError.FileNotFound)
                    Qt.callLater(() => newsCache.setText("{}"));
                root.fetchNews(true);
            }
        }

        // Summary
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: summaryRow.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: summaryRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "system_update"
                    color: root.checkSupported && root.packages.length > 0 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.large
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.summaryText
                        font: Tokens.font.title.small
                        elide: Text.ElideRight
                        animate: true
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: root.lastChecked > 0
                        text: qsTr("Last checked: %1").arg(Qt.formatTime(new Date(root.lastChecked), "hh:mm"))
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        animate: true
                    }
                }

                IconTextButton {
                    icon: "refresh"
                    text: qsTr("Check")
                    type: IconTextButton.Tonal
                    disabled: root.checking
                    onClicked: root.refresh()
                }
            }
        }

        // Arch news
        SectionHeader {
            text: qsTr("Arch news")
        }

        ItemList {
            id: newsList

            Layout.fillWidth: true
            first: true
            last: true
            showList: root.newsItems.length > 0
            placeholderIcon: "rss_feed"
            placeholderText: root.newsLoading ? qsTr("Loading news...") : root.newsError !== "" ? root.newsError : qsTr("No news")

            model: ScriptModel {
                values: root.newsItems
            }

            delegate: StateLayer {
                id: newsItem

                required property int index
                required property var modelData

                readonly property bool manual: modelData.title.toLowerCase().includes("manual intervention")

                anchors.left: newsList.list.contentItem.left
                anchors.right: newsList.list.contentItem.right
                implicitHeight: newsRow.implicitHeight + newsRow.anchors.margins * 2
                radius: Tokens.rounding.extraSmall
                bottomLeftRadius: newsList.last && index === newsList.list.count - 1 ? Tokens.rounding.extraLarge : radius
                bottomRightRadius: newsList.last && index === newsList.list.count - 1 ? Tokens.rounding.extraLarge : radius
                anchors.fill: undefined

                onClicked: Qt.openUrlExternally(newsItem.modelData.link)

                RowLayout {
                    id: newsRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    anchors.leftMargin: Tokens.padding.extraLarge
                    anchors.rightMargin: Tokens.padding.extraLarge
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: newsItem.manual ? "warning" : "article"
                        color: newsItem.manual ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: newsItem.modelData.title
                            font: Tokens.font.body.small
                            color: newsItem.manual ? Colours.palette.m3error : Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.formatDate(newsItem.modelData.pubDate)
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: newsItem.modelData.description
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    MaterialIcon {
                        text: "open_in_new"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.small
                    }
                }
            }
        }

        // Pending updates
        SectionHeader {
            text: qsTr("Pending updates (%1)").arg(root.packages.length)
        }

        ItemList {
            id: pkgList

            Layout.fillWidth: true
            first: true
            last: true
            showList: root.packages.length > 0
            placeholderIcon: root.checkSupported ? "task_alt" : "download"
            placeholderText: root.checking ? qsTr("Checking...") : root.checkSupported ? qsTr("System is up to date") : qsTr("Install pacman-contrib to see pending updates")

            model: ScriptModel {
                values: root.packages
            }

            delegate: StateLayer {
                id: pkg

                required property int index
                required property var modelData

                anchors.left: pkgList.list.contentItem.left
                anchors.right: pkgList.list.contentItem.right
                implicitHeight: pkgRow.implicitHeight + pkgRow.anchors.margins * 2
                radius: Tokens.rounding.extraSmall
                bottomLeftRadius: pkgList.last && index === pkgList.list.count - 1 ? Tokens.rounding.extraLarge : radius
                bottomRightRadius: pkgList.last && index === pkgList.list.count - 1 ? Tokens.rounding.extraLarge : radius
                anchors.fill: undefined

                RowLayout {
                    id: pkgRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.extraLarge
                    anchors.rightMargin: Tokens.padding.extraLarge
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.fillWidth: true
                        text: pkg.modelData.name
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: `${pkg.modelData.oldVer} → ${pkg.modelData.newVer}`
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }
}
