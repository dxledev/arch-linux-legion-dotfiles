pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> workspaceIconItems: [
        MenuItem {
            text: WorkspaceAppearance.styles[0].name
            icon: WorkspaceAppearance.styles[0].icon
            property string style: WorkspaceAppearance.styles[0].id
        },
        MenuItem {
            text: WorkspaceAppearance.styles[1].name
            icon: WorkspaceAppearance.styles[1].icon
            property string style: WorkspaceAppearance.styles[1].id
        },
        MenuItem {
            text: WorkspaceAppearance.styles[2].name
            icon: WorkspaceAppearance.styles[2].icon
            property string style: WorkspaceAppearance.styles[2].id
        }
    ]

    title: Tr.tr("Workspaces")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SelectRow {
            first: true
            label: Tr.tr("Workspace icons")
            subtext: Tr.tr("Choose how workspace indicators are displayed")
            menuItems: root.workspaceIconItems
            active: root.workspaceIconItems.find(item => item.style === WorkspaceAppearance.style)
            onSelected: item => WorkspaceAppearance.selectStyle(item.style)
        }

        StepperRow {
            label: Tr.trCtx("Shown", "number of workspaces")
            subtext: Tr.tr("Number of workspaces displayed")
            value: Config.bar.workspaces.shown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.shown = v
        }

        ToggleRow {
            // TRANSLATORS: the three following labels name visual decorations drawn on the workspace pill
            text: Tr.tr("Active indicator")
            checked: Config.bar.workspaces.activeIndicator
            onToggled: GlobalConfig.bar.workspaces.activeIndicator = checked
        }

        ToggleRow {
            text: Tr.tr("Active trail")
            checked: Config.bar.workspaces.activeTrail
            onToggled: GlobalConfig.bar.workspaces.activeTrail = checked
        }

        ToggleRow {
            text: Tr.tr("Occupied background")
            checked: Config.bar.workspaces.occupiedBg
            onToggled: GlobalConfig.bar.workspaces.occupiedBg = checked
        }

        ToggleRow {
            text: Tr.tr("Show windows")
            subtext: Tr.tr("Show icons of open windows on each workspace")
            checked: Config.bar.workspaces.showWindows
            onToggled: GlobalConfig.bar.workspaces.showWindows = checked
        }

        ToggleRow {
            text: Tr.tr("Windows on special workspaces")
            checked: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: GlobalConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked
        }

        StepperRow {
            // TRANSLATORS: maximum number of window icons shown per workspace
            label: Tr.tr("Max window icons")
            value: Config.bar.workspaces.maxWindowIcons
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.maxWindowIcons = v
        }

        ToggleRow {
            last: true
            text: Tr.tr("Per-monitor workspaces")
            subtext: Tr.tr("Show each monitor's workspaces independently")
            checked: GlobalConfig.bar.workspaces.perMonitorWorkspaces
            onToggled: GlobalConfig.bar.workspaces.perMonitorWorkspaces = checked
        }
    }
}
