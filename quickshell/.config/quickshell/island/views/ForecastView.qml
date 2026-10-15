pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../components"
import "../core"
import "../island"
import "../services"
import "../styles"
import "../services/WeatherData.js" as Data

// Weather for the day picked in the Calendar: the day's conditions and an hour-by-hour temperature
// curve on the left, the days ahead on the right. Same footprint as the Calendar so the island does
// not resize on the way in or out; Back returns to the Calendar on the same day.
FocusScope {
    id: root
    objectName: "forecast-view"

    readonly property int panelPadding: 24
    readonly property int cardWidth: 420
    // The calendar's card height (it follows the UI font); 443 when opened without the calendar.
    readonly property int cardHeight: IslandState.calendarCardHeight > 0 ? Math.round(IslandState.calendarCardHeight) : 443
    readonly property int sidePaneWidth: 320
    readonly property int innerPadding: 20
    readonly property int chartWidth: cardWidth - innerPadding * 2
    readonly property int chartHeight: 124
    readonly property color rainColor: "#38BDF8"
    readonly property color stormColor: "#A78BFA"

    readonly property string units: WeatherService.units
    readonly property bool twelveHour: WeatherService.twelveHour
    readonly property var forecast: WeatherService.forecast
    readonly property date now: clock.date
    readonly property string todayKey: DashboardTasksService.dateKey(now)
    property string selectedKey: IslandState.calendarSelectedKey || todayKey
    readonly property date selectedDate: dateOf(selectedKey)
    readonly property var day: { WeatherService.forecast; return WeatherService.dayFor(selectedKey) }
    readonly property int dayIndex: forecast && day ? forecast.days.indexOf(day) : -1
    readonly property var placeNow: forecast ? Data.placeNow(forecast.utcOffsetSeconds, now.getTime()) : null
    readonly property var hours: day ? day.hours : []
    readonly property int restingHour: placeNow && placeNow.key === selectedKey ? placeNow.hour : 12
    property int hoverHour: -1
    readonly property int shownHour: hoverHour >= 0 ? hoverHour : restingHour
    readonly property var shownEntry: hours.find(entry => entry.hour === shownHour) ?? null
    readonly property var range: Data.hourRange(hours)
    readonly property real overallLow: forecast ? Math.min.apply(null, forecast.days.map(entry => entry.loC)) : 0
    readonly property real overallHigh: forecast ? Math.max.apply(null, forecast.days.map(entry => entry.hiC)) : 1
    readonly property bool empty: !day

    implicitWidth: panelPadding * 2 + cardWidth + 24 + sidePaneWidth
    implicitHeight: panelPadding * 2 + content.implicitHeight

    Component.onCompleted: {
        WeatherService.ensure()
        forceActiveFocus()
        revealSelected()
    }

    function dateOf(key) {
        const parts = key.split("-").map(Number)
        return new Date(parts[0], parts[1] - 1, parts[2])
    }

    function relativeLabel() {
        const days = Math.round((selectedDate.getTime() - dateOf(todayKey).getTime()) / 86400000)
        if (days === 0) return "Today"
        if (days === 1) return "Tomorrow"
        return "In " + days + " days"
    }

    function select(key) {
        selectedKey = key
        IslandState.calendarSelectedKey = key
        hoverHour = -1
    }

    function step(offset) {
        if (!forecast) return
        const index = Math.max(0, Math.min(forecast.days.length - 1, (dayIndex < 0 ? 0 : dayIndex) + offset))
        select(forecast.days[index].key)
    }

    function toneFor(code) {
        if (code === 0 || code === 1) return Theme.warning
        if (code >= 51 && code <= 67 || code >= 80 && code <= 82) return rainColor
        if (code >= 95) return stormColor
        return Theme.textPrimary
    }

    function iconFor(code, night) {
        return "../assets/icons/" + Data.iconName(code, night) + ".svg"
    }

    function clockText(hour) {
        return Data.formatClock((hour < 10 ? "0" : "") + hour + ":00", twelveHour)
    }

    function updatedText() {
        return WeatherService.fetchedAt > 0
            ? "Updated " + Qt.formatTime(new Date(WeatherService.fetchedAt), twelveHour ? "h:mm AP" : "HH:mm") : ""
    }

    function pointX(index) {
        return hourX(hours[index].hour)
    }

    function pointY(tempC) {
        return 26 + (range.hi - tempC) / (range.hi - range.lo) * 52
    }

    function hourX(hourValue) {
        return 8 + hourValue * (chartWidth - 16) / 23
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // New data replaces the day list's model, which resets its scroll; bring the selected row back.
    function revealSelected() {
        if (dayIndex >= 0) list.positionViewAtIndex(dayIndex, ListView.Contain)
    }
    onDayIndexChanged: Qt.callLater(revealSelected)
    Connections {
        target: WeatherService
        function onForecastChanged() { Qt.callLater(root.revealSelected) }
    }

    onHoursChanged: curve.requestPaint()
    onRangeChanged: curve.requestPaint()
    Connections {
        target: Theme
        function onAccentChanged() { curve.requestPaint() }
    }

    Keys.onEscapePressed: IslandController.reset()
    Keys.onPressed: event => {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
        let handled = true
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_Up: root.step(-1); break
        case Qt.Key_Right:
        case Qt.Key_Down: root.step(1); break
        case Qt.Key_Home:
        case Qt.Key_T: root.select(root.todayKey); break
        case Qt.Key_R: WeatherService.refresh(); break
        default: handled = false
        }
        event.accepted = handled
    }

    Column {
        id: content
        x: root.panelPadding
        y: root.panelPadding
        width: parent.width - root.panelPadding * 2
        spacing: 14

        PanelHeader {
            title: "Forecast"
            trailingText: WeatherService.placeName
            onBack: IslandController.backFromForecast()
        }

        Row {
            width: parent.width
            spacing: 24

            Rectangle {
                id: dayCard
                objectName: "forecast-day-card"
                width: root.cardWidth
                height: root.cardHeight
                radius: 22
                color: Theme.card

                Item {
                    id: dayTitle
                    x: root.innerPadding
                    y: 18
                    width: parent.width - root.innerPadding * 2
                    height: titleColumn.height

                    Column {
                        id: titleColumn
                        width: parent.width - 80
                        spacing: 2
                        UiText {
                            text: root.relativeLabel().toUpperCase()
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                            color: root.selectedKey === root.todayKey ? Theme.accent : Theme.textMuted
                        }
                        UiText {
                            objectName: "forecast-day-title"
                            width: parent.width
                            text: Qt.formatDate(root.selectedDate, "dddd")
                            elide: Text.ElideRight
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                        UiText {
                            text: Qt.formatDate(root.selectedDate, "MMMM d, yyyy")
                            font.pixelSize: 13
                            color: Theme.textSecondary
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        IconButton {
                            objectName: "forecast-previous-day"
                            enabled: root.dayIndex > 0
                            opacity: enabled ? 1 : 0.4
                            iconSource: "../assets/icons/chevron-left.svg"
                            description: "Previous day"
                            onClicked: root.step(-1)
                        }
                        IconButton {
                            objectName: "forecast-next-day"
                            enabled: root.forecast !== null && root.dayIndex < root.forecast.days.length - 1
                            opacity: enabled ? 1 : 0.4
                            iconSource: "../assets/icons/chevron-right.svg"
                            description: "Next day"
                            onClicked: root.step(1)
                        }
                    }
                }

                // Conditions for the day: icon, high and low, then the four numbers worth a glance.
                Item {
                    id: hero
                    objectName: "forecast-hero"
                    visible: !root.empty
                    x: root.innerPadding
                    y: dayTitle.y + dayTitle.height + 14
                    width: dayTitle.width
                    height: 84

                    SvgIcon {
                        id: heroIcon
                        anchors.verticalCenter: parent.verticalCenter
                        source: root.day ? root.iconFor(root.day.code, false) : ""
                        size: 64
                        color: root.day ? root.toneFor(root.day.code) : Theme.textPrimary
                    }
                    Column {
                        anchors.left: heroIcon.right
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        Item {
                            width: highText.width + 10 + lowText.width
                            height: highText.height
                            UiText {
                                id: highText
                                objectName: "forecast-high"
                                text: root.day ? Data.formatTemp(root.day.hiC, root.units) : ""
                                font.pixelSize: 48
                                font.weight: Font.Light
                                color: Theme.textPrimary
                            }
                            UiText {
                                id: lowText
                                objectName: "forecast-low"
                                x: highText.width + 10
                                y: highText.height - height - 10
                                text: root.day ? Data.formatTemp(root.day.loC, root.units) + " low" : ""
                                font.pixelSize: 18
                                color: Theme.textSecondary
                            }
                        }
                        UiText {
                            objectName: "forecast-condition"
                            text: root.day ? Data.condition(root.day.code) : ""
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                    }
                }

                Row {
                    id: stats
                    objectName: "forecast-stats"
                    visible: !root.empty
                    x: root.innerPadding
                    y: hero.y + hero.height + 14
                    spacing: 8
                    Repeater {
                        model: [
                            { label: "Rain", icon: "weather-droplet", value: root.day ? Data.formatPercent(root.day.precip) : "" },
                            { label: "Wind", icon: "weather-wind", value: root.day ? Data.formatWind(root.day.windKmh, root.units) : "" },
                            { label: "Sunrise", icon: "weather-sunrise", value: root.day ? Data.formatClock(root.day.sunrise, root.twelveHour) : "" },
                            { label: "Sunset", icon: "weather-sunset", value: root.day ? Data.formatClock(root.day.sunset, root.twelveHour) : "" }
                        ]
                        Rectangle {
                            id: tile
                            required property var modelData
                            width: (root.chartWidth - 8 * 3) / 4
                            height: 54
                            radius: 14
                            color: Theme.surface
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 12
                                spacing: 3
                                Row {
                                    spacing: 5
                                    SvgIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        source: "../assets/icons/" + tile.modelData.icon + ".svg"
                                        size: 13
                                        color: Theme.textMuted
                                    }
                                    UiText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: tile.modelData.label
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                    }
                                }
                                UiText {
                                    text: tile.modelData.value
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                }
                            }
                        }
                    }
                }

                // Hour readout, then the day's temperature curve. Hover scrubs it; at rest it marks the
                // current hour on today and midday on other days. Night is shaded and the bars along the
                // bottom are the chance of rain.
                UiText {
                    id: readout
                    objectName: "forecast-readout"
                    visible: !root.empty
                    x: root.innerPadding
                    y: stats.y + stats.height + 16
                    width: root.chartWidth
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    color: Theme.textSecondary
                    text: {
                        const entry = root.shownEntry
                        if (!entry) return ""
                        return root.clockText(entry.hour) + "   " + Data.formatTemp(entry.tempC, root.units)
                            + "   " + Data.condition(entry.code) + "   " + Data.formatPercent(entry.precip) + " rain"
                    }
                }

                Item {
                    id: chart
                    objectName: "forecast-chart"
                    visible: !root.empty
                    x: root.innerPadding
                    y: readout.y + readout.height + 6
                    width: root.chartWidth
                    height: root.chartHeight

                    Rectangle {
                        id: nightMorning
                        readonly property real edge: root.day && root.day.sunrise ? root.hourX(Number(root.day.sunrise.slice(0, 2)) + Number(root.day.sunrise.slice(3, 5)) / 60) : 0
                        width: edge
                        height: parent.height
                        radius: 10
                        color: Theme.surface
                        opacity: 0.7
                    }
                    Rectangle {
                        id: nightEvening
                        readonly property real edge: root.day && root.day.sunset ? root.hourX(Number(root.day.sunset.slice(0, 2)) + Number(root.day.sunset.slice(3, 5)) / 60) : parent.width
                        x: edge
                        width: parent.width - edge
                        height: parent.height
                        radius: 10
                        color: Theme.surface
                        opacity: 0.7
                    }

                    Repeater {
                        model: root.hours
                        Rectangle {
                            required property var modelData
                            required property int index
                            width: 6
                            height: Math.max(0, modelData.precip / 100 * 22)
                            x: root.pointX(index) - width / 2
                            y: parent.height - 4 - height
                            radius: 3
                            color: root.rainColor
                            opacity: 0.45
                        }
                    }

                    Canvas {
                        id: curve
                        anchors.fill: parent
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const hours = root.hours
                            if (hours.length < 2) return
                            const points = hours.map((entry, index) => ({ x: root.pointX(index), y: root.pointY(entry.tempC) }))
                            const trace = () => {
                                ctx.moveTo(points[0].x, points[0].y)
                                for (let i = 0; i < points.length - 1; i++) {
                                    const before = points[Math.max(0, i - 1)]
                                    const from = points[i]
                                    const to = points[i + 1]
                                    const after = points[Math.min(points.length - 1, i + 2)]
                                    ctx.bezierCurveTo(from.x + (to.x - before.x) / 6, from.y + (to.y - before.y) / 6,
                                        to.x - (after.x - from.x) / 6, to.y - (after.y - from.y) / 6, to.x, to.y)
                                }
                            }
                            ctx.beginPath()
                            trace()
                            ctx.lineTo(points[points.length - 1].x, height)
                            ctx.lineTo(points[0].x, height)
                            ctx.closePath()
                            ctx.globalAlpha = 0.12
                            ctx.fillStyle = Theme.accent
                            ctx.fill()
                            ctx.globalAlpha = 1
                            ctx.beginPath()
                            trace()
                            ctx.lineWidth = 2.5
                            ctx.lineJoin = "round"
                            ctx.lineCap = "round"
                            ctx.strokeStyle = Theme.accent
                            ctx.stroke()
                        }
                    }

                    // High and low of the day, set beside the curve's own extremes.
                    Repeater {
                        model: root.hours.length > 1 ? [
                            { hi: true, entry: root.hours.reduce((best, entry) => entry.tempC > best.tempC ? entry : best) },
                            { hi: false, entry: root.hours.reduce((best, entry) => entry.tempC < best.tempC ? entry : best) }
                        ] : []
                        UiText {
                            id: extreme
                            required property var modelData
                            x: Math.max(0, Math.min(chart.width - width, root.hourX(modelData.entry.hour) - width / 2))
                            y: root.pointY(modelData.entry.tempC) + (modelData.hi ? -22 : 8)
                            text: Data.formatTemp(modelData.entry.tempC, root.units)
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.textSecondary
                        }
                    }

                    Rectangle {
                        id: marker
                        visible: root.shownEntry !== null
                        readonly property real px: root.shownEntry ? root.hourX(root.shownEntry.hour) : 0
                        x: px - 0.5
                        width: 1
                        height: parent.height
                        color: Theme.textMuted
                        opacity: root.hoverHour >= 0 ? 0.8 : 0.4
                        Behavior on x { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
                    }
                    Rectangle {
                        visible: root.shownEntry !== null
                        width: 10
                        height: 10
                        radius: 5
                        x: marker.px - 5
                        y: root.shownEntry ? root.pointY(root.shownEntry.tempC) - 5 : 0
                        color: Theme.accent
                        border.width: 2
                        border.color: Theme.card
                        Behavior on x { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
                    }

                    HoverHandler {
                        id: scrub
                        onPointChanged: root.hoverHour = Math.max(0, Math.min(23, Math.round((point.position.x - 8) * 23 / (chart.width - 16))))
                        onHoveredChanged: if (!hovered) root.hoverHour = -1
                    }
                }

                Item {
                    id: axis
                    visible: !root.empty
                    x: root.innerPadding
                    y: chart.y + chart.height + 4
                    width: root.chartWidth
                    height: 14
                    Repeater {
                        model: [0, 3, 6, 9, 12, 15, 18, 21]
                        UiText {
                            required property int modelData
                            x: root.hourX(modelData) - width / 2 + (modelData === 0 ? width / 2 - 4 : 0)
                            text: Data.formatHour(modelData, root.twelveHour)
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }
                }

                // No data yet, or none for this day.
                Column {
                    objectName: "forecast-empty"
                    visible: root.empty
                    anchors.centerIn: parent
                    width: parent.width - 80
                    spacing: 12
                    UiText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        font.pixelSize: 14
                        color: WeatherService.error ? Theme.danger : Theme.textSecondary
                        text: WeatherService.loading ? "Loading the forecast…"
                            : WeatherService.error ? WeatherService.error
                            : root.forecast ? "No forecast for this day." : "No forecast yet."
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: !WeatherService.loading
                        width: retryText.implicitWidth + 28
                        height: 32
                        radius: 16
                        color: retryTap.pressed ? Theme.buttonPressed : retryHover.hovered ? Theme.surfaceVariant : Theme.surface
                        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                        Accessible.role: Accessible.Button
                        Accessible.name: "Try again"
                        UiText {
                            id: retryText
                            anchors.centerIn: parent
                            text: "Try again"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                        HoverHandler { id: retryHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: retryTap; onTapped: WeatherService.refresh() }
                    }
                }
            }

            Rectangle {
                id: outlook
                objectName: "forecast-days-pane"
                width: root.sidePaneWidth
                height: root.cardHeight
                radius: 22
                color: Theme.surface

                Item {
                    id: outlookHeader
                    x: 20
                    y: 14
                    width: parent.width - 40
                    height: 36
                    UiText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.forecast ? "Next " + root.forecast.days.length + " days" : "Next days"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }
                    IconButton {
                        id: refreshButton
                        objectName: "forecast-refresh"
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: !WeatherService.loading
                        iconSource: "../assets/icons/refresh.svg"
                        description: "Refresh forecast"
                        onClicked: WeatherService.refresh()
                        RotationAnimator on rotation {
                            running: WeatherService.loading
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                            alwaysRunToEnd: true
                        }
                    }
                }

                ListView {
                    id: list
                    objectName: "forecast-days"
                    x: 10
                    y: outlookHeader.y + outlookHeader.height + 4
                    width: parent.width - 20
                    height: statusLine.y - 6 - y
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.forecast ? root.forecast.days : []

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: modelData.key === root.selectedKey
                        objectName: "forecast-day-" + modelData.key
                        width: ListView.view.width
                        height: 44
                        radius: 14
                        color: selected ? Theme.card : rowHover.hovered ? Theme.surfaceVariant : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                        Accessible.role: Accessible.Button
                        Accessible.name: Qt.formatDate(root.dateOf(modelData.key), "dddd, MMMM d") + ", "
                            + Data.condition(modelData.code) + ", high " + Data.formatTemp(modelData.hiC, root.units)
                            + ", low " + Data.formatTemp(modelData.loC, root.units)

                        UiText {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 50
                            text: modelData.key === root.todayKey ? "Today" : Qt.formatDate(root.dateOf(modelData.key), "ddd d")
                            font.pixelSize: 13
                            font.weight: row.selected ? Font.DemiBold : Font.Normal
                            color: row.selected ? Theme.textPrimary : Theme.textSecondary
                        }
                        SvgIcon {
                            x: 68
                            anchors.verticalCenter: parent.verticalCenter
                            source: root.iconFor(modelData.code, false)
                            size: 20
                            color: root.toneFor(modelData.code)
                        }
                        UiText {
                            x: 96
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            text: modelData.precip >= 20 ? Math.round(modelData.precip) + "%" : ""
                            font.pixelSize: 11
                            color: root.rainColor
                        }
                        UiText {
                            x: 132
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            horizontalAlignment: Text.AlignRight
                            text: Data.formatTemp(modelData.loC, root.units)
                            font.pixelSize: 13
                            color: Theme.textMuted
                        }
                        Rectangle {
                            x: 172
                            anchors.verticalCenter: parent.verticalCenter
                            width: 56
                            height: 4
                            radius: 2
                            color: Theme.surfaceVariant
                            Rectangle {
                                readonly property real span: Math.max(1, root.overallHigh - root.overallLow)
                                x: (row.modelData.loC - root.overallLow) / span * parent.width
                                width: Math.max(4, (row.modelData.hiC - row.modelData.loC) / span * parent.width)
                                height: parent.height
                                radius: 2
                                color: row.selected ? Theme.accent : Theme.textMuted
                            }
                        }
                        UiText {
                            x: 236
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            text: Data.formatTemp(modelData.hiC, root.units)
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.select(row.modelData.key) }
                    }
                }

                UiText {
                    id: statusLine
                    objectName: "forecast-status"
                    x: 20
                    y: parent.height - height - 16
                    width: parent.width - 40
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    color: WeatherService.error ? Theme.danger : Theme.textMuted
                    text: WeatherService.loading ? "Updating…" : WeatherService.error || root.updatedText()
                }
            }
        }
    }
}
