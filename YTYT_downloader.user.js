// ==UserScript==
// @name         YTYT-Downloader
// @namespace    https://github.com/SysAdminDoc/ytyt-downloader
// @version      1.3.0
// @description  Stream YouTube to VLC or download with yt-dlp - buttons in action bar
// @author       SysAdminDoc
// @match        https://www.youtube.com/*
// @match        https://youtube.com/*
// @grant        GM_addStyle
// @run-at       document-idle
// @homepageURL  https://github.com/SysAdminDoc/ytyt-downloader
// @supportURL   https://github.com/SysAdminDoc/ytyt-downloader/issues
// ==/UserScript==

(function() {
    'use strict';

    GM_addStyle(`
        .ytyt-vlc-btn {
            display: inline-flex !important;
            align-items: center !important;
            gap: 6px !important;
            padding: 0 16px !important;
            height: 36px !important;
            margin-left: 8px !important;
            border-radius: 18px !important;
            border: none !important;
            background: #f97316 !important;
            color: white !important;
            font-family: "Roboto", "Arial", sans-serif !important;
            font-size: 14px !important;
            font-weight: 500 !important;
            cursor: pointer !important;
        }
        .ytyt-vlc-btn:hover { background: #ea580c !important; }
        .ytyt-vlc-btn svg { width: 20px !important; height: 20px !important; fill: white !important; }
        .ytyt-dl-btn {
            display: inline-flex !important;
            align-items: center !important;
            gap: 6px !important;
            padding: 0 16px !important;
            height: 36px !important;
            margin-left: 8px !important;
            border-radius: 18px !important;
            border: none !important;
            background: #22c55e !important;
            color: white !important;
            font-family: "Roboto", "Arial", sans-serif !important;
            font-size: 14px !important;
            font-weight: 500 !important;
            cursor: pointer !important;
        }
        .ytyt-dl-btn:hover { background: #16a34a !important; }
        .ytyt-dl-btn svg { width: 20px !important; height: 20px !important; fill: white !important; }
    `);

    function createSvg(pathD) {
        var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('viewBox', '0 0 24 24');
        svg.setAttribute('width', '20');
        svg.setAttribute('height', '20');
        var path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        path.setAttribute('d', pathD);
        path.setAttribute('fill', 'white');
        svg.appendChild(path);
        return svg;
    }

    function getCurrentVideoUrl() {
        var urlParams = new URLSearchParams(window.location.search);
        var videoId = urlParams.get('v');
        if (videoId) return 'https://www.youtube.com/watch?v=' + videoId;
        var shortsMatch = window.location.pathname.match(/\/shorts\/([a-zA-Z0-9_-]+)/);
        if (shortsMatch) return 'https://www.youtube.com/watch?v=' + shortsMatch[1];
        return null;
    }

    function openInVLC() {
        var url = getCurrentVideoUrl();
        if (url) window.location.href = 'ytvlc://' + encodeURIComponent(url);
    }

    function downloadVideo() {
        var url = getCurrentVideoUrl();
        if (url) window.location.href = 'ytdl://' + encodeURIComponent(url);
    }

    function createButtons() {
        document.querySelectorAll('.ytyt-vlc-btn, .ytyt-dl-btn').forEach(function(el) { el.remove(); });
        if (!getCurrentVideoUrl()) return;

        var actionBar = document.querySelector('#top-level-buttons-computed');
        if (!actionBar) return;

        var vlcBtn = document.createElement('button');
        vlcBtn.className = 'ytyt-vlc-btn';
        vlcBtn.title = 'Stream in VLC Player';
        vlcBtn.appendChild(createSvg('M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 14.5v-9l6 4.5-6 4.5z'));
        vlcBtn.appendChild(document.createTextNode(' VLC'));
        vlcBtn.addEventListener('click', function(e) { e.preventDefault(); e.stopPropagation(); openInVLC(); });

        var dlBtn = document.createElement('button');
        dlBtn.className = 'ytyt-dl-btn';
        dlBtn.title = 'Download with yt-dlp';
        dlBtn.appendChild(createSvg('M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z'));
        dlBtn.appendChild(document.createTextNode(' DL'));
        dlBtn.addEventListener('click', function(e) { e.preventDefault(); e.stopPropagation(); downloadVideo(); });

        actionBar.appendChild(vlcBtn);
        actionBar.appendChild(dlBtn);
    }

    function tryCreate(n) {
        if (n <= 0) return;
        createButtons();
        if (!document.querySelector('.ytyt-vlc-btn') && getCurrentVideoUrl()) {
            setTimeout(function() { tryCreate(n - 1); }, 1000);
        }
    }

    setTimeout(function() { tryCreate(5); }, 2000);

    var lastUrl = location.href;
    new MutationObserver(function() {
        if (location.href !== lastUrl) {
            lastUrl = location.href;
            setTimeout(function() { tryCreate(5); }, 1500);
        }
    }).observe(document.body, { subtree: true, childList: true });

    window.addEventListener('yt-navigate-finish', function() { setTimeout(function() { tryCreate(5); }, 1000); });
})();
