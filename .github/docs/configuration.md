# Configuration Guide

All configuration for participants, binaries, ports, and protocol versions is centralized in `scripts/utils/config.sh`.

---

## Key Options

| Option            | Example Value         | Purpose                                  |
|-------------------|----------------------|------------------------------------------|
| PARTICIPANTS      | ("alice" "bob" ...)  | Main users; add/remove as needed         |
| TESTNET_MAGIC     | 42                   | Cardano testnet magic (42 = Yaci, 1=preprod)|
| CARDANO_VERSION   | 8.1.2                | Cardano CLI version                      |
| HYDRA_VERSION     | 1.2.0                | Hydra node version                       |
| BIN_DIR           | "bin"                | Where wrappers/binaries live             |
| KEYS_DIR          | "keys"               | Where all key/addr files go              |
| ...               | ...                  | See config.sh and comments for full list |

All ports, Docker options and protocol params are settable in this file.
Config is well-documented inline.

---

### Participants

Change `PARTICIPANTS`, re-run `npm run generate-keys`, re-topup, and you're done.

---

### Protocol Parameters

`config/hydra/protocol-parameters.json` holds the script/chain details.  
If you get version/compatibility errors, update using `cardano-cli`'s `query protocol-parameters` for your node.

---

All changes require a new keygen + setup run.