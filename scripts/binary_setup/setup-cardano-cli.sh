#!/bin/bash

# Script to download and set up Cardano CLI binary for Linux (for key/address generation)

set -e

# Calculate ROOT_DIR (scripts/binary_setup -> scripts -> project root)
ROOT_DIR="$(dirname $(dirname $(dirname $(realpath $0))))"
CONFIG_PATH="$ROOT_DIR/scripts/utils/config.sh"

# Source config file
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi
source "$CONFIG_PATH"

# Resolve paths from config
BIN_PATH="$ROOT_DIR/$BIN_DIR"
CLI_PATH="$ROOT_DIR/$CARDANO_CLI"


# Check if cardano-cli already exists
if [ -f "$CLI_PATH" ]; then
    echo "cardano-cli already exists at $CLI_PATH. Skipping download."
    "$CLI_PATH" --version
    exit 0
fi


echo "Downloading Cardano CLI version $CARDANO_VERSION for Linux..."

# Download the Linux binary (x86_64) using URL from config
TMP_DIR=$(mktemp -d)

echo "Downloading from $CARDANO_CLI_DOWNLOAD_URL..."
curl -L --fail "$CARDANO_CLI_DOWNLOAD_URL" -o "$TMP_DIR/cardano-node.tar.gz" || {
    echo "Failed to download Cardano CLI. Please check the version or your internet connection."
    rm -rf "$TMP_DIR"
    exit 1
}

# Extract archive
echo "Extracting archive..."
tar -xzf "$TMP_DIR/cardano-node.tar.gz" -C "$TMP_DIR"

# Find and move cardano-cli to bin (handle nested directories)
CLI_BINARY=$(find "$TMP_DIR" -name "cardano-cli" -type f | head -n 1)
if [ -n "$CLI_BINARY" ]; then
    mv "$CLI_BINARY" "$CLI_PATH"
    chmod +x "$CLI_PATH"
    echo "cardano-cli installed at $CLI_PATH"
    "$CLI_PATH" --version
else
    echo "cardano-cli binary not found in the archive. Please check the release format."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Cleanup
rm -rf "$TMP_DIR"

# echo ""
# echo "Add $BIN_PATH to your PATH to use cardano-cli:"
# echo "  export PATH=\"$BIN_PATH:\$PATH\""
