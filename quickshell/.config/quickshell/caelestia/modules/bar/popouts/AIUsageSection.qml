pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var section

    readonly property bool warning: /warning|warn|error|failed|expired/i.test(`${section.label ?? ""} ${section.value ?? ""} ${Array.isArray(section.body) ? section.body.join(" ") : ""}`)

    visible: section.type !== "spacer"
    spacing: Tokens.spacing.small

    AIUsageMetric {
        visible: root.section.type === "metric"
        Layout.fillWidth: true
        metric: root.section.metric
    }

    StyledRect {
        Layout.fillWidth: true
        visible: root.section.type === "text" || root.section.type === "block"
        implicitHeight: sectionContent.implicitHeight + Tokens.padding.medium
        color: root.warning ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainerLow
        radius: Tokens.rounding.medium

        ColumnLayout {
            id: sectionContent

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    visible: root.warning
                    text: "warning"
                    color: Colours.palette.m3onTertiaryContainer
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.section.label
                    color: root.warning ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.label.medium
                    visible: text.length > 0
                }

                StyledText {
                    Layout.maximumWidth: 210
                    text: root.section.type === "text" ? root.section.value : ""
                    color: root.warning ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                    visible: text.length > 0
                    wrapMode: Text.Wrap
                }
            }

            Repeater {
                model: root.section.type === "block" ? root.section.body : []

                StyledText {
                    required property string modelData

                    Layout.fillWidth: true
                    text: modelData
                    color: root.warning ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
