import QtQuick
import QtQuick.Controls
import "../styles"

Button {
    id: root
    required property string title
    property string subtitle: ""
    required property url iconSource
    property bool showPin: false
    property bool pinned: false
    property bool pinEnabled: true
    property bool selected: false
    property bool reorderable: false
    property bool dropTarget: false
    readonly property bool reordering: reorderHandler.active
    property real shiftX: 0
    property real shiftY: 0
    // A drag steals the pointer grab, so the Button never sees the release and stays down.
    property bool pressSuppressed: false
    down: pressed && !pressSuppressed
    focusPolicy: Qt.TabFocus
    signal pinClicked()
    signal reorderStarted()
    signal reorderMoved(point scenePosition)
    signal reorderFinished(bool committed)
    implicitHeight: 132
    padding: 18
    hoverEnabled: true
    onPressed: pressSuppressed = false
    onReleased: pressSuppressed = false
    // Lifted while dragged; the grid's layout is untouched so other cards stay put.
    z: reordering ? 2 : 0
    scale: reordering ? 1.04 : 1
    opacity: reordering ? 0.85 : 1
    transform: Translate { x: root.shiftX; y: root.shiftY }
    Behavior on scale { NumberAnimation { duration: Theme.animationFast; easing.type: Theme.animationVertical } }
    Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
    Behavior on shiftX { enabled: !root.reordering; NumberAnimation { duration: Theme.animationFast; easing.type: Theme.animationVertical } }
    Behavior on shiftY { enabled: !root.reordering; NumberAnimation { duration: Theme.animationFast; easing.type: Theme.animationVertical } }
    HoverHandler {
        enabled: root.enabled && root.hovered
        cursorShape: root.reordering ? Qt.ClosedHandCursor : root.reorderable ? Qt.OpenHandCursor : Qt.PointingHandCursor
    }
    // The default drag threshold keeps clicks and pin taps as plain Button input.
    DragHandler {
        id: reorderHandler
        enabled: root.reorderable
        target: null
        property bool canceled: false
        onActiveChanged: {
            if (active) {
                canceled = false;
                root.pressSuppressed = true;
                root.reorderStarted();
                return;
            }
            // Snap back before the view may rebuild this delegate on commit.
            root.shiftX = 0;
            root.shiftY = 0;
            root.reorderFinished(!canceled);
        }
        onCanceled: canceled = true
        onTranslationChanged: {
            if (!active) return;
            root.shiftX = centroid.scenePosition.x - centroid.scenePressPosition.x;
            root.shiftY = centroid.scenePosition.y - centroid.scenePressPosition.y;
            root.reorderMoved(centroid.scenePosition);
        }
    }
    Accessible.name: title
    background: Rectangle {
        radius: 26
        color: root.down ? Theme.buttonPressed : root.hovered ? Theme.surfaceVariant : Theme.surface
        border.width: root.activeFocus || root.selected || root.dropTarget ? 2 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    }
    contentItem: Item {
        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
            SvgIcon { anchors.centerIn: parent; source: root.iconSource; color: Theme.accent; size: 22 }
        }
        SvgIcon {
            id: chevron
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 12
            source: "../assets/icons/chevron-right.svg"
            color: Theme.textMuted
            size: 16
        }
        IconButton {
            objectName: "navigation-card-pin"
            anchors.right: chevron.left
            anchors.rightMargin: 4
            anchors.top: parent.top
            anchors.topMargin: 4
            width: 32
            height: 32
            padding: 7
            visible: root.showPin
            enabled: root.pinEnabled
            opacity: enabled ? 1 : 0.4
            iconSource: root.pinned ? "../assets/icons/pin-filled.svg" : "../assets/icons/pin.svg"
            iconColor: root.pinned ? Theme.accent : Theme.textSecondary
            description: root.pinned ? "Unpin " + root.title : root.pinEnabled ? "Pin " + root.title : "Unpin a submenu first"
            Accessible.checkable: true
            Accessible.checked: root.pinned
            onClicked: root.pinClicked()
        }
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 4
            UiText { width: parent.width; text: root.title; color: Theme.textPrimary; font.pixelSize: 15; font.weight: Font.DemiBold; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
            UiText { width: parent.width; text: root.subtitle; color: Theme.textSecondary; font.pixelSize: 11; elide: Text.ElideRight }
        }
    }
}
