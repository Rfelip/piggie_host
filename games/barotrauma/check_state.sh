#!/bin/bash
# Check if Barotrauma is installed
GAME_DIR="$1"
CONFIG_FILE="$GAME_DIR/install_config.ini"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    if [ "$game_installed" -eq 1 ]; then
        exit 0
    fi
fi
exit 1
