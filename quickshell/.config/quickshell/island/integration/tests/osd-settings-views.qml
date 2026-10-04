pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../views"
import "../../core"
import "../../island"

ShellRoot {
    id: root
    StatusWatcher {}
    FloatingWindow {
        visible: true
        implicitWidth: 800
        implicitHeight: 740
        CompactView { id: dp; monitorName: "DP-1"; monitorActive: false; width: implicitWidth; height: implicitHeight }
        CompactView { id: hdmi; x: 400; monitorName: "HDMI-A-1"; monitorActive: true; width: implicitWidth; height: implicitHeight }
        Loader {
            id: panel
            y: 80
            width: item?.implicitWidth ?? 0
            height: item?.implicitHeight ?? 0
            sourceComponent: clockSettings
        }
    }
    Component { id: clockSettings; ClockSettingsView {} }
    Component { id: osdSettings; OsdSettingsView {} }
    Component { id: mainSettings; SettingsView {} }

    function childrenNamed(item, name) {
        let found = item.objectName === name ? [item] : [];
        for (const child of item.children) found = found.concat(childrenNamed(child, name));
        return found;
    }
    function compactSnapshot(compact) {
        const overlay = childrenNamed(compact, "compact-status")[0];
        const percentages = childrenNamed(overlay, "osd-percentage").filter(label => label.parent.parent.visible);
        const sliders = childrenNamed(overlay, "osd-slider").filter(slider => slider.parent.parent.visible);
        const text = childrenNamed(overlay, "status-label")[0];
        return {showing: compact.showingStatus, width: compact.implicitWidth, height: compact.implicitHeight,
            labels: childrenNamed(overlay, "osd-monitor-label").filter(label => label.visible).map(label => label.text),
            percentages: percentages.map(label => ({text: label.text, visible: label.visible, font: label.font.family,
                size: label.font.pixelSize, bold: label.font.bold})),
            text: {font: text.font.family, size: text.font.pixelSize, bold: text.font.bold},
            sliders: sliders.map(slider => ({width: slider.width, height: slider.height, radius: slider.radius}))};
    }
    IpcHandler {
        target: "osdTest"
        function snapshot(): string {
            const clock = childrenNamed(dp, "clock-label")[0];
            const indicator = childrenNamed(panel.item, "scroll-progress")[0];
            const fill = childrenNamed(indicator, "scroll-progress-fill")[0];
            const title = childrenNamed(panel.item, "panel-title")[0];
            const scroll = childrenNamed(panel.item, panel.item.scrollObjectName)[0];
            const smoothScroll = childrenNamed(scroll, "smooth-scroll")[0];
            return JSON.stringify({ready: ThemeService.ready, busy: ThemeService.busy, error: ThemeService.error,
                settings: ThemeService.settings, dp: root.compactSnapshot(dp), hdmi: root.compactSnapshot(hdmi),
                mode: StatusManager.mode, animation: StatusManager.animationDuration,
                clock: {font: clock.font.family, size: clock.font.pixelSize, bold: clock.font.bold},
                panel: panel.item?.title, choices: childrenNamed(panel.item, "setting-choice-Font").length,
                progress: {value: indicator.progress, scrollable: indicator.scrollable, opacity: indicator.opacity,
                    width: indicator.width, fillWidth: fill.width, height: indicator.height,
                    titleX: title.x, titleY: title.y, titleHeight: title.height, headerHeight: title.parent.parent.height},
                scroll: {position: scroll.contentY - scroll.originY, range: Math.max(0, scroll.contentHeight - scroll.height),
                    destination: smoothScroll.destination - scroll.originY, animating: smoothScroll.animating},
                modal: IslandState.modal});
        }
        function scrollTo(fraction: real): void {
            const scroll = childrenNamed(panel.item, "settings-panel-scroll")[0];
            scroll.contentY = scroll.originY + fraction * Math.max(0, scroll.contentHeight - scroll.height);
        }
        function wheel(distance: real, precise: bool): bool {
            const scroll = childrenNamed(panel.item, panel.item.scrollObjectName)[0];
            return childrenNamed(scroll, "smooth-scroll")[0].scrollBy(distance, precise);
        }
        function keyboard(): void { StatusManager.show({mode: "keyboard", icon: "󰌌", title: "English", value: "EN"}); }
        function save(key: string, value: string): void { ThemeService.setSetting(key, value); }
        function screens(single: bool): void {
            ThemeService.islandScreens = single ? [{name: "HDMI-A-1"}]
                : [{name: "DP-1"}, {name: "HDMI-A-1"}];
        }
        function settingsPanel(name: string): void {
            if (name === "OSD") {
                IslandController.openOsdSettings();
                panel.sourceComponent = osdSettings;
            } else if (name === "Clock") {
                IslandController.openClockSettings();
                panel.sourceComponent = clockSettings;
            } else {
                IslandController.openSettings();
                panel.sourceComponent = mainSettings;
            }
        }
    }
}
