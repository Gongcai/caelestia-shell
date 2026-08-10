pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property string effectiveWallpaper: Wallpapers.pathForScreen(nState.screen.name)
    readonly property bool videoWallpaper: Wallpapers.isVideoPath(effectiveWallpaper)

    title: qsTr("Wallpaper & style")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledClippingRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                Loader {
                    id: wallIndicatorLoader

                    anchors.centerIn: parent

                    opacity: 0
                    active: opacity > 0

                    sourceComponent: StyledRect {
                        implicitWidth: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2
                        implicitHeight: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2

                        color: Colours.palette.m3primaryContainer
                        radius: Tokens.rounding.full

                        LoadingIndicator {
                            id: wallLoadingIndicator

                            anchors.centerIn: parent
                            containsIcon: true
                            implicitSize: Math.min(wallWrapper.implicitWidth, wallWrapper.implicitHeight) * 0.4
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Timer {
                    id: wallLoadDebounceTimer

                    interval: 100
                    onTriggered: {
                        if (!root.videoWallpaper && wallImg.status !== Image.Ready)
                            wallIndicatorLoader.opacity = 1;
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: root.videoWallpaper
                    text: "video_library"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                }

                FadeImage {
                    id: wallImg

                    anchors.fill: parent
                    visible: !root.videoWallpaper
                    source: root.videoWallpaper ? "" : root.effectiveWallpaper
                    preventInit: wallIndicatorLoader.opacity > 0
                    fadeOutAnim: Anim.DefaultEffects
                    fadeInAnim: Anim.SlowEffects

                    onSourceChanged: wallLoadDebounceTimer.restart()

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallLoadDebounceTimer.stop();
                            wallIndicatorLoader.opacity = 0;
                        }
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: qsTr("Wallpapers")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: {
                    root.nState.selectedWallpaperScreen = root.nState.screen.name;
                    root.nState.openSubPage(1); // Wallpaper page
                }
            }

            IconTextButton {
                icon: "palette"
                text: qsTr("Colours")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(3) // Colours page
            }
        }

        ToggleRow {
            first: true
            text: qsTr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            SectionHeader {
                first: true
                text: qsTr("Transparency & blur")
            }

            ToggleRow {
                first: true
                text: qsTr("Transparency")
                subtext: qsTr("Allow the wallpaper and windows to show through panels")
                checked: GlobalConfig.appearance.transparency.enabled
                onToggled: GlobalConfig.appearance.transparency.enabled = checked
            }

            SliderRow {
                icon: "opacity"
                label: qsTr("Surface opacity")
                value: GlobalConfig.appearance.transparency.base
                valueLabel: qsTr("%1%").arg(Math.round(value * 100))
                enabled: GlobalConfig.appearance.transparency.enabled
                onMoved: v => GlobalConfig.appearance.transparency.base = Math.round(v * 100) / 100
            }

            SliderRow {
                icon: "layers"
                label: qsTr("Layer opacity")
                value: GlobalConfig.appearance.transparency.layers
                valueLabel: qsTr("%1%").arg(Math.round(value * 100))
                enabled: GlobalConfig.appearance.transparency.enabled
                onMoved: v => GlobalConfig.appearance.transparency.layers = Math.round(v * 100) / 100
            }

            ToggleRow {
                text: qsTr("Background blur")
                subtext: qsTr("Blur transparent Shell surfaces using Hyprland")
                checked: GlobalConfig.appearance.blur.enabled
                onToggled: GlobalConfig.appearance.blur.enabled = checked
            }

            StepperRow {
                label: qsTr("Blur radius")
                subtext: qsTr("Hyprland-wide sampling distance used by each pass")
                value: GlobalConfig.appearance.blur.size
                from: 1
                to: 40
                stepSize: 1
                enabled: GlobalConfig.appearance.blur.enabled
                onMoved: v => GlobalConfig.appearance.blur.size = Math.round(v)
            }

            StepperRow {
                label: qsTr("Blur passes")
                subtext: qsTr("Hyprland-wide; higher values are smoother but cost more GPU")
                value: GlobalConfig.appearance.blur.passes
                from: 1
                to: 8
                stepSize: 1
                enabled: GlobalConfig.appearance.blur.enabled
                onMoved: v => GlobalConfig.appearance.blur.passes = Math.round(v)
            }

            SliderRow {
                icon: "blur_on"
                label: qsTr("Blur vibrancy")
                value: GlobalConfig.appearance.blur.vibrancy
                valueLabel: qsTr("%1%").arg(Math.round(value * 100))
                enabled: GlobalConfig.appearance.blur.enabled
                onMoved: v => GlobalConfig.appearance.blur.vibrancy = Math.round(v * 100) / 100
            }
        }

        ToggleRow {
            last: true
            text: qsTr("Dark theme")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }
    }
}
