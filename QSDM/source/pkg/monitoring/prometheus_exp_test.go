package monitoring

import (
	"strings"
	"testing"
)

func TestPrometheusExposition_containsNvidiaSeries(t *testing.T) {
	s := PrometheusExposition()
	for _, sub := range []string{
		"QSD_nvidia_lock_http_blocks_total",
		"QSD_nvidia_lock_p2p_rejects_total",
		"QSD_ngc_challenge_issued_total",
		"QSD_ngc_proof_ingest_accepted_total",
		"QSD_ngc_proof_ingest_rejected_total",
		"# TYPE QSD_ngc_ingest_nonce_pool_size gauge",
		"QSD_submesh_p2p_reject_route_total",
		"QSD_submesh_api_wallet_reject_route_total",
		"QSD_mesh_companion_publish_total",
		"QSD_p2p_wallet_ingress_dedupe_skip_total",
		"QSD_hot_reload_apply_success_total",
		"QSD_hot_reload_dry_run_total",
		"QSD_hot_reload_last_dry_run_changed",
	} {
		if !strings.Contains(s, sub) {
			t.Fatalf("exposition missing %q", sub)
		}
	}
}
