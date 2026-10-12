pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property ListModel history: ListModel {}
    property ListModel popups: ListModel {}
    property var entries: []
    property int unreadCount: 0
    property int storedSerial: 0
    readonly property url defaultIcon: Qt.resolvedUrl("../assets/icons/bell.svg")
    // Shared with Caelestia, Noctalia and Waybar; see shared/notifications/README.md.
    readonly property string historyScript: Quickshell.env("ISLAND_NOTIFICATION_HISTORY")
        || Quickshell.shellDir + "/../shared/notifications/history"

    function storedIcon(notification) {
        return notification.appIcon || DesktopEntries.byId(notification.desktopEntry)?.icon || "";
    }

    function storedImage(source) {
        if (source.startsWith("/")) return source;
        return source.startsWith("file://") ? decodeURIComponent(source.slice(7)) : "";
    }

    function displayTime(date) {
        return date.toDateString() === new Date().toDateString()
            ? date.toLocaleTimeString() : date.toLocaleString(Qt.locale(), Locale.ShortFormat);
    }

    function loadStored(text) {
        let records = [];
        try { records = JSON.parse(text); } catch (error) { return; }
        for (const record of records) {
            if (history.count >= 100) break;
            const time = new Date(record.time);
            history.append({
                notificationId: -(++storedSerial), app: record.app || "", summary: record.summary || "",
                body: record.body || "", icon: (imageSource(record.icon || "") || defaultIcon).toString(),
                image: imageSource(record.image || ""), time: displayTime(time), unread: false,
                storeKey: record.key || "", storeTime: record.time || ""
            });
        }
    }

    function storeCommand(args) {
        Quickshell.execDetached([historyScript, ...args]);
    }

    function storeMatch(snapshot) {
        return JSON.stringify({key: snapshot.storeKey, time: snapshot.storeTime, summary: snapshot.summary, body: snapshot.body});
    }

    function imageSource(source) {
        if (!source) return "";
        if (source.startsWith("/")) return "file://" + encodeURI(source).replace(/#/g, "%23").replace(/\?/g, "%3F");
        return source.includes(":") ? source : Quickshell.iconPath(source);
    }

    function getAppIcon(notification) {
        const icon = notification.appIcon || DesktopEntries.byId(notification.desktopEntry)?.icon;
        return imageSource(icon) || root.defaultIcon;
    }

    function popupMonitor() {
        const screens = ThemeService.islandScreens;
        return screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)?.name
            || screens[0]?.name || "";
    }

    function historyIndex(notificationId) {
        for (let index = 0; index < history.count; index++) {
            if (history.get(index).notificationId === notificationId) return index;
        }
        return -1;
    }

    function updateHistory(entry) {
        if (entry.notification.transient) return;
        const index = historyIndex(entry.notificationId);
        const unread = index < 0 || history.get(index).unread;
        const now = new Date();
        const storeTime = index < 0 ? now.toISOString() : history.get(index).storeTime;
        const storeId = index < 0 ? now.getTime() * 1000 + (++storedSerial % 1000) : 0;
        const snapshot = {
            notificationId: entry.notificationId, app: entry.app, summary: entry.summary,
            body: entry.body, icon: entry.icon.toString(), image: entry.image.toString(),
            time: now.toLocaleTimeString(), unread: unread,
            storeKey: index < 0 ? storeTime + "|" + storeId : history.get(index).storeKey, storeTime: storeTime
        };
        if (index < 0) {
            history.insert(0, snapshot);
            unreadCount++;
            storeCommand(["append", JSON.stringify({
                time: storeTime, id: storeId, app: entry.app, summary: entry.summary, body: entry.body,
                icon: storedIcon(entry.notification), image: storedImage(entry.image.toString()) || undefined,
                urgency: entry.notification.urgency
            })]);
        } else {
            history.set(index, snapshot);
            if (index > 0) history.move(index, 0, 1);
        }
        while (history.count > 100) forget(history.count - 1, false);
    }

    function release(entry) {
        for (let index = 0; index < popups.count; index++) {
            if (popups.get(index).entry === entry) {
                popups.remove(index);
                break;
            }
        }
        entries = entries.filter(item => item !== entry);
        entry.destroy();
    }

    function receive(notification) {
        notification.tracked = true;
        const existing = entries.find(entry => entry.notificationId === notification.id);
        if (existing) { promote(existing); return; }
        const entry = notificationComponent.createObject(root, {
            notification: notification, notificationId: notification.id, monitorName: popupMonitor()
        });
        entry.updated.connect(() => root.updateHistory(entry));
        entry.finished.connect(() => root.release(entry));
        entries = [entry, ...entries];
        popups.insert(0, {entry: entry});
        entry.refresh();
    }

    function promote(entry) {
        for (let index = 0; index < popups.count; index++) {
            if (popups.get(index).entry === entry) {
                if (index > 0) popups.move(index, 0, 1);
                break;
            }
        }
        entries = [entry, ...entries.filter(item => item !== entry)];
        entry.refresh();
    }

    function send(app, summary, body) {
        Quickshell.execDetached(["/usr/bin/notify-send", "--app-name", app, summary, body]);
    }

    function clear() {
        for (const entry of entries.slice()) entry.dismiss();
        history.clear();
        unreadCount = 0;
        storeCommand(["clear"]);
    }

    function forget(index, removeStored) {
        if (index < 0 || index >= history.count) return;
        const snapshot = history.get(index);
        entries.find(entry => entry.notificationId === snapshot.notificationId)?.dismiss();
        if (snapshot.unread) unreadCount = Math.max(0, unreadCount - 1);
        if (removeStored) storeCommand(["remove", storeMatch(snapshot)]);
        history.remove(index);
    }

    function remove(index) {
        forget(index, true);
    }

    function markRead() {
        for (let index = 0; index < history.count; index++) history.setProperty(index, "unread", false);
        unreadCount = 0;
    }

    function removeById(notificationId) {
        remove(historyIndex(notificationId));
    }

    Process {
        running: true
        command: [root.historyScript, "list", "--limit", "100"]
        stdout: StdioCollector { onStreamFinished: root.loadStored(text) }
    }

    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        onNotification: notification => root.receive(notification)
    }

    NotificationReplacements {
        onReplaced: notificationId => Qt.callLater(() => {
            const entry = root.entries.find(item => item.notificationId === Number(notificationId));
            if (entry) root.promote(entry);
        })
    }

    Connections {
        target: ThemeService
        function onIslandScreensChanged() {
            const names = ThemeService.islandScreens.map(screen => screen.name);
            for (const entry of root.entries) {
                if (!names.includes(entry.monitorName)) entry.monitorName = root.popupMonitor();
            }
        }
    }

    Component {
        id: notificationComponent
        NotificationData {}
    }
}
