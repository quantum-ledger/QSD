param(
    [string]$QSDRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [switch]$NoOpen,
    [switch]$NoStayOpen,
    [switch]$AllowParallel
)

$ErrorActionPreference = "Stop"

$QSDRoot = (Resolve-Path $QSDRoot).Path
$LocalRoot = Join-Path $QSDRoot "source\.cache\local-validator"
$UrlFile = Join-Path $LocalRoot "local-gui-persist.url"
$OutLog = Join-Path $LocalRoot "local-gui-persist.out.log"
$ErrLog = Join-Path $LocalRoot "local-gui-persist.err.log"

New-Item -ItemType Directory -Force -Path $LocalRoot | Out-Null

$candidates = @(
    "QSD-local-gui-home-server.exe",
    "QSD-local-gui-hive-v2.exe",
    "QSD-local-gui-hive.exe",
    "QSD-local-gui-persist.exe",
    "QSD-local-gui-next.exe",
    "QSD-local-gui-sqlite.exe",
    "QSD-local-gui.exe"
)

$ExePath = $null
foreach ($candidate in $candidates) {
    $path = Join-Path $LocalRoot $candidate
    if (Test-Path -LiteralPath $path) {
        $ExePath = $path
        break
    }
}
if ($null -eq $ExePath) {
    throw "Missing local GUI executable in $LocalRoot"
}

$running = Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -like "QSD-local-gui*"
}
if ($running -and -not $AllowParallel) {
    Write-Host "QSD local GUI is already running."
    exit 0
}

$env:QSD_LOCAL_GUI_URL_FILE = $UrlFile
if ($NoStayOpen) {
    Remove-Item Env:\QSD_LOCAL_GUI_STAY_OPEN -ErrorAction SilentlyContinue
} else {
    $env:QSD_LOCAL_GUI_STAY_OPEN = "1"
}
if ($NoOpen) {
    $env:QSD_LOCAL_GUI_NO_OPEN = "1"
} else {
    Remove-Item Env:\QSD_LOCAL_GUI_NO_OPEN -ErrorAction SilentlyContinue
}

$env:HTTP_PROXY = ""
$env:HTTPS_PROXY = ""
$env:ALL_PROXY = ""
$env:NO_PROXY = "127.0.0.1,localhost,api.QSD.tech"

$process = Start-Process `
    -FilePath $ExePath `
    -WorkingDirectory $QSDRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $OutLog `
    -RedirectStandardError $ErrLog `
    -PassThru

Write-Host "QSD local GUI started pid=$($process.Id)"
