#!/bin/bash
# Check if game is installed based on config
# Returns 0 if installed (green), 1 if not (default/red)

GAME_DIR="$1"
CONFIG_FILE="$GAME_DIR/install_config.ini"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    if [ "$game_installed" -eq 1 ]; then
        exit 0
    fi
fi
exit 1
