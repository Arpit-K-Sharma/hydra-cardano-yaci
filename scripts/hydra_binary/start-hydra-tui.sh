#!/bin/bash
# Start Hydra TUI for a participant index directly in the current terminal
set -e

source "$(dirname "$0")/../utils/config-path.sh"
source "$CONFIG_PATH"

BIN_PATH="$ROOT_DIR/$BIN_DIR"
HYDRA_TUI_PATH="$BIN_PATH/hydra-tui"

if [ ! -x "$HYDRA_TUI_PATH" ]; then
    echo "hydra-tui binary not found at $HYDRA_TUI_PATH"
    echo "Please run: npm run setup:hydra-tui"
    exit 1
fi

IDX="$1"
if [ -z "$IDX" ]; then
    echo "Usage: $0 <participant_index>"
    echo "Available indices: 0 to $((NUM_PARTICIPANTS-1))"
    exit 1
fi

if ! [[ "$IDX" =~ ^[0-9]+$ ]] || [ "$IDX" -ge "$NUM_PARTICIPANTS" ]; then
    echo "Invalid participant index: $IDX"
    echo "Available indices: 0 to $((NUM_PARTICIPANTS-1))"
    exit 1
fi

PARTICIPANT="${PARTICIPANTS[$IDX]}"
API_PORT=$((4000 + IDX))
SIGNING_KEY="$ROOT_DIR/$KEYS_DIR/$PAYMENT_SUBDIR/$PARTICIPANT/payment.skey"
NODE_SOCKET="$YACI_NODE_SOCK_LOCAL_PATH"

if [ ! -f "$SIGNING_KEY" ]; then
    echo "Signing key not found for $PARTICIPANT: $SIGNING_KEY"
    exit 1
fi
if [ ! -S "$NODE_SOCKET" ]; then
    echo "Node socket not found: $NODE_SOCKET"
    exit 1
fi

echo "Starting Hydra TUI for participant $IDX ($PARTICIPANT) on port $API_PORT..."
echo "Press Ctrl+C to exit"

exec "$HYDRA_TUI_PATH" --connect 127.0.0.1:$API_PORT --testnet-magic $TESTNET_MAGIC --cardano-signing-key "$SIGNING_KEY" --node-socket "$NODE_SOCKET"
