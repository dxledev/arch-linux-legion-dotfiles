import QtQuick
import "../../components"
import "../../services"
import "../../styles"

// Advanced filters drawer: everything wallhaven's search API accepts beyond the toolbar controls.
Rectangle {
    id: root
    readonly property var filters: WallhavenService.filters
    readonly property int labelWidth: 92
    property bool expanded: false

    readonly property var topRanges: [
        { value: "1d", label: "Day" }, { value: "3d", label: "3 days" }, { value: "1w", label: "Week" },
        { value: "1M", label: "Month" }, { value: "3M", label: "3 months" }, { value: "6M", label: "6 months" },
        { value: "1y", label: "Year" }
    ]
    readonly property var minimumResolutions: [
        { value: "", label: "Any" }, { value: "1920x1080", label: "1920×1080" }, { value: "2560x1440", label: "2560×1440" },
        { value: "3440x1440", label: "3440×1440" }, { value: "3840x2160", label: "3840×2160" }, { value: "5120x2880", label: "5120×2880" }
    ]
    readonly property var exactResolutions: [
        "1280x720", "1920x1080", "1920x1200", "2560x1080", "2560x1440", "2560x1600",
        "3440x1440", "3840x1600", "3840x2160", "5120x1440", "5120x2880"
    ]
    readonly property var ratios: [
        { value: "landscape", label: "Landscape" }, { value: "portrait", label: "Portrait" },
        { value: "16x9", label: "16:9" }, { value: "16x10", label: "16:10" }, { value: "21x9", label: "21:9" },
        { value: "32x9", label: "32:9" }, { value: "48x9", label: "48:9" }, { value: "4x3", label: "4:3" },
        { value: "5x4", label: "5:4" }, { value: "3x2", label: "3:2" }, { value: "1x1", label: "1:1" },
        { value: "9x16", label: "9:16" }, { value: "10x16", label: "10:16" }, { value: "9x18", label: "9:18" }
    ]

    clip: true
    radius: 22
    color: Theme.surface
    height: expanded ? content.implicitHeight + 28 : 0
    visible: height > 0
    Behavior on height { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }

    component Row_: Item {
        id: line
        property string label: ""
        property real labelWidth: 92
        default property alias items: flow.data
        width: parent.width
        implicitHeight: Math.max(26, flow.implicitHeight)
        UiText {
            width: line.labelWidth
            y: 5
            text: line.label
            color: Theme.textMuted
            font.pixelSize: 12
        }
        Flow {
            id: flow
            x: line.labelWidth
            width: parent.width - line.labelWidth
            spacing: 6
        }
    }

    Column {
        id: content
        x: 18
        y: 14
        width: parent.width - 36
        spacing: 12

        Row_ {
            label: "Top range"
            visible: root.filters.sorting === "toplist"
            Repeater {
                model: root.topRanges
                WallhavenChip {
                    required property var modelData
                    text: modelData.label
                    checked: root.filters.topRange === modelData.value
                    onClicked: WallhavenService.setFilter("topRange", modelData.value)
                }
            }
        }
        Row_ {
            label: "At least"
            Repeater {
                model: root.minimumResolutions
                WallhavenChip {
                    required property var modelData
                    text: modelData.label
                    checked: root.filters.atleast === modelData.value
                    onClicked: WallhavenService.setFilter("atleast", modelData.value)
                }
            }
        }
        Row_ {
            label: "Exact size"
            Repeater {
                model: root.exactResolutions
                WallhavenChip {
                    required property string modelData
                    text: modelData.replace("x", "×")
                    checked: root.filters.resolutions.indexOf(modelData) >= 0
                    onClicked: WallhavenService.toggleListItem("resolutions", modelData)
                }
            }
        }
        Row_ {
            label: "Aspect ratio"
            Repeater {
                model: root.ratios
                WallhavenChip {
                    required property var modelData
                    text: modelData.label
                    checked: root.filters.ratios.indexOf(modelData.value) >= 0
                    onClicked: WallhavenService.toggleListItem("ratios", modelData.value)
                }
            }
        }
        Row_ {
            label: "Color"
            Repeater {
                model: WallhavenService.colorChoices
                Rectangle {
                    id: swatch
                    required property string modelData
                    readonly property bool active: root.filters.colors === modelData
                    width: 24; height: 24; radius: 12
                    color: "#" + modelData
                    border.width: active ? 3 : 1
                    border.color: active ? Theme.accent : Theme.border
                    scale: swatchHover.hovered ? 1.12 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.animationFast } }
                    HoverHandler { id: swatchHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: WallhavenService.setFilter("colors", swatch.active ? "" : swatch.modelData) }
                    IslandTooltip { parent: swatch; visible: swatchHover.hovered; text: "#" + swatch.modelData }
                }
            }
        }
        Item {
            width: parent.width
            height: keyField.implicitHeight
            UiText {
                width: root.labelWidth
                anchors.verticalCenter: parent.verticalCenter
                text: "API key"
                color: Theme.textMuted
                font.pixelSize: 12
            }
            SearchField {
                id: keyField
                onNavigateDown: stepDown()
                objectName: "wallhaven-key"
                x: root.labelWidth
                width: parent.width - root.labelWidth - saveKey.width - 8
                implicitHeight: 36
                echoMode: TextInput.Password
                placeholderText: WallhavenService.hasKey ? "Key saved — type a new one to replace it" : "Paste your wallhaven API key (unlocks NSFW and collections)"
                onAccepted: saveKey.save()
            }
            WallhavenButton {
                id: saveKey
                anchors.right: parent.right
                implicitHeight: 36
                text: keyField.text.length === 0 && WallhavenService.hasKey ? "Remove key" : "Save key"
                enabled: keyField.text.length > 0 || WallhavenService.hasKey
                function save() {
                    WallhavenService.saveKey(keyField.text);
                    keyField.text = "";
                }
                onClicked: save()
            }
        }
        UiText {
            width: parent.width
            visible: WallhavenService.keyError.length > 0
            text: WallhavenService.keyError
            color: Theme.danger
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        Item {
            width: parent.width
            height: 30
            UiText {
                anchors.left: parent.left
                anchors.right: reset.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Tips: +tag  -tag  \"exact phrase\"  @user  id:TAGID  type:png  like:WALLPAPERID"
                color: Theme.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            WallhavenButton {
                id: reset
                anchors.right: parent.right
                implicitHeight: 30
                text: "Reset filters"
                onClicked: WallhavenService.resetFilters()
            }
        }
    }
}
