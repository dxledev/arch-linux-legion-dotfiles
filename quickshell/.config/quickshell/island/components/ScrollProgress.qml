import QtQuick
import "../services"
import "../styles"

Item {
    id: root

    property var scrollTargets: []
    property bool alwaysVisible: ThemeService.settings.scrollProgressAlwaysVisible ?? true
    property int visibleDuration: ThemeService.settings.scrollProgressVisibleDuration ?? 1500
    property bool showOnNonScrollable: ThemeService.settings.scrollProgressShowOnNonScrollable ?? false
    property int animationDuration: ThemeService.settings.scrollProgressAnimationDuration ?? 180
    property bool recentlyActive: false
    readonly property bool moving: scrollTargets.some(target => target && (target.moving || target.scrollAnimationRunning))
    readonly property var metrics: measureProgress()
    readonly property bool scrollable: metrics.scrollable
    readonly property real progress: metrics.progress
    property real displayedProgress: progress

    objectName: "scroll-progress"
    implicitHeight: 2
    opacity: (scrollable || showOnNonScrollable) && (alwaysVisible || recentlyActive || moving) ? 1 : 0

    function measureProgress() {
        let totalHeight = 0;
        let revealedHeight = 0;
        for (const target of scrollTargets) {
            if (!target || target.height <= 0 || target.contentHeight <= target.height + 1) continue;
            const scrollRange = target.contentHeight - target.height;
            const offset = Math.max(0, Math.min(scrollRange, target.contentY - target.originY));
            totalHeight += target.contentHeight;
            revealedHeight += target.height + offset;
        }
        return {scrollable: totalHeight > 0, progress: totalHeight > 0 ? revealedHeight / totalHeight : 1};
    }

    function reveal() {
        recentlyActive = true;
        hideDelay.restart();
    }

    Component.onCompleted: reveal()
    onProgressChanged: reveal()
    onMovingChanged: reveal()
    onVisibleChanged: if (visible) reveal()
    onAlwaysVisibleChanged: reveal()
    onShowOnNonScrollableChanged: reveal()
    onVisibleDurationChanged: if (recentlyActive) hideDelay.restart()

    Rectangle {
        objectName: "scroll-progress-fill"
        width: root.width * root.displayedProgress
        height: root.height
        radius: height / 2
        color: Theme.accent
        antialiasing: true
    }

    Behavior on displayedProgress {
        enabled: !root.moving && root.animationDuration > 0
        SmoothedAnimation {
            velocity: -1
            duration: root.animationDuration
            maximumEasingTime: root.animationDuration / 2
            reversingMode: SmoothedAnimation.Immediate
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic }
    }

    Timer {
        id: hideDelay
        interval: Math.max(1, root.visibleDuration)
        onTriggered: root.recentlyActive = false
    }
}
