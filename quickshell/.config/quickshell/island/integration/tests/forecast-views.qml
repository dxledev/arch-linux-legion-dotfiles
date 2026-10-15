import QtQuick
import Quickshell
import "../../views"
import "../../core"
import "../../island"
import "../../services"
import "../../services/WeatherData.js" as Data

ShellRoot {
    id: root
    property int phase: 0
    property int ticks: 0
    property string movedKey: ""
    property string firstQuote: ""
    property real calendarWidth: 0
    property real calendarHeight: 0
    IslandIPC { id: ipc }

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children ?? []) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    function allNamed(item, name, out = []) {
        if (!item) return out;
        if (item.objectName === name) out.push(item);
        for (const child of item.children ?? []) allNamed(child, name, out);
        return out;
    }

    function keyFor(offset) {
        const day = new Date();
        day.setDate(day.getDate() + offset);
        return DashboardTasksService.dateKey(day);
    }

    function fahrenheit(celsius) { return Math.round(celsius * 9 / 5 + 32) + "°"; }

    FloatingWindow {
        visible: true
        implicitWidth: 860
        implicitHeight: 620
        // Stands in for ViewHost: the mode picks the panel, and every switch builds a fresh one.
        Loader {
            id: host
            anchors.fill: parent
            sourceComponent: IslandState.mode === IslandState.forecastMode ? forecastPanel
                : IslandState.mode === IslandState.calendarMode ? calendarPanel : null
        }
    }
    Component { id: calendarPanel; CalendarView {} }
    Component { id: forecastPanel; ForecastView {} }

    function step() {
        if (!ThemeService.ready || !DashboardTasksService.ready) return;
        const view = host.item;
        if (phase === 0) {
            IslandController.setMode(IslandState.expandedMode, "HDMI-A-1");
            IslandController.openCalendar();
            check(IslandState.mode === IslandState.calendarMode, "Calendar opens");
            phase = 1;
        } else if (phase === 1) {
            check(view && view.objectName === "calendar-view", "Calendar is showing");
            // With FORECAST_SHOT set, the calendar is saved next to the forecast image for review.
            const shot = Quickshell.env("FORECAST_SHOT");
            if (shot && !root.calendarShotSaved) {
                if (!root.calendarShotRequested) {
                    root.calendarShotRequested = true;
                    host.grabToImage(result => { result.saveToFile(shot.replace(/\.png$/, "-calendar.png")); root.calendarShotSaved = true; });
                }
                return;
            }
            check(IslandState.calendarReturnMode === IslandState.expandedMode, "Calendar remembers the expanded island");
            const button = named(view, "calendar-forecast-button");
            check(button && button.opacity === 1, "Forecast button is on for today");
            check(view.forecastAvailable, "Today has a forecast");
            const pane = named(view, "calendar-day-pane");
            const title = named(view, "calendar-day-title");
            check(button.x + button.width <= pane.width - 20 + 0.5 && button.x >= title.mapToItem(pane, 0, 0).x + title.width, "Forecast button sits beside the day title inside the pane");
            check(title.width >= 150, "The day title keeps room for 'Wednesday', saw " + title.width);
            // Range: today through 15 days ahead.
            view.select(new Date(2020, 0, 1));
            check(!view.forecastAvailable && named(view, "calendar-forecast-button").opacity < 1, "A past day has no forecast");
            view.openForecast();
            check(IslandState.mode === IslandState.calendarMode, "A past day cannot open the forecast");
            const last = new Date(); last.setDate(last.getDate() + 14);
            view.select(last);
            check(view.forecastAvailable, "Day 14 is inside the range");
            last.setDate(last.getDate() + 1);
            view.select(last);
            check(!view.forecastAvailable, "Day 15 is outside the range");
            const target = new Date(); target.setDate(target.getDate() + 3);
            view.select(target);
            check(view.forecastAvailable, "Three days ahead has a forecast");
            root.firstQuote = view.quote.q;
            root.calendarWidth = view.implicitWidth;
            root.calendarHeight = view.implicitHeight;
            view.openForecast();
            check(IslandState.mode === IslandState.forecastMode, "Forecast button opens the forecast panel");
            check(IslandState.calendarReturnMode === IslandState.expandedMode, "Forecast keeps the calendar's way back");
            check(IslandState.calendarSelectedKey === root.keyFor(3), "Forecast carries the selected day");
            check(IslandState.modal, "Forecast is a modal panel");
            phase = 2;
        } else if (phase === 2) {
            check(view && view.objectName === "forecast-view", "Forecast is showing");
            if (!WeatherService.forecast) return;
            check(WeatherService.forecast.days.length === 15, "Fifteen days arrive");
            check(view.implicitWidth === root.calendarWidth && view.implicitHeight === root.calendarHeight,
                "Forecast is the calendar's size (" + view.implicitWidth + "x" + view.implicitHeight + " vs " + root.calendarWidth + "x" + root.calendarHeight + ")");
            check(view.selectedKey === root.keyFor(3), "Forecast opens on the calendar's day");
            check(view.day && view.day.key === root.keyFor(3), "The day resolves from the forecast");
            // Day 3 peaks at 23 C and the fixture's code for day 3 is light rain.
            check(named(view, "forecast-high").text === root.fahrenheit(23), "High shows in Fahrenheit, saw " + named(view, "forecast-high").text);
            check(named(view, "forecast-low").text === root.fahrenheit(13) + " low", "Low shows next to it");
            check(named(view, "forecast-condition").text === "Light rain", "Condition reads from the code");
            check(allNamed(view, "forecast-days").length === 1 && named(view, "forecast-days").count === 15, "Day list holds fifteen rows");
            check(view.hours.length === 24, "Hourly data covers the day");
            check(named(view, "forecast-readout").text.length > 0, "Readout names an hour");
            check(WeatherService.placeName === "", "Coordinates alone give no place name");
            check(Data.formatTemp(view.shownEntry.tempC, "Fahrenheit").endsWith("°"), "Readout hour has a temperature");
            // Stepping days moves the shared selection.
            view.step(1);
            check(view.selectedKey === root.keyFor(4) && IslandState.calendarSelectedKey === root.keyFor(4), "Next day updates the shared selection");
            check(named(view, "forecast-high").text === root.fahrenheit(24), "Next day shows its own high");
            view.select(root.keyFor(0));
            check(view.selectedKey === root.keyFor(0), "Today selects");
            view.step(-1);
            check(view.selectedKey === root.keyFor(0), "Stepping back from today stays on today");
            view.select(root.keyFor(14));
            view.step(1);
            check(view.selectedKey === root.keyFor(14), "Stepping past the last day stays on it");
            view.select(root.keyFor(5));
            root.movedKey = root.keyFor(5);
            check(named(view, "forecast-status").text.startsWith("Updated "), "Status says when the forecast arrived");
            phase = 3;
        } else if (phase === 3) {
            // Grab the panel for review when asked.
            const shot = Quickshell.env("FORECAST_SHOT");
            if (shot && !root.shotRequested) {
                root.shotRequested = true;
                host.grabToImage(result => { result.saveToFile(shot); root.shotSaved = true; });
                return;
            }
            if (shot && !root.shotSaved) return;
            IslandController.backFromForecast();
            check(IslandState.mode === IslandState.calendarMode, "Back from the forecast returns to the calendar");
            check(IslandState.calendarReturnMode === IslandState.expandedMode, "Back keeps the calendar's way back");
            phase = 4;
        } else if (phase === 4) {
            check(view && view.objectName === "calendar-view", "Calendar is showing again");
            check(view.selectedKey === root.movedKey, "Calendar reopens on the day last viewed in the forecast");
            check(view.quote && view.quote.q === root.firstQuote, "Calendar keeps its quote across the forecast");
            IslandController.backFromCalendar();
            check(IslandState.mode === IslandState.expandedMode, "Back from the calendar returns to the expanded island");
            check(IslandState.calendarSelectedKey === "" && IslandState.calendarQuote === null, "Leaving both panels clears the shared selection");
            // Closing from the forecast also clears it.
            IslandController.openCalendar();
            IslandController.openForecast(root.keyFor(2), null);
            IslandController.reset();
            check(IslandState.calendarSelectedKey === "", "Closing the forecast clears the shared selection");
            // A day far down the list opens with its row in view, and stays there when fresh data replaces the model.
            IslandController.openCalendar();
            IslandController.openForecast(root.keyFor(12), null);
            phase = 5;
        } else if (phase === 5) {
            check(view && view.objectName === "forecast-view", "Forecast is showing for a late day");
            if (!WeatherService.forecast) return;
            const list = named(view, "forecast-days");
            const row = named(view, "forecast-day-" + root.keyFor(12));
            if (!row) return;
            const top = row.mapToItem(list, 0, 0).y;
            check(top >= -1 && top + row.height <= list.height + 1, "Selected row is inside the list's viewport, top " + top + " of " + list.height);
            WeatherService.refresh();
            phase = 6;
        } else if (phase === 6) {
            if (WeatherService.loading) return;
            const list = named(host.item, "forecast-days");
            const row = named(host.item, "forecast-day-" + root.keyFor(12));
            if (!row) return;
            const top = row.mapToItem(list, 0, 0).y;
            check(top >= -1 && top + row.height <= list.height + 1, "Selected row stays in view after a refresh, top " + top);
            // The calendar shortcut closes the island from the forecast instead of going back.
            ipc.openCalendar();
            check(IslandState.mode === IslandState.defaultMode, "Calendar shortcut closes the island from the forecast");
            console.log("PASS: forecast panel, calendar round trip and cache");
            Qt.quit();
        }
    }

    property bool shotRequested: false
    property bool calendarShotRequested: false
    property bool calendarShotSaved: false
    property bool shotSaved: false

    Timer {
        interval: 120
        running: true
        repeat: true
        onTriggered: {
            try {
                root.ticks++;
                if (root.ticks > 200) throw new Error("timed out in phase " + root.phase + (WeatherService.error ? " (" + WeatherService.error + ")" : ""));
                root.step();
            } catch (error) {
                console.error("FAIL: " + error);
                Qt.quit();
            }
        }
    }
}
