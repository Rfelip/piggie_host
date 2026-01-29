#!/bin/bash
# Terraria Starter
# usage: start.sh <install_path> <save_file> <settings_file>

INSTALL_PATH="$1"
SAVE_FILE="$2"      # Path to world file (e.g., saves/MyWorld.wld)
SETTINGS_FILE="$3"  # Path to serverconfig.txt

cd "$INSTALL_PATH" || exit 1

ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then
    if ! command -v box64 &> /dev/null; then
        echo "Error: aarch64 detected but box64 is not installed."
        echo "Please install box64 to run x86_64 Terraria on ARM."
        exit 1
    fi
    EXEC_CMD="box64 ./TerrariaServer.bin.x86_64"
else
    EXEC_CMD="./TerrariaServer.bin.x86_64"
fi

# Check permissions
chmod +x ./TerrariaServer.bin.x86_64

echo "Starting Terraria Server..."
echo "World: $SAVE_FILE"
echo "Config: $SETTINGS_FILE"

# Terraria needs absolute paths sometimes, or relative to CWD.
# We are in INSTALL_PATH.
# The manager passed absolute paths for SAVE_FILE and SETTINGS_FILE in manager.sh (ABS_SAVE_FILE).

# Launch
# -x64 is implicit in the binary name
# We pass -config and -world. 
# Note: If -world is set, it overrides config.

$EXEC_CMD -config "$SETTINGS_FILE" -world "$SAVE_FILE"
