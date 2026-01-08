#!/bin/bash
# Usage: source this file to set ROOT_DIR and CONFIG_PATH in any script

# Find the project root based on the location of the script being executed, not this file
_SCRIPT_SOURCE="${BASH_SOURCE[1]:-$0}"
_SCRIPT_DIR="$(cd "$(dirname "$_SCRIPT_SOURCE")" && pwd)"
# Always resolve ROOT_DIR based on the location of this sourced file
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$_SCRIPT_DIR/../.." && pwd)"
CONFIG_PATH="$ROOT_DIR/scripts/utils/config.sh"
