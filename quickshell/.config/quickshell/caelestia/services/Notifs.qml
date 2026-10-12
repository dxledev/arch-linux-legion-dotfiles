pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components.misc
import qs.services
import qs.utils
import qs.integration

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n.popup)
    property alias dnd: props.dnd

    property bool loaded
    property int storedSerial: 0
    property var pendingRemovals: []
    // Shared with Island, Noctalia and Waybar; see shared/notifications/README.md.
    readonly property string historyScript: Quickshell.env("CAELESTIA_NOTIFICATION_HISTORY")
        || Quickshell.shellPath("shared/notifications/history")

    function hasFullscreen(): bool {
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    function shouldShowPopup(): bool {
        if (props.dnd || ShellState.anySidebarOpen())
            return false;
        if (GlobalConfig.notifs.fullscreen === NotifsFullscreen.Off && hasFullscreen())
            return false;
        return true;
    }

    function storedImage(source: string): string {
        if (source.startsWith("/"))
            return source;
        return source.startsWith("file://") ? Paths.toLocalFile(source) : "";
    }

    function storedRecord(notif: NotifData): var {
        return {
            time: notif.time.toISOString(),
            id: notif.storeId,
            app: notif.appName,
            summary: notif.summary,
            body: notif.body,
            icon: notif.appIcon,
            image: root.storedImage(notif.image) || undefined,
            urgency: notif.urgency
        };
    }

    function store(notif: NotifData): void {
        notif.storeId = Date.now() * 1000 + (++root.storedSerial % 1000);
        notif.storeKey = `${notif.time.toISOString()}|${notif.storeId}`;
        Quickshell.execDetached([root.historyScript, "append", JSON.stringify(root.storedRecord(notif))]);
    }

    // Re-appending merges a newly cached image into the existing record.
    function persist(notif: NotifData): void {
        if (notif.notification && notif.storeKey && root.storedImage(notif.image))
            Quickshell.execDetached([root.historyScript, "append", JSON.stringify(root.storedRecord(notif))]);
    }

    function forget(notif: NotifData): void {
        if (!notif.storeKey)
            return;
        root.pendingRemovals = [...root.pendingRemovals, JSON.stringify({
                key: notif.storeKey,
                time: notif.time.toISOString(),
                summary: notif.summary,
                body: notif.body
            })];
        removalTimer.restart();
    }

    function clearAll(): void {
        for (const notif of root.list.slice()) {
            notif.storeKey = "";
            notif.close();
        }
        root.pendingRemovals = [];
        Quickshell.execDetached([root.historyScript, "clear"]);
    }

    onDndChanged: {
        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    Timer {
        id: removalTimer

        interval: 300
        onTriggered: {
            // Clearing every loaded notification also clears records beyond the load limit.
            const command = root.list.length === 0 ? ["clear"] : ["remove", ...root.pendingRemovals];
            root.pendingRemovals = [];
            Quickshell.execDetached([root.historyScript, ...command]);
        }
    }

    PersistentProperties {
        id: props

        property bool dnd

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
            if (!notif.transient)
                root.store(comp);
        }
    }

    NotificationReplacements {
        onReplaced: notificationId => {
            const notif = root.list.find(n => !n.closed && n.notification && n.notificationId === notificationId);
            if (notif) {
                notif.popup = root.shouldShowPopup();
                notif.time = new Date();
                notif.updateTimeStr();
                notif.refreshArtwork();
                notif.restartTimeout();
                root.list = [notif, ...root.list.filter(n => n !== notif)];
            }
        }
    }

    Process {
        running: true
        command: [root.historyScript, "list", "--limit", "500"]
        stdout: StdioCollector {
            onStreamFinished: {
                let records = [];
                try {
                    records = JSON.parse(text);
                } catch (error) {
                    console.warn("Notifs: could not read shared notification history");
                }
                const stored = records.map(record => notifComp.createObject(root, {
                        time: new Date(record.time),
                        notificationId: record.key,
                        storeKey: record.key,
                        summary: record.summary ?? "",
                        body: record.body ?? "",
                        appIcon: record.icon ?? "",
                        appName: record.app ?? "",
                        image: record.image ?? "",
                        urgency: record.urgency ?? NotificationUrgency.Normal
                    }));
                root.list = [...root.list, ...stored].sort((a, b) => b.time - a.time);
                root.loaded = true;
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: root.clearAll()
    }

    IpcHandler {
        function clear(): void {
            root.clearAll();
        }

        function isDndEnabled(): bool {
            return props.dnd;
        }

        function toggleDnd(): void {
            props.dnd = !props.dnd;
        }

        function enableDnd(): void {
            props.dnd = true;
        }

        function disableDnd(): void {
            props.dnd = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
