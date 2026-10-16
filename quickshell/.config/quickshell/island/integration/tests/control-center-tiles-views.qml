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

    // Whether any text inside the cards is cut short.
    function truncatedNames(items) {
        const found = [];
        const walk = item => {
            if (item.truncated === true) found.push(item.text + " " + Math.round(item.implicitWidth) + ">" + Math.round(item.width));
            for (const child of item.children) walk(child);
        };
        items.forEach(walk);
        return found.join("|");
    }

    function truncated(items) { return truncatedNames(items) !== ""; }

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

    Loader {
        id: powerProfileLoader
        active: root.phase >= 6
        source: "../../views/PowerProfileView.qml"
    }

    Loader {
        id: protonVpnLoader
        active: root.phase >= 6
        source: "../../views/ProtonVpnView.qml"
    }

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
            width: 630
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
                    const sunshine = root.named(controlCenter, "sunshine-control-card");
                    root.check(wifi && bluetooth && microphone && nightlight && idleLock && media && sunshine,
                               "All seven Control Center tiles render");
                    const bell = root.named(controlCenter, "notifications-button");
                    root.check(bell, "Notifications button renders");
                    const timerCard = root.named(controlCenter, "timer-control-card");
                    root.check(timerCard, "Timer card renders");
                    root.check(Math.abs(sunshine.x - wifi.x) < 1 && Math.abs(bell.x + bell.width - (media.x + media.width)) < 1,
                               "Sunshine, Timer and the notifications button fill the last row edge to edge: " + [sunshine.x, sunshine.width, timerCard.x, timerCard.width, bell.x, bell.width, wifi.x, media.x, media.width].map(Math.round).join(","));
                    root.check(timerCard.x > sunshine.x + sunshine.width && bell.x > timerCard.x + timerCard.width
                                   && Math.abs(bell.y - sunshine.y) < 1 && Math.abs(timerCard.y - sunshine.y) < 1,
                               "Timer sits between Sunshine and the notifications button");
                    root.check(!root.truncated([sunshine, timerCard, bell]), "Nothing in the last row is cut off (idle): " + root.truncatedNames([sunshine, timerCard, bell]));
                    // The timer card: a clock until a timer runs, then a lit icon with a draining ring that pauses it.
                    root.check(timerCard.title === "Timer" && timerCard.subtitle === "Off" && !timerCard.active && timerCard.progress < 0
                                   && String(timerCard.iconSource).endsWith("clock.svg") && !root.named(timerCard, "control-card-progress").visible,
                               "With no timer the card is a plain clock");
                    root.check(TimerService.start(120, "", false), "Start a timer");
                    root.check(timerCard.title === "Active Timer" && /^0[12]:\d\d$/.test(timerCard.subtitle) && timerCard.active
                                   && timerCard.progress > 0.9 && root.named(timerCard, "control-card-progress").visible
                                   && String(timerCard.iconSource).endsWith("clock.svg"),
                               "A running timer lights the icon, shows the time left and the ring: " + timerCard.subtitle);
                    root.check(!root.truncated([sunshine, timerCard, bell]), "Nothing in the last row is cut off (running): " + root.truncatedNames([sunshine, timerCard, bell]));
                    root.click(root.named(timerCard, "control-card-toggle"));
                    root.check(TimerService.leadingPaused && IslandState.mode === IslandState.controlCenterMode
                                   && /^0[12]:\d\d paused$/.test(timerCard.subtitle) && String(timerCard.iconSource).endsWith("player-pause.svg"),
                               "Pressing the icon pauses the timer without leaving: " + timerCard.subtitle);
                    root.check(!root.truncated([sunshine, timerCard, bell]), "Nothing in the last row is cut off (paused): " + root.truncatedNames([sunshine, timerCard, bell]));
                    const frozen = timerCard.subtitle;
                    root.click(root.named(timerCard, "control-card-toggle"));
                    root.check(!TimerService.leadingPaused && timerCard.subtitle === frozen.replace(" paused", ""),
                               "Pressing it again resumes the timer where it stopped: " + timerCard.subtitle);
                    TimerService.cancelAll();
                    root.check(timerCard.title === "Timer" && timerCard.progress < 0, "Cancelling the timer puts the clock back");
                    root.click(root.named(timerCard, "control-card-toggle"));
                    root.check(IslandState.mode === IslandState.timerMode, "With no timer the icon opens the timer panel");
                    IslandState.mode = IslandState.controlCenterMode;
                    root.click(root.named(timerCard, "control-card-navigation"));
                    root.check(IslandState.mode === IslandState.timerMode, "The card's body opens the timer panel");
                    IslandState.mode = IslandState.controlCenterMode;
                    root.check(bell.x > sunshine.x + sunshine.width && Math.abs(bell.y - sunshine.y) < 1,
                               "Notifications button sits to the right of Sunshine");
                    root.check(/^\d+\+?$/.test(bell.subtitle),
                               "Notifications button describes the count");
                    root.check(!NotificationService.doNotDisturb && !bell.active, "Do Not Disturb starts off");
                    root.click(root.named(bell, "control-card-toggle"));
                    root.check(NotificationService.doNotDisturb && bell.active
                                   && IslandState.mode === IslandState.controlCenterMode,
                               "Bell icon turns Do Not Disturb on without navigating");
                    root.check(bell.title === "Do Not Disturb" && bell.subtitle === "Silent mode on",
                               "Do Not Disturb replaces the title and description");
                    root.check(!root.truncated([sunshine, timerCard, bell]), "Nothing in the last row is cut off (Do Not Disturb): " + root.truncatedNames([sunshine, timerCard, bell]));
                    root.click(root.named(bell, "control-card-toggle"));
                    root.check(!NotificationService.doNotDisturb && bell.title === "Alerts",
                               "Bell icon turns Do Not Disturb off");
                    root.click(root.named(bell, "control-card-navigation"));
                    root.check(IslandState.mode === IslandState.notificationsMode,
                               "Notifications body opens the notification panel");
                    IslandState.mode = IslandState.controlCenterMode;
                    root.check(root.named(controlCenter, "open-notifications") === null,
                               "Control Center no longer embeds the notification section");
                    const sunshineOpen = root.named(sunshine, "control-card-trailing");
                    root.check(root.named(sunshine, "control-card-toggle").enabled
                                   && root.named(sunshine, "control-card-navigation").enabled
                                   && sunshineOpen && sunshineOpen.visible && sunshineOpen.enabled,
                               "Sunshine has a toggle, a body toggle and a separate open-page button");
                    root.check(root.named(sunshine, "control-card-trailing") !== null
                                   && !root.named(wifi, "control-card-trailing").visible,
                               "Only Sunshine shows the trailing open-page button");
                    root.click(root.named(sunshine, "control-card-toggle"));
                    root.check(IslandState.mode === IslandState.controlCenterMode,
                               "Sunshine toggle does not navigate away");
                    for (const tile of [nightlight, idleLock]) {
                        root.check(!root.named(tile, "control-card-navigation").enabled,
                                   tile.objectName + " keeps its outer route reserved");
                        root.check(root.named(tile, "control-card-toggle").enabled,
                                   tile.objectName + " keeps its inner toggle enabled");
                    }
                    root.check(root.named(wifi, "control-card-toggle").enabled,
                               "Wi-Fi keeps its inner toggle enabled");
                    root.check(root.named(wifi, "control-card-navigation").enabled,
                               "Wi-Fi outer route is enabled");
                    root.check(root.named(bluetooth, "control-card-toggle").enabled,
                               "Bluetooth keeps its inner toggle enabled");
                    root.check(root.named(bluetooth, "control-card-navigation").enabled,
                               "Bluetooth outer route is enabled");
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
                    root.click(root.named(root.named(root.controlCenter, "bluetooth-control-card"), "control-card-navigation"));
                    root.check(IslandState.mode === IslandState.bluetoothMode,
                               "Bluetooth outer action opens the Bluetooth panel");
                    IslandController.reset();
                    IslandController.openControlCenter();
                    root.next();
                } else if (root.phase === 4) {
                    const sunshineCard = root.named(controlCenter, "sunshine-control-card");
                    root.click(root.named(sunshineCard, "control-card-navigation"));
                    root.check(IslandState.mode === IslandState.controlCenterMode,
                               "Sunshine tile body toggles the service instead of opening the web UI");
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
                    root.next();
                } else if (root.phase === 6) {
                    const power = powerProfileLoader.item;
                    const vpn = protonVpnLoader.item;
                    if (!power || !vpn || root.elapsed < 400) return;
                    root.check(root.named(power, "power-profile-selector") && root.named(power, "power-profile-indicator"),
                               "Power profile panel renders its selector and sliding indicator");
                    root.check(root.named(power, "power-profile-balanced") && root.named(power, "power-profile-power-saver"),
                               "Power profile panel offers Power saver and Balanced");
                    const segment = root.named(power, "power-profile-balanced");
                    const block = segment.contentItem.children[0];
                    root.check(Math.abs(block.y + block.height / 2 - segment.height / 2) < 1,
                               "Power profile icon and label are centred vertically in their segment");
                    root.check(ProtonVpnService.panelUsers === 1 && ProtonVpnService.enabled,
                               "Proton VPN panel holds the service while open");
                    root.check(root.named(vpn, "protonvpn-status-card").height > 0 && root.named(vpn, "protonvpn-status-title").text.length > 0,
                               "Proton VPN panel renders its status");
                    root.next();
                } else if (root.phase === 7) {
                    protonVpnLoader.active = false;
                    root.next();
                } else if (root.phase === 8) {
                    root.check(ProtonVpnService.panelUsers === 0 && !ProtonVpnService.enabled,
                               "Proton VPN service stops polling once its panel closes");
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
