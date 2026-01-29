#!/bin/bash
# Server-side Backup Script
# Usage: ./backup.sh <instance_name> [retention_days]

INSTANCE_NAME="$1"
RETENTION_DAYS="${2:-7}" # Default to keeping 7 days of backups

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/configs/$INSTANCE_NAME"
BACKUP_DIR="$PROJECT_ROOT/backups/$INSTANCE_NAME"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$INSTANCE_NAME" ] || [ ! -d "$CONFIG_DIR" ]; then
    echo "Usage: $0 <instance_name> [retention_days]"
    exit 1
fi

# Load settings to find the SAVE_FILE
source "$CONFIG_DIR/settings.sh"

# Resolve the absolute path of the save file
# SAVE_FILE in settings is relative to CONFIG_DIR usually
SAVE_PATH="$CONFIG_DIR/$SAVE_FILE"

if [ ! -f "$SAVE_PATH" ]; then
    echo -e "${RED}Error: Save file not found at $SAVE_PATH${NC}"
    exit 1
fi

# Prepare Backup Directory
mkdir -p "$BACKUP_DIR"

# Timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME=$(basename "$SAVE_PATH")
BACKUP_NAME="${FILENAME}_${TIMESTAMP}.zip" # We zip everything for consistency

echo "Backing up $INSTANCE_NAME..."
echo "Source: $SAVE_PATH"
echo "Dest:   $BACKUP_DIR/$BACKUP_NAME"

# Create Archive
# If source is a folder (Minecraft/Terraria), we zip it.
# If source is a zip (Factorio), we copy it (or re-zip? Copy is faster).

if [ -d "$SAVE_PATH" ]; then
    # It's a directory (e.g. Minecraft World)
    cd "$(dirname "$SAVE_PATH")"
    zip -r "$BACKUP_DIR/$BACKUP_NAME" "$(basename "$SAVE_PATH")" -q
else
    # It's a file (e.g. Factorio Zip)
    # If it's already a zip, just copy it to the backup name
    cp "$SAVE_PATH" "$BACKUP_DIR/$BACKUP_NAME"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Backup successful.${NC}"
else
    echo -e "${RED}Backup failed.${NC}"
    exit 1
fi

# --- Cloud Backup (Rclone) ---
if command -v rclone &> /dev/null; then
    # Check if 'gdrive' remote exists
    if rclone listremotes | grep -q "^gdrive:"; then
        echo "Uploading to Google Drive (gdrive:game_backups/$INSTANCE_NAME)..."
        
        # Upload
        rclone copy "$BACKUP_DIR/$BACKUP_NAME" "gdrive:game_backups/$INSTANCE_NAME"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Cloud upload successful.${NC}"
            
            # Cloud Retention: Keep only last 3 days
            echo "Cleaning up cloud backups older than 3 days..."
            rclone delete "gdrive:game_backups/$INSTANCE_NAME" --min-age 3d
        else
            echo -e "${RED}Cloud upload failed.${NC}"
        fi
    fi
fi

# Retention Policy: Delete old local backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "*_${FILENAME}_*.zip" -type f -mtime +$RETENTION_DAYS -delete
# Note: The pattern matches our naming convention to avoid deleting wrong files

echo "Done."
