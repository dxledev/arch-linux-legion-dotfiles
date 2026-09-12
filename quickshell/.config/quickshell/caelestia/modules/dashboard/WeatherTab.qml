import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    property bool showHourlyForecast: false
    property bool use24Hour: !GlobalConfig.services.useTwelveHourClock
    property int hourlyForecastHours: 7
    property double now: Date.now()
    readonly property date locationNow: new Date(now + (Number.isFinite(Weather.utcOffsetSeconds) ? Weather.utcOffsetSeconds : 0) * 1000)
    readonly property string locationTime: Number.isFinite(Weather.utcOffsetSeconds)
        ? formatHour(locationNow.getUTCHours(), locationNow.getUTCMinutes()) : "--:--"

    function formatHour(hour, minute): string {
        const minutes = String(minute).padStart(2, "0");
        return use24Hour ? String(hour).padStart(2, "0") + ":" + minutes
            : (hour % 12 || 12) + ":" + minutes + (hour >= 12 ? " PM" : " AM");
    }

    function forecastHour(timestamp): string {
        const time = timestamp.split("T")[1].split(":");
        return formatHour(Number(time[0]), Number(time[1]));
    }

    WeatherLocations { id: locations }

    WeatherLocationPicker {
        id: locationPicker
        locations: locations
        x: locationTitle.mapToItem(root, 0, 0).x
        y: locationTitle.mapToItem(root, 0, locationTitle.height).y + 6
    }

    MouseArea {
        anchors.fill: parent
        z: 20
        visible: locationPicker.visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: locationPicker.close()
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = Date.now()
    }

    implicitWidth: layout.implicitWidth > 800 ? layout.implicitWidth : 840
    implicitHeight: layout.implicitHeight
    Component.onCompleted: Weather.reload()

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            Layout.fillWidth: true

            Column {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    id: locationTitle
                    text: locations.displayName || Tr.tr("Loading...")
                    HoverHandler {
                        id: locationHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: locationPicker.visible ? locationPicker.close() : locationPicker.open()
                    }
                    font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                    color: locationHover.hovered ? Colours.palette.m3primary : Colours.palette.m3onSurface
                }

                StyledText {
                    text: Number.isFinite(Weather.utcOffsetSeconds)
                        ? new Date(root.locationNow.getUTCFullYear(), root.locationNow.getUTCMonth(), root.locationNow.getUTCDate()).toLocaleDateString(Qt.locale(), "dddd, MMMM d") : ""
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Row {
                spacing: Tokens.spacing.largeIncreased

                WeatherStat {
                    icon: "schedule"
                    label: Tr.tr("Time")
                    value: root.locationTime
                    colour: timeHover.hovered ? Colours.palette.m3primary : Colours.palette.m3tertiary
                    HoverHandler {
                        id: timeHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler { onTapped: root.use24Hour = !root.use24Hour }
                }

                WeatherStat {
                    icon: "wb_twilight"
                    label: Tr.tr("Sunrise")
                    value: Weather.sunrise
                    colour: Colours.palette.m3tertiary
                }

                WeatherStat {
                    icon: "bedtime"
                    label: Tr.tr("Sunset")
                    value: Weather.sunset
                    colour: Colours.palette.m3tertiary
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: bigInfoRow.implicitHeight + Tokens.padding.small

            radius: Tokens.rounding.extraLarge * 2
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: bigInfoRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: Weather.icon
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(3).build()
                    color: Colours.palette.m3secondary
                    animate: true
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -Tokens.spacing.small

                    StyledText {
                        text: Weather.temp
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Medium).build()
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.leftMargin: Tokens.padding.extraSmall
                        text: Weather.description
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            DetailCard {
                icon: "water_drop"
                label: Tr.tr("Humidity")
                value: Strings.percent(Weather.humidity)
                colour: Colours.palette.m3secondary
            }
            DetailCard {
                icon: "thermostat"
                label: Tr.trCtx("Feels like", "apparent temperature")
                value: Weather.feelsLike
                colour: Colours.palette.m3primary
            }
            DetailCard {
                icon: "air"
                label: Tr.tr("Wind")
                value: Weather.windSpeed ? Tr.tr("%1 km/h").arg(Weather.windSpeed) : "--"
                colour: Colours.palette.m3tertiary
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            Layout.leftMargin: Tokens.padding.medium
            visible: forecastRepeater.count > 0
            Layout.fillWidth: true
            text: root.showHourlyForecast ? Tr.tr("Hourly Forecast") : Tr.tr("7-Day Forecast")
            HoverHandler {
                id: forecastHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler { onTapped: root.showHourlyForecast = !root.showHourlyForecast }
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
            color: forecastHover.hovered ? Colours.palette.m3primary : Colours.palette.m3onSurface
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Repeater {
                id: forecastRepeater

                model: root.showHourlyForecast ? Weather.hourlyForecast.slice(0, root.hourlyForecastHours) : Weather.forecast

                StyledRect {
                    id: forecastItem

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: forecastItemColumn.implicitHeight + Tokens.padding.medium * 2

                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: forecastItemColumn

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: forecastItem.index === 0 ? (root.showHourlyForecast ? Tr.tr("Now") : Tr.trCtx("Today", "forecast column")) : new Date(root.showHourlyForecast ? forecastItem.modelData.timestamp : forecastItem.modelData.date).toLocaleDateString(Qt.locale(), "ddd")
                            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            Layout.topMargin: -Tokens.spacing.extraSmall
                            Layout.alignment: Qt.AlignHCenter
                            text: root.showHourlyForecast ? root.forecastHour(forecastItem.modelData.timestamp) : new Date(forecastItem.modelData.date).toLocaleDateString(Qt.locale(), "MMM d")
                            font: Tokens.font.body.small
                            opacity: 0.7
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: forecastItem.modelData.icon
                            fontStyle: Tokens.font.icon.extraLarge
                            color: Colours.palette.m3secondary
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Hi: " + Weather.formatTemp(root.showHourlyForecast ? Math.max(forecastItem.modelData.tempC, forecastItem.modelData.feelsLikeC) : forecastItem.modelData.maxTempC, true)
                            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                            color: Colours.palette.m3tertiary
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Lo: " + Weather.formatTemp(root.showHourlyForecast ? Math.min(forecastItem.modelData.tempC, forecastItem.modelData.feelsLikeC) : forecastItem.modelData.minTempC, true)
                            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                            color: Colours.palette.m3tertiary
                        }
                    }
                }
            }
        }
    }

    component DetailCard: StyledRect {
        id: detailRoot

        property string icon
        property string label
        property string value
        property color colour

        Layout.fillWidth: true
        Layout.preferredHeight: 60
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainer

        Row {
            anchors.centerIn: parent
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: detailRoot.icon
                color: detailRoot.colour
                fontStyle: Tokens.font.icon.large
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledText {
                    text: detailRoot.label
                    font: Tokens.font.body.small
                    opacity: 0.7
                    horizontalAlignment: Text.AlignLeft
                }
                StyledText {
                    text: detailRoot.value
                    font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
    }

    component WeatherStat: Row {
        id: weatherStat

        property string icon
        property string label
        property string value
        property color colour

        spacing: Tokens.spacing.small

        MaterialIcon {
            text: weatherStat.icon
            fontStyle: Tokens.font.icon.extraLarge
            color: weatherStat.colour
        }

        Column {
            StyledText {
                text: weatherStat.label
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
            StyledText {
                text: weatherStat.value
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                color: Colours.palette.m3onSurface
            }
        }
    }
}
