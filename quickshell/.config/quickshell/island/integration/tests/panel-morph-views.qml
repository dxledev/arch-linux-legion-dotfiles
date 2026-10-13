import QtQuick
import Quickshell
import "../../island"
import "../../core"
import "../../services"
import "../../styles"

ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0
    property var samples: []
    property real baseRadius: 0
    property real targetWidth: 0
    property real targetHeight: 0


    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function viewHostOf(item) {
        if (item.reveal !== undefined && item.settled !== undefined) return item;
        for (const child of item.children) {
            const found = viewHostOf(child);
            if (found) return found;
        }
        return null;
    }

    function next() {
        phase++;
        elapsed = 0;
        samples = [];
    }

    function sample() {
        const host = viewHostOf(capsule);
        samples.push({t: elapsed, opacity: host.opacity, width: capsule.panelWidth, height: capsule.panelHeight,
            radius: capsule.radius, settled: host.settled});
        return host;
    }

    function checkOpening(label) {
        check(samples.length > 3, label + " produced samples");
        check(samples[0].opacity < 0.6, label + " does not appear at full opacity: " + samples[0].opacity);
        for (let i = 1; i < samples.length; i++) {
            check(samples[i].opacity >= samples[i - 1].opacity - 0.001,
                label + " does not dim and fade back in (" + samples[i - 1].opacity + " -> " + samples[i].opacity + ")");
            check(samples[i].width <= targetWidth + 0.5, label + " width never overshoots: " + samples[i].width + " > " + targetWidth);
            check(samples[i].height <= targetHeight + 0.5, label + " height never overshoots");
        }
        const last = samples[samples.length - 1];
        check(last.opacity === 1 && last.settled, label + " settles at full opacity");
        check(Math.abs(last.width - targetWidth) < 0.5 && Math.abs(last.height - targetHeight) < 0.5, label + " reaches its size");
    }

    function tick() {
        elapsed += 40;
        switch (phase) {
        case 0: {
            if (!ThemeService.ready) return;
            ThemeService.settings = {radius: 23, islandAnimationDuration: 300, uiAnimationDuration: 300};
            StatusManager.visible = false;
            IslandController.reset();
            baseRadius = capsule.radius;
            check(baseRadius === 23, "Compact radius is the saved radius");
            ThemeService.settings = {radius: 10, islandAnimationDuration: 300, uiAnimationDuration: 300};
            check(capsule.radius === 10, "Corner radius slider applies immediately: " + capsule.radius);
            ThemeService.settings = {radius: 23, islandAnimationDuration: 300, uiAnimationDuration: 300};
            check(capsule.radius === 23, "Corner radius restores immediately");
            next();
            break;
        }
        case 1:
            if (elapsed < 200) return;
            IslandController.setMode(IslandState.wifiMode, capsule.monitorName);
            check(capsule.panelMorphDuration === 300, "Panel morphs use the Expansion duration");
            next();
            break;
        case 2: {
            const host = sample();
            if (samples.length === 1) {
                targetWidth = host.implicitWidth;
                targetHeight = host.implicitHeight;
                check(capsule.radius < 23 * 1.4 - 0.5, "Radius has not jumped to the panel radius: " + capsule.radius);
            }
            if (elapsed < 900) return;
            checkOpening("Wi-Fi panel");
            const mid = samples.find(s => s.radius > 23.5 && s.radius < 23 * 1.4 - 0.5);
            check(mid !== undefined, "Corner radius morphs through intermediate values");
            check(Math.abs(samples[samples.length - 1].radius - 23 * 1.4) < 0.01, "Radius settles at the panel radius");
            next();
            break;
        }
        case 3:
            IslandController.setMode(IslandState.bluetoothMode, capsule.monitorName);
            next();
            break;
        case 4: {
            const host = sample();
            if (samples.length === 1) {
                targetWidth = Math.max(host.implicitWidth, capsule.panelWidth);
                targetHeight = Math.max(host.implicitHeight, capsule.panelHeight);
                check(host.opacity < 0.6, "Switching panels does not carry the previous panel's opacity: " + host.opacity);
            }
            if (elapsed < 900) return;
            check(samples[samples.length - 1].opacity === 1, "Second panel settles at full opacity");
            check(samples.every(s => s.opacity <= 1.0001), "Opacity never exceeds one");
            next();
            break;
        }
        case 5:
            IslandState.settingsSection = "appearance";
            IslandController.setMode(IslandState.settingsSectionMode, capsule.monitorName);
            next();
            break;
        case 6:
            if (elapsed < 900) return;
            check(viewHostOf(capsule).opacity === 1, "Appearance section settles at full opacity");
            IslandState.settingsSection = "clock";
            next();
            break;
        case 7: {
            const host = sample();
            if (samples.length === 1)
                check(host.opacity < 0.6, "Switching settings sections gates the incoming section: " + host.opacity);
            if (elapsed < 900) return;
            check(samples[samples.length - 1].opacity === 1 && samples[samples.length - 1].settled, "Clock section settles at full opacity");
            check(samples.every((s, i) => i === 0 || s.opacity >= samples[i - 1].opacity - 0.001), "Section switch does not dim and fade back in");
            IslandController.reset();
            next();
            break;
        }
        case 8:
            if (elapsed < 900) return;
            check(capsule.radius === 23, "Radius returns to the compact radius: " + capsule.radius);
            check(viewHostOf(capsule).opacity === 1, "Compact view is visible after closing");
            IslandController.openExpanded(capsule.monitorName);
            check(capsule.hopping && capsule.panelMorphDuration === Math.round(300 * 0.62),
                "Compact to expanded uses the shorter hop: " + capsule.panelMorphDuration);
            next();
            break;
        case 9:
            if (elapsed < 900) return;
            check(viewHostOf(capsule).opacity === 1, "Expanded view settles at full opacity");
            ThemeService.settings = {radius: 23, islandAnimationDuration: 0, uiAnimationDuration: 0};
            Theme.uiAnimationDuration = 0;
            IslandController.reset();
            next();
            break;
        case 10:
            if (elapsed < 200) return;
            IslandController.setMode(IslandState.wifiMode, capsule.monitorName);
            next();
            break;
        case 11: {
            const host = sample();
            if (elapsed < 80) return;
            check(host.opacity === 1 && host.settled, "Zero durations disable the reveal: " + host.opacity);
            check(Math.abs(capsule.panelWidth - host.implicitWidth) < 0.01, "Zero durations jump to the panel size");
            check(Math.abs(capsule.radius - 23 * 1.4) < 0.01, "Zero durations jump to the panel radius");
            Theme.uiAnimationDuration = 300;
            ThemeService.settings = {radius: 23, islandAnimationDuration: 300, uiAnimationDuration: 300, panelAnimationStyle: "classic"};
            IslandController.reset();
            next();
            break;
        }
        case 12:
            if (elapsed < 900) return;
            check(capsule.classicStyle, "Classic style is selected from the saved setting");
            IslandController.setMode(IslandState.wifiMode, capsule.monitorName);
            check(Math.abs(capsule.radius - 23 * 1.4) < 0.01, "Classic radius snaps to the panel radius: " + capsule.radius);
            next();
            break;
        case 13: {
            const host = sample();
            if (samples.length === 1) {
                targetWidth = host.implicitWidth;
                check(host.opacity === 1, "Classic panels swap in at full opacity: " + host.opacity);
            }
            if (elapsed < 900) return;
            check(samples.every(s => s.opacity === 1), "Classic never fades panels");
            const peak = Math.max(...samples.map(s => s.width));
            check(peak > targetWidth + 5, "Classic width overshoots like OutBack: " + peak + " vs " + targetWidth);
            check(Math.abs(samples[samples.length - 1].width - targetWidth) < 0.5, "Classic width settles on its target");
            IslandController.reset();
            next();
            break;
        }
        case 14:
            if (elapsed < 900) return;
            IslandController.openExpanded(capsule.monitorName);
            check(capsule.panelMorphDuration === 300, "Classic has no shortened hop: " + capsule.panelMorphDuration);
            ThemeService.settings = {radius: 23, islandAnimationDuration: 300, uiAnimationDuration: 300, panelAnimationStyle: "morph"};
            IslandController.reset();
            next();
            break;
        case 15:
            if (elapsed < 900) return;
            check(!capsule.classicStyle, "Morph is restored by the saved setting");
            IslandController.setMode(IslandState.wifiMode, capsule.monitorName);
            next();
            break;
        case 16: {
            const host = sample();
            if (samples.length === 1)
                check(host.opacity < 0.6, "Switching back to morph gates panels again: " + host.opacity);
            if (elapsed < 900) return;
            check(samples[samples.length - 1].opacity === 1, "Morph panel settles after switching styles");
            IslandController.reset();
            console.log("PASS: panel morph curve, lockstep radius, gated panel reveal, hop timing, zero-duration behavior and classic style");
            Qt.quit();
            break;
        }
        }
    }

    FloatingWindow {
        visible: false
        implicitWidth: 1200
        implicitHeight: 700
        Island { id: capsule; monitorName: "HDMI-A-1"; monitorActive: true }
    }

    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: " + error); Qt.quit(); }
        }
    }
}
