import QtQuick
import QtMultimedia
import qs.utils as Utils
import qs.services

Item {
    id: root

    property string source

    function syncPlayback(): void {
        if (visible && source && !GameMode.enabled) {
            if (player.playbackState !== MediaPlayer.PlayingState)
                player.play();
        } else {
            player.pause();
        }
    }

    onVisibleChanged: syncPlayback()
    onSourceChanged: syncPlayback()
    Component.onCompleted: syncPlayback()

    Connections {
        target: GameMode

        function onEnabledChanged(): void {
            root.syncPlayback();
        }
    }

    VideoOutput {
        id: output

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    MediaPlayer {
        id: player

        source: Utils.Paths.toFileUrl(root.source)
        videoOutput: output
        audioOutput: null
        loops: MediaPlayer.Infinite

        onErrorOccurred: (error, errorString) => console.warn(`Failed to play video wallpaper: ${errorString}`)
    }
}
