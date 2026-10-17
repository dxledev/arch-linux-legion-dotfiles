import QtQuick
import Quickshell
import "../core"
import "../services"
import "../styles"

// The expanded island's workspace section, on one line: persistent workspaces, special
// workspaces (greyed out while empty) and the two overview toggles.
Item {
    id: root

    property string monitorName: ""
    readonly property var screen: (QsWindow.window as QsWindow)?.screen ?? Quickshell.screens.find(screen => screen.name === monitorName) ?? null
    readonly property var monitor: screen ? Compositor.monitorFor(screen) : null
    readonly property var activeWorkspace: WorkspaceService.showAllMonitors ? Compositor.focusedWorkspace : monitor?.activeWorkspace
    readonly property var entries: WorkspaceService.workspaceEntries(
        WorkspaceService.workspacesForMonitor(Compositor.workspaces, monitor?.name, WorkspaceService.showAllMonitors),
        WorkspaceService.rules.length === 0 ? null
            : WorkspaceService.persistentForMonitor(WorkspaceService.rules, monitor, WorkspaceService.showAllMonitors),
        ThemeService.settings.workspacePersistent ?? true,
        ThemeService.settings.workspaceCount ?? 11,
        activeWorkspace?.id ?? 1)
    readonly property var specials: WorkspaceService.specialEntries(
        Compositor.workspaces, Compositor.toplevels, WorkspaceService.rules,
        monitor?.lastIpcObject?.specialWorkspace?.name ?? "")
    readonly property string home: Quickshell.env("HOME")
    // Settings -> Workspaces: the expanded row inherits the switcher (OSD) style unless it has its own.
    readonly property bool inheritStyle: ThemeService.settings.workspaceExpandedInheritStyle ?? true
    readonly property bool dotsStyle: inheritStyle
        ? ThemeService.settings.workspaceStyle === "dots"
        : ThemeService.settings.workspaceExpandedStyle === "dots"
    readonly property int dotSize: inheritStyle
        ? ThemeService.settings.workspaceDotSize ?? 8
        : ThemeService.settings.workspaceExpandedDotSize ?? 8

    implicitWidth: line.implicitWidth + 36
    implicitHeight: line.implicitHeight + 34 + recordControls.implicitHeight + recordControls.topGap

    // Nerd Font glyphs (Material Design range) are built from code points so the source stays ASCII.
    function glyph(codePoint) { return String.fromCodePoint(codePoint); }

    function specialIcon(name) {
        switch (name) {
        case "discordspace": return glyph(0xf066f);
        case "mediaspace": return glyph(0xf04c7);
        case "scratchpad": return glyph(0xf040);
        case "socialspace": return glyph(0xf02fe);
        default: return glyph(0xf005);
        }
    }

    function specialLabel(name) {
        const labels = {discordspace: "Discord", mediaspace: "Media", scratchpad: "Scratchpad", socialspace: "Social"};
        return labels[name] ?? name.charAt(0).toUpperCase() + name.slice(1);
    }

    function focusWorkspace(id) {
        Compositor.focusWorkspace(id, monitor?.name);
    }

    function toggleSpecial(name) {
        Quickshell.execDetached([home + "/bin/hypr-focus-special-workspace", name]);
    }

    function toggleOverview(script) {
        Compositor.toggleOverview(script);
        IslandController.reset();
    }

    // One line: persistent workspaces, special workspaces, then the two overview toggles.
    // Plain buttons on the island itself, a wider gap between the groups.
    Row {
        id: line
        objectName: "workspace-panel-line"
        y: 6
        spacing: 24
        anchors.horizontalCenter: parent.horizontalCenter

        Item {
            id: workspacesGroup
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(dotsHolder.visible ? dotsHolder.width : 0, workspaceRow.visible ? workspaceRow.width : 0)
            height: Math.max(dotsHolder.height, workspaceRow.height)

            Item {
                id: dotsHolder
                objectName: "workspace-panel-dots"
                visible: root.dotsStyle
                width: workspaceDots.width
                height: Math.max(workspaceDots.height, 28)
                WorkspaceDots {
                    id: workspaceDots
                    anchors.verticalCenter: parent.verticalCenter
                    interactive: true
                    namePrefix: "workspace-panel-workspace-"
                    workspaces: WorkspaceService.workspacesForMonitor(Compositor.workspaces, root.monitor?.name, WorkspaceService.showAllMonitors)
                    activeWorkspace: root.activeWorkspace?.id ?? 1
                    persistentIds: WorkspaceService.rules.length === 0 ? null
                        : WorkspaceService.persistentForMonitor(WorkspaceService.rules, root.monitor, WorkspaceService.showAllMonitors)
                    persistent: ThemeService.settings.workspacePersistent ?? true
                    persistentCount: ThemeService.settings.workspaceCount ?? 11
                    animationDuration: ThemeService.settings.workspaceAnimationDuration ?? 160
                    dotSize: root.dotSize
                    onWorkspaceClicked: workspaceId => root.focusWorkspace(workspaceId)
                }
            }

            Row {
                id: workspaceRow
                objectName: "workspace-panel-workspaces"
                visible: !root.dotsStyle
                spacing: 6
                Repeater {
                    model: root.entries
                    WorkspaceChip {
                        required property var modelData
                        objectName: "workspace-panel-workspace-" + modelData.id
                        text: String(modelData.id)
                        active: modelData.id === (root.activeWorkspace?.id ?? -1)
                        dimmed: !modelData.occupied
                        description: "Workspace " + modelData.id
                        onClicked: root.focusWorkspace(modelData.id)
                    }
                }
            }
        }

        Row {
            objectName: "workspace-panel-specials"
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Repeater {
                model: root.specials
                WorkspaceChip {
                    required property var modelData
                    objectName: "workspace-panel-special-" + modelData.name
                    text: root.specialIcon(modelData.name)
                    fontSize: 15
                    active: modelData.active
                    dimmed: !modelData.occupied
                    description: root.specialLabel(modelData.name) + (modelData.occupied ? "" : " (empty)")
                    onClicked: root.toggleSpecial(modelData.name)
                }
            }
        }

        Row {
            objectName: "workspace-panel-overview"
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            WorkspaceChip {
                objectName: "workspace-panel-workspace-control"
                iconSource: "../assets/icons/workspaces.svg"
                description: "Workspace control"
                onClicked: root.toggleOverview("hypr-toggle-workspace-control")
            }
            WorkspaceChip {
                objectName: "workspace-panel-mission-control"
                // niri has a single overview, which the first button already opens.
                visible: !Compositor.niri
                iconSource: "../assets/icons/grid.svg"
                description: "Mission control"
                onClicked: root.toggleOverview("hypr-toggle-mission-control")
            }
        }
    }

    // Screen recording controls on a line of their own under the workspaces.
    RecordControls {
        id: recordControls
        readonly property real topGap: 10
        y: line.y + line.height + topGap
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
