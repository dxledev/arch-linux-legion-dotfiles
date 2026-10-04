import QtQuick
import QtQuick.Layouts
import "../services"
import "../styles"

Item {
    id: root
    property string icon: ""
    property real value: 0
    property string label: ""
    implicitWidth: sliderRow.implicitWidth + 28
    implicitHeight: content.implicitHeight
    height: implicitHeight

    Column {
        id: content
        width: root.width
        spacing: 2

        Text {
            id: monitorLabel
            objectName: "osd-monitor-label"
            visible: root.label.length > 0
            x: 14
            width: parent.width - 28
            text: root.label
            color: Theme.textSecondary
            font.family: OsdSettings.fontFamily
            font.pixelSize: OsdSettings.fontSize
            font.bold: OsdSettings.fontBold
            elide: Text.ElideRight
        }
        RowLayout {
            id: sliderRow
            x: 14
            width: parent.width - 28
            height: OsdSettings.rowHeight
            spacing: 10
            Text {
                text: root.icon
                color: Theme.textPrimary
                font.family: Theme.iconFont
                font.pixelSize: OsdSettings.iconSize
                Layout.alignment: Qt.AlignVCenter
            }
            Rectangle {
                objectName: "osd-slider"
                Layout.preferredWidth: OsdSettings.sliderWidth
                Layout.fillWidth: true
                Layout.preferredHeight: OsdSettings.sliderHeight
                Layout.alignment: Qt.AlignVCenter
                radius: OsdSettings.sliderRadius
                color: Theme.surface
                Rectangle {
                    objectName: "osd-slider-fill"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    radius: OsdSettings.sliderRadius
                    width: parent.width * Math.max(0, Math.min(1, root.value / 100))
                    color: Theme.accent
                    Behavior on width {
                        NumberAnimation { duration: OsdSettings.sliderAnimationDuration; easing.type: Easing.OutCubic }
                    }
                }
            }
            Text {
                objectName: "osd-percentage"
                visible: OsdSettings.showPercentage || root.value < 0
                text: root.value < 0 ? "Muted" : Math.round(root.value) + "%"
                color: Theme.textPrimary
                font.family: OsdSettings.fontFamily
                font.pixelSize: OsdSettings.fontSize
                font.bold: OsdSettings.fontBold
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
