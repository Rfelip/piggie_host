#!/bin/bash
# Minecraft Installer
# Installs Java 21 and downloads the Server JAR.

INSTALL_PATH="$1"
MC_VERSION="1.21.4"
# URL for 1.21.4 (This is dynamic and expires, usually. Using a known stable mirror or direct Mojang link if possible)
# Mojang launcher meta gives this. For simplicity in this script, I will use the direct link for 1.21.4.
DOWNLOAD_URL="https://piston-data.mojang.com/v1/objects/4707d00eb834b446575d89a61a11b5d548d8c001/server.jar"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Minecraft Setup ===${NC}"

# 1. Install Java (Dependencies)
if command -v apt-get &> /dev/null; then
    echo "Installing OpenJDK 21 (Debian/Ubuntu)..."
    sudo apt-get update
    sudo apt-get install -y openjdk-21-jre-headless
    
    if [ $? -eq 0 ]; then
        # Mark deps as installed
        sed -i 's/^dependencies_installed=.*/dependencies_installed=1/' "$(dirname "$0")/install_config.ini"
    fi
elif command -v yum &> /dev/null; then
    echo "Installing Java 21 (CentOS/RHEL)..."
    # AWS Amazon Linux 2023 or similar might need different package names
    sudo yum install -y java-21-openjdk-headless
    
    if [ $? -eq 0 ]; then
        sed -i 's/^dependencies_installed=.*/dependencies_installed=1/' "$(dirname "$0")/install_config.ini"
    fi
else
    echo -e "${RED}Unsupported package manager. Please install Java 21 manually.${NC}"
fi

# Verify Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}Java not found. Please install Java 21 manually.${NC}"
    exit 1
fi

JAVA_VER=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VER" -lt 21 ]; then
    echo -e "${RED}Warning: Java version $JAVA_VER detected. MC 1.21+ requires Java 21.${NC}"
fi

# 2. Download Server
mkdir -p "$INSTALL_PATH"
cd "$INSTALL_PATH" || exit 1

if [ -f "server.jar" ]; then
    echo "server.jar already exists."
else
    echo "Downloading Minecraft Server $MC_VERSION..."
    wget -O server.jar "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Download failed.${NC}"
        exit 1
    fi
fi

# 3. Accept EULA (Required for headless run)
echo "eula=true" > eula.txt
echo "Accepted EULA (eula.txt created)."

# Mark game as installed
sed -i 's/^game_installed=.*/game_installed=1/' "$(dirname "$0")/install_config.ini"

echo -e "${GREEN}Minecraft installed successfully at $INSTALL_PATH${NC}"
