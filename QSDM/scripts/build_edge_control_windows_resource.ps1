param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$IconPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$builder = Join-Path $PSScriptRoot 'build_windows_version_resource.ps1'
& $builder `
    -ProductVersion $Version `
    -FileVersion $Version `
    -ProductName 'QSD Hive' `
    -FileDescription 'QSD Edge Control' `
    -InternalName 'QSD-edge-control' `
    -OriginalFilename 'QSD-edge-control.exe' `
    -IconPath $IconPath `
    -OutputPath $OutputPath
