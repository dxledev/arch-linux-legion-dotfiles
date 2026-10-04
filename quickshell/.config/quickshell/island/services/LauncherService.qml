pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "LauncherSearch.js" as Search

Singleton {
    id: root
    readonly property string appListPath: Quickshell.env("APP_LIST") || Quickshell.env("HOME") + "/.config/apps.list"
    readonly property string appListScript: Quickshell.env("ISLAND_APP_LIST_SCRIPT") || Quickshell.env("HOME") + "/bin/app-list"
    property var configuredRows: []
    property var usage: ({})
    property bool usageLoaded: false
    property bool refreshPending: false
    property string error: ""
    readonly property bool loading: reader.running
    readonly property var applications: ThemeService.settings.launcherShowAllApps ?? true
        ? DesktopEntries.applications.values.filter(entry => !entry.noDisplay).map(entry => root.appFromEntry(entry))
            .sort((a, b) => a.name.localeCompare(b.name))
        : configuredRows.map(row => root.appFromRow(row))

    function appFromEntry(entry) {
        return {id: entry.id, name: entry.name, icon: entry.icon || "application-x-executable",
            description: entry.genericName || entry.comment || "", keywords: entry.keywords || [], entry: entry, launcher: ""};
    }

    function appFromRow(row) {
        const entry = DesktopEntries.byId(row.launcher.replace(/\.desktop$/, ""));
        return {id: row.launcher, name: row.name, icon: row.icon || "application-x-executable",
            description: entry?.genericName || entry?.comment || "", keywords: entry?.keywords || [], entry: entry, launcher: row.launcher};
    }

    function search(query) { return Search.results(applications, query, ThemeService.settings, usage); }

    function launch(app, dryRun = false) {
        if (!app) return false;
        if (dryRun) return app.launcher || app.entry?.id || false;
        if (app.launcher) Quickshell.execDetached(["/usr/bin/bash", appListScript, "--launch", app.launcher]);
        else if (app.entry) app.entry.execute();
        else return false;
        const previous = usage[app.id] || {};
        usage = Object.assign({}, usage, {[app.id]: {count: (previous.count || 0) + 1, lastUsed: Date.now()}});
        if (usageLoaded) usageFile.setText(JSON.stringify(usage));
        return true;
    }

    function refresh() {
        if (reader.running) { refreshPending = true; return; }
        reader.running = true;
    }

    FileView {
        path: root.appListPath
        watchChanges: true
        onFileChanged: { reload(); root.refresh(); }
    }
    FileView {
        id: usageFile
        path: ThemeService.stateDirectory + "/launcher-usage.json"
        atomicWrites: true
        onLoaded: {
            try { root.usage = JSON.parse(text()); }
            catch (error) { root.usage = ({}); }
            root.usageLoaded = true;
        }
        onLoadFailed: root.usageLoaded = true
    }
    Process {
        id: reader
        command: ["/usr/bin/bash", root.appListScript, "--list"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(code) {
            root.error = "";
            try {
                if (code !== 0) throw new Error(stderr.text.trim() || "Could not load apps.list");
                root.configuredRows = JSON.parse(stdout.text);
            } catch (error) { root.error = String(error); root.configuredRows = []; }
            if (root.refreshPending) { root.refreshPending = false; root.refresh(); }
        }
    }
    Component.onCompleted: refresh()
}
