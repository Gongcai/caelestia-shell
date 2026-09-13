pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.filedialog
import qs.utils

Item {
    id: root

    required property ScreenState screenState
    readonly property alias window: panelWindow
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }
    readonly property FileDialog kdeConnectFilePicker: FileDialog {
        title: qsTr("Send a file")
        filterLabel: qsTr("Files")
    }
    readonly property bool modalActive: facePicker.opened || kdeConnectFilePicker.opened || screenState.dashboardGithubLogin

    Component.onCompleted: screenState.dashboardGithubLogin = false // Reset stale persisted state, login cannot survive a restart

    readonly property real nonAnimHeight: (content.item as Content)?.nonAnimHeight ?? 0
    readonly property bool shouldBeActive: screenState.dashboard && Config.dashboard.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 854 // Hard coded fallback for first open

    Behavior on offsetScale {
        Anim {}
    }

    GlassPanelWindow {
        id: panelWindow

        name: "dashboard"
        hostWindow: root.QsWindow.window
        shown: root.shouldBeActive && content.status === Loader.Ready
        panelWidth: root.width
        panelHeight: root.height
        panelX: hostWindow.bar.implicitWidth + root.x
        panelY: hostWindow.borderThickness
        flushToFrame: true
        acceptsFocus: !root.Config.dashboard.showOnHover
        keepOpen: hostWindow.interactionWrapper.dashboardShortcutActive || root.modalActive
        onCloseRequested: root.screenState.dashboard = false
    }

    Loader {
        id: content

        parent: panelWindow.contentItem
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            facePicker: root.facePicker
            kdeConnectFilePicker: root.kdeConnectFilePicker
        }
    }
}
