# Apps (non-core)

Everything here is **optional** relative to the **`QSD/`** node (the QSD ledger). The node builds and runs without these folders.

| App | Role |
|-----|------|
| **`QSD-hive/`** | Desktop client (Windows/Linux): CELL wallets, Task Studio, NVIDIA mining, Mother Hive edge pools, Sky Fang linking. Public downloads at [QSD.tech/download.html](https://QSD.tech/download.html). |
| **`QSD-hive-wallet-extension/`** | Chrome/Edge provider that connects HTTPS sites to the active Hive-held wallet through the authenticated native messaging bridge. It holds no private keys. |
| **`QSD-edge-agent/`** | Edge Agent, Relay, and Edge Control utilities for pooled CPU/GPU/RAM work. |
| **`QSD-tray-monitor/`** | Windows tray health monitor for the local home validator stack. |
| **`QSD-nvidia-ngc/`** | Optional Docker NGC GPU attestation sidecar; pairs with `QSD_NGC_INGEST_SECRET` on the node. |
| **`QSD-landing/`** | Legacy marketing stub. **Production site is `QSD/deploy/landing/`** (served at QSD.tech). |

To promote an app to its own repository later, copy one folder and add a client SDK from `QSD/source/sdk/`.
