pragma ComponentBehavior: Bound

import "media"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property Item dashboard

    readonly property bool shouldBeActive: Config.dashboard.enabled && screenState.dashboardLyrics
    readonly property bool expanded: screenState.dashboardLyricsExpanded
    property real sampledPosition
    property int currentLyricIndex: -1
    readonly property string currentLyric: {
        const lines = Lyrics.lyrics;
        if (!lines.length)
            return "";

        // Timed lyrics often contain empty separator rows. In compact mode,
        // keep showing the most recent real line instead of rendering dots.
        for (let i = Math.min(currentLyricIndex, lines.length - 1); i >= 0; --i) {
            const line = lines[i]?.trim() ?? "";
            if (line)
                return line;
        }
        for (const line of lines) {
            if (line?.trim())
                return line.trim();
        }
        return "";
    }
    readonly property var _: {
        const player = Players.active;
        if (player)
            Lyrics.setTrack(player.trackArtist, player.trackTitle, player.trackAlbum, player.length);
        else
            Lyrics.clearTrack();
    }

    property real offsetScale: shouldBeActive ? 0 : 1

    function updateCurrentLyric(): void {
        sampledPosition = Players.active?.position ?? 0;
        currentLyricIndex = Lyrics.hasLyrics ? Lyrics.indexForTime(sampledPosition) : -1;
    }

    implicitHeight: expanded ? Math.min(Math.max(420, dashboard.nonAnimHeight), screen.height - Tokens.padding.large * 2) : 40
    visible: offsetScale < 1
    opacity: 1 - offsetScale

    anchors.left: parent.left
    anchors.right: dashboard.left
    anchors.top: parent.top
    anchors.topMargin: (-implicitHeight - 5) * offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }

    Timer {
        running: root.visible && (Players.active?.isPlaying ?? false)
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: root.updateCurrentLyric()
    }

    Connections {
        target: Players
        function onActiveChanged(): void {
            root.updateCurrentLyric();
        }
    }

    Connections {
        target: Players.active
        function onPositionChanged(): void {
            root.updateCurrentLyric();
        }
    }

    Connections {
        target: Lyrics
        function onLyricsChanged(): void {
            root.updateCurrentLyric();
        }
    }

    Loader {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        active: root.expanded && root.visible
        visible: active

        sourceComponent: ClippingRectangle {
            radius: Tokens.rounding.medium
            color: "transparent"

            LyricList {
                anchors.fill: parent
            }
        }
    }

    Item {
        id: compactLyrics

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        visible: !root.expanded

        readonly property real overflow: Math.max(0, lyricText.implicitWidth - width)
        readonly property bool shouldScroll: overflow > 1
        readonly property bool hovered: hoverHandler.hovered
        property real scrollOffset

        clip: true

        function resetScroll(): void {
            marquee.stop();
            scrollOffset = 0;
            if (shouldScroll && visible && !hovered)
                marquee.start();
        }

        onShouldScrollChanged: Qt.callLater(resetScroll)
        onVisibleChanged: Qt.callLater(resetScroll)
        onHoveredChanged: Qt.callLater(resetScroll)

        HoverHandler {
            id: hoverHandler
        }

        StyledText {
            id: lyricText

            x: compactLyrics.shouldScroll ? compactLyrics.scrollOffset : (compactLyrics.width - implicitWidth) / 2
            height: parent.height
            text: {
                if (!Players.active)
                    return qsTr("Nothing playing");
                if (Lyrics.loading)
                    return qsTr("Loading lyrics...");
                if (!Lyrics.hasLyrics)
                    return qsTr("No lyrics found");
                return root.currentLyric || qsTr("Instrumental");
            }
            color: Lyrics.hasLyrics ? Colours.palette.m3primary : Colours.palette.m3outline
            font: Tokens.font.title.medium
            verticalAlignment: Text.AlignVCenter
            opacity: compactLyrics.hovered ? 0 : 1

            onTextChanged: Qt.callLater(compactLyrics.resetScroll)

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small
            opacity: compactLyrics.hovered ? 1 : 0
            enabled: compactLyrics.hovered

            IconButton {
                type: IconButton.Text
                isRound: true
                icon: "skip_previous"
                font: Tokens.font.icon.small
                disabled: !Players.active?.canGoPrevious
                onClicked: Players.active?.previous()
            }

            IconButton {
                type: IconButton.Tonal
                isRound: true
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                font: Tokens.font.icon.small
                disabled: !Players.active?.canTogglePlaying
                onClicked: Players.active?.togglePlaying()
            }

            IconButton {
                type: IconButton.Text
                isRound: true
                icon: "skip_next"
                font: Tokens.font.icon.small
                disabled: !Players.active?.canGoNext
                onClicked: Players.active?.next()
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        SequentialAnimation {
            id: marquee

            loops: Animation.Infinite

            PauseAnimation {
                duration: 1200
            }
            NumberAnimation {
                target: compactLyrics
                property: "scrollOffset"
                from: 0
                to: -compactLyrics.overflow
                duration: Math.max(1000, compactLyrics.overflow * 25)
                easing.type: Easing.Linear
            }
            PauseAnimation {
                duration: 1200
            }
            NumberAnimation {
                target: compactLyrics
                property: "scrollOffset"
                from: -compactLyrics.overflow
                to: 0
                duration: Math.max(1000, compactLyrics.overflow * 25)
                easing.type: Easing.Linear
            }
        }
    }
}
