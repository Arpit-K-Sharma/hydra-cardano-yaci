#!/bin/bash

# Script to install prerequisites required for Hydra-Cardano-Yaci setup

set -e

echo "============================================"
echo "Checking Prerequisites"
echo "============================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error counter
ERRORS=0

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    elif [ "$(uname)" = "Darwin" ]; then
        OS="macos"
    else
        OS="unknown"
    fi
    echo "$OS"
}

OS=$(detect_os)
echo -e "${BLUE}Detected OS: $OS${NC}"
echo ""

# Determine if sudo is needed
SUDO=""
if [ "$EUID" -ne 0 ] && [ "$OS" != "macos" ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    fi
fi

# Function to check if a command exists
check_command() {
    local cmd=$1
    local version_flag=$2
    local install_name=${3:-$1}
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}[✔] $cmd is installed${NC}"
        if [ -n "$version_flag" ]; then
            VERSION=$($cmd $version_flag 2>&1 | head -n 1)
            echo -e "${YELLOW}    Version: $VERSION${NC}"
        fi
        return 0
    else
        echo -e "${RED}[✘] $cmd is not installed${NC}"
        return 1
    fi
}

# Function to install package based on OS
install_package() {
    local package=$1
    
    echo -e "${YELLOW}Installing $package...${NC}"
    
    case "$OS" in
        ubuntu|debian)
            $SUDO apt-get update -qq
            $SUDO apt-get install -y "$package"
            ;;
        fedora|rhel|centos)
            $SUDO yum install -y "$package"
            ;;
        arch|manjaro)
            $SUDO pacman -S --noconfirm "$package"
            ;;
        macos)
            if command -v brew &> /dev/null; then
                brew install "$package"
            else
                echo -e "${RED}Homebrew not found. Please install Homebrew first: https://brew.sh/${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Unsupported OS: $OS${NC}"
            echo "Please install $package manually"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✔] $package installed successfully${NC}"
        return 0
    else
        echo -e "${RED}[✘] Failed to install $package${NC}"
        return 1
    fi
}

echo "-------------------------------------"
echo "Checking Required Tools"
echo "-------------------------------------"
echo ""

# Check Node.js (required, cannot be auto-installed reliably)
echo "Checking for Node.js..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}[✘] Node.js not found${NC}"
    echo ""
    echo "Node.js >= 20.8.0 is required."
    echo "Please install from: https://nodejs.org/"
    echo ""
    if [ "$OS" = "macos" ]; then
        echo "For macOS, you can use Homebrew:"
        echo "  brew install node"
    elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        echo "For Ubuntu/Debian, you can use:"
        echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "  sudo apt-get install -y nodejs"
    fi
    echo ""
    ERRORS=$((ERRORS + 1))
else
    NODE_VERSION=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 20 ]; then
        echo -e "${GREEN}[✔] Node.js $NODE_VERSION installed (>= 20.8.0 required)${NC}"
    else
        echo -e "${RED}[✘] Node.js $NODE_VERSION found but >= 20.8.0 required${NC}"
        echo "Please upgrade Node.js from: https://nodejs.org/"
        ERRORS=$((ERRORS + 1))
    fi
fi
echo ""

# Check npm (comes with Node.js)
echo "Checking for npm..."
if ! check_command "npm" "--version"; then
    echo -e "${RED}npm not found (should come with Node.js)${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Array to collect packages that need installation
REQUIRED_PACKAGES=()

# Check curl
echo "Checking for curl..."
if ! check_command "curl" "--version"; then
    REQUIRED_PACKAGES+=("curl")
fi
echo ""

# Check wget
echo "Checking for wget..."
if ! check_command "wget" "--version"; then
    REQUIRED_PACKAGES+=("wget")
fi
echo ""

# Check unzip
echo "Checking for unzip..."
if ! check_command "unzip" "-v"; then
    REQUIRED_PACKAGES+=("unzip")
fi
echo ""

# Check tar
echo "Checking for tar..."
if ! check_command "tar" "--version"; then
    REQUIRED_PACKAGES+=("tar")
fi
echo ""

# Check jq (JSON parser)
echo "Checking for jq..."
if ! check_command "jq" "--version"; then
    REQUIRED_PACKAGES+=("jq")
fi
echo ""

# Check Docker (optional but recommended)
echo "Checking for Docker..."
if ! check_command "docker" "--version"; then
    echo -e "${YELLOW}[!] Docker not found (optional for alternative devnet setup)${NC}"
    echo "    If you want to use Docker, install from: https://docs.docker.com/get-docker/"
else
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        echo -e "${YELLOW}[!] Docker is installed but not running${NC}"
        echo "    Start Docker to use it"
    fi
fi
echo ""

# Check socat (optional, useful for socket bridging)
echo "Checking for socat..."
if ! check_command "socat" "-V"; then
    echo -e "${YELLOW}[!] socat not found (optional, useful for socket bridging)${NC}"
    read -p "Install socat? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REQUIRED_PACKAGES+=("socat")
    fi
fi
echo ""

# Install missing packages
if [ ${#REQUIRED_PACKAGES[@]} -eq 0 ]; then
    echo "-------------------------------------"
    echo -e "${GREEN}All required packages are installed!${NC}"
    echo "-------------------------------------"
else
    echo "-------------------------------------"
    echo "Installing Missing Packages"
    echo "-------------------------------------"
    echo ""
    echo "Packages to install: ${REQUIRED_PACKAGES[*]}"
    echo ""
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! install_package "$package"; then
            ERRORS=$((ERRORS + 1))
        fi
        echo ""
    done
fi

# Final summary
echo ""
echo "============================================"
echo "Prerequisites Check Summary"
echo "============================================"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✔ All Prerequisites Satisfied!       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BLUE}📦 Installed Versions:${NC}"
    echo "┌────────────────────────────────────────┐"
    if command -v node &> /dev/null; then
        printf "│ %-15s %-22s │\n" "Node.js:" "$(node --version)"
    fi
    if command -v npm &> /dev/null; then
        printf "│ %-15s %-22s │\n" "npm:" "$(npm --version)"
    fi
    if command -v curl &> /dev/null; then
        CURL_VER=$(curl --version 2>&1 | head -n 1 | awk '{print $2}')
        printf "│ %-15s %-22s │\n" "curl:" "$CURL_VER"
    fi
    if command -v wget &> /dev/null; then
        WGET_VER=$(wget --version 2>&1 | head -n 1 | awk '{print $3}')
        printf "│ %-15s %-22s │\n" "wget:" "$WGET_VER"
    fi
    if command -v jq &> /dev/null; then
        printf "│ %-15s %-22s │\n" "jq:" "$(jq --version 2>&1)"
    fi
    if command -v unzip &> /dev/null; then
        UNZIP_VER=$(unzip -v 2>&1 | head -n 1 | awk '{print $2}')
        printf "│ %-15s %-22s │\n" "unzip:" "$UNZIP_VER"
    fi
    if command -v tar &> /dev/null; then
        TAR_VER=$(tar --version 2>&1 | head -n 1 | awk '{print $NF}')
        printf "│ %-15s %-22s │\n" "tar:" "$TAR_VER"
    fi
    if command -v docker &> /dev/null; then
        DOCKER_VER=$(docker --version 2>&1 | awk '{print $3}' | tr -d ',')
        printf "│ %-15s %-22s │\n" "Docker:" "$DOCKER_VER"
    fi
    if command -v socat &> /dev/null; then
        SOCAT_VER=$(socat -V 2>&1 | head -n 1 | awk '{print $2}')
        printf "│ %-15s %-22s │\n" "socat:" "$SOCAT_VER"
    fi
    echo "└────────────────────────────────────────┘"
    echo ""
    
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    echo "1️⃣  Install Yaci DevKit"
    echo "-------> npm run setup:devkit "
    echo ""   
    echo "2️⃣  Start the Devnet                 "
    echo "-------> npm run start:devnet"
    echo ""
    echo "3️⃣  Bridge node.sock with socat"
    echo "-------> npm run bridge:node-sock"
    echo ""
    echo -e "${GREEN}✨ You're all set! Happy coding! ✨${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ $ERRORS Error(s) Found                   ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}⚠️  Issues Detected:${NC}"
    echo ""
    
    # Show what's missing
    if ! command -v node &> /dev/null || [ "$NODE_MAJOR" -lt 20 ]; then
        echo -e "${RED}  ✗ Node.js >= 20.8.0 is required${NC}"
        echo "    Install from: https://nodejs.org/"
        echo ""
    fi
    
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}  ✗ npm is required (comes with Node.js)${NC}"
        echo ""
    fi
    
    echo -e "${YELLOW}📋 Recommended Actions:${NC}"
    echo "┌────────────────────────────────────────┐"
    echo "│  1. Install Node.js >= 20.8.0         │"
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        echo "│     Ubuntu/Debian:                     │"
        echo "│     curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "│     sudo apt-get install -y nodejs    │"
    elif [ "$OS" = "macos" ]; then
        echo "│     macOS (via Homebrew):              │"
        echo "│     brew install node                  │"
    fi
    echo "│                                        │"
    echo "│  2. Re-run this script                 │"
    echo "│     npm run setup:prerequisites        │"
    echo "└────────────────────────────────────────┘"
    echo ""
    echo -e "${RED}Please resolve the errors above and try again.${NC}"
    echo ""
    exit 1
fi