#!/bin/bash
# Stop all running Hydra node Docker containers for participants defined in config.sh
set -e

# Source config for PARTICIPANTS
source "$(dirname "$0")/utils/config-path.sh"
source "$CONFIG_PATH"

for name in "${PARTICIPANTS[@]}"; do
  docker stop hydra-node-$name || true
  echo "Stopped hydra-node-$name"
done
