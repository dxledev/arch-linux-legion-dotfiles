pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.services
import qs.modules.nexus

Item {
    id: root

    required property NexusState nState
    required property string query
    property var selectedResult

    VerticalFadeListView {
        id: results

        anchors.fill: parent
        topMargin: Tokens.padding.large
        bottomMargin: Tokens.padding.large
        spacing: Tokens.spacing.extraSmall
        cacheBuffer: height

        model: ScriptModel {
            values: NexusSearchRegistry.query(root.query)
        }

        delegate: StyledRect {
            id: resultItem

            required property var modelData
            required property int index

            readonly property bool isCurrentLocation: modelData === root.selectedResult
            readonly property bool isFirst: index === 0
            readonly property bool isLast: index === results.count - 1

            anchors.left: ListView.view.contentItem.left
            anchors.right: ListView.view.contentItem.right
            implicitHeight: {
                const height = resultLayout.implicitHeight + resultLayout.anchors.margins * 2;
                return height % 2 === 0 ? height : height + 1;
            }
            color: isCurrentLocation ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            topLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentLocation ? Tokens.rounding.extraLargeIncreased : isFirst ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
            topRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentLocation ? Tokens.rounding.extraLargeIncreased : isFirst ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
            bottomLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentLocation ? Tokens.rounding.extraLargeIncreased : isLast ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
            bottomRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentLocation ? Tokens.rounding.extraLargeIncreased : isLast ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

            RadiusBehavior on topLeftRadius {}
            RadiusBehavior on topRightRadius {}
            RadiusBehavior on bottomLeftRadius {}
            RadiusBehavior on bottomRightRadius {}

            StateLayer {
                id: stateLayer

                anchors.fill: parent
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius
                bottomRightRadius: parent.bottomRightRadius
                onClicked: {
                    root.selectedResult = resultItem.modelData;
                    root.nState.navigateTo(resultItem.modelData.pageIndex, resultItem.modelData.subPagePath);
                }
            }

            RowLayout {
                id: resultLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledRect {
                    Layout.fillHeight: true
                    Layout.topMargin: -1
                    Layout.bottomMargin: -1
                    implicitWidth: height
                    radius: Tokens.rounding.full
                    color: resultItem.isCurrentLocation ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 1
                        text: resultItem.modelData.icon
                        color: resultItem.isCurrentLocation ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                        fontStyle: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                        grade: 25
                        fill: 1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: resultItem.modelData.label
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: resultItem.modelData.breadcrumb
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: resultItem.modelData.description.length > 0
                        text: resultItem.modelData.description
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    component RadiusBehavior: Behavior {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        visible: results.count === 0
        spacing: Tokens.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "search_off"
            color: Colours.palette.m3outline
            fontStyle: Tokens.font.icon.large
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Tr.tr("No settings found")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.medium
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Tr.tr("Try a different search term")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
        }
    }
}
