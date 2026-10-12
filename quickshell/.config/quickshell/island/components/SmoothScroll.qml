import QtQuick
import "../services"

Item {
    id: root

    required property Flickable scrollTarget
    // Horizontal targets scroll contentX; vertical wheel notches still drive them.
    property bool horizontal: false
    // Lets a view take over wheel input while keeping the smoothed programmatic scrolling.
    property bool wheelEnabled: true
    property int animationDuration: ThemeService.settings.scrollAnimationDuration ?? 180
    property real wheelStep: ThemeService.settings.scrollWheelStep ?? 64
    property real destination: 0
    property real scrollPosition: 0
    property bool synchronizing: false
    property bool updatingContent: false
    readonly property bool animating: animation.running

    objectName: "smooth-scroll"

    function contentPosition() {
        return horizontal ? scrollTarget.contentX : scrollTarget.contentY;
    }

    function setContentPosition(position) {
        if (horizontal) scrollTarget.contentX = position;
        else scrollTarget.contentY = position;
    }

    function boundedPosition(position) {
        // Match Flickable's own bounds, which include its leading and trailing margins.
        const start = horizontal ? scrollTarget.originX - scrollTarget.leftMargin : scrollTarget.originY - scrollTarget.topMargin;
        const extent = horizontal ? scrollTarget.leftMargin + scrollTarget.contentWidth + scrollTarget.rightMargin
            : scrollTarget.topMargin + scrollTarget.contentHeight + scrollTarget.bottomMargin;
        const viewport = horizontal ? scrollTarget.width : scrollTarget.height;
        return Math.max(start, Math.min(start + Math.max(0, extent - viewport), position));
    }

    function synchronize() {
        synchronizing = true;
        destination = contentPosition();
        scrollPosition = destination;
        synchronizing = false;
    }

    function scrollBy(distance, precise = false) {
        if (!scrollTarget.interactive || scrollTarget.dragging || !distance) return false;
        const current = animating && !precise ? destination : contentPosition();
        const next = boundedPosition(current + distance);
        if (Math.abs(next - current) < 0.01) return false;
        scrollTarget.cancelFlick();
        if (precise || animationDuration <= 0) {
            animation.stop();
            setContentPosition(next);
            synchronize();
        } else {
            if (!animating) synchronize();
            destination = next;
            scrollPosition = next;
        }
        return true;
    }

    // Scrolls to an absolute position, measured from where any running animation will land.
    function scrollTo(position, precise = false) {
        return scrollBy(position - (animating && !precise ? destination : contentPosition()), precise);
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
            setContentPosition(boundedPosition(scrollPosition));
            updatingContent = false;
        }
    }
    Component.onCompleted: synchronize()
    onHorizontalChanged: { animation.stop(); synchronize(); }

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
        enabled: root.wheelEnabled && root.scrollTarget.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            // Horizontal targets also accept sideways wheels and touchpad swipes.
            const pixel = root.horizontal && event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.pixelDelta.y;
            const angle = root.horizontal && event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y;
            const precise = pixel !== 0;
            const distance = precise ? -pixel : -angle / 120 * root.wheelStep;
            event.accepted = root.scrollBy(distance, precise);
        }
    }

    Connections {
        target: root.scrollTarget
        function onContentYChanged() {
            if (!root.horizontal && !root.updatingContent) { animation.stop(); root.synchronize(); }
        }
        function onContentXChanged() {
            if (root.horizontal && !root.updatingContent) { animation.stop(); root.synchronize(); }
        }
        function onDraggingChanged() {
            if (root.scrollTarget.dragging) { animation.stop(); root.synchronize(); }
        }
        function onContentHeightChanged() { root.updateBounds(); }
        function onHeightChanged() { root.updateBounds(); }
        function onOriginYChanged() { root.updateBounds(); }
        function onContentWidthChanged() { if (root.horizontal) root.updateBounds(); }
        function onWidthChanged() { if (root.horizontal) root.updateBounds(); }
        function onOriginXChanged() { if (root.horizontal) root.updateBounds(); }
    }
}
