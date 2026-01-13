#!/bin/bash
# Script to download and install hydra-node and hydra-tui binaries for Linux x86_64
set -e

# Source config-path.sh to set ROOT_DIR and CONFIG_PATH
source "$(dirname "$0")/../utils/config-path.sh"

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi

source "$CONFIG_PATH"

# Resolve paths from config
BIN_PATH="$ROOT_DIR/$BIN_DIR"
HYDRA_PATH="$ROOT_DIR/$HYDRA_NODE"
HYDRA_TUI_BINARY="hydra-tui"
HYDRA_TUI_PATH="$BIN_PATH/$HYDRA_TUI_BINARY"

# Check if unzip is available
if ! command -v unzip &> /dev/null; then
    echo "unzip not found. Please install unzip:"
    echo "  sudo apt install unzip  # Debian/Ubuntu"
    echo "  sudo yum install unzip  # RHEL/CentOS"
    exit 1
fi

mkdir -p "$BIN_PATH"

# ==================== Install hydra-node ====================
if [ -f "$HYDRA_PATH" ]; then
    echo "hydra-node already exists at $HYDRA_PATH. Skipping download."
    "$HYDRA_PATH" --version || true
else
    TMP_DIR=$(mktemp -d)
    ARCHIVE="$TMP_DIR/hydra.zip"
    
    echo "Downloading Hydra version $HYDRA_VERSION for Linux..."
    echo "URL: $HYDRA_DOWNLOAD_URL"
    
    # Download using curl or wget
    if command -v curl &> /dev/null; then
        curl -L --fail "$HYDRA_DOWNLOAD_URL" -o "$ARCHIVE" || {
            echo "Failed to download Hydra. Check HYDRA_VERSION or URL in $CONFIG_PATH"
            rm -rf "$TMP_DIR"
            exit 1
        }
    elif command -v wget &> /dev/null; then
        wget "$HYDRA_DOWNLOAD_URL" -O "$ARCHIVE" || {
            echo "Failed to download Hydra. Check HYDRA_VERSION or URL in $CONFIG_PATH"
            rm -rf "$TMP_DIR"
            exit 1
        }
    else
        echo "Neither curl nor wget found. Please install one of them."
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    echo "Extracting hydra-node archive..."
    unzip -q "$ARCHIVE" -d "$TMP_DIR"
    
    # Find hydra-node binary (handle nested directories)
    HYDRA_BINARY=$(find "$TMP_DIR" -type f -name "$HYDRA_NODE_BINARY" | head -n 1)
    
    if [ -z "$HYDRA_BINARY" ]; then
        echo "hydra-node binary not found in archive. Contents:"
        ls -R "$TMP_DIR"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Find hydra-tui binary if it exists in the archive
    TUI_IN_ARCHIVE=$(find "$TMP_DIR" -type f -name "$HYDRA_TUI_BINARY" | head -n 1)
    
    # Move hydra-node
    mv "$HYDRA_BINARY" "$HYDRA_PATH"
    chmod +x "$HYDRA_PATH"
    echo "hydra-node installed at $HYDRA_PATH"
    echo "Verification:"
    "$HYDRA_PATH" --version
    
    # Move hydra-tui if found
    if [ -n "$TUI_IN_ARCHIVE" ]; then
        mv "$TUI_IN_ARCHIVE" "$HYDRA_TUI_PATH"
        chmod +x "$HYDRA_TUI_PATH"
        echo "hydra-tui found and installed at $HYDRA_TUI_PATH"
        "$HYDRA_TUI_PATH" --version || true
    fi
    
    # Clean up temp directory
    rm -rf "$TMP_DIR"
fi

# ==================== Check for hydra-tui ====================
if [ ! -f "$HYDRA_TUI_PATH" ]; then
    echo ""
    echo "WARNING: hydra-tui was not found in the release archive."
    echo "If you need hydra-tui, you may need to:"
    echo "  1. Build it from source: https://github.com/cardano-scaling/hydra"
    echo "  2. Use Docker: docker pull ghcr.io/cardano-scaling/hydra-tui"
    echo "  3. Check if it's available in a different release format"
fi

echo ""
echo "Installation complete!"
echo "hydra-node: $HYDRA_PATH"
if [ -f "$HYDRA_TUI_PATH" ]; then
    echo "hydra-tui: $HYDRA_TUI_PATH"
fi
echo ""
echo "Add $BIN_PATH to your PATH if not already:"
echo "  export PATH=\"$BIN_PATH:\$PATH\""

exit 0