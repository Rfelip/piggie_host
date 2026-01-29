#!/bin/bash
# Universal Game Server Manager (Interactive Remote)

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$PROJECT_ROOT/configs"
GAMES_DIR="$PROJECT_ROOT/games"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Helper Functions ---

function get_game_status() {
    local game_name=$1
    local check_script="$GAMES_DIR/$game_name/check_state.sh"
    
    if [ -f "$check_script" ]; then
        chmod +x "$check_script"
        "$check_script" "$GAMES_DIR/$game_name"
        return $?
    fi
    return 1 # Not installed/Unknown
}

function update_install_state() {
    local game_name=$1
    local key=$2
    local value=$3
    local config_file="$GAMES_DIR/$game_name/install_config.ini"
    
    # Simple sed replacement or append
    if grep -q "^$key=" "$config_file"; then
        sed -i "s/^$key=.*/$key=$value/" "$config_file"
    else
        echo "$key=$value" >> "$config_file"
    fi
}

function install_game_menu() {
    echo -e "${BLUE}=== Install / Setup Game ===${NC}"
    
    # List available game definitions
    local games=($(ls -d $GAMES_DIR/*/ | xargs -n 1 basename))
    
    if [ ${#games[@]} -eq 0 ]; then
        echo -e "${RED}No game definitions found in $GAMES_DIR${NC}"
        read -p "Press Enter..."
        return
    fi

    for i in "${!games[@]}"; do
        local game="${games[$i]}"
        get_game_status "$game"
        if [ $? -eq 0 ]; then
             echo -e "$((i+1))) ${GREEN}$game (Installed)${NC}"
        else
             echo -e "$((i+1))) ${YELLOW}$game (Not Installed)${NC}"
        fi
    done
    echo "b) Back"

    read -p "Select a game to setup: " choice
    if [ "$choice" == "b" ]; then return; fi
    
    local idx=$((choice-1))
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$idx" -lt 0 ] || [ "$idx" -ge "${#games[@]}" ]; then
        echo -e "${RED}Invalid selection.${NC}"
        return
    fi

    local selected_game="${games[$idx]}"
    local install_script="$GAMES_DIR/$selected_game/install.sh"
    local config_ini="$GAMES_DIR/$selected_game/install_config.ini"

    echo -e "Selected: $selected_game"
    
    # 1. Check/Install Dependencies
    source "$config_ini" 2>/dev/null
    if [ "${dependencies_installed:-0}" -ne 1 ]; then
        echo "Installing system dependencies..."
        # In a real scenario, we might call a specific deps script.
        # For now, we assume standard deps are checked in install.sh or global setup.
        # We mark it as done.
        update_install_state "$selected_game" "dependencies_installed" "1"
    fi

    # 2. Run Installer
    if [ "${game_installed:-0}" -ne 1 ]; then
        echo "Running game installer..."
        chmod +x "$install_script"
        "$install_script" "$GAMES_DIR/$selected_game" # Install to games dir (shared)
        if [ $? -eq 0 ]; then
             update_install_state "$selected_game" "game_installed" "1"
             echo -e "${GREEN}Installation successful.${NC}"
        else
             echo -e "${RED}Installation failed.${NC}"
             read -p "Press Enter..."
             return
        fi
    else
        echo "Game binaries already installed."
    fi

    # 3. Create Instance
    echo -e "${BLUE}=== Create Server Instance ===${NC}"
    read -p "Enter instance name (e.g., MyWorld): " instance_name
    if [ -z "$instance_name" ]; then echo "Cancelled."; return; fi
    
    local instance_dir="$CONFIGS_DIR/$instance_name"
    if [ -d "$instance_dir" ]; then
        echo -e "${RED}Instance '$instance_name' already exists.${NC}"
        return
    fi

    mkdir -p "$instance_dir"
    
    # Create settings.sh
    cat << EOF > "$instance_dir/settings.sh"
GAME="$selected_game"
DESCRIPTION="$selected_game Server - $instance_name"
INSTALL_PATH="$GAMES_DIR/$selected_game"
SAVE_FILE="saves/save.zip"
SETTINGS_FILE="server-settings.json"
EOF
    
    echo -e "${GREEN}Instance '$instance_name' created in $instance_dir${NC}"
    echo "Please upload your save file to $instance_dir/saves/ and configure settings.sh."
    read -p "Press Enter..."
}

function manage_servers_menu() {
    echo -e "${BLUE}=== Manage Servers ===${NC}"
    
    local configs=()
    while IFS= read -r -d $'\0' dir; do
        if [ -f "$dir/settings.sh" ]; then
            configs+=("$(basename "$dir")")
        fi
    done < <(find "$CONFIGS_DIR" -maxdepth 1 -type d -not -path "$CONFIGS_DIR" -print0)

    if [ ${#configs[@]} -eq 0 ]; then
        echo "No servers configured."
        read -p "Press Enter..."
        return
    fi

    for i in "${!configs[@]}"; do
        echo "$((i+1))) ${configs[$i]}"
    done
    echo "b) Back"

    read -p "Select server: " choice
    if [ "$choice" == "b" ]; then return; fi

    local idx=$((choice-1))
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$idx" -lt 0 ] || [ "$idx" -ge "${#configs[@]}" ]; then
        echo "Invalid."
        return
    fi

    local instance="${configs[$idx]}"
    local instance_dir="$CONFIGS_DIR/$instance"
    
    # Load config
    source "$instance_dir/settings.sh"
    
    echo -e "${YELLOW}Managing: $instance ($GAME)${NC}"
    echo "1) Start Server"
    echo "2) Stop Server (Kill Screen)"
    echo "3) View Console (Attach)"
    echo "4) Edit Game System Configs (settings.sh)"
    echo "5) Edit Game Server Settings (e.g. server.properties)"
    echo "b) Back"
    
    read -p "Action: " action
    case $action in
        1)
            # ... existing start logic ...
            local start_script="$GAMES_DIR/$GAME/start.sh"
            local session_name="game-$instance"
            
            # Check if game installed
            get_game_status "$GAME"
            if [ $? -ne 0 ]; then
                echo -e "${RED}Game '$GAME' is not installed correctly. Run setup first.${NC}"
                read -p "Press Enter..."
                return
            fi

            # Check running
            if screen -list | grep -q "\.${session_name}\s"; then
                echo -e "${RED}Already running.${NC}"
            else
                echo "Starting..."
                chmod +x "$start_script"
                # Resolve paths relative to instance dir for saves
                local abs_save="$instance_dir/$SAVE_FILE"
                local abs_settings="$instance_dir/$SETTINGS_FILE"
                
                # Using screen
                screen -dmS "$session_name" bash -c "'$start_script' '$INSTALL_PATH' '$abs_save' '$abs_settings' || { echo 'Crash'; read; }"
                echo -e "${GREEN}Started.${NC}"
            fi
            ;;
        2)
            local session_name="game-$instance"
            screen -S "$session_name" -X quit
            echo "Stop signal sent."
            ;;
        3)
            local session_name="game-$instance"
            screen -r "$session_name"
            ;;
        4)
            local editor="vi"
            if command -v nano &> /dev/null; then editor="nano"; fi
            $editor "$instance_dir/settings.sh"
            ;;
        5)
            # Source settings again to be sure
            source "$instance_dir/settings.sh"
            local editor="vi"
            if command -v nano &> /dev/null; then editor="nano"; fi
            
            local target_file="$instance_dir/$SETTINGS_FILE"
            if [ -f "$target_file" ]; then
                $editor "$target_file"
            else
                echo -e "${RED}Error: $target_file not found.${NC}"
                read -p "Press Enter..."
            fi
            ;;
        *)
            ;;
    esac
    read -p "Press Enter..."
}

# --- Main Loop ---

while true; do
    clear
    echo -e "${BLUE}=== Universal Game Server Manager ===${NC}"
    echo "1) Install / Setup Game"
    echo "2) Manage Servers"
    echo "3) Exit"
    
    read -p "Select option: " opt
    case $opt in
        1) install_game_menu ;;
        2) manage_servers_menu ;;
        3) exit 0 ;;
        *) echo "Invalid option." ;;
    esac
done