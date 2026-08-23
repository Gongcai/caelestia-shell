import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar
    property bool quickpanel
    property bool launchpad

    onLauncherChanged: {
        if (launcher)
            launchpad = false;
    }
    onSessionChanged: {
        if (session)
            launchpad = false;
    }
    onUtilitiesChanged: {
        if (utilities)
            launchpad = false;
    }
    onSidebarChanged: {
        if (sidebar)
            launchpad = false;
    }

    // Dashboard and quickpanel share the top edge; keep their drawers mutually exclusive.
    onDashboardChanged: {
        if (dashboard) {
            quickpanel = false;
            launchpad = false;
        }
    }
    onQuickpanelChanged: {
        if (quickpanel) {
            dashboard = false;
            launchpad = false;
        }
    }
    onLaunchpadChanged: {
        if (launchpad) {
            launcher = false;
            session = false;
            dashboard = false;
            quickpanel = false;
            utilities = false;
            sidebar = false;
        }
    }

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
    property bool dashboardLunar
    property bool dashboardLyrics
    property bool dashboardLyricsPinned
    property bool dashboardLyricsExpanded
    property bool dashboardGithubLogin
}
