# Collect diagnostics of a Windows VM and upload them to the openQA job
# Usage: collect_logs.ps1 -UploadUrl <autoinst_url('/uploadlog/win-diag.zip')>
param(
    [Parameter(Mandatory = $true)][string]$UploadUrl,
    [string]$Name = 'win-diag.zip'
)

$ErrorActionPreference = 'Continue'
$dir = Join-Path $env:TEMP 'win-diag'
$zip = Join-Path $env:TEMP $Name
Remove-Item $dir, $zip -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $dir -Force | Out-Null

# wsl.exe prints UTF-16
[Console]::OutputEncoding = [System.Text.Encoding]::Unicode
& {
    '== wsl --version'
    wsl --version
    '== enabled optional features'
    Get-WindowsOptionalFeature -Online | Where-Object State -eq 'Enabled' | Select-Object -ExpandProperty FeatureName
    '== related processes'
    Get-Process | Where-Object ProcessName -match 'wsl|msiexec|TrustedInstaller|powershell' | Format-Table Id, ProcessName, StartTime -AutoSize | Out-String
    '== network'
    ipconfig /all
    Test-NetConnection -ComputerName github.com -Port 443 | Out-String
    '== application events'
    Get-WinEvent -LogName Application -MaxEvents 80 | Format-List TimeCreated, ProviderName, Id, Message | Out-String
} *>&1 | Out-File -FilePath (Join-Path $dir 'info.txt') -Encoding utf8

Copy-Item 'C:\Windows\Panther' -Destination (Join-Path $dir 'Panther') -Recurse -ErrorAction SilentlyContinue
Copy-Item 'C:\Windows\System32\Sysprep\Panther' -Destination (Join-Path $dir 'SysprepPanther') -Recurse -ErrorAction SilentlyContinue
Compress-Archive -Path "$dir\*" -DestinationPath $zip -Force

curl.exe --silent --show-error --max-time 300 --form "upload=@$zip" --form "upname=$Name" $UploadUrl
exit $LASTEXITCODE
