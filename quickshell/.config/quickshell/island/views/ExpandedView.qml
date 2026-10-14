import QtQuick
import "../components"
import "../services"
import "../island"
import "../styles"

Item {
    id: root
    property string monitorName: ""
    readonly property real topHeight: 75
    readonly property bool panelOpen: IslandState.workspacePanelOpen

    implicitWidth: Math.max(520, center.implicitWidth + 2 * (leftSection.width + 36), panelOpen ? workspacePanel.implicitWidth : 0)
    implicitHeight: topHeight + (panelOpen ? workspacePanel.implicitHeight : 0)

    // The clock row keeps its own fixed height so opening the section never moves the clock.
    Item {
        id: top
        width: parent.width
        height: root.topHeight

        Row {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            LeftSection { id: leftSection; width: 130; anchors.verticalCenter: parent.verticalCenter }
            Item {
                width: parent.width - leftSection.width - rightSection.width
                height: parent.height
            }
            RightSection {
                id: rightSection
                width: 128
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        CenterSection {
            id: center
            objectName: "expanded-clock-group"
            expanded: true
            lyricsActive: root.monitorName !== "" && IslandState.lyricsClockMonitor === root.monitorName
            anchors.centerIn: parent
        }
    }

    WorkspacePanel {
        id: workspacePanel
        monitorName: root.monitorName
        y: root.topHeight
        width: parent.width
        // Fades with the island's height so the section never shows outside the capsule.
        opacity: root.panelOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
    }
}
