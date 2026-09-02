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

    // Dashboard and quickpanel sit on different edges, so they can coexist;
    // each still closes the launchpad when opened.
    onDashboardChanged: {
        if (dashboard)
            launchpad = false;
    }
    onQuickpanelChanged: {
        if (quickpanel)
            launchpad = false;
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
