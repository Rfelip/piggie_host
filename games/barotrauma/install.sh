#!/bin/bash
# Barotrauma Installer (Anonymous)

INSTALL_PATH="$1"
APP_ID="1026340"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Barotrauma Setup ===${NC}"

# 1. Dependencies (SteamCMD)
if ! command -v steamcmd &> /dev/null && [ ! -f ~/steamcmd/steamcmd.sh ]; then
    echo "SteamCMD not found. Running installer..."
    "$(dirname "$0")/../../scripts/setup/install_steamcmd.sh"
fi

# Determine SteamCMD command
if command -v steamcmd &> /dev/null; then
    STEAM_CMD="steamcmd"
else
    STEAM_CMD="$HOME/steamcmd/steamcmd.sh"
fi

# ARM Check for SteamCMD (SteamCMD is 32-bit x86)
ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then
    if ! command -v box86 &> /dev/null; then
        echo -e "${RED}Error: Running SteamCMD on ARM requires 'box86'.${NC}"
        echo "Please install box86 to proceed with SteamCMD games."
        exit 1
    fi
    # On ARM, we wrap the steamcmd script in box86
    STEAM_CMD="box86 $STEAM_CMD"
fi

# 2. Run Installation
mkdir -p "$INSTALL_PATH"
echo "Installing Barotrauma Dedicated Server (Anonymous)..."

$STEAM_CMD +force_install_dir "$INSTALL_PATH" +login anonymous +app_update $APP_ID validate +quit

if [ $? -eq 0 ]; then
    update_install_state "barotrauma" "game_installed" "1"
    echo -e "${GREEN}Barotrauma installed successfully.${NC}"
else
    echo -e "${RED}Installation failed.${NC}"
    exit 1
fi

# 3. Accept License/Setup
# Barotrauma might need some initial files, but steamcmd handles the base.
mkdir -p "$INSTALL_PATH/Saves"

sed -i 's/^game_installed=.*/game_installed=1/' "$(dirname "$0")/install_config.ini"
