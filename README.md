# QSD

**QSD** (Quantum-Secure Dynamic ledger) is a post-quantum-secure
ledger with a two-tier node model — CPU-only validators run the PoE + BFT
consensus, and miners run an additive, Mesh3D-tied Proof-of-Work that
mints the native coin, **Cell (CELL)**. Consumers use **QSD Hive**
(Windows/Linux) for wallets, signed tasks, NVIDIA mining, and Mother Hive
edge pools. Operators use Core plus optional home gateway, tray monitor,
and attestation sidecars.

Transaction signatures use **ML-DSA-87** (NIST FIPS 204) — the
standardised post-quantum replacement for classical Ed25519 / Ed448 —
so transactions signed today remain unforgeable against cryptographically
relevant quantum adversaries tomorrow.

desktop client (CELL wallets, tasks, mining, edge). |
| [**`apps/QSD-edge-agent/`**](apps/QSD-edge-agent/) | Edge Agent / Relay / Edge Control utilities for Mother Hive pools. |
| [**`apps/QSD-tray-monitor/`**](apps/QSD-tray-monitor/) | Windows tray health monitor for the local home stack. |
| [**`apps/QSD-nvidia-ngc/`**](apps/QSD-nvidia-ngc/) | Optional NVIDIA NGC GPU attestation sidecar — opt-in, per-operator API policy, **not** a consensus rule. See [`NVIDIA_LOCK_CONSENSUS_SCOPE.md`](QSD/docs/docs/NVIDIA_LOCK_CONSENSUS_SCOPE.md). |
| [**`apps/QSD-landing/`**](apps/QSD-landing/) | Legacy marketing stub. Prefer `QSD/deploy/landing/` for the live site. |

## Start here

- **Feature summary (current capabilities):** [`QSDM/docs/docs/Feature Summary.md`](QSDM/docs/docs/Feature%20Summary.md)
- **Operator wiki (end-to-end):** [`QSDM/docs/docs/OPERATOR_GUIDE.md`](QSDM/docs/docs/OPERATOR_GUIDE.md) ⭐ start here if you are new
- **Run a validator (CPU-only):** [`QSDM/docs/docs/VALIDATOR_QUICKSTART.md`](QSDM/docs/docs/VALIDATOR_QUICKSTART.md)
- **Run a miner (Hive or console; CUDA solver bundled):** [`QSDM/docs/docs/MINER_QUICKSTART.md`](QSDM/docs/docs/MINER_QUICKSTART.md)
- **Home gateway (narrow public mining/status):** [`QSDM/docs/docs/HOME_GATEWAY.md`](QSDM/docs/docs/HOME_GATEWAY.md)
- **Edge pool / Mother Hive:** [`QSDM/docs/docs/EDGE_POOL.md`](QSDM/docs/docs/EDGE_POOL.md)
- **Run the NGC attestation sidecar:** [`apps/QSDM-nvidia-ngc/QUICKSTART.md`](apps/QSDM-nvidia-ngc/QUICKSTART.md)
- **API reference:** [`QSDM/docs/docs/API_REFERENCE.md`](QSDM/docs/docs/API_REFERENCE.md) and [`openapi.yaml`](QSDM/docs/docs/openapi.yaml)
- **Protocol specs:** [`MINING_PROTOCOL_V2.md`](QSDM/docs/docs/MINING_PROTOCOL_V2.md), [`NODE_ROLES.md`](QSDM/docs/docs/NODE_ROLES.md), [`CELL_TOKENOMICS.md`](QSDM/docs/docs/CELL_TOKENOMICS.md)
- **Code signing policy:** [`CODE_SIGNING_POLICY.md`](CODE_SIGNING_POLICY.md)
- **Privacy policy:** [`PRIVACY.md`](PRIVACY.md)
- **Security reporting:** [`SECURITY.md`](SECURITY.md)

> **New?** The operator wiki answers the three questions every new node
> operator asks: *do I need an NVIDIA GPU, do I need a paid NGC plan, and
> do I have to sync to your VPS?* Spoiler: **no, no, and no — but NVIDIA
> is the first-class mining path today

## License

[MIT](LICENSE) © 2024-2026 Joedel Lopez Dalioan (Blackbeard).

The ledger node and sidecars are permissively licensed. Vendored
third-party dependencies under `QSD/source/wasmer-go-patched/` retain
their own licences (see [`QSD/source/wasmer-go-patched/LICENSE`](QSD/source/wasmer-go-patched/LICENSE)).

## Windows signing

QSD is preparing an application for free open-source signing through
SignPath Foundation. The application is pending, and no artifact may be
represented as SignPath-signed until it passes the repository's release gates.
See the [code signing policy](CODE_SIGNING_POLICY.md) for roles, provenance,
approval, verification, and incident-response requirements.
