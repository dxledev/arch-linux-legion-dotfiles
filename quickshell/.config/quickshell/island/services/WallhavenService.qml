pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// State and helper calls behind Browse Wallpapers. The Python helper (integration/wallhaven) owns
// the wallhaven API client, API key, downloads and palette generation; this singleton only drives it.
Singleton {
    id: root

    readonly property string helper: Quickshell.env("ISLAND_WALLHAVEN_HELPER") || Quickshell.shellDir + "/integration/wallhaven"
    readonly property var materialVariants: [
        { id: "tonalspot", label: "Tonal Spot", description: "Island's default Material palette" },
        { id: "vibrant", label: "Vibrant", description: "More saturated Material colors" },
        { id: "expressive", label: "Expressive", description: "Shifted, playful hues" },
        { id: "fidelity", label: "Fidelity", description: "Stays close to the wallpaper" },
        { id: "fruitsalad", label: "Fruit Salad", description: "Bold contrasting hues" },
        { id: "monochrome", label: "Monochrome", description: "Greyscale Material" },
        { id: "neutral", label: "Neutral", description: "Barely-there tint" },
        { id: "rainbow", label: "Rainbow", description: "Wide hue spread" },
        { id: "content", label: "Content", description: "Material tuned to the image" }
    ]
    readonly property var groupOrder: ["style", "theory", "mood", "island", "material"]
    readonly property var groupTitles: ({
        style: "Styles", theory: "Color theory", mood: "Moods",
        island: "Island originals", material: "Island Material"
    })

    // ---- search filters ------------------------------------------------------------------------
    property var filters: defaultFilters()
    property var activeFilters: defaultFilters()
    property bool configReady: false
    property bool hasKey: false
    property string keyError: ""
    property string username: ""
    property var colorChoices: []
    property var schemes: []
    // "browse" searches wallhaven; "collections" lists a user's collections and browses one.
    property string view: "browse"
    property var collections: []
    property var activeCollection: null
    property string collectionsError: ""

    // ---- results ---------------------------------------------------------------------------------
    property ListModel results: ListModel {}
    // `meta` describes what the grid shows: wallhaven fixes its own page size (24, or 32/64 with some
    // accounts), so smaller pages are slices of the fetched page and `page`/`lastPage` count slices.
    property var meta: ({ page: 1, lastPage: 1, perPage: 24, total: 0, seed: "" })
    property var apiMeta: ({ page: 1, lastPage: 1, perPage: 24, total: 0, seed: "" })
    property var apiItems: []
    property int apiPage: 0
    property int pageSize: 0    // 0: the whole wallhaven page
    readonly property var pageSizeOptions: {
        const per = apiMeta.perPage > 0 ? apiMeta.perPage : 24;
        const sizes = [];
        for (const divisor of [1, 2, 3, 4, 6, 8]) {
            const size = per / divisor;
            if (Number.isInteger(size) && size >= 4) sizes.push(size);
        }
        return sizes;
    }
    // The chosen size when it divides the API page, otherwise the closest smaller one.
    readonly property int effectivePageSize: {
        const options = pageSizeOptions;
        if (pageSize <= 0) return options[0];
        for (const size of options) if (size <= pageSize) return size;
        return options[options.length - 1];
    }
    property bool searching: false
    property int requestedPage: 1
    property int fetchCount: 0
    property int cacheHits: 0
    property bool searched: false
    property string error: ""
    readonly property bool hasMore: meta.page < meta.lastPage
    readonly property bool busy: searching
    property bool opened: false
    signal pageLoaded()

    // ---- selected wallpaper ----------------------------------------------------------------------
    property string selectedId: ""
    property var selected: null
    property var detail: null
    property string preparedPath: ""
    property bool preparing: false
    property string prepareError: ""
    property string previewMode: ThemeService.state.mode === "light" ? "light" : "dark"
    property var previews: ({})
    property bool previewsRunning: false
    property string selectedKind: "aether"
    property string selectedScheme: "pastel"
    property bool working: false
    property bool awaitingTheme: false
    property string workStatus: ""
    property string workError: ""
    property string appliedId: ""

    readonly property var schemeGroups: {
        const groups = {};
        for (const scheme of schemes) (groups[scheme.group] = groups[scheme.group] || []).push(
            { id: scheme.id, label: scheme.label, description: scheme.description, kind: "aether" });
        groups.material = materialVariants.map(variant => ({ id: variant.id, label: variant.label, description: variant.description, kind: "material" }));
        return groupOrder.filter(key => groups[key] && groups[key].length > 0)
            .map(key => ({ key: key, title: groupTitles[key], schemes: groups[key] }));
    }
    readonly property var selectedPalette: previews[previewMode + ":" + selectedScheme] ?? null

    function defaultFilters() {
        return { q: "", categories: "111", purity: "100", sorting: "date_added", order: "desc", topRange: "1M",
                 atleast: "", resolutions: [], ratios: [], colors: "", seed: "" };
    }

    function schemeLabel(kind, id) {
        const pool = kind === "material" ? materialVariants : schemes;
        return pool.find(entry => entry.id === id)?.label ?? id;
    }

    function parse(text) {
        const lines = text.trim().split("\n");
        for (let i = lines.length - 1; i >= 0; i--) {
            try { return JSON.parse(lines[i]); } catch (err) {}
        }
        return null;
    }

    function failure(code, output, errors, fallback) {
        const data = parse(output);
        if (data && data.error) return data.error;
        if (code !== 0) return errors.trim().split("\n").pop() || fallback;
        return data ? "" : fallback;
    }

    // ---- lifecycle -------------------------------------------------------------------------------
    function open() {
        if (opened) return;
        opened = true;
        configJob.run([helper, "config"], "config");
        schemesJob.run([helper, "schemes"], "schemes");
    }

    // ---- filters ---------------------------------------------------------------------------------
    function setFilter(key, value) {
        const next = Object.assign({}, filters);
        next[key] = value;
        filters = next;
        if (key !== "q") { searchTimer.restart(); saveTimer.restart(); }
    }

    function setQuery(text) { setFilter("q", text); }

    function toggleBit(key, index) {
        if (key === "purity" && index === 2 && !hasKey) return;
        const chars = filters[key].split("");
        chars[index] = chars[index] === "1" ? "0" : "1";
        if (chars.every(c => c === "0")) return;
        setFilter(key, chars.join(""));
    }

    function toggleListItem(key, value) {
        const list = filters[key].slice();
        const at = list.indexOf(value);
        if (at >= 0) list.splice(at, 1); else list.push(value);
        setFilter(key, list);
    }

    function resetFilters() {
        const next = defaultFilters();
        next.q = filters.q;
        filters = next;
        saveTimer.restart();
        search();
    }

    function filterCount() {
        const f = filters;
        return (f.categories !== "111" ? 1 : 0) + (f.purity !== "100" ? 1 : 0) + (f.atleast ? 1 : 0)
            + (f.resolutions.length > 0 ? 1 : 0) + (f.ratios.length > 0 ? 1 : 0) + (f.colors ? 1 : 0)
            + (f.sorting === "toplist" && f.topRange !== "1M" ? 1 : 0);
    }

    function saveKey(key) {
        keyError = "";
        keyJob.run([helper, "set-key"], "key", { ISLAND_WALLHAVEN_NEW_KEY: key });
    }

    function setUsername(name) {
        username = name.trim();
        saveTimer.restart();
    }

    // ---- searching -------------------------------------------------------------------------------
    // Pages already fetched (and the next one, prefetched in the background) live in `pageCache`, keyed by
    // wallhaven page number; a new search clears it. Thumbnails are cached on disk by the helper.
    property var pageCache: ({})
    property var pageCacheOrder: []
    property var localThumbs: ({})
    property var installedIds: ({})
    property int token: 0
    property int generation: 0
    property var waiting: null
    property int prefetching: 0

    function search() {
        searchTimer.stop();
        activeFilters = Object.assign({}, filters);
        generation++;
        pageCache = ({});
        pageCacheOrder = [];
        apiItems = [];
        apiPage = 0;
        prefetching = 0;
        waiting = null;
        backgroundTimer.stop();
        prefetchJob.cancel();
        thumbsJob.cancel();
        request(1);
    }

    // Pagination: each page replaces the grid; the toolbar sorting and filters stay as searched.
    function goToPage(page) {
        if (busy || !searched || page < 1 || page > meta.lastPage || page === meta.page) return;
        request(page);
    }

    function retry() { request(requestedPage); }

    function setPageSize(size) {
        if (size === pageSize) return;
        const first = apiPage > 0 ? (meta.page - 1) * effectivePageSize : 0;
        pageSize = size;
        saveTimer.restart();
        if (apiPage > 0) request(Math.floor(first / effectivePageSize) + 1);
    }

    // First, last, the current page and its neighbours; 0 marks a gap.
    function pageWindow(current, last) {
        const wanted = new Set([1, last, current - 1, current, current + 1]);
        if (current <= 3) { wanted.add(2); wanted.add(3); wanted.add(4); }
        if (current >= last - 2) { wanted.add(last - 1); wanted.add(last - 2); wanted.add(last - 3); }
        const pages = [...wanted].filter(n => n >= 1 && n <= last).sort((a, b) => a - b);
        const out = [];
        for (const n of pages) {
            if (out.length > 0 && n - out[out.length - 1] === 2) out.push(n - 1);
            else if (out.length > 0 && n - out[out.length - 1] > 2) out.push(0);
            out.push(n);
        }
        return out;
    }

    function pageArgv(page, cache) {
        const collection = view === "collections" ? activeCollection : null;
        if (collection)
            return [helper, "collection", collection.user, String(collection.id), String(page)].concat(cache ? ["cache"] : []);
        return [helper, "search", JSON.stringify({ filters: Object.assign({}, activeFilters), page: page, cache: cache })];
    }

    // Shows page `page` of the grid: a slice of the loaded wallhaven page, a cached one, or a fetch.
    function request(page) {
        if (view === "collections" && !activeCollection) return;
        const size = effectivePageSize;
        const per = apiMeta.perPage > 0 ? apiMeta.perPage : 24;
        const wanted = Math.floor(((page - 1) * size) / per) + 1;
        searched = true;
        error = "";
        requestedPage = page;
        token++;
        waiting = null;
        if (wanted === apiPage) {
            searching = false;
            showSlice(page);
            return;
        }
        const cached = pageCache[wanted];
        if (cached) {
            cacheHits++;
            searching = false;
            applyApiPage(wanted, cached, page);
            return;
        }
        searching = true;
        if (prefetching === wanted) {
            waiting = { token: token, page: wanted, view: page };
            return;
        }
        fetchCount++;
        searchJob.run(pageArgv(wanted, false), { token: token, page: wanted, view: page, generation: generation });
    }

    function rememberPage(page, data) {
        const next = Object.assign({}, pageCache);
        next[page] = data;
        const order = pageCacheOrder.filter(entry => entry !== page);
        order.push(page);
        while (order.length > 8) delete next[order.shift()];
        pageCache = next;
        pageCacheOrder = order;
    }

    function applyApiPage(page, data, viewPage) {
        apiItems = data.data;
        apiPage = page;
        apiMeta = data.meta;
        hasKey = data.hasKey === true;
        if (activeFilters.sorting === "random" && data.meta.seed && !activeFilters.seed) {
            const next = Object.assign({}, activeFilters);
            next.seed = data.meta.seed;
            activeFilters = next;
        }
        showSlice(viewPage);
        backgroundTimer.restart();
    }

    function showSlice(page) {
        const size = effectivePageSize;
        const total = Math.min(apiMeta.total, apiMeta.lastPage * apiMeta.perPage);
        const last = Math.max(1, Math.ceil(total / size));
        const shown = Math.min(Math.max(1, page), last);
        const offset = ((shown - 1) * size) % apiMeta.perPage;
        meta = Object.assign({}, apiMeta, { page: shown, lastPage: last, perPage: size, total: apiMeta.total });
        requestedPage = shown;
        replaceResults(apiItems.slice(offset, offset + size));
        pageLoaded();
    }

    // The page after this one, fetched in the background so Next is instant.
    function prefetchNext() {
        const next = apiPage + 1;
        if (next > apiMeta.lastPage || pageCache[next] || prefetching === next) return;
        if (activeFilters.sorting === "random" && !activeFilters.seed) return;
        prefetching = next;
        fetchCount++;
        prefetchJob.run(pageArgv(next, true), { generation: generation, page: next });
    }

    // Saves the loaded page's thumbnails to disk, those not on screen first, so slicing through it is instant.
    function warmThumbs() {
        const size = effectivePageSize;
        const first = ((meta.page - 1) * size) % apiMeta.perPage;
        const wanted = [];
        apiItems.forEach((item, index) => {
            if (!/^https?:/.test(item.thumb) || localThumbs[item.id]) return;
            wanted.push({ id: item.id, url: item.thumb, shown: index >= first && index < first + size });
        });
        if (wanted.length === 0) return;
        wanted.sort((a, b) => a.shown - b.shown);
        thumbsJob.run([helper, "thumbs", JSON.stringify(wanted.map(entry => ({ id: entry.id, url: entry.url })))], { generation: generation });
    }

    function replaceResults(items) {
        results.clear();
        for (const item of items) {
            results.append({
                wid: item.id, url: item.url, path: item.path, thumb: localThumbs[item.id] || item.thumb, thumbSmall: item.thumbSmall,
                resolution: item.resolution, width: item.width, height: item.height, ratio: item.ratio,
                fileSize: item.fileSize, fileType: item.fileType, category: item.category, purity: item.purity,
                views: item.views, favorites: item.favorites, colorsCsv: item.colors.join(","),
                createdAt: item.createdAt, installed: item.installed === true || installedIds[item.id] === true
            });
        }
    }

    function markInstalled(id) {
        const ids = Object.assign({}, installedIds);
        ids[id] = true;
        installedIds = ids;
        for (let i = 0; i < results.count; i++)
            if (results.get(i).wid === id) results.setProperty(i, "installed", true);
        if (selected && selected.id === id) {
            const next = Object.assign({}, selected);
            next.installed = true;
            selected = next;
        }
    }

    // ---- collections -----------------------------------------------------------------------------
    function setView(name) {
        if (view === name) return;
        view = name;
        if (name === "collections") {
            if (collections.length === 0) loadCollections();
            if (activeCollection) search();
        } else search();
    }

    function loadCollections() {
        collectionsError = "";
        collectionsJob.run([helper, "collections", username], "collections");
        saveTimer.restart();
    }

    function openCollection(collection) {
        activeCollection = collection;
        search();
    }

    // ---- selection ---------------------------------------------------------------------------------
    function rowItem(index) {
        const row = results.get(index);
        return {
            id: row.wid, url: row.url, path: row.path, thumb: row.thumb, resolution: row.resolution,
            width: row.width, height: row.height, ratio: row.ratio, fileSize: row.fileSize, fileType: row.fileType,
            category: row.category, purity: row.purity, views: row.views, favorites: row.favorites,
            colors: row.colorsCsv ? row.colorsCsv.split(",") : [], createdAt: row.createdAt, installed: row.installed
        };
    }

    function select(item) {
        if (!item || selectedId === item.id) return;
        selectedId = item.id;
        selected = item;
        detail = null;
        preparedPath = "";
        prepareError = "";
        previews = ({});
        workStatus = "";
        workError = "";
        previewsRunning = false;
        previewJob.cancel();
        preparing = true;
        infoJob.run([helper, "info", item.id], { id: item.id });
        prepareJob.run([helper, "prepare", item.id, item.path], { id: item.id });
    }

    function closeDetail() {
        selectedId = "";
        selected = null;
        detail = null;
        preparedPath = "";
        previews = ({});
        previewsRunning = false;
        preparing = false;
        infoJob.cancel();
        prepareJob.cancel();
        previewJob.cancel();
    }

    function setPreviewMode(mode) {
        if (previewMode === mode) return;
        previewMode = mode;
        loadPreviews();
    }

    function loadPreviews() {
        if (!preparedPath || !selectedId) return;
        for (const key in previews) if (key.startsWith(previewMode + ":")) return;
        previewsRunning = true;
        previewJob.run([helper, "previews", preparedPath, previewMode], { id: selectedId, mode: previewMode });
    }

    function choose(kind, id) {
        selectedKind = kind;
        selectedScheme = id;
    }

    function searchFor(query) {
        view = "browse";
        const next = Object.assign({}, filters);
        next.q = query;
        filters = next;
        closeDetail();
        search();
    }

    function filterColor(hex) {
        const value = hex.replace("#", "").toLowerCase();
        if (colorChoices.indexOf(value) < 0) return;
        view = "browse";
        setFilter("colors", filters.colors === value ? "" : value);
    }

    function openPage() {
        if (selectedId && /^[A-Za-z0-9]+$/.test(selectedId))
            Quickshell.execDetached(["xdg-open", "https://wallhaven.cc/w/" + selectedId]);
    }

    // Saves the full image into the Dynamic library, then (optionally) applies it with the chosen palette.
    function install(applyPalette) {
        if (!selected || working) return;
        working = true;
        workError = "";
        workStatus = selected.installed ? "Preparing…" : "Downloading…";
        installJob.run([helper, "install", selected.id, selected.path], {
            id: selected.id, apply: applyPalette, kind: selectedKind, scheme: selectedScheme, mode: previewMode
        });
    }

    // Background downloads wait a moment so they never compete with the thumbnails being shown.
    Timer {
        id: backgroundTimer
        interval: 700
        onTriggered: { root.warmThumbs(); root.prefetchNext(); }
    }
    Timer { id: searchTimer; interval: 450; onTriggered: root.search() }
    Timer {
        id: saveTimer
        interval: 700
        onTriggered: {
            const saved = Object.assign({}, root.filters, { q: "", seed: "" });
            saveJob.run([root.helper, "save-config", JSON.stringify({ filters: saved, username: root.username, pageSize: root.pageSize })], "save");
        }
    }

    WallhavenJob {
        id: configJob
        onFinished: (tag, code, output, errors) => {
            const data = root.parse(output);
            if (data && data.filters) {
                root.filters = data.filters;
                root.activeFilters = Object.assign({}, data.filters);
                root.hasKey = data.hasKey === true;
                root.username = data.username || "";
                root.colorChoices = data.colors || [];
                root.pageSize = data.pageSize > 0 ? data.pageSize : 0;
            }
            root.configReady = true;
            if (!root.searched) root.search();
        }
    }
    WallhavenJob {
        id: schemesJob
        onFinished: (tag, code, output) => { const data = root.parse(output); if (Array.isArray(data)) root.schemes = data; }
    }
    WallhavenJob { id: saveJob }
    WallhavenJob {
        id: keyJob
        onFinished: (tag, code, output, errors) => {
            const message = root.failure(code, output, errors, "Could not save the API key.");
            root.keyError = message;
            if (message) return;
            root.hasKey = root.parse(output).hasKey === true;
            if (!root.hasKey && root.filters.purity[2] === "1")
                root.setFilter("purity", root.filters.purity.slice(0, 2) + "0");
            root.search();
        }
    }
    WallhavenJob {
        id: searchJob
        onFinished: (tag, code, output, errors) => {
            if (tag.token !== root.token || tag.generation !== root.generation) return;
            root.searching = false;
            const message = root.failure(code, output, errors, "Wallhaven returned no results.");
            if (message) {
                root.error = message;
                if (tag.view === 1) root.results.clear();
                return;
            }
            const data = root.parse(output);
            root.rememberPage(tag.page, data);
            root.applyApiPage(tag.page, data, tag.view);
        }
    }
    // Runs beside searchJob so a click never cancels the page being fetched ahead.
    WallhavenJob {
        id: prefetchJob
        onFinished: (tag, code, output, errors) => {
            if (tag.generation !== root.generation) return;
            if (root.prefetching === tag.page) root.prefetching = 0;
            const message = root.failure(code, output, errors, "");
            const data = message ? null : root.parse(output);
            const wait = root.waiting;
            if (data && data.data) root.rememberPage(tag.page, data);
            if (!wait || wait.page !== tag.page) return;
            root.waiting = null;
            if (data && data.data) {
                root.searching = false;
                root.applyApiPage(tag.page, data, wait.view);
            } else {
                // The background fetch failed; make the request the user is waiting for.
                root.fetchCount++;
                searchJob.run(root.pageArgv(tag.page, false), { token: wait.token, page: tag.page, view: wait.view, generation: root.generation });
            }
        }
    }
    WallhavenJob {
        id: thumbsJob
        onLine: (tag, text) => {
            if (tag.generation !== root.generation) return;
            try {
                const entry = JSON.parse(text);
                if (entry.id && entry.path) root.localThumbs[entry.id] = entry.path;
            } catch (err) {}
        }
    }
    WallhavenJob {
        id: collectionsJob
        onFinished: (tag, code, output, errors) => {
            const message = root.failure(code, output, errors, "Could not load collections.");
            root.collectionsError = message;
            if (message) { root.collections = []; return; }
            const data = root.parse(output);
            root.collections = data.data.map(entry => ({ id: entry.id, label: entry.label, count: entry.count, user: data.user }));
        }
    }
    WallhavenJob {
        id: infoJob
        onFinished: (tag, code, output) => {
            const data = root.parse(output);
            if (tag.id === root.selectedId && data && !data.error) root.detail = data;
        }
    }
    WallhavenJob {
        id: prepareJob
        onFinished: (tag, code, output, errors) => {
            if (tag.id !== root.selectedId) return;
            root.preparing = false;
            const message = root.failure(code, output, errors, "Could not download the full image.");
            if (message) { root.prepareError = message; return; }
            root.preparedPath = root.parse(output).path;
            root.loadPreviews();
        }
    }
    WallhavenJob {
        id: previewJob
        onLine: (tag, text) => {
            if (tag.id !== root.selectedId) return;
            let palette = null;
            try { palette = JSON.parse(text); } catch (err) { return; }
            if (!palette || palette.error || !palette.scheme) return;
            const next = Object.assign({}, root.previews);
            next[tag.mode + ":" + palette.scheme] = palette;
            root.previews = next;
        }
        onFinished: (tag) => { if (tag.id === root.selectedId) root.previewsRunning = false; }
    }
    WallhavenJob {
        id: installJob
        onFinished: (tag, code, output, errors) => {
            const message = root.failure(code, output, errors, "Could not save the wallpaper.");
            if (message) { root.working = false; root.workError = message; root.workStatus = ""; return; }
            const data = root.parse(output);
            root.markInstalled(tag.id);
            if (!tag.apply) {
                root.working = false;
                root.workStatus = "Saved to your Dynamic wallpapers";
                return;
            }
            root.workStatus = "Applying " + root.schemeLabel(tag.kind, tag.scheme) + " (" + tag.mode + ")…";
            root.awaitingTheme = true;
            root.appliedId = tag.id;
            ThemeService.execute(["wallpaper-palette", data.path, tag.kind, tag.scheme, tag.mode]);
        }
    }

    Connections {
        target: ThemeService
        function onBusyChanged() {
            if (!root.awaitingTheme || ThemeService.busy || ThemeService.pending.length > 0) return;
            root.awaitingTheme = false;
            root.working = false;
            root.workError = ThemeService.error;
            root.workStatus = ThemeService.error ? "" : "Applied wallpaper and palette";
            if (ThemeService.error) root.appliedId = "";
        }
    }
}
