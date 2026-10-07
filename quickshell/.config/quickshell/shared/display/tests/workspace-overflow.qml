import QtQuick
import Quickshell
import "caelestia/modules/display/vendor" as Caelestia
import "island/modules/display/vendor" as Island
import "caelestia/modules/display/compat" as CaelestiaKit
import "island/modules/display/compat" as IslandKit

ShellRoot {
    id: root
    property int step: 0
    property var widths: [240, 480, 760, 1100]
    property var fontSizes: [10, 12, 18, 24]
    property var fontFamilies: ["monospace", "DejaVu Sans"]
    property string fontFamily: fontFamilies[0]
    property var cases: [
        ["1", "2", "3", "4", "5"],
        ["1", "special:discordspace", "special:mediaspace", "special:newsspace", "special:scratchpad"],
        ["special:" + "long_workspace_name".repeat(30)],
        Array.from({length: 100}, (_, index) => String(index + 1)),
        [],
        ["12345", "67890", "special:αβγδεζηθ", "special:漢字工作區"]
    ]
    property var ids: cases[0]
    property var profile: ({outputs: [
        {key: "left", name: "Secondary", width: 1920, height: 1080, x: 0, y: 0, scale: 1},
        {key: "right", name: "Primary", width: 2560, height: 1440, x: 1920, y: 0, scale: 1.25}
    ]})
    property var plan: [
        {output_key: "left", workspaces: ids},
        {output_key: "right", workspaces: ids}
    ]

    function check(ok, message) { if (!ok) throw new Error(message) }

    function descendants(item, predicate) {
        var matches = []
        for (const child of item.children) {
            if (predicate(child)) matches.push(child)
            matches = matches.concat(descendants(child, predicate))
        }
        return matches
    }

    function checkCanvas(canvas) {
        const cards = descendants(canvas, item => typeof item.workspaceIds !== "undefined")
        check(cards.length === 2, "two monitor previews")
        for (const card of cards) {
            const rows = descendants(card, item => typeof item.inset !== "undefined" && typeof item.spacing !== "undefined")
            check(rows.length === 1, "one workspace chip row")
            const row = rows[0]
            row.forceLayout()
            if (ids.length === 0) {
                check(!row.visible, "empty workspace row hidden")
                continue
            }
            const maximumWidth = Math.max(0, Math.min(card.width * 0.6, card.width - row.inset * 2))
            check(row.width <= maximumWidth + 1, "chip row exceeds width budget")
            check(row.x >= -0.5 && row.x + row.width <= card.width + 0.5, "workspace chips escape monitor")
            const chips = row.children.filter(item => typeof item.ownerKey !== "undefined")
            check(chips.length === (card.chipsFit ? ids.length : 1), "chip fallback count")
            if (ids.some(id => id.length > 80)) check(!card.chipsFit, "long name uses bounded summary")
            for (const chip of chips) {
                check(chip.x + chip.width <= maximumWidth + 1, "individual chip escapes row")
                for (const label of chip.children) {
                    check(label.width >= 0 && label.x >= -0.5 && label.x + label.width <= chip.width + 0.5, "chip text escapes pill")
                    if (card.chipsFit) check(!label.truncated, "fitting workspace label unexpectedly elided")
                }
            }
        }
    }

    function checkInfo(row) {
        const texts = row.children.filter(item => typeof item.text !== "undefined")
        check(texts.length === 3, "profile workspace columns")
        for (const text of texts) {
            check(text.width >= 0 && text.x >= -0.5 && text.x + text.width <= row.width + 0.5, "profile column escapes row")
            check(text.y >= -0.5 && text.y + text.height <= row.height + 0.5, "profile text escapes row height")
        }
        const values = texts.find(text => text.text === row.workspaces)
        if (ids.some(id => id.length > 80)) check(values.lineCount > 1, "long workspace wraps")
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 1600
        implicitHeight: 900
        color: "#101010"
        Column {
            id: content
            width: 1560
            x: 20; y: 20
            spacing: 20
            Caelestia.DisplayCanvas {
                id: caelestiaCanvas
                width: 760; height: 300
                profile: root.profile; workspacePlan: root.plan
                fontFamily: root.fontFamily
                foreground: "#eeeeee"; dim: "#aaaaaa"; accent: "#ffab91"
            }
            Caelestia.WorkspaceInfoRow {
                id: caelestiaInfo
                width: caelestiaCanvas.width
                label: "Workspaces"; displayName: "Secondary with a long nickname"
                workspaces: root.ids.join(", ")
                fontFamily: root.fontFamily
            }
            Island.DisplayCanvas {
                id: islandCanvas
                width: caelestiaCanvas.width; height: 300
                profile: root.profile; workspacePlan: root.plan
                fontFamily: root.fontFamily
                emphasis: "workspaces"
                foreground: "#eeeeee"; dim: "#aaaaaa"; accent: "#ffab91"
            }
            Island.WorkspaceInfoRow {
                id: islandInfo
                width: caelestiaCanvas.width
                label: "Workspaces"; displayName: "Primary with a long nickname"
                workspaces: root.ids.join(", ")
                fontFamily: root.fontFamily
            }
        }
    }

    Timer {
        interval: 30; running: true; repeat: true
        onTriggered: {
            try {
                if (root.step > 0) {
                    root.checkCanvas(caelestiaCanvas)
                    root.checkCanvas(islandCanvas)
                    root.checkInfo(caelestiaInfo)
                    root.checkInfo(islandInfo)
                }
                const total = root.widths.length * root.fontSizes.length * root.fontFamilies.length * root.cases.length
                if (root.step === total) {
                    caelestiaCanvas.width = 1100
                    CaelestiaKit.Style.fontBaseSize = 12
                    IslandKit.Style.fontBaseSize = 12
                    root.ids = root.cases[1]
                    root.step++
                    return
                }
                if (root.step > total) {
                    stop()
                    Qt.callLater(function() {
                        content.grabToImage(function(result) {
                            root.check(result.saveToFile(Quickshell.env("DISPLAY_WORKSPACE_IMAGE")), "save rendered screenshot")
                            console.log("PASS: workspace overflow, both editors, 192 cases, compact previews, long names, many IDs, empty plans, font size/family changes and wrapped profile rows")
                            Qt.quit()
                        })
                    })
                    return
                }
                const familyIndex = root.step % root.fontFamilies.length
                const widthIndex = Math.floor(root.step / root.fontFamilies.length) % root.widths.length
                const fontIndex = Math.floor(root.step / (root.widths.length * root.fontFamilies.length)) % root.fontSizes.length
                const caseIndex = Math.floor(root.step / (root.widths.length * root.fontSizes.length * root.fontFamilies.length))
                root.fontFamily = root.fontFamilies[familyIndex]
                caelestiaCanvas.width = root.widths[widthIndex]
                CaelestiaKit.Style.fontBaseSize = root.fontSizes[fontIndex]
                IslandKit.Style.fontBaseSize = root.fontSizes[fontIndex]
                root.ids = root.cases[caseIndex]
                root.step++
            } catch (error) {
                console.error("FAIL:", error, "step", root.step)
                Qt.quit()
            }
        }
    }
}
