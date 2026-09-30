pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import "Format.js" as Format

ColumnLayout {
    id: root

    required property var entry
    required property var controller
    readonly property bool hasEntry: (entry.key || "").length > 0
    readonly property bool isImage: entry.payloadKind === "image"
    readonly property bool isColor: entry.payloadKind === "color"
    readonly property string openLink: Format.link(entry)
    readonly property color swatch: isColor ? entry.contentText.trim() : "transparent"
    readonly property string entryKey: entry.key || ""
    readonly property string entryIdentity: entry.contentHash || entryKey
    property string pendingCopyKey: ""
    property string pendingCopyIdentity: ""
    property string copiedIdentity: ""
    readonly property bool copying: pendingCopyKey.length > 0
    readonly property bool copied: entryIdentity.length > 0 && copiedIdentity === entryIdentity
    spacing: Style.gap

    function copyEntry(): void {
        if (!hasEntry || copying)
            return;
        copyFeedback.stop();
        copiedIdentity = "";
        pendingCopyKey = entryKey;
        pendingCopyIdentity = entryIdentity;
        ClipboardState.copyEntry(entryKey, false);
    }

    onEntryIdentityChanged: {
        copiedIdentity = "";
        copyFeedback.stop();
    }

    Timer {
        id: copyFeedback
        interval: 1800
        onTriggered: root.copiedIdentity = ""
    }

    Connections {
        target: root.controller
        function onCopyCompleted(key: string, success: bool, message: string): void {
            if (key !== root.pendingCopyKey)
                return;
            root.pendingCopyKey = "";
            if (success && root.pendingCopyIdentity === root.entryIdentity) {
                root.copiedIdentity = root.entryIdentity;
                copyFeedback.restart();
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: root.hasEntry ? (root.entry.previewText || "Clipboard entry").replace(/[\r\n\t]+/g, " ") : "Preview"
            textFormat: Text.PlainText
            color: Style.text
            font: Tokens.font.title.small
            elide: Text.ElideRight
        }

        IconButton {
            visible: root.hasEntry
            icon: "star"
            type: IconButton.Text
            isToggle: true
            checked: root.entry.favorite || false
            Accessible.name: checked ? "Unpin entry" : "Pin entry"
            onClicked: root.controller.setFavorite(root.entry.key, !root.entry.favorite)
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.hasEntry
        text: root.entry.loading ? "Decoding…" : `${root.entry.payloadKind || "clipboard"} · ${root.entry.mimeType || "type unknown"} · ${Format.bytes(root.entry.size || 0)}`
        color: Style.muted
        font: Tokens.font.label.small
        elide: Text.ElideRight
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Style.outline
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: (root.entry.qrText || "").length > 0
        spacing: 4

        Text {
            text: "QR code content"
            color: Style.accent
            font: Tokens.font.label.small
        }

        QQC.ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(100, qrContent.implicitHeight)
            clip: true
            QQC.TextArea {
                id: qrContent
                text: root.entry.qrText || ""
                textFormat: TextEdit.PlainText
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                color: Style.text
                font: Tokens.font.body.small
                background: Rectangle { color: Style.row; radius: Tokens.rounding.small }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Tokens.rounding.medium
        color: Style.row
        border.width: root.isImage ? 1 : 0
        border.color: Style.outline
        clip: true

        Image {
            id: imagePreview
            anchors.fill: parent
            anchors.margins: Style.rowPadding
            visible: root.isImage
            source: root.isImage ? root.entry.imageUrl || root.entry.thumbnailUrl || "" : ""
            sourceSize.width: Math.max(1, width * 2)
            sourceSize.height: Math.max(1, height * 2)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            retainWhileLoading: true
            cache: false
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Style.padding * 2
            visible: root.isColor
            spacing: Style.gap

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(180, root.height / 3)
                radius: Tokens.rounding.medium
                color: root.swatch
            }

            Text {
                Layout.fillWidth: true
                text: `${root.entry.contentText || ""}\nRGB ${Math.round(root.swatch.r * 255)}, ${Math.round(root.swatch.g * 255)}, ${Math.round(root.swatch.b * 255)}`
                color: Style.text
                font: Tokens.font.body.medium
                horizontalAlignment: Text.AlignHCenter
            }
        }

        QQC.ScrollView {
            anchors.fill: parent
            visible: root.hasEntry && !root.isImage && !root.isColor
            clip: true
            QQC.TextArea {
                text: Format.body(root.entry)
                textFormat: TextEdit.PlainText
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                padding: Style.rowPadding
                color: Style.text
                selectionColor: Style.accent
                font: Tokens.font.body.small
                background: null
            }
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - Style.padding * 2
            visible: !root.hasEntry || (root.isImage && (imagePreview.source.toString().length === 0 || imagePreview.status === Image.Error))
            text: root.hasEntry ? "Image preview unavailable." : "Select an entry to preview it."
            color: Style.muted
            font: Tokens.font.body.small
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.hasEntry

        IconButton {
            objectName: "clipboardPreviewCopy"
            implicitHeight: openLinkButton.implicitHeight
            icon: root.copied ? "check" : "content_copy"
            type: IconButton.Tonal
            enabled: !root.copying
            activeFocusOnTab: true
            stateLayer.manualHoverOverride: activeFocus
            Accessible.name: root.copied ? "Copied" : "Copy entry"
            QQC.ToolTip.visible: hovered || activeFocus
            QQC.ToolTip.text: root.copied ? "Copied" : "Copy"
            QQC.ToolTip.delay: 400
            onClicked: root.copyEntry()
            Keys.onReturnPressed: root.copyEntry()
            Keys.onSpacePressed: root.copyEntry()
        }

        TextButton {
            id: openLinkButton
            objectName: "clipboardPreviewOpenLink"
            visible: root.openLink.length > 0
            text: "Open link"
            type: TextButton.Tonal
            onClicked: Qt.openUrlExternally(root.openLink)
        }

        Item { Layout.fillWidth: true }
    }
}
