import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property var list
    required property int index
    property bool reserveDescriptionSpace: true

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        stateOpacity: 0
        onPositionChanged: mouse => root.list.selectFromPointer(root.index, mapToGlobal(mouse.x, mouse.y))
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        MaterialIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            visible: !root.modelData?.glyph
            text: root.modelData?.icon ?? ""
            width: root.modelData?.glyph ? glyph.width : implicitWidth
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
        }

        StyledText {
            id: glyph
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.modelData?.glyph
            text: root.modelData?.glyph ?? ""
            width: 36
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 28
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width
            implicitHeight: name.implicitHeight + (root.reserveDescriptionSpace || desc.text.length > 0 ? desc.implicitHeight : 0)

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
                width: parent.width - Tokens.spacing.medium
                elide: Text.ElideRight
            }

            StyledText {
                id: desc

                text: root.modelData?.desc ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - Tokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }
    }
}
