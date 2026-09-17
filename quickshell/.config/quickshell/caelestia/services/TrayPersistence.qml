pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs.utils

Singleton {
    id: root

    property bool loaded
    property var knownItems: []

    readonly property var liveItems: SystemTray.items.values
    readonly property var liveIds: liveItems.map(item => item.id)

    readonly property var pinnedItems: knownItems.filter(item =>
        item.persistent !== false
        && !liveIds.includes(item.id)
    )

    function normaliseId(id: string): string {
        return (id ?? "")
            .replace(/_status_icon_\d+$/i, "")
            .replace(/[-_]status[-_]icon[-_]?\d*$/i, "")
            .replace(/[-_]client$/i, "");
    }

    function lookupDesktopEntry(id: string, title: string, tooltipTitle: string): var {
        const candidates = [
            id,
            normaliseId(id),
            title,
            tooltipTitle
        ];

        for (const candidate of candidates) {
            if (!candidate)
                continue;

            const entry = DesktopEntries.heuristicLookup(candidate);

            if (entry)
                return entry;
        }

        return null;
    }

    function snapshot(item: var): var {
        const entry = lookupDesktopEntry(
            item.id,
            item.title,
            item.tooltipTitle
        );

        return {
            id: item.id,
            title: entry?.name
                || item.title
                || item.tooltipTitle
                || item.id,
            icon: entry?.icon ?? "",
            desktopEntry: entry?.id ?? "",
            persistent: true
        };
    }

    function syncLiveItems(): void {
        if (!loaded)
            return;

        const next = knownItems.slice();
        let changed = false;

        for (const item of liveItems) {
            const incoming = snapshot(item);
            const index = next.findIndex(saved => saved.id === incoming.id);

            if (index === -1) {
                next.push(incoming);
                changed = true;
                continue;
            }

            const previous = next[index];

            const updated = {
                id: previous.id,
                title: incoming.title || previous.title,
                icon: incoming.icon || previous.icon,
                desktopEntry: incoming.desktopEntry || previous.desktopEntry,
                persistent: previous.persistent !== false
            };

            if (JSON.stringify(previous) !== JSON.stringify(updated)) {
                next[index] = updated;
                changed = true;
            }
        }

        if (!changed)
            return;

        next.sort((a, b) =>
            (a.title || a.id).localeCompare(b.title || b.id)
        );

        knownItems = next;
        saveTimer.restart();
    }

    function isPersistent(id: string): bool {
        return knownItems.find(item => item.id === id)?.persistent !== false;
    }

    function setPersistent(id: string, enabled: bool): void {
        const index = knownItems.findIndex(item => item.id === id);

        if (index === -1)
            return;

        const next = knownItems.slice();

        next[index] = Object.assign({}, next[index], {
            persistent: enabled
        });

        knownItems = next;
        saveTimer.restart();
    }

    function desktopEntryFor(app: var): var {
        if (!app)
            return null;

        if (app.desktopEntry) {
            const exact = DesktopEntries.byId(app.desktopEntry);

            if (exact)
                return exact;
        }

        return lookupDesktopEntry(
            app.id ?? "",
            app.title ?? "",
            ""
        );
    }

    function launch(id: string): void {
        const app = knownItems.find(item => item.id === id);
        const entry = desktopEntryFor(app);

        if (entry)
            entry.execute();
    }

    function iconSource(app: var): string {
        const entry = desktopEntryFor(app);
        const icon = app?.icon || entry?.icon || "application-x-executable";

        return Quickshell.iconPath(icon, "image-missing");
    }

    onLiveItemsChanged: syncLiveItems()

    Timer {
        id: saveTimer

        interval: 100
        onTriggered: storage.setText(
            JSON.stringify(root.knownItems, null, 2)
        )
    }

    FileView {
        id: storage

        path: `${Paths.state}/tray-persistence.json`
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());

                root.knownItems = Array.isArray(data)
                    ? data
                        .filter(item => item?.id)
                        .map(item => ({
                            id: item.id,
                            title: item.title || item.id,
                            icon: item.icon || "",
                            desktopEntry: item.desktopEntry || "",
                            persistent: item.persistent !== false
                        }))
                    : [];
            } catch (error) {
                console.warn(
                    "Unable to load persistent tray state:",
                    error
                );

                root.knownItems = [];
            }

            root.loaded = true;
            root.syncLiveItems();
        }

        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return;

            root.loaded = true;
            root.syncLiveItems();
            saveTimer.restart();
        }
    }
}
