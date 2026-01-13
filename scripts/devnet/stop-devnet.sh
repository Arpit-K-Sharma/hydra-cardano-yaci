#!/bin/bash
# Stop Yaci Devnet and clean up related resources

set -e

# Load config
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../utils/config-path.sh"
source "$CONFIG_PATH"


# Stop Yaci CLI container if running
if docker ps --format '{{.Names}}' | grep -q "^$YACI_CONTAINER_NAME$"; then
  echo "Stopping Yaci CLI container: $YACI_CONTAINER_NAME..."
  docker stop "$YACI_CONTAINER_NAME"
else
  echo "Yaci CLI container $YACI_CONTAINER_NAME is not running."
fi

# Stop Yaci Viewer container if running
VIEWER_CONTAINER="node1-yaci-viewer-1"
if docker ps --format '{{.Names}}' | grep -q "^$VIEWER_CONTAINER$"; then
  echo "Stopping Yaci Viewer container: $VIEWER_CONTAINER..."
  docker stop "$VIEWER_CONTAINER"
else
  echo "Yaci Viewer container $VIEWER_CONTAINER is not running."
fi

# Optionally stop any other devnet-related containers here

# Clean up socat bridge
if [ -f "$ROOT_DIR/yaci-socket/stop-bridge.sh" ]; then
  bash "$ROOT_DIR/yaci-socket/stop-bridge.sh"
fi

# Optionally clean up node.sock
if [ -S "$ROOT_DIR/yaci-socket/node.sock" ]; then
  rm -f "$ROOT_DIR/yaci-socket/node.sock"
fi

echo "Devnet stopped and cleaned up."
