pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Internal
import Caelestia.Services
import qs.components
import qs.services

Item {
    id: root

    required property Item wallpaper
    required property real absX
    required property real absY

    readonly property real widgetScale: Config.background.desktopVisualiser.scale
    readonly property bool bgEnabled: Config.background.desktopVisualiser.background.enabled
    readonly property bool blurEnabled: bgEnabled && Config.background.desktopVisualiser.background.blur && !GameMode.enabled
    readonly property var player: Players.list.find(candidate => candidate.isPlaying) ?? Players.active
    readonly property bool playing: Players.list.some(candidate => candidate.isPlaying)
    readonly property list<real> silentValues: Array.from({
        length: GlobalConfig.services.visualiserBars
    }, () => 0)

    implicitWidth: 320 * widgetScale
    implicitHeight: 126 * widgetScale

    ServiceRef {
        // Releasing the reference stops both the cava worker and PipeWire capture
        // when no MPRIS player is producing music.
        service: root.playing ? Audio.cava : null
    }

    Item {
        anchors.fill: parent

        Loader {
            asynchronous: true
            anchors.fill: parent
            active: root.blurEnabled

            sourceComponent: MultiEffect {
                source: ShaderEffectSource {
                    sourceItem: root.wallpaper
                    sourceRect: Qt.rect(root.absX, root.absY, root.width, root.height)
                }
                maskSource: backgroundPlate
                maskEnabled: true
                blurEnabled: true
                blur: 1
                blurMax: 64
                autoPaddingEnabled: false
            }
        }

        StyledRect {
            id: backgroundPlate

            visible: root.bgEnabled
            anchors.fill: parent
            radius: Tokens.rounding.extraLarge * root.widgetScale
            opacity: Config.background.desktopVisualiser.background.opacity
            color: Colours.palette.m3surface

            layer.enabled: root.blurEnabled
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large * root.widgetScale
            spacing: Tokens.spacing.small * root.widgetScale

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small * root.widgetScale

                MaterialIcon {
                    text: root.playing ? "graphic_eq" : "music_note"
                    fill: root.playing ? 1 : 0
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.builders.medium.scale(root.widgetScale).build()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: (root.player?.trackTitle ?? qsTr("No music playing")) || qsTr("Unknown title")
                        elide: Text.ElideRight
                        font: Tokens.font.title.builders.small.scale(root.widgetScale).build()
                        color: Colours.palette.m3onSurface
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: (root.player?.trackArtist ?? Players.getIdentity(root.player) ?? "") || qsTr("Unknown artist")
                        elide: Text.ElideRight
                        font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            VisualiserBars {
                id: bars

                Layout.fillWidth: true
                Layout.fillHeight: true
                values: root.playing ? Audio.cava.values : root.silentValues
                primaryColor: Colours.palette.m3primary
                secondaryColor: Colours.palette.m3tertiary
                rounding: Tokens.rounding.full
                spacing: Tokens.spacing.extraSmall * root.widgetScale
                mirrored: false
                maximumBarCount: Config.background.desktopVisualiser.bars
                barHeightRatio: 0.92
                animationDuration: Tokens.anim.durations.normal
            }
        }

        Timer {
            // A spectrum remains fluid at 30 FPS and avoids doubling the paint
            // work on 120/144 Hz displays.
            interval: 33
            repeat: true
            running: !bars.settled
            onTriggered: bars.advance(interval / 1000)
        }
    }
}
