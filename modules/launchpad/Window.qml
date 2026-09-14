pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.components.containers

StyledWindow {
    id: root

    required property ScreenState screenState

    name: "launchpad"
    visible: false
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Unmapping releases the loader. Defer it so destroying the content
    // cannot re-enter the window's visibility binding during the close fade.
    Binding {
        target: root
        property: "visible"
        value: root.screenState.launchpad || ((contentLoader.item as Wrapper)?.reveal ?? 0) > 0
        delayed: true
    }

    Loader {
        id: contentLoader

        anchors.fill: parent
        // A hidden layer window can have no configured size at startup.
        // Create its grid after mapping, and release it after the close fade.
        active: root.visible && width > 0 && height > 0
        sourceComponent: Wrapper {
            screen: root.screen
            screenState: root.screenState
        }
    }
}
