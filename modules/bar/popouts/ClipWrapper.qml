pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.components.containers
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    required property real borderThickness

    readonly property alias content: content
    readonly property alias window: panelWindow
    property real offsetScale: x > 0 || content.hasCurrent ? 0 : 1

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: content.implicitWidth * (1 - offsetScale)
    implicitHeight: content.implicitHeight

    x: content.isDetached ? (parent.width - content.nonAnimWidth) / 2 : 0
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;

        const off = content.currentCenter - borderThickness - content.nonAnimHeight / 2;
        const diff = parent.height - Math.floor(off + content.nonAnimHeight);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    Behavior on offsetScale {
        Anim {}
    }

    GlassPanelWindow {
        id: panelWindow

        name: "popout"
        hostWindow: root.QsWindow.window
        shown: content.hasCurrent || content.isDetached
        panelWidth: content.implicitWidth
        panelHeight: content.implicitHeight
        panelX: hostWindow.bar.implicitWidth + root.x
        panelY: root.borderThickness + root.y
        acceptsFocus: content.isDetached || content.currentName === "wirelesspassword"
        keepOpen: hostWindow.bar.window.hovered || content.isDetached || (content.currentName.startsWith("traymenu") && (content.current as StackView)?.depth > 1)
        onCloseRequested: {
            content.hasCurrent = false;
            hostWindow.bar.closeTray();
        }
    }

    Wrapper {
        id: content

        parent: panelWindow.contentItem
        screen: root.screen
        offsetScale: root.offsetScale

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
    }
}
