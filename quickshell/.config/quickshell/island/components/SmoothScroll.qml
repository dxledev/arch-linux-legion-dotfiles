import QtQuick
import "../services"

Item {
    id: root

    required property Flickable scrollTarget
    property int animationDuration: ThemeService.settings.scrollAnimationDuration ?? 180
    property real wheelStep: ThemeService.settings.scrollWheelStep ?? 64
    property real destination: 0
    property real scrollPosition: 0
    property bool synchronizing: false
    property bool updatingContent: false
    readonly property bool animating: animation.running

    objectName: "smooth-scroll"

    function boundedPosition(position) {
        return Math.max(scrollTarget.originY, Math.min(scrollTarget.originY
            + Math.max(0, scrollTarget.contentHeight - scrollTarget.height), position));
    }

    function synchronize() {
        synchronizing = true;
        destination = scrollTarget.contentY;
        scrollPosition = destination;
        synchronizing = false;
    }

    function scrollBy(distance, precise = false) {
        if (!scrollTarget.interactive || scrollTarget.dragging || !distance) return false;
        const current = animating && !precise ? destination : scrollTarget.contentY;
        const next = boundedPosition(current + distance);
        if (Math.abs(next - current) < 0.01) return false;
        scrollTarget.cancelFlick();
        if (precise || animationDuration <= 0) {
            animation.stop();
            scrollTarget.contentY = next;
            synchronize();
        } else {
            if (!animating) synchronize();
            destination = next;
            scrollPosition = next;
        }
        return true;
    }

    function updateBounds() {
        if (animating) {
            destination = boundedPosition(destination);
            scrollPosition = destination;
        } else synchronize();
    }

    onScrollPositionChanged: {
        if (!synchronizing) {
            updatingContent = true;
            scrollTarget.contentY = boundedPosition(scrollPosition);
            updatingContent = false;
        }
    }
    Component.onCompleted: synchronize()

    Behavior on scrollPosition {
        enabled: !root.synchronizing && root.animationDuration > 0
        SmoothedAnimation {
            id: animation
            velocity: -1
            duration: root.animationDuration
            maximumEasingTime: root.animationDuration / 2
            reversingMode: SmoothedAnimation.Immediate
        }
    }

    WheelHandler {
        parent: root.scrollTarget
        target: null
        enabled: root.scrollTarget.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const precise = event.pixelDelta.y !== 0;
            const distance = precise ? -event.pixelDelta.y : -event.angleDelta.y / 120 * root.wheelStep;
            event.accepted = root.scrollBy(distance, precise);
        }
    }

    Connections {
        target: root.scrollTarget
        function onContentYChanged() {
            if (!root.updatingContent) { animation.stop(); root.synchronize(); }
        }
        function onDraggingChanged() {
            if (root.scrollTarget.dragging) { animation.stop(); root.synchronize(); }
        }
        function onContentHeightChanged() { root.updateBounds(); }
        function onHeightChanged() { root.updateBounds(); }
        function onOriginYChanged() { root.updateBounds(); }
    }
}
