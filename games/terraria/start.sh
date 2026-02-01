#!/bin/bash
# Terraria Starter
# usage: start.sh <install_path> <save_file> <settings_file>

INSTALL_PATH="$1"
SAVE_FILE="$2"      # Path to world file (e.g., saves/MyWorld.wld)
SETTINGS_FILE="$3"  # Path to serverconfig.txt

echo "--- Terraria Start Script Debug ---"
echo "Target Install Path: $INSTALL_PATH"
echo "Save File: $SAVE_FILE"
echo "Settings File: $SETTINGS_FILE"
echo "Current Directory: $(pwd)"

cd "$INSTALL_PATH" || { echo "ERROR: Could not change to directory $INSTALL_PATH"; exit 1; }
echo "Changed directory to: $(pwd)"

# Check if mono is installed
if ! command -v mono &> /dev/null; then
    echo "ERROR: mono is not installed. Please install mono-complete."
    exit 1
fi

if [ ! -f "./TerrariaServer.exe" ]; then
    echo "ERROR: TerrariaServer.exe not found in $(pwd)"
    ls -F
    exit 1
fi

echo "Starting Terraria Server via Mono..."

# Logic for World file
# If SAVE_FILE exists, use it. If not, launch without -world to allow interactive creation.
if [ -f "$SAVE_FILE" ]; then
    echo "Existing world found: $SAVE_FILE"
    WORLD_ARG="-world \"$SAVE_FILE\""
else
    echo "World file not found at $SAVE_FILE"
    echo "Launching in interactive mode (you will need to create/select a world)..."
    WORLD_ARG=""
    # Ensure the parent directory of the save file exists so it can be saved later
    mkdir -p "$(dirname "$SAVE_FILE")"
fi

# Launch
mono --server --gc=sgen -O=all ./TerrariaServer.exe -config "$SETTINGS_FILE" $WORLD_ARG
