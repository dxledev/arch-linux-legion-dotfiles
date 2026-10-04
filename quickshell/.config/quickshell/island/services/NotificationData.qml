import QtQuick
import Quickshell.Services.Notifications
import "../styles"

QtObject {
    id: root

    required property var notification
    property string monitorName
    required property int notificationId
    property string app: ""
    property string summary: ""
    property string body: ""
    property url icon
    property url image
    readonly property var actions: closed ? [] : notification.actions
    property bool popup: false
    property bool closed: false
    property bool hovered: false
    property real remaining: 0
    property real deadline: 0
    readonly property int animationDuration: ThemeService.settings.notificationAnimationDuration ?? Theme.animationNormal

    signal updated()
    signal finished()

    function restartTimeout() {
        if (closed) return;
        timeout.stop();
        const requested = notification.expireTimeout;
        remaining = requested === 0 || (requested < 0 && notification.urgency === NotificationUrgency.Critical)
            ? 0 : requested > 0 ? requested : (ThemeService.settings.notificationTimeout ?? 5000);
        resumeTimeout();
    }

    function resumeTimeout() {
        if (!closed && !hovered && remaining > 0) {
            deadline = Date.now() + remaining;
            timeout.interval = remaining;
            timeout.start();
        }
    }

    function refresh() {
        if (closed) return;
        app = notification.appName;
        summary = notification.summary;
        body = notification.body;
        icon = NotificationService.getAppIcon(notification);
        image = NotificationService.imageSource(notification.image);
        popup = true;
        updated();
        restartTimeout();
    }

    function closePopup() {
        if (closed) return;
        closed = true;
        popup = false;
        timeout.stop();
        cleanup.restart();
    }

    function dismiss() {
        if (closed) return;
        closePopup();
        notification.dismiss();
    }

    function invoke(action) {
        if (closed) return;
        const resident = notification.resident;
        action.invoke();
        if (!resident) dismiss();
    }

    onHoveredChanged: {
        if (hovered && timeout.running) {
            remaining = Math.max(1, deadline - Date.now());
            timeout.stop();
        } else if (!hovered) resumeTimeout();
    }

    readonly property Timer timeout: Timer {
        onTriggered: {
            root.closePopup();
            root.notification.expire();
        }
    }

    readonly property Timer cleanup: Timer {
        interval: root.animationDuration + 50
        onTriggered: root.finished()
    }

    readonly property Connections changes: Connections {
        target: root.closed ? null : root.notification
        function onClosed() { root.closePopup(); }
        function onSummaryChanged() { Qt.callLater(root.refresh); }
        function onBodyChanged() { Qt.callLater(root.refresh); }
        function onImageChanged() { Qt.callLater(root.refresh); }
        function onAppIconChanged() { Qt.callLater(root.refresh); }
        function onAppNameChanged() { Qt.callLater(root.refresh); }
        function onExpireTimeoutChanged() { Qt.callLater(root.restartTimeout); }
    }
}
