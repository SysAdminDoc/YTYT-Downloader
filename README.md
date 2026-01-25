# YTYT-Downloader

<img width="654" height="366" alt="ytytfull" src="https://github.com/user-attachments/assets/d5892a79-c6ff-47c6-ab63-cacfb8e78622" />



Send Youtube videos to **VLC** and download directly from YouTube's interface.

![Version](https://img.shields.io/badge/version-1.3.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 🚀 Quick Install (PowerShell One-Liner)

Paste this into an elevated PowerShell window:

<div class="position-relative">
  <pre><code>irm https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/src/Install-YTYT.ps1 | iex
</code></pre>
</div>

## Features

- **Stream to VLC** - One-click streaming of any YouTube video to VLC media player
- **Download with yt-dlp** - Instantly trigger yt-dlp downloads from the browser
- **Native Integration** - Buttons blend seamlessly into YouTube's action bar
- **Shorts Support** - Works on both regular videos and YouTube Shorts
- **SPA Compatible** - Handles YouTube's single-page navigation without page reloads

## Screenshot

The script adds two buttons to the right of YouTube's standard action buttons:

<img width="227" height="61" alt="dls" src="https://github.com/user-attachments/assets/efbaddc3-c8a8-4a09-91a3-8a7e18eb14c5" />


| Button | Color | Function |
|--------|-------|----------|
| **VLC** | Orange | Stream video in VLC Player |
| **DL** | Green | Download with yt-dlp |

## Requirements

### 1. Userscript Manager

Install one of the following browser extensions:

- [Tampermonkey](https://www.tampermonkey.net/) (Chrome, Firefox, Edge, Safari)
- [Violentmonkey](https://violentmonkey.github.io/) (Chrome, Firefox, Edge)
- [Greasemonkey](https://www.greasespot.net/) (Firefox)

### 2. Protocol Handlers

This script uses custom URL protocols to communicate with local applications. You'll need to register these handlers on your system.

#### Windows Setup

Create a `.reg` file with the following content and run it:

```reg
Windows Registry Editor Version 5.00

; VLC Protocol Handler
[HKEY_CLASSES_ROOT\ytvlc]
@="URL:YTVLC Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\ytvlc\shell]

[HKEY_CLASSES_ROOT\ytvlc\shell\open]

[HKEY_CLASSES_ROOT\ytvlc\shell\open\command]
@="\"C:\\Path\\To\\Your\\vlc-handler.bat\" \"%1\""

; yt-dlp Protocol Handler
[HKEY_CLASSES_ROOT\ytdl]
@="URL:YTDL Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\ytdl\shell]

[HKEY_CLASSES_ROOT\ytdl\shell\open\command]
@="\"C:\\Path\\To\\Your\\ytdl-handler.bat\" \"%1\""
```

#### Example Handler Scripts (Windows)

**vlc-handler.bat**
```batch
@echo off
setlocal EnableDelayedExpansion
set "url=%~1"
set "url=!url:ytvlc://=!"
set "url=!url:%%3A=:!"
set "url=!url:%%2F=/!"
set "url=!url:%%3F=?!"
set "url=!url:%%3D==!"
set "url=!url:%%26=&!"
"C:\Program Files\VideoLAN\VLC\vlc.exe" "!url!"
```

**ytdl-handler.bat**
```batch
@echo off
setlocal EnableDelayedExpansion
set "url=%~1"
set "url=!url:ytdl://=!"
set "url=!url:%%3A=:!"
set "url=!url:%%2F=/!"
set "url=!url:%%3F=?!"
set "url=!url:%%3D==!"
set "url=!url:%%26=&!"
cd /d "%USERPROFILE%\Downloads"
start cmd /k yt-dlp "!url!"
```

### 3. Required Software

- [VLC Media Player](https://www.videolan.org/vlc/) - For streaming functionality
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - For download functionality

## Installation

1. Install a userscript manager (see Requirements)
2. Click the link below or create a new script and paste the contents:

   **[Install YTYT-Downloader](https://github.com/SysAdminDoc/YTYT-Downloader/raw/refs/heads/main/src/YTYT_downloader.user.js)**

3. Set up the protocol handlers for your operating system
4. Navigate to any YouTube video and use the new buttons!


<img width="984" height="892" alt="2026-01-24 16_58_56-YTYT-Downloader Setup" src="https://github.com/user-attachments/assets/86cc4732-25ad-47de-9b0a-9b562b6b9b94" />
<img width="984" height="892" alt="2026-01-24 16_59_23-YTYT-Downloader Setup" src="https://github.com/user-attachments/assets/db2ce562-fa7a-44b5-ad57-a414cd01e5e9" />
<img width="984" height="892" alt="2026-01-24 16_59_48-YTYT-Downloader Setup" src="https://github.com/user-attachments/assets/6d2fefc3-5445-4390-adc0-e3e3c2d64e54" />



## How It Works

1. The script detects when you're on a YouTube video or Shorts page
2. It injects VLC and Download buttons into the action bar
3. Clicking a button triggers a custom protocol URL (`ytvlc://` or `ytdl://`)
4. Your OS routes the protocol to the registered handler script
5. The handler script launches VLC or yt-dlp with the video URL

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Buttons don't appear | Refresh the page or wait a few seconds for YouTube to fully load |
| "Protocol not recognized" | Ensure the registry entries are correctly installed |
| VLC doesn't open | Verify VLC path in your handler script |
| yt-dlp doesn't download | Make sure yt-dlp is installed and in your PATH |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - The powerful YouTube downloader
- [VLC](https://www.videolan.org/) - The versatile media player

---

**[Report Issues](https://github.com/SysAdminDoc/ytyt-downloader/issues)** | **[SysAdminDoc](https://github.com/SysAdminDoc)**
