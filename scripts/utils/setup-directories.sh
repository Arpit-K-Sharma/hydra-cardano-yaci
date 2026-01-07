#!/bin/sh

set -eu

# Directories Setup Script

# Compute project root 
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

echo "-------------------------------------"
echo "Setting up project directories..."
echo "-------------------------------------"
echo ""

echo "Creating directory structure"

# Participants: try to read from config.sh (Bash array), fallback to defaults
CONFIG_PATH="$ROOT_DIR/scripts/utils/config.sh"
PARTICIPANTS="alice bob carol"
if [ -f "$CONFIG_PATH" ]; then
    LINE=$(grep -E '^PARTICIPANTS=\(' "$CONFIG_PATH" 2>/dev/null || true)
    if [ -n "$LINE" ]; then
        PARTICIPANTS=$(echo "$LINE" | sed -e 's/.*(//' -e 's/).*//' | tr -d '"')
    fi
fi

# Binary directory
mkdir -p bin
echo "✓ Created bin directory"

# Keys directories aligned with generate-keys.sh
mkdir -p keys/payment
mkdir -p keys/hydra
for NAME in $PARTICIPANTS; do
    mkdir -p "keys/payment/$NAME"
    mkdir -p "keys/hydra/$NAME"
    chmod 700 "keys/payment/$NAME" "keys/hydra/$NAME"
done

# Parent directories standard permissions
chmod 755 bin keys
echo "✓ Created keys directory"

# Set ownership to current user to avoid root-owned files (e.g., from Docker)
OWNER_UID=$(id -u)
OWNER_GID=$(id -g)
chown -R "$OWNER_UID:$OWNER_GID" bin keys 2>/dev/null || true

echo ""
echo "-------------------------------------"
echo "Directory setup complete."
echo "-------------------------------------"
echo ""
