# API Reference

All core scripts are invoked as npm scripts or shell wraps.

| Script/NPM cmd               | Description                              |
|------------------------------|------------------------------------------|
| install:prerequisites        | Installs/checks all dependencies         |
| setup:directories            | Folders for bin, keys, logs, etc.        |
| setup:cardano-cli            | Download/install CLI binary (native)     |
| setup:hydra-node             | Download/install HYDRA node (native)     |
| setup:docker:cardano-cli     | Generate Docker Cardano CLI wrapper      |
| setup:docker:hydra-node      | Docker HYDRA node wrapper                |
| generate-keys                | Makes keys for all in PARTICIPANTS       |
| publish-scripts              | Publishes scripts, creates .env (native) |
| publish-scripts:docker       | Publishes scripts, creates .env (Docker) |
| hydra:start                  | Start all hydra nodes (native)           |
| hydra:start:docker           | Start all hydra nodes (Docker)           |
| hydra:stop                   | Stop Hydra nodes (native)                |
| hydra:stop:docker            | Stop Hydra (Docker)                      |
| tui:start -- <index>         | Run TUI for participant (native)         |
| tui:start:docker -- <index>  | Run TUI for participant (Docker)         |
| bridge:node-socket           | Bridge `node.socket` for access          |
| ...                          | See `scripts/` and `bin/` for more!      |

Wrapper scripts in `bin/` launch Docker or binaries as configured.

---

**Directories**
- `keys/payment/` / `keys/hydra/`: Per-participant keys and addresses
- `logs/`: Node, hydra, TUI logs
- `config/hydra/`: Protocol param templates

---

See inline comments in `scripts/utils/config.sh` for environment/config option details.