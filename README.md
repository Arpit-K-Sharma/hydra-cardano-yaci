# Hydra-Cardano-Yaci

Automation and tooling for Cardano Hydra/Yaci devnet workflows. This project enables you to quickly set up a Cardano devnet and operate Hydra Heads for scalable, off-chain Cardano transactions, supporting both Docker and native (binary) workflows.

---

## Features
- One-command setup for Cardano devnet and Hydra Head
- Supports both Docker and non-Docker (native binary) environments
- Multi-participant support (default: alice, bob, carol)
- Automated key generation and protocol configuration
- Modular scripts for setup, start, stop, and monitoring
- Easily switch between Docker and native workflows

---

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Native (Binary) Workflow](#a-native-binary-workflow)
  - [Docker Workflow](#b-docker-workflow)
- [Troubleshooting & Known Issues](#troubleshooting--known-issues)
- [Documentation](#documentation)
- [License](#license)

---

## Overview
Hydra-Cardano-Yaci is ideal for developers, testers, and researchers who want to experiment with Cardano Hydra in a local, reproducible environment. It automates the setup and management of a Cardano devnet and Hydra Heads, using [Yaci DevKit](https://github.com/txpipe/yaci-devkit) and official Cardano/Hydra binaries or Docker images.

---

## Prerequisites
- Linux (recommended)
- [Node.js](https://nodejs.org/) >= 20.8.0
- [Docker](https://www.docker.com/) (for Docker-based workflow)
- curl, unzip, git

Install on Ubuntu/Debian:
```sh
sudo apt update
sudo apt install -y curl unzip git
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```
Log out and back in after adding yourself to the docker group.

---

## Installation
1. **Clone the repository:**
   ```sh
   git clone https://github.com/your-username/hydra-cardano-yaci.git
   cd hydra-cardano-yaci
   ```
2. **Install prerequisites:**
   ```sh
   npm run install:prerequisites
   ```
3. **Configure participants and network:**
   Edit `scripts/utils/config.sh` to set participant names, network magic, and versions as needed.
4. **Generate keys:**
   ```sh
   npm run generate-keys
   ```

---

## Usage

### A. Native (Binary) Workflow
1. Set up Cardano CLI and Hydra Node binaries:
   ```sh
   npm run setup:cardano-cli
   npm run setup:hydra-node
   ```
2. Start the devnet:
   ```sh
   npm run start:devnet
   ```
3. Start Hydra nodes:
   ```sh
   npm run hydra:start
   ```
4. (Optional) Start Hydra TUI for a participant:
   ```sh
   npm run tui:start -- <participant_index>
   # Example: npm run tui:start -- 0
   ```
5. Stop Hydra nodes:
   ```sh
   npm run hydra:stop
   ```
6. Stop the devnet:
   ```sh
   npm run stop:devnet
   ```

### B. Docker Workflow
1. Set up Cardano CLI and Hydra Node Docker wrappers:
   ```sh
   npm run setup:docker:cardano-cli
   npm run setup:docker:hydra-node
   ```
2. Start the devnet:
   ```sh
   npm run start:devnet
   ```
3. Start Hydra nodes (Docker):
   ```sh
   npm run hydra:start:docker
   ```
4. (Optional) Start Hydra TUI (Docker) for a participant:
   ```sh
   npm run tui:start:docker -- <participant_index>
   # Example: npm run tui:start:docker -- 0
   ```
5. Stop Hydra nodes (Docker):
   ```sh
   npm run hydra:stop:docker
   ```
6. Stop the devnet:
   ```sh
   npm run stop:devnet
   ```

---

## Configuration
- `scripts/utils/config.sh`: Main configuration (participants, versions, ports)
- `config/hydra/protocol-parameters.json`: Hydra protocol parameters

---

## Troubleshooting & Known Issues

### PlutusV3 ValidationTagMismatch on Close (Conway/Protocol 10.x)
**Issue:**
When using Hydra 1.2.0 with Cardano node 10.1.4 (Conway era, Protocol 10.2) on a Yaci DevKit devnet, closing the Hydra head fails with a PlutusV3 ValidationTagMismatch error. The head opens successfully (Init → Commit → CollectCom → Open), but any attempt to close the head (via TUI or API) is rejected by the cardano-node with a script validation error.

**Workarounds & Recommendations:**
- Consider downgrading cardano-node to a version using Protocol 9.x if possible.
- Monitor for Hydra releases with explicit support for Protocol 10.x/Conway.
- Ensure protocol parameters in `config/hydra/protocol-parameters.json` match those exported from your running cardano-node.
- For updates and discussion, see the [Hydra GitHub issues](https://github.com/input-output-hk/hydra/issues) and [Yaci DevKit documentation](https://github.com/txpipe/yaci-devkit).

---

## Documentation
- See the [docs/](.github/docs/) folder for detailed guides
- View Full Docs (https://Arpit-K-Sharma.github.io/hydra-cardano-yaci/)  



---

## License
MIT
