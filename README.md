# YTYT-Downloader

<img width="654" height="366" alt="ytytfull" src="https://github.com/user-attachments/assets/d5892a79-c6ff-47c6-ab63-cacfb8e78622" />

Download YouTube videos, extract MP3 audio, save transcripts, and stream to VLC - all from YouTube's interface.

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Quick Install (PowerShell One-Liner)

Paste this into an elevated PowerShell window:

```powershell
irm https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/src/Install-YTYT.ps1 | iex
```

The installer automatically downloads and configures everything: yt-dlp, ffmpeg, VLC detection, protocol handlers, and the userscript.

## Features

- **Download Video** - One-click MP4 downloads up to 1080p with progress UI
- **Download Audio** - Extract MP3 audio from any video
- **Download Transcript** - Save video captions/subtitles as timestamped text files
- **Stream to VLC** - Instantly stream any video to VLC media player
- **Progress Popup** - Real-time download progress with thumbnail, speed, and ETA
- **Auto-Retry** - Failed downloads automatically retry up to 3 times
- **Settings Panel** - Toggle which buttons to show/hide
- **Shorts Support** - Works on both regular videos and YouTube Shorts
- **SPA Compatible** - Handles YouTube's single-page navigation seamlessly

## Screenshot

The script adds download buttons to YouTube's action bar with a settings gear:

<img width="227" height="61" alt="dls" src="https://github.com/user-attachments/assets/efbaddc3-c8a8-4a09-91a3-8a7e18eb14c5" />

| Button | Color | Function | Default |
|--------|-------|----------|---------|
| **Video** | Green | Download video as MP4 | Shown |
| **MP3** | Purple | Download audio as MP3 | Shown |
| **TXT** | Blue | Download transcript | Shown |
| **VLC** | Orange | Stream in VLC Player | Hidden |
| **⚙️** | Gray | Settings panel | Always |

Click the gear icon to toggle button visibility. Settings persist across sessions.

## Requirements

### Automatic Installation (Recommended)

Run the PowerShell installer - it handles everything automatically:
- Downloads yt-dlp and ffmpeg
- Detects VLC installation
- Registers protocol handlers
- Creates the userscript

### Manual Requirements

If installing manually, you'll need:

1. **Userscript Manager** - Install one of:
   - [Tampermonkey](https://www.tampermonkey.net/) (Chrome, Firefox, Edge, Safari)
   - [Violentmonkey](https://violentmonkey.github.io/) (Chrome, Firefox, Edge)
   - [Greasemonkey](https://www.greasespot.net/) (Firefox)

2. **VLC Media Player** - [Download](https://www.videolan.org/vlc/)

3. **yt-dlp** - [Download](https://github.com/yt-dlp/yt-dlp)

4. **ffmpeg** - Required for MP3 extraction and video merging

## Installation

### Option 1: Automatic Installer (Windows)

1. Open PowerShell as Administrator
2. Run the one-liner:
   ```powershell
   irm https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/src/Install-YTYT.ps1 | iex
   ```
3. Follow the installer prompts
4. Install the userscript in your browser

### Option 2: Manual Installation

1. Install a userscript manager (see Requirements)
2. Install the userscript:

   **[Install YTYT-Downloader](https://github.com/SysAdminDoc/YTYT-Downloader/raw/refs/heads/main/src/YTYT_downloader.user.js)**

3. Set up protocol handlers manually (see Protocol Handlers section below)

## Installer Screenshots

<img width="984" height="892" alt="2026-01-24 16_58_56-YTYT-Downloader Setup" src="https://github.com/user-attachments/assets/86cc4732-25ad-47de-9b0a-9b562b6b9b94" />
<img width="984" height="892" alt="2026-01-24 16_59_23-YTYT-Downloader Setup" src="https://github.com/user-attachments/assets/db2ce562-fa7a-44b5-ad57-a414cd01e5e9" />
<img width="984" height="892" alt="2026-01-24 16_59_48-YTYT-Downloader Setup" src="https://github.com/user-attachments/assets/6d2fefc3-5445-4390-adc0-e3e3c2d64e54" />

## How It Works

1. The userscript detects YouTube video/Shorts pages
2. It injects download buttons into the action bar
3. Clicking a button triggers a custom protocol URL:
   - `ytdl://` - Download video/audio
   - `ytvlc://` - Stream to VLC
4. Windows protocol handlers launch PowerShell scripts
5. Download progress appears in a popup window with thumbnail

### Transcript Download

The transcript button extracts captions directly in the browser:
- Prefers English captions, falls back to first available language
- Includes timestamps in `[MM:SS]` format
- Downloads as a `.txt` file

## Protocol Handlers (Manual Setup)

If not using the automatic installer, create these registry entries:

```reg
Windows Registry Editor Version 5.00

; VLC Protocol Handler
[HKEY_CLASSES_ROOT\ytvlc]
@="URL:YTVLC Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\ytvlc\shell\open\command]
@="\"C:\\Path\\To\\ytvlc-handler.bat\" \"%1\""

; Download Protocol Handler
[HKEY_CLASSES_ROOT\ytdl]
@="URL:YTDL Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\ytdl\shell\open\command]
@="\"C:\\Path\\To\\ytdl-handler.bat\" \"%1\""
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Buttons don't appear | Refresh the page or wait for YouTube to fully load |
| "Protocol not recognized" | Re-run the installer or check registry entries |
| VLC doesn't open | Verify VLC is installed and path is correct |
| Download fails | Check that yt-dlp and ffmpeg are installed |
| Settings don't save | Ensure your userscript manager has storage permissions |
| No transcript available | Video doesn't have captions/subtitles |

## Uninstalling

Run the installer again - it automatically removes the previous installation before reinstalling. To fully uninstall:

1. Delete the installation folder (default: `%LOCALAPPDATA%\YTYT`)
2. Remove registry keys under `HKCU:\Software\Classes\` for: `ytvlc`, `ytvlcq`, `ytdl`, `ytmpv`, `ytdlplay`
3. Remove the userscript from your userscript manager
4. Delete desktop shortcut if created

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - The powerful YouTube downloader
- [VLC](https://www.videolan.org/) - The versatile media player
- [ffmpeg](https://ffmpeg.org/) - Audio/video processing

---

**[Report Issues](https://github.com/SysAdminDoc/YTYT-Downloader/issues)** | **[SysAdminDoc](https://github.com/SysAdminDoc)**
