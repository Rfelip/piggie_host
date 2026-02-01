#!/bin/bash
# 02_install_deps.sh
# Installs dependencies and handles screen/tmux fallback.

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}=== Installing Dependencies ===${NC}"

# Detect Package Manager
if command -v apt-get &> /dev/null; then
    PKG_MGR="apt-get"
    INSTALL_CMD="sudo apt-get install -y"
    UPDATE_CMD="sudo apt-get update"
elif command -v yum &> /dev/null; then
    PKG_MGR="yum"
    INSTALL_CMD="sudo yum install -y"
    UPDATE_CMD="sudo yum check-update"
elif command -v pacman &> /dev/null; then
    PKG_MGR="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    UPDATE_CMD="sudo pacman -Sy"
else
    echo -e "${RED}Warning: Unsupported package manager. Please install dependencies manually.${NC}"
    exit 0
fi

# Update
if [ -n "$PKG_MGR" ]; then
    echo "Updating package lists..."
    $UPDATE_CMD
    
    echo "Installing core tools..."
    if [ "$PKG_MGR" == "pacman" ]; then
        $INSTALL_CMD wget tar xz git nano zip unzip cronie rclone mono
        sudo systemctl enable --now cronie
    elif [ "$PKG_MGR" == "apt-get" ]; then
        $INSTALL_CMD wget tar xz-utils git nano zip unzip cron rclone mono-complete
    else
        $INSTALL_CMD wget tar xz-utils git nano zip unzip cron rclone
        # Mono might be named differently on yum, usually mono-core or mono-complete
        $INSTALL_CMD mono-core || echo "Warning: mono-core not found, skipping."
    fi
    
    echo "Attempting to install 'screen'..."
    $INSTALL_CMD screen
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install 'screen'. Attempting 'tmux'...${NC}"
        $INSTALL_CMD tmux
        if [ $? -ne 0 ]; then
             echo -e "${RED}Failed to install 'tmux'. Terminal multiplexing unavailable.${NC}"
             exit 1
        fi
    fi
fi

# Final Check
if command -v screen &> /dev/null; then
    echo -e "${GREEN}Dependency 'screen' is available.${NC}"
elif command -v tmux &> /dev/null; then
    echo -e "${GREEN}Dependency 'tmux' is available (fallback).${NC}"
else
    echo -e "${RED}Critical: Neither 'screen' nor 'tmux' is available.${NC}"
    exit 1
fi

# ARM Compatibility Check
ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then
    if ! command -v box64 &> /dev/null; then
        echo -e "${YELLOW}[WARNING] aarch64 architecture detected but 'box64' is missing.${NC}"
        echo -e "${YELLOW}You will need 'box64' to run x86_64 games (Factorio, Terraria).${NC}"
        echo -e "${YELLOW}Please install it manually (e.g., via AUR or source).${NC}"
    else
        echo -e "${GREEN}ARM Compatibility: box64 is installed.${NC}"
    fi
fi

echo -e "${GREEN}Dependency setup complete.${NC}"
