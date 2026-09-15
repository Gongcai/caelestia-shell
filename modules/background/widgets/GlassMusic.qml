pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.images
import qs.services

Item {
    id: root

    required property DesktopBackdrop desktopBackdrop
    required property Item motionItem
    required property real absX
    required property real absY
    property var player: Players.active
    property bool lyricsVisible
    readonly property real widgetScale: Math.max(0.5, Math.min(2, Config.background.desktopMusic.scale))
    readonly property bool compact: Config.background.desktopMusic.layout === "compact"
    readonly property bool tall: Config.background.desktopMusic.layout === "tall"
    readonly property real padding: (compact ? 16 : 24) * widgetScale
    readonly property real duration: Number.isFinite(player?.length) && player.length > 0 && player.length < 2147483647 ? player.length : 0
    readonly property string artUrl: player?.trackArtUrl || (player === Players.active ? Players.getArtUrl(Players.active) : "")

    function timeText(seconds: real): string {
        if (!Number.isFinite(seconds) || seconds < 0)
            return "--:--";
        const minutes = Math.floor(seconds / 60);
        return minutes + ":" + String(Math.floor(seconds % 60)).padStart(2, "0");
    }

    function seek(seconds: real): void {
        if (player?.canSeek && player?.positionSupported && duration > 0)
            player.position = Math.max(0, Math.min(duration, seconds));
    }

    function syncLyrics(): void {
        if (!lyricsVisible)
            return;
        if (player)
            Lyrics.setTrack(player.trackArtist, player.trackTitle, player.trackAlbum, duration);
        else
            Lyrics.clearTrack();
    }

    function nextPlayer(): void {
        const players = Players.list;
        if (players.length > 1)
            Players.manualActive = players[(players.indexOf(Players.active) + 1) % players.length];
    }

    implicitWidth: (tall ? 280 : 560) * widgetScale
    implicitHeight: (compact ? 120 : tall ? 480 : 280) * widgetScale
    onLyricsVisibleChanged: syncLyrics()
    onPlayerChanged: syncLyrics()
    onCompactChanged: {
        if (compact)
            lyricsVisible = false;
    }

    DesktopWidgetSurface {
        id: surface

        anchors.fill: parent
        desktopBackdrop: root.desktopBackdrop
        transformItem: root.motionItem
        sampleX: root.absX
        sampleY: root.absY
        radius: (root.compact ? 28 : 44) * root.widgetScale
    }

    Flipable {
        id: pages

        anchors.fill: parent
        transform: Rotation {
            origin.x: pages.width / 2
            origin.y: pages.height / 2
            axis.x: 0
            axis.y: 1
            axis.z: 0
            angle: root.lyricsVisible ? 180 : 0

            Behavior on angle {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutCubic
                }
            }
        }

        front: Item {
            anchors.fill: parent

            StyledClippingRect {
                id: cover

                x: root.padding
                y: root.padding
                width: root.compact ? 64 * root.widgetScale : root.tall ? root.width - root.padding * 2 : 184 * root.widgetScale
                height: width
                radius: 16 * root.widgetScale
                color: Qt.alpha(surface.foreground, 0.08)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "music_note"
                    color: surface.secondaryForeground
                    fontStyle: Tokens.font.icon.size(cover.width * 0.4).build()
                }

                FadeImage {
                    anchors.fill: parent
                    source: root.artUrl
                }
            }

            ColumnLayout {
                x: root.tall ? root.padding : cover.x + cover.width + 16 * root.widgetScale
                y: root.compact ? root.padding : root.tall ? cover.y + cover.height + 16 * root.widgetScale : 68 * root.widgetScale
                width: root.width - x - root.padding - (root.compact ? 140 * root.widgetScale : 0)
                spacing: 4 * root.widgetScale

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: root.compact || root.tall ? Text.AlignLeft : Text.AlignHCenter
                    text: root.player?.trackTitle || qsTr("Nothing playing")
                    color: surface.foreground
                    font: Tokens.font.title.builders.small.weight(Font.DemiBold).scale(root.widgetScale).build()
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: root.compact || root.tall ? Text.AlignLeft : Text.AlignHCenter
                    text: root.player ? root.player.trackArtist || qsTr("Unknown artist") : qsTr("Start playback in a music app")
                    color: surface.secondaryForeground
                    font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
                    elide: Text.ElideRight
                }
            }
        }

        back: Item {
            anchors.fill: parent

            ListView {
                id: lyrics

                objectName: "musicLyricList"
                anchors.fill: parent
                anchors.margins: root.padding
                anchors.topMargin: 44 * root.widgetScale
                anchors.bottomMargin: 116 * root.widgetScale
                clip: true
                spacing: 14 * root.widgetScale
                model: Lyrics.lyrics
                currentIndex: {
                    // Track loading and offset edits also change the current line.
                    Lyrics.lyrics;
                    Lyrics.offset;
                    return Lyrics.hasLyrics ? Lyrics.indexForTime(root.player?.position ?? 0) : -1;
                }
                visible: Lyrics.hasLyrics
                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Center);
                }

                delegate: StyledText {
                    id: lyric

                    required property int index
                    required property string modelData

                    width: lyrics.width
                    text: modelData
                    color: surface.foreground
                    opacity: index === lyrics.currentIndex ? 1 : 0.4
                    wrapMode: Text.Wrap
                    font: Tokens.font.title.builders.small.weight(Font.DemiBold).scale(root.widgetScale).build()

                    StateLayer {
                        color: surface.foreground
                        disabled: !root.player?.canSeek
                        onClicked: root.seek(Lyrics.timeForIndex(lyric.index))
                    }
                }
            }

            StyledText {
                objectName: "musicLyricPlaceholder"
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -32 * root.widgetScale
                visible: !Lyrics.hasLyrics
                text: Lyrics.loading ? qsTr("Loading lyrics…") : qsTr("No lyrics found")
                color: surface.secondaryForeground
                font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
            }
        }
    }

    DesktopWidgetButton {
        objectName: "musicLyrics"
        x: root.width - root.padding - width
        y: root.tall && !root.lyricsVisible ? root.height - 156 * root.widgetScale : 12 * root.widgetScale
        visible: !root.compact
        foreground: surface.foreground
        widgetScale: root.widgetScale
        icon: root.lyricsVisible ? "album" : "lyrics"
        Accessible.name: root.lyricsVisible ? qsTr("Show album art") : qsTr("Show lyrics")
        onClicked: root.lyricsVisible = !root.lyricsVisible
    }

    DesktopWidgetButton {
        objectName: "musicPlayer"
        x: root.width - root.padding - width * 2
        y: root.tall ? root.height - 156 * root.widgetScale : 12 * root.widgetScale
        visible: !root.compact && !root.lyricsVisible && Players.list.length > 1
        foreground: surface.foreground
        widgetScale: root.widgetScale
        icon: "speaker_group"
        Accessible.name: qsTr("Next player")
        onClicked: root.nextPlayer()
    }

    RowLayout {
        id: controls

        x: root.compact ? root.width - root.padding - width : root.tall || root.lyricsVisible ? (root.width - width) / 2 : (root.width + 184 * root.widgetScale) / 2 - width / 2
        y: root.compact ? (root.height - height) / 2 - 6 * root.widgetScale : root.height - 112 * root.widgetScale
        spacing: 12 * root.widgetScale

        DesktopWidgetButton {
            objectName: "musicPrevious"
            foreground: surface.foreground
            widgetScale: root.widgetScale
            icon: "skip_previous"
            disabled: !root.player?.canGoPrevious
            Accessible.name: qsTr("Previous track")
            onClicked: {
                if (root.player?.canGoPrevious)
                    root.player.previous();
            }
        }

        DesktopWidgetButton {
            objectName: "musicToggle"
            implicitWidth: 44 * root.widgetScale
            font: Tokens.font.icon.size(30 * root.widgetScale).build()
            foreground: surface.foreground
            widgetScale: root.widgetScale
            icon: root.player?.isPlaying ? "pause" : "play_arrow"
            disabled: !root.player?.canTogglePlaying
            Accessible.name: root.player?.isPlaying ? qsTr("Pause") : qsTr("Play")
            onClicked: {
                if (root.player?.canTogglePlaying)
                    root.player.togglePlaying();
            }
        }

        DesktopWidgetButton {
            objectName: "musicNext"
            foreground: surface.foreground
            widgetScale: root.widgetScale
            icon: "skip_next"
            disabled: !root.player?.canGoNext
            Accessible.name: qsTr("Next track")
            onClicked: {
                if (root.player?.canGoNext)
                    root.player.next();
            }
        }
    }

    Slider {
        id: progress

        objectName: "musicProgress"
        x: root.compact ? 96 * root.widgetScale : root.padding
        y: root.height - (root.compact ? 32 : 58) * root.widgetScale
        width: root.width - x - root.padding
        height: 24 * root.widgetScale
        from: 0
        to: Math.max(1, root.duration)
        value: root.duration > 0 ? root.player?.position ?? 0 : 0
        enabled: root.player?.canSeek === true && root.player?.positionSupported === true && root.duration > 0
        leftPadding: 0
        rightPadding: 0
        onMoved: root.seek(value)
        Accessible.name: qsTr("Playback position")

        background: Rectangle {
            x: progress.leftPadding
            y: (progress.height - height) / 2
            width: progress.availableWidth
            height: 3 * root.widgetScale
            radius: height / 2
            color: Qt.alpha(surface.foreground, 0.22)

            Rectangle {
                width: parent.width * progress.visualPosition
                height: parent.height
                radius: height / 2
                color: surface.foreground
            }
        }

        handle: Item {}
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        visible: !root.compact

        StyledText {
            text: root.timeText(root.player?.position ?? 0)
            color: surface.secondaryForeground
            font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: root.duration ? root.timeText(root.duration) : "--:--"
            color: surface.secondaryForeground
            font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
        }
    }

    Timer {
        interval: 1000
        running: root.visible && (root.player?.isPlaying ?? false) && !GameMode.enabled
        triggeredOnStart: true
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    Connections {
        function onTrackTitleChanged(): void {
            root.syncLyrics();
        }
        function onTrackArtistChanged(): void {
            root.syncLyrics();
        }
        function onTrackAlbumChanged(): void {
            root.syncLyrics();
        }

        target: root.player
    }
}
