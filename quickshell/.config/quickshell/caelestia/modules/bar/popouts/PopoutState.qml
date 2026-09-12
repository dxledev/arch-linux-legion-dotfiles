import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent

    signal detachRequested(mode: string)
    signal wifiQrRequested(ssid: string, iface: string)
}
