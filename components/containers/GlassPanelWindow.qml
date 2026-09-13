pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.services

StyledWindow {
    id: root

    required property var hostWindow
    required property bool shown
    required property real panelX
    required property real panelY
    required property real panelWidth
    required property real panelHeight
    property bool allowFullscreen: false
    property bool acceptsFocus: false
    property bool keepOpen: true
    property real surfaceOpacity: 0.14
    property bool flushToFrame: false
    readonly property bool hovered: hover.hovered

    signal closeRequested

    function scheduleHoverClose(): void {
        hoverClose.restart();
    }

    screen: hostWindow.screen
    visible: false
    implicitWidth: Math.ceil(panelWidth)
    implicitHeight: Math.ceil(panelHeight)
    anchors.top: true
    anchors.left: true
    margins.left: Math.round(Math.max(0, Math.min(panelX, screen.width - width)))
    margins.top: Math.round(Math.max(0, Math.min(panelY, screen.height - height)))
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: allowFullscreen && hostWindow.hasFullscreen ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: acceptsFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Mapping a window can synchronously recalculate its content's implicit size.
    Binding {
        target: root
        property: "visible"
        value: root.shown && root.panelWidth > 0 && root.panelHeight > 0 && (root.allowFullscreen || !root.hostWindow.hasFullscreen)
        delayed: true
    }

    mask: Region {
        item: background
        radius: background.radius
    }

    onHoveredChanged: {
        if (hovered)
            hoverClose.stop();
        else
            scheduleHoverClose();
    }

    // Background and controls share a surface. The compositor animates both
    // with the same bounds, including its refraction sampling geometry.
    StyledRect {
        id: background

        anchors.fill: parent
        radius: root.flushToFrame ? 0 : Tokens.rounding.large
        color: Colours.transparency.enabled ? Qt.alpha(Colours.palette.m3surface, root.surfaceOpacity) : Colours.palette.m3surface
        border.width: 0
    }

    HoverHandler {
        id: hover
    }

    Timer {
        id: hoverClose

        interval: 120
        onTriggered: {
            if (!root.hovered && !root.keepOpen && !root.hostWindow.interactionWrapper.containsMouse)
                root.closeRequested();
        }
    }
}
