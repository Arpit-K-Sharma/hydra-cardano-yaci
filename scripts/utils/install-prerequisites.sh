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

# Check for Node.js (required for Yaci DevKit NPM)
if ! command -v node &> /dev/null; then
    echo "Node.js not found. Will need to install (required for Yaci DevKit)."
    NODE_MISSING=true
else
    NODE_VERSION=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 20 ]; then
        echo "✓ Node.js $NODE_VERSION installed (meets requirement >= 20.8.0)"
    else
        echo "⚠ Node.js $NODE_VERSION installed but version >= 20.8.0 required"
        NODE_MISSING=true
    fi
fi

# Check for npm (comes with Node.js)
if ! command -v npm &> /dev/null; then
    echo "npm not found. Will be installed with Node.js."
else
    echo "✓ npm already installed"
fi

# Install packages if any are missing
if [ ${#REQUIRED_PACKAGES[@]} -eq 0 ]; then
    echo ""
    echo "All prerequisites are already installed!"
    exit 0
fi

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

echo ""
echo "=== Prerequisites installed successfully! ==="

# Install Node.js if missing
if [ "$NODE_MISSING" = true ]; then
    echo ""
    echo "=== Installing Node.js 20.x ==="
    case "$OS" in
        ubuntu|debian)
            curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash -
            $SUDO apt install -y nodejs
            ;;
        fedora|rhel|centos)
            curl -fsSL https://rpm.nodesource.com/setup_20.x | $SUDO bash -
            $SUDO yum install -y nodejs
            ;;
        arch|manjaro)
            $SUDO pacman -S --noconfirm nodejs npm
            ;;
        *)
            echo "Please install Node.js 20.x manually from https://nodejs.org/"
            ;;
    esac
    echo "✓ Node.js installed: $(node --version)"
fi

echo ""
echo "You can now run the setup scripts:"
echo "  ./scripts/binary_setup/setup-cardano-cli.sh"
echo "  ./scripts/binary_setup/setup-hydra-node.sh"
echo "  ./scripts/devnet/setup-yaci-devkit.sh"
