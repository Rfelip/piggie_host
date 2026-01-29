#!/bin/bash
# Barotrauma Starter
# usage: start.sh <install_path> <save_file> <settings_file>

INSTALL_PATH="$1"

cd "$INSTALL_PATH" || exit 1

ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then
    if ! command -v box64 &> /dev/null; then
        echo "Error: aarch64 detected but box64 is not installed."
        exit 1
    fi
    EXEC_CMD="box64 ./Barotrauma-Dedicated-Server"
else
    EXEC_CMD="./Barotrauma-Dedicated-Server"
fi

chmod +x ./Barotrauma-Dedicated-Server

echo "Starting Barotrauma Server..."
# Barotrauma uses serversettings.xml and dedicatedserver_settings.xml by default in CWD
$EXEC_CMD
