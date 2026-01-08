#!/bin/bash

# Script to start Yaci DevKit devnet with Yaci Viewer and generate .env file
# Runs in FOREGROUND to allow user interaction with devnet CLI

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
echo "Starting Yaci DevKit Devnet"
echo "============================================"
echo ""

# Configuration
YACI_DEVKIT_DIR="$ROOT_DIR/yaci-devkit"
VIEWER_APP_DIR="$ROOT_DIR/yaci-viewer/applications/viewer"
LOGS_DIR_FULL="$ROOT_DIR/$LOGS_DIR"
PID_DIR="$ROOT_DIR/.pids"
ENV_FILE="$ROOT_DIR/.env"

# PID files
VIEWER_PID_FILE="$PID_DIR/yaci-viewer.pid"

# Create necessary directories
mkdir -p "$LOGS_DIR_FULL" "$PID_DIR"

# Check if Yaci DevKit is installed
if [ ! -d "$YACI_DEVKIT_DIR/node_modules/@bloxbean/yaci-devkit" ]; then
    print_error "Yaci DevKit not found"
    echo "Please run: npm run setup:devkit"
    echo "OR: ./scripts/devnet/setup-yaci-devkit.sh"
    exit 1
fi

# Check if Viewer is installed
VIEWER_EXISTS=0
if [ -d "$VIEWER_APP_DIR" ]; then
    VIEWER_EXISTS=1
    print_success "Yaci Viewer found"
else
    print_warning "Yaci Viewer not found, will skip starting viewer"
    print_info "Run setup script to install: npm run setup:devkit"
fi

echo ""
echo "============================================"
echo "Configuration Options"
echo "============================================"
echo ""
echo "Select devnet mode:"
echo "  1) Yaci Store (Blockfrost-compatible API) [Recommended]"
echo "  2) Ogmios + Kupo"
echo "  3) Custom (interactive configuration)"
echo ""
read -p "Enter choice [1-3] (default: 1): " MODE_CHOICE
MODE_CHOICE=${MODE_CHOICE:-1}

case $MODE_CHOICE in
    1)
        MODE="yaci-store"
        MODE_CMD="create-node --start --enable-submit-api --enable-yaci-store"
        print_info "Selected: Yaci Store mode (Blockfrost-compatible)"
        ;;
    2)
        MODE="kupomios"
        MODE_CMD="create-node --start --enable-submit-api --enable-ogmios --enable-kupo"
        print_info "Selected: Ogmios + Kupo mode"
        ;;
    3)
        MODE="custom"
        MODE_CMD="create-node --start --interactive"
        print_info "Selected: Custom interactive mode"
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Block time configuration:"
echo "  1) 1 second (default)"
echo "  2) 0.2 seconds (200ms - fast development)"
echo "  3) 0.1 seconds (100ms - ultra-fast)"
echo "  4) Custom"
echo ""
read -p "Enter choice [1-4] (default: 1): " BLOCK_CHOICE
BLOCK_CHOICE=${BLOCK_CHOICE:-1}

BLOCK_TIME=""
case $BLOCK_CHOICE in
    1)
        BLOCK_TIME=""
        print_info "Using default 1 second block time"
        ;;
    2)
        BLOCK_TIME="--block-time 0.2 --slot-length 0.2"
        print_info "Using 200ms block time"
        ;;
    3)
        BLOCK_TIME="--block-time 0.1 --slot-length 0.1"
        print_info "Using 100ms block time"
        ;;
    4)
        read -p "Enter block time in seconds (e.g., 0.5, 2): " CUSTOM_BLOCK
        BLOCK_TIME="--block-time $CUSTOM_BLOCK --slot-length $CUSTOM_BLOCK"
        print_info "Using custom ${CUSTOM_BLOCK}s block time"
        ;;
esac

# Add block time to command if specified
if [ -n "$BLOCK_TIME" ]; then
    MODE_CMD="$MODE_CMD $BLOCK_TIME"
fi

# Start Yaci Viewer in background first (if available)
if [ $VIEWER_EXISTS -eq 1 ]; then
    echo ""
    echo "============================================"
    echo "Starting Yaci Viewer (Background)"
    echo "============================================"
    echo ""
    
    print_info "Starting Yaci Viewer in background..."
    
    cd "$VIEWER_APP_DIR"
    VIEWER_LOG="$LOGS_DIR_FULL/yaci-viewer.log"
    
    nohup npm run dev > "$VIEWER_LOG" 2>&1 &
    VIEWER_PID=$!
    echo $VIEWER_PID > "$VIEWER_PID_FILE"
    
    print_success "Yaci Viewer started (PID: $VIEWER_PID)"
    print_info "Logs: $VIEWER_LOG"
    print_info "Access at: http://localhost:5173"
    
    cd "$ROOT_DIR"
    
    sleep 3
fi

# Generate .env file BEFORE starting devnet
echo ""
echo "============================================"
echo "Creating Environment File"
echo "============================================"
echo ""

print_info "Generating .env file at: $ENV_FILE"

# Detect socket path (will be available after devnet starts)
SOCKET_PATH="$YACI_NODE_SOCKET_PATH"

cat > "$ENV_FILE" << EOF
# Yaci DevNet Environment Configuration
# Generated: $(date)
# Mode: $MODE

# =============================================================================
# YACI DEVKIT CONFIGURATION
# =============================================================================

# Yaci Store API (Blockfrost-compatible)
YACI_STORE_URL=http://localhost:$YACI_STORE_PORT
YACI_STORE_API_URL=http://localhost:$YACI_STORE_PORT/api/v1
YACI_STORE_SWAGGER_URL=http://localhost:$YACI_STORE_PORT/swagger-ui/index.html

# Yaci Cluster Admin API
YACI_CLUSTER_API_URL=http://localhost:$YACI_CLUSTER_API_PORT
YACI_TOPUP_API=$YACI_TOPUP_API
YACI_UTXOS_API=$YACI_UTXOS_API

# Ogmios WebSocket API
OGMIOS_URL=http://localhost:$YACI_OGMIOS_PORT
OGMIOS_WS_URL=ws://localhost:$YACI_OGMIOS_PORT

# Kupo API
KUPO_URL=http://localhost:1442

# Cardano Submit API
SUBMIT_API_URL=http://localhost:$YACI_SUBMIT_API_PORT

# =============================================================================
# CARDANO NODE CONFIGURATION
# =============================================================================

# Node socket path (required for cardano-cli)
CARDANO_NODE_SOCKET_PATH=$SOCKET_PATH

# Network configuration
CARDANO_NETWORK=devnet
TESTNET_MAGIC=$TESTNET_MAGIC

# =============================================================================
# YACI VIEWER
# =============================================================================

YACI_VIEWER_URL=http://localhost:5173
EOF

if [ $VIEWER_EXISTS -eq 1 ]; then
    echo "YACI_VIEWER_PID=$VIEWER_PID" >> "$ENV_FILE"
    echo "YACI_VIEWER_LOG=$VIEWER_LOG" >> "$ENV_FILE"
fi

cat >> "$ENV_FILE" << EOF

# =============================================================================
# PROJECT PATHS
# =============================================================================

PROJECT_ROOT=$ROOT_DIR
YACI_CLI_HOME=$YACI_CLI_HOME
LOGS_DIR=$LOGS_DIR_FULL
EOF

print_success "Environment file created: $ENV_FILE"

echo ""
echo "============================================"
echo "Starting Yaci DevKit (INTERACTIVE)"
echo "============================================"
echo ""

print_info "Starting Yaci DevKit in interactive mode..."
print_info "Command: npx yaci-devkit $MODE_CMD"
echo ""
print_success "🎯 Devnet will start and you'll see: default:devnet>"
print_info "You can now run commands interactively!"
echo ""
print_warning "⚠️  When you're done, type 'exit' or press Ctrl+C"
print_warning "⚠️  Then run: npm run stop:devnet to cleanup"
echo ""
echo "============================================"
echo "📊 Quick Reference:"
echo "============================================"
echo ""
if [[ "$MODE" == "yaci-store" ]]; then
    echo "🌐 Yaci Store API:"
    echo "   http://localhost:$YACI_STORE_PORT/api/v1"
    echo ""
    echo "📖 Swagger UI:"
    echo "   http://localhost:$YACI_STORE_PORT/swagger-ui/index.html"
    echo ""
fi
if [[ "$MODE" == "kupomios" ]]; then
    echo "🌐 Ogmios: http://localhost:$YACI_OGMIOS_PORT"
    echo "🌐 Kupo: http://localhost:1442"
    echo ""
fi
echo "🔧 Submit API:"
echo "   http://localhost:$YACI_SUBMIT_API_PORT"
echo ""
if [ $VIEWER_EXISTS -eq 1 ]; then
    echo "📺 Yaci Viewer:"
    echo "   http://localhost:5173"
    echo ""
fi
echo "📝 Environment:"
echo "   source $ENV_FILE"
echo ""
echo "============================================"
echo ""
echo "Starting devnet..."
echo ""

# Change to yaci-devkit directory and run INTERACTIVELY
cd "$YACI_DEVKIT_DIR"

# Run yaci-devkit in foreground (interactive mode)
npx yaci-devkit $MODE_CMD

# If user exits the interactive shell, show cleanup message
echo ""
echo "============================================"
echo "Devnet Stopped"
echo "============================================"
echo ""
print_warning "Devnet CLI has exited"
print_info "Yaci Viewer is still running in background"
echo ""
print_info "To fully stop all services, run:"
echo "   npm run stop:devnet"
echo "   OR"
echo "   ./scripts/devnet/stop-devnet.sh"
echo ""