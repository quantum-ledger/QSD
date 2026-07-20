param(
    [string]$ExtensionId = 'habkkkednignfkoffhpbjahcjbikkahh',
    [string]$HostPath = ""
)

$ErrorActionPreference = 'Stop'
$extensionIdPattern = '^[a-p]{32}$'
if ($ExtensionId -notmatch $extensionIdPattern) {
    throw 'ExtensionId must be the 32-character Chrome or Edge extension ID.'
}
if (-not $HostPath) {
    $HostPath = Join-Path $PSScriptRoot '..\..\native\QSD-hive-wallet-host.exe'
}
$HostPath = (Resolve-Path -LiteralPath $HostPath).Path
$installDir = Join-Path $env:LOCALAPPDATA 'QSD\HiveWalletBridge'
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
$manifestPath = Join-Path $installDir 'tech.QSD.hive_wallet.json'
$manifest = [ordered]@{
    name = 'tech.QSD.hive_wallet'
    description = 'QSD Hive Wallet native bridge'
    path = $HostPath
    type = 'stdio'
    allowed_origins = @("chrome-extension://$ExtensionId/")
}
$manifestJson = $manifest | ConvertTo-Json -Depth 4
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestPath, $manifestJson, $utf8WithoutBom)

$registryRoots = @(
    'HKCU:\Software\Google\Chrome\NativeMessagingHosts\tech.QSD.hive_wallet',
    'HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\tech.QSD.hive_wallet'
)
foreach ($registryPath in $registryRoots) {
    New-Item -Force -Path $registryPath | Out-Null
    Set-Item -LiteralPath $registryPath -Value $manifestPath
}
Write-Host "QSD Wallet bridge registered for extension $ExtensionId"
