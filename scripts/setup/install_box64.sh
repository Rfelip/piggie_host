#!/bin/bash
# Box64 Installer (Source Build)
# Compiles Box64 from source for ARM64/Aarch64 systems.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Box64 Installer ===${NC}"

# Check if already installed
if command -v box64 &> /dev/null; then
    echo -e "${GREEN}Box64 is already installed. Skipping source build.${NC}"
    exit 0
fi

# 0. Arch Check
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo -e "${RED}Error: Box64 is only for aarch64 (ARM64) systems. Detected: $ARCH${NC}"
    exit 1
fi

# 1. Install Build Dependencies
LOG_FILE="/tmp/install_box64.log"
echo "Installing build dependencies (logging to $LOG_FILE)..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update > "$LOG_FILE" 2>&1
    sudo apt-get install -y git cmake make python3 gcc build-essential >> "$LOG_FILE" 2>&1
elif command -v pacman &> /dev/null; then
    sudo pacman -Sy --noconfirm git cmake make python gcc base-devel >> "$LOG_FILE" 2>&1
elif command -v yum &> /dev/null; then
    sudo yum install -y git cmake make python3 gcc >> "$LOG_FILE" 2>&1
fi

# 2. Clone Source
BUILD_DIR="$HOME/box64_build"
echo "Cloning Box64 repository to $BUILD_DIR..."
rm -rf "$BUILD_DIR" 2>/dev/null
git clone https://github.com/ptitSeb/box64.git "$BUILD_DIR" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to clone repository. Check $LOG_FILE${NC}"
    exit 1
fi

cd "$BUILD_DIR" || exit 1

# 3. Configure (CMake)
echo "Configuring build..."
mkdir -p build && cd build
# Generic ARM64 build flags.
# For Oracle Ampere (Altra), we can let CMake auto-detect or force ARM64.
cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}CMake configuration failed. Check $LOG_FILE${NC}"
    exit 1
fi

# 4. Compile (Make)
echo "Compiling... (This may take a while, progress logged to $LOG_FILE)"
# Use -j$(nproc) to use all cores (4 on Oracle Ampere)
make -j$(nproc) >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed. Check $LOG_FILE${NC}"
    exit 1
fi

# 5. Install
echo "Installing..."
sudo make install >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}Installation failed.${NC}"
    exit 1
fi

# 6. Restart binfmt (if systemd exists)
if command -v systemctl &> /dev/null; then
    echo "Restarting systemd-binfmt..."
    sudo systemctl restart systemd-binfmt
fi

# 7. Verification & Cleanup
if command -v box64 &> /dev/null; then
    echo -e "${GREEN}Box64 installed successfully!${NC}"
    box64 --version
    
    echo "Cleaning up build directory..."
    rm -rf "$BUILD_DIR"
else
    echo -e "${RED}Installation verified failed. Box64 binary not found.${NC}"
    exit 1
fi
