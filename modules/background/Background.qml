pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.background.widgets

Variants {
    model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).background.enabled)

    StyledWindow {
        id: win

        required property ShellScreen modelData
        readonly property string effectiveWallpaper: Wallpapers.pathForScreen(modelData.name)

        screen: modelData
        name: "background"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: contentItem.Config.background.wallpaperEnabled ? WlrLayer.Background : WlrLayer.Bottom
        color: contentItem.Config.background.wallpaperEnabled ? "black" : "transparent"
        surfaceFormat.opaque: false

        mask: Region {
            item: widgets.clockInteractionTarget

            Region {
                item: widgets.memoryInteractionTarget
            }
        }

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        ShellState.ComponentRef {
            screen: win.screen
            slot: "background"
            component: win
        }

        Item {
            id: behindClock

            anchors.fill: parent

            Loader {
                id: wallpaper

                asynchronous: true

                anchors.fill: parent
                active: Config.background.wallpaperEnabled

                sourceComponent: Wallpapers.isVideoPath(win.effectiveWallpaper) ? videoWallpaperComponent : imageWallpaperComponent
            }

            Component {
                id: imageWallpaperComponent

                Wallpaper {
                    source: win.effectiveWallpaper
                }
            }

            Component {
                id: videoWallpaperComponent

                VideoWallpaper {
                    source: win.effectiveWallpaper
                }
            }

            Visualiser {
                anchors.fill: parent
                screen: win.modelData
                wallpaper: wallpaper
            }
        }

        DesktopWidgets {
            id: widgets

            z: 1
            anchors.fill: parent
            screen: win.modelData
            wallpaper: behindClock
        }
    }
}
