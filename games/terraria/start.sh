#!/bin/bash
# Terraria Starter
# usage: start.sh <install_path> <save_file> <settings_file>

INSTALL_PATH="$1"
SAVE_FILE="$2"      # Path to world file (e.g., saves/MyWorld.wld)
SETTINGS_FILE="$3"  # Path to serverconfig.txt

# Fallback for settings file
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Warning: Settings file $SETTINGS_FILE not found."
    if [ -f "$(dirname "$SETTINGS_FILE")/serverconfig.txt" ]; then
        SETTINGS_FILE="$(dirname "$SETTINGS_FILE")/serverconfig.txt"
        echo "Falling back to: $SETTINGS_FILE"
    fi
fi

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
# Terraria worlds can be in the system default or our instance saves folder
TERRARIA_SAVES_DIR="$HOME/.local/share/Terraria/Worlds"

if [[ "$SAVE_FILE" == */* ]]; then
    # It's a path (possibly relative to the project root or absolute)
    if [[ "$SAVE_FILE" == /* ]]; then
        ACTUAL_SAVE_PATH="$SAVE_FILE"
    else
        # Try relative to project root (where we started)
        ACTUAL_SAVE_PATH="$OLDPWD/$SAVE_FILE"
    fi
else
    # It's a simple name. Check local first, then system default.
    # OLDPWD is the directory we were in before 'cd $INSTALL_PATH'
    INSTANCE_SAVE="$OLDPWD/configs/$SAVE_FILE/saves/${SAVE_FILE}.wld"
    SYSTEM_SAVE="$TERRARIA_SAVES_DIR/${SAVE_FILE}.wld"
    
    if [ -f "$INSTANCE_SAVE" ]; then
        ACTUAL_SAVE_PATH="$INSTANCE_SAVE"
    else
        ACTUAL_SAVE_PATH="$SYSTEM_SAVE"
    fi
fi

if [ -f "$ACTUAL_SAVE_PATH" ]; then
    # Convert to absolute path to be certain
    ACTUAL_SAVE_PATH=$(realpath "$ACTUAL_SAVE_PATH")
    echo "Found world file: $ACTUAL_SAVE_PATH"
    WORLD_ARG="-world $ACTUAL_SAVE_PATH"
else
    echo "World file not found at $ACTUAL_SAVE_PATH"
    echo "Checking for any .wld in the world name directory..."
    # Fallback: if SAVE_FILE is a name, look for ANY .wld in its config/saves folder
    POTENTIAL_SAVE=$(find "$OLDPWD/configs/$SAVE_FILE/saves" -name "*.wld" -print -quit 2>/dev/null)
    if [ -n "$POTENTIAL_SAVE" ]; then
        echo "Found potential world: $POTENTIAL_SAVE"
        WORLD_ARG="-world \"$POTENTIAL_SAVE\""
    else
        echo "Launching in interactive mode (you will need to create/select a world)..."
        WORLD_ARG=""
        mkdir -p "$(dirname "$ACTUAL_SAVE_PATH")"
    fi
fi

# Launch
# We use 'eval' or pass arguments directly to ensure quotes are handled correctly by the shell vs the mono app
echo "Executing: mono --server --gc=sgen -O=all ./TerrariaServer.exe -config \"$SETTINGS_FILE\" $WORLD_ARG"
mono --server --gc=sgen -O=all ./TerrariaServer.exe -config "$SETTINGS_FILE" $WORLD_ARG
