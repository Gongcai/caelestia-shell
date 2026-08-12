pragma ComponentBehavior: Bound

import "media"
import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.Services
import qs.components
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

    StyledText {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        visible: !root.expanded
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
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        animate: true
    }
}
