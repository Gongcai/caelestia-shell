pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers

Item {
    id: root

    required property ScreenState screenState
    required property bool sidebarVisible
    readonly property alias window: panelWindow
    readonly property real nonAnimWidth: content.implicitWidth

    readonly property bool shouldBeActive: screenState.session && Config.session.enabled
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarOffset: sidebarVisible ? 14 : 0

    visible: offsetScale < 1
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight || 510 // Hard coded fallback for first open

    Behavior on offsetScale {
        Anim {}
    }

    GlassPanelWindow {
        id: panelWindow

        name: "session"
        hostWindow: root.QsWindow.window
        shown: root.shouldBeActive && content.status === Loader.Ready
        panelWidth: root.width
        panelHeight: root.height
        panelX: hostWindow.width - hostWindow.borderThickness - root.parent.anchors.rightMargin - width
        panelY: (hostWindow.height - height) / 2
        acceptsFocus: true
    }

    Loader {
        id: content

        parent: panelWindow.contentItem
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
