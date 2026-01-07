#!/bin/bash

# Script to generate payment and Hydra keys for participants defined in config.sh

set -e

ROOT_DIR="$(dirname $(dirname $(realpath $0)))"
CONFIG_PATH="$ROOT_DIR/scripts/utils/config.sh"

# Source config file
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi
source "$CONFIG_PATH"
# Resolve paths
CARDANO_CLI_PATH="$ROOT_DIR/$CARDANO_CLI"
HYDRA_NODE_PATH="$ROOT_DIR/$HYDRA_NODE"

# Check if cardano-cli exists
if [ ! -f "$CARDANO_CLI_PATH" ]; then
    echo "cardano-cli not found at $CARDANO_CLI_PATH"
    echo "Please run setup-cardano-cli.sh or setup-cardano-cli-docker.sh first."
    exit 1
fi

# Check if hydra-node exists
if [ ! -f "$HYDRA_NODE_PATH" ]; then
    echo "hydra-node not found at $HYDRA_NODE_PATH"
    echo "Please run setup-hydra-node.sh or setup-hydra-node-docker.sh first."
    exit 1
fi

echo "=========================================="
echo "Generating keys for: ${PARTICIPANTS[*]}"
echo "=========================================="
echo ""

# Change to root directory for relative paths (important for Docker)
cd "$ROOT_DIR"

for NAME in "${PARTICIPANTS[@]}"; do
    echo "=== Generating keys for $NAME ==="
    
    # Create key directories using relative paths
    KEY_DIR="$KEYS_DIR/$PAYMENT_SUBDIR/$NAME"
    HYDRA_KEY_DIR="$KEYS_DIR/$HYDRA_SUBDIR/$NAME"
    
    echo "  [Payment Keys]"
    # Check if payment keys already exist
    if [ -f "$KEY_DIR/payment.skey" ] && [ -f "$KEY_DIR/payment.vkey" ]; then
        echo "    Payment keys already exist. Skipping generation."
    else
        # Generate payment key pair (using relative paths for Docker compatibility)
        "$CARDANO_CLI_PATH" address key-gen \
            --verification-key-file "$KEY_DIR/payment.vkey" \
            --signing-key-file "$KEY_DIR/payment.skey"
        echo "    ✓ Generated payment keys"
    fi
    
    # Generate payment address (using testnet magic from config)
    if [ -f "$KEY_DIR/payment.addr" ]; then
        echo "    Payment address already exists. Skipping."
    else
        "$CARDANO_CLI_PATH" address build \
            --payment-verification-key-file "$KEY_DIR/payment.vkey" \
            --testnet-magic "$TESTNET_MAGIC" \
            --out-file "$KEY_DIR/payment.addr"
        echo "    ✓ Generated payment address"
    fi
    
    # Display the address
    echo "    Address: $(cat $KEY_DIR/payment.addr)"
    
    echo ""
    echo "  [Hydra Keys]"
    # Check if Hydra keys already exist
    if [ -f "$HYDRA_KEY_DIR/hydra.sk" ] && [ -f "$HYDRA_KEY_DIR/hydra.vk" ]; then
        echo "    Hydra keys already exist. Skipping generation."
    else
        # Generate Hydra key pair using hydra-node gen-hydra-key
        "$HYDRA_NODE_PATH" gen-hydra-key \
            --output-file "$HYDRA_KEY_DIR/hydra"
        echo "    ✓ Generated hydra keys"
    fi
    
    echo ""
done

echo "=========================================="
echo "Summary:"
echo "  Payment keys: $ROOT_DIR/$KEYS_DIR/$PAYMENT_SUBDIR/"
echo "  Hydra keys:   $ROOT_DIR/$KEYS_DIR/$HYDRA_SUBDIR/"
echo "=========================================="
echo ""
echo "Generated addresses:"
for NAME in "${PARTICIPANTS[@]}"; do
    ADDR=$(cat "$KEYS_DIR/$PAYMENT_SUBDIR/$NAME/payment.addr")
    echo "  $NAME: $ADDR"
done
echo ""