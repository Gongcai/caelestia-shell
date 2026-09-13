pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

Item {
    id: root

    required property ScreenState screenState
    readonly property alias window: panelWindow

    readonly property real nonAnimHeight: (content.item as Content)?.nonAnimHeight ?? 0
    readonly property bool shouldBeActive: screenState.quickpanel && Config.quickpanel.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            Clipboard.reload();
    }

    Timer {
        interval: 750
        repeat: true
        running: root.shouldBeActive
        onTriggered: Clipboard.reload()
    }

    visible: offsetScale < 1
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 400

    Behavior on offsetScale {
        Anim {}
    }

    GlassPanelWindow {
        id: panelWindow

        name: "quickpanel"
        hostWindow: root.QsWindow.window
        shown: root.shouldBeActive && content.status === Loader.Ready
        panelWidth: root.width
        panelHeight: root.height
        panelX: hostWindow.bar.implicitWidth
        panelY: hostWindow.height - hostWindow.borderThickness - height
        acceptsFocus: true
        keepOpen: hostWindow.interactionWrapper.quickpanelShortcutActive
        onCloseRequested: root.screenState.quickpanel = false
    }

    Loader {
        id: content

        parent: panelWindow.contentItem
        anchors.left: parent.left
        anchors.top: parent.top

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
