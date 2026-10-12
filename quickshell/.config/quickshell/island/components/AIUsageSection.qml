pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../styles"

ColumnLayout {
    id: root

    required property var section
    property double clockNow: Date.now()
    property bool clock12Hour: false

    objectName: "ai-usage-section"
    visible: section.type !== "spacer"
    spacing: 8

    readonly property bool warning: /warning|warn|error|failed|expired/i.test(warningText())

    function warningText() {
        const values = [String(section.label ?? ""), String(section.value ?? "")];
        const body = section.body ?? [];
        for (let index = 0; index < (body.length ?? 0); index++)
            values.push(String(body[index]));
        return values.join(" ");
    }

    AIUsageMetric {
        Layout.fillWidth: true
        visible: root.section.type === "metric" && !!root.section.metric
        metric: root.section.metric ?? ({})
        clockNow: root.clockNow
        clock12Hour: root.clock12Hour
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.section.type === "text" || root.section.type === "block"
        implicitHeight: content.implicitHeight + 24
        radius: 14
        color: root.warning ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12) : Theme.surface
        border.width: root.warning ? 1 : 0
        border.color: Theme.warning

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            UiText {
                Layout.fillWidth: true
                visible: String(root.section.label ?? "").length > 0
                text: root.section.label ?? ""
                textFormat: Text.PlainText
                color: root.warning ? Theme.warning : Theme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            UiText {
                Layout.fillWidth: true
                visible: root.section.type === "text" && String(root.section.value ?? "").length > 0
                text: root.section.value ?? ""
                textFormat: Text.PlainText
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }

            Repeater {
                model: root.section.type === "block" ? root.section.body ?? [] : []

                UiText {
                    id: bodyLine
                    required property string modelData
                    Layout.fillWidth: true
                    text: bodyLine.modelData
                    textFormat: Text.PlainText
                    color: root.warning ? Theme.textPrimary : Theme.textSecondary
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
