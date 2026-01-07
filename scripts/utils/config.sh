#!/bin/bash

# =============================================================================
# Configuration file for Hydra-Cardano-Yaci setup
# Edit this file to customize your setup - all scripts will use these values
# =============================================================================

# -----------------------------------------------------------------------------
# DIRECTORY PATHS (relative to project root)
# -----------------------------------------------------------------------------

# Binary folder for CLI tools
BIN_DIR="bin"

# Key storage base directory
KEYS_DIR="keys"

# Payment key subdirectory (under KEYS_DIR)
PAYMENT_SUBDIR="payment"

# Hydra key subdirectory (under KEYS_DIR) - for future use
HYDRA_SUBDIR="hydra"

# -----------------------------------------------------------------------------
# PARTICIPANTS
# -----------------------------------------------------------------------------

# List of participants (edit to add/remove names)
PARTICIPANTS=("alice" "bob" "carol")

# Number of participants (auto-calculated from array)
NUM_PARTICIPANTS=${#PARTICIPANTS[@]}

# -----------------------------------------------------------------------------
# NETWORK CONFIGURATION
# -----------------------------------------------------------------------------

# Testnet magic (change for different networks)
# 42 = local devnet, 1 = preprod, 2 = preview, 764824073 = mainnet
TESTNET_MAGIC=42

# -----------------------------------------------------------------------------
# CARDANO CLI CONFIGURATION
# -----------------------------------------------------------------------------

# Cardano CLI version (update when new versions are released)
CARDANO_VERSION="8.1.2"

# Cardano CLI binary name
CARDANO_CLI_BINARY="cardano-cli"

# Cardano CLI full path (relative to project root)
CARDANO_CLI="${BIN_DIR}/${CARDANO_CLI_BINARY}"

# Cardano CLI download URL template
CARDANO_CLI_DOWNLOAD_URL="https://github.com/input-output-hk/cardano-node/releases/download/${CARDANO_VERSION}/cardano-node-${CARDANO_VERSION}-linux.tar.gz"

# -----------------------------------------------------------------------------
# HYDRA CONFIGURATION
# -----------------------------------------------------------------------------

# Hydra version (latest stable as of 2026)
HYDRA_VERSION="1.2.0"

# Hydra binary name
HYDRA_NODE_BINARY="hydra-node"

# Hydra node full path (relative to project root)
HYDRA_NODE="${BIN_DIR}/${HYDRA_NODE_BINARY}"

# Hydra download URL (ZIP format for x86_64 Linux)
HYDRA_DOWNLOAD_URL="https://github.com/cardano-scaling/hydra/releases/download/${HYDRA_VERSION}/hydra-x86_linux-${HYDRA_VERSION}.zip"

# -----------------------------------------------------------------------------
# YACI DEVKIT API ENDPOINTS
# -----------------------------------------------------------------------------

# Yaci DevKit API endpoints
YACI_TOPUP_API="http://localhost:10000/local-cluster/api/addresses/topup"
YACI_UTXOS_API="http://localhost:10000/local-cluster/api/addresses"

# =============================================================================
# END OF CONFIGURATION
# =============================================================================
