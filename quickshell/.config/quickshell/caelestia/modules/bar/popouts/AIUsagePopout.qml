pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

ColumnLayout {
    id: root

    readonly property var entry: AIUsage.selectedEntry
    readonly property int minimumDetailsHeight: 340
    readonly property int maximumDetailsHeight: 560

    width: 440
    implicitWidth: width
    spacing: Tokens.spacing.small

    Component.onCompleted: AIUsage.refresh()

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "psychology"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.large
            fill: 1
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("AI Usage")
            font: Tokens.font.title.medium
        }

        IconTextButton {
            text: AIUsage.loading ? Tr.tr("Updating") : Tr.tr("Retry")
            icon: "refresh"
            type: IconTextButton.Tonal
            enabled: !AIUsage.loading
            onClicked: AIUsage.refresh()
        }
    }

    StyledRect {
        Layout.fillWidth: true
        visible: AIUsage.stale || AIUsage.refreshError.length > 0 || root.entry?.stale === true
        Layout.preferredHeight: visible ? staleRow.implicitHeight + Tokens.padding.small * 2 : 0
        radius: Tokens.rounding.medium
        color: Colours.palette.m3errorContainer

        RowLayout {
            id: staleRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "warning"
                color: Colours.palette.m3onErrorContainer
            }

            StyledText {
                Layout.fillWidth: true
                text: AIUsage.refreshError.length > 0 ? AIUsage.refreshError : root.entry?.stale ? Tr.tr("Provider report is stale") : Tr.tr("Showing the last report; it is stale")
                color: Colours.palette.m3onErrorContainer
                wrapMode: Text.Wrap
            }
        }
    }

    StyledRect {
        Layout.fillWidth: true
        visible: AIUsage.availableEntries.length > 0
        Layout.preferredHeight: visible ? providerColumn.implicitHeight + Tokens.padding.small * 2 : 0
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

        ColumnLayout {
            id: providerColumn

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.leftMargin: Tokens.padding.extraSmall
                text: Tr.tr("Providers and accounts")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            StyledListView {
                id: providerList

                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                implicitHeight: Math.min(contentHeight, 176)
                clip: true
                spacing: Tokens.spacing.extraSmall
                model: AIUsage.availableEntries

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: providerList
                }

                delegate: StyledRect {
                    id: providerItem

                    required property var modelData
                    readonly property bool selected: AIUsage.selectedId === modelData.id
                    readonly property string subtitle: modelData.plan || (modelData.name !== modelData.displayName ? modelData.name : modelData.id)

                    width: providerList.width
                    height: implicitHeight
                    implicitHeight: providerLabels.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.medium
                    color: selected ? Colours.palette.m3secondaryContainer : "transparent"

                    StateLayer {
                        radius: providerItem.radius
                        onClicked: AIUsage.selectEntry(providerItem.modelData.id)
                    }

                    RowLayout {
                        id: providerLabels

                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.small
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: providerItem.modelData.displayName
                                color: providerItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                text: providerItem.subtitle
                                color: providerItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        StyledText {
                            visible: providerItem.modelData.stale
                            text: Tr.tr("Stale")
                            color: Colours.palette.m3tertiary
                            font: Tokens.font.label.small
                        }
                    }
                }
            }
        }
    }

    StyledFlickable {
        id: detailsFlickable

        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(root.minimumDetailsHeight, Math.min(details.implicitHeight, root.maximumDetailsHeight))
        clip: true
        contentWidth: width
        contentHeight: Math.max(details.implicitHeight, height)
        flickableDirection: Flickable.VerticalFlick

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: detailsFlickable
        }

        ColumnLayout {
            id: details

            width: detailsFlickable.width
            height: Math.max(implicitHeight, detailsFlickable.height)
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                visible: !AIUsage.hasReport
                text: AIUsage.loading ? Tr.tr("Loading provider usage…") : Tr.tr("No usage report yet. Retry to check providers.")
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                visible: AIUsage.hasReport && AIUsage.availableEntries.length === 0
                text: Tr.tr("No available providers reported usage.")
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.Wrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !!root.entry
                spacing: Tokens.spacing.small

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: root.entry?.displayName ?? ""
                        font: Tokens.font.title.medium
                        wrapMode: Text.Wrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: root.entry?.plan ?? ""
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: 0
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Last update")
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        text: root.entry?.fetchedAtMs !== null && root.entry?.fetchedAtMs !== undefined ? Qt.formatDateTime(new Date(root.entry.fetchedAtMs), GlobalConfig.services.useTwelveHourClock ? "MMM d, h:mm AP" : "MMM d, HH:mm") : Tr.tr("Unavailable")
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: 0
                }

                StyledRect {
                    Layout.fillWidth: true
                    visible: root.entry?.credits.length > 0
                    implicitHeight: creditsLabel.implicitHeight + Tokens.padding.medium
                    color: Colours.palette.m3surfaceContainerLow
                    radius: Tokens.rounding.medium

                    RowLayout {
                        id: creditsLabel

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Credits")
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: root.entry?.credits ?? ""
                            wrapMode: Text.Wrap
                        }
                    }
                }

                Item {
                    visible: root.entry?.credits.length > 0
                    Layout.fillHeight: visible
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: 0
                }

                Repeater {
                    model: root.entry?.sections ?? []

                    delegate: ColumnLayout {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        Item {
                            Layout.fillHeight: true
                            Layout.minimumHeight: 0
                            Layout.preferredHeight: 0
                        }

                        AIUsageSection {
                            Layout.fillWidth: true
                            section: modelData
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: (root.entry?.sections.length ?? 0) === 0
                    text: Tr.tr("No quota details are available for this provider.")
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
