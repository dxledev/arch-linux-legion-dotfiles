pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../island"

Singleton {
    id: root

    property ListModel history: ListModel {}
    property ListModel popups: ListModel {}
    property var entries: []
    property int unreadCount: 0
    property int storedSerial: 0
    // Notifications whose action buttons stay usable from the notification center, by id. The popup
    // timing out must not close them: the sender (a screen recording's Watch / Show in folder) is still
    // waiting for the answer.
    property var live: ({})
    // Do Not Disturb keeps notifications in the history but shows no popup, except critical ones.
    property bool doNotDisturb: false
    readonly property string countText: history.count > 99 ? "99+" : String(history.count)
    function toggleDoNotDisturb() { doNotDisturb = !doNotDisturb; }
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
        return screens.find(screen => screen.name === Compositor.focusedMonitorName)?.name
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

    function actionable(notification) {
        return !notification.transient && notification.appName !== timerApp
            && notification.actions.some(action => action.identifier !== "default");
    }

    // Keeps an actionable notification answerable after its popup is gone; false when it has no buttons to keep.
    function retain(notification) {
        if (!actionable(notification)) return false;
        const id = notification.id;
        if (live[id] === notification) return true;
        notification.tracked = true;
        live = Object.assign({}, live, {[id]: notification});
        notification.closed.connect(() => {
            if (live[id] !== notification) return;
            const rest = Object.assign({}, live);
            delete rest[id];
            live = rest;
        });
        return true;
    }

    // Buttons the center shows for a notification card: the live notification's actions, never "default".
    function actionsFor(notificationId) {
        return (live[notificationId]?.actions ?? []).filter(action => action.identifier !== "default");
    }

    function invokeAction(notificationId, identifier) {
        const entry = entries.find(item => item.notificationId === notificationId);
        const action = (entry ? entry.actions : live[notificationId]?.actions ?? [])
            .find(item => item.identifier === identifier);
        if (!action) return;
        if (entry) { entry.invoke(action); return; }
        const notification = live[notificationId];
        const resident = notification.resident;
        action.invoke();
        // A sender usually closes its notification as soon as it is answered; only close what is still open.
        if (!resident && live[notificationId] === notification) notification.dismiss();
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

    // Spotify announces every track change. While the media panel is open, or the floating lyrics card
    // is (and the lyrics are not also projected onto the island clock), the player is already on
    // screen, so the popup would only repeat it. The notification still goes to the history.
    readonly property string mediaNotificationApp: "spotify-media-controls"
    // A timer's alert was asked for by the user, so Do Not Disturb does not hold it back.
    readonly property string timerApp: "Island Timer"
    // The hint a timer's alert carries: the id of the timer, so its buttons reach the right one.
    readonly property string timerHint: "x-island-timer"
    function mediaNotificationCovered(notification) {
        if (notification.appName !== mediaNotificationApp) return false;
        if (IslandState.mode === IslandState.mediaControlsMode) return true;
        return IslandState.lyricsOpen && IslandState.lyricsClockMonitor === "";
    }

    function receive(notification) {
        notification.tracked = true;
        const retained = retain(notification);
        const existing = entries.find(entry => entry.notificationId === notification.id);
        if (existing) { promote(existing); return; }
        if (mediaNotificationCovered(notification)
                || (doNotDisturb && notification.urgency !== NotificationUrgency.Critical
                    && notification.appName !== timerApp)) {
            updateHistory({
                notification: notification, notificationId: notification.id, app: notification.appName,
                summary: notification.summary, body: notification.body, icon: getAppIcon(notification),
                image: imageSource(notification.image)
            });
            notification.tracked = retained;
            return;
        }
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
        const shown = entries.map(entry => entry.notificationId);
        for (const entry of entries.slice()) entry.dismiss();
        for (const [id, notification] of Object.entries(live)) if (!shown.includes(Number(id))) notification.dismiss();
        history.clear();
        unreadCount = 0;
        storeCommand(["clear"]);
    }

    function forget(index, removeStored) {
        if (index < 0 || index >= history.count) return;
        const snapshot = history.get(index);
        const entry = entries.find(item => item.notificationId === snapshot.notificationId);
        if (entry) entry.dismiss();
        else live[snapshot.notificationId]?.dismiss();
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
            const id = Number(notificationId);
            const entry = root.entries.find(item => item.notificationId === id);
            if (entry) root.promote(entry);
            // A notification kept for its buttons has no entry left; its update shows again like a new one.
            else if (root.live[id]) root.receive(root.live[id]);
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
