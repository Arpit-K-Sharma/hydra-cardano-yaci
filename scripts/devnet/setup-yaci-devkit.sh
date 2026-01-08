#!/bin/bash

# Script to install Yaci DevKit and Yaci Viewer locally via NPM

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
echo "Setting up Yaci DevKit (NPM Distribution)"
echo "============================================"
echo ""

# Check for Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed"
    echo "Please run: ./scripts/utils/install-prerequisites.sh"
    exit 1
fi

NODE_VERSION=$(node --version | sed 's/v//')
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 20 ]; then
    print_error "Node.js version >= 20.8.0 required (found $NODE_VERSION)"
    echo "Please upgrade Node.js."
    exit 1
fi
print_success "Node.js $NODE_VERSION detected"

# Check for npm
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed"
    exit 1
fi
print_success "npm $(npm --version) detected"

# Check for git
if ! command -v git &> /dev/null; then
    print_error "git is not installed"
    echo "Git is required to clone Yaci Viewer repository"
    exit 1
fi
print_success "git $(git --version | awk '{print $3}') detected"

# Check OS compatibility
OS=$(uname -s)
ARCH=$(uname -m)
echo ""
echo "🖥️  System Information:"
echo "   OS: $OS"
echo "   Architecture: $ARCH"

if [[ "$OS" == "Linux" && "$ARCH" == "x86_64" ]]; then
    print_success "Linux x64 - Supported"
elif [[ "$OS" == "Darwin" && "$ARCH" == "arm64" ]]; then
    print_success "macOS ARM64 - Supported"
elif [[ "$OS" == "Darwin" && "$ARCH" == "x86_64" ]]; then
    print_success "macOS Intel - Supported"
else
    print_warning "System ($OS $ARCH) may not be officially supported"
fi

echo ""
echo "============================================"
echo "Step 1/2: Installing Yaci DevKit (NPM)"
echo "============================================"
echo ""

# Install yaci-devkit locally in the yaci-devkit directory
YACI_DEVKIT_DIR="$ROOT_DIR/yaci-devkit"
mkdir -p "$YACI_DEVKIT_DIR"

# Check if yaci-devkit is already installed
if [ -d "$YACI_DEVKIT_DIR/node_modules/@bloxbean/yaci-devkit" ]; then
    YACI_VERSION=$(npm list --prefix "$YACI_DEVKIT_DIR" @bloxbean/yaci-devkit 2>/dev/null | grep @bloxbean/yaci-devkit | awk '{print $2}' | head -1 || echo "unknown")
    print_success "Yaci DevKit is already installed locally (v$YACI_VERSION)"
else
    print_info "Installing Yaci DevKit locally..."
    if npm install --prefix "$YACI_DEVKIT_DIR" @bloxbean/yaci-devkit; then
        print_success "Yaci DevKit installed locally"
    else
        print_error "Failed to install Yaci DevKit"
        exit 1
    fi
fi

echo ""
echo "============================================"
echo "Step 2/2: Installing Yaci Viewer (Source)"
echo "============================================"
echo ""

# Clone Yaci Viewer from GitHub for local development
VIEWER_SOURCE_DIR="$ROOT_DIR/yaci-viewer"

if [ -d "$VIEWER_SOURCE_DIR" ]; then
    print_warning "Yaci Viewer directory already exists at: $VIEWER_SOURCE_DIR"
    read -p "Remove and reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$VIEWER_SOURCE_DIR"
        print_info "Removed existing directory"
    else
        print_info "Keeping existing installation"
        SKIP_VIEWER=1
    fi
fi

if [ "$SKIP_VIEWER" != "1" ]; then
    print_info "Cloning Yaci Viewer from GitHub..."
    if git clone https://github.com/bloxbean/yaci-devkit.git "$VIEWER_SOURCE_DIR"; then
        print_success "Repository cloned"
    else
        print_error "Failed to clone repository"
        exit 1
    fi
    
    # Navigate to viewer application directory
    VIEWER_APP_DIR="$VIEWER_SOURCE_DIR/applications/viewer"
    
    if [ ! -d "$VIEWER_APP_DIR" ]; then
        print_error "Viewer application directory not found at: $VIEWER_APP_DIR"
        exit 1
    fi
    
    cd "$VIEWER_APP_DIR"
    
    print_info "Installing Viewer dependencies..."
    if npm install; then
        print_success "Dependencies installed"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
    
    print_info "Building Yaci Viewer..."
    if npm run build; then
        print_success "Yaci Viewer built successfully"
    else
        print_error "Build failed"
        exit 1
    fi
    
    cd "$ROOT_DIR"
fi

echo ""
echo "============================================"
echo "Creating Required Directories"
echo "============================================"
echo ""

# Create yaci-cli home directory if it doesn't exist
if [ ! -d "$YACI_CLI_HOME" ]; then
    mkdir -p "$YACI_CLI_HOME"
    print_success "Created Yaci CLI home: $YACI_CLI_HOME"
else
    print_info "Yaci CLI home exists: $YACI_CLI_HOME"
fi

# Create logs directory
LOGS_DIR_FULL="$ROOT_DIR/$LOGS_DIR"
mkdir -p "$LOGS_DIR_FULL"
print_success "Created logs directory: $LOGS_DIR_FULL"

# Create PID directory for process tracking
PID_DIR="$ROOT_DIR/.pids"
mkdir -p "$PID_DIR"
print_success "Created PID directory: $PID_DIR"

echo ""
echo "============================================"
echo "🎉 Yaci DevKit Setup Complete!"
echo "============================================"
echo ""
echo "📦 Installed Components:"
echo "   • Yaci DevKit: $YACI_DEVKIT_DIR"
if [ "$SKIP_VIEWER" != "1" ]; then
    echo "   • Yaci Viewer: $VIEWER_SOURCE_DIR/applications/viewer"
fi
echo "   • Yaci CLI Home: $YACI_CLI_HOME"
echo "   • Logs: $LOGS_DIR_FULL"
echo ""
echo "📚 Next Steps:"
echo ""
echo "1. Start the devnet:"
echo "   npm run start:devnet"
echo "   OR"
echo "   ./scripts/devnet/start-devnet.sh"
echo ""
echo "2. Fund addresses:"
echo "   npm run fund-addresses"
echo ""
echo "3. Stop the devnet:"
echo "   npm run stop:devnet"
echo "   OR"
echo "   ./scripts/devnet/stop-devnet.sh"
echo ""
echo "🌐 Default Ports (from config):"
echo "   • Yaci Store API: http://localhost:$YACI_STORE_PORT"
echo "   • Yaci Cluster API: http://localhost:$YACI_CLUSTER_API_PORT"
echo "   • Ogmios WebSocket: ws://localhost:$YACI_OGMIOS_PORT"
if [ "$SKIP_VIEWER" != "1" ]; then
    echo "   • Yaci Viewer: http://localhost:5173"
fi
echo ""
echo "📖 Configuration:"
echo "   Edit: $CONFIG_PATH"
echo ""
echo "============================================"