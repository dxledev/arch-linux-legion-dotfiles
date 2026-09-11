pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.services
import qs.utils

Searcher {
    id: root

    property var pendingPanels: null
    property string pendingPanelName

    function transformSearch(search: string): string {
        return search.slice(GlobalConfig.launcher.actionPrefix.length);
    }

    function openPanel(name: string): void {
        const components = ShellState.componentsForActive();
        const state = ShellState.forActive();
        if (!components?.panels || !state)
            return;

        state.session = false;
        pendingPanelName = name;
        pendingPanels = components.panels;
        finishOpeningPanel();
    }

    function finishOpeningPanel(): void {
        if (!pendingPanels || pendingPanels.launcher.visible)
            return;
        const popouts = pendingPanels.popouts;
        pendingPanels = null;
        ShellState.componentsFor(popouts.screen)?.bar?.pinPopout(root.pendingPanelName);
    }

    Connections {
        target: root.pendingPanels?.launcher ?? null

        function onVisibleChanged(): void {
            root.finishOpeningPanel();
        }
    }

    list: variants.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.actions

    Variants {
        id: variants

        model: GlobalConfig.launcher.actions.filter(a => (a.enabled ?? true) && (GlobalConfig.launcher.enableDangerousActions || !(a.dangerous ?? false)))

        Action {}
    }

    component Action: QtObject {
        required property var modelData
        readonly property string name: modelData.name ? Tr.trMarked(modelData.name) : Tr.trCtx("Unnamed", "launcher action with no name")
        readonly property string desc: modelData.description ? Tr.trMarked(modelData.description) : Tr.trCtx("No description", "launcher action with no description")
        readonly property string icon: modelData.icon ?? "help_outline"
        readonly property list<string> command: modelData.command ?? []
        readonly property bool enabled: modelData.enabled ?? true
        readonly property bool dangerous: modelData.dangerous ?? false

        function onClicked(list: AppList): void {
            if (command.length === 0)
                return;

            if (command[0] === "apps") {
                list.search.text = "";
            } else if (command[0] === "autocomplete" && command.length > 1) {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}${command[1]} `;
            } else if (command[0] === "setMode" && command.length > 1) {
                list.screenState.launcher = false;
                Colours.setMode(command[1]);
            } else if (command[0] === "panel" && ["battery", "bluetooth", "network", "audio"].includes(command[1])) {
                list.screenState.launcher = false;
                root.openPanel(command[1]);
            } else if (command[0] === "session" && command.length > 1) {
                list.screenState.launcher = false;
                const sessionCommand = Config.session.commands[command[1]];
                if (!SessionManager.exec(sessionCommand))
                    Quickshell.execDetached(sessionCommand);
            } else {
                list.screenState.launcher = false;
                if (!SessionManager.exec(command))
                    Quickshell.execDetached(command);
            }
        }
    }
}
