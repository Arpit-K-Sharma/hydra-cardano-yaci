#!/bin/bash

# Publish Hydra scripts using Docker wrapper, ensuring paths are relative for container compatibility
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
    set -a  # Automatically export all variables
    source "$ENV_FILE"
    set +a
fi

# Construct relative paths for Docker
BIN_PATH="$BIN_DIR"
HYDRA_NODE_PATH="$BIN_PATH/hydra-node"

# Use socket path from .env (set by start-devnet.sh) or fall back to config default
if [ -n "$CARDANO_NODE_SOCKET_PATH" ]; then
    NODE_SOCKET_PATH="${CARDANO_NODE_SOCKET_PATH#$ROOT_DIR/}"
else
    NODE_SOCKET_PATH="${YACI_NODE_SOCK_LOCAL_PATH#$ROOT_DIR/}"
fi

# Validate PARTICIPANTS array exists and has elements
if [ -z "${PARTICIPANTS[*]}" ] || [ ${#PARTICIPANTS[@]} -eq 0 ]; then
    echo "ERROR: PARTICIPANTS array is empty or not defined in config"
    echo "Please check your $CONFIG_PATH file"
    exit 1
fi

# Use the first participant from the PARTICIPANTS array
FIRST_PARTICIPANT="${PARTICIPANTS[0]}"
SIGNING_KEY_PATH="$KEYS_DIR/$PAYMENT_SUBDIR/$FIRST_PARTICIPANT/payment.skey"

# Display configuration
cat <<EOF
============================================
Publishing Hydra Scripts (Docker)
============================================
  Hydra Node:     $HYDRA_NODE_PATH
  Node Socket:    $NODE_SOCKET_PATH
  Signing Key:    $SIGNING_KEY_PATH
  Testnet Magic:  $TESTNET_MAGIC
  Participant:    $FIRST_PARTICIPANT
============================================
EOF

# Create a temporary file for full output
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

echo "Publishing scripts (this may take 20-30 seconds)..."
echo ""

set +e  # Don't exit on error, we'll handle it
"$HYDRA_NODE_PATH" publish-scripts \
    --testnet-magic "$TESTNET_MAGIC" \
    --node-socket "$NODE_SOCKET_PATH" \
    --cardano-signing-key "$SIGNING_KEY_PATH" > "$TEMP_OUTPUT" 2>&1
EXIT_CODE=$?
set -e


echo ""

# Check if command succeeded
if [ $EXIT_CODE -ne 0 ]; then
    echo "============================================"
    echo "✗ Failed to publish scripts (Docker)"
    echo "============================================"
    echo ""
    echo "Exit code: $EXIT_CODE"
    exit 1
fi

# Extract all TXIDs (64-char hex) as a comma-separated list
TXID=$(grep -Eo '[a-f0-9]{64}' "$TEMP_OUTPUT" | paste -sd, -)

if [ -z "$TXID" ]; then
    echo "============================================"
    echo "✗ Failed to extract transaction IDs"
    echo "============================================"
    echo ""
    echo "Scripts may have been published, but couldn't parse the txids."
    echo "Full output shown above."
    echo ""
    echo "Please check manually and add to .env:"
    echo "  HYDRA_SCRIPTS_TX_IDS=<your_csv_txids>"
    exit 1
fi


# Write TXIDs to .env file
if grep -q '^HYDRA_SCRIPTS_TX_ID=' "$ROOT_DIR/.env"; then
    sed -i "s/^HYDRA_SCRIPTS_TX_ID=.*/HYDRA_SCRIPTS_TX_ID=$TXID/" "$ROOT_DIR/.env"
else
    echo "HYDRA_SCRIPTS_TX_ID=$TXID" >> "$ROOT_DIR/.env"
fi

echo "============================================"
echo "✓ Published Hydra scripts (Docker)"
echo "============================================"
echo "  TXID: $TXID"
echo "  (Saved to .env as HYDRA_SCRIPTS_TX_IDS)"
echo "============================================"
