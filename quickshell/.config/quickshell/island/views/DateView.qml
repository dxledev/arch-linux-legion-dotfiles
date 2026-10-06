import QtQuick
import "../styles"
import "../services"

Text {
    id: date

    color: Theme.textSecondary

    font.family: ThemeService.clockFontFamily
    font.pixelSize: 11

    text: Qt.formatDate(new Date(), "ddd, MMM d")

    Timer {
        interval: 60000
        running: true
        repeat: true

        onTriggered: {
            date.text = Qt.formatDate(new Date(), "ddd, MMM d")
        }
    }
}
