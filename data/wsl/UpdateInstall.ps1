# Define a function to log messages with timestamps
function LogMessage {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "$Timestamp - $Message" -ForegroundColor $Color
}

# Start logging
LogMessage "Starting Windows Update process..."

# Create Update Session
$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()

# Search for Updates
LogMessage "Searching for updates..."
$SearchResult = $Searcher.Search("IsInstalled=0")

# Check if updates are available
if ($SearchResult.Updates.Count -eq 0) {
    LogMessage "No updates found." -Color "Yellow"
    return
}

# Display updates found
LogMessage "$($SearchResult.Updates.Count) update(s) found."
$UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
foreach ($Update in $SearchResult.Updates) {
    LogMessage "Update found: $($Update.Title)"
    $UpdatesToInstall.Add($Update) | Out-Null
}

# Initialize the Downloader
LogMessage "Downloading updates..."
$Downloader = $Session.CreateUpdateDownloader()
$Downloader.Updates = $UpdatesToInstall

# Download updates
foreach ($Update in $Downloader.Updates) {
    LogMessage "Downloading: $($Update.Title)..."
    # Start downloading this update individually
    $DownloadResult = $Downloader.Download()
    LogMessage "Downloaded: $($Update.Title) successfully." -Color "Green"
}

# Install updates
LogMessage "Installing updates..."
$Installer = $Session.CreateUpdateInstaller()
$Installer.Updates = $UpdatesToInstall

try {
    $InstallResult = $Installer.Install()
    if ($InstallResult.ResultCode -eq 2) {
        LogMessage "Updates installed successfully." -Color "Green"
    } else {
        LogMessage "Installation completed with errors or partial success." -Color "Yellow"
    }
} catch {
    LogMessage "Error occurred during installation: $_" -Color "Red"
}

# Completion message
LogMessage "Windows Update process completed."
