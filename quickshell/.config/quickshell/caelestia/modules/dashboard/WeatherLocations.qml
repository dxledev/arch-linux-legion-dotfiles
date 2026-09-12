import QtQuick
import Quickshell.Io
import qs.services
import qs.utils

Item {
    id: root

    property string configPath: `${Paths.home}/.config/dashboard/weather.json`
    property var locations: []
    property int selectedIndex: -1
    readonly property string displayName: locations[selectedIndex]?.displayName ?? Weather.city

    function select(index: int): void {
        if (index < 0 || index >= locations.length)
            return;
        selectedIndex = index;
        const location = locations[index];
        const coords = `${location.latitude},${location.longitude}`;
        Weather.selectedLocation = coords;
        Weather.cacheCity(coords, location.displayName);
        Weather.reload();
        selection.setText(coords);
    }

    FileView {
        id: selection
        path: `${Paths.state}/dashboard-weather-location`
        blockLoading: true
        printErrors: false
    }

    FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const config = JSON.parse(text());
                const entries = Array.isArray(config) ? config : config.locations;
                root.locations = (entries ?? []).filter(entry => entry.displayName
                    && Number.isFinite(entry.latitude) && Number.isFinite(entry.longitude));
                const saved = Weather.selectedLocation || selection.text().trim();
                const savedIndex = root.locations.findIndex(entry => `${entry.latitude},${entry.longitude}` === saved);
                root.select(savedIndex >= 0 ? savedIndex : Math.max(0, Math.min(config.selectedIndex ?? 0, root.locations.length - 1)));
            } catch (error) {
                console.warn("Unable to load dashboard weather locations:", error);
            }
        }
    }
}
