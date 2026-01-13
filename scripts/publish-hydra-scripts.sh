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
    set -a  # Automatically export all variables
    source "$ENV_FILE"
    set +a
fi

# Construct paths
BIN_PATH="$ROOT_DIR/$BIN_DIR"
HYDRA_NODE_PATH="$ROOT_DIR/$HYDRA_NODE"

# Use socket path from .env (set by start-devnet.sh) or fall back to config default
if [ -n "$CARDANO_NODE_SOCKET_PATH" ]; then
    NODE_SOCKET_PATH="$CARDANO_NODE_SOCKET_PATH"
else
    NODE_SOCKET_PATH="$YACI_NODE_SOCK_LOCAL_PATH"
fi

# Validate PARTICIPANTS array exists and has elements
if [ -z "${PARTICIPANTS[*]}" ] || [ ${#PARTICIPANTS[@]} -eq 0 ]; then
    echo "ERROR: PARTICIPANTS array is empty or not defined in config"
    echo "Please check your $CONFIG_PATH file"
    exit 1
fi

# Use the first participant from the PARTICIPANTS array
FIRST_PARTICIPANT="${PARTICIPANTS[0]}"
SIGNING_KEY_PATH="$ROOT_DIR/$KEYS_DIR/$PAYMENT_SUBDIR/$FIRST_PARTICIPANT/payment.skey"

echo "============================================"
echo "Pre-flight Checks"
echo "============================================"
echo ""

# Check hydra-node binary
if [ ! -x "$HYDRA_NODE_PATH" ]; then
    echo "✗ hydra-node binary not found at $HYDRA_NODE_PATH"
    echo ""
    echo "Please run: npm run setup:hydra-node"
    exit 1
fi
echo "✓ Hydra node binary found"

# Check node socket
if [ ! -S "$NODE_SOCKET_PATH" ]; then
    echo "✗ node.socket not found at $NODE_SOCKET_PATH"
    echo ""
    echo "Please ensure the devnet is running:"
    echo "  npm run start:devnet"
    echo ""
    echo "Or run the socket bridge:"
    echo "  npm run bridge:node-socket"
    exit 1
fi
echo "✓ Node socket found"

# Check signing key
if [ ! -f "$SIGNING_KEY_PATH" ]; then
    echo "✗ Signing key not found at $SIGNING_KEY_PATH"
    echo ""
    echo "Please run: npm run generate-keys"
    exit 1
fi
echo "✓ Signing key found"

# Verify the address has funds
echo ""
echo "Checking if address has funds..."
PAYMENT_ADDR_FILE="$ROOT_DIR/$KEYS_DIR/$PAYMENT_SUBDIR/$FIRST_PARTICIPANT/payment.addr"
if [ -f "$PAYMENT_ADDR_FILE" ]; then
    PAYMENT_ADDR=$(cat "$PAYMENT_ADDR_FILE")
    echo "  Address: $PAYMENT_ADDR"
    
    # Try to query UTxOs (will fail if not funded)
    if command -v cardano-cli &> /dev/null; then
        echo "  Querying UTxOs..."
        if cardano-cli query utxo \
            --address "$PAYMENT_ADDR" \
            --socket-path "$NODE_SOCKET_PATH" \
            --testnet-magic "$TESTNET_MAGIC" 2>/dev/null | grep -q "lovelace"; then
            echo "✓ Address has funds"
        else
            echo "✗ Address has no funds"
            echo ""
            echo "Please fund the address first:"
            echo "  Address: $PAYMENT_ADDR"
            echo ""
            echo "In Yaci DevKit, run:"
            echo "  devnet:default> topup $PAYMENT_ADDR 1000"
            exit 1
        fi
    else
        echo "  (cardano-cli not found, skipping balance check)"
    fi
else
    echo "  (payment.addr file not found, skipping balance check)"
fi

echo ""
echo "============================================"
echo "Publishing Hydra Scripts"
echo "============================================"
echo ""
echo "Configuration:"
echo "  Hydra Node:     $HYDRA_NODE_PATH"
echo "  Node Socket:    $NODE_SOCKET_PATH"
echo "  Signing Key:    $SIGNING_KEY_PATH"
echo "  Testnet Magic:  $TESTNET_MAGIC"
echo "  Participant:    $FIRST_PARTICIPANT"
echo ""

# Create a temporary file for full output
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

# Publish scripts and capture output
echo "Publishing scripts (this may take 20-30 seconds)..."
echo ""

set +e  # Don't exit on error, we'll handle it
"$HYDRA_NODE_PATH" publish-scripts \
    --testnet-magic "$TESTNET_MAGIC" \
    --node-socket "$NODE_SOCKET_PATH" \
    --cardano-signing-key "$SIGNING_KEY_PATH" > "$TEMP_OUTPUT" 2>&1
EXIT_CODE=$?
set -e

# Show the output
cat "$TEMP_OUTPUT"
echo ""

# Check if command succeeded
if [ $EXIT_CODE -ne 0 ]; then
    echo "============================================"
    echo "✗ Failed to publish scripts"
    echo "============================================"
    echo ""
    echo "Exit code: $EXIT_CODE"
    echo ""
    echo "Common issues:"
    echo "  1. Insufficient funds - ensure address is funded (need ~5 ADA)"
    echo "  2. Node not synced - wait for devnet to fully start"
    echo "  3. Wrong testnet magic - check TESTNET_MAGIC in config"
    echo "  4. Socket connection issues - verify bridge is running"
    exit 1
fi



# Extract all TXIDs (64-char hex) as a comma-separated list
TXIDS=$(grep -Eo '[a-f0-9]{64}' "$TEMP_OUTPUT" | paste -sd, -)

if [ -z "$TXIDS" ]; then
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

# Validate TXIDS format (at least one 64 hex character, comma-separated)
if ! echo "$TXIDS" | grep -qE '^[a-f0-9]{64}(,[a-f0-9]{64})*$'; then
    echo "============================================"
    echo "✗ Invalid transaction IDs format"
    echo "============================================"
    echo ""
    echo "Extracted TXIDS: $TXIDS"
    echo "Expected: CSV of 64 hexadecimal characters"
    exit 1
fi

# Add or update HYDRA_SCRIPTS_TX_IDS (all TXIDs)
if grep -q "^HYDRA_SCRIPTS_TX_ID=" "$ENV_FILE" 2>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^HYDRA_SCRIPTS_TX_ID=.*|HYDRA_SCRIPTS_TX_ID=$TXIDS|" "$ENV_FILE"
    else
        sed -i "s|^HYDRA_SCRIPTS_TX_ID=.*|HYDRA_SCRIPTS_TX_ID=$TXIDS|" "$ENV_FILE"
    fi
    echo "Updated HYDRA_SCRIPTS_TX_ID in $ENV_FILE"
else
    echo "HYDRA_SCRIPTS_TX_ID=$TXIDS" >> "$ENV_FILE"
    echo "Added HYDRA_SCRIPTS_TX_ID to $ENV_FILE"
fi

echo ""
echo "============================================"
echo "✓ Hydra Scripts Published Successfully!"
echo "============================================"
echo ""
echo "Transaction ID: $TXID"
echo "Written to: $ENV_FILE"
echo ""
echo "Next steps:"
echo "  1. Wait for transaction to be confirmed (a few seconds)"
echo "  2. Start Hydra nodes: npm run start:hydra-node"
echo ""
echo "The nodes will automatically use this TXID from .env"