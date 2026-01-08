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
# Using nohup to run in background, we'll poll for readiness
DEVNET_LOG="$ROOT_DIR/$LOGS_DIR/devnet.log"

# Ensure logs directory exists
mkdir -p "$ROOT_DIR/$LOGS_DIR"

echo "Starting Yaci DevKit..."
# Kill any existing yaci-devkit process
pkill -f "yaci-devkit up" 2>/dev/null || true
sleep 1

nohup npx --prefix "$YACI_DEVKIT_DIR" yaci-devkit up --enable-yaci-store > "$DEVNET_LOG" 2>&1 &
YACI_PID=$!

echo "Yaci DevKit started with PID: $YACI_PID"
echo "Log file: $DEVNET_LOG"
echo ""

# Wait for the devnet to be ready by polling the API
MAX_WAIT=180
WAITED=0
DEVNET_READY=false

echo "Waiting for devnet services to be ready (max $MAX_WAIT seconds)..."
echo "Note: This may take a while as Yaci Store initializes..."

while [ $WAITED -lt $MAX_WAIT ]; do
    # Check if the cluster API is responding
    CLUSTER_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$YACI_CLUSTER_API_PORT/local-cluster/api/admin/devnet" 2>&1)
    
    if [ "$CLUSTER_RESPONSE" = "200" ]; then
        # Check if Yaci Store is responding (any HTTP response means it's up)
        STORE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$YACI_STORE_PORT/" 2>&1)
        
        # Accept 200-599 (any real HTTP response code - service is up)
        if [ "$STORE_RESPONSE" -ge 200 ] && [ "$STORE_RESPONSE" -lt 600 ] 2>/dev/null; then
            echo ""
            echo "✓ Devnet and Yaci Store are ready!"
            DEVNET_READY=true
            break
        fi
    fi
    
    sleep 2
    WAITED=$((WAITED + 2))
    
    if [ $((WAITED % 10)) -eq 0 ]; then
        echo "  Waited $WAITED seconds..."
    else
        echo -n "."
    fi
done

echo ""
if [ "$DEVNET_READY" = false ]; then
    echo "⚠ Warning: Devnet may not be fully initialized, but proceeding..."
    echo "Check the log if issues persist:"
    echo "  tail -f $DEVNET_LOG"
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
    echo "  Ogmios:         ws://localhost:$YACI_OGMIOS_PORT"
    echo ""
    
    # Start Yaci Viewer if installed locally
    if [ -d "$YACI_DEVKIT_DIR/node_modules/@bloxbean/yaci-viewer" ]; then
        # Check if viewer is already running
        if ! curl -s "http://localhost:$YACI_VIEWER_PORT" > /dev/null 2>&1; then
            echo "Starting Yaci Viewer..."
            nohup npx --prefix "$YACI_DEVKIT_DIR" yaci-viewer > /dev/null 2>&1 &
            sleep 2
            if curl -s "http://localhost:$YACI_VIEWER_PORT" > /dev/null 2>&1; then
                echo "✓ Yaci Viewer started at http://localhost:$YACI_VIEWER_PORT"
            else
                echo "⚠ Yaci Viewer may take a moment to start at http://localhost:$YACI_VIEWER_PORT"
            fi
        else
            echo "✓ Yaci Viewer already running at http://localhost:$YACI_VIEWER_PORT"
        fi
    else
        echo "Note: Yaci Viewer not installed. Run: npm run setup:devkit"
    fi
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
    echo "Devnet is running with the following configuration:"
    echo "  PID: $YACI_PID"
    echo "  Log: $DEVNET_LOG"
    echo ""
    echo "Next steps:"
    echo "  1. Fund addresses:   ./scripts/fund-addresses.sh"
    echo "  2. Publish scripts:  ./scripts/publish-hydra-scripts.sh"
    echo ""
    echo "To monitor devnet logs:"
    echo "  tail -f $DEVNET_LOG"
else
    echo "Warning: Could not retrieve devnet info from API."
    echo "Using default socket path: $YACI_NODE_SOCKET_PATH"
    
    echo "CARDANO_NODE_SOCKET_PATH=$YACI_NODE_SOCKET_PATH" > "$ENV_FILE"
fi
