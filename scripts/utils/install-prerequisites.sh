#!/bin/bash

# Script to install prerequisites required for Hydra-Cardano-Yaci setup

set -e

echo "=== Installing Prerequisites ==="
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Please install dependencies manually."
    exit 1
fi

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# List of required packages
REQUIRED_PACKAGES=()

# Check for curl
if ! command -v curl &> /dev/null; then
    echo "curl not found. Will install."
    REQUIRED_PACKAGES+=("curl")
else
    echo "✓ curl already installed"
fi

# Check for wget
if ! command -v wget &> /dev/null; then
    echo "wget not found. Will install."
    REQUIRED_PACKAGES+=("wget")
else
    echo "✓ wget already installed"
fi

# Check for unzip
if ! command -v unzip &> /dev/null; then
    echo "unzip not found. Will install."
    REQUIRED_PACKAGES+=("unzip")
else
    echo "✓ unzip already installed"
fi

# Check for tar
if ! command -v tar &> /dev/null; then
    echo "tar not found. Will install."
    REQUIRED_PACKAGES+=("tar")
else
    echo "✓ tar already installed"
fi

# Check for jq (useful for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo "jq not found. Will install (optional but recommended)."
    REQUIRED_PACKAGES+=("jq")
else
    echo "✓ jq already installed"
fi


# Check for Node.js (required for npm scripts)
if ! command -v node &> /dev/null; then
    echo "✗ Node.js not found. Please install Node.js (>= 20.8.0) from https://nodejs.org/ and re-run this script."
    exit 1
else
    NODE_VERSION=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 20 ]; then
        echo "✓ Node.js $NODE_VERSION installed (meets requirement >= 20.8.0)"
    else
        echo "⚠ Node.js $NODE_VERSION installed but version >= 20.8.0 required. Please upgrade Node.js."
        exit 1
    fi
fi

# Check for npm (comes with Node.js)
if ! command -v npm &> /dev/null; then
    echo "✗ npm not found. Please install Node.js (which includes npm) from https://nodejs.org/ and re-run this script."
    exit 1
else
    echo "✓ npm already installed"
fi



# Install packages if any are missing
if [ ${#REQUIRED_PACKAGES[@]} -eq 0 ]; then
    echo ""
    echo "All prerequisites are already installed!"
else
    echo ""
    echo "Installing missing packages: ${REQUIRED_PACKAGES[*]}"
    echo ""
    case "$OS" in
        ubuntu|debian)
            $SUDO apt update
            $SUDO apt install -y "${REQUIRED_PACKAGES[@]}"
            ;;
        fedora|rhel|centos)
            $SUDO yum install -y "${REQUIRED_PACKAGES[@]}"
            ;;
        arch|manjaro)
            $SUDO pacman -S --noconfirm "${REQUIRED_PACKAGES[@]}"
            ;;
        *)
            echo "Unsupported OS: $OS"
            echo "Please install these packages manually: ${REQUIRED_PACKAGES[*]}"
            exit 1
            ;;
    esac
fi


# Final check for node and npm
NODE_OK=false
NPM_OK=false
if command -v node &> /dev/null; then
    NODE_OK=true
fi
if command -v npm &> /dev/null; then
    NPM_OK=true
fi

if [ "$NODE_OK" = true ] && [ "$NPM_OK" = true ]; then
    echo ""
    echo "=== Prerequisites installed successfully! ==="
    echo ""
    echo "You can now run the setup scripts:"
    echo "  ./scripts/binary_setup/setup-cardano-cli.sh"
    echo "  ./scripts/binary_setup/setup-hydra-node.sh"
    echo "  ./scripts/devnet/setup-yaci-devkit.sh"
else
    echo ""
    echo "✗ Error: Node.js and npm are both required."
    if [ "$NPM_OK" = true ] && [ "$NODE_OK" = false ]; then
        echo "  npm is installed but node is not. This usually means your PATH is misconfigured or npm was installed separately."
    fi
    echo "  Please ensure both node and npm are installed and available in your PATH."
    exit 1
fi
