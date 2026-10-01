pragma Singleton

import Quickshell

Singleton {
    property bool secretConsumersReady: Quickshell.env("CAELESTIA_START_LOCKED") !== "1" || Quickshell.env("CAELESTIA_NATIVE_LOCK_PROVIDER") === "1"
}
