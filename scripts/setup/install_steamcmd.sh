#!/bin/bash
# SteamCMD Installer Script

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Installing SteamCMD ===${NC}"

# Check if already installed
if command -v steamcmd &> /dev/null || [ -f "$HOME/steamcmd/steamcmd.sh" ]; then
    echo -e "${GREEN}SteamCMD is already installed. Skipping.${NC}"
    exit 0
fi

# 1. Detect Package Manager
LOG_FILE="/tmp/install_steamcmd.log"
if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    echo "Configuring repositories and installing SteamCMD (logging to $LOG_FILE)..."
    sudo add-apt-repository multilib -y > "$LOG_FILE" 2>&1
    sudo dpkg --add-architecture i386 >> "$LOG_FILE" 2>&1
    sudo apt-get update >> "$LOG_FILE" 2>&1
    # Note: steamcmd on Debian/Ubuntu often requires accepting a license interactively
    # We use debconf-set-selections to try and automate it
    echo steamcmd steam/question select I AGREE | sudo debconf-set-selections >> "$LOG_FILE" 2>&1
    echo steamcmd steam/license note '' | sudo debconf-set-selections >> "$LOG_FILE" 2>&1
    sudo apt-get install -y steamcmd >> "$LOG_FILE" 2>&1
    
    # Symlink for easier access
    [ ! -f /usr/local/bin/steamcmd ] && sudo ln -s /usr/games/steamcmd /usr/local/bin/steamcmd >> "$LOG_FILE" 2>&1

elif command -v pacman &> /dev/null; then
    # Arch Linux
    # Check if in AUR or main repos. Usually it's in AUR or a custom repo.
    # For now, we'll try manual install to be safe on ARM/Headless
    echo "Arch Linux detected. Attempting manual installation of SteamCMD..."
    mkdir -p ~/steamcmd
    cd ~/steamcmd || exit
    wget -qO- "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - >> "$LOG_FILE" 2>&1
    
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    echo "Installing SteamCMD (logging to $LOG_FILE)..."
    sudo yum install -y steamcmd >> "$LOG_FILE" 2>&1 || sudo yum install -y glibc.i686 libstdc++.i686 >> "$LOG_FILE" 2>&1
fi

# Verification
if command -v steamcmd &> /dev/null || [ -f ~/steamcmd/steamcmd.sh ]; then
    echo -e "${GREEN}SteamCMD installed successfully.${NC}"
else
    # Manual Fallback for any other system
    echo "Performing manual fallback installation..."
    mkdir -p ~/steamcmd
    cd ~/steamcmd || exit
    wget -qO- "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    echo -e "${GREEN}SteamCMD installed to ~/steamcmd/steamcmd.sh${NC}"
fi
