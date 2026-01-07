#!/bin/bash

# Script to setup Hydra Node using Docker

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
# Note: bin directory is managed by scripts/setup-folders.sh

echo "---------------------------------------------"
echo "Setting up Hydra Node (Docker)"
echo "---------------------------------------------"
echo ""

# Docker image
DOCKER_IMAGE="ghcr.io/cardano-scaling/hydra-node:${HYDRA_VERSION}"

echo "Step 1: Pulling Hydra node Docker image..."
echo "Image: $DOCKER_IMAGE"
docker pull "$DOCKER_IMAGE"
echo ""
echo "✓ Docker image pulled"
echo ""

# Step 2: Create hydra-node wrapper
echo "Step 2: Creating hydra-node wrapper..."

cat > "$BIN_PATH/hydra-node" << EOF
#!/bin/bash
# Hydra Node Docker Wrapper

SCRIPT_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="\$(dirname "\$SCRIPT_DIR")"

docker run --rm \\
  -u "\$(id -u):\$(id -g)" \\
  -v "\$PROJECT_ROOT:/workspace" \\
  -w /workspace \\
  --network host \\
  ghcr.io/cardano-scaling/hydra-node:${HYDRA_VERSION} \\
  "\$@"
EOF

chmod +x "$BIN_PATH/hydra-node"
echo "  ✓ Created $BIN_PATH/hydra-node"
echo ""

# Step 3: Test hydra-node
echo "Step 3: Testing hydra-node..."
VERSION_OUTPUT=$("$BIN_PATH/hydra-node" --version 2>&1)
if [ -n "$VERSION_OUTPUT" ]; then
    echo "  ✓ hydra-node works! Version: $VERSION_OUTPUT"
else
    echo "  ✗ hydra-node test failed"
    exit 1
fi

echo ""
echo "---------------------------------------------"
echo "✓ Hydra Node Docker setup complete!"
echo "---------------------------------------------"
echo ""
echo "You can now use:"
echo "  $BIN_PATH/hydra-node --version"
echo ""
