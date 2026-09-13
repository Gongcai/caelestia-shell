pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.sidebar as Sidebar
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var rootWindow
    required property Sidebar.Wrapper sidebar
    required property BarPopouts.Wrapper popouts
    readonly property alias window: panelWindow
    readonly property matrix4x4 deformMatrix: Qt.matrix4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)

    function scheduleHoverClose(): void {
        hoverClose.restart();
    }

    readonly property PersistentProperties props: PersistentProperties {
        property bool recordingListExpanded: false
        property string recordingConfirmDelete
        property string recordingMode
        property string controlCenterPage: "main"

        reloadableId: "utilities"
    }
    readonly property bool shouldBeActive: screenState.sidebar || (screenState.utilities && Config.utilities.enabled && !(screenState.session && Config.session.enabled))
    readonly property real totalPadding: Tokens.padding.large * 2
    readonly property real nonAnimHeight: ((content.item as Content)?.nonAnimHeight ?? 0) + totalPadding
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarLerp

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight + totalPadding
    implicitWidth: sidebar.width * sidebarLerp + Tokens.sizes.utilities.width * (1 - sidebarLerp)

    states: State {
        name: "attachedToSidebar"
        when: root.screenState.sidebar

        PropertyChanges {
            root.sidebarLerp: 1
        }
    }

    transitions: [
        Transition {
            from: ""

            Anim {
                property: "sidebarLerp"
                duration: Tokens.anim.durations.expressiveDefaultSpatial / 2
                easing: Tokens.anim.standardAccel
            }
        },
        Transition {
            to: ""

            Anim {
                property: "sidebarLerp"
                duration: Tokens.anim.durations.expressiveDefaultSpatial / 2
                easing: Tokens.anim.standardDecel
            }
        }
    ]

    Behavior on offsetScale {
        Anim {}
    }

    Timer {
        id: hoverClose

        interval: 120
        onTriggered: {
            const interactions = root.rootWindow.interactionWrapper;
            if (!panelHover.hovered && !interactions.containsMouse && !interactions.utilitiesShortcutActive)
                root.screenState.utilities = false;
        }
    }

    StyledWindow {
        id: panelWindow

        readonly property bool hovered: panelHover.hovered

        name: "control-center"
        screen: root.screen
        visible: root.shouldBeActive && content.status === Loader.Ready && !root.rootWindow.hasFullscreen
        implicitWidth: Math.ceil(root.implicitWidth)
        implicitHeight: Math.ceil(root.implicitHeight)
        anchors.right: true
        anchors.bottom: true
        margins.right: root.Config.border.thickness
        margins.bottom: root.Config.border.thickness
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            item: panelBackground
            radius: panelBackground.radius
        }

        // The surface itself is panel-sized. Hyprland animates its content and
        // the glass together; no second window or screen-space mask follows it.
        StyledRect {
            id: panelBackground

            anchors.fill: parent
            radius: Tokens.rounding.large
            color: Colours.transparency.enabled ? Qt.alpha(Colours.palette.m3surface, 0.14) : Colours.palette.m3surface
            border.width: 0
        }

        HoverHandler {
            id: panelHover

            onHoveredChanged: {
                if (hovered)
                    hoverClose.stop();
                else {
                    root.scheduleHoverClose();
                    root.sidebar.window.scheduleHoverClose();
                }
            }
        }
    }

    Loader {
        id: content

        parent: panelWindow.contentItem
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

        asynchronous: true
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: root.implicitWidth - root.totalPadding
            screen: root.screen
            props: root.props
            screenState: root.screenState
            popouts: root.popouts
            deformMatrix: root.deformMatrix
        }
    }
}
