import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../core"
import "../../services"

// Clicks the real confirmation buttons inside a full Island: the drawer must sit above the island-wide
// click area, and answering must not pin or expand the island.
ShellRoot {
    id: root
    property bool accepted: false
    property int answered: 0

    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }
    function ask() {
        StatusManager.confirm({monitorName: "HDMI-A-1", title: "Delete 2 wallpapers?", detail: "Files are removed from disk.",
            acceptLabel: "Delete", onAccepted: () => { root.accepted = true; }});
    }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }

    FloatingWindow {
        id: window
        visible: true
        color: "transparent"
        implicitWidth: 900
        implicitHeight: 900
        Island { id: island; x: 100; y: 10; monitorName: "HDMI-A-1" }
        TestCase {
            id: test
            name: "wallpaper-delete"
            when: window.visible

            function clickButton(name) {
                const button = root.named(island.statusArea, name);
                verify(button, name + " missing");
                const point = button.mapToItem(null, button.width / 2, button.height / 2);
                mouseClick(test, point.x, point.y);
            }

            function waitOpen() {
                tryVerify(() => island.statusDrawerOpen && island.statusArea.reveal === 1, 3000, "drawer open");
            }

            function test_confirm() {
                ThemeService.settings = ThemeService.settings || ({});
                IslandController.setMode(IslandState.wallpaperSelectorMode, "HDMI-A-1");
                wait(500);
                const pinned = IslandState.islandPinned;
                const mode = IslandState.mode;

                root.ask();
                waitOpen();
                compare(StatusManager.mode, "confirm");
                clickButton("confirm-cancel");
                verify(!StatusManager.confirming, "cancel resolves");
                verify(!root.accepted, "cancel does not accept");
                compare(IslandState.islandPinned, pinned);
                compare(IslandState.mode, mode);

                wait(400);
                root.ask();
                waitOpen();
                clickButton("confirm-accept");
                verify(!StatusManager.confirming, "accept resolves");
                verify(root.accepted, "accept runs the handler");
                compare(IslandState.islandPinned, pinned);
                compare(IslandState.mode, mode);

                // A click beside the buttons must not reach the island's pin toggle.
                wait(400);
                root.ask();
                waitOpen();
                const title = root.named(island.statusArea, "confirm-title");
                const spot = title.mapToItem(null, 4, title.height / 2);
                mouseClick(test, spot.x, spot.y);
                verify(StatusManager.confirming, "stray click leaves the question open");
                compare(IslandState.islandPinned, pinned);

                // Another OSD replaces the question briefly, then the question returns.
                StatusManager.show({mode: "volume", title: "40%", value: 40, icon: "", monitorName: "HDMI-A-1"});
                compare(StatusManager.mode, "volume");
                verify(StatusManager.confirming, "question survives an interrupting OSD");
                tryVerify(() => StatusManager.mode === "confirm" && StatusManager.visible, 8000, "question returns");
                compare(StatusManager.title, "Delete 2 wallpapers?");
                waitOpen();
                clickButton("confirm-accept");
                verify(!StatusManager.confirming && root.accepted, "returned question still answers");
                console.log("PASS: wallpaper delete confirmation clicks");
            }
            function cleanupTestCase() { quitTimer.start(); }
        }
    }
}
