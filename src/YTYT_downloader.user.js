// ==UserScript==
// @name         YTYT-Downloader
// @namespace    https://github.com/SysAdminDoc/ytyt-downloader
// @version      2.0.0
// @description  Stream YouTube to VLC or download video/audio/transcript with yt-dlp
// @author       SysAdminDoc
// @match        https://www.youtube.com/*
// @match        https://youtube.com/*
// @grant        GM_getValue
// @grant        GM_setValue
// @run-at       document-start
// @homepageURL  https://github.com/SysAdminDoc/ytyt-downloader
// @supportURL   https://github.com/SysAdminDoc/ytyt-downloader/issues
// ==/UserScript==

(function() {
    'use strict';

    // Default settings - VLC hidden by default
    const DEFAULT_SETTINGS = {
        showVLC: false,
        showVideo: true,
        showAudio: true,
        showTranscript: true
    };

    function getSettings() {
        try {
            const saved = GM_getValue('ytyt_settings', null);
            if (saved) return { ...DEFAULT_SETTINGS, ...JSON.parse(saved) };
        } catch (e) {}
        return { ...DEFAULT_SETTINGS };
    }

    function saveSettings(settings) {
        try {
            GM_setValue('ytyt_settings', JSON.stringify(settings));
        } catch (e) {}
    }

    let settings = getSettings();

    // Inject styles immediately
    const styleSheet = document.createElement('style');
    styleSheet.textContent = `
        .ytyt-container {
            position: relative !important;
            display: inline-flex !important;
            align-items: center !important;
        }
        .ytyt-settings-panel {
            position: absolute !important;
            top: 100% !important;
            right: 0 !important;
            margin-top: 8px !important;
            background: #1f2937 !important;
            border: 1px solid #374151 !important;
            border-radius: 12px !important;
            padding: 16px !important;
            min-width: 200px !important;
            z-index: 9999 !important;
            box-shadow: 0 10px 25px rgba(0,0,0,0.5) !important;
        }
        .ytyt-settings-title {
            margin: 0 0 12px 0 !important;
            color: #f3f4f6 !important;
            font-size: 14px !important;
            font-weight: 600 !important;
        }
        .ytyt-settings-item {
            display: flex !important;
            align-items: center !important;
            justify-content: space-between !important;
            padding: 8px 0 !important;
            color: #d1d5db !important;
            font-size: 13px !important;
        }
        .ytyt-toggle {
            position: relative !important;
            width: 40px !important;
            height: 22px !important;
            background: #374151 !important;
            border-radius: 11px !important;
            cursor: pointer !important;
            transition: background 0.2s !important;
        }
        .ytyt-toggle.active {
            background: #22c55e !important;
        }
        .ytyt-toggle::after {
            content: '' !important;
            position: absolute !important;
            top: 2px !important;
            left: 2px !important;
            width: 18px !important;
            height: 18px !important;
            background: white !important;
            border-radius: 50% !important;
            transition: left 0.2s !important;
        }
        .ytyt-toggle.active::after {
            left: 20px !important;
        }
    `;
    (document.head || document.documentElement).appendChild(styleSheet);

    function createSvg(pathD, fill = 'white') {
        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('viewBox', '0 0 24 24');
        svg.setAttribute('width', '20');
        svg.setAttribute('height', '20');
        const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        path.setAttribute('d', pathD);
        path.setAttribute('fill', fill);
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
        if (url) window.location.href = 'ytvlc://' + encodeURIComponent(url);
    }

    function downloadVideo() {
        const url = getCurrentVideoUrl();
        if (url) window.location.href = 'ytdl://' + encodeURIComponent(url);
    }

    function downloadAudio() {
        const url = getCurrentVideoUrl();
        if (url) window.location.href = 'ytdl://' + encodeURIComponent(url) + '?ytyt_audio_only=1';
    }

    async function downloadTranscript() {
        const videoId = getCurrentVideoId();
        if (!videoId) return;
        try {
            const response = await fetch(window.location.href);
            const html = await response.text();
            const tracksMatch = html.match(/"captionTracks":\s*(\[.*?\])/s);
            let captionTracks = [];
            if (tracksMatch) {
                try {
                    let jsonStr = tracksMatch[1];
                    let depth = 0, endIdx = 0;
                    for (let i = 0; i < jsonStr.length; i++) {
                        if (jsonStr[i] === '[') depth++;
                        if (jsonStr[i] === ']') depth--;
                        if (depth === 0) { endIdx = i + 1; break; }
                    }
                    captionTracks = JSON.parse(jsonStr.substring(0, endIdx));
                } catch (e) {}
            }
            if (captionTracks.length === 0) { alert('No transcript available for this video.'); return; }
            let selectedTrack = captionTracks.find(t => t.languageCode === 'en' || t.languageCode?.startsWith('en')) || captionTracks[0];
            if (!selectedTrack?.baseUrl) { alert('Could not find transcript URL.'); return; }
            const transcriptResponse = await fetch(selectedTrack.baseUrl);
            const transcriptXml = await transcriptResponse.text();
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(transcriptXml, 'text/xml');
            const textElements = xmlDoc.querySelectorAll('text');
            if (textElements.length === 0) { alert('Transcript is empty.'); return; }
            let videoTitle = document.querySelector('h1.ytd-watch-metadata yt-formatted-string')?.textContent || document.title.replace(' - YouTube', '') || 'transcript';
            videoTitle = videoTitle.replace(/[<>:"/\\|?*]/g, '').trim();
            let transcriptText = 'Transcript: ' + videoTitle + '\nVideo: ' + getCurrentVideoUrl() + '\n' + '='.repeat(50) + '\n\n';
            textElements.forEach(el => {
                const start = parseFloat(el.getAttribute('start') || 0);
                const text = el.textContent.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&#39;/g, "'").replace(/\n/g, ' ').trim();
                if (text) {
                    const mins = Math.floor(start / 60), secs = Math.floor(start % 60);
                    transcriptText += '[' + mins.toString().padStart(2, '0') + ':' + secs.toString().padStart(2, '0') + '] ' + text + '\n';
                }
            });
            const blob = new Blob([transcriptText], { type: 'text/plain;charset=utf-8' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a'); a.href = url; a.download = videoTitle + '_transcript.txt';
            document.body.appendChild(a); a.click(); document.body.removeChild(a); URL.revokeObjectURL(url);
        } catch (error) { alert('Failed to download transcript. This video may not have captions available.'); }
    }

    function buttonsExist() { return document.querySelector('.ytyt-container') !== null; }
    function removeButtons() { document.querySelectorAll('.ytyt-container').forEach(el => el.remove()); }

    // Create settings panel using DOM methods (no innerHTML to comply with TrustedHTML)
    function createSettingsPanel() {
        const panel = document.createElement('div');
        panel.className = 'ytyt-settings-panel';

        const title = document.createElement('div');
        title.className = 'ytyt-settings-title';
        title.textContent = 'YTYT Settings';
        panel.appendChild(title);

        const settingsConfig = [
            { key: 'showVLC', label: 'VLC Button' },
            { key: 'showVideo', label: 'Video Download' },
            { key: 'showAudio', label: 'Audio Download' },
            { key: 'showTranscript', label: 'Transcript' }
        ];

        settingsConfig.forEach(({ key, label }) => {
            const item = document.createElement('div');
            item.className = 'ytyt-settings-item';

            const labelSpan = document.createElement('span');
            labelSpan.textContent = label;
            item.appendChild(labelSpan);

            const toggle = document.createElement('div');
            toggle.className = 'ytyt-toggle' + (settings[key] ? ' active' : '');
            toggle.dataset.setting = key;
            toggle.addEventListener('click', (e) => {
                e.stopPropagation();
                settings[key] = !settings[key];
                toggle.classList.toggle('active');
                saveSettings(settings);
                removeButtons();
                setTimeout(createButtons, 100);
            });
            item.appendChild(toggle);

            panel.appendChild(item);
        });

        return panel;
    }

    function createButton(className, title, bgColor, hoverColor, iconPath, labelText, onClick) {
        const btn = document.createElement('button');
        btn.className = className;
        btn.title = title;
        btn.style.cssText = `display:inline-flex;align-items:center;gap:6px;padding:0 16px;height:36px;margin-left:8px;border-radius:18px;border:none;background:${bgColor};color:white;font-family:"Roboto","Arial",sans-serif;font-size:14px;font-weight:500;cursor:pointer;transition:background 0.2s;`;
        btn.onmouseenter = () => { btn.style.background = hoverColor; };
        btn.onmouseleave = () => { btn.style.background = bgColor; };
        btn.appendChild(createSvg(iconPath));
        btn.appendChild(document.createTextNode(' ' + labelText));
        btn.addEventListener('click', (e) => { e.preventDefault(); e.stopPropagation(); onClick(); });
        return btn;
    }

    function createButtons() {
        if (!getCurrentVideoId() || buttonsExist()) return buttonsExist();

        const selectors = [
            '#top-level-buttons-computed',
            'ytd-menu-renderer.ytd-watch-metadata #top-level-buttons-computed',
            '#actions ytd-menu-renderer #top-level-buttons-computed'
        ];

        let actionBar = null;
        for (const selector of selectors) {
            actionBar = document.querySelector(selector);
            if (actionBar && actionBar.offsetParent !== null) break;
        }
        if (!actionBar) return false;

        const container = document.createElement('div');
        container.className = 'ytyt-container';

        // VLC button (orange)
        if (settings.showVLC) {
            container.appendChild(createButton(
                'ytyt-vlc-btn',
                'Stream in VLC Player',
                '#f97316', '#ea580c',
                'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 14.5v-9l6 4.5-6 4.5z',
                'VLC',
                openInVLC
            ));
        }

        // Video download button (green)
        if (settings.showVideo) {
            container.appendChild(createButton(
                'ytyt-video-btn',
                'Download Video (MP4)',
                '#22c55e', '#16a34a',
                'M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z',
                'Video',
                downloadVideo
            ));
        }

        // Audio download button (purple)
        if (settings.showAudio) {
            container.appendChild(createButton(
                'ytyt-audio-btn',
                'Download Audio (MP3)',
                '#8b5cf6', '#7c3aed',
                'M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z',
                'MP3',
                downloadAudio
            ));
        }

        // Transcript button (blue)
        if (settings.showTranscript) {
            container.appendChild(createButton(
                'ytyt-transcript-btn',
                'Download Transcript',
                '#3b82f6', '#2563eb',
                'M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z',
                'TXT',
                downloadTranscript
            ));
        }

        // Settings button (gear)
        const settingsBtn = document.createElement('button');
        settingsBtn.className = 'ytyt-settings-btn';
        settingsBtn.title = 'YTYT Settings';
        settingsBtn.style.cssText = 'display:inline-flex;align-items:center;justify-content:center;width:36px;height:36px;margin-left:8px;border-radius:50%;border:none;background:#374151;cursor:pointer;transition:background 0.2s;';
        settingsBtn.onmouseenter = () => { settingsBtn.style.background = '#4b5563'; };
        settingsBtn.onmouseleave = () => { settingsBtn.style.background = '#374151'; };
        const gearSvg = createSvg('M19.14 12.94c.04-.31.06-.63.06-.94 0-.31-.02-.63-.06-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.04.31-.06.63-.06.94s.02.63.06.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z', '#9ca3af');
        settingsBtn.appendChild(gearSvg);

        let panelVisible = false;
        let settingsPanel = null;

        settingsBtn.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            if (panelVisible && settingsPanel) {
                settingsPanel.remove();
                settingsPanel = null;
                panelVisible = false;
            } else {
                settingsPanel = createSettingsPanel();
                container.appendChild(settingsPanel);
                panelVisible = true;
                const closePanel = (evt) => {
                    if (settingsPanel && !settingsPanel.contains(evt.target) && evt.target !== settingsBtn) {
                        settingsPanel.remove();
                        settingsPanel = null;
                        panelVisible = false;
                        document.removeEventListener('click', closePanel);
                    }
                };
                setTimeout(() => document.addEventListener('click', closePanel), 10);
            }
        });
        container.appendChild(settingsBtn);

        actionBar.appendChild(container);
        return true;
    }

    let retryCount = 0;
    function tryCreateButtons() {
        if (createButtons()) { retryCount = 0; return; }
        if (retryCount < 15) { retryCount++; setTimeout(tryCreateButtons, Math.min(500 * Math.pow(1.5, retryCount - 1), 3000)); }
        else retryCount = 0;
    }

    let currentVideoId = null;
    function handleNavigation() {
        const newVideoId = getCurrentVideoId();
        if (newVideoId !== currentVideoId) {
            currentVideoId = newVideoId;
            removeButtons();
            retryCount = 0;
            if (newVideoId) setTimeout(tryCreateButtons, 500);
        } else if (newVideoId && !buttonsExist()) tryCreateButtons();
    }

    function init() {
        handleNavigation();
        new MutationObserver(() => {
            if (getCurrentVideoId() && !buttonsExist()) {
                clearTimeout(window.ytytDebounce);
                window.ytytDebounce = setTimeout(handleNavigation, 300);
            }
        }).observe(document.body || document.documentElement, { childList: true, subtree: true });
        window.addEventListener('yt-navigate-finish', () => setTimeout(handleNavigation, 500));
        window.addEventListener('yt-navigate-start', removeButtons);
        window.addEventListener('popstate', () => setTimeout(handleNavigation, 500));
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
    else init();
    window.addEventListener('load', () => setTimeout(handleNavigation, 1000));
})();
