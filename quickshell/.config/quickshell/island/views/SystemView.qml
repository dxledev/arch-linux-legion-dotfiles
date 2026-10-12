import QtQuick
import "../components"
import "../services"
import "../services/SystemMetrics.js" as Metrics
import "../core"
import "../styles"

FocusScope {
    id: root
    objectName: "system-view"
    property int panelPadding: 24
    implicitWidth: 600
    implicitHeight: content.implicitHeight + panelPadding * 2
    Component.onCompleted: forceActiveFocus()
    Keys.onEscapePressed: IslandController.reset()
    SystemInfoService { id: system }
    Column {
        id: content
        x: root.panelPadding; y: root.panelPadding
        width: parent.width - root.panelPadding * 2
        spacing: 18
        PanelHeader { title: "System"; onBack: IslandController.backFromSystem() }
        Row {
            width: parent.width
            spacing: 12
            SystemResourceCard {
                objectName: "system-cpu"
                width: (parent.width - parent.spacing * 2) / 3
                title: "CPU"; usage: system.cpuUsage; history: system.cpuHistory
                ready: system.cpuReady
                detail: system.cpuReady ? "Processor usage" : "Sampling…"
            }
            SystemResourceCard {
                objectName: "system-memory"
                width: (parent.width - parent.spacing * 2) / 3
                title: "Memory"; usage: system.memoryUsage; history: system.memoryHistory
                ready: system.ready
                detail: system.ready ? Metrics.gibibytes(system.sample.memoryUsed) + " / " + Metrics.gibibytes(system.sample.memoryTotal) : "Sampling…"
            }
            SystemResourceCard {
                objectName: "system-storage"
                width: (parent.width - parent.spacing * 2) / 3
                title: "Storage"; usage: system.diskUsage; history: system.diskHistory
                ready: system.sample.diskTotal > 0
                detail: system.sample.diskTotal > 0 ? Metrics.gibibytes(system.sample.diskUsed) + " / " + Metrics.gibibytes(system.sample.diskTotal) : "Sampling…"
            }
        }
        Rectangle {
            width: parent.width
            height: details.implicitHeight + 32
            radius: 18; color: Theme.surface
            Column {
                id: details
                x: 16; y: 16; width: parent.width - 32
                spacing: 8
                UiText { width: parent.width; text: system.hostname + " · Up " + system.uptime; color: Theme.textPrimary; font.pixelSize: 13; elide: Text.ElideRight }
                UiText { width: parent.width; text: system.processor; color: Theme.textSecondary; font.pixelSize: 12; elide: Text.ElideRight }
                UiText { width: parent.width; text: system.error || "Linux " + system.kernel + " · Storage /"; color: system.error ? Theme.danger : Theme.textMuted; font.pixelSize: 11; elide: Text.ElideRight }
            }
        }
    }
}
