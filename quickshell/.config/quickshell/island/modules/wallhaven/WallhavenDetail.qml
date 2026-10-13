import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import "../../components"
import "../../services"
import "../../styles"

// Side pane for the selected wallpaper: full-size preview, facts, palette choices and actions.
Rectangle {
    id: root
    readonly property var item: WallhavenService.selected
    readonly property var detail: WallhavenService.detail
    // A wallpaper already in the Dynamic folder: nothing to download or save, only palettes to add.
    readonly property bool library: item !== null && item.library === true
    readonly property bool staticTheme: ThemeService.state.source !== "dynamic"
    readonly property string schemeName: WallhavenService.schemeLabel(WallhavenService.selectedKind, WallhavenService.selectedScheme)

    function fileSize(bytes) {
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB";
        return Math.max(1, Math.round(bytes / 1024)) + " KB";
    }

    radius: 26
    color: Theme.surface
    clip: true

    Flickable {
        id: scroll
        anchors.fill: parent
        anchors.margins: 14
        contentWidth: width
        contentHeight: body.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        SmoothScroll { scrollTarget: scroll }
        ScrollBar.vertical: ScrollBar {
            width: 4
            contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.textMuted; opacity: 0.5 }
        }

        Column {
            id: body
            width: scroll.width - 6
            spacing: 14

            // ---- preview -----------------------------------------------------------------------
            ClippingRectangle {
                width: parent.width
                height: Math.round(width * 0.58)
                radius: 18
                color: Theme.surfaceVariant
                Image {
                    anchors.fill: parent
                    // Library items are the full-size file itself; only `full` below decodes it, scaled down.
                    source: root.item && !root.library ? root.item.thumb : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
                Image {
                    id: full
                    anchors.fill: parent
                    source: WallhavenService.preparedPath ? WallhavenService.fileUrl(WallhavenService.preparedPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: 960
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animationNormal } }
                }
                Rectangle {
                    visible: WallhavenService.preparing
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    height: 24
                    width: preparing.implicitWidth + 20
                    radius: 12
                    color: "#a0000000"
                    UiText {
                        id: preparing
                        anchors.centerIn: parent
                        text: "Downloading full size…"
                        color: "#ffffff"
                        font.pixelSize: 11
                    }
                }
                IconButton {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    iconSource: "../assets/icons/close.svg"
                    description: "Close details"
                    onClicked: WallhavenService.closeDetail()
                }
            }

            // ---- facts -------------------------------------------------------------------------
            Column {
                width: parent.width
                spacing: 6
                UiText {
                    width: parent.width
                    visible: !nameField.visible
                    text: root.item ? (root.library ? root.item.name : "wallhaven-" + root.item.id) : ""
                    color: Theme.textPrimary
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                // Staged downloads can be renamed before saving; saved wallpapers rename from the Wallpapers panel.
                RenameField {
                    id: nameField
                    objectName: "wallhaven-name-field"
                    width: parent.width
                    visible: root.item !== null && !root.library && !root.item.installed
                    enabled: !WallhavenService.working
                    cancelOnBlur: false
                    implicitHeight: 32
                    placeholderText: "File name"
                    suffix: WallhavenService.stagedSuffix(root.item)
                    text: WallhavenService.stagedName
                    onTextEdited: WallhavenService.stagedName = text
                    onCommitted: nameField.focus = false
                    onCancelled: { WallhavenService.stagedName = WallhavenService.defaultName(root.item); nameField.focus = false; }
                }
                UiText {
                    width: parent.width
                    text: root.item
                        ? (root.library
                            ? [root.item.resolution, root.fileSize(root.item.fileSize), root.item.fileType].filter(part => part).join("  ·  ")
                            : [root.item.resolution, root.fileSize(root.item.fileSize), root.item.category,
                               root.item.views.toLocaleString() + " views", root.item.favorites.toLocaleString() + " favorites"].join("  ·  "))
                        : ""
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
                UiText {
                    width: parent.width
                    visible: root.detail !== null && root.detail.uploader.length > 0
                    text: root.detail ? "Uploaded by " + root.detail.uploader : ""
                    color: Theme.textMuted
                    font.pixelSize: 12
                }
            }

            // ---- actions -----------------------------------------------------------------------
            Row {
                width: parent.width
                spacing: 8
                WallhavenButton {
                    id: applyButton
                    objectName: "wallhaven-apply"
                    primary: true
                    width: root.library ? parent.width : parent.width - download.width - pageButton.width - 16
                    text: WallhavenService.working ? "Working…" : root.library ? "Add palette + apply" : "Apply wallpaper + palette"
                    iconSource: "../assets/icons/sparkles.svg"
                    enabled: !WallhavenService.working && !ThemeService.busy && root.item !== null
                    onClicked: WallhavenService.install(true)
                }
                WallhavenButton {
                    id: download
                    objectName: "wallhaven-download"
                    visible: !root.library
                    text: root.item && root.item.installed ? "Saved" : "Save"
                    iconSource: root.item && root.item.installed ? "../assets/icons/check.svg" : "../assets/icons/download.svg"
                    enabled: !WallhavenService.working && root.item !== null && !root.item.installed
                    onClicked: WallhavenService.install(false)
                }
                IconButton {
                    id: pageButton
                    visible: !root.library
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 38
                    implicitHeight: 38
                    iconSource: "../assets/icons/external-link.svg"
                    description: "Open on wallhaven.cc"
                    onClicked: WallhavenService.openPage()
                }
            }
            UiText {
                width: parent.width
                visible: text.length > 0
                text: WallhavenService.workError || WallhavenService.prepareError
                    || (WallhavenService.working || WallhavenService.workStatus ? WallhavenService.workStatus
                        : root.staticTheme ? "Applying switches Island to the Dynamic theme."
                        : root.library ? "Schemes marked ✓ are already stored for this wallpaper; applying one again regenerates it." : "")
                color: WallhavenService.workError || WallhavenService.prepareError ? Theme.danger
                    : WallhavenService.workStatus.startsWith("Applied") ? Theme.success : Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }

            // ---- palette -----------------------------------------------------------------------
            Item {
                width: parent.width
                height: 32
                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter
                    SvgIcon { anchors.verticalCenter: parent.verticalCenter; source: "../assets/icons/palette.svg"; size: 17; color: Theme.accent }
                    UiText { anchors.verticalCenter: parent.verticalCenter; text: "Palette · " + root.schemeName; color: Theme.textPrimary; font.pixelSize: 14; font.weight: Font.DemiBold }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    WallhavenChip {
                        objectName: "wallhaven-mode-dark"
                        text: "Dark"
                        checked: WallhavenService.previewMode === "dark"
                        onClicked: WallhavenService.setPreviewMode("dark")
                    }
                    WallhavenChip {
                        objectName: "wallhaven-mode-light"
                        text: "Light"
                        checked: WallhavenService.previewMode === "light"
                        onClicked: WallhavenService.setPreviewMode("light")
                    }
                }
            }
            // Mock window painted with the selected palette, so the result is judged in context.
            Rectangle {
                id: mock
                readonly property var palette: WallhavenService.selectedPalette
                width: parent.width
                height: 118
                radius: 16
                color: palette ? palette.colors.background : Theme.surfaceVariant
                border.width: 1
                border.color: Theme.border
                Behavior on color { ColorAnimation { duration: Theme.animationNormal } }
                Column {
                    visible: mock.palette !== null
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    Row {
                        spacing: 6
                        Repeater {
                            model: mock.palette ? [mock.palette.colors.red, mock.palette.colors.yellow, mock.palette.colors.green] : []
                            Rectangle { required property string modelData; width: 9; height: 9; radius: 5; color: modelData }
                        }
                        UiText {
                            leftPadding: 6
                            text: "island ~ " + WallhavenService.selectedScheme
                            color: mock.palette ? mock.palette.colors.muted : "transparent"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }
                    Row {
                        spacing: 0
                        UiText { text: "❯ "; color: mock.palette ? mock.palette.colors.accent : "transparent"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                        UiText { text: "wallpaper "; color: mock.palette ? mock.palette.colors.foreground : "transparent"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                        UiText { text: "--palette "; color: mock.palette ? mock.palette.colors.cyan : "transparent"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                        UiText { text: WallhavenService.selectedScheme; color: mock.palette ? mock.palette.colors.yellow : "transparent"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                    }
                    Row {
                        spacing: 0
                        UiText { text: "ok "; color: mock.palette ? mock.palette.colors.green : "transparent"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                        UiText { text: "warn "; color: mock.palette ? mock.palette.colors.yellow : "transparent"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                        UiText { text: "error "; color: mock.palette ? mock.palette.colors.red : "transparent"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                        UiText { text: "info"; color: mock.palette ? mock.palette.colors.blue : "transparent"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                    }
                    Row {
                        spacing: 3
                        Repeater {
                            model: mock.palette ? mock.palette.terminal : []
                            Rectangle { required property string modelData; width: (mock.width - 24 - 15 * 3) / 16; height: 14; radius: 4; color: modelData }
                        }
                    }
                }
                UiText {
                    visible: mock.palette === null
                    anchors.centerIn: parent
                    width: parent.width - 32
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: WallhavenService.selectedKind === "material"
                        ? "Island renders Material palettes from the wallpaper when you apply."
                        : WallhavenService.prepareError ? "Preview unavailable." : "Generating palettes from the full-size image…"
                    color: Theme.textMuted
                    font.pixelSize: 12
                }
            }
            WallhavenSchemes { width: parent.width }

            // ---- tags and colors -----------------------------------------------------------------
            UiText {
                visible: root.detail !== null && root.detail.tags.length > 0
                text: "Tags"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Flow {
                width: parent.width
                spacing: 6
                Repeater {
                    model: root.detail ? root.detail.tags : []
                    WallhavenChip {
                        required property var modelData
                        text: modelData.name
                        description: modelData.category
                        onClicked: WallhavenService.searchFor("id:" + modelData.id)
                    }
                }
                WallhavenChip {
                    visible: root.item !== null && !root.library
                    text: "More like this"
                    tint: Theme.success
                    onClicked: WallhavenService.searchFor("like:" + root.item.id)
                }
                WallhavenChip {
                    visible: root.detail !== null && root.detail.uploader.length > 0
                    text: root.detail ? "@" + root.detail.uploader : ""
                    onClicked: WallhavenService.searchFor("@" + root.detail.uploader)
                }
            }
            UiText {
                visible: root.item !== null && root.item.colors.length > 0
                text: "Colors"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Flow {
                width: parent.width
                spacing: 8
                Repeater {
                    model: root.item ? root.item.colors : []
                    Rectangle {
                        id: dot
                        required property string modelData
                        width: 26; height: 26; radius: 13
                        color: modelData
                        border.width: 1
                        border.color: Theme.border
                        HoverHandler { id: dotHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: WallhavenService.filterColor(dot.modelData) }
                        IslandTooltip { parent: dot; visible: dotHover.hovered; text: "Filter by " + dot.modelData }
                    }
                }
            }
        }
    }
}
