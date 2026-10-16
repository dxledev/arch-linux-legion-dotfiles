pragma ComponentBehavior: Bound
import QtQuick
import "../components"
import "../core"
import "../styles"
import "../services/MenuEntries.js" as MenuEntries

SettingsPanel {
    id: root
    title: "Settings"
    contentSpacing: 8
    maximumHeight: 635
    // Keep the panel full height while filtering so results do not shrink it with every keystroke.
    minimumHeight: searchVisible ? maximumHeight : 0
    scrollObjectName: "settings-scroll"
    searchable: true
    searchPlaceholder: "Search settings…"
    backAction: () => IslandController.openNavigation()
    escapeAction: () => IslandController.reset()
    readonly property var sections: searchVisible ? MenuEntries.filterSettingsSections(searchText) : MenuEntries.settingsSections

    function focusResult(index) {
        const item = links.itemAt(index);
        if (item) item.forceActiveFocus();
    }

    onSearchNavigateDown: focusResult(0)
    onSearchAccepted: {
        const first = root.sections[0];
        if (first) IslandController.openSettingsSection(first.key);
    }
    Repeater {
        id: links
        model: root.sections
        SettingLink {
            required property var modelData
            required property int index
            objectName: "settings-entry-" + modelData.key
            textLabel: modelData.title
            iconSource: modelData.icon
            onClicked: IslandController.openSettingsSection(modelData.key)
            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()
            Keys.onDownPressed: root.focusResult(index + 1)
            Keys.onUpPressed: {
                if (index > 0) root.focusResult(index - 1);
                else if (root.searchVisible) root.searchInput.forceActiveFocus();
            }
        }
    }
    UiText {
        visible: root.searchVisible && root.sections.length === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 24
        bottomPadding: 24
        text: "No settings match your search."
        color: Theme.textSecondary
        font.pixelSize: 13
    }
}
