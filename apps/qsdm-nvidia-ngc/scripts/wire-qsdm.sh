#!/usr/bin/env sh
# Set env vars so docker-compose validators POST proof bundles to a local QSD API.
# Usage: ./scripts/wire-QSD.sh <api_port> <ngc_ingest_secret> [proof_node_id] [proof_hmac_secret]
# Example: ./scripts/wire-QSD.sh 8080 "<random-32-byte-secret>" "validator-1" "<separate-random-32-byte-hmac-secret>"
# Then: docker compose up --build  (from apps/QSD-nvidia-ngc)

API_PORT="${1:-}"
SECRET="${2:-}"
PROOF_NODE="${3:-}"
HMAC_SECRET="${4:-}"

if [ -z "$SECRET" ] || [ -z "$API_PORT" ]; then
	echo "Usage: $0 <api_port> <ngc_ingest_secret> [proof_node_id_optional] [proof_hmac_secret_optional]" >&2
	exit 1
fi

# Export under BOTH the preferred QSD_* name and the legacy
# QSDPLUS_* alias so docker-compose containers running mixed sidecar
# versions all see the value (the post-rebrand sidecar reads QSD_*
# first, the deprecation-window sidecar reads QSDPLUS_*; setting
# both is cheap and removes a foot-gun). The QSDplus -> QSD rebrand
# previously collapsed the QSDPLUS_* lines into duplicates of the
# QSD_* lines (incl. an inert self-assignment of QSD_NGC_REPORT_URL),
# silently breaking any container still on the legacy name.
export QSD_NGC_INGEST_SECRET="$SECRET"
export QSD_NGC_REPORT_URL="http://host.docker.internal:${API_PORT}/api/v1/monitoring/ngc-proof"
export QSDPLUS_NGC_INGEST_SECRET="$SECRET"
export QSDPLUS_NGC_REPORT_URL="$QSD_NGC_REPORT_URL"

if [ -n "$PROOF_NODE" ]; then
	export QSD_NGC_PROOF_NODE_ID="$PROOF_NODE"
	export QSDPLUS_NGC_PROOF_NODE_ID="$PROOF_NODE"
fi
if [ -n "$HMAC_SECRET" ]; then
	export QSD_NGC_PROOF_HMAC_SECRET="$HMAC_SECRET"
	export QSDPLUS_NGC_PROOF_HMAC_SECRET="$HMAC_SECRET"
fi

echo "QSD_NGC_REPORT_URL=$QSD_NGC_REPORT_URL"
echo "QSD_NGC_INGEST_SECRET=(set)"
if [ -n "$PROOF_NODE" ]; then
	echo "QSD_NGC_PROOF_NODE_ID=$PROOF_NODE"
fi
if [ -n "$HMAC_SECRET" ]; then
	echo "QSD_NGC_PROOF_HMAC_SECRET=(set)"
fi
echo "Run: docker compose up --build"
echo ""
echo "Ops checklist (better NGC utilization):"
echo "  - Node: set QSD_NGC_INGEST_SECRET to the same value (enables POST .../ngc-proof)."
echo "  - NVIDIA-lock: align QSD_NGC_PROOF_NODE_ID with node QSD_NVIDIA_LOCK_EXPECTED_NODE_ID when binding."
echo "  - If node uses ingest nonce: set QSD_NGC_FETCH_CHALLENGE=true on sidecar; optional QSD_NGC_CHALLENGE_JITTER_MAX_SEC for many validators."
echo "  - GPU proofs: use Dockerfile.ngc / validator-gpu so gpu_fingerprint.available=true in bundles."
echo "  - Metrics: QSD_ngc_proof_ingest_* on /api/metrics/prometheus (dashboard + alerts)."
