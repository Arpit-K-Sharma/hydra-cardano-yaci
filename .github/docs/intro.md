## Important Notice: Protocol Compatibility Issue

**Known Issue:**
Hydra 1.2.0 with Cardano node 10.1.4 (Conway/Protocol 10.x) may fail to close the Hydra head due to PlutusV3 ValidationTagMismatch errors. See the Troubleshooting section in the setup guide for details and workarounds.

# Introduction

Hydra-Cardano-Yaci is a toolkit for automating and managing Cardano devnets with Hydra Head support. It enables developers to:

- Quickly spin up a Cardano devnet using [Yaci DevKit](https://github.com/txpipe/yaci-devkit)
- Set up and operate Hydra Heads for scalable, off-chain Cardano transactions
- Use either Docker-based or native (binary) workflows
- Automate key generation, node setup, and protocol configuration

**Key Features:**
- One-command setup for devnet and Hydra Head
- Support for multiple participants (default: alice, bob, carol)
- Easy switching between Docker and non-Docker environments
- Modular scripts for setup, start, stop, and monitoring

This project is ideal for developers, testers, and researchers who want to experiment with Cardano Hydra in a local, reproducible environment.
