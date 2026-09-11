import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property Fonts.Font modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight
    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium

        MaterialIcon {
            id: preview

            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData?.icon ?? "font_download"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
        }

        Column {
            anchors.left: preview.right
            anchors.right: current.left
            anchors.margins: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                width: parent.width
                text: root.modelData?.name ?? ""
                textFormat: Text.PlainText
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                visible: root.modelData?.current ?? false
                text: Tr.tr("Current font")
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
            }
        }

        MaterialIcon {
            id: current

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.modelData?.current ? 1 : 0
            text: "check"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.large
        }
    }
}
