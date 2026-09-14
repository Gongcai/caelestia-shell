pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components.effects
import qs.services

DesktopGlass {
    id: root

    required property DesktopBackdrop desktopBackdrop
    readonly property color foreground: Colours.palette.m3onSurface
    readonly property color secondaryForeground: Qt.alpha(foreground, 0.66)

    sourceItem: desktopBackdrop.wallpaper
    sourceTexture: desktopBackdrop.texture
    sourceRevision: desktopBackdrop.revision
    pixelRatio: desktopBackdrop.pixelRatio
    live: desktopBackdrop.live
    glassEnabled: desktopBackdrop.sampling && Colours.transparency.enabled && !GameMode.enabled
    blur: Config.background.desktopGlass.blur
    refraction: Config.background.desktopGlass.refraction
    tintOpacity: Config.background.desktopGlass.opacity
    tint: Colours.palette.m3surface
    solidColor: Colours.palette.m3surfaceContainer
}
