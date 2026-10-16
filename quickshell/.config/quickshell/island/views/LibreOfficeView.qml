import "../core"
import "../services"

LauncherView {
    title: "LibreOffice"
    placeholder: "LibreOffice…"
    sourceApps: LauncherService.libreOfficeApps
    function goBack() { IslandController.openLauncher(); }
}
