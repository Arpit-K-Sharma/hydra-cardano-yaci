#!/bin/bash
# Start Hydra TUI for a participant index using Docker
set -e

source "$(dirname "$0")/../utils/config-path.sh"
source "$CONFIG_PATH"

PROJECT_ROOT="$ROOT_DIR"
BIN_PATH="$ROOT_DIR/$BIN_DIR"

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

# Relative paths for Docker container (mounted at /workspace)
SIGNING_KEY="$KEYS_DIR/$PAYMENT_SUBDIR/$PARTICIPANT/payment.skey"
NODE_SOCKET="yaci-socket/node.socket"

# Verify files exist on host (use absolute paths for check)
if [ ! -f "$ROOT_DIR/$SIGNING_KEY" ]; then
    echo "Signing key not found for $PARTICIPANT: $ROOT_DIR/$SIGNING_KEY"
    exit 1
fi
if [ ! -S "$ROOT_DIR/$NODE_SOCKET" ]; then
    echo "Node socket not found: $ROOT_DIR/$NODE_SOCKET"
    exit 1
fi

DOCKER_IMAGE="ghcr.io/cardano-scaling/hydra-tui:${HYDRA_VERSION}"

# Run Hydra TUI in Docker

echo "Starting Hydra TUI (Docker) for participant $IDX ($PARTICIPANT) on port $API_PORT..."
echo "Press Ctrl+C to exit"

docker run --rm -it \
  --network host \
  -u "$(id -u):$(id -g)" \
  -v "$ROOT_DIR:/workspace" \
  -w /workspace \
  $DOCKER_IMAGE \
  --connect 127.0.0.1:$API_PORT \
  --testnet-magic $TESTNET_MAGIC \
  --cardano-signing-key "$SIGNING_KEY" \
  --node-socket "$NODE_SOCKET"
