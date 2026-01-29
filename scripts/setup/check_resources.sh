#!/bin/bash
# 01_check_resources.sh
# Analyzes system resources to prevent OOM errors.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== System Resource Analysis ===${NC}"

# 1. CPU
CPU_CORES=$(nproc)
echo -e "CPU Cores: ${YELLOW}$CPU_CORES${NC}"

# 2. RAM
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
FREE_MEM_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
FREE_MEM_MB=$((FREE_MEM_KB / 1024))

echo -e "Total RAM: ${YELLOW}${TOTAL_MEM_MB}MB${NC}"
echo -e "Available RAM: ${YELLOW}${FREE_MEM_MB}MB${NC}"

if [ "$TOTAL_MEM_MB" -lt 1024 ]; then
    echo -e "${RED}WARNING: Less than 1GB of RAM detected. Heavy games (like Minecraft) may crash.${NC}"
    echo -e "${RED}Recommendation: Add a swap file if not already present.${NC}"
fi

# 3. Disk
DISK_AVAIL=$(df -h . | tail -1 | awk '{print $4}')
echo -e "Disk Space Available: ${YELLOW}$DISK_AVAIL${NC}"

echo -e "${GREEN}Resource check complete.${NC}"
echo "-----------------------------------"
