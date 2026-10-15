import QtQuick
import "../components"
import "../services"

SettingsPanel {
    title: "Wallpaper"
    SettingSection {
        title: "Gallery layout"
        iconSource: "../assets/icons/grid.svg"
        SettingSlider { label: "Rows"; setting: "wallpaperRows"; minimum: 1; maximum: 5; suffix: "" }
        SettingSlider { label: "Columns"; setting: "wallpaperColumns"; minimum: 2; maximum: 5; suffix: "" }
        SettingChoice {
            label: "Scroll"; choices: ["vertical", "horizontal"]
            selected: ThemeService.settings.wallpaperScrollDirection || "vertical"
            onChosen: value => ThemeService.setSetting("wallpaperScrollDirection", value)
        }
        // Wrapping only makes sense for a single-row carousel.
        SettingToggle {
            text: "Infinite scroll"; setting: "wallpaperInfiniteScroll"
            enabled: !ThemeService.busy && (ThemeService.settings.wallpaperRows ?? 3) === 1
            opacity: enabled ? 1 : 0.45
        }
    }
    SettingSection {
        title: "Favorites"
        iconSource: "../assets/icons/star.svg"
        // Lowering the limit under the current favorites would orphan some; ask the user to unstar first.
        SettingSlider {
            label: "Favorite limit"; setting: "wallpaperFavoritesLimit"; minimum: 5; maximum: 20; suffix: ""
            guard: value => {
                const extra = WallpaperService.favorites.length - Math.round(value);
                return extra > 0 ? "Remove " + extra + (extra === 1 ? " favorite" : " favorites") + " to lower the limit to " + Math.round(value) : "";
            }
        }
    }
    SettingSection {
        title: "Active wallpaper"
        iconSource: "../assets/icons/image.svg"
        SettingToggle { id: blurToggle; text: "Blur active wallpaper"; setting: "wallpaperActiveBlur" }
        // The ranges are capped so the blur stays cheap: each pass re-renders the card.
        SettingSlider { visible: blurToggle.checked; label: "Blur strength"; setting: "wallpaperBlurStrength"; minimum: 20; maximum: 100; step: 5; suffix: "%" }
        SettingSlider { visible: blurToggle.checked; label: "Blur radius"; setting: "wallpaperBlurRadius"; minimum: 8; maximum: 48; step: 4 }
        SettingSlider { visible: blurToggle.checked; label: "Blur passes"; setting: "wallpaperBlurPasses"; minimum: 1; maximum: 3; suffix: "" }
    }
    SettingSection {
        title: "Animation"
        iconSource: "../assets/icons/sparkles.svg"
        SettingChoice {
            label: "Transition"; choices: ["none", "simple", "fade", "wipe", "wave", "grow", "center", "outer", "random"]
            selected: ThemeService.settings.transition || "grow"
            onChosen: value => ThemeService.setSetting("transition", value)
        }
        SettingSlider { label: "Duration"; setting: "transitionDuration"; maximum: 10; step: 0.1; suffix: " s" }
        SettingSlider { label: "Frame rate"; setting: "transitionFps"; minimum: 30; maximum: 240; step: 30; suffix: " fps" }
    }
}
