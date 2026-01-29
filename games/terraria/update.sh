#!/bin/bash
# Terraria Update Script
# Updates Terraria Server binaries.

INSTALL_PATH="$1"
DOWNLOAD_URL="https://terraria.org/api/download/pc-dedicated-server/terraria-server-1449.zip"
ZIP_NAME="terraria-server.zip"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Updating Terraria ===${NC}"
echo "Target: $INSTALL_PATH"

if [ ! -d "$INSTALL_PATH" ]; then
    echo -e "${RED}Error: Install path does not exist.${NC}"
    exit 1
fi

cd "$INSTALL_PATH" || exit 1

# 1. Download
echo "Downloading Terraria Server..."
rm "$ZIP_NAME" 2>/dev/null
wget -O "$ZIP_NAME" "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    echo -e "${RED}Download failed.${NC}"
    exit 1
fi

# 2. Extract
echo "Extracting..."
unzip -o "$ZIP_NAME"

# Move Linux files
LINUX_DIR=$(find . -type d -name "Linux" | head -n 1)

if [ -d "$LINUX_DIR" ]; then
    echo "Updating binaries..."
    cp -r "$LINUX_DIR"/* .
    
    # Cleanup
    rm -rf "$(dirname "$LINUX_DIR")" 2>/dev/null
    rm "$ZIP_NAME"
    
    # Ensure executable
    chmod +x TerrariaServer.bin.x86_64
    
    echo -e "${GREEN}Update successful.${NC}"
else
    echo -e "${RED}Error: Could not locate Linux server files in archive.${NC}"
    exit 1
fi
