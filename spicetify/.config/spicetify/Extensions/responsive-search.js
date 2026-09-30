(function installSearchLayoutStyle() {
    if (document.getElementById('responsive-search-style')) return;

    const style = document.createElement('style');
    style.id = 'responsive-search-style';
    style.textContent = '.Root__globalNav { contain: layout style; }';
    document.head.appendChild(style);
})();
