#!/bin/bash
# Minecraft Starter
# usage: start.sh <install_path> <save_file> <settings_file>

INSTALL_PATH="$1"
SAVE_FILE="$2"      # Unused for MC (MC uses 'world' folder in CWD usually, or level-name in server.properties)
SETTINGS_FILE="$3"  # We source this for RAM config

cd "$INSTALL_PATH" || exit 1

# Default RAM
RAM_MIN="1024M"
RAM_MAX="2048M"

# Load Settings
if [ -f "$SETTINGS_FILE" ]; then
    source "$SETTINGS_FILE"
fi

# Override RAM if set in settings.sh
# Expected vars: MC_RAM_MIN, MC_RAM_MAX
if [ -n "$MC_RAM_MIN" ]; then RAM_MIN="$MC_RAM_MIN"; fi
if [ -n "$MC_RAM_MAX" ]; then RAM_MAX="$MC_RAM_MAX"; fi

echo "Starting Minecraft Server..."
echo "RAM: $RAM_MIN - $RAM_MAX"

# Note: We rely on the manager to wrap this in screen/tmux.
# We just run the process.
exec java -Xms$RAM_MIN -Xmx$RAM_MAX -jar server.jar nogui
