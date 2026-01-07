#!/bin/bash

# Script to setup Cardano CLI using Docker

set -e

# Source config-path.sh to set ROOT_DIR and CONFIG_PATH
source "$(dirname "$0")/../utils/config-path.sh"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Config file not found at $CONFIG_PATH"
    exit 1
fi
source "$CONFIG_PATH"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

BIN_PATH="$ROOT_DIR/$BIN_DIR"

echo "---------------------------------------------"
echo "Setting up Cardano CLI (Docker)"
echo "---------------------------------------------"
echo ""

# Docker image
DOCKER_IMAGE="ghcr.io/blinklabs-io/cardano-node:latest"

echo "Step 1: Pulling Cardano CLI Docker image..."
echo "Image: $DOCKER_IMAGE"
docker pull "$DOCKER_IMAGE"
echo ""
echo "✓ Docker image pulled"
echo ""

# Step 2: Create cardano-cli wrapper
echo "Step 2: Creating cardano-cli wrapper..."

cat > "$BIN_PATH/cardano-cli" << 'EOF'
#!/bin/bash
# Cardano CLI Docker Wrapper

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PROJECT_ROOT:/workspace" \
  -w /workspace \
  ghcr.io/blinklabs-io/cardano-node:latest \
  cli "$@"
EOF

chmod +x "$BIN_PATH/cardano-cli"
echo "  ✓ Created $BIN_PATH/cardano-cli"
echo ""

# Step 3: Test cardano-cli
echo "Step 3: Testing cardano-cli..."
if "$BIN_PATH/cardano-cli" --version 2>&1 | grep -q "cardano-cli"; then
    echo "  ✓ cardano-cli works!"
else
    echo "  ✗ cardano-cli test failed"
    exit 1
fi

echo ""
echo "---------------------------------------------"
echo "✓ Cardano CLI Docker setup complete!"
echo "---------------------------------------------"
echo ""
echo "You can now use:"
echo "  $BIN_PATH/cardano-cli --version"
echo ""
