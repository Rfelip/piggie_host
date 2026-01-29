#!/bin/bash
# Minecraft Update Script
# Updates the server.jar.
# NOTE: This script currently updates to 1.21.4 (Hardcoded).
# In a production env, you'd want to scrape the version manifest or accept a URL arg.

INSTALL_PATH="$1"
DOWNLOAD_URL="https://piston-data.mojang.com/v1/objects/4707d00eb834b446575d89a61a11b5d548d8c001/server.jar"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Updating Minecraft ===${NC}"
echo "Target: $INSTALL_PATH"

if [ ! -d "$INSTALL_PATH" ]; then
    echo -e "${RED}Error: Install path does not exist.${NC}"
    exit 1
fi

cd "$INSTALL_PATH" || exit 1

# 1. Backup old jar
if [ -f "server.jar" ]; then
    mv server.jar "server.jar.bak.$(date +%F_%H-%M-%S)"
    echo "Backed up old server.jar"
fi

# 2. Download Logic
TARGET_FILE="server.jar"
download_success=0
CURRENT_URL="$DOWNLOAD_URL"

while [ $download_success -eq 0 ]; do
    echo "Downloading from: $CURRENT_URL"
    wget -O "$TARGET_FILE" "$CURRENT_URL"
    
    if [ $? -eq 0 ]; then
        download_success=1
        echo -e "${GREEN}Update successful.${NC}"
    else
        echo -e "${RED}Download failed.${NC}"
        echo -e "${YELLOW}Options:${NC}"
        echo "1) Retry with custom URL"
        echo "2) Cancel (Restore Backup)"
        read -p "Select option: " retry_choice
        
        if [ "$retry_choice" == "1" ]; then
            read -p "Enter new URL: " new_url
            if [ -n "$new_url" ]; then
                CURRENT_URL="$new_url"
            else
                echo "Invalid URL."
            fi
        else
            echo "Update cancelled. Restoring backup..."
            if ls server.jar.bak.* 1> /dev/null 2>&1; then
                mv server.jar.bak.* server.jar
            fi
            exit 1
        fi
    fi
done
