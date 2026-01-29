#!/bin/bash
# SteamCMD Installer Script

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Installing SteamCMD ===${NC}"

# 1. Detect Package Manager
if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    sudo add-apt-repository multilib -y 2>/dev/null
    sudo dpkg --add-architecture i386 2>/dev/null
    sudo apt-get update
    # Note: steamcmd on Debian/Ubuntu often requires accepting a license interactively
    # We use debconf-set-selections to try and automate it
    echo steamcmd steam/question select I AGREE | sudo debconf-set-selections
    echo steamcmd steam/license note '' | sudo debconf-set-selections
    sudo apt-get install -y steamcmd
    
    # Symlink for easier access
    [ ! -f /usr/local/bin/steamcmd ] && sudo ln -s /usr/games/steamcmd /usr/local/bin/steamcmd

elif command -v pacman &> /dev/null; then
    # Arch Linux
    # Check if in AUR or main repos. Usually it's in AUR or a custom repo.
    # For now, we'll try manual install to be safe on ARM/Headless
    echo "Arch Linux detected. Attempting manual installation of SteamCMD..."
    mkdir -p ~/steamcmd
    cd ~/steamcmd || exit
    wget -qO- "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    sudo yum install -y steamcmd || sudo yum install -y glibc.i686 libstdc++.i686
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
