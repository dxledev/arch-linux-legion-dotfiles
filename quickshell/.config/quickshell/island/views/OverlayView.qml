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
    readonly property bool textStatus: StatusManager.mode === "keyboard" || StatusManager.mode === "nightlight" || StatusManager.mode === "notice"
    implicitWidth: {
        switch (StatusManager.mode) {
        case "workspace": return workspaceView.implicitWidth;
        case "volume": return volumeRow.implicitWidth;
        case "brightness": return Math.max(160, ...brightnessRows.map((event, index) => brightnessRepeater.itemAt(index)?.implicitWidth ?? 0));
        case "nightlight": return Math.max(StatusManager.statusWidth, textRow.implicitWidth + 28);
        case "notice": return Math.max(Theme.statusKeyboardWidth, textRow.implicitWidth + 28);
        case "keyboard": return Math.max(Theme.statusKeyboardWidth, textRow.implicitWidth + 28);
        case "confirm": return StatusManager.statusWidth;
        default: return Theme.statusDefaultWidth;
        }
    }
    implicitHeight: StatusManager.mode === "workspace" ? workspaceView.implicitHeight
        : StatusManager.mode === "brightness" ? brightnessColumn.implicitHeight + (brightnessLabels ? 12 : 0)
        : StatusManager.mode === "confirm" ? confirmRow.implicitHeight + 16
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
    // Keeps clicks beside the buttons from reaching the island's pin toggle.
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: StatusManager.mode === "confirm"
    }
    RowLayout {
        id: confirmRow
        objectName: "confirm-osd"
        visible: StatusManager.mode === "confirm"
        // The accept label sits one button padding inside its pill. The row's right edge moves out by half
        // that, so the pill ends closer to the edge than the question starts and the label sits just inside.
        readonly property real sideMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: sideMargin
        anchors.right: parent.right
        anchors.rightMargin: sideMargin - confirmAccept.padding / 2
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                objectName: "confirm-title"
                Layout.fillWidth: true
                text: StatusManager.title
                color: Theme.textPrimary
                font.family: OsdSettings.fontFamily
                font.pixelSize: OsdSettings.fontSize
                font.bold: OsdSettings.fontBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: StatusManager.confirmDetail.length > 0
                text: StatusManager.confirmDetail
                color: Theme.textSecondary
                font.family: OsdSettings.fontFamily
                font.pixelSize: Math.max(11, OsdSettings.fontSize - 5)
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
        TextActionButton {
            objectName: "confirm-cancel"
            text: "Cancel"
            onClicked: StatusManager.resolveConfirm(false)
        }
        TextActionButton {
            id: confirmAccept
            objectName: "confirm-accept"
            text: StatusManager.confirmAcceptLabel
            danger: true
            onClicked: StatusManager.resolveConfirm(true)
        }
    }
}
