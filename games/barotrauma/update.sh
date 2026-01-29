#!/bin/bash
# Barotrauma Update Script
# Uses SteamCMD to update

INSTALL_PATH="$1"
APP_ID="1026340"

# Find SteamCMD
if command -v steamcmd &> /dev/null; then STEAM_CMD="steamcmd"; else STEAM_CMD="$HOME/steamcmd/steamcmd.sh"; fi

ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then STEAM_CMD="box86 $STEAM_CMD"; fi

echo "Updating Barotrauma..."
$STEAM_CMD +force_install_dir "$INSTALL_PATH" +login anonymous +app_update $APP_ID +quit

if [ $? -eq 0 ]; then
    echo "Update successful."
else
    echo "Update failed."
    exit 1
fi
