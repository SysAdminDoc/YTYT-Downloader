<#
.SYNOPSIS
    YTYT-Downloader Installer - Professional setup wizard for VLC streaming and video downloading
.DESCRIPTION
    Installs and configures:
    - yt-dlp (auto-download)
    - ffmpeg (auto-download)
    - VLC protocol handler (ytvlc://)
    - Download protocol handler (ytdl://)
    - Userscript for YouTube integration
.NOTES
    Author: SysAdminDoc
    Version: 2.0.0
    Repository: https://github.com/SysAdminDoc/YTYT-Downloader
#>

#Requires -Version 5.1

# ============================================
# CONFIGURATION
# ============================================
$script:AppName = "YTYT-Downloader"
$script:AppVersion = "2.0.0"
$script:InstallPath = "$env:LOCALAPPDATA\YTYT-Downloader"
$script:YtDlpUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
$script:DefaultDownloadPath = "$env:USERPROFILE\Videos\YouTube"
$script:GitHubRepo = "https://github.com/SysAdminDoc/YTYT-Downloader"
$script:UserscriptUrl = "https://github.com/SysAdminDoc/YTYT-Downloader/raw/refs/heads/main/src/YTYT_downloader.user.js"

# Image URLs
$script:IconUrl = "https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/images/icons/ytyticn.ico"
$script:LogoUrl = "https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/images/ytytfull.png"
$script:IconPngUrl = "https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/images/icons/ytyticn-128x128.png"

# Browser icon URLs
$script:BrowserIcons = @{
    Chrome  = "https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/images/browsers/chrome.png"
    Firefox = "https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/images/browsers/firefox.png"
    Edge    = "https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/images/browsers/edge.png"
    Safari  = "https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/images/browsers/safari.png"
    Opera   = "https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/images/browsers/opera.png"
}

# Userscript manager links by browser
$script:UserscriptManagers = @{
    Chrome = @{
        Tampermonkey = "https://chromewebstore.google.com/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo"
        Violentmonkey = "https://chrome.google.com/webstore/detail/violent-monkey/jinjaccalgkegednnccohejagnlnfdag"
    }
    Firefox = @{
        Tampermonkey = "https://addons.mozilla.org/en-US/firefox/addon/tampermonkey/"
        Greasemonkey = "https://addons.mozilla.org/en-US/firefox/addon/greasemonkey/"
        Violentmonkey = "https://addons.mozilla.org/firefox/addon/violentmonkey/"
    }
    Edge = @{
        Tampermonkey = "https://microsoftedge.microsoft.com/addons/detail/tampermonkey/iikmkjmpaadaobahmlepeloendndfphd"
        Violentmonkey = "https://microsoftedge.microsoft.com/addons/detail/eeagobfjdenkkddmbclomhiblgggliao"
    }
    Safari = @{
        Tampermonkey = "https://apps.apple.com/us/app/tampermonkey/id6738342400"
    }
    Opera = @{
        Tampermonkey = "https://addons.opera.com/en/extensions/details/tampermonkey-beta/"
    }
}

# ============================================
# ASSEMBLIES
# ============================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================
# HELPER FUNCTIONS
# ============================================
function Download-Image {
    param([string]$Url, [string]$OutPath)
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
        $webClient.DownloadFile($Url, $OutPath)
        $webClient.Dispose()
        return $true
    } catch {
        return $false
    }
}

function Get-BitmapImageFromFile {
    param([string]$Path)
    if (Test-Path $Path) {
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.UriSource = New-Object System.Uri($Path, [System.UriKind]::Absolute)
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.EndInit()
        $bitmap.Freeze()
        return $bitmap
    }
    return $null
}

function Get-BitmapImageFromUrl {
    param([string]$Url)
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
        $imageData = $webClient.DownloadData($Url)
        $webClient.Dispose()
        
        $stream = New-Object System.IO.MemoryStream(,$imageData)
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.StreamSource = $stream
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.EndInit()
        $bitmap.Freeze()
        return $bitmap
    } catch {
        return $null
    }
}

# ============================================
# PRE-FLIGHT CHECKS
# ============================================
$tempDir = Join-Path $env:TEMP "YTYT-Installer"
if (!(Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

# Download icon for window
$iconPath = Join-Path $tempDir "ytyt.ico"
Download-Image -Url $script:IconUrl -OutPath $iconPath | Out-Null

# Check for VLC
$vlcPaths = @(
    "${env:ProgramFiles}\VideoLAN\VLC\vlc.exe",
    "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe",
    "$env:LOCALAPPDATA\Programs\VideoLAN\VLC\vlc.exe"
)
$vlcFound = $null
foreach ($path in $vlcPaths) {
    if (Test-Path $path) {
        $vlcFound = $path
        break
    }
}

# ============================================
# XAML GUI DEFINITION
# ============================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="YTYT-Downloader Setup" Height="720" Width="800"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#0a0a0a">
    <Window.Resources>
        <!-- Color Palette -->
        <SolidColorBrush x:Key="BgDark" Color="#0a0a0a"/>
        <SolidColorBrush x:Key="BgCard" Color="#141414"/>
        <SolidColorBrush x:Key="BgHover" Color="#1f1f1f"/>
        <SolidColorBrush x:Key="Border" Color="#2a2a2a"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#fafafa"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#a1a1aa"/>
        <SolidColorBrush x:Key="TextMuted" Color="#71717a"/>
        <SolidColorBrush x:Key="AccentGreen" Color="#22c55e"/>
        <SolidColorBrush x:Key="AccentGreenHover" Color="#16a34a"/>
        <SolidColorBrush x:Key="AccentOrange" Color="#f97316"/>
        <SolidColorBrush x:Key="AccentRed" Color="#ef4444"/>
        <SolidColorBrush x:Key="AccentBlue" Color="#3b82f6"/>
        
        <!-- Base Button Style -->
        <Style x:Key="BaseButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentGreen}"/>
            <Setter Property="Foreground" Value="#0a0a0a"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="24,12"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                CornerRadius="8" 
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="{StaticResource AccentGreenHover}"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Opacity" Value="0.5"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <!-- Secondary Button -->
        <Style x:Key="SecondaryButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="{StaticResource BgCard}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8" 
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="{StaticResource BgHover}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <!-- Danger Button -->
        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="{StaticResource AccentRed}"/>
            <Setter Property="Foreground" Value="White"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#dc2626"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <!-- Browser Icon Button -->
        <Style x:Key="BrowserButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Width" Value="72"/>
            <Setter Property="Height" Value="72"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{StaticResource BgCard}" 
                                BorderBrush="{StaticResource Border}" BorderThickness="2"
                                CornerRadius="12" Padding="12">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="{StaticResource AccentGreen}"/>
                                <Setter TargetName="border" Property="Background" Value="{StaticResource BgHover}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- TextBox Style -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource BgCard}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,10"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="CaretBrush" Value="{StaticResource TextPrimary}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8">
                            <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsFocused" Value="True">
                    <Setter Property="BorderBrush" Value="{StaticResource AccentGreen}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <!-- CheckBox Style -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal">
                            <Border x:Name="checkbox" Width="20" Height="20" 
                                    Background="{StaticResource BgCard}" 
                                    BorderBrush="{StaticResource Border}" 
                                    BorderThickness="2" CornerRadius="4"
                                    VerticalAlignment="Center">
                                <Path x:Name="checkmark" Data="M3,7 L6,10 L11,4" 
                                      Stroke="{StaticResource AccentGreen}" StrokeThickness="2"
                                      Visibility="Collapsed" Margin="2"/>
                            </Border>
                            <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="checkmark" Property="Visibility" Value="Visible"/>
                                <Setter TargetName="checkbox" Property="BorderBrush" Value="{StaticResource AccentGreen}"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="checkbox" Property="BorderBrush" Value="{StaticResource AccentGreen}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Label Style -->
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="0"/>
        </Style>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="0,0,0,1">
            <Grid Margin="32,24">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <Image x:Name="imgLogo" Grid.Column="0" Width="180" Height="60" Stretch="Uniform" Margin="0,0,24,0"/>
                
                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="Setup Wizard" FontSize="24" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" FontFamily="Segoe UI"/>
                    <TextBlock x:Name="txtSubtitle" Text="Stream to VLC and download with yt-dlp" FontSize="14" Foreground="{StaticResource TextSecondary}" FontFamily="Segoe UI" Margin="0,4,0,0"/>
                </StackPanel>
                
                <TextBlock Grid.Column="2" Text="v2.0.0" FontSize="12" Foreground="{StaticResource TextMuted}" VerticalAlignment="Top" FontFamily="Segoe UI Semibold"/>
            </Grid>
        </Border>
        
        <!-- Main Content - TabControl without visible tabs -->
        <TabControl x:Name="tabWizard" Grid.Row="1" Background="Transparent" BorderThickness="0" Padding="0">
            <TabControl.ItemContainerStyle>
                <Style TargetType="TabItem">
                    <Setter Property="Visibility" Value="Collapsed"/>
                </Style>
            </TabControl.ItemContainerStyle>
            
            <!-- Step 1: Welcome / Base Tools -->
            <TabItem x:Name="tabStep1">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="32,24">
                        <!-- Step Indicator -->
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,32">
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <TextBlock Text="1" Foreground="#0a0a0a" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource Border}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource BgCard}" Stroke="{StaticResource Border}" StrokeThickness="2"/>
                            <TextBlock Text="2" Foreground="{StaticResource TextMuted}" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource Border}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource BgCard}" Stroke="{StaticResource Border}" StrokeThickness="2"/>
                            <TextBlock Text="3" Foreground="{StaticResource TextMuted}" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                        </StackPanel>
                        
                        <TextBlock Text="Step 1: Install Base Tools" FontSize="20" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,8"/>
                        <TextBlock Text="Configure installation paths and options for yt-dlp and ffmpeg." FontSize="14" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,24" TextWrapping="Wrap"/>
                        
                        <!-- VLC Status -->
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="20" Margin="0,0,0,16">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Ellipse x:Name="vlcIndicator" Width="12" Height="12" Fill="{StaticResource AccentRed}" VerticalAlignment="Center" Margin="0,0,16,0"/>
                                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                                    <TextBlock Text="VLC Media Player" FontSize="14" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}"/>
                                    <TextBlock x:Name="txtVlcStatus" Text="Not detected" FontSize="12" Foreground="{StaticResource TextSecondary}"/>
                                </StackPanel>
                                <Button x:Name="btnInstallVlc" Content="Install VLC" Grid.Column="2" Style="{StaticResource SecondaryButton}" Padding="16,8"/>
                            </Grid>
                        </Border>
                        
                        <!-- VLC Path -->
                        <TextBlock Text="VLC Path" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,8"/>
                        <Grid Margin="0,0,0,16">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="txtVlcPath" Grid.Column="0"/>
                            <Button x:Name="btnBrowseVlc" Content="Browse" Grid.Column="1" Style="{StaticResource SecondaryButton}" Margin="12,0,0,0" Padding="16,10"/>
                        </Grid>
                        
                        <!-- Download Path -->
                        <TextBlock Text="Download Folder" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,8"/>
                        <Grid Margin="0,0,0,24">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="txtDownloadPath" Grid.Column="0"/>
                            <Button x:Name="btnBrowseDownload" Content="Browse" Grid.Column="1" Style="{StaticResource SecondaryButton}" Margin="12,0,0,0" Padding="16,10"/>
                        </Grid>
                        
                        <!-- Options -->
                        <TextBlock Text="Options" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,12"/>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="20">
                            <StackPanel>
                                <CheckBox x:Name="chkAutoUpdate" Content="Auto-update yt-dlp before each download" IsChecked="True" Margin="0,0,0,12"/>
                                <CheckBox x:Name="chkNotifications" Content="Show toast notifications for download progress" IsChecked="True" Margin="0,0,0,12"/>
                                <CheckBox x:Name="chkDesktopShortcut" Content="Create desktop shortcut for clipboard downloads" IsChecked="False"/>
                            </StackPanel>
                        </Border>
                        
                        <!-- Status Box -->
                        <TextBlock Text="Installation Log" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,24,0,8"/>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="16">
                            <ScrollViewer x:Name="statusScroll" Height="120" VerticalScrollBarVisibility="Auto">
                                <TextBlock x:Name="txtStatus" Text="Ready to install base tools..." Foreground="{StaticResource TextMuted}" TextWrapping="Wrap" FontFamily="Cascadia Code, Consolas, monospace" FontSize="12"/>
                            </ScrollViewer>
                        </Border>
                        
                        <!-- Progress Bar -->
                        <Border Background="{StaticResource BgCard}" CornerRadius="4" Height="8" Margin="0,16,0,0">
                            <Border x:Name="progressFill" Background="{StaticResource AccentGreen}" CornerRadius="4" HorizontalAlignment="Left" Width="0"/>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            
            <!-- Step 2: Install Userscript Manager -->
            <TabItem x:Name="tabStep2">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="32,24">
                        <!-- Step Indicator -->
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,32">
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <Path Data="M8,12 L11,15 L16,9" Stroke="#0a0a0a" StrokeThickness="2" Margin="-26,8,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource AccentGreen}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <TextBlock Text="2" Foreground="#0a0a0a" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource Border}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource BgCard}" Stroke="{StaticResource Border}" StrokeThickness="2"/>
                            <TextBlock Text="3" Foreground="{StaticResource TextMuted}" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                        </StackPanel>
                        
                        <TextBlock Text="Step 2: Install a Userscript Manager" FontSize="20" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,8"/>
                        <TextBlock Text="Select your browser to see compatible userscript manager extensions." FontSize="14" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,24" TextWrapping="Wrap"/>
                        
                        <!-- Browser Selection -->
                        <TextBlock Text="Select Your Browser" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,16"/>
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,24">
                            <Button x:Name="btnChrome" Style="{StaticResource BrowserButton}" ToolTip="Chrome / Chromium" Margin="8">
                                <Image x:Name="imgChrome" Width="40" Height="40" Stretch="Uniform"/>
                            </Button>
                            <Button x:Name="btnFirefox" Style="{StaticResource BrowserButton}" ToolTip="Firefox" Margin="8">
                                <Image x:Name="imgFirefox" Width="40" Height="40" Stretch="Uniform"/>
                            </Button>
                            <Button x:Name="btnEdge" Style="{StaticResource BrowserButton}" ToolTip="Microsoft Edge" Margin="8">
                                <Image x:Name="imgEdge" Width="40" Height="40" Stretch="Uniform"/>
                            </Button>
                            <Button x:Name="btnSafari" Style="{StaticResource BrowserButton}" ToolTip="Safari" Margin="8">
                                <Image x:Name="imgSafari" Width="40" Height="40" Stretch="Uniform"/>
                            </Button>
                            <Button x:Name="btnOpera" Style="{StaticResource BrowserButton}" ToolTip="Opera" Margin="8">
                                <Image x:Name="imgOpera" Width="40" Height="40" Stretch="Uniform"/>
                            </Button>
                        </StackPanel>
                        
                        <!-- Selected Browser Info -->
                        <Border x:Name="pnlBrowserLinks" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="24" Visibility="Collapsed">
                            <StackPanel>
                                <TextBlock x:Name="txtSelectedBrowser" Text="Chrome / Chromium" FontSize="18" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,16"/>
                                <TextBlock Text="Compatible Userscript Managers:" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,12"/>
                                <StackPanel x:Name="pnlManagerLinks">
                                    <!-- Dynamically populated -->
                                </StackPanel>
                            </StackPanel>
                        </Border>
                        
                        <!-- Instructions -->
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource AccentOrange}" BorderThickness="1" CornerRadius="12" Padding="20" Margin="0,24,0,0">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock Text="!" FontSize="20" Foreground="{StaticResource AccentOrange}" FontWeight="Bold" Margin="0,0,16,0" VerticalAlignment="Top"/>
                                <StackPanel>
                                    <TextBlock Text="Important" FontSize="14" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,4"/>
                                    <TextBlock Text="Install a userscript manager extension in your browser before proceeding to the next step. Tampermonkey is recommended for most users." FontSize="13" Foreground="{StaticResource TextSecondary}" TextWrapping="Wrap"/>
                                </StackPanel>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            
            <!-- Step 3: Install Userscript -->
            <TabItem x:Name="tabStep3">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="32,24">
                        <!-- Step Indicator -->
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,32">
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <Path Data="M8,12 L11,15 L16,9" Stroke="#0a0a0a" StrokeThickness="2" Margin="-26,8,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource AccentGreen}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <Path Data="M8,12 L11,15 L16,9" Stroke="#0a0a0a" StrokeThickness="2" Margin="-26,8,0,0"/>
                            <Rectangle Width="60" Height="2" Fill="{StaticResource AccentGreen}" VerticalAlignment="Center" Margin="8,0"/>
                            <Ellipse Width="32" Height="32" Fill="{StaticResource AccentGreen}"/>
                            <TextBlock Text="3" Foreground="#0a0a0a" FontWeight="Bold" FontSize="14" Margin="-22,7,0,0"/>
                        </StackPanel>
                        
                        <TextBlock Text="Step 3: Install the Userscript" FontSize="20" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,8"/>
                        <TextBlock Text="Click the button below to install the YTYT-Downloader userscript in your browser." FontSize="14" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,32" TextWrapping="Wrap"/>
                        
                        <!-- Big Install Button -->
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="16" Padding="32" HorizontalAlignment="Center">
                            <StackPanel HorizontalAlignment="Center">
                                <Image x:Name="imgUserscriptIcon" Width="80" Height="80" Margin="0,0,0,20"/>
                                <TextBlock Text="YTYT-Downloader Userscript" FontSize="18" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                                <TextBlock Text="Adds VLC and Download buttons to YouTube" FontSize="13" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center" Margin="0,0,0,20"/>
                                <Button x:Name="btnInstallUserscript" Content="Install Userscript" Style="{StaticResource BaseButton}" Padding="32,14" FontSize="16"/>
                            </StackPanel>
                        </Border>
                        
                        <!-- Success Message -->
                        <Border Background="#14532d" BorderBrush="{StaticResource AccentGreen}" BorderThickness="1" CornerRadius="12" Padding="20" Margin="0,32,0,0">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock Text="OK" FontSize="16" Foreground="{StaticResource AccentGreen}" FontWeight="Bold" Margin="0,0,16,0" VerticalAlignment="Top"/>
                                <StackPanel>
                                    <TextBlock Text="Setup Complete!" FontSize="14" FontWeight="SemiBold" Foreground="{StaticResource AccentGreen}" Margin="0,0,0,4"/>
                                    <TextBlock Text="After installing the userscript, visit any YouTube video. You'll see VLC (orange) and DL (green) buttons next to the like/share buttons." FontSize="13" Foreground="#86efac" TextWrapping="Wrap"/>
                                </StackPanel>
                            </StackPanel>
                        </Border>
                        
                        <!-- Alternate Install -->
                        <TextBlock Text="Alternative: Manual Installation" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,32,0,8"/>
                        <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="16">
                            <StackPanel>
                                <TextBlock TextWrapping="Wrap" FontSize="13" Foreground="{StaticResource TextSecondary}">
                                    <Run>If the automatic install doesn't work, you can drag the userscript file into your userscript manager:</Run>
                                </TextBlock>
                                <Button x:Name="btnOpenFolder" Content="Open Install Folder" Style="{StaticResource SecondaryButton}" Margin="0,12,0,0" Padding="16,10" HorizontalAlignment="Left"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            
            <!-- Uninstall Tab -->
            <TabItem x:Name="tabUninstall">
                <StackPanel Margin="32,24" VerticalAlignment="Center" HorizontalAlignment="Center">
                    <Image x:Name="imgUninstallIcon" Width="80" Height="80" Margin="0,0,0,24"/>
                    <TextBlock Text="Uninstall YTYT-Downloader" FontSize="24" FontWeight="SemiBold" Foreground="{StaticResource TextPrimary}" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                    <TextBlock Text="This will remove all installed components and protocol handlers." FontSize="14" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center" Margin="0,0,0,32" TextWrapping="Wrap" MaxWidth="400" TextAlignment="Center"/>
                    
                    <Border Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="24" Margin="0,0,0,24">
                        <StackPanel>
                            <TextBlock Text="The following will be removed:" FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,12"/>
                            <TextBlock Text="[X] Protocol handlers (ytvlc://, ytdl://, etc.)" Foreground="{StaticResource TextMuted}" FontFamily="Cascadia Code, Consolas" FontSize="12" Margin="0,4"/>
                            <TextBlock Text="[X] yt-dlp and ffmpeg executables" Foreground="{StaticResource TextMuted}" FontFamily="Cascadia Code, Consolas" FontSize="12" Margin="0,4"/>
                            <TextBlock Text="[X] Configuration files" Foreground="{StaticResource TextMuted}" FontFamily="Cascadia Code, Consolas" FontSize="12" Margin="0,4"/>
                            <TextBlock Text="[X] Desktop and startup shortcuts" Foreground="{StaticResource TextMuted}" FontFamily="Cascadia Code, Consolas" FontSize="12" Margin="0,4"/>
                            <TextBlock Text="[!] Userscript must be removed manually from browser" Foreground="{StaticResource AccentOrange}" FontFamily="Cascadia Code, Consolas" FontSize="12" Margin="0,12,0,0"/>
                        </StackPanel>
                    </Border>
                    
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <Button x:Name="btnCancelUninstall" Content="Cancel" Style="{StaticResource SecondaryButton}" Margin="0,0,12,0" Padding="24,12"/>
                        <Button x:Name="btnConfirmUninstall" Content="Uninstall" Style="{StaticResource DangerButton}" Padding="24,12"/>
                    </StackPanel>
                </StackPanel>
            </TabItem>
        </TabControl>
        
        <!-- Footer -->
        <Border Grid.Row="2" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="0,1,0,0">
            <Grid Margin="32,16">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <Button x:Name="btnUninstall" Content="Uninstall" Style="{StaticResource SecondaryButton}" Padding="16,10" Grid.Column="0"/>
                
                <StackPanel Grid.Column="2" Orientation="Horizontal">
                    <Button x:Name="btnBack" Content="Back" Style="{StaticResource SecondaryButton}" Padding="20,10" Margin="0,0,12,0" Visibility="Collapsed"/>
                    <Button x:Name="btnNext" Content="Install Base Tools" Style="{StaticResource BaseButton}" Padding="20,10"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# ============================================
# LOAD WINDOW
# ============================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Set window icon
if (Test-Path $iconPath) {
    $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new($iconPath))
}

# ============================================
# GET CONTROLS
# ============================================
$imgLogo = $window.FindName("imgLogo")
$txtSubtitle = $window.FindName("txtSubtitle")
$tabWizard = $window.FindName("tabWizard")

# Step 1 controls
$vlcIndicator = $window.FindName("vlcIndicator")
$txtVlcStatus = $window.FindName("txtVlcStatus")
$btnInstallVlc = $window.FindName("btnInstallVlc")
$txtVlcPath = $window.FindName("txtVlcPath")
$btnBrowseVlc = $window.FindName("btnBrowseVlc")
$txtDownloadPath = $window.FindName("txtDownloadPath")
$btnBrowseDownload = $window.FindName("btnBrowseDownload")
$chkAutoUpdate = $window.FindName("chkAutoUpdate")
$chkNotifications = $window.FindName("chkNotifications")
$chkDesktopShortcut = $window.FindName("chkDesktopShortcut")
$txtStatus = $window.FindName("txtStatus")
$statusScroll = $window.FindName("statusScroll")
$progressFill = $window.FindName("progressFill")

# Step 2 controls
$btnChrome = $window.FindName("btnChrome")
$btnFirefox = $window.FindName("btnFirefox")
$btnEdge = $window.FindName("btnEdge")
$btnSafari = $window.FindName("btnSafari")
$btnOpera = $window.FindName("btnOpera")
$imgChrome = $window.FindName("imgChrome")
$imgFirefox = $window.FindName("imgFirefox")
$imgEdge = $window.FindName("imgEdge")
$imgSafari = $window.FindName("imgSafari")
$imgOpera = $window.FindName("imgOpera")
$pnlBrowserLinks = $window.FindName("pnlBrowserLinks")
$txtSelectedBrowser = $window.FindName("txtSelectedBrowser")
$pnlManagerLinks = $window.FindName("pnlManagerLinks")

# Step 3 controls
$imgUserscriptIcon = $window.FindName("imgUserscriptIcon")
$btnInstallUserscript = $window.FindName("btnInstallUserscript")
$btnOpenFolder = $window.FindName("btnOpenFolder")

# Uninstall controls
$imgUninstallIcon = $window.FindName("imgUninstallIcon")
$btnCancelUninstall = $window.FindName("btnCancelUninstall")
$btnConfirmUninstall = $window.FindName("btnConfirmUninstall")

# Footer controls
$btnUninstall = $window.FindName("btnUninstall")
$btnBack = $window.FindName("btnBack")
$btnNext = $window.FindName("btnNext")

# ============================================
# LOAD IMAGES
# ============================================
$logoImage = Get-BitmapImageFromUrl -Url $script:LogoUrl
if ($logoImage) { $imgLogo.Source = $logoImage }

$iconImage = Get-BitmapImageFromUrl -Url $script:IconPngUrl
if ($iconImage) { 
    $imgUserscriptIcon.Source = $iconImage 
    $imgUninstallIcon.Source = $iconImage
}

# Load browser icons
$imgChrome.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Chrome
$imgFirefox.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Firefox
$imgEdge.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Edge
$imgSafari.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Safari
$imgOpera.Source = Get-BitmapImageFromUrl -Url $script:BrowserIcons.Opera

# ============================================
# SET DEFAULTS
# ============================================
if ($vlcFound) {
    $txtVlcPath.Text = $vlcFound
    $vlcIndicator.Fill = [System.Windows.Media.Brushes]::LimeGreen
    $txtVlcStatus.Text = "Detected: $vlcFound"
    $btnInstallVlc.Visibility = "Collapsed"
} else {
    $txtVlcPath.Text = ""
    $txtVlcStatus.Text = "Not detected - click Install VLC or browse manually"
}
$txtDownloadPath.Text = $script:DefaultDownloadPath

# Track wizard state
$script:CurrentStep = 1
$script:BaseToolsInstalled = $false

# ============================================
# HELPER FUNCTIONS
# ============================================
function Update-Status {
    param([string]$Message)
    $txtStatus.Text = $txtStatus.Text + "`n" + $Message
    $statusScroll.ScrollToEnd()
    $window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
}

function Set-Progress {
    param([int]$Value)
    $maxWidth = $progressFill.Parent.ActualWidth
    if ($maxWidth -le 0) { $maxWidth = 700 }
    $progressFill.Width = ($Value / 100) * $maxWidth
    $window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
}

function Update-WizardButtons {
    switch ($script:CurrentStep) {
        1 {
            $btnBack.Visibility = "Collapsed"
            if ($script:BaseToolsInstalled) {
                $btnNext.Content = "Next: Userscript Manager"
            } else {
                $btnNext.Content = "Install Base Tools"
            }
        }
        2 {
            $btnBack.Visibility = "Visible"
            $btnNext.Content = "Next: Install Userscript"
        }
        3 {
            $btnBack.Visibility = "Visible"
            $btnNext.Content = "Finish"
        }
        4 {
            $btnBack.Visibility = "Collapsed"
            $btnNext.Visibility = "Collapsed"
        }
    }
}

function Show-BrowserLinks {
    param([string]$Browser)
    
    $pnlBrowserLinks.Visibility = "Visible"
    $txtSelectedBrowser.Text = $Browser
    $pnlManagerLinks.Children.Clear()
    
    $managers = $script:UserscriptManagers[$Browser]
    foreach ($manager in $managers.GetEnumerator()) {
        $linkPanel = New-Object System.Windows.Controls.StackPanel
        $linkPanel.Orientation = "Horizontal"
        $linkPanel.Margin = "0,8,0,0"
        
        $bullet = New-Object System.Windows.Controls.TextBlock
        $bullet.Text = ">"
        $bullet.Foreground = [System.Windows.Media.Brushes]::LimeGreen
        $bullet.FontFamily = New-Object System.Windows.Media.FontFamily("Cascadia Code, Consolas")
        $bullet.Margin = "0,0,8,0"
        $bullet.VerticalAlignment = "Center"
        
        $link = New-Object System.Windows.Controls.TextBlock
        $link.Cursor = [System.Windows.Input.Cursors]::Hand
        $link.VerticalAlignment = "Center"
        
        $hyperlink = New-Object System.Windows.Documents.Hyperlink
        $hyperlink.Inlines.Add($manager.Key)
        $hyperlink.Foreground = [System.Windows.Media.Brushes]::DodgerBlue
        $hyperlink.TextDecorations = $null
        $url = $manager.Value
        $hyperlink.Add_Click({ Start-Process $url }.GetNewClosure())
        $hyperlink.Add_MouseEnter({ $this.TextDecorations = [System.Windows.TextDecorations]::Underline })
        $hyperlink.Add_MouseLeave({ $this.TextDecorations = $null })
        
        $link.Inlines.Add($hyperlink)
        
        $linkPanel.Children.Add($bullet)
        $linkPanel.Children.Add($link)
        $pnlManagerLinks.Children.Add($linkPanel)
    }
}

# ============================================
# EVENT HANDLERS
# ============================================

# Browse VLC
$btnBrowseVlc.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "VLC|vlc.exe|All Files|*.*"
    $dialog.Title = "Select VLC executable"
    if ($dialog.ShowDialog()) {
        $txtVlcPath.Text = $dialog.FileName
        $vlcIndicator.Fill = [System.Windows.Media.Brushes]::LimeGreen
        $txtVlcStatus.Text = "Selected: $($dialog.FileName)"
    }
})

# Browse Download folder
$btnBrowseDownload.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select download folder"
    $dialog.SelectedPath = $txtDownloadPath.Text
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtDownloadPath.Text = $dialog.SelectedPath
    }
})

# Install VLC via winget
$btnInstallVlc.Add_Click({
    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetPath) {
        Update-Status "Installing VLC via winget..."
        $btnInstallVlc.IsEnabled = $false
        try {
            Start-Process -FilePath "winget" -ArgumentList "install", "--id", "VideoLAN.VLC", "--accept-package-agreements", "--accept-source-agreements", "-h" -Wait -NoNewWindow
            Start-Sleep -Seconds 2
            foreach ($path in $vlcPaths) {
                if (Test-Path $path) {
                    $txtVlcPath.Text = $path
                    $vlcIndicator.Fill = [System.Windows.Media.Brushes]::LimeGreen
                    $txtVlcStatus.Text = "Installed: $path"
                    $btnInstallVlc.Visibility = "Collapsed"
                    Update-Status "VLC installed successfully!"
                    break
                }
            }
        } catch {
            Update-Status "Error installing VLC: $($_.Exception.Message)"
        }
        $btnInstallVlc.IsEnabled = $true
    } else {
        [System.Windows.MessageBox]::Show("winget is not available. Please install VLC manually from https://www.videolan.org/vlc/", "YTYT-Downloader", "OK", "Warning")
        Start-Process "https://www.videolan.org/vlc/"
    }
})

# Browser buttons
$btnChrome.Add_Click({ Show-BrowserLinks -Browser "Chrome" })
$btnFirefox.Add_Click({ Show-BrowserLinks -Browser "Firefox" })
$btnEdge.Add_Click({ Show-BrowserLinks -Browser "Edge" })
$btnSafari.Add_Click({ Show-BrowserLinks -Browser "Safari" })
$btnOpera.Add_Click({ Show-BrowserLinks -Browser "Opera" })

# Install Userscript button
$btnInstallUserscript.Add_Click({
    Start-Process $script:UserscriptUrl
})

# Open folder button
$btnOpenFolder.Add_Click({
    if (Test-Path $script:InstallPath) {
        $userscriptPath = Join-Path $script:InstallPath "YTYT-Downloader.user.js"
        if (Test-Path $userscriptPath) {
            Start-Process explorer.exe -ArgumentList "/select,`"$userscriptPath`""
        } else {
            Start-Process explorer.exe -ArgumentList $script:InstallPath
        }
    } else {
        [System.Windows.MessageBox]::Show("Install folder not found. Please complete Step 1 first.", "YTYT-Downloader", "OK", "Warning")
    }
})

# Back button
$btnBack.Add_Click({
    if ($script:CurrentStep -eq 4) {
        $script:CurrentStep = 1
        $tabWizard.SelectedIndex = 0
    } elseif ($script:CurrentStep -gt 1) {
        $script:CurrentStep--
        $tabWizard.SelectedIndex = $script:CurrentStep - 1
    }
    Update-WizardButtons
})

# Uninstall button (show uninstall tab)
$btnUninstall.Add_Click({
    $script:CurrentStep = 4
    $tabWizard.SelectedIndex = 3
    Update-WizardButtons
})

# Cancel uninstall
$btnCancelUninstall.Add_Click({
    $script:CurrentStep = 1
    $tabWizard.SelectedIndex = 0
    $btnNext.Visibility = "Visible"
    Update-WizardButtons
})

# Confirm uninstall
$btnConfirmUninstall.Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "Are you sure you want to uninstall YTYT-Downloader?`n`nThis will remove all components and cannot be undone.",
        "Confirm Uninstall",
        "YesNo",
        "Warning"
    )
    
    if ($result -eq "Yes") {
        try {
            # Force kill yt-dlp and ffmpeg processes
            Get-Process -Name "yt-dlp" -ErrorAction SilentlyContinue | Stop-Process -Force
            Get-Process -Name "ffmpeg" -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Milliseconds 500
            
            # Remove protocol handlers
            Remove-Item -Path "HKCU:\Software\Classes\ytvlc" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "HKCU:\Software\Classes\ytvlcq" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "HKCU:\Software\Classes\ytdl" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "HKCU:\Software\Classes\ytmpv" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "HKCU:\Software\Classes\ytdlplay" -Recurse -Force -ErrorAction SilentlyContinue
            
            # Remove install directory
            if (Test-Path $script:InstallPath) {
                Remove-Item -Path $script:InstallPath -Recurse -Force
            }
            
            # Remove desktop shortcut
            $shortcutPath = "$env:USERPROFILE\Desktop\YouTube Download.lnk"
            if (Test-Path $shortcutPath) {
                Remove-Item $shortcutPath -Force
            }
            
            # Remove startup shortcut
            $startupPath = [Environment]::GetFolderPath('Startup')
            $serverShortcut = Join-Path $startupPath "YTYT-Server.lnk"
            if (Test-Path $serverShortcut) {
                Remove-Item $serverShortcut -Force
            }
            
            [System.Windows.MessageBox]::Show(
                "YTYT-Downloader has been uninstalled successfully.`n`nRemember to also remove the userscript from your browser's userscript manager.",
                "Uninstall Complete",
                "OK",
                "Information"
            )
            $window.Close()
        } catch {
            [System.Windows.MessageBox]::Show("Error during uninstall: $($_.Exception.Message)", "Error", "OK", "Error")
        }
    }
})

# Next button (main action button)
$btnNext.Add_Click({
    switch ($script:CurrentStep) {
        1 {
            if (-not $script:BaseToolsInstalled) {
                # Run installation
                $btnNext.IsEnabled = $false
                $btnBack.IsEnabled = $false
                $txtStatus.Text = "Starting installation..."
                Set-Progress 0
                
                try {
                    # Step 1: Create directories
                    Update-Status "Creating directories..."
                    Set-Progress 5
                    
                    if (!(Test-Path $script:InstallPath)) {
                        New-Item -ItemType Directory -Path $script:InstallPath -Force | Out-Null
                    }
                    Update-Status "  [OK] Install path: $($script:InstallPath)"
                    
                    $dlPath = $txtDownloadPath.Text
                    if (!(Test-Path $dlPath)) {
                        New-Item -ItemType Directory -Path $dlPath -Force | Out-Null
                    }
                    Update-Status "  [OK] Download path: $dlPath"
                    Set-Progress 10
                    
                    # Step 2: Download yt-dlp
                    Update-Status "Downloading yt-dlp..."
                    $ytdlpPath = Join-Path $script:InstallPath "yt-dlp.exe"
                    Invoke-WebRequest -Uri $script:YtDlpUrl -OutFile $ytdlpPath -UseBasicParsing
                    Update-Status "  [OK] Downloaded yt-dlp"
                    Set-Progress 25
                    
                    # Step 3: Download ffmpeg
                    Update-Status "Downloading ffmpeg (this may take a moment)..."
                    $ffmpegZipUrl = "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
                    $ffmpegZip = Join-Path $script:InstallPath "ffmpeg.zip"
                    $ffmpegPath = Join-Path $script:InstallPath "ffmpeg.exe"
                    
                    if (!(Test-Path $ffmpegPath)) {
                        try {
                            Invoke-WebRequest -Uri $ffmpegZipUrl -OutFile $ffmpegZip -UseBasicParsing
                            Update-Status "  [OK] Downloaded ffmpeg archive"
                            Update-Status "  Extracting ffmpeg..."
                            
                            Add-Type -AssemblyName System.IO.Compression.FileSystem
                            $zip = [System.IO.Compression.ZipFile]::OpenRead($ffmpegZip)
                            $ffmpegEntry = $zip.Entries | Where-Object { $_.Name -eq "ffmpeg.exe" } | Select-Object -First 1
                            if ($ffmpegEntry) {
                                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($ffmpegEntry, $ffmpegPath, $true)
                            }
                            $zip.Dispose()
                            Remove-Item $ffmpegZip -Force -ErrorAction SilentlyContinue
                            Update-Status "  [OK] Extracted ffmpeg"
                        } catch {
                            Update-Status "  [!] Warning: Could not download ffmpeg"
                            Update-Status "      You can install manually via: winget install ffmpeg"
                        }
                    } else {
                        Update-Status "  [OK] ffmpeg already exists"
                    }
                    Set-Progress 40
                    
                    # Step 4: Save config
                    Update-Status "Saving configuration..."
                    $config = @{
                        VlcPath = $txtVlcPath.Text
                        DownloadPath = $dlPath
                        AutoUpdate = $chkAutoUpdate.IsChecked
                        Notifications = $chkNotifications.IsChecked
                        SponsorBlock = $true
                        YtDlpPath = $ytdlpPath
                        FfmpegPath = $ffmpegPath
                    }
                    $config | ConvertTo-Json | Set-Content (Join-Path $script:InstallPath "config.json") -Encoding UTF8
                    Update-Status "  [OK] Configuration saved"
                    Set-Progress 45
                    
                    # Step 5: Create handlers
                    Update-Status "Creating protocol handlers..."
                    
                    # VLC Handler
                    $vlcHandler = @'
param([string]$url)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$videoUrl = $url -replace '^ytvlc://', ''
$videoUrl = [System.Uri]::UnescapeDataString($videoUrl)

$videoId = $null
if ($videoUrl -match '[?&]v=([^&]+)') { $videoId = $matches[1] }
elseif ($videoUrl -match 'youtu\.be/([^?]+)') { $videoId = $matches[1] }

$isLive = $false
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    $pageContent = $webClient.DownloadString("https://www.youtube.com/watch?v=$videoId")
    if ($pageContent -match '"isLiveNow"\s*:\s*true') { $isLive = $true }
    $webClient.Dispose()
} catch { }

$videoTitle = "YouTube Video"
try {
    $titleOutput = & $config.YtDlpPath --get-title $videoUrl 2>$null
    if ($titleOutput) { $videoTitle = $titleOutput }
} catch { }

if ($isLive) {
    $vlcArgs = @("--no-video-title-show", "--meta-title=`"$videoTitle (LIVE)`"", $videoUrl)
    Start-Process -FilePath $config.VlcPath -ArgumentList $vlcArgs
} else {
    if ($config.AutoUpdate) {
        Start-Process -FilePath $config.YtDlpPath -ArgumentList "--update" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    }
    $streams = & $config.YtDlpPath -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" -g $videoUrl 2>$null
    if ($streams) {
        $streamArray = $streams -split "`n" | Where-Object { $_ -match "^http" }
        $vlcArgs = @("--no-video-title-show", "--meta-title=`"$videoTitle`"")
        if ($streamArray.Count -ge 2) {
            $vlcArgs += "`"$($streamArray[0])`""
            $vlcArgs += "--input-slave=`"$($streamArray[1])`""
        } else {
            $vlcArgs += "`"$($streamArray[0])`""
        }
        Start-Process -FilePath $config.VlcPath -ArgumentList $vlcArgs
    }
}

if ($config.Notifications) {
    $iconPath = Join-Path $PSScriptRoot "icon.ico"
    $notify = New-Object System.Windows.Forms.NotifyIcon
    if (Test-Path $iconPath) {
        $notify.Icon = New-Object System.Drawing.Icon($iconPath)
    } else {
        $notify.Icon = [System.Drawing.SystemIcons]::Information
    }
    $notify.BalloonTipTitle = "YTYT-Downloader"
    $notify.BalloonTipText = "Playing: $videoTitle"
    $notify.Visible = $true
    $notify.ShowBalloonTip(3000)
    Start-Sleep -Seconds 3
    $notify.Dispose()
}
'@
                    $vlcHandler | Set-Content (Join-Path $script:InstallPath "ytvlc-handler.ps1") -Encoding UTF8
                    Update-Status "  [OK] VLC handler"
                    Set-Progress 50
                    
                    # Download Handler
                    $dlHandler = @'
param([string]$url)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$videoUrl = $url -replace '^ytdl://', ''
$videoUrl = [System.Uri]::UnescapeDataString($videoUrl)

$iconPath = Join-Path $PSScriptRoot "icon.ico"
$notify = $null
if ($config.Notifications) {
    $notify = New-Object System.Windows.Forms.NotifyIcon
    if (Test-Path $iconPath) {
        $notify.Icon = New-Object System.Drawing.Icon($iconPath)
    } else {
        $notify.Icon = [System.Drawing.SystemIcons]::Information
    }
    $notify.BalloonTipTitle = "YTYT-Downloader"
    $notify.BalloonTipText = "Starting download..."
    $notify.Visible = $true
    $notify.ShowBalloonTip(2000)
}

if ($config.AutoUpdate) {
    Start-Process -FilePath $config.YtDlpPath -ArgumentList "--update" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

$outputTemplate = Join-Path $config.DownloadPath "%(title)s.%(ext)s"
$ffmpegLocation = Split-Path $config.FfmpegPath -Parent

$arguments = @(
    "-f", "bestvideo[height<=1080]+bestaudio/best[height<=1080]"
    "--merge-output-format", "mp4"
    "--ffmpeg-location", "`"$ffmpegLocation`""
    "-o", "`"$outputTemplate`""
    $videoUrl
)

$process = Start-Process -FilePath $config.YtDlpPath -ArgumentList $arguments -NoNewWindow -Wait -PassThru

if ($config.Notifications -and $notify) {
    Start-Sleep -Seconds 1
    if ($process.ExitCode -eq 0) {
        $notify.BalloonTipText = "Download complete!"
        $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    } else {
        $notify.BalloonTipText = "Download may have failed"
        $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
    }
    $notify.ShowBalloonTip(3000)
    Start-Sleep -Seconds 3
    $notify.Dispose()
}
'@
                    $dlHandler | Set-Content (Join-Path $script:InstallPath "ytdl-handler.ps1") -Encoding UTF8
                    Update-Status "  [OK] Download handler"
                    Set-Progress 55
                    
                    # VLC Queue Handler
                    $vlcQueueHandler = @'
param([string]$url)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$videoUrl = $url -replace '^ytvlcq://', ''
$videoUrl = [System.Uri]::UnescapeDataString($videoUrl)

$videoTitle = "YouTube Video"
try {
    $titleOutput = & $config.YtDlpPath --get-title $videoUrl 2>$null
    if ($titleOutput) { $videoTitle = $titleOutput }
} catch { }

$vlcProcess = Get-Process -Name "vlc" -ErrorAction SilentlyContinue
$streams = & $config.YtDlpPath -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" -g $videoUrl 2>$null

if ($streams) {
    $streamArray = $streams -split "`n" | Where-Object { $_ -match "^http" }
    if ($vlcProcess) {
        $vlcArgs = @("--playlist-enqueue", "--no-video-title-show", "--meta-title=`"$videoTitle`"")
    } else {
        $vlcArgs = @("--no-video-title-show", "--meta-title=`"$videoTitle`"")
    }
    if ($streamArray.Count -ge 2) {
        $vlcArgs += "`"$($streamArray[0])`""
        $vlcArgs += "--input-slave=`"$($streamArray[1])`""
    } else {
        $vlcArgs += "`"$($streamArray[0])`""
    }
    Start-Process -FilePath $config.VlcPath -ArgumentList $vlcArgs
}

if ($config.Notifications) {
    $iconPath = Join-Path $PSScriptRoot "icon.ico"
    $notify = New-Object System.Windows.Forms.NotifyIcon
    if (Test-Path $iconPath) {
        $notify.Icon = New-Object System.Drawing.Icon($iconPath)
    } else {
        $notify.Icon = [System.Drawing.SystemIcons]::Information
    }
    $notify.BalloonTipTitle = "YTYT-Downloader"
    $notify.BalloonTipText = if ($vlcProcess) { "Added to queue: $videoTitle" } else { "Playing: $videoTitle" }
    $notify.Visible = $true
    $notify.ShowBalloonTip(2000)
    Start-Sleep -Seconds 2
    $notify.Dispose()
}
'@
                    $vlcQueueHandler | Set-Content (Join-Path $script:InstallPath "ytvlcq-handler.ps1") -Encoding UTF8
                    Update-Status "  [OK] VLC queue handler"
                    Set-Progress 60
                    
                    # Download icon for notifications
                    Update-Status "Downloading application icon..."
                    $notifyIconPath = Join-Path $script:InstallPath "icon.ico"
                    Download-Image -Url $script:IconUrl -OutPath $notifyIconPath | Out-Null
                    Update-Status "  [OK] Application icon"
                    Set-Progress 65
                    
                    # Step 6: Create VBS launchers
                    Update-Status "Creating silent launchers..."
                    $vbsTemplate = @'
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{SCRIPT}"" """ & WScript.Arguments(0) & """", 0, False
'@
                    @("ytvlc", "ytvlcq", "ytdl") | ForEach-Object {
                        $vbs = $vbsTemplate -replace '{SCRIPT}', (Join-Path $script:InstallPath "$_-handler.ps1")
                        $vbs | Set-Content (Join-Path $script:InstallPath "$_-launcher.vbs") -Encoding ASCII
                    }
                    Update-Status "  [OK] Silent launchers created"
                    Set-Progress 70
                    
                    # Step 7: Register protocols
                    Update-Status "Registering URL protocols..."
                    
                    # ytvlc://
                    $protocolRoot = "HKCU:\Software\Classes\ytvlc"
                    New-Item -Path $protocolRoot -Force | Out-Null
                    Set-ItemProperty -Path $protocolRoot -Name "(Default)" -Value "URL:YTVLC Protocol"
                    Set-ItemProperty -Path $protocolRoot -Name "URL Protocol" -Value ""
                    New-Item -Path "$protocolRoot\shell\open\command" -Force | Out-Null
                    Set-ItemProperty -Path "$protocolRoot\shell\open\command" -Name "(Default)" -Value "wscript.exe `"$(Join-Path $script:InstallPath 'ytvlc-launcher.vbs')`" `"%1`""
                    
                    # ytvlcq://
                    $protocolRoot = "HKCU:\Software\Classes\ytvlcq"
                    New-Item -Path $protocolRoot -Force | Out-Null
                    Set-ItemProperty -Path $protocolRoot -Name "(Default)" -Value "URL:YTVLCQ Protocol"
                    Set-ItemProperty -Path $protocolRoot -Name "URL Protocol" -Value ""
                    New-Item -Path "$protocolRoot\shell\open\command" -Force | Out-Null
                    Set-ItemProperty -Path "$protocolRoot\shell\open\command" -Name "(Default)" -Value "wscript.exe `"$(Join-Path $script:InstallPath 'ytvlcq-launcher.vbs')`" `"%1`""
                    
                    # ytdl://
                    $protocolRoot = "HKCU:\Software\Classes\ytdl"
                    New-Item -Path $protocolRoot -Force | Out-Null
                    Set-ItemProperty -Path $protocolRoot -Name "(Default)" -Value "URL:YTDL Protocol"
                    Set-ItemProperty -Path $protocolRoot -Name "URL Protocol" -Value ""
                    New-Item -Path "$protocolRoot\shell\open\command" -Force | Out-Null
                    Set-ItemProperty -Path "$protocolRoot\shell\open\command" -Name "(Default)" -Value "wscript.exe `"$(Join-Path $script:InstallPath 'ytdl-launcher.vbs')`" `"%1`""
                    
                    Update-Status "  [OK] Registered: ytvlc://, ytvlcq://, ytdl://"
                    Set-Progress 80
                    
                    # Step 8: Create userscript
                    Update-Status "Creating userscript..."
                    $userscript = @'
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
'@
                    $userscript | Set-Content (Join-Path $script:InstallPath "YTYT-Downloader.user.js") -Encoding UTF8
                    Update-Status "  [OK] Userscript created"
                    Set-Progress 90
                    
                    # Step 9: Desktop shortcut (optional)
                    if ($chkDesktopShortcut.IsChecked) {
                        Update-Status "Creating desktop shortcut..."
                        $WshShell = New-Object -ComObject WScript.Shell
                        $shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\YouTube Download.lnk")
                        $shortcut.TargetPath = "powershell.exe"
                        $shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `"Add-Type -AssemblyName System.Windows.Forms; `$url = [System.Windows.Forms.Clipboard]::GetText(); if (`$url -match 'youtube|youtu.be') { Start-Process 'ytdl://' + `$url }`""
                        $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,175"
                        $shortcut.Save()
                        Update-Status "  [OK] Desktop shortcut created"
                    }
                    
                    Set-Progress 100
                    Update-Status ""
                    Update-Status "========================================"
                    Update-Status "Base tools installation complete!"
                    Update-Status "========================================"
                    
                    $script:BaseToolsInstalled = $true
                    $btnNext.Content = "Next: Userscript Manager"
                    
                } catch {
                    Update-Status ""
                    Update-Status "[ERROR] $($_.Exception.Message)"
                    [System.Windows.MessageBox]::Show("Installation failed:`n`n$($_.Exception.Message)", "Error", "OK", "Error")
                }
                
                $btnNext.IsEnabled = $true
                $btnBack.IsEnabled = $true
            } else {
                # Move to step 2
                $script:CurrentStep = 2
                $tabWizard.SelectedIndex = 1
                Update-WizardButtons
            }
        }
        2 {
            # Move to step 3
            $script:CurrentStep = 3
            $tabWizard.SelectedIndex = 2
            Update-WizardButtons
        }
        3 {
            # Finish - close window
            $window.Close()
        }
    }
})

# Initialize
Update-WizardButtons

# Show the window
$window.ShowDialog() | Out-Null

# Cleanup temp files
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
