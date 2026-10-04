import QtQuick
import Quickshell.Services.UPower

Item {
    readonly property int percentage: Math.round(UPower.displayDevice.percentage * 100)
    readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property string status: UPowerDeviceState.toString(UPower.displayDevice.state)
    readonly property string icon: pluggedIn ? "󰂄" : percentage >= 95 ? "󰁹" : percentage >= 75 ? "󰂀" : percentage >= 50 ? "󰁿" : percentage >= 25 ? "󰁾" : percentage >= 10 ? "󰁼" : "󰁺"
}
