---
---

# API Reference

This project primarily interacts with the following endpoints provided by Yaci DevKit and Hydra nodes:

- Yaci DevKit Admin API: `http://localhost:<YACI_CLUSTER_API_PORT>/local-cluster/api/...`
- Yaci Store (Blockfrost-compatible): `http://localhost:<YACI_STORE_PORT>/api/v1`
- Hydra node WebSocket API: `ws://localhost:<hydra-api-port>` (ports vary per participant)

See the source scripts in `scripts/` for exact CLI and HTTP usage patterns.