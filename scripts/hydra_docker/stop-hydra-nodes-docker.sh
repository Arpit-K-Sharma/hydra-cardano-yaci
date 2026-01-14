#!/bin/bash
# Stop all Hydra nodes running via Docker for all participants defined in config.sh
set -e

# Source config
source "$(dirname "$0")/../utils/config-path.sh"
source "$CONFIG_PATH"

echo "Stopping Hydra nodes..."

for NAME in "${PARTICIPANTS[@]}"; do
    NODE_DIR="$ROOT_DIR/hydra-nodes/$NAME"
    PID_FILE="$NODE_DIR/hydra-node.pid"
    CONTAINER_NAME="hydra-$NAME"
    STOPPED=false

    # First, kill the wrapper process if running (via PID file)
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "Stopping $NAME wrapper (PID: $PID)..."
            kill $PID 2>/dev/null || true
            sleep 1
        fi
        rm -f "$PID_FILE"
    fi

    # Then stop the Docker container (this is the actual hydra-node)
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Stopping Docker container $CONTAINER_NAME..."
        docker stop "$CONTAINER_NAME" > /dev/null 2>&1 || true
        
        # Wait for container to stop
        for i in {1..10}; do
            if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
                echo "  ✓ $NAME stopped"
                STOPPED=true
                break
            fi
            sleep 1
        done

        # Force remove if still running
        if [ "$STOPPED" = false ]; then
            echo "  Force removing $NAME container..."
            docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true
            STOPPED=true
        fi
    fi

    if [ "$STOPPED" = false ]; then
        echo "  $NAME: Not running"
    fi
done

echo ""
echo "--------------------------------------------"
echo "✓ All Hydra nodes stopped."
echo "--------------------------------------------"
