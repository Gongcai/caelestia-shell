pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar
import qs.modules.launchpad as Launchpad

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions
    readonly property alias panels: panels

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property bool hasFullscreenOnNormalWs: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            if (!specialName)
                return false;
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return hasFullscreenOnNormalWs;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: contentItem.Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property int dragMaskPadding: {
        if (focusGrab.active || panels.popouts.isDetached)
            return 0;

        if (monitor?.lastIpcObject.specialWorkspace?.name || monitor?.activeWorkspace?.lastIpcObject.windows > 0)
            return 0;

        const thresholds = [];
        for (const panel of ["dashboard", "quickpanel", "launcher", "session", "sidebar"])
            if (contentItem.Config[panel].enabled)
                thresholds.push(contentItem.Config[panel].dragThreshold);
        return Math.max(...thresholds);
    }

    onHasFullscreenChanged: {
        screenState.launcher = false;
        screenState.session = false;
        screenState.dashboard = false;
        screenState.dashboardLyrics = false;
        screenState.quickpanel = false;
        screenState.launchpad = false;
        panels.popouts.close();
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: (fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen) || (hasSpecialWorkspace && hasFullscreenOnNormalWs) ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: screenState.launchpad ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: screenState.launchpad ? null : hasFullscreen ? emptyRegion : regions

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Behavior on surfaceColour {
        CAnim {}
    }

    Region {
        id: emptyRegion
    }

    Regions {
        id: regions

        bar: bar
        panels: panels
        win: root
    }

    HyprlandFocusGrab {
        id: focusGrab

        active: {
            const s = root.screenState;
            const conf = root.contentItem.Config;
            if (s.launchpad || (s.launcher && conf.launcher.enabled) || (s.session && conf.session.enabled) || (s.sidebar && conf.sidebar.enabled))
                return true;
            if (!conf.dashboard.showOnHover && s.dashboard && conf.dashboard.enabled)
                return true;
            if (!conf.quickpanel.showOnHover && s.quickpanel && conf.quickpanel.enabled)
                return true;
            if (s.dashboardLyrics && !s.dashboardLyricsPinned && conf.dashboard.enabled)
                return true;
            if (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
                return true;
            return false;
        }
        windows: [root, bar.window, panels.utilities.window, panels.dashboard.window,
            panels.quickpanel.window, panels.launcher.window, panels.sidebar.window,
            panels.session.window, panels.osd.window, panels.notifications.window,
            panels.dashboardLyrics.window, panels.popoutsWrapper.window]
        onCleared: {
            root.screenState.launcher = false;
            root.screenState.launchpad = false;
            root.screenState.session = false;
            root.screenState.sidebar = false;
            if (!panels.dashboard.modalActive)
                root.screenState.dashboard = false;
            root.screenState.quickpanel = false;
            if (!root.screenState.dashboardLyricsPinned)
                root.screenState.dashboardLyrics = false;
            panels.popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    StyledRect {
        anchors.fill: parent
        opacity: (root.screenState.session && Config.session.enabled) || panels.popouts.detachedMode !== "" ? 0.5 : 0
        color: Colours.palette.m3scrim

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        anchors.fill: parent
        // Panel surfaces are rendered independently by Hyprglass. The former
        // full-screen Blob SDF produced a separate Gaussian blur sheet under
        // them and could remain visible after a drawer closed.
        visible: false
        opacity: root.surfaceColour.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup

            color: root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
        }

        BlobInvertedRect {
            anchors.fill: parent
            // Keep the global contour subtle. Native panel surfaces carry the
            // glass material; a fully opaque inverted rect reads as a second
            // full-screen blur sheet underneath them.
            opacity: 0.16
            anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
            group: blobGroup
            radius: root.borderRounding
            borderLeft: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderRight: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderTop: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderBottom: root.borderThickness - anchors.margins - root.sdfBorderOffset
        }

        // Keep a shared SDF under the native glass windows. Its overlapping
        // shapes provide the continuous bulged transitions at adjoining edges.
        PanelBg { id: dashBg; panel: panels.dashboard; deformAmount: 0.1 }
        PanelBg { id: quickpanelBg; panel: panels.quickpanel; deformAmount: 0.1 }
        PanelBg { id: dashLyricsBg; panel: panels.dashboardLyrics; deformAmount: 0.08 }
        PanelBg { id: launcherBg; panel: panels.launcher; deformAmount: 0.1 }
        PanelBg {
            id: sessionBg
            panel: panels.sessionWrapper
            deformAmount: 0.2
            x: panels.sessionWrapper.x + panels.session.x + bar.implicitWidth
            implicitWidth: panels.session.width
        }
        PanelBg {
            id: sidebarBg
            panel: panels.sidebar
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
            bottomLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }
        PanelBg {
            id: osdBg
            panel: panels.osdWrapper
            deformAmount: 0.25
            x: panels.osdWrapper.x + panels.osd.x + bar.implicitWidth
            implicitWidth: panels.osd.width
        }
        PanelBg { id: notifsBg; panel: panels.notifications }
        PanelBg {
            id: utilsBg
            panel: panels.utilities
            deformAmount: panels.sidebar.visible ? 0.1 : 0.15
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
            topLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }
        PanelBg {
            id: popoutBg
            property real extraWidth: panels.popouts.isDetached ? 0 : 0.2
            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1
            x: panels.popoutsWrapper.x + panels.popouts.x + bar.implicitWidth - panels.popouts.width * extraWidth
            implicitWidth: panels.popouts.width * (1 + extraWidth)
            Behavior on extraWidth { Anim {} }
        }

    }

    // Border pixels live on the same surface as the drawer composition so
    // Hyprglass can sample them with the same refraction material.
    Item {
        anchors.fill: parent
        visible: !root.hasFullscreen && !root.screenState.launchpad && root.borderThickness > 0
        opacity: root.surfaceColour.a

        StyledRect { x: 0; y: 0; width: parent.width; height: root.borderThickness; color: root.surfaceColour }
        StyledRect { x: 0; y: parent.height - root.borderThickness; width: parent.width; height: root.borderThickness; color: root.surfaceColour }
        StyledRect { x: 0; y: root.borderThickness; width: root.borderThickness; height: parent.height - 2 * root.borderThickness; color: root.surfaceColour }
        StyledRect { x: parent.width - root.borderThickness; y: root.borderThickness; width: root.borderThickness; height: parent.height - 2 * root.borderThickness; color: root.surfaceColour }
    }

    ScreenFrame {
        hostWindow: root
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        screenState: root.screenState
        panels: panels
        bar: bar
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen

        Panels {
            id: panels

            screen: root.screen
            screenState: root.screenState
            bar: bar
            rootWindow: root
            borderThickness: root.borderThickness

        }

        BarWrapper {
            id: bar

            anchors.top: parent.top
            anchors.bottom: parent.bottom

            screen: root.screen
            screenState: root.screenState
            popouts: panels.popouts

            fullscreen: root.hasFullscreen
        }
    }

    Launchpad.Wrapper {
        anchors.fill: parent
        screen: root.screen
        screenState: root.screenState
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "rootWindow"
        component: root
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "interactionWrapper"
        component: interactions
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "bar"
        component: bar
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "panels"
        component: panels
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15
        group: blobGroup
        x: panel.x + bar.implicitWidth
        y: panel.y + root.borderThickness
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }

}
