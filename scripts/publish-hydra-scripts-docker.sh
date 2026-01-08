#!/bin/bash

# Publish Hydra scripts using Docker hydra-node, using the first participant from config
set -e

# Source config-path.sh to set ROOT_DIR and CONFIG_PATH
source "$(dirname "$0")/utils/config-path.sh"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi
source "$CONFIG_PATH"

# Source .env file if it exists (for CARDANO_NODE_SOCKET_PATH)
ENV_FILE="$ROOT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

HYDRA_NODES_DIR="$ROOT_DIR/hydra-nodes"
CONFIG_DIR="$ROOT_DIR/config"

# Use socket path from .env (set by devnet) or fall back to config default
if [ -n "$CARDANO_NODE_SOCKET_PATH" ]; then
    NODE_SOCKET_PATH="$CARDANO_NODE_SOCKET_PATH"
else
    NODE_SOCKET_PATH="$YACI_NODE_SOCKET_PATH"
fi

# Use the first participant from the PARTICIPANTS array in config
FIRST_PARTICIPANT="${PARTICIPANTS[0]}"
SIGNING_KEY_PATH="/hydra-nodes/$FIRST_PARTICIPANT/keys/cardano.sk" # Path inside container
NODE_SOCKET_PATH_DOCKER="/hydra-nodes/node/node.sock" # Path inside container

# Check node socket
if [ ! -S "$NODE_SOCKET_PATH" ]; then
    echo "node.socket not found at $NODE_SOCKET_PATH"
    echo ""
    echo "Please ensure the devnet is running:"
    echo "  yaci-devkit up --enable-yaci-store"
    echo ""
    echo "Or check if CARDANO_NODE_SOCKET_PATH is set correctly in .env (auto-set by devnet startup)"
    exit 1
fi

# Check signing key
if [ ! -f "$HYDRA_NODES_DIR/$FIRST_PARTICIPANT/keys/cardano.sk" ]; then
    echo "Signing key not found at $HYDRA_NODES_DIR/$FIRST_PARTICIPANT/keys/cardano.sk"
    echo "Please run: npm run generate-keys"
    exit 1
fi

# Run hydra-node publish-scripts in Docker
TXID=$(docker run --rm \
  --platform linux/arm64 \
  -v "$HYDRA_NODES_DIR:/hydra-nodes" \
  -v "$CONFIG_DIR:/config" \
  --network host \
  ghcr.io/cardano-scaling/hydra-node:$HYDRA_VERSION \
  publish-scripts \
    --testnet-magic 42 \
    --node-socket "$NODE_SOCKET_PATH" \

# Publish scripts and capture txid
echo "Publishing scripts (this may take a moment)..."
TXID=$(docker run --rm \
  --platform linux/arm64 \
  -v "$HYDRA_NODES_DIR:/hydra-nodes" \
  -v "$CONFIG_DIR:/config" \
  --network host \
  ghcr.io/cardano-scaling/hydra-node:$HYDRA_VERSION \
  publish-scripts \
    --testnet-magic $TESTNET_MAGIC \
    --node-socket "$NODE_SOCKET_PATH_DOCKER" \
    --cardano-signing-key "$SIGNING_KEY_PATH" 2>&1 | tail -1 | tr -d '\n')

if [ -z "$TXID" ]; then
    echo "Failed to publish scripts or retrieve txid."
    exit 1
fi

# Append or update HYDRA_SCRIPTS_TX_ID in .env
if grep -q "^HYDRA_SCRIPTS_TX_ID=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^HYDRA_SCRIPTS_TX_ID=.*|HYDRA_SCRIPTS_TX_ID=$TXID|" "$ENV_FILE"
else
    echo "HYDRA_SCRIPTS_TX_ID=$TXID" >> "$ENV_FILE"
fi

    --cardano-signing-key "$SIGNING_KEY_PATH" 2>/dev/null | tail -1 | tr -d '\n')

if [ -z "$TXID" ]; then
    echo "Failed to publish scripts or retrieve txid."
    exit 1
fi

# Append or update HYDRA_SCRIPTS_TX_ID in .env
if grep -q "^HYDRA_SCRIPTS_TX_ID=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^HYDRA_SCRIPTS_TX_ID=.*|HYDRA_SCRIPTS_TX_ID=$TXID|" "$ENV_FILE"
else
    echo "HYDRA_SCRIPTS_TX_ID=$TXID" >> "$ENV_FILE"
fi

echo ""
echo "============================================"
echo "Hydra Scripts Published Successfully (Docker)!"
echo "============================================"
echo ""
echo "Transaction ID: $TXID"
echo "Written to: $ENV_FILE"
echo ""
echo "Next steps:"
echo "  - Use this TXID when starting Hydra nodes with --hydra-scripts-tx-id"
