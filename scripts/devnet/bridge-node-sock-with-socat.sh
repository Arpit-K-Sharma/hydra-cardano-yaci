#!/bin/bash
# Script to copy node.sock from Yaci Docker container and bridge it locally
# Creates yaci-socket folder and converts node.sock to node.socket

set -e

# Source config-path.sh to get CONFIG_PATH
source "$(dirname "$0")/../utils/config-path.sh"
source "$CONFIG_PATH"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
DOCKER_SOCKET_PATH="/clusters/nodes/default/node/node.sock"
LOCAL_FOLDER="yaci-socket"
LOCAL_SOCKET_NAME="node.socket"
LOCAL_SOCKET_PATH="$(pwd)/${LOCAL_FOLDER}/${LOCAL_SOCKET_NAME}"
SOCAT_PORT="3333"

# Step 0: Verify container is running
log_info "Checking if container $YACI_CONTAINER_NAME is running..."
if ! docker ps --format '{{.Names}}' | grep -q "^${YACI_CONTAINER_NAME}$"; then
    log_error "Container $YACI_CONTAINER_NAME is not running"
    log_info "Available containers:"
    docker ps --format 'table {{.Names}}\t{{.Status}}'
    exit 1
fi

log_info "✓ Container $YACI_CONTAINER_NAME is running"

# Step 1: Create yaci-socket folder
log_info "Creating local socket directory: $LOCAL_FOLDER"
mkdir -p "$LOCAL_FOLDER"

# Step 2: Copy node.sock from Docker container
log_info "Copying node.sock from Docker container..."
log_info "Source: $YACI_CONTAINER_NAME:$DOCKER_SOCKET_PATH"
log_info "Destination: ${LOCAL_FOLDER}/node.sock"

if docker cp "${YACI_CONTAINER_NAME}:${DOCKER_SOCKET_PATH}" "${LOCAL_FOLDER}/node.sock" 2>/dev/null; then
    log_info "✓ Successfully copied node.sock from container"
else
    log_warn "Direct copy failed (expected for active sockets)"
    log_info "Proceeding with TCP bridge method instead..."
fi

# Step 3: Convert node.sock to node.socket (rename)
if [ -f "${LOCAL_FOLDER}/node.sock" ]; then
    log_info "Renaming node.sock to node.socket..."
    mv "${LOCAL_FOLDER}/node.sock" "$LOCAL_SOCKET_PATH"
    log_info "✓ Renamed to node.socket"
fi

# Step 4: Clean up any existing socat processes
log_info "Cleaning up old socat processes..."
pkill -9 -f "socat.*${LOCAL_SOCKET_NAME}" 2>/dev/null || true
rm -f "$LOCAL_SOCKET_PATH" 2>/dev/null || true
sleep 1

# Step 5: Get container IP for TCP connectivity
CONTAINER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$YACI_CONTAINER_NAME")
log_info "Container IP: $CONTAINER_IP"
log_info "Target port: $SOCAT_PORT"

# Step 6: Start socat bridge
log_info "Starting socat bridge..."
log_info "Command: socat UNIX-LISTEN:${LOCAL_SOCKET_PATH},fork,reuseaddr TCP:localhost:${SOCAT_PORT}"

socat UNIX-LISTEN:"${LOCAL_SOCKET_PATH}",fork,reuseaddr TCP:localhost:${SOCAT_PORT} &
SOCAT_PID=$!

# Step 7: Wait and verify socket creation
sleep 2
if [ ! -S "$LOCAL_SOCKET_PATH" ]; then
    log_error "Failed to create socket at $LOCAL_SOCKET_PATH"
    log_info "Checking if socat process is running..."
    if ! ps -p $SOCAT_PID > /dev/null 2>&1; then
        log_error "Socat process died. Check connectivity to localhost:${SOCAT_PORT}"
    fi
    exit 1
fi

# Step 8: Set permissions
chmod 777 "$LOCAL_SOCKET_PATH"
log_info "✓ Socket created with proper permissions"

# Step 9: Test the connection
log_info "Testing socket connection..."
if timeout 3 socat - UNIX-CONNECT:"$LOCAL_SOCKET_PATH" < /dev/null &>/dev/null; then
    log_info "✓ Socket connection test PASSED"
else
    log_warn "Socket test inconclusive, but bridge is running"
fi

# Step 10: Save PID for cleanup
echo $SOCAT_PID > "${LOCAL_FOLDER}/socat.pid"

# Print success message
cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Node socket bridge is running successfully${NC}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configuration:

  Container:        $YACI_CONTAINER_NAME
  Docker Path:      $DOCKER_SOCKET_PATH
  Local Folder:     $LOCAL_FOLDER
  Local Socket:     $LOCAL_SOCKET_PATH
  TCP Target:       localhost:${SOCAT_PORT}
  Socat PID:        $SOCAT_PID

Environment Variable:

  export CARDANO_NODE_SOCKET_PATH="${LOCAL_SOCKET_PATH}"

Management Commands:$

  Stop bridge:      pkill -f "socat.*${LOCAL_SOCKET_NAME}"
                    or kill $SOCAT_PID
  
  Check status:     ps aux | grep socat
  
  View socket:      ls -la ${LOCAL_FOLDER}/
  
  Remove folder:    rm -rf ${LOCAL_FOLDER}

${YELLOW}Next Steps:${NC}

  1. Export the socket path:
     export CARDANO_NODE_SOCKET_PATH="${LOCAL_SOCKET_PATH}"${NC}
  
  2. Run your Hydra scripts:
     npm run publish-scripts${NC}

${YELLOW}Keep this terminal open to maintain the bridge${NC}

EOF

# Keep the script running
log_info "Press Ctrl+C to stop the bridge"
wait $SOCAT_PID