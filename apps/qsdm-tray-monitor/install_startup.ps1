param(
    [string]$ExePath = (Join-Path $PSScriptRoot "dist\QSD-tray-monitor.exe"),
    [string]$QSDRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\QSD")).Path
)

$ErrorActionPreference = "Stop"

$ExePath = (Resolve-Path $ExePath).Path
$QSDRoot = (Resolve-Path $QSDRoot).Path
$startup = [Environment]::GetFolderPath("Startup")
if ([string]::IsNullOrWhiteSpace($startup)) {
    throw "Could not locate the current user's Startup folder"
}

$launcher = Join-Path $startup "QSD-Tray-Monitor.vbs"
$command = "`"$ExePath`" --root `"$QSDRoot`""
$vbsCommand = $command.Replace('"', '""')
Set-Content -LiteralPath $launcher -Encoding ASCII -Value @"
Set shell = CreateObject("WScript.Shell")
shell.Run "$vbsCommand", 0, False
"@

Write-Host "Installed QSD Tray Monitor Startup launcher: $launcher"
