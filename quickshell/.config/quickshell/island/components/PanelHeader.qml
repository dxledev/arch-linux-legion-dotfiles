import QtQuick
import QtQuick.Controls
import "../styles"
import "../core"

Item {
    id: root
    required property string title
    property string subtitle: ""
    property string trailingText: ""
    property bool trailingClickable: false
    // Makes the title a link-style button, for panels that lead to a related panel.
    property bool titleClickable: false
    property string titleDescription: ""
    // Same for the subtitle, for panels whose source line switches between related lists.
    property bool subtitleClickable: false
    property string subtitleDescription: ""
    property url titleActionIcon: ""
    property string titleActionDescription: ""
    property bool titleActionActive: false
    property var scrollTargets: []
    // Optional delete-mode controls shown left of the close button: a trash toggle and, once
    // something is marked, a confirm check beside it.
    property bool deleteVisible: false
    property bool deleteActive: false
    property bool deleteConfirmVisible: false
    property string deleteDescription: "Delete"
    property string deleteConfirmDescription: "Delete selected"
    // The trash toggle greys out while something else (a name edit) owns the panel.
    property bool deleteEnabled: true
    // Optional sort button left of the star; the panel owns the menu it opens.
    property bool sortVisible: false
    property bool sortActive: false
    property url sortIcon: "../assets/icons/sort-asc.svg"
    property string sortDescription: "Sort"
    readonly property Item sortButton: sortToggle
    // Optional star toggle left of the trash, for panels whose list can put favorites first.
    property bool favoritesVisible: false
    property bool favoritesActive: false
    property string favoritesDescription: "Show favorites only"
    // Optional folder button right of the star, for panels backed by a directory on disk.
    property bool folderVisible: false
    property string folderDescription: "Open folder"
    // A name edit reuses the confirm slot: the same check saves it.
    property bool editConfirmVisible: false
    property string editConfirmDescription: "Save name"
    readonly property Item editConfirmButton: editConfirm
    // Marks the header's buttons so keyboard navigation starts in the panel's content, below them.
    readonly property bool panelHeader: true
    readonly property Item trailingAnchor: actions.width > 0 ? actions : closeButton
    signal back()
    signal sortToggled()
    signal favoritesToggled()
    signal folderClicked()
    signal deleteToggled()
    signal deleteConfirmed()
    signal editConfirmed()
    signal trailingClicked()
    signal titleClicked()
    signal subtitleClicked()
    signal titleActionClicked()
    width: parent.width
    implicitHeight: subtitle ? 64 : 48
    IconButton {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        iconSource: "../assets/icons/chevron-left.svg"
        description: "Back"
        onClicked: root.back()
    }
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 52
        anchors.right: trailingLabel.visible ? trailingLabel.left : root.trailingAnchor.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Item {
            width: parent.width
            height: Math.max(titleLabel.implicitHeight, titleAction.visible ? titleAction.implicitHeight : 0)
            UiText {
                id: titleLabel
                objectName: "panel-title"
                anchors.verticalCenter: parent.verticalCenter
                width: titleAction.visible ? Math.min(implicitWidth, parent.width - titleAction.width - 8) : parent.width
                text: root.title
                color: root.titleClickable && (titleMouse.containsMouse || titleLabel.activeFocus) ? Theme.accent : Theme.textPrimary
                font.pixelSize: 25
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                // Keyboard: a link-style title opens its related panel with Enter or Space.
                activeFocusOnTab: root.titleClickable
                Keys.onReturnPressed: root.titleClicked()
                Keys.onEnterPressed: root.titleClicked()
                Keys.onSpacePressed: root.titleClicked()
                Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                MouseArea {
                    id: titleMouse
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.min(titleLabel.contentWidth, titleLabel.width)
                    enabled: root.titleClickable
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: root.titleDescription || root.title
                    onClicked: root.titleClicked()
                }
                ScrollProgress {
                    anchors.left: parent.left
                    anchors.top: parent.bottom
                    anchors.topMargin: 1
                    width: Math.min(titleLabel.contentWidth, titleLabel.width)
                    height: implicitHeight
                    scrollTargets: root.scrollTargets
                }
            }
            IconButton {
                id: titleAction
                objectName: "panel-title-action"
                anchors.left: titleLabel.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: root.titleActionIcon.toString().length > 0
                iconSource: root.titleActionIcon
                iconColor: root.titleActionActive ? Theme.accent : Theme.textPrimary
                description: root.titleActionDescription
                onClicked: root.titleActionClicked()
            }
        }
        UiText {
            id: subtitleLabel
            objectName: "panel-subtitle"
            visible: root.subtitle.length > 0
            width: Math.min(implicitWidth, parent.width)
            text: root.subtitle
            color: root.subtitleClickable && (subtitleMouse.containsMouse || subtitleLabel.activeFocus) ? Theme.accent : Theme.textSecondary
            font.pixelSize: 12
            font.underline: root.subtitleClickable && (subtitleMouse.containsMouse || subtitleLabel.activeFocus)
            elide: Text.ElideRight
            activeFocusOnTab: root.subtitleClickable
            Keys.onReturnPressed: root.subtitleClicked()
            Keys.onEnterPressed: root.subtitleClicked()
            Keys.onSpacePressed: root.subtitleClicked()
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
            MouseArea {
                id: subtitleMouse
                anchors.fill: parent
                anchors.topMargin: -4
                anchors.bottomMargin: -4
                enabled: root.subtitleClickable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: root.subtitleDescription || root.subtitle
                onClicked: root.subtitleClicked()
            }
        }
    }
    Button {
        id: trailingLabel
        focusPolicy: Qt.TabFocus
        anchors.right: root.trailingAnchor.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Math.max(0, (root.width - 116) / 2))
        visible: root.trailingText.length > 0
        text: root.trailingText
        enabled: root.trailingClickable
        hoverEnabled: root.trailingClickable
        padding: root.trailingClickable ? 10 : 0
        Accessible.name: root.trailingText
        onClicked: root.trailingClicked()
        contentItem: UiText {
            text: trailingLabel.text
            color: root.trailingClickable && (trailingLabel.hovered || trailingLabel.activeFocus) ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
        }
        background: Rectangle {
            radius: height / 2
            color: trailingLabel.down ? Theme.buttonPressed : trailingLabel.hovered ? Theme.surfaceVariant : "transparent"
            border.width: root.trailingClickable && trailingLabel.activeFocus ? 2 : 0
            border.color: Theme.accent
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
        }
        HoverHandler {
            enabled: root.trailingClickable
            cursorShape: Qt.PointingHandCursor
        }
    }
    Row {
        id: actions
        anchors.right: closeButton.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        visible: root.deleteVisible || root.favoritesVisible || root.folderVisible || root.sortVisible
        width: visible ? implicitWidth : 0
        IconButton {
            objectName: "panel-delete-confirm"
            visible: root.deleteConfirmVisible
            iconSource: "../assets/icons/check.svg"
            iconColor: Theme.danger
            description: root.deleteConfirmDescription
            onClicked: root.deleteConfirmed()
        }
        IconButton {
            id: editConfirm
            objectName: "panel-edit-confirm"
            visible: root.editConfirmVisible
            iconSource: "../assets/icons/check.svg"
            iconColor: Theme.accent
            description: root.editConfirmDescription
            onClicked: root.editConfirmed()
        }
        IconButton {
            id: sortToggle
            objectName: "panel-sort-toggle"
            visible: root.sortVisible
            iconSource: root.sortIcon
            iconColor: root.sortActive ? Theme.accent : Theme.textPrimary
            description: root.sortDescription
            onClicked: root.sortToggled()
        }
        IconButton {
            objectName: "panel-favorites-toggle"
            visible: root.favoritesVisible
            iconSource: root.favoritesActive ? "../assets/icons/star-filled.svg" : "../assets/icons/star.svg"
            iconColor: root.favoritesActive ? Theme.accent : Theme.textPrimary
            description: root.favoritesDescription
            onClicked: root.favoritesToggled()
        }
        IconButton {
            objectName: "panel-folder-button"
            visible: root.folderVisible
            iconSource: "../assets/icons/folder.svg"
            description: root.folderDescription
            onClicked: root.folderClicked()
        }
        IconButton {
            objectName: "panel-delete-toggle"
            enabled: root.deleteEnabled
            opacity: enabled ? 1 : 0.4
            iconSource: "../assets/icons/trash.svg"
            iconColor: root.deleteActive ? Theme.danger : Theme.textPrimary
            description: root.deleteDescription
            onClicked: root.deleteToggled()
        }
    }
    IconButton {
        id: closeButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        iconSource: "../assets/icons/close.svg"
        description: "Close"
        onClicked: IslandController.reset()
    }
}
