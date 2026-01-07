#!/bin/bash
# Usage: source this file to set ROOT_DIR and CONFIG_PATH in any script

# Find the project root (assumes this file is in scripts/utils/)
ROOT_DIR="$(dirname $(dirname $(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")))"
CONFIG_PATH="$ROOT_DIR/scripts/utils/config.sh"
