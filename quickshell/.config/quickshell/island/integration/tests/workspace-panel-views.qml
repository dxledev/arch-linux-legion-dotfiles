import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../core"
import "../../services"
import "../../styles"
import "../../views"

ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0
    property real clockY: 0

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    function settings(values) { ThemeService.settings = Object.assign({}, ThemeService.settings, values); }

    // The workspace row exists twice (chips and dots); only the shown one counts.
    function shown(item, name) {
        if (item.objectName === name && item.visible) return item;
        for (const child of item.children) {
            const found = shown(child, name);
            if (found) return found;
        }
        return null;
    }

    function next() { phase++; elapsed = 0; }

    function entry(list, name) { return list.find(item => item.name === name); }

    function tick() {
        elapsed += 40;
        switch (phase) {
        case 0: {
            // Pure helpers: the four named specials always appear, extras come from rules and live workspaces.
            const rules = [{workspaceString: "special:aether", enabled: true}, {workspaceString: "special:term", enabled: true}, {workspaceString: "3"}, {workspaceString: "special:nexus", enabled: false}];
            const live = [{id: -98, name: "special:mediaspace"}, {id: -99, name: "special:floating"}, {id: 2, name: "2"}];
            const windows = [{workspace: {name: "special:mediaspace"}}, {workspace: {name: "1"}}];
            const list = WorkspaceService.specialEntries(live, windows, rules, "special:mediaspace");
            check(list.map(item => item.name).join(",") === "discordspace,mediaspace,scratchpad,socialspace,floating,term", "Special order and extras (Caelestia's aether and nexus excluded): " + list.map(item => item.name));
            check(entry(list, "mediaspace").occupied && entry(list, "mediaspace").active, "Occupied active special");
            check(!entry(list, "discordspace").occupied && !entry(list, "term").occupied, "Empty specials are not occupied");
            check(WorkspaceService.specialEntries([], [], [], "").every(item => !item.active), "No active special when none is shown");
            const numbered = WorkspaceService.workspaceEntries([{id: 14, toplevels: {values: [1]}}], null, true, 3, 2);
            check(numbered.map(item => item.id).join(",") === "1,2,3,14" && numbered[3].occupied, "Persistent ids plus occupied and active");
            if (!ThemeService.ready) return;
            ThemeService.settings = Object.assign({}, ThemeService.settings, {islandAnimationDuration: 0, hoverToExpand: false});
            StatusManager.visible = false;
            IslandState.workspacePanelOpen = false;
            IslandController.openExpanded("HDMI-A-1");
            IslandState.islandPinned = true;
            next();
            break;
        }
        case 1:
            if (elapsed < 120) return;
            check(first.height === 75, "Section starts collapsed");
            check(named(first, "workspace-panel-pill") !== null, "Pill is present");
            check(!named(first, "workspace-panel-line").visible, "Section hidden while collapsed");
            clockY = named(first, "expanded-clock-group").mapToItem(first, 0, 0).y;
            const pill = named(first, "workspace-panel-pill");
            const point = pill.mapToItem(first, pill.width / 2, pill.height / 2);
            check(Math.abs(point.x - first.width / 2) < 1 && point.y > clockY + 30, "Pill is centred under the clock");
            // A real click reaches the pill, not the island-wide pin handler.
            const pinned = IslandState.islandPinned;
            check(input.mouseClick(pill, pill.width / 2, pill.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Deliver pill click");
            check(IslandState.workspacePanelOpen, "Clicking the pill opens the section");
            check(IslandState.islandPinned === pinned && IslandState.mode === IslandState.expandedMode, "Pill click leaves pin and mode alone");
            next();
            break;
        case 2:
            if (elapsed < 300) return;
            check(first.height > 75, "Island expands downward");
            check(first.panelHeight === first.height, "No drawer height while no OSD shows");
            check(Math.abs(named(first, "expanded-clock-group").mapToItem(first, 0, 0).y - clockY) < 0.01, "Clock stays in place");
            const specials = named(first, "workspace-panel-specials");
            for (const name of ["discordspace", "mediaspace", "scratchpad", "socialspace"])
                check(named(specials, "workspace-panel-special-" + name) !== null, "Special " + name);
            const line = named(first, "workspace-panel-line");
            check(named(line, "workspace-panel-workspace-control") !== null && named(line, "workspace-panel-mission-control") !== null, "Overview toggles");
            check(shown(first, "workspace-panel-workspace-1") !== null, "Persistent workspaces listed");
            const centerY = item => item.mapToItem(first, 0, item.height / 2).y;
            const lineY = centerY(shown(first, "workspace-panel-workspace-1"));
            check(Math.abs(centerY(named(line, "workspace-panel-special-discordspace")) - lineY) < 1.5
                && Math.abs(centerY(named(line, "workspace-panel-mission-control")) - lineY) < 1.5, "Workspaces, specials and overview toggles share one line");
            const order = ["workspace-panel-workspace-1", "workspace-panel-special-discordspace", "workspace-panel-workspace-control"]
                .map(name => (shown(first, name) ?? named(line, name)).mapToItem(first, 0, 0).x);
            check(order[0] < order[1] && order[1] < order[2], "Order is workspaces, specials, overview toggles");
            const lastChip = named(line, "workspace-panel-mission-control");
            const right = lastChip.mapToItem(first, lastChip.width, 0).x;
            const firstChip = shown(first, "workspace-panel-workspace-1").mapToItem(first, 0, 0).x;
            check(right <= first.width && firstChip >= 0, "Section fits inside the island width: " + firstChip + ".." + right + " of " + first.width);
            settings({workspaceStyle: "dots", workspaceDotSize: 8, workspaceExpandedInheritStyle: true});
            next();
            break;
        case 3: {
            // Inheriting the switcher style: dots like the workspace OSD instead of numbered chips.
            if (elapsed < 200) return;
            const holder = named(first, "workspace-panel-dots");
            check(holder.visible && !named(first, "workspace-panel-workspaces").visible, "Inherited dots style shows dots, not chips");
            check(shown(first, "workspace-panel-workspace-2").width === 8 && shown(first, "workspace-panel-workspace-1").width === 18, "Inherited dots use the switcher dot size and a widened active dot");
            check(first.width >= first.height && first.height > 75, "Island keeps a sensible size in dots style");
            settings({workspaceDotSize: 5});
            next();
            break;
        }
        case 4: {
            if (elapsed < 200) return;
            check(shown(first, "workspace-panel-workspace-2").width === 5, "Inherited dot size follows the switcher dot size");
            // A real press on a small dot lands on its (larger) hit area, not on the island's own handlers.
            const dotsRow = named(first, "workspace-panel-dots").children[0];
            let clicked = -1;
            dotsRow.workspaceClicked.connect(id => { clicked = id; });
            const dot = shown(first, "workspace-panel-workspace-2");
            check(input.mouseClick(dot, dot.width / 2, dot.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Deliver dot click");
            check(clicked === 2, "Clicking a dot picks that workspace: " + clicked);
            // Settings -> Workspaces: Expanded switcher style controls follow the inherit switch.
            const panelView = settingsLoader.item;
            const inherit = named(panelView, "workspace-expanded-inherit");
            check(inherit !== null && inherit.checked, "Inherit switch is on when the setting is true");
            check(!named(panelView, "setting-choice-Style").enabled, "Own style is disabled while inheriting");
            settings({workspaceExpandedInheritStyle: false});
            check(!inherit.checked && named(panelView, "setting-choice-Style").enabled, "Turning inherit off enables the own style");
            settings({workspaceExpandedInheritStyle: true});
            // Own style, default: chips even though the switcher uses dots.
            settings({workspaceExpandedInheritStyle: false, workspaceExpandedStyle: "default"});
            next();
            break;
        }
        case 5: {
            if (elapsed < 200) return;
            check(!named(first, "workspace-panel-dots").visible && named(first, "workspace-panel-workspaces").visible, "Own default style shows chips while the switcher uses dots");
            check(shown(first, "workspace-panel-workspace-2").width === 32, "Chip width");
            // Own style, dots with their own size, while the switcher stays on default.
            settings({workspaceStyle: "default", workspaceExpandedStyle: "dots", workspaceExpandedDotSize: 12});
            next();
            break;
        }
        case 6: {
            if (elapsed < 200) return;
            check(named(first, "workspace-panel-dots").visible && shown(first, "workspace-panel-workspace-2").width === 12, "Own dots style uses its own dot size");
            settings({workspaceExpandedInheritStyle: true});
            next();
            break;
        }
        case 7: {
            if (elapsed < 200) return;
            check(!named(first, "workspace-panel-dots").visible && shown(first, "workspace-panel-workspace-2").width === 32, "Inherit switches back to the switcher's default style");
            // A workspace OSD is covered; another OSD drops below the section.
            StatusManager.show({mode: "workspace", monitorName: "HDMI-A-1", icon: "", title: "3", value: 3});
            next();
            break;
        }
        case 8:
            if (elapsed < 240) return;
            check(!first.statusDrawerOpen && first.statusDrawerHeight === 0, "Workspace OSD is suppressed while the section is open");
            StatusManager.show({mode: "volume", monitorName: "HDMI-A-1", icon: "", title: "50%", value: 50});
            next();
            break;
        case 9:
            if (elapsed < 240) return;
            check(first.statusDrawerOpen && first.statusArea.y === first.panelHeight && first.panelHeight > 75, "Volume OSD drops below the section");
            StatusManager.visible = false;
            IslandState.workspacePanelOpen = false;
            next();
            break;
        case 10:
            if (elapsed < 300) return;
            check(first.height === 75, "Section collapses");
            StatusManager.show({mode: "workspace", monitorName: "HDMI-A-1", icon: "", title: "4", value: 4});
            next();
            break;
        case 11:
            if (elapsed < 240) return;
            check(first.statusDrawerOpen, "Regular workspace OSD returns when the section is closed");
            IslandState.workspacePanelOpen = true;
            IslandController.reset();
            next();
            break;
        case 12:
            if (elapsed < 120) return;
            check(!IslandState.workspacePanelOpen, "Leaving expanded mode closes the section");
            console.log("PASS: workspace panel pill, sections, special workspace states, stationary clock, switcher-style inheritance, workspace OSD suppression and OSD drawer below the section");
            Qt.quit();
        }
    }

    TestEvent { id: input }
    FloatingWindow {
        visible: true
        color: "transparent"
        implicitWidth: 900
        implicitHeight: 400
        Island { id: first; x: 20; y: 10; monitorName: "HDMI-A-1"; monitorActive: true }
        Loader {
            id: settingsLoader
            x: 560
            y: 10
            width: 320
            height: 380
            sourceComponent: WorkspaceSettingsView { width: 320 }
        }
    }
    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: phase " + root.phase + ": " + error); Qt.quit(); }
        }
    }
}
