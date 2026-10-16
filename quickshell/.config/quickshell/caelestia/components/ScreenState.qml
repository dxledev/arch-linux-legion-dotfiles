import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool osd
    property bool session
    property bool launcher
    // Dedicated launcher submenu (e.g. "libreoffice"); "" shows the normal apps list.
    property string launcherSubmenu
    property bool dashboard
    property bool utilities
    property bool sidebar

    // Dashboard state
    property bool dashboardPinned: false
    property int dashboardTab
    property date dashboardDate: new Date()

    onDashboardChanged: {
        if (!dashboard)
            dashboardPinned = false;
    }
}
