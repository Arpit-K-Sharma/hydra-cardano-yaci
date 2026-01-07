#!/bin/bash

# Script to start the Yaci DevKit devnet and export the node socket path

set -e

# Source config-path.sh to set ROOT_DIR and CONFIG_PATH
source "$(dirname "$0")/../utils/config-path.sh"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi
source "$CONFIG_PATH"

ENV_FILE="$ROOT_DIR/.env"

echo "============================================"
echo "Starting Yaci DevKit Devnet"
echo "============================================"
echo ""

# Check if yaci-devkit is installed locally
YACI_DEVKIT_DIR="$ROOT_DIR/yaci-devkit"
if [ ! -d "$YACI_DEVKIT_DIR/node_modules/@bloxbean/yaci-devkit" ]; then
    echo "Error: Yaci DevKit is not installed locally."
    echo "Please run: ./scripts/devnet/setup-yaci-devkit.sh"
    exit 1
fi

# Check if a devnet is already running by checking the API
if curl -s "http://localhost:$YACI_CLUSTER_API_PORT/local-cluster/api/admin/devnet" > /dev/null 2>&1; then
    echo "⚠ A devnet appears to be already running on port $YACI_CLUSTER_API_PORT"
    echo ""
    
    # Get devnet info
    DEVNET_INFO=$(curl -s "http://localhost:$YACI_CLUSTER_API_PORT/local-cluster/api/admin/devnet" 2>/dev/null || echo "{}")
    
    if [ -n "$DEVNET_INFO" ] && [ "$DEVNET_INFO" != "{}" ]; then
        SOCKET_PATH=$(echo "$DEVNET_INFO" | jq -r '.socketPath // empty' 2>/dev/null)
        if [ -n "$SOCKET_PATH" ]; then
            echo "✓ Devnet is running"
            echo "  Socket path: $SOCKET_PATH"
            
            # Export socket path to .env
            if grep -q "^CARDANO_NODE_SOCKET_PATH=" "$ENV_FILE" 2>/dev/null; then
                sed -i "s|^CARDANO_NODE_SOCKET_PATH=.*|CARDANO_NODE_SOCKET_PATH=$SOCKET_PATH|" "$ENV_FILE"
            else
                echo "CARDANO_NODE_SOCKET_PATH=$SOCKET_PATH" >> "$ENV_FILE"
            fi
            echo "✓ Socket path exported to $ENV_FILE"
            exit 0
        fi
    fi
    
    echo "Do you want to restart the devnet? (y/n)"
    read -r RESTART
    if [ "$RESTART" != "y" ] && [ "$RESTART" != "Y" ]; then
        echo "Exiting without changes."
        exit 0
    fi
fi

echo "Starting devnet with Yaci Store enabled..."
echo ""
echo "This will:"
echo "  - Download Cardano node (if not present)"
echo "  - Start a local devnet with testnet magic $TESTNET_MAGIC"
echo "  - Enable Yaci Store (Blockfrost-compatible APIs)"
echo "  - Enable Ogmios for script evaluation"
echo ""

# Start the devnet in background and capture output
# Using nohup to run in background, but we need to wait for it to be ready
TEMP_LOG=$(mktemp)

echo "Starting Yaci DevKit..."
nohup npx --prefix "$YACI_DEVKIT_DIR" yaci-devkit up --enable-yaci-store > "$TEMP_LOG" 2>&1 &
YACI_PID=$!

echo "Waiting for devnet to start (PID: $YACI_PID)..."

# Wait for the devnet to be ready (check API endpoint)
MAX_WAIT=120
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s "http://localhost:$YACI_CLUSTER_API_PORT/local-cluster/api/admin/devnet" > /dev/null 2>&1; then
        echo ""
        echo "✓ Devnet is ready!"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo ""
    echo "Error: Devnet did not start within $MAX_WAIT seconds."
    echo "Check the log: $TEMP_LOG"
    exit 1
fi

# Get devnet info from API
DEVNET_INFO=$(curl -s "http://localhost:$YACI_CLUSTER_API_PORT/local-cluster/api/admin/devnet" 2>/dev/null || echo "{}")

if [ -n "$DEVNET_INFO" ] && [ "$DEVNET_INFO" != "{}" ]; then
    SOCKET_PATH=$(echo "$DEVNET_INFO" | jq -r '.socketPath // empty' 2>/dev/null)
    NODE_PORT=$(echo "$DEVNET_INFO" | jq -r '.nodePort // empty' 2>/dev/null)
    PROTOCOL_MAGIC=$(echo "$DEVNET_INFO" | jq -r '.protocolMagic // empty' 2>/dev/null)
    
    echo ""
    echo "============================================"
    echo "Devnet Started Successfully!"
    echo "============================================"
    echo ""
    echo "Node Socket:      $SOCKET_PATH"
    echo "Node Port:        $NODE_PORT"
    echo "Protocol Magic:   $PROTOCOL_MAGIC"
    echo ""
    echo "API Endpoints:"
    echo "  Cluster API:    http://localhost:$YACI_CLUSTER_API_PORT"
    echo "  Yaci Store:     http://localhost:$YACI_STORE_PORT/api/v1"
    echo "  Yaci Viewer:    http://localhost:$YACI_VIEWER_PORT"
    echo ""
    
    # Export to .env file
    {
        echo "# Yaci DevKit Configuration (auto-generated)"
        echo "CARDANO_NODE_SOCKET_PATH=$SOCKET_PATH"
        echo "YACI_NODE_PORT=$NODE_PORT"
        echo "YACI_PROTOCOL_MAGIC=$PROTOCOL_MAGIC"
        echo "YACI_CLUSTER_API=http://localhost:$YACI_CLUSTER_API_PORT"
        echo "YACI_STORE_API=http://localhost:$YACI_STORE_PORT/api/v1"
    } > "$ENV_FILE"
    
    echo "✓ Configuration exported to $ENV_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Fund addresses:   ./scripts/fund-addresses.sh"
    echo "  2. Publish scripts:  ./scripts/publish-hydra-scripts.sh"
else
    echo "Warning: Could not retrieve devnet info from API."
    echo "Using default socket path: $YACI_NODE_SOCKET_PATH"
    
    echo "CARDANO_NODE_SOCKET_PATH=$YACI_NODE_SOCKET_PATH" > "$ENV_FILE"
fi

# Cleanup temp log
rm -f "$TEMP_LOG"
