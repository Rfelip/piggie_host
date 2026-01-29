#!/bin/bash
# Factorio Update Script
# Updates the Factorio installation to the latest stable version.

INSTALL_PATH="$1"
VERSION="${2:-stable}"
FACTORIO_URL="https://www.factorio.com/get-download/$VERSION/headless/linux64"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Updating Factorio ===${NC}"
echo "Target: $INSTALL_PATH"

if [ ! -d "$INSTALL_PATH" ]; then
    echo -e "${RED}Error: Install path does not exist. Run install.sh first.${NC}"
    exit 1
fi

cd "$INSTALL_PATH" || exit 1

# 1. Download
echo "Downloading latest stable..."
rm factorio_headless.tar.xz 2>/dev/null
wget -O factorio_headless.tar.xz "$FACTORIO_URL"

if [ $? -ne 0 ]; then
    echo -e "${RED}Download failed.${NC}"
    exit 1
fi

# 2. Backup Binaries (Optional/Safety)
# Moving bin to bin_old could be done, but tar overwrite is usually fine.
# We will just extract over.

# 3. Extract
echo "Extracting update..."
tar -xJf factorio_headless.tar.xz

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Update extracted successfully.${NC}"
    rm factorio_headless.tar.xz
else
    echo -e "${RED}Extraction failed.${NC}"
    exit 1
fi

echo -e "${GREEN}Factorio updated to latest stable.${NC}"
