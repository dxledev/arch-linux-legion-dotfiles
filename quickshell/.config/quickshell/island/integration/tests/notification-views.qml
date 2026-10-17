import QtQuick
import Quickshell
import Quickshell.Io
import "../../island"
import "../../windows"
import "../../services"
import "../../styles"
import "../../components"

ShellRoot {
    id: root

    readonly property var service: NotificationService

    function capsules(item) {
        let result = [];
        if (item.objectName === "notification-capsule") result.push(item);
        for (const child of item.children || []) result = result.concat(capsules(child));
        return result;
    }

    function texts(item) {
        let result = [];
        if (item.objectName === "notification-summary" || item.objectName === "notification-body")
            result.push({name: item.objectName, text: item.text, format: item.textFormat});
        for (const child of item.children || []) result = result.concat(texts(child));
        return result;
    }

    function actionButtons(item) {
        let result = [];
        if ((item.objectName || "").startsWith("notification-action-")) result.push(item);
        for (const child of item.children || []) result = result.concat(actionButtons(child));
        return result;
    }

    function named(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    function rings(item) {
        let result = [];
        if (item.objectName === "notification-countdown-ring") result.push(item);
        for (const child of item.children || []) result = result.concat(rings(child));
        return result;
    }

    NotificationWindow {
        id: window
        screen: Quickshell.screens[0]
        islandTop: 10
        islandBottom: 43
        islandWidth: 160
    }

    // The newest history card, as the notification center draws it.
    FloatingWindow {
        visible: true
        implicitWidth: 400
        implicitHeight: 160
        NotificationCard {
            id: card
            width: 400
            notification: NotificationService.history.count > 0 ? NotificationService.history.get(0)
                : {notificationId: 0, app: "", summary: "", body: "", icon: "", image: "", time: ""}
        }
    }

    IslandTooltip {
        id: tooltip
        parent: window.contentItem
        text: "Dismiss notification"
    }

    IpcHandler {
        target: "notificationTest"
        function ready(): bool { return ThemeService.ready; }
        function snapshot(): string {
            return JSON.stringify({
                history: NotificationService.history.count,
                historySummaries: [...Array(NotificationService.history.count).keys()]
                    .map(index => NotificationService.history.get(index).summary),
                unread: NotificationService.unreadCount,
                popups: NotificationService.popups.count,
                live: Object.keys(NotificationService.live).map(Number),
                cardFits: (() => { const column = root.named(card, "notification-card-text"); return column.implicitHeight > 60 && column.implicitHeight <= column.height; })(),
                cardActions: root.actionButtons(card).map(button => button.text),
                tooltip: {opened: tooltip.opened, background: tooltip.background.color.toString(),
                    foreground: tooltip.contentItem.color.toString(), radius: tooltip.background.radius,
                    height: tooltip.background.height},
                texts: root.texts(window.contentItem),
                rings: root.rings(window.contentItem).map(ring => ({
                    visible: ring.visible, width: ring.width, height: ring.height,
                    progress: ring.progress, z: ring.z
                })),
                entries: NotificationService.entries.map(entry => ({
                    id: entry.notificationId, summary: entry.summary, body: entry.body,
                    closed: entry.closed, popup: entry.popup, hovered: entry.hovered,
                    remaining: entry.remaining, monitor: entry.monitorName,
                    duration: entry.totalDuration, countdown: entry.countdownProgress,
                    actions: entry.actions.map(action => action.identifier)
                })),
                window: {visible: window.visible, active: window.popupActive, width: window.width, top: window.popupTop,
                    height: window.height, zone: window.exclusiveZone, focusable: window.focusable,
                    regions: window.mask.regions.length, front: window.frontEntry?.notificationId,
                    landingY: window.landingY, islandHeight: window.islandHeight},
                capsules: root.capsules(window.contentItem).map(capsule => ({
                    id: capsule.parent.entry.notificationId,
                    width: capsule.width, y: capsule.y, opacity: capsule.opacity,
                    height: capsule.height, fullHeight: capsule.parent.fullHeight,
                    originY: capsule.parent.originY, startHeight: capsule.parent.startHeight,
                    depth: capsule.parent.stackIndex, z: capsule.parent.z, visible: capsule.parent.visible,
                    radius: capsule.radius, background: capsule.color.toString(),
                    progress: capsule.parent.progress
                }))
            });
        }
        function hover(paused: bool): void { NotificationService.entries[0].hovered = paused; }
        function showTooltip(): void { tooltip.open(); }
        function hideTooltip(): void { tooltip.close(); }
        function dismiss(): void { NotificationService.entries[0].dismiss(); }
        function invoke(): void {
            const entry = NotificationService.entries[0];
            entry.invoke(entry.actions.find(action => action.identifier === "test"));
        }
        function clickCardAction(identifier: string): void {
            root.actionButtons(card).find(button => button.objectName === "notification-action-" + identifier)?.clicked();
        }
        function timeout(milliseconds: int): void {
            ThemeService.settings = Object.assign({}, ThemeService.settings, {notificationTimeout: milliseconds});
        }
        function markRead(): void { NotificationService.markRead(); }
        function moveAway(): void { NotificationService.entries[0].monitorName = "other-monitor"; }
        function moveBack(): void { NotificationService.entries[0].monitorName = window.monitorName; }
        function clear(): void { NotificationService.clear(); }
        function media(state: string): void {
            IslandState.mode = state === "panel" ? IslandState.mediaControlsMode : IslandState.defaultMode;
            IslandState.lyricsOpen = state === "lyrics" || state === "lyrics-clock";
            IslandState.lyricsClockMonitor = state === "lyrics-clock" ? window.monitorName : "";
        }
        function removeFirst(): void { NotificationService.remove(0); }
        function expanded(): void { window.islandBottom = 200; window.islandWidth = 560; }
        function settings(): void {
            ThemeService.settings = Object.assign({}, ThemeService.settings, {
                notificationWidth: 480, notificationMargin: 20, notificationSlideDistance: 40,
                notificationAnimationDuration: 150, notificationStartWidthPercent: 25,
                radius: 18, opacity: 0.8
            });
        }
    }
}
