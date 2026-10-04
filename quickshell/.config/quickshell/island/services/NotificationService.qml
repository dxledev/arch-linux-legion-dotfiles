pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Singleton {
    id: root

    property ListModel history: ListModel {}
    property ListModel popups: ListModel {}
    property var entries: []
    property int unreadCount: 0
    readonly property url defaultIcon: Qt.resolvedUrl("../assets/icons/bell.svg")

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
        const snapshot = {
            notificationId: entry.notificationId, app: entry.app, summary: entry.summary,
            body: entry.body, icon: entry.icon.toString(), image: entry.image.toString(),
            time: new Date().toLocaleTimeString(), unread: unread
        };
        if (index < 0) {
            history.insert(0, snapshot);
            unreadCount++;
        } else {
            history.set(index, snapshot);
            if (index > 0) history.move(index, 0, 1);
        }
        while (history.count > 100) remove(history.count - 1);
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
    }

    function remove(index) {
        if (index < 0 || index >= history.count) return;
        const snapshot = history.get(index);
        entries.find(entry => entry.notificationId === snapshot.notificationId)?.dismiss();
        if (snapshot.unread) unreadCount = Math.max(0, unreadCount - 1);
        history.remove(index);
    }

    function markRead() {
        for (let index = 0; index < history.count; index++) history.setProperty(index, "unread", false);
        unreadCount = 0;
    }

    function removeById(notificationId) {
        remove(historyIndex(notificationId));
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
