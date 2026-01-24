// ==UserScript==
// @name         YTYT-Downloader
// @namespace    https://github.com/SysAdminDoc/ytyt-downloader
// @version      1.4.0
// @description  Stream YouTube to VLC or download with yt-dlp - buttons in action bar
// @author       SysAdminDoc
// @match        https://www.youtube.com/*
// @match        https://youtube.com/*
// @grant        GM_addStyle
// @run-at       document-start
// @homepageURL  https://github.com/SysAdminDoc/ytyt-downloader
// @supportURL   https://github.com/SysAdminDoc/ytyt-downloader/issues
// ==/UserScript==

(function() {
    'use strict';

    // Inject styles immediately
    const styleSheet = document.createElement('style');
    styleSheet.textContent = `
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
            flex-shrink: 0 !important;
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
            flex-shrink: 0 !important;
        }
        .ytyt-dl-btn:hover { background: #16a34a !important; }
        .ytyt-dl-btn svg { width: 20px !important; height: 20px !important; fill: white !important; }
    `;
    (document.head || document.documentElement).appendChild(styleSheet);

    // Debug logging (set to false for production)
    const DEBUG = false;
    function log(...args) {
        if (DEBUG) console.log('[YTYT]', ...args);
    }

    function createSvg(pathD) {
        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('viewBox', '0 0 24 24');
        svg.setAttribute('width', '20');
        svg.setAttribute('height', '20');
        const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        path.setAttribute('d', pathD);
        path.setAttribute('fill', 'white');
        svg.appendChild(path);
        return svg;
    }

    function getCurrentVideoId() {
        const urlParams = new URLSearchParams(window.location.search);
        const videoId = urlParams.get('v');
        if (videoId) return videoId;
        const shortsMatch = window.location.pathname.match(/\/shorts\/([a-zA-Z0-9_-]+)/);
        if (shortsMatch) return shortsMatch[1];
        return null;
    }

    function getCurrentVideoUrl() {
        const videoId = getCurrentVideoId();
        if (videoId) return 'https://www.youtube.com/watch?v=' + videoId;
        return null;
    }

    function openInVLC() {
        const url = getCurrentVideoUrl();
        if (url) {
            log('Opening in VLC:', url);
            window.location.href = 'ytvlc://' + encodeURIComponent(url);
        }
    }

    function downloadVideo() {
        const url = getCurrentVideoUrl();
        if (url) {
            log('Downloading:', url);
            window.location.href = 'ytdl://' + encodeURIComponent(url);
        }
    }

    function buttonsExist() {
        return document.querySelector('.ytyt-vlc-btn') !== null;
    }

    function removeButtons() {
        document.querySelectorAll('.ytyt-vlc-btn, .ytyt-dl-btn').forEach(el => el.remove());
    }

    function createButtons() {
        // Don't create if not on a video page
        if (!getCurrentVideoId()) {
            log('Not on video page, skipping');
            return false;
        }

        // Don't create duplicates
        if (buttonsExist()) {
            log('Buttons already exist');
            return true;
        }

        // Find the action bar - try multiple selectors for different YouTube layouts
        const selectors = [
            '#top-level-buttons-computed',
            'ytd-menu-renderer.ytd-watch-metadata #top-level-buttons-computed',
            '#actions ytd-menu-renderer #top-level-buttons-computed',
            'ytd-watch-metadata #actions-inner #menu #top-level-buttons-computed',
            '#owner ~ #actions #top-level-buttons-computed'
        ];

        let actionBar = null;
        for (const selector of selectors) {
            actionBar = document.querySelector(selector);
            if (actionBar && actionBar.offsetParent !== null) {
                log('Found action bar with selector:', selector);
                break;
            }
        }

        if (!actionBar) {
            log('Action bar not found');
            return false;
        }

        // Create VLC button
        const vlcBtn = document.createElement('button');
        vlcBtn.className = 'ytyt-vlc-btn';
        vlcBtn.title = 'Stream in VLC Player';
        vlcBtn.appendChild(createSvg('M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 14.5v-9l6 4.5-6 4.5z'));
        vlcBtn.appendChild(document.createTextNode(' VLC'));
        vlcBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            openInVLC();
        });

        // Create Download button
        const dlBtn = document.createElement('button');
        dlBtn.className = 'ytyt-dl-btn';
        dlBtn.title = 'Download with yt-dlp';
        dlBtn.appendChild(createSvg('M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z'));
        dlBtn.appendChild(document.createTextNode(' DL'));
        dlBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            downloadVideo();
        });

        actionBar.appendChild(vlcBtn);
        actionBar.appendChild(dlBtn);
        log('Buttons created successfully');
        return true;
    }

    // Retry mechanism with exponential backoff
    let retryCount = 0;
    const MAX_RETRIES = 15;
    const BASE_DELAY = 500;

    function tryCreateButtons() {
        if (createButtons()) {
            retryCount = 0;
            return;
        }

        if (retryCount < MAX_RETRIES) {
            retryCount++;
            const delay = Math.min(BASE_DELAY * Math.pow(1.5, retryCount - 1), 3000);
            log(`Retry ${retryCount}/${MAX_RETRIES} in ${delay}ms`);
            setTimeout(tryCreateButtons, delay);
        } else {
            log('Max retries reached');
            retryCount = 0;
        }
    }

    // Periodic check as fallback (every 2 seconds when on video page)
    let periodicInterval = null;

    function startPeriodicCheck() {
        if (periodicInterval) return;
        periodicInterval = setInterval(() => {
            if (getCurrentVideoId() && !buttonsExist()) {
                log('Periodic check: buttons missing, recreating');
                createButtons();
            }
        }, 2000);
    }

    function stopPeriodicCheck() {
        if (periodicInterval) {
            clearInterval(periodicInterval);
            periodicInterval = null;
        }
    }

    // Track current video to detect changes
    let currentVideoId = null;

    function handleNavigation() {
        const newVideoId = getCurrentVideoId();

        if (newVideoId !== currentVideoId) {
            log('Video changed:', currentVideoId, '->', newVideoId);
            currentVideoId = newVideoId;
            removeButtons();
            retryCount = 0;

            if (newVideoId) {
                startPeriodicCheck();
                // Give YouTube time to build the UI
                setTimeout(tryCreateButtons, 500);
            } else {
                stopPeriodicCheck();
            }
        } else if (newVideoId && !buttonsExist()) {
            // Same video but buttons disappeared (YouTube rebuilt DOM)
            log('Buttons disappeared, recreating');
            tryCreateButtons();
        }
    }

    // MutationObserver for DOM changes
    function setupObserver() {
        const observer = new MutationObserver((mutations) => {
            // Check if we're on a video page and buttons are missing
            if (getCurrentVideoId() && !buttonsExist()) {
                // Debounce - only trigger after mutations settle
                clearTimeout(window.ytytDebounce);
                window.ytytDebounce = setTimeout(() => {
                    log('DOM changed, checking buttons');
                    handleNavigation();
                }, 300);
            }
        });

        // Observe the main content area
        const target = document.querySelector('ytd-app') || document.body;
        observer.observe(target, {
            childList: true,
            subtree: true
        });
        log('Observer attached to:', target.tagName);
    }

    // Initialize when DOM is ready
    function init() {
        log('Initializing YTYT-Downloader v1.4.0');

        // Initial attempt
        handleNavigation();

        // Setup observer for SPA navigation
        setupObserver();

        // Listen for YouTube's navigation events
        window.addEventListener('yt-navigate-finish', () => {
            log('yt-navigate-finish event');
            setTimeout(handleNavigation, 500);
        });

        window.addEventListener('yt-navigate-start', () => {
            log('yt-navigate-start event');
            removeButtons();
        });

        // Fallback: popstate for browser back/forward
        window.addEventListener('popstate', () => {
            log('popstate event');
            setTimeout(handleNavigation, 500);
        });

        // Also check on page visibility change (tab switch)
        document.addEventListener('visibilitychange', () => {
            if (!document.hidden && getCurrentVideoId() && !buttonsExist()) {
                log('Tab visible, checking buttons');
                setTimeout(tryCreateButtons, 300);
            }
        });
    }

    // Start when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Also try after full load
    window.addEventListener('load', () => {
        log('Window load event');
        setTimeout(handleNavigation, 1000);
    });

})();
