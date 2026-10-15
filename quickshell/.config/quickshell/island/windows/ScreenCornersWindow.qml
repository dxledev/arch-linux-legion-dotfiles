pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "../core"
import "../services"

// The four rounded screen corners for one screen. Each corner is its own small layer surface with
// an empty input mask, so the desktop underneath stays fully clickable.
Scope {
    id: root

    required property ShellScreen screen
    readonly property real cornerRadius: ThemeService.settings.screenCornerRadius ?? 24
    readonly property bool wanted: ThemeService.ready && (ThemeService.settings.screenCorners ?? false)
        && !WorkspaceService.hasFullscreen(Hyprland.monitorFor(root.screen))

    Variants {
        model: [
            { top: true, left: true },
            { top: true, left: false },
            { top: false, left: true },
            { top: false, left: false }
        ]

        PanelWindow {
            id: corner

            required property var modelData

            screen: root.screen
            visible: root.wanted
            color: "transparent"
            focusable: false
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "island-screen-corners"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors {
                top: corner.modelData.top
                bottom: !corner.modelData.top
                left: corner.modelData.left
                right: !corner.modelData.left
            }
            implicitWidth: Math.max(1, root.cornerRadius)
            implicitHeight: Math.max(1, root.cornerRadius)
            mask: Region {}

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                // The top-left shape, mirrored into the other three corners.
                transform: Scale {
                    origin.x: corner.width / 2
                    origin.y: corner.height / 2
                    xScale: corner.modelData.left ? 1 : -1
                    yScale: corner.modelData.top ? 1 : -1
                }

                ShapePath {
                    strokeWidth: -1
                    fillColor: IslandGeometry.surfaceColor
                    startX: 0
                    startY: 0
                    PathLine { x: corner.width; y: 0 }
                    PathArc {
                        x: 0; y: corner.height
                        radiusX: corner.width; radiusY: corner.height
                        direction: PathArc.Counterclockwise
                    }
                    PathLine { x: 0; y: 0 }
                }
            }
        }
    }
}
