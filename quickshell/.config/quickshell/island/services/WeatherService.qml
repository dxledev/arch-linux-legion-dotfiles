pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "WeatherData.js" as Data

// Forecast for the Calendar's Forecast panel, fetched the way Caelestia does it: Open-Meteo for the
// forecast and for place-name lookups, ip-api.com to find the machine when no location is set. It only
// talks to the network when the panel asks (ensure()), keeps the last answer in
// <state>/weather.json so reopening is instant and works offline, and a failed refresh never
// replaces good data. Location and units follow Caelestia's `services.weatherLocation` and
// `services.weatherUnits` in ~/.config/caelestia/shell.json; ISLAND_WEATHER_LOCATION ("lat,lon" or a
// city name) and ISLAND_WEATHER_UNITS (Celsius or Fahrenheit) override them.
Singleton {
    id: root

    readonly property string forecastUrlBase: Quickshell.env("ISLAND_WEATHER_URL") || "https://api.open-meteo.com/v1/forecast"
    readonly property string ipLocationUrl: Quickshell.env("ISLAND_WEATHER_LOCATION_URL") || "http://ip-api.com/json?fields=status,message,city,lat,lon"
    readonly property string geocodeUrlBase: Quickshell.env("ISLAND_WEATHER_GEOCODE_URL") || "https://geocoding-api.open-meteo.com/v1/search"
    readonly property string caelestiaConfigPath: Quickshell.env("ISLAND_CAELESTIA_CONFIG")
        || (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/caelestia/shell.json"
    readonly property int maxAgeMs: 30 * 60 * 1000
    readonly property int placeMaxAgeMs: 6 * 60 * 60 * 1000

    // Caelestia's weather settings, read once and again whenever its config file changes.
    property var caelestiaServices: ({})
    readonly property string configuredLocation: Quickshell.env("ISLAND_WEATHER_LOCATION")
        || String(caelestiaServices.weatherLocation || "")
    readonly property string units: Quickshell.env("ISLAND_WEATHER_UNITS") || caelestiaServices.weatherUnits
        || (Qt.locale().name.endsWith("_US") ? "Fahrenheit" : "Celsius")
    readonly property bool twelveHour: ThemeService.settings.clock12Hour ?? false

    // The place being forecast: { lat, lon, city }, and the parsed forecast with when it arrived.
    property var place: null
    property double placeAt: 0
    property string placeKey: ""
    property var forecast: null
    property double fetchedAt: 0

    property string error: ""
    readonly property bool loading: locator.running || fetcher.running
    readonly property bool hasForecast: forecast !== null
    readonly property string locationKey: configuredLocation || "ip"
    readonly property string placeName: place ? place.city : ""

    function isStale() {
        return forecast === null || Date.now() - fetchedAt > maxAgeMs
    }

    function dayFor(key) {
        return Data.findDay(forecast, key)
    }

    // Called each time the panel opens; fetches only when the cache is missing, old or for another place.
    function ensure() {
        if (loading) return
        if (forecast !== null && placeKey !== locationKey) {
            forecast = null
            place = null
        }
        if (isStale()) refresh()
    }

    function refresh() {
        if (loading) return
        error = ""
        const configured = Data.parseCoords(configuredLocation)
        if (configured) {
            useLocation({ lat: configured.lat, lon: configured.lon, city: "" })
        } else if (place !== null && placeKey === locationKey && Date.now() - placeAt < placeMaxAgeMs) {
            fetchForecast()
        } else if (configuredLocation) {
            locator.command = ["curl", "-fsS", "-m", "10", "-A", "island-calendar", "--",
                geocodeUrlBase + "?name=" + encodeURIComponent(configuredLocation) + "&count=1&language=en&format=json"]
            locator.mode = "geocode"
            locator.running = true
        } else {
            locator.command = ["curl", "-fsS", "-m", "10", "-A", "island-calendar", "--", ipLocationUrl]
            locator.mode = "ip"
            locator.running = true
        }
    }

    function useLocation(found) {
        place = found
        placeAt = Date.now()
        placeKey = locationKey
        fetchForecast()
    }

    function fetchForecast() {
        fetcher.command = ["curl", "-fsS", "-m", "15", "-A", "island-calendar", "--", Data.forecastUrl(forecastUrlBase, place)]
        fetcher.running = true
    }

    function describeFailure(what) {
        error = hasForecast ? "Offline. Showing the last forecast." : what
    }

    function save() {
        store.setText(JSON.stringify({
            fetchedAt: fetchedAt, place: place, placeAt: placeAt, placeKey: placeKey, forecast: forecast
        }) + "\n")
    }

    function restore(raw) {
        try {
            const data = JSON.parse(raw)
            const found = data.place
            if (!found || !isFinite(Number(found.lat)) || !isFinite(Number(found.lon))) return
            place = { lat: Number(found.lat), lon: Number(found.lon), city: String(found.city || "") }
            placeAt = Number(data.placeAt) || 0
            placeKey = String(data.placeKey || "")
            const cached = data.forecast
            if (cached && Array.isArray(cached.days) && cached.days.length > 0) {
                forecast = cached
                fetchedAt = Number(data.fetchedAt) || 0
            }
        } catch (failure) {
            // Missing or unreadable cache: the next open fetches a fresh forecast.
        }
    }

    function applyConfig(raw) {
        try {
            const services = JSON.parse(raw).services
            caelestiaServices = services && typeof services === "object" ? services : {}
        } catch (failure) {
            caelestiaServices = {}
        }
    }

    FileView {
        id: caelestiaConfig

        path: root.caelestiaConfigPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.applyConfig(text())
        onFileChanged: reload()
    }

    FileView {
        id: store

        path: ThemeService.stateDirectory + "/weather.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.restore(text())
    }

    Component.onCompleted: {
        applyConfig(caelestiaConfig.text())
        restore(store.text())
    }

    Process {
        id: locator

        property string mode: "ip"
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: code => {
            if (code !== 0) {
                root.describeFailure("Couldn't find your location. Check your connection.")
                return
            }
            try {
                root.useLocation(mode === "geocode" ? Data.parseGeocode(stdout.text) : Data.parseIpLocation(stdout.text))
            } catch (failure) {
                root.describeFailure(mode === "geocode"
                    ? "No place named “" + root.configuredLocation + "” was found."
                    : "Couldn't find your location. Set weatherLocation in Caelestia's config.")
            }
        }
    }

    Process {
        id: fetcher

        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: code => {
            if (code !== 0) {
                root.describeFailure("Couldn't load the forecast. Check your connection.")
                return
            }
            try {
                root.forecast = Data.parse(stdout.text)
                root.fetchedAt = Date.now()
                root.error = ""
                root.save()
            } catch (failure) {
                root.describeFailure("The weather service sent an unexpected reply.")
            }
        }
    }
}
