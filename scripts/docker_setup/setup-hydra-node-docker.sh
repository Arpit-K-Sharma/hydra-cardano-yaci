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

cat > "$BIN_PATH/hydra-node" << 'WRAPPER_EOF'
#!/bin/bash
# Hydra Node Docker Wrapper

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Extract node-id from arguments for container naming
CONTAINER_NAME="hydra-node"
for i in "$@"; do
  if [[ "$prev_arg" == "--node-id" ]]; then
    CONTAINER_NAME="hydra-$i"
    break
  fi
  prev_arg="$i"
done

# Stop and remove existing container with same name (if any)
docker rm -f "$CONTAINER_NAME" 2>/dev/null

docker run --rm \
  --name "$CONTAINER_NAME" \
  -u "$(id -u):$(id -g)" \
  -v "$PROJECT_ROOT:/workspace" \
  -w /workspace \
  --network host \
WRAPPER_EOF

# Append the image with version (not quoted so variable expands)
echo "  ghcr.io/cardano-scaling/hydra-node:${HYDRA_VERSION} \\" >> "$BIN_PATH/hydra-node"
echo '  "$@"' >> "$BIN_PATH/hydra-node"

chmod +x "$BIN_PATH/hydra-node"
echo "  ✓ Created $BIN_PATH/hydra-node"
echo ""

# Step 2b: Create hydra-tui wrapper
echo "Step 2b: Creating hydra-tui wrapper..."

cat > "$BIN_PATH/hydra-tui" << 'WRAPPER_EOF'
#!/bin/bash
# Hydra TUI Docker Wrapper

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

docker run --rm -it \
  -u "$(id -u):$(id -g)" \
  -v "$PROJECT_ROOT:/workspace" \
  -w /workspace \
  --network host \
WRAPPER_EOF

# Append the image with version (not quoted so variable expands)
echo "  ghcr.io/cardano-scaling/hydra-tui:${HYDRA_VERSION} \\" >> "$BIN_PATH/hydra-tui"
echo '  "$@"' >> "$BIN_PATH/hydra-tui"

chmod +x "$BIN_PATH/hydra-tui"
echo "  ✓ Created $BIN_PATH/hydra-tui"
echo ""

# Step 3: Pull Hydra TUI Docker image
echo "Step 3: Pulling Hydra TUI Docker image..."
DOCKER_TUI_IMAGE="ghcr.io/cardano-scaling/hydra-tui:${HYDRA_VERSION}"
echo "Image: $DOCKER_TUI_IMAGE"
docker pull "$DOCKER_TUI_IMAGE"
echo ""
echo "✓ Docker TUI image pulled"
echo ""

# Step 4: Test hydra-node
echo "Step 4: Testing hydra-node..."
VERSION_OUTPUT=$("$BIN_PATH/hydra-node" --version 2>&1)
if [ -n "$VERSION_OUTPUT" ]; then
    echo "  ✓ hydra-node works! Version: $VERSION_OUTPUT"
else
    echo "  ✗ hydra-node test failed"
    exit 1
fi

# Step 5: Test hydra-tui
echo "Step 5: Testing hydra-tui..."
TUI_VERSION_OUTPUT=$(docker run --rm ghcr.io/cardano-scaling/hydra-tui:${HYDRA_VERSION} --version 2>&1)
if [ -n "$TUI_VERSION_OUTPUT" ]; then
    echo "  ✓ hydra-tui works! Version: $TUI_VERSION_OUTPUT"
else
    echo "  ✗ hydra-tui test failed"
    exit 1
fi

echo ""
echo "---------------------------------------------"
echo "✓ Hydra Node & TUI Docker setup complete!"
echo "---------------------------------------------"
echo ""
echo "You can now use:"
echo "  $BIN_PATH/hydra-node --version"
echo "  $BIN_PATH/hydra-tui --version"
echo ""
