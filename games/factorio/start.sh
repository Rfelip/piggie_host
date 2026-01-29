#!/bin/bash
# Generic Factorio Starter
# Expects: $INSTALL_PATH (where installed), $SAVE_FILE (path to save zip), $SETTINGS_FILE (path to json)

INSTALL_PATH="$1"
SAVE_FILE="$2"
SETTINGS_FILE="$3"

if [ -z "$INSTALL_PATH" ] || [ -z "$SAVE_FILE" ]; then
    echo "Usage: start.sh <install_path> <save_file> [settings_file]"
    exit 1
fi

cd "$INSTALL_PATH/factorio" || exit 1

ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then
    EXEC_CMD="box64 ./bin/x64/factorio"
else
    EXEC_CMD="./bin/x64/factorio"
fi

# The manager will handle the 'screen' session wrapping, this script just runs the game command
# or we can keep screen here. Keeping screen here allows game-specific screen flags.
# However, the manager wants to control the process. 
# Let's output the command to be run, or run it directly.
# Better: Run it directly, let the manager wrap it in screen/systemd.

echo "Starting Factorio..."
echo "Exec: $EXEC_CMD --start-server $SAVE_FILE --server-settings ${SETTINGS_FILE:-data/server-settings.json}"

$EXEC_CMD --start-server "$SAVE_FILE" --server-settings "${SETTINGS_FILE:-data/server-settings.json}"
