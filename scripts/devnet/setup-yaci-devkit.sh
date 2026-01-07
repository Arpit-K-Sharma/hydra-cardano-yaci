#!/bin/bash

# Script to install Yaci DevKit via NPM for cross-platform Cardano devnet

set -e


# Source config-path.sh to set ROOT_DIR and CONFIG_PATH
source "$(dirname "$0")/../utils/config-path.sh"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi
source "$CONFIG_PATH"

echo "============================================"
echo "Setting up Yaci DevKit (NPM Distribution)"
echo "============================================"
echo ""

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed."
    echo "Please run: ./scripts/utils/install-prerequisites.sh"
    exit 1
fi

NODE_VERSION=$(node --version | sed 's/v//')
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 20 ]; then
    echo "Error: Node.js version >= 20.8.0 required (found $NODE_VERSION)"
    echo "Please upgrade Node.js."
    exit 1
fi
echo "✓ Node.js $NODE_VERSION detected"

# Check for npm
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed."
    exit 1
fi
echo "✓ npm $(npm --version) detected"

# Check if yaci-devkit is already installed locally
YACI_DEVKIT_DIR="$ROOT_DIR/yaci-devkit"
if [ -d "$YACI_DEVKIT_DIR/node_modules/@bloxbean/yaci-devkit" ]; then
    echo "\u2713 Yaci DevKit is already installed locally in $YACI_DEVKIT_DIR"
    npx --prefix "$YACI_DEVKIT_DIR" yaci-devkit --version 2>/dev/null || echo "  (version check not available)"
else
    echo ""
    echo "Installing Yaci DevKit locally in $YACI_DEVKIT_DIR via NPM..."
    mkdir -p "$YACI_DEVKIT_DIR"
    npm install --prefix "$YACI_DEVKIT_DIR" @bloxbean/yaci-devkit
    echo "\u2713 Yaci DevKit installed locally"
fi

# Create yaci-cli home directory if it doesn't exist
if [ ! -d "$YACI_CLI_HOME" ]; then
    mkdir -p "$YACI_CLI_HOME"
    echo "✓ Created Yaci CLI home directory: $YACI_CLI_HOME"
else
    echo "✓ Yaci CLI home directory exists: $YACI_CLI_HOME"
fi

echo ""
echo "============================================"
echo "Yaci DevKit Setup Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Start the devnet:    ./scripts/devnet/start-devnet.sh"
echo "  2. Fund addresses:      ./scripts/fund-addresses.sh"
echo "  3. Publish scripts:     ./scripts/publish-hydra-scripts.sh"
echo ""
echo "Useful commands:"
echo "  yaci-devkit up --enable-yaci-store    # Start devnet with indexer"
echo "  yaci-devkit up --interactive          # Start with CLI prompt"
echo ""
