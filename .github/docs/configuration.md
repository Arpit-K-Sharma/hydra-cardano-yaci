---
---

# Configuration

Key configuration files and locations:

- `scripts/utils/config.sh`: Main configuration (participants, versions, ports)
- `config/hydra/protocol-parameters.json`: Hydra protocol parameters
- `.env` (optional): Environment overrides (CARDANO_NODE_SOCKET_PATH, HYDRA_SCRIPTS_TX_ID, etc.)

Sample important variables in `scripts/utils/config.sh`:

- `PARTICIPANTS=("alice" "bob" "carol")`
- `BIN_DIR`, `KEYS_DIR`, `LOGS_DIR`
- Yaci ports: `YACI_CLUSTER_API_PORT`, `YACI_STORE_PORT`, `YACI_OGMIOS_PORT`, `YACI_VIEWER_PORT`