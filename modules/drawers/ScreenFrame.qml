pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

Scope {
    id: root

    required property var hostWindow

    Variants {
        model: ["top", "bottom", "left", "right"]

        StyledWindow {
            id: edge

            required property string modelData
            readonly property real thickness: root.hostWindow.borderLayoutThickness
            readonly property real rounding: root.hostWindow.contentItem.Config.border.rounding
            readonly property bool horizontal: modelData === "top" || modelData === "bottom"
            readonly property real band: Math.min(screen.height / 2, Math.ceil(thickness + rounding * 1.45 + 2))
            readonly property real stripX: modelData === "right" ? screen.width - thickness : 0
            readonly property real stripY: modelData === "bottom" ? screen.height - band : horizontal ? 0 : band

            name: "frame-" + modelData
            screen: root.hostWindow.screen
            // The main drawers surface owns the unified Blob border. Separate
            // edge surfaces get expanded by compositor blur and create stale
            // full-height masks underneath open drawers.
            visible: false
            implicitWidth: horizontal ? screen.width : thickness
            implicitHeight: horizontal ? band : screen.height - band * 2
            anchors.top: true
            anchors.left: true
            margins.left: stripX
            margins.top: stripY
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            // Keep this surface local to the strip. The continuous contour is
            // rendered by ContentWindow's shared BlobGroup; drawing a full
            // screen SDF here makes a narrow layer sample outside its bounds.
            StyledRect {
                anchors.fill: parent
                color: Colours.transparency.enabled
                    ? Qt.alpha(Colours.palette.m3surface, 0.14)
                    : Colours.palette.m3surface
                radius: edge.horizontal ? 0 : edge.rounding * 0.35
            }
        }
    }
}
