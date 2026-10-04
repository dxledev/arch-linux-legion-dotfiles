import QtQuick
import Quickshell
import Quickshell.Io
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
                unread: NotificationService.unreadCount,
                popups: NotificationService.popups.count,
                tooltip: {opened: tooltip.opened, background: tooltip.background.color.toString(),
                    foreground: tooltip.contentItem.color.toString(), radius: tooltip.background.radius,
                    height: tooltip.background.height},
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
        function markRead(): void { NotificationService.markRead(); }
        function moveAway(): void { NotificationService.entries[0].monitorName = "other-monitor"; }
        function moveBack(): void { NotificationService.entries[0].monitorName = window.monitorName; }
        function clear(): void { NotificationService.clear(); }
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
