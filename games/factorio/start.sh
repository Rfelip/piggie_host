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
    if ! command -v box64 &> /dev/null; then
        echo "Error: aarch64 detected but box64 is not installed."
        echo "Please install box64 to run x86_64 Factorio on ARM."
        exit 1
    fi
    EXEC_CMD="box64 ./bin/x64/factorio"
else
    EXEC_CMD="./bin/x64/factorio"
fi

echo "Starting Factorio..."
echo "Exec: $EXEC_CMD --start-server $SAVE_FILE --server-settings ${SETTINGS_FILE:-data/server-settings.json}"

$EXEC_CMD --start-server "$SAVE_FILE" --server-settings "${SETTINGS_FILE:-data/server-settings.json}"
