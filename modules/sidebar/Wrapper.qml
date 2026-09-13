pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.containers

Item {
    id: root

    required property ScreenState screenState
    readonly property alias window: panelWindow
    readonly property Props props: Props {}

    readonly property bool shouldBeActive: screenState.sidebar && Config.sidebar.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    implicitWidth: Tokens.sizes.sidebar.width

    Behavior on offsetScale {
        Anim {}
    }

    GlassPanelWindow {
        id: panelWindow

        name: "sidebar"
        hostWindow: root.QsWindow.window
        shown: root.shouldBeActive && content.status === Loader.Ready
        panelWidth: root.width
        panelHeight: root.height
        panelX: hostWindow.width - hostWindow.borderThickness - width
        panelY: hostWindow.borderThickness + root.y
        flushToFrame: true
        keepOpen: !root.Config.sidebar.showOnHover || hostWindow.panels.utilities.window.hovered
        onCloseRequested: root.screenState.sidebar = false
    }

    Loader {
        id: content

        parent: panelWindow.contentItem
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: Tokens.padding.large
        anchors.margins: CUtils.clamp(anchors.leftMargin - Config.border.thickness, 0, anchors.leftMargin)
        anchors.bottomMargin: 0

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: Tokens.sizes.sidebar.width - content.anchors.leftMargin - content.anchors.margins
            props: root.props
            screenState: root.screenState
        }
    }
}
