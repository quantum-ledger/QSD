# Example: set env vars so docker-compose validators POST proof bundles to a local QSD API.
# 1) Start the node with the same secret:  $env:QSD_NGC_INGEST_SECRET = "<random-32-byte-secret>"
# 2) From this directory:  .\scripts\wire-QSD.ps1 -ApiPort 8080 -Secret "<random-32-byte-secret>"
#    Optional node binding (must match node's QSD_NVIDIA_LOCK_EXPECTED_NODE_ID):
#    .\scripts\wire-QSD.ps1 -ApiPort 8080 -Secret "..." -ProofNodeId "validator-1"
# 3)  docker compose up --build

param(
    [int]$ApiPort = 8080,
    [string]$Secret = "",
    [string]$ProofNodeId = "",
    [string]$ProofHMACSecret = ""
)

if ([string]::IsNullOrWhiteSpace($Secret)) {
    Write-Host "Usage: .\scripts\wire-QSD.ps1 -ApiPort 8080 -Secret (same as node) [-ProofNodeId id] [-ProofHMACSecret s]" -ForegroundColor Yellow
    exit 1
}

# Export under BOTH the preferred QSD_* name and the legacy
# QSDPLUS_* alias so docker-compose containers running mixed sidecar
# versions all see the value (the post-rebrand sidecar reads QSD_*
# first, the deprecation-window sidecar reads QSDPLUS_*; setting
# both is cheap and removes a foot-gun). The QSDplus -> QSD rebrand
# previously collapsed the QSDPLUS_* lines into duplicates of the
# QSD_* lines (incl. an inert self-assignment of QSD_NGC_REPORT_URL),
# silently breaking any container still on the legacy name.
$env:QSD_NGC_INGEST_SECRET = $Secret
$env:QSD_NGC_REPORT_URL = "http://host.docker.internal:$ApiPort/api/v1/monitoring/ngc-proof"
$env:QSDPLUS_NGC_INGEST_SECRET = $Secret
$env:QSDPLUS_NGC_REPORT_URL = $env:QSD_NGC_REPORT_URL
if (![string]::IsNullOrWhiteSpace($ProofNodeId)) {
    $env:QSD_NGC_PROOF_NODE_ID = $ProofNodeId
    $env:QSDPLUS_NGC_PROOF_NODE_ID = $ProofNodeId
}
if (![string]::IsNullOrWhiteSpace($ProofHMACSecret)) {
    $env:QSD_NGC_PROOF_HMAC_SECRET = $ProofHMACSecret
    $env:QSDPLUS_NGC_PROOF_HMAC_SECRET = $ProofHMACSecret
}
Write-Host "QSD_NGC_REPORT_URL=$($env:QSD_NGC_REPORT_URL)" -ForegroundColor Green
Write-Host "QSD_NGC_INGEST_SECRET=(set)" -ForegroundColor Green
if (![string]::IsNullOrWhiteSpace($ProofNodeId)) {
    Write-Host "QSD_NGC_PROOF_NODE_ID=$ProofNodeId" -ForegroundColor Green
}
if (![string]::IsNullOrWhiteSpace($ProofHMACSecret)) {
    Write-Host "QSD_NGC_PROOF_HMAC_SECRET=(set)" -ForegroundColor Green
}
Write-Host "Run: docker compose up --build" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ops checklist (better NGC utilization):" -ForegroundColor DarkGray
Write-Host "  - Node: set QSD_NGC_INGEST_SECRET to the same value (enables POST .../ngc-proof)." -ForegroundColor DarkGray
Write-Host "  - NVIDIA-lock: align QSD_NGC_PROOF_NODE_ID with node QSD_NVIDIA_LOCK_EXPECTED_NODE_ID when binding." -ForegroundColor DarkGray
Write-Host "  - If node uses ingest nonce: set QSD_NGC_FETCH_CHALLENGE=true on sidecar; optional QSD_NGC_CHALLENGE_JITTER_MAX_SEC for many validators." -ForegroundColor DarkGray
Write-Host "  - GPU proofs: use Dockerfile.ngc / validator-gpu so gpu_fingerprint.available=true in bundles." -ForegroundColor DarkGray
Write-Host "  - Metrics: QSD_ngc_proof_ingest_* on /api/metrics/prometheus (dashboard + alerts)." -ForegroundColor DarkGray
