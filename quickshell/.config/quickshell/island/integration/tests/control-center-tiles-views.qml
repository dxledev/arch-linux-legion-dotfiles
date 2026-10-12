import QtQuick
import QtTest
import Quickshell
import "../../integration/tests/fake-mpris"
import "../../components"
import "../../core"
import "../../island"
import "../../services"
import "../../styles"

ShellRoot {
    id: root

    property int phase: 0
    property int elapsed: 0
    property int iconActions: 0
    property int panelActions: 0
    readonly property var controlCenter: controlCenterLoader.item

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, objectName) {
        if (!item) return null;
        if (item.objectName === objectName) return item;
        for (const child of item.children) {
            const result = named(child, objectName);
            if (result) return result;
        }
        return null;
    }

    function click(item, x, y) {
        check(item, "Pointer target exists");
        check(input.mouseClick(item, x ?? item.width / 2, y ?? item.height / 2,
                               Qt.LeftButton, Qt.NoModifier, 0), "Deliver pointer click");
    }

    function move(item, x, y) {
        check(input.mouseMove(item, x ?? item.width / 2, y ?? item.height / 2,
                              0, Qt.NoButton, Qt.NoModifier), "Deliver pointer movement");
    }

    function sameColor(left, right) {
        return Math.abs(left.r - right.r) < 0.01
            && Math.abs(left.g - right.g) < 0.01
            && Math.abs(left.b - right.b) < 0.01
            && Math.abs(left.a - right.a) < 0.01;
    }

    function next() { phase++; elapsed = 0; }

    TestEvent { id: input }

    FloatingWindow {
        visible: true
        implicitWidth: 1280
        implicitHeight: 1000

        ControlCard {
            id: sampleCard
            objectName: "sample-control-card"
            x: 24
            y: 24
            title: "Sample"
            subtitle: "Interaction probe"
            icon: "x"
            panelEnabled: true
            onIconToggled: root.iconActions++
            onClicked: root.panelActions++
        }

        Loader {
            id: controlCenterLoader
            objectName: "control-center-loader"
            x: 220
            y: 24
            width: 520
            source: "../../views/ControlCenterView.qml"
            onLoaded: item.objectName = "control-center-view"
        }
    }

    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: {
            root.elapsed += interval;
            try {
                if (root.phase === 0) {
                    if (!ThemeService.ready || ThemeService.busy) return;
                    const toggle = root.named(sampleCard, "control-card-toggle");
                    const navigation = root.named(sampleCard, "control-card-navigation");
                    root.check(toggle && navigation, "Control card exposes independent inner and outer buttons");
                    root.check(toggle.enabled && navigation.enabled, "Both sample actions start enabled");
                    root.click(toggle);
                    root.check(root.iconActions === 1 && root.panelActions === 0,
                               "Inner button fires only the icon action");
                    root.click(navigation);
                    root.check(root.iconActions === 1 && root.panelActions === 1,
                               "Outer button fires only the panel action");
                    const outsideIconPoints = [[30, 2], [30, 58], [2, 30], [13, 13], [52, 30]];
                    for (const point of outsideIconPoints) {
                        root.click(sampleCard, point[0], point[1]);
                        root.check(root.iconActions === 1 && root.panelActions === 2 + outsideIconPoints.indexOf(point),
                                   "Click outside the icon circle routes through the card: " + point.join(","));
                    }
                    sampleCard.panelEnabled = false;
                    root.check(!navigation.enabled && toggle.enabled,
                               "Disabling the panel route leaves the icon action enabled");
                    const panelCount = root.panelActions;
                    root.click(navigation);
                    root.click(toggle);
                    root.check(root.iconActions === 2 && root.panelActions === panelCount,
                               "Disabled outer route is a no-op while inner action still works");
                    sampleCard.panelEnabled = true;
                    sampleCard.iconEnabled = false;
                    const disabledIconCount = root.iconActions;
                    root.click(sampleCard, 30, 30);
                    root.check(root.iconActions === disabledIconCount && root.panelActions === panelCount,
                               "Disabled icon circle is reserved from both actions");
                    root.click(sampleCard, 30, 2);
                    root.check(root.iconActions === disabledIconCount && root.panelActions === panelCount + 1,
                               "Outer route remains active beyond a disabled icon circle");
                    sampleCard.iconEnabled = true;
                    root.move(navigation, navigation.width - 8, navigation.height / 2);
                    root.next();
                } else if (root.phase === 1) {
                    if (root.elapsed < 260) return;
                    const toggle = root.named(sampleCard, "control-card-toggle");
                    const navigation = root.named(sampleCard, "control-card-navigation");
                    root.check(navigation.hovered && !toggle.hovered,
                               "Pointer over the panel area hovers only the outer action");
                    root.check(root.sameColor(sampleCard.color, Theme.surfaceVariant),
                               "Outer hover uses the card hover color");
                    root.check(root.sameColor(toggle.background.color, Theme.buttonBackground),
                               "Outer hover does not recolor the inner icon button");
                    root.move(toggle);
                    root.next();
                } else if (root.phase === 2) {
                    if (root.elapsed < 260) return;
                    const toggle = root.named(sampleCard, "control-card-toggle");
                    const navigation = root.named(sampleCard, "control-card-navigation");
                    root.check(toggle.hovered && !navigation.hovered,
                               "Pointer over the icon area hovers only the inner action");
                    root.check(root.sameColor(sampleCard.color, Theme.surface),
                               "Inner hover leaves the card background at its normal color");
                    root.check(root.sameColor(toggle.background.color, Theme.surfaceVariant),
                               "Inner hover uses its own button color");
                    IslandController.openControlCenter();
                    root.next();
                } else if (root.phase === 3) {
                    const wifi = root.named(controlCenter, "wifi-control-card");
                    const bluetooth = root.named(controlCenter, "bluetooth-control-card");
                    const microphone = root.named(controlCenter, "microphone-control-card");
                    const nightlight = root.named(controlCenter, "nightlight-button");
                    const idleLock = root.named(controlCenter, "idle-lock-button");
                    const media = root.named(controlCenter, "media-control-card");
                    root.check(wifi && bluetooth && microphone && nightlight && idleLock && media,
                               "All six Control Center tiles render");
                    for (const tile of [bluetooth, nightlight, idleLock]) {
                        root.check(!root.named(tile, "control-card-navigation").enabled,
                                   tile.objectName + " keeps its outer route reserved");
                        root.check(root.named(tile, "control-card-toggle").enabled,
                                   tile.objectName + " keeps its inner toggle enabled");
                    }
                    root.check(root.named(wifi, "control-card-toggle").enabled,
                               "Wi-Fi keeps its inner toggle enabled");
                    root.check(root.named(wifi, "control-card-navigation").enabled,
                               "Wi-Fi outer route is enabled");
                    root.check(root.named(microphone, "control-card-navigation").enabled,
                               "Microphone outer route is enabled");
                    root.check(root.named(media, "control-card-navigation").enabled,
                               "Media outer route is enabled");
                    root.click(root.named(microphone, "control-card-navigation"));
                    root.check(IslandState.mode === IslandState.audioDevicesMode,
                               "Microphone outer action opens audio device selection");
                    IslandController.reset();
                    IslandController.openControlCenter();
                    root.click(root.named(root.named(root.controlCenter, "wifi-control-card"), "control-card-navigation"));
                    root.check(IslandState.mode === IslandState.wifiMode,
                               "Wi-Fi outer action opens the Wi-Fi panel");
                    IslandController.reset();
                    IslandController.openControlCenter();
                    root.next();
                } else if (root.phase === 4) {
                    const media = root.named(controlCenter, "media-control-card");
                    root.click(root.named(media, "control-card-navigation"));
                    root.check(IslandState.mode === IslandState.mediaControlsMode,
                               "Media outer action opens media controls");
                    IslandController.reset();
                    IslandController.openControlCenter();
                    MediaService.updatePlayer();
                    root.check(MediaService.player === Mpris.players.values[1],
                               "Media service selects the currently playing fake player");
                    root.check(root.named(media, "control-card-toggle").enabled,
                               "Media inner action enables for a controllable fake player");
                    root.next();
                } else if (root.phase === 5) {
                    const media = root.named(controlCenter, "media-control-card");
                    root.click(root.named(media, "control-card-toggle"));
                    root.check(Mpris.players.values[1].toggleCount === 1
                                   && Mpris.players.values[0].toggleCount === 0,
                               "Media inner action toggles only the currently playing fake player");
                    root.check(MediaService.player === Mpris.players.values[1] && !MediaService.isPlaying,
                               "Pausing retains the selected player for a later resume");
                    root.check(IslandState.mode === IslandState.controlCenterMode,
                               "Media inner action does not navigate away");
                    root.click(root.named(media, "control-card-toggle"));
                    root.check(Mpris.players.values[1].toggleCount === 2 && MediaService.isPlaying,
                               "A second media inner action resumes the same player");
                    console.log("PASS: tile action separation, disabled routes, independent hover feedback, and Control Center navigation");
                    Qt.quit();
                }
            } catch (error) {
                console.error("FAIL:", error.message || error);
                Qt.quit();
            }
        }
    }
}
