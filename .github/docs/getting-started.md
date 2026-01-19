---
title: Getting Started
layout: page
---

# Getting Started

Welcome to Hydra-Cardano-Yaci! This guide will help you quickly set up and run a Cardano devnet with Hydra Head support.

## Quick Start

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
   Edit `scripts/utils/config.sh` as needed.
4. **Generate keys:**
   ```sh
   npm run generate-keys
   ```
5. **Choose your workflow:**
   - [Native (Binary) Workflow](usage.md#native-binary-workflow)
   - [Docker Workflow](usage.md#docker-workflow)
