#!/bin/bash

# Script to stop all running Yaci DevKit devnet processes

# Source config-path.sh for ROOT_DIR
source "$(dirname "$0")/../utils/config-path.sh"

echo "============================================"
echo "Stopping Yaci DevKit Devnet"
echo "============================================"
echo ""

# Ports used by Yaci DevKit (NPM distribution)
# 10000 - yaci-cli API
# 3001  - cardano-node
# 8080  - yaci-store
# 8090  - cardano-submit-api
# 1337  - ogmios
# 3000  - yaci-viewer (legacy)
# 5173  - yaci-viewer (default)
PORTS="10000 3001 8080 8090 1337 3000 5173"

# Collect PIDs from process names
PIDS=""

# yaci-devkit npm process
for PID in $(pgrep -f 'yaci-devkit' 2>/dev/null); do
    PIDS+=" $PID"
done

# yaci-cli process
for PID in $(pgrep -f 'yaci-cli' 2>/dev/null); do
    PIDS+=" $PID"
done

# yaci-viewer process
for PID in $(pgrep -f 'yaci-viewer' 2>/dev/null); do
    PIDS+=" $PID"
done

# cardano-node process
for PID in $(pgrep -f 'cardano-node' 2>/dev/null); do
    PIDS+=" $PID"
done

# cardano-submit-api process
for PID in $(pgrep -f 'cardano-submit-api' 2>/dev/null); do
    PIDS+=" $PID"
done

# yaci-store process
for PID in $(pgrep -f 'yaci-store' 2>/dev/null); do
    PIDS+=" $PID"
done

# ogmios process
for PID in $(pgrep -f 'ogmios' 2>/dev/null); do
    PIDS+=" $PID"
done

# Also collect PIDs from any process listening on Yaci ports
for PORT in $PORTS; do
    PID_ON_PORT=$(lsof -ti tcp:$PORT 2>/dev/null)
    if [ -n "$PID_ON_PORT" ]; then
        PIDS+=" $PID_ON_PORT"
    fi
done

# Remove duplicates and empty entries
PIDS=$(echo $PIDS | xargs -n1 2>/dev/null | sort -u | xargs 2>/dev/null)

if [ -z "$PIDS" ]; then
    echo "No running Yaci DevKit devnet or related processes found."
    exit 0
fi

echo "Found processes to stop (PIDs: $PIDS)"
echo ""

# First try graceful kill
echo "Sending SIGTERM to processes..."
kill $PIDS 2>/dev/null || true

# Wait a moment for graceful shutdown
sleep 2

# Check if any processes are still running and force kill
REMAINING=""
for PID in $PIDS; do
    if ps -p $PID > /dev/null 2>&1; then
        REMAINING+=" $PID"
    fi
done

if [ -n "$REMAINING" ]; then
    echo "Some processes did not stop gracefully. Force killing (PIDs:$REMAINING)..."
    kill -9 $REMAINING 2>/dev/null || true
    sleep 1
fi

# Final check on ports
echo ""
STILL_RUNNING=""
for PORT in $PORTS; do
    if lsof -i :$PORT 2>/dev/null | grep LISTEN > /dev/null 2>&1; then
        STILL_RUNNING+="$PORT "
    fi
done

if [ -n "$STILL_RUNNING" ]; then
    echo "⚠ Warning: Some ports are still in use: $STILL_RUNNING"
    echo "  You may need to manually kill processes on these ports."
    exit 1
else
    echo "✓ Yaci DevKit devnet stopped successfully."
    echo ""
    echo "All ports are now free:"
    for PORT in $PORTS; do
        echo "  - Port $PORT: free"
    done
fi
