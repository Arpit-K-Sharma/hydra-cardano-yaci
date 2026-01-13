#!/bin/bash
# Start Hydra nodes using Docker for all participants defined in config.sh
set -e

# Source config for PARTICIPANTS and HYDRA_VERSION
source "$(dirname "$0")/../utils/config-path.sh"
source "$CONFIG_PATH"

PROJECT_ROOT="$ROOT_DIR"
HYDRA_NODES_DIR="$PROJECT_ROOT/hydra-nodes"
CONFIG_DIR="$PROJECT_ROOT/config"
BASE_PORT=4001

for idx in "${!PARTICIPANTS[@]}"; do
  name=${PARTICIPANTS[$idx]}
  port=$((BASE_PORT + idx))
  docker run -d --rm \
    --platform linux/arm64 \
    --name hydra-node-$name \
    -v "$HYDRA_NODES_DIR:/hydra-nodes" \
    -v "$CONFIG_DIR:/config" \
    --network host \
    ghcr.io/cardano-scaling/hydra-node:$HYDRA_VERSION \
    --node-id $name \
    --api-host 0.0.0.0 \
    --api-port $port \
    --config /config/hydra-$name.yaml \
    "$@"
  echo "Started hydra-node-$name on port $port"
done
