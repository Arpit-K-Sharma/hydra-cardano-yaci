#!/bin/bash

# Script to install Yaci DevKit via NPM for cross-platform Cardano devnet

set -e

# Calculate ROOT_DIR (scripts/devnet -> scripts -> project root)
ROOT_DIR="$(dirname $(dirname $(dirname $(realpath $0))))"
CONFIG_PATH="$ROOT_DIR/scripts/utils/config.sh"

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

# Check if yaci-devkit is already installed
if command -v yaci-devkit &> /dev/null; then
    echo "✓ Yaci DevKit is already installed"
    yaci-devkit --version 2>/dev/null || echo "  (version check not available)"
else
    echo ""
    echo "Installing Yaci DevKit globally via NPM..."
    echo "Package: $YACI_DEVKIT_NPM_PACKAGE"
    echo ""
    npm install -g "$YACI_DEVKIT_NPM_PACKAGE"
    echo ""
    echo "✓ Yaci DevKit installed successfully"
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
