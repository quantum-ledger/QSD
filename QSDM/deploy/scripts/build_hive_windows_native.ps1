param(
    [string]$HiveSourceDir = "apps/QSD-hive/QSD-hive-main",
    [string]$QSDSourceDir = "QSD/source",
    [string]$EdgeAgentVersion = "",
    [string]$GoExe = "",
    [switch]$KeepGeneratedResource,
    [switch]$SkipCudaRuntimeSelfTest
)

$ErrorActionPreference = 'Stop'

$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$hive = (Resolve-Path (Join-Path $workspace $HiveSourceDir)).Path
$QSD = (Resolve-Path (Join-Path $workspace $QSDSourceDir)).Path
$native = Join-Path $hive 'native\windows\x64'
$goCache = Join-Path $workspace '.cache\go-build'
$goModCache = Join-Path $workspace '.cache\go-mod'
$officialGo = Join-Path $env:ProgramFiles 'Go\bin\go.exe'
$goOverride = if ($GoExe) { $GoExe } else { $env:QSD_GO_EXE }
$go = if ($goOverride) {
    if (-not (Test-Path -LiteralPath $goOverride -PathType Leaf)) {
        throw "Configured Go executable was not found: $goOverride"
    }
    (Resolve-Path -LiteralPath $goOverride).Path
} elseif (Test-Path -LiteralPath $officialGo) {
    $officialGo
} else {
    (Get-Command go -ErrorAction Stop).Source
}
$requiredGoLine = Get-Content -LiteralPath (Join-Path $QSD 'go.mod') |
    Where-Object { $_ -match '^go\s+(\d+\.\d+\.\d+)\s*$' } |
    Select-Object -First 1
if (-not $requiredGoLine) {
    throw 'QSD go.mod does not contain a MAJOR.MINOR.PATCH go directive.'
}
$requiredGo = [version]([regex]::Match($requiredGoLine, '^go\s+(\d+\.\d+\.\d+)\s*$').Groups[1].Value)
$env:GOTOOLCHAIN = 'auto'
$env:GOMODCACHE = $goModCache
New-Item -ItemType Directory -Force -Path $goModCache | Out-Null
Push-Location $QSD
try {
    $goVersionOutput = (& $go env GOVERSION).Trim()
    if ($LASTEXITCODE -ne 0 -or $goVersionOutput -notmatch '^go(\d+\.\d+\.\d+)$') {
        throw "Unable to select the Go toolchain required by $QSD\go.mod using $go"
    }
    $goVersion = [version]$Matches[1]
}
finally {
    Pop-Location
}
if ($goVersion -lt $requiredGo) {
    throw "Go $requiredGo or newer is required; automatic toolchain selection returned $goVersion from $go. Set QSD_GO_EXE to a current Go SDK."
}
Write-Host "Using $goVersionOutput through $go"
$version = (Get-Content -Raw (Join-Path $hive 'release\app\package.json') | ConvertFrom-Json).version
if ($version -notmatch '^(\d+\.\d+\.\d+)(?:-[0-9A-Za-z.-]+)?$') {
    throw 'Hive version must use SemVer MAJOR.MINOR.PATCH with an optional prerelease suffix.'
}
$binaryVersion = $Matches[1]
$edgeVersionFile = Join-Path $workspace 'apps\QSD-edge-agent\VERSION'
if (-not $EdgeAgentVersion) {
    if (-not (Test-Path -LiteralPath $edgeVersionFile)) {
        throw "QSD edge-agent version file not found at $edgeVersionFile"
    }
    $EdgeAgentVersion = (Get-Content -Raw -LiteralPath $edgeVersionFile).Trim()
}
if ($EdgeAgentVersion -notmatch '^\d+\.\d+\.\d+$') {
    throw 'EdgeAgentVersion must use MAJOR.MINOR.PATCH format.'
}
$gitSha = (& git -C $QSD rev-parse --short HEAD).Trim()
$buildDate = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$buildInfo = "-s -w -X github.com/blackbeardONE/QSD/pkg/buildinfo.Version=hive-v$version -X github.com/blackbeardONE/QSD/pkg/buildinfo.GitSHA=$gitSha -X github.com/blackbeardONE/QSD/pkg/buildinfo.BuildDate=$buildDate"
$controlIcon = Join-Path $hive 'assets\icon.ico'
$versionResourceBuilder = Join-Path $workspace 'QSD\scripts\build_windows_version_resource.ps1'
$cudaSolverBuilder = Join-Path $workspace 'QSD\scripts\build_miner_cuda.ps1'
$edgeGpuBuilder = Join-Path $workspace 'QSD\scripts\build_edge_gpu_helper.ps1'
$cudaSolver = Join-Path $native 'QSD-miner-cuda-solver.exe'
$edgeGpuHelper = Join-Path $native 'QSD-edge-gpu-helper.exe'

$resourceSpecs = @(
    @{
        Path = Join-Path $QSD 'cmd\QSDcli\rsrc_windows_amd64.syso'
        FileVersion = $binaryVersion
        Description = 'QSD Command Line Interface'
        InternalName = 'QSDcli'
        OriginalFilename = 'QSDcli.exe'
    },
    @{
        Path = Join-Path $QSD 'cmd\QSDminer-console\rsrc_windows_amd64.syso'
        FileVersion = $binaryVersion
        Description = 'QSD Console Miner'
        InternalName = 'QSDminer-console'
        OriginalFilename = 'QSDminer-console.exe'
    },
    @{
        Path = Join-Path $QSD 'cmd\QSD-hive-wallet-host\rsrc_windows_amd64.syso'
        FileVersion = $binaryVersion
        Description = 'QSD Hive Wallet Browser Bridge'
        InternalName = 'QSD-hive-wallet-host'
        OriginalFilename = 'QSD-hive-wallet-host.exe'
    },
    @{
        Path = Join-Path $QSD 'cmd\QSD-edge-agent\rsrc_windows_amd64.syso'
        FileVersion = $EdgeAgentVersion
        Description = 'QSD Edge Agent'
        InternalName = 'QSD-edge-agent'
        OriginalFilename = 'QSD-edge-agent.exe'
    },
    @{
        Path = Join-Path $QSD 'cmd\QSD-edge-control\rsrc_windows_amd64.syso'
        FileVersion = $EdgeAgentVersion
        Description = 'QSD Edge Control'
        InternalName = 'QSD-edge-control'
        OriginalFilename = 'QSD-edge-control.exe'
    }
)

New-Item -ItemType Directory -Force -Path $native | Out-Null
New-Item -ItemType Directory -Force -Path $goCache | Out-Null

foreach ($resource in $resourceSpecs) {
    & $versionResourceBuilder `
        -ProductVersion $binaryVersion `
        -FileVersion $resource.FileVersion `
        -ProductName 'QSD Hive' `
        -FileDescription $resource.Description `
        -InternalName $resource.InternalName `
        -OriginalFilename $resource.OriginalFilename `
        -IconPath $controlIcon `
        -OutputPath $resource.Path
}
Push-Location $QSD
try {
    $env:GOCACHE = $goCache
    $env:CGO_ENABLED = '0'
    $env:GOOS = 'windows'
    $env:GOARCH = 'amd64'

    & $go build -trimpath -tags dilithium_circl -ldflags '-s -w' -o (Join-Path $native 'QSDcli.exe') ./cmd/QSDcli
    if ($LASTEXITCODE -ne 0) { throw "QSDcli build failed with exit code $LASTEXITCODE" }

    & $go build -trimpath -ldflags '-s -w -H=windowsgui' -o (Join-Path $native 'QSD-hive-wallet-host.exe') ./cmd/QSD-hive-wallet-host
    if ($LASTEXITCODE -ne 0) { throw "QSD-hive-wallet-host build failed with exit code $LASTEXITCODE" }

    & $go build -trimpath -ldflags $buildInfo -o (Join-Path $native 'QSDminer-console.exe') ./cmd/QSDminer-console
    if ($LASTEXITCODE -ne 0) { throw "QSDminer-console build failed with exit code $LASTEXITCODE" }

    & $go build -trimpath -ldflags "-s -w -X main.version=$EdgeAgentVersion" -o (Join-Path $native 'QSD-edge-agent.exe') ./cmd/QSD-edge-agent
    if ($LASTEXITCODE -ne 0) { throw "QSD-edge-agent build failed with exit code $LASTEXITCODE" }

    & $go build -trimpath -ldflags "-s -w -H=windowsgui -X main.version=$EdgeAgentVersion" -o (Join-Path $native 'QSD-edge-control.exe') ./cmd/QSD-edge-control
    if ($LASTEXITCODE -ne 0) { throw "QSD-edge-control build failed with exit code $LASTEXITCODE" }
}
finally {
    $resourceCleanupFailed = @()
    if (-not $KeepGeneratedResource) {
        foreach ($resource in $resourceSpecs) {
            for ($attempt = 0; $attempt -lt 30 -and (Test-Path -LiteralPath $resource.Path); $attempt++) {
                Remove-Item -LiteralPath $resource.Path -Force -ErrorAction SilentlyContinue
                if (Test-Path -LiteralPath $resource.Path) {
                    Start-Sleep -Milliseconds ([Math]::Min(($attempt + 1) * 100, 1000))
                }
            }
            if (Test-Path -LiteralPath $resource.Path) {
                $resourceCleanupFailed += $resource.Path
            }
        }
    }
    Pop-Location
    if ($resourceCleanupFailed.Count -gt 0) {
        Write-Warning "Windows retained generated version resources after cleanup retries. They are ignored by git and will be overwritten by the next build: $($resourceCleanupFailed -join ', ')"
    }
}

$cudaArguments = @{
    Version = $binaryVersion
    SkipRuntimeSelfTest = [bool]$SkipCudaRuntimeSelfTest
}
& $cudaSolverBuilder @cudaArguments
if ($LASTEXITCODE -ne 0) { throw 'QSD CUDA miner solver build failed.' }

& $edgeGpuBuilder @cudaArguments
if ($LASTEXITCODE -ne 0) { throw 'QSD Edge GPU Helper build failed.' }

& (Join-Path $native 'QSDminer-console.exe') --version
if ($LASTEXITCODE -ne 0) { throw 'Packaged QSDminer-console failed its version probe.' }

if (-not $SkipCudaRuntimeSelfTest) {
    & $cudaSolver --self-test
    if ($LASTEXITCODE -ne 0) { throw 'Packaged QSD CUDA miner solver failed its self-test.' }

    $gpuResult = & $edgeGpuHelper --seed ('00' * 32) --units 1024 --json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or -not $gpuResult.gpu_name) {
        throw 'Packaged QSD Edge GPU Helper failed its runtime self-test.'
    }
}

& (Join-Path $native 'QSD-edge-agent.exe') --version
if ($LASTEXITCODE -ne 0) { throw 'Packaged QSD-edge-agent failed its version probe.' }

& (Join-Path $native 'QSD-edge-control.exe') --version
if ($LASTEXITCODE -ne 0) { throw 'Packaged QSD-edge-control failed its version probe.' }

Write-Host "Hive Windows native tools are ready in $native"
