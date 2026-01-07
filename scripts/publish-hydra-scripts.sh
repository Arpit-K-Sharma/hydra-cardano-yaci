#!/bin/bash

# Publish Hydra scripts and write the resulting txid to the .env file
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

BIN_PATH="$ROOT_DIR/$BIN_DIR"
HYDRA_NODE_PATH="$ROOT_DIR/$HYDRA_NODE"

# Use socket path from .env (set by start-devnet.sh) or fall back to config default
if [ -n "$CARDANO_NODE_SOCKET_PATH" ]; then
    NODE_SOCKET_PATH="$CARDANO_NODE_SOCKET_PATH"
else
    NODE_SOCKET_PATH="$YACI_NODE_SOCKET_PATH"
fi

# Use the first participant from the PARTICIPANTS array
FIRST_PARTICIPANT="${PARTICIPANTS[0]}"
SIGNING_KEY_PATH="$ROOT_DIR/$KEYS_DIR/$PAYMENT_SUBDIR/$FIRST_PARTICIPANT/payment.skey"

# Check hydra-node binary
if [ ! -x "$HYDRA_NODE_PATH" ]; then
    echo "hydra-node binary not found at $HYDRA_NODE_PATH"
    echo "Please run: ./scripts/binary_setup/setup-hydra-node.sh"
    exit 1
fi

# Check node socket
if [ ! -S "$NODE_SOCKET_PATH" ]; then
    echo "node.socket not found at $NODE_SOCKET_PATH"
    echo ""
    echo "Please ensure the devnet is running:"
    echo "  ./scripts/devnet/start-devnet.sh"
    echo ""
    echo "Or check if CARDANO_NODE_SOCKET_PATH is set correctly in .env"
    exit 1
fi

# Check signing key
if [ ! -f "$SIGNING_KEY_PATH" ]; then
    echo "Signing key not found at $SIGNING_KEY_PATH"
    echo "Please run: ./scripts/generate-keys.sh"
    exit 1
fi

echo "============================================"
echo "Publishing Hydra Scripts"
echo "============================================"
echo ""
echo "Using:"
echo "  Hydra Node:     $HYDRA_NODE_PATH"
echo "  Node Socket:    $NODE_SOCKET_PATH"
echo "  Signing Key:    $SIGNING_KEY_PATH"
echo "  Testnet Magic:  $TESTNET_MAGIC"
echo ""

# Publish scripts and capture txid
echo "Publishing scripts (this may take a moment)..."
TXID=$("$HYDRA_NODE_PATH" publish-scripts \
    --testnet-magic $TESTNET_MAGIC \
    --node-socket "$NODE_SOCKET_PATH" \
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

echo ""
echo "============================================"
echo "Hydra Scripts Published Successfully!"
echo "============================================"
echo ""
echo "Transaction ID: $TXID"
echo "Written to: $ENV_FILE"
echo ""
echo "Next steps:"
echo "  - Use this TXID when starting Hydra nodes with --hydra-scripts-tx-id"
