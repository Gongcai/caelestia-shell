pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels
    readonly property alias window: panelWindow

    readonly property bool shouldBeActive: screenState.launcher && Config.launcher.enabled

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;
        if (screenState.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    visible: offsetScale < 1
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630 // Hard coded fallback for first open

    Behavior on offsetScale {
        Anim {}
    }

    GlassPanelWindow {
        id: panelWindow

        name: "launcher"
        hostWindow: root.QsWindow.window
        shown: root.shouldBeActive && content.status === Loader.Ready
        panelWidth: root.width
        panelHeight: root.height
        panelX: hostWindow.bar.implicitWidth + root.x
        panelY: hostWindow.height - hostWindow.borderThickness - height
        acceptsFocus: true
    }

    Loader {
        id: content

        parent: panelWindow.contentItem
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}
