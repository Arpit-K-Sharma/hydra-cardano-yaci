#!/bin/bash

# Script to stop all running Hydra nodes for all participants
set -e

source "$(dirname "$0")/utils/config-path.sh"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi
source "$CONFIG_PATH"

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

for NAME in "${PARTICIPANTS[@]}"; do
    NODE_DIR="$ROOT_DIR/hydra-nodes/$NAME"
    PID_FILE="$NODE_DIR/hydra-node.pid"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "Stopping Hydra node for $NAME (PID: $PID)"
            kill $PID
            sleep 1
            if ps -p $PID > /dev/null 2>&1; then
                echo "  PID $PID did not terminate, sending SIGKILL..."
                kill -9 $PID
            fi
            echo "  Stopped."
        else
            echo "  No running process for $NAME (PID file exists, but process not found)"
        fi
        rm -f "$PID_FILE"
    else
        echo "  No PID file for $NAME, node not running."
    fi
    echo ""
done

echo "All Hydra nodes stopped."
