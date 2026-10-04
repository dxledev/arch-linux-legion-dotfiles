pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

PanelWindow {
    id: root

    required property real islandTop
    required property real islandBottom
    required property real islandWidth
    property real islandRadius: 23
    readonly property string monitorName: screen?.name ?? ""
    readonly property real popupTop: islandTop
    readonly property real islandHeight: islandBottom - islandTop
    readonly property real landingY: islandHeight + (ThemeService.settings.notificationMargin ?? 10)
        + (ThemeService.settings.notificationSlideDistance ?? 24)
    readonly property int visibleCards: ThemeService.settings.notificationStackVisible ?? 3
    readonly property real stackSpacing: ThemeService.settings.notificationStackSpacing ?? 8
    property var popupItems: []
    readonly property var frontEntry: NotificationService.entries.find(entry => entry.monitorName === root.monitorName) ?? null
    readonly property var frontPopup: popupItems.find(popup => popup?.entry === root.frontEntry) ?? null
    readonly property bool popupActive: frontEntry !== null

    function updateItems() {
        const items = [];
        for (let index = 0; index < popups.count; index++) {
            const popup = popups.itemAt(index);
            if (popup) items.push(popup);
        }
        popupItems = items;
    }

    function stackIndex(modelIndex) {
        let position = 0;
        for (let index = 0; index < modelIndex; index++) {
            if (NotificationService.popups.get(index).entry.monitorName === root.monitorName) position++;
        }
        return position;
    }

    WlrLayershell.namespace: "island-notifications"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: false
    color: "transparent"
    anchors.top: true
    margins.top: popupTop
    implicitWidth: Math.min(ThemeService.settings.notificationWidth ?? 400, Math.max(1, (screen?.width ?? 1920) - 24))
    implicitHeight: popupActive ? Math.min(landingY + (frontPopup?.fullHeight ?? 80) + (visibleCards - 1) * stackSpacing,
        Math.max(1, (screen?.height ?? 1080) - popupTop - 12)) : 1
    // Keeping the transparent surface mapped avoids a compositor fade on every ejection.
    visible: ThemeService.ready
    mask: Region {
        regions: root.frontPopup?.visible ? [root.frontPopup.inputRegion, islandOcclusion] : []
    }

    Region {
        id: islandOcclusion
        intersection: Intersection.Subtract
        x: (root.width - root.islandWidth) / 2
        width: root.islandWidth
        height: root.islandHeight
        radius: root.islandRadius
    }

    Item {
        anchors.fill: parent
        clip: true
        Repeater {
            id: popups
            model: NotificationService.popups
            onItemAdded: Qt.callLater(root.updateItems)
            onItemRemoved: Qt.callLater(root.updateItems)
            NotificationPopup {
                id: popup
                required property var model
                required property int index
                entry: model.entry
                islandWidth: root.islandWidth
                islandHeight: root.islandHeight
                landingY: root.landingY
                stackIndex: root.stackIndex(index)
                stackSpacing: root.stackSpacing
                frontHeight: root.frontPopup?.fullHeight ?? fullHeight
                width: root.width
                height: root.height
                z: popups.count - index
                visible: entry.monitorName === root.monitorName && stackIndex < root.visibleCards
                readonly property Region inputRegion: Region { item: popup.surface; radius: popup.surface.radius }
            }
        }
    }
}
