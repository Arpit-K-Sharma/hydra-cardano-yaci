#!/bin/bash
# Stop all socat bridge processes and clean up socket files for devnet

YACI_CONTAINER_NAME="node1-yaci-cli-1"
YACI_NODE_SOCK_LOCAL_PATH="/home/z_shadow/hydra-cardano-yaci/yaci-socket/node.sock"
LOCAL_SOCK_DIR="$(dirname "$YACI_NODE_SOCK_LOCAL_PATH")"

# Kill socat on host
pkill -9 -f "socat.*$YACI_NODE_SOCK_LOCAL_PATH" 2>/dev/null || true
rm -f "$YACI_NODE_SOCK_LOCAL_PATH" 2>/dev/null || true
rm -f "$LOCAL_SOCK_DIR/socat.pid" 2>/dev/null || true

# Kill socat in container
if docker ps --format '{{.Names}}' | grep -q "^${YACI_CONTAINER_NAME}$"; then
  docker exec "$YACI_CONTAINER_NAME" pkill -9 socat 2>/dev/null || true
fi

echo "Bridge stopped and cleaned up."
