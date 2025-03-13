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
# Detect OS Version
$OSVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
$IsWindows11 = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion -match "2[0-9]H2"

# Set Default Wallpaper Path
if ($IsWindows11) {
    $DefaultWallpaper = "$env:Windir\Web\Wallpaper\Windows\img0.jpg"  # Windows 11 default
} else {
    $DefaultWallpaper = "$env:Windir\Web\Wallpaper\Windows\img0.jpg"  # Windows 10 default
}

# Apply Default Wallpaper
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $DefaultWallpaper

# Refresh Desktop
Add-Type @"
using System.Runtime.InteropServices;
public class Desktop {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Desktop]::SystemParametersInfo(0x0014, 0, $DefaultWallpaper, 0x01 -bor 0x02)

Write-Host "Desktop wallpaper reset to default for Windows $(if ($IsWindows11) {'11'} else {'10'})!" -ForegroundColor Green


# Set the lockscreen background to the default one
LogMessage "Setting default lockscreen background..."
# Run this as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires admin rights. Restart PowerShell as Administrator!" -ForegroundColor Red
    exit
}

# Remove custom login background
$LoginBackgroundPath = "$env:SystemRoot\System32\oobe\info\backgrounds\backgroundDefault.jpg"
if (Test-Path $LoginBackgroundPath) {
    Remove-Item $LoginBackgroundPath -Force
    Write-Host "Custom login screen image removed." -ForegroundColor Green
}

# Disable OEMBackground
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background"
Set-ItemProperty -Path $RegPath -Name "OEMBackground" -Value 0 -Type DWord -ErrorAction SilentlyContinue

Write-Host "Login screen reset to default. Reboot to see changes." -ForegroundColor Green

LogMessage "Process finished successfully"
$port.WriteLine('0')
exit 0