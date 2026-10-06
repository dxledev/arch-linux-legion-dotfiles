pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../styles"
import "../core"
import "../components"
import "../services"

Item {
    id: root
    property string monitorName: ""
    readonly property var brightnessRows: StatusManager.brightnessForScreen(monitorName)
    readonly property bool brightnessLabels: ThemeService.islandScreens.length === 1
    readonly property bool textStatus: StatusManager.mode === "keyboard" || StatusManager.mode === "nightlight"
    implicitWidth: {
        switch (StatusManager.mode) {
        case "workspace": return workspaceView.implicitWidth;
        case "volume": return volumeRow.implicitWidth;
        case "brightness": return Math.max(160, ...brightnessRows.map((event, index) => brightnessRepeater.itemAt(index)?.implicitWidth ?? 0));
        case "nightlight": return Math.max(StatusManager.statusWidth, textRow.implicitWidth + 28);
        case "keyboard": return Math.max(Theme.statusKeyboardWidth, textRow.implicitWidth + 28);
        default: return Theme.statusDefaultWidth;
        }
    }
    implicitHeight: StatusManager.mode === "workspace" ? workspaceView.implicitHeight
        : StatusManager.mode === "brightness" ? brightnessColumn.implicitHeight + (brightnessLabels ? 12 : 0)
        : StatusManager.mode === "volume" || textStatus ? OsdSettings.rowHeight : 33

    WorkspaceView {
        id: workspaceView
        anchors.centerIn: parent
        width: implicitWidth
        height: implicitHeight
        visible: StatusManager.mode === "workspace"
    }
    OsdSliderRow {
        id: volumeRow
        objectName: "volume-osd"
        anchors.centerIn: parent
        width: parent.width
        visible: StatusManager.mode === "volume"
        icon: StatusManager.mode === "volume" ? StatusManager.icon : "󰃠"
        value: Number(StatusManager.value) || 0
    }
    Column {
        id: brightnessColumn
        objectName: "brightness-osd"
        anchors.centerIn: parent
        width: parent.width
        spacing: 6
        visible: StatusManager.mode === "brightness"
        Repeater {
            id: brightnessRepeater
            model: root.brightnessRows
            OsdSliderRow {
                required property var modelData
                width: brightnessColumn.width
                icon: modelData.icon
                value: modelData.value
                label: root.brightnessLabels ? modelData.label : ""
            }
        }
    }
    RowLayout {
        id: textRow
        objectName: "text-osd"
        visible: root.textStatus
        width: implicitWidth
        height: implicitHeight
        anchors.centerIn: parent
        spacing: 10
        Text {
            text: StatusManager.icon
            color: Theme.textPrimary
            font.family: Theme.iconFont
            font.pixelSize: OsdSettings.iconSize
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            objectName: "status-label"
            text: StatusManager.title
            color: Theme.textPrimary
            font.family: OsdSettings.fontFamily
            font.pixelSize: OsdSettings.fontSize
            font.bold: OsdSettings.fontBold
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
