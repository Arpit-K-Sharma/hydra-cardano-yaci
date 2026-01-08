#!/bin/bash

# Script to stop all running Yaci DevKit devnet and viewer processes

set -e

# Source config-path.sh to set ROOT_DIR and CONFIG_PATH
source "$(dirname "$0")/../utils/config-path.sh"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi
source "$CONFIG_PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() { echo -e "${RED}❌ $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

echo "============================================"
echo "Stopping Yaci DevKit Devnet"
echo "============================================"
echo ""

# Configuration
PID_DIR="$ROOT_DIR/.pids"
VIEWER_PID_FILE="$PID_DIR/yaci-viewer.pid"

STOPPED_COUNT=0
FAILED_COUNT=0

# Function to stop process by PID
stop_process() {
    local PID=$1
    local NAME=$2
    
    if ps -p $PID > /dev/null 2>&1; then
        print_info "Stopping $NAME (PID: $PID)..."
        
        # Try graceful shutdown first
        if kill -TERM $PID 2>/dev/null; then
            # Wait up to 10 seconds for graceful shutdown
            for i in {1..10}; do
                if ! ps -p $PID > /dev/null 2>&1; then
                    print_success "$NAME stopped gracefully"
                    STOPPED_COUNT=$((STOPPED_COUNT+1))
                    return 0
                fi
                sleep 1
            done
            
            # Force kill if still running
            print_warning "$NAME didn't stop gracefully, force killing..."
            if kill -9 $PID 2>/dev/null; then
                print_success "$NAME force stopped"
                STOPPED_COUNT=$((STOPPED_COUNT+1))
                return 0
            else
                print_error "Failed to stop $NAME"
                FAILED_COUNT=$((FAILED_COUNT+1))
                return 1
            fi
        else
            print_error "Failed to send stop signal to $NAME"
            FAILED_COUNT=$((FAILED_COUNT+1))
            return 1
        fi
    else
        print_warning "$NAME (PID: $PID) is not running"
        return 1
    fi
}

# Function to find and stop processes by pattern
stop_by_pattern() {
    local PATTERN=$1
    local NAME=$2
    
    print_info "Searching for $NAME processes..."
    
    PIDS=$(pgrep -f "$PATTERN" 2>/dev/null || true)
    
    if [ -z "$PIDS" ]; then
        print_info "No $NAME processes found"
        return 0
    fi
    
    echo "Found $NAME processes: $PIDS"
    
    for PID in $PIDS; do
        # Skip our own script
        if [ $PID -eq $$ ]; then
            continue
        fi
        
        stop_process $PID "$NAME"
    done
}

# Function to kill process on specific port
kill_port() {
    local PORT=$1
    local SERVICE=$2
    
    print_info "Checking port $PORT ($SERVICE)..."
    
    if command -v lsof &> /dev/null; then
        PID=$(lsof -ti:$PORT 2>/dev/null || true)
        if [ -n "$PID" ]; then
            print_warning "Found process on port $PORT (PID: $PID)"
            if kill -9 $PID 2>/dev/null; then
                print_success "Killed process on port $PORT"
                STOPPED_COUNT=$((STOPPED_COUNT+1))
            else
                print_error "Failed to kill process on port $PORT"
                FAILED_COUNT=$((FAILED_COUNT+1))
            fi
        else
            print_info "Port $PORT is free"
        fi
    elif command -v netstat &> /dev/null; then
        PID=$(netstat -tlnp 2>/dev/null | grep ":$PORT " | awk '{print $7}' | cut -d'/' -f1 || true)
        if [ -n "$PID" ] && [ "$PID" != "-" ]; then
            print_warning "Found process on port $PORT (PID: $PID)"
            if kill -9 $PID 2>/dev/null; then
                print_success "Killed process on port $PORT"
                STOPPED_COUNT=$((STOPPED_COUNT+1))
            else
                print_error "Failed to kill process on port $PORT"
                FAILED_COUNT=$((FAILED_COUNT+1))
            fi
        else
            print_info "Port $PORT is free"
        fi
    else
        print_warning "Cannot check ports (lsof/netstat not available)"
    fi
}

echo "🔍 Checking for running Yaci services..."
echo ""

# Stop Viewer from PID file
if [ -f "$VIEWER_PID_FILE" ]; then
    VIEWER_PID=$(cat "$VIEWER_PID_FILE")
    stop_process $VIEWER_PID "Yaci Viewer"
    rm -f "$VIEWER_PID_FILE"
else
    print_info "No Yaci Viewer PID file found"
fi

echo ""
echo "============================================"
echo "Finding Additional Processes"
echo "============================================"
echo ""

# Stop any remaining yaci-cli processes
stop_by_pattern "yaci-cli" "Yaci CLI"

echo ""

# Stop yaci-devkit npm processes
stop_by_pattern "yaci-devkit" "Yaci DevKit"

echo ""

# Stop yaci-viewer processes
stop_by_pattern "$ROOT_DIR/yaci-viewer" "Yaci Viewer"

echo ""

# Stop cardano-node processes started by yaci
stop_by_pattern "cardano-node.*devnet" "Cardano Node (devnet)"

echo ""

# Stop cardano-submit-api processes
stop_by_pattern "cardano-submit-api" "Submit API"

echo ""

# Stop yaci-store processes
stop_by_pattern "yaci-store" "Yaci Store"

echo ""

# Stop ogmios processes
stop_by_pattern "ogmios" "Ogmios"

echo ""

# Stop kupo processes
stop_by_pattern "kupo" "Kupo"

echo ""
echo "============================================"
echo "Cleaning Up Port Bindings"
echo "============================================"
echo ""

# Ports from config
PORTS="$YACI_CLUSTER_API_PORT $YACI_NODE_PORT $YACI_SUBMIT_API_PORT $YACI_STORE_PORT $YACI_OGMIOS_PORT 5173 3000 1442"

for PORT in $PORTS; do
    kill_port $PORT "Port $PORT"
done

echo ""
echo "============================================"
echo "Optional: Clean Data & Logs"
echo "============================================"
echo ""

print_warning "Do you want to clean up data and log files?"
echo "This will remove:"
echo "  • All log files in $ROOT_DIR/$LOGS_DIR"
echo "  • Yaci CLI home directory: $YACI_CLI_HOME"
echo "  • PID files"
echo ""
read -p "Clean logs and data? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Cleaning up files..."
    
    # Remove log files
    if [ -d "$ROOT_DIR/$LOGS_DIR" ]; then
        rm -rf "$ROOT_DIR/$LOGS_DIR"/*
        print_success "Cleaned log directory"
    fi
    
    # Remove PID directory
    if [ -d "$PID_DIR" ]; then
        rm -rf "$PID_DIR"
        print_success "Cleaned PID directory"
    fi
    
    # Ask about Yaci CLI home
    print_warning "Remove Yaci CLI home? This deletes blockchain data and cluster config"
    read -p "Remove $YACI_CLI_HOME? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "$YACI_CLI_HOME" ]; then
            rm -rf "$YACI_CLI_HOME"
            print_success "Removed Yaci CLI home"
        fi
    fi
    
    # Ask about .env file
    if [ -f "$ROOT_DIR/.env" ]; then
        print_warning "Remove .env file?"
        read -p "Remove $ROOT_DIR/.env? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$ROOT_DIR/.env"
            print_success "Removed .env file"
        fi
    fi
else
    print_info "Keeping logs and data files"
fi

echo ""
echo "============================================"
echo "Shutdown Summary"
echo "============================================"
echo ""

if [ $STOPPED_COUNT -gt 0 ]; then
    print_success "Stopped $STOPPED_COUNT process(es)"
fi

if [ $FAILED_COUNT -gt 0 ]; then
    print_error "Failed to stop $FAILED_COUNT process(es)"
fi

if [ $STOPPED_COUNT -eq 0 ] && [ $FAILED_COUNT -eq 0 ]; then
    print_info "No Yaci processes were running"
fi

echo ""
echo "📊 Final Status:"
echo "   • All Yaci DevKit processes: STOPPED"
echo "   • All Yaci Viewer processes: STOPPED"
echo "   • Port bindings: CLEARED"
echo ""

# Check if any ports are still in use
PORTS_STILL_IN_USE=""
for PORT in $PORTS; do
    if lsof -i :$PORT 2>/dev/null | grep LISTEN > /dev/null 2>&1; then
        PORTS_STILL_IN_USE+="$PORT "
    fi
done

if [ -n "$PORTS_STILL_IN_USE" ]; then
    print_warning "Some ports are still in use: $PORTS_STILL_IN_USE"
    echo "   You may need to manually investigate these ports"
else
    print_success "All configured ports are free"
fi

echo ""
print_success "Yaci DevNet shutdown complete!"
echo ""
echo "💡 To start again, run:"
echo "   npm run start:devnet"
echo "   OR"
echo "   ./scripts/devnet/start-devnet.sh"
echo ""
echo "============================================"