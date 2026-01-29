#!/bin/bash

# Universal Game Server Manager (Bash Edition)
# Resolve paths relative to the script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$PROJECT_ROOT/configs"
GAMES_DIR="$PROJECT_ROOT/games"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Universal Game Server Manager ===${NC}"

# 1. List available configurations
configs=()
while IFS= read -r -d $'\0' dir; do
    if [ -f "$dir/settings.sh" ]; then
        configs+=("$(basename "$dir")")
    fi
done < <(find "$CONFIGS_DIR" -maxdepth 1 -type d -not -path "$CONFIGS_DIR" -print0)

if [ ${#configs[@]} -eq 0 ]; then
    echo -e "${RED}No server configurations found in $CONFIGS_DIR/*/settings.sh${NC}"
    exit 1
fi

echo "Available Servers:"
for i in "${!configs[@]}"; do
    # Source settings briefly to get description if available
    (
        source "$CONFIGS_DIR/${configs[$i]}/settings.sh"
        echo -e "$((i+1))) ${configs[$i]} [${GAME:-unknown}] - ${DESCRIPTION:-No description}"
    )
done

# 2. Select a server
read -p "Select a server (1-${#configs[@]}): " choice
if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#configs[@]}" ]; then
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
fi

SELECTED_INSTANCE="${configs[$((choice-1))]}"
INSTANCE_DIR="$CONFIGS_DIR/$SELECTED_INSTANCE"

# 3. Load configuration
source "$INSTANCE_DIR/settings.sh"

# 4. Check installation
INSTALL_SCRIPT="$GAMES_DIR/$GAME/install.sh"
START_SCRIPT="$GAMES_DIR/$GAME/start.sh"

if [ ! -f "$INSTALL_SCRIPT" ] || [ ! -f "$START_SCRIPT" ]; then
    echo -e "${RED}Error: Game scripts for '$GAME' not found in $GAMES_DIR/$GAME/${NC}"
    exit 1
fi

# Use default install path if not set
INSTALL_PATH="${INSTALL_PATH:-$HOME/servers/$SELECTED_INSTANCE}"

if [ ! -d "$INSTALL_PATH" ]; then
    echo -e "${BLUE}Server not found at $INSTALL_PATH. Running installer...${NC}"
    chmod +x "$INSTALL_SCRIPT"
    "$INSTALL_SCRIPT" "$INSTALL_PATH"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Installation failed.${NC}"
        exit 1
    fi
fi

# 5. Start server in screen
SESSION_NAME="game-$SELECTED_INSTANCE"

if screen -list | grep -q "\.${SESSION_NAME}\s"; then
    echo -e "${RED}Error: Screen session '$SESSION_NAME' is already running.${NC}"
    exit 1
fi

echo -e "${GREEN}Starting $SELECTED_INSTANCE...${NC}"
chmod +x "$START_SCRIPT"

# Resolve absolute paths for the game scripts
ABS_INSTANCE_DIR=$(realpath "$INSTANCE_DIR")
ABS_SAVE_FILE="${ABS_INSTANCE_DIR}/${SAVE_FILE}"
ABS_SETTINGS_FILE="${ABS_INSTANCE_DIR}/${SETTINGS_FILE}"

screen -dmS "$SESSION_NAME" bash -c "'$START_SCRIPT' '$INSTALL_PATH' '$ABS_SAVE_FILE' '$ABS_SETTINGS_FILE' || { echo 'Server exited with error'; read -p 'Press Enter...'; }"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Server started in screen session '$SESSION_NAME'.${NC}"
    echo "Attach with: screen -r $SESSION_NAME"
else
    echo -e "${RED}Failed to start screen session.${NC}"
fi
