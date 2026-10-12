pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root

    objectName: "ai-usage-view"
    property var usageService: AIUsageService
    readonly property var entries: usageService.availableEntries ?? []
    readonly property var selectedEntry: usageService.selectedEntry ?? null
    property var displayedEntry: usageService.selectedEntry ?? null
    property real providerOpacity: 1
    property bool providerTransitionReady: false
    readonly property bool hasRefreshError: String(usageService.refreshError ?? "").length > 0
    readonly property bool selectedFailed: !!displayedEntry && (displayedEntry.failed === true || String(displayedEntry.error ?? "").length > 0)
    readonly property bool stale: usageService.stale === true || displayedEntry?.stale === true
    readonly property bool showProviderPicker: entries.length > 1
    readonly property int selectedIndex: entries.findIndex(entry => entry.id === usageService.selectedId)
    readonly property int providerFadeOutDuration: Math.max(0, Math.round(Theme.animationFast / 3))
    readonly property int providerFadeInDuration: Math.max(0, Theme.animationFast - providerFadeOutDuration)
    readonly property bool providerTransitionRunning: providerTransition.running

    implicitWidth: 520
    implicitHeight: content.implicitHeight + 44
    focus: true

    Component.onCompleted: {
        displayedEntry = selectedEntry;
        providerTransitionReady = true;
        forceActiveFocus();
        usageService.refresh();
    }

    function selectProvider(index) {
        if (index >= 0 && index < entries.length)
            usageService.selectEntry(entries[index].id);
    }

    function resetDetailScroll() {
        detailsFlickable.cancelFlick();
        detailsFlickable.contentY = 0;
    }

    function transitionToSelectedProvider() {
        if (!providerTransitionReady) {
            displayedEntry = selectedEntry;
            return;
        }

        providerTransition.stop();
        providerTransition.start();
    }

    onSelectedEntryChanged: {
        const sameProvider = (displayedEntry?.id ?? "") === (selectedEntry?.id ?? "");
        if (!providerTransitionReady || (!providerTransition.running && sameProvider)) {
            displayedEntry = selectedEntry;
        } else if (!sameProvider) {
            transitionToSelectedProvider();
        }
    }

    function syncDisplayedEntry() {
        if (providerTransitionReady && !providerTransition.running && (displayedEntry?.id ?? "") === (selectedEntry?.id ?? ""))
            displayedEntry = selectedEntry;
    }

    Keys.onEscapePressed: IslandController.reset()

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        PanelHeader {
            Layout.fillWidth: true
            title: "AI Usage"
            scrollTargets: [detailsFlickable]
            onBack: IslandController.openNavigation()
        }

        RowLayout {
            objectName: "ai-usage-provider-picker-row"
            Layout.fillWidth: true
            spacing: 10

            UiText {
                visible: root.showProviderPicker
                text: "Provider"
                color: Theme.textSecondary
                font.pixelSize: 13
            }

            ComboBox {
                id: providerPicker
                objectName: "ai-usage-provider-picker"
                visible: root.showProviderPicker
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                model: root.entries.map(entry => entry.displayName)
                currentIndex: root.selectedIndex
                onActivated: index => root.selectProvider(index)
                Accessible.name: "AI usage provider"
                leftPadding: 14
                rightPadding: 38

                contentItem: UiText {
                    text: providerPicker.currentText
                    textFormat: Text.PlainText
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                indicator: SvgIcon {
                    x: providerPicker.width - width - 15
                    anchors.verticalCenter: parent.verticalCenter
                    source: "../assets/icons/chevron-right.svg"
                    size: 16
                    rotation: 90
                    color: Theme.textSecondary
                }

                background: Rectangle {
                    radius: 14
                    color: providerPicker.down ? Theme.buttonPressed : Theme.surfaceVariant
                    border.width: providerPicker.activeFocus ? 2 : 0
                    border.color: Theme.accent
                }

                HoverHandler {
                    objectName: "ai-usage-provider-cursor"
                    enabled: providerPicker.enabled
                    cursorShape: Qt.PointingHandCursor
                }

                delegate: ItemDelegate {
                    id: providerDelegate
                    required property string modelData
                    required property int index
                    width: providerPicker.width - 12
                    height: 38
                    objectName: "ai-usage-provider-entry-" + (root.entries[index]?.id ?? index)
                    highlighted: providerPicker.highlightedIndex === index
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                    contentItem: UiText {
                        text: providerDelegate.modelData
                        textFormat: Text.PlainText
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        radius: 12
                        color: providerDelegate.highlighted ? Theme.surfaceVariant : "transparent"
                    }
                }

                popup: Popup {
                    y: providerPicker.height + 5
                    width: providerPicker.width
                    implicitHeight: Math.min(contentItem.implicitHeight + 12, 220)
                    padding: 6
                    background: Rectangle {
                        radius: 18
                        color: Theme.surface
                        border.color: Theme.surfaceVariant
                    }
                    contentItem: ListView {
                        id: providerOptions
                        clip: true
                        implicitHeight: contentHeight
                        model: providerPicker.popup.visible ? providerPicker.delegateModel : null
                        currentIndex: providerPicker.highlightedIndex
                        SmoothScroll {
                            scrollTarget: providerOptions
                        }
                        ScrollBar.vertical: ScrollBar {}
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                visible: !root.showProviderPicker
            }

            IslandButton {
                objectName: "ai-usage-refresh"
                cursorShape: Qt.PointingHandCursor
                text: root.usageService.loading ? "Refreshing…" : "Refresh"
                enabled: !root.usageService.loading
                Accessible.name: root.usageService.loading ? "Refreshing AI usage" : "Refresh AI usage"
                onClicked: root.usageService.refresh()
            }
        }

        UiText {
            objectName: "ai-usage-loading"
            Layout.fillWidth: true
            visible: root.usageService.loading
            text: "Loading provider usage…"
            color: Theme.textSecondary
            font.pixelSize: 12
        }

        Rectangle {
            objectName: "ai-usage-status"
            Layout.fillWidth: true
            visible: root.hasRefreshError || root.selectedFailed || root.stale
            opacity: root.providerOpacity
            implicitHeight: statusContent.implicitHeight + 20
            radius: 14
            color: root.hasRefreshError || root.selectedFailed ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.12) : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12)
            border.width: 1
            border.color: root.hasRefreshError || root.selectedFailed ? Theme.danger : Theme.warning

            ColumnLayout {
                id: statusContent
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                UiText {
                    objectName: "ai-usage-error"
                    Layout.fillWidth: true
                    visible: root.hasRefreshError || root.selectedFailed
                    text: root.hasRefreshError ? root.usageService.refreshError : root.displayedEntry?.error ?? "Provider report is unavailable."
                    textFormat: Text.PlainText
                    color: Theme.danger
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }

                UiText {
                    objectName: "ai-usage-stale"
                    Layout.fillWidth: true
                    visible: root.stale
                    text: root.displayedEntry?.stale ? "This provider report is stale." : "Showing the last report; it is stale."
                    color: Theme.warning
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
            }
        }

        Flickable {
            id: detailsFlickable
            objectName: "ai-usage-details-scroll"
            Layout.fillWidth: true
            opacity: root.providerOpacity
            Layout.minimumHeight: 72
            Layout.preferredHeight: Math.min(Math.max(detailsContent.implicitHeight, 72), 440)
            contentWidth: width
            contentHeight: Math.max(height, detailsContent.implicitHeight)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            SmoothScroll {
                scrollTarget: detailsFlickable
            }
            ScrollBar.vertical: ScrollBar {}

            ColumnLayout {
                id: detailsContent
                width: detailsFlickable.width
                spacing: 12

                UiText {
                    objectName: "ai-usage-empty"
                    Layout.fillWidth: true
                    visible: !root.usageService.loading && !root.displayedEntry
                    text: root.usageService.hasReport ? "No available providers reported usage." : "No usage report yet. Refresh to check providers."
                    textFormat: Text.PlainText
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }

                ColumnLayout {
                    objectName: "ai-usage-provider-details"
                    Layout.fillWidth: true
                    visible: !!root.displayedEntry
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        UiText {
                            objectName: "ai-usage-provider-title"
                            Layout.fillWidth: true
                            text: root.displayedEntry?.displayName ?? ""
                            textFormat: Text.PlainText
                            color: Theme.textPrimary
                            font.pixelSize: 19
                            font.weight: Font.DemiBold
                            wrapMode: Text.Wrap
                        }

                        UiText {
                            Layout.fillWidth: true
                            visible: String(root.displayedEntry?.plan ?? "").length > 0
                            text: root.displayedEntry?.plan ?? ""
                            textFormat: Text.PlainText
                            color: Theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.displayedEntry?.fetchedAtMs !== null && root.displayedEntry?.fetchedAtMs !== undefined
                        spacing: 8

                        UiText {
                            Layout.fillWidth: true
                            text: "Last update"
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }

                        UiText {
                            text: Qt.formatDateTime(new Date(Number(root.displayedEntry?.fetchedAtMs)), ThemeService.settings.clock12Hour ? "MMM d, h:mm AP" : "MMM d, HH:mm")
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        objectName: "ai-usage-credits"
                        Layout.fillWidth: true
                        visible: !root.selectedFailed && String(root.displayedEntry?.credits ?? "").length > 0
                        implicitHeight: creditRow.implicitHeight + 24
                        radius: 14
                        color: Theme.surface

                        RowLayout {
                            id: creditRow
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            UiText {
                                text: "Credits"
                                color: Theme.textSecondary
                                font.pixelSize: 12
                            }

                            UiText {
                                Layout.fillWidth: true
                                text: root.displayedEntry?.credits ?? ""
                                textFormat: Text.PlainText
                                color: Theme.textPrimary
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignRight
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    ColumnLayout {
                        objectName: "ai-usage-metrics"
                        Layout.fillWidth: true
                        visible: !root.selectedFailed && root.displayedEntry?.sections?.length > 0
                        spacing: 12

                        ColumnLayout {
                            objectName: "ai-usage-sections"
                            Layout.fillWidth: true
                            spacing: 12

                            Repeater {
                                model: root.selectedFailed ? [] : root.displayedEntry?.sections ?? []

                                delegate: AIUsageSection {
                                    id: sectionDelegate
                                    required property var modelData
                                    Layout.fillWidth: true
                                    section: sectionDelegate.modelData
                                    clockNow: Number(root.usageService.clockNow ?? Date.now())
                                    clock12Hour: ThemeService.settings.clock12Hour ?? false
                                }
                            }
                        }
                    }

                    UiText {
                        objectName: "ai-usage-no-details"
                        Layout.fillWidth: true
                        visible: !root.selectedFailed && (root.displayedEntry?.sections?.length ?? 0) === 0
                        text: "No quota details are available for this provider."
                        textFormat: Text.PlainText
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: providerTransition

        NumberAnimation {
            target: root
            property: "providerOpacity"
            to: 0
            duration: root.providerFadeOutDuration
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: {
                root.displayedEntry = root.selectedEntry;
                root.resetDetailScroll();
            }
        }

        NumberAnimation {
            target: root
            property: "providerOpacity"
            to: 1
            duration: root.providerFadeInDuration
            easing.type: Easing.OutCubic
        }

        onFinished: root.syncDisplayedEntry()
    }
}
