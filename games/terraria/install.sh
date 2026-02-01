#!/bin/bash
# Terraria Installer
# Installs Terraria Dedicated Server (Vanilla)

INSTALL_PATH="$1"
# Update this URL when new versions release
DOWNLOAD_URL="https://terraria.org/api/download/pc-dedicated-server/terraria-server-1453.zip"
ZIP_NAME="terraria-server.zip"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Terraria Setup ===${NC}"

# 1. Dependencies
# Terraria needs unzip and mono.
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y unzip mono-complete
elif command -v yum &> /dev/null; then
    sudo yum install -y unzip mono-core
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm unzip mono
fi

sed -i 's/^dependencies_installed=.*/dependencies_installed=1/' "$(dirname "$0")/install_config.ini"

# 2. Download
mkdir -p "$INSTALL_PATH"
cd "$INSTALL_PATH" || exit 1

if [ -f "$ZIP_NAME" ]; then
    echo "Archive exists, skipping download."
else
    echo "Downloading Terraria Server..."
    wget -O "$ZIP_NAME" "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Download failed.${NC}"
        exit 1
    fi
fi

# 3. Extract
# The zip usually contains a '1449' folder. We want to flatten it or find the linux dir.
# Structure: 1449/Linux/TerrariaServer.bin.x86_64
echo "Extracting..."
unzip -o "$ZIP_NAME"
# Find the Linux folder and move contents up
LINUX_DIR=$(find . -type d -name "Linux" | head -n 1)

if [ -d "$LINUX_DIR" ]; then
    echo "Found Linux binaries in $LINUX_DIR"
    cp -r "$LINUX_DIR"/* .
    # Cleanup raw folder
    rm -rf "$(dirname "$LINUX_DIR")" 2>/dev/null
    # Cleanup archive
    rm "$ZIP_NAME"

    # --- Mono Sync Fix ---
    # To prevent "runtime and class libraries out of sync" errors
    echo "Applying Mono compatibility fixes..."
    rm -f System*.dll
    rm -f Mono*.dll
    rm -f monoconfig
    rm -f mscorlib.dll
    # WindowsBase.dll and FNA.dll should remain
else
    echo -e "${RED}Error: Could not locate Linux server files in archive.${NC}"
    exit 1
fi

# Make executable
chmod +x TerrariaServer.bin.x86_64 2>/dev/null
chmod +x TerrariaServer.exe 2>/dev/null

# Create default config if not exists
if [ ! -f "serverconfig.txt" ]; then
    echo "Creating default serverconfig.txt..."
    cat << EOF > serverconfig.txt
# Terraria Server Config
world=saves/world1.wld
autocreate=2
worldname=TerrariaWorld
difficulty=0
maxplayers=8
port=7777
password=
motd=Welcome to Terraria
secure=1
EOF
fi

mkdir -p saves

# Mark installed
sed -i 's/^game_installed=.*/game_installed=1/' "$(dirname "$0")/install_config.ini"

echo -e "${GREEN}Terraria installed successfully at $INSTALL_PATH${NC}"
