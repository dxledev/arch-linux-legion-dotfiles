pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.utils
import qs.integration

QtObject {
    id: notif

    property bool popup
    property bool closed
    property bool timeoutPaused: false
    property var locks: new Set()

    property date time: new Date()
    property int ageMins: 0
    readonly property string timeStr: {
        if (ageMins < 1)
            return Tr.tr("now");

        const h = Math.floor(ageMins / 60);
        const d = Math.floor(h / 24);

        if (d > 0)
            return Tr.trCtx("%1d", "abbreviated notification age, days").arg(d);
        if (h > 0)
            return Tr.trCtx("%1h", "abbreviated notification age, hours").arg(h);
        return Tr.trCtx("%1m", "abbreviated notification age, minutes").arg(ageMins);
    }

    readonly property Timer timeStrTimer: Timer {
        running: !notif.closed
        repeat: true
        interval: 5000
        onTriggered: notif.updateTimeStr()
    }

    property Notification notification
    property string notificationId
    property string summary
    property string body
    readonly property var formattedSummary: NotificationFormat.format(summary)
    readonly property var formattedBody: NotificationFormat.format(body)
    property string appIcon
    property string appName
    property string image
    property bool artworkAvailable: false
    property bool artworkPending: false
    property int artworkRevision: 0
    property int cachedArtworkRevision: -1
    property string artworkSource
    property string artworkLoaderSource
    readonly property Timer artworkTimeout: Timer {
        interval: 15000
        repeat: false
        onTriggered: notif.failArtwork(notif.artworkSource, notif.artworkRevision)
    }
    property var hints // Hints are not persisted across restarts
    property real expireTimeout: GlobalConfig.notifs.defaultExpireTimeout
    property int urgency: NotificationUrgency.Normal
    property bool resident
    property bool hasActionIcons
    property list<var> actions

    function appIconFor(icon: var, name: string): string {
        const normalizedName = name.toLowerCase().replace(/[^a-z0-9]/g, "");
        if (normalizedName === "chromack")
            return "color-picker";
        if (normalizedName.includes("spotify"))
            return "spotify";

        if (icon && icon !== "null" && icon !== "undefined")
            return icon;

        return "";
    }

    function loadableImageSource(source: string): string {
        const iconPrefix = "image://icon/";
        if (source.startsWith(iconPrefix))
            return source;

        if (source.startsWith("/"))
            return `file://${encodeURI(source).replace(/#/g, "%23").replace(/\?/g, "%3F")}`;

        return source;
    }

    function isCachedArtwork(source: string): bool {
        if (!source.startsWith("file://") && !source.startsWith("/"))
            return false;

        const path = Paths.toLocalFile(source);
        return path === Paths.notifimagecache || path.startsWith(`${Paths.notifimagecache}/`);
    }

    function loadArtwork(source: string): void {
        const resolvedSource = loadableImageSource(source || "");
        const revision = ++artworkRevision;

        artworkTimeout.stop();
        dummyImageLoader.active = false;
        artworkSource = resolvedSource;
        artworkAvailable = false;
        artworkPending = false;
        cachedArtworkRevision = -1;
        artworkLoaderSource = "";

        if (!resolvedSource) {
            image = "";
            return;
        }

        if (resolvedSource.startsWith("image://icon/") || isCachedArtwork(resolvedSource)) {
            image = source;
            artworkAvailable = true;
            return;
        }

        image = "";
        artworkPending = true;
        artworkTimeout.restart();
        dummyImageLoader.active = true;
        Qt.callLater(() => {
            if (revision === artworkRevision && artworkPending)
                artworkLoaderSource = resolvedSource;
        });
    }

    function refreshArtwork(): void {
        if (notification)
            loadArtwork(notification.image);
    }

    function finishArtwork(cachePath: string, source: string, revision: int): void {
        if (!artworkPending || revision !== artworkRevision || source !== artworkSource)
            return;

        artworkTimeout.stop();
        image = cachePath;
        artworkAvailable = true;
        artworkPending = false;
        dummyImageLoader.active = false;
    }

    function failArtwork(source: string, revision: int): void {
        if (!artworkPending || revision !== artworkRevision || source !== artworkSource)
            return;

        artworkTimeout.stop();
        image = "";
        artworkAvailable = false;
        artworkPending = false;
        artworkSource = "";
        artworkLoaderSource = "";
        dummyImageLoader.active = false;
    }

    function invalidateArtwork(source: string): void {
        if (artworkPending || !image || loadableImageSource(image) !== loadableImageSource(source))
            return;

        image = "";
        artworkAvailable = false;
        artworkRevision++;
        artworkSource = "";
        artworkLoaderSource = "";
        dummyImageLoader.active = false;
    }

    onImageChanged: Notifs.persist()

    readonly property bool hasFullscreen: {
        const monitor = Hypr.focusedMonitor;
        const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
        if (specialName) {
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
    }

    readonly property Timer timer: Timer {
        running: true
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : notif.hasFullscreen ? GlobalConfig.notifs.fullscreenExpireTimeout : GlobalConfig.notifs.defaultExpireTimeout
        onTriggered: {
            // Always expire if the active workspace has a fullscreen window
            if (GlobalConfig.notifs.expire || notif.hasFullscreen)
                notif.popup = false;
        }
    }

    readonly property LazyLoader dummyImageLoader: LazyLoader {
        active: false

        // qmllint disable uncreatable-type
        PanelWindow {
            // qmllint enable uncreatable-type
            implicitWidth: TokenConfig.sizes.notifs.image
            implicitHeight: TokenConfig.sizes.notifs.image
            color: "transparent"
            mask: Region {}

            Image {
                function tryCache(): void {
                    if (!notif.artworkPending || status !== Image.Ready || width != TokenConfig.sizes.notifs.image || height != TokenConfig.sizes.notifs.image)
                        return;

                    const source = notif.artworkSource;
                    const revision = notif.artworkRevision;
                    if (!source || notif.artworkLoaderSource !== source)
                        return;

                    if (notif.isCachedArtwork(source)) {
                        notif.finishArtwork(source, source, revision);
                        return;
                    }

                    if (notif.cachedArtworkRevision === revision)
                        return;
                    notif.cachedArtworkRevision = revision;

                    const cacheKey = [notif.appName, notif.summary, notif.notificationId, source, notif.time.getTime(), revision].join("|");
                    let h1 = 0xdeadbeef, h2 = 0x41c6ce57, ch;
                    for (let i = 0; i < cacheKey.length; i++) {
                        ch = cacheKey.charCodeAt(i);
                        h1 = Math.imul(h1 ^ ch, 2654435761);
                        h2 = Math.imul(h2 ^ ch, 1597334677);
                    }
                    h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507);
                    h1 ^= Math.imul(h2 ^ (h2 >>> 13), 3266489909);
                    h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507);
                    h2 ^= Math.imul(h1 ^ (h1 >>> 13), 3266489909);
                    const hash = (h2 >>> 0).toString(16).padStart(8, 0) + (h1 >>> 0).toString(16).padStart(8, 0);

                    const cache = `${Paths.notifimagecache}/${hash}.png`;
                    CUtils.saveItem(this, Qt.resolvedUrl(cache), () => notif.finishArtwork(cache, source, revision), () => notif.failArtwork(source, revision));
                }

                anchors.fill: parent
                source: notif.artworkLoaderSource ? Qt.resolvedUrl(notif.artworkLoaderSource) : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                opacity: 0

                onWidthChanged: tryCache()
                onHeightChanged: tryCache()
                onStatusChanged: {
                    tryCache();
                    if (status === Image.Error && notif.artworkPending)
                        notif.failArtwork(notif.artworkSource, notif.artworkRevision);
                }
            }
        }
    }

    readonly property Connections conn: Connections {
        function onClosed(): void {
            notif.close();
        }

        function onSummaryChanged(): void {
            notif.summary = notif.notification.summary;
        }

        function onBodyChanged(): void {
            notif.body = notif.notification.body;
        }

        function onAppIconChanged(): void {
            notif.appIcon = notif.appIconFor(notif.notification.appIcon, notif.appName);
        }

        function onAppNameChanged(): void {
            notif.appName = notif.notification.appName;
            notif.appIcon = notif.appIconFor(notif.notification.appIcon, notif.appName);
        }

        function onImageChanged(): void {
            notif.loadArtwork(notif.notification.image);
        }

        function onExpireTimeoutChanged(): void {
            notif.expireTimeout = notif.notification.expireTimeout;
        }

        function onUrgencyChanged(): void {
            notif.urgency = notif.notification.urgency;
        }

        function onResidentChanged(): void {
            notif.resident = notif.notification.resident;
        }

        function onHasActionIconsChanged(): void {
            notif.hasActionIcons = notif.notification.hasActionIcons;
        }

        function onActionsChanged(): void {
            // qmllint disable unresolved-type
            notif.actions = notif.notification.actions.map(a => ({
                        // qmllint enable unresolved-type
                        identifier: a.identifier,
                        text: a.text,
                        invoke: () => a.invoke()
                    }));
        }

        function onHintsChanged(): void {
            notif.hints = notif.notification.hints;
        }

        target: notif.notification
    }

    function updateTimeStr(): void {
        const diff = Date.now() - time.getTime();
        const m = Math.floor(diff / 60000);
        ageMins = m;

        if (m < 1) {
            timeStrTimer.interval = 5000;
        } else {
            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);

            if (d > 0)
                timeStrTimer.interval = 3600000;
            else if (h > 0)
                timeStrTimer.interval = 300000;
            else
                timeStrTimer.interval = m < 10 ? 30000 : 60000;
        }
    }

    function lock(item: Item): void {
        locks.add(item);
    }

    function restartTimeout(): void {
        timer.stop();
        if (!timeoutPaused)
            timer.start();
    }

    function unlock(item: Item): void {
        locks.delete(item);
        if (closed)
            close();
    }

    function close(): void {
        closed = true;
        if (locks.size === 0 && Notifs.list.includes(this)) {
            Notifs.list = Notifs.list.filter(n => n !== this);
            notification?.dismiss();
            destroy();
        }
    }

    Component.onCompleted: {
        if (!notification) {
            appIcon = appIconFor(appIcon, appName);
            artworkSource = image;
            artworkAvailable = image.length > 0;
            return;
        }

        notificationId = notification.id;
        summary = notification.summary;
        body = notification.body;
        appName = notification.appName;
        appIcon = appIconFor(notification.appIcon, appName);
        loadArtwork(notification.image);
        expireTimeout = notification.expireTimeout;
        hints = notification.hints;
        urgency = notification.urgency;
        resident = notification.resident;
        hasActionIcons = notification.hasActionIcons;
        // qmllint disable unresolved-type
        actions = notification.actions.map(a => ({
                    // qmllint enable unresolved-type
                    identifier: a.identifier,
                    text: a.text,
                    invoke: () => a.invoke()
                }));
    }
}
