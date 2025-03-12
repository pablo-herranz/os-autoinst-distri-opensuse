# Define a function to log messages with timestamps
function LogMessage {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "$Timestamp - $Message" -ForegroundColor $Color
}

# Validate COM port status at script start
if (-not $port -or -not ($port -is [System.IO.Ports.SerialPort]) -or -not $port.IsOpen) {
    LogMessage "COM port is not initialized or closed. Exiting." -Color "Red"
    exit 1
}

# Set the wallpaper to the default one
LogMessage "Setting default wallpaper..."
# Clear the custom wallpaper registry entry
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value ""

# Refresh the desktop to apply changes
Add-Type @"
using System.Runtime.InteropServices;
public class Desktop {
  [DllImport("user32.dll", CharSet=CharSet.Auto)]
  public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Desktop]::SystemParametersInfo(0x0014, 0, "", 0x01 -bor 0x02)  # SPI_SETDESKWALLPAPER
# Set to the exact default image path
$DefaultWallpaperPath = "$env:Windir\Web\Wallpaper\Windows\img0.jpg"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $DefaultWallpaperPath
[Desktop]::SystemParametersInfo(0x0014, 0, $DefaultWallpaperPath, 0x01 -bor 0x02)


# Set the lockscreen background to the default one
LogMessage "Setting default lockscreen background..."
# Delete the custom login background file (if it exists)
$LoginBackgroundPath = "$env:SystemRoot\System32\oobe\info\backgrounds\backgroundDefault.jpg"
if (Test-Path $LoginBackgroundPath) {
    Remove-Item $LoginBackgroundPath -Force
}
# Disable the OEMBackground registry flag
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background" -Name "OEMBackground" -Value 0 -Type DWord
# Delete the backgrounds folder (if empty)
$BackgroundsFolder = "$env:SystemRoot\System32\oobe\info\backgrounds"
if (Test-Path $BackgroundsFolder -PathType Container) {
    Remove-Item $BackgroundsFolder -Force -Recurse -ErrorAction SilentlyContinue
}

LogMessage "Process finished successfully"
$port.WriteLine('0')
exit 0