import QtQuick
import Quickshell
import qs.components
import qs.components.containers
import qs.services

Item {
    id: root

    required property ScreenState screenState
    required property Item sidebarPanel
    readonly property alias window: panelWindow
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    property alias utilitiesPanel: content.utilitiesPanel

    visible: height > 0
    anchors.topMargin: -5
    implicitWidth: Math.max(sidebarPanel.width, content.implicitWidth)
    implicitHeight: content.implicitHeight

    GlassPanelWindow {
        id: panelWindow

        name: "notifications"
        hostWindow: root.QsWindow.window
        shown: Notifs.popups.length > 0
        panelWidth: content.implicitWidth
        panelHeight: Math.max(64, root.height)
        panelX: hostWindow.width - hostWindow.borderThickness - width
        panelY: hostWindow.borderThickness
        allowFullscreen: true
    }

    Content {
        id: content

        parent: panelWindow.contentItem
        anchors.topMargin: -root.anchors.topMargin
        screenState: root.screenState
    }
}
