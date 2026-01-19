# Usage Guide

## Native Workflow

```sh
npm run setup:cardano-cli
npm run setup:hydra-node
npm run setup:hydra-tui
npm run start:devnet
npm run hydra:start
npm run tui:start -- 0
```

## Docker Workflow

```sh
npm run setup:docker:cardano-cli
npm run setup:docker:hydra-node
npm run setup:docker:hydra-tui
npm run start:devnet
npm run hydra:start:docker
npm run tui:start:docker -- 0
```

## Critical Notes:

- Do not mix native and Docker binaries/wrappers.
- All addresses are per-participant under `keys/payment/{user}/`.
- Funding must be done via Yaci CLI `topup` command.
- On restart, always ensure devnet, bridge, and node are running and connected.

---

## Advanced

- *Top-up more ADA any time from Yaci terminal.*
- *Expand participant count by modifying config, regenerating keys, and funding wallets again.*
- *Tweak protocol parameters anytime if you're experimenting with chain-level behavior.*

**Need example scripts or debugging? See [Troubleshooting](troubleshooting.md).**