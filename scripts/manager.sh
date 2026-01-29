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
    local update_script="$GAMES_DIR/$selected_game/update.sh"
    local config_ini="$GAMES_DIR/$selected_game/install_config.ini"

    echo -e "Selected: $selected_game"
    
    # Check if already installed
    get_game_status "$selected_game"
    local is_installed=$?
    
    if [ $is_installed -eq 0 ]; then
        echo -e "${YELLOW}Game is already installed.${NC}"
        echo "1) Re-Install / Update"
        echo "2) Create New Instance"
        echo "b) Back"
        read -p "Option: " subopt
        if [ "$subopt" == "1" ]; then
            if [ -f "$update_script" ]; then
                chmod +x "$update_script"
                "$update_script" "$GAMES_DIR/$selected_game"
                read -p "Press Enter..."
                return
            else
                echo -e "${RED}No update script found for $selected_game.${NC}"
            fi
        elif [ "$subopt" == "b" ]; then
            return
        fi
        # If option 2, fall through to Create Instance
    fi

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
    
    # Check Backup Status
    local backup_script="$PROJECT_ROOT/scripts/backup.sh"
    local cron_status="${RED}[No Backup Schedule]${NC}"
    if crontab -l 2>/dev/null | grep -q "$backup_script $instance"; then
        cron_status="${GREEN}[Backups Active]${NC}"
    fi

    echo -e "${YELLOW}Managing: $instance ($GAME)${NC}"
    echo -e "Status: $cron_status"
    echo "1) Start Server"
    echo "2) Stop Server (Kill Screen)"
    echo "3) View Console (Attach)"
    echo "4) Edit Game System Configs (settings.sh)"
    echo "5) Edit Game Server Settings (e.g. server.properties)"
    echo "6) Configure Auto-start (systemd)"
    echo "7) Configure Auto-Backup (Cron)"
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
                # Check if systemd service exists
                if [ -f "/etc/systemd/system/${session_name}.service" ]; then
                    echo -e "${YELLOW}Systemd service detected.${NC}"
                    read -p "Start via systemd? (y/n): " use_sys
                    if [ "$use_sys" == "y" ]; then
                        sudo systemctl start "$session_name"
                        echo -e "${GREEN}Start signal sent via systemd.${NC}"
                        read -p "Press Enter..."
                        continue
                    fi
                fi
                
                echo "Starting manually..."
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
        6)
            local service_name="game-$instance"
            local is_installed=0
            local status_text="${RED}(Not Configured)${NC}"
            
            # Check if service file exists
            if [ -f "/etc/systemd/system/${service_name}.service" ]; then
                is_installed=1
                # Check Enabled Status
                if systemctl is-enabled "$service_name" &>/dev/null; then
                    status_text="${GREEN}(Enabled)${NC}"
                else
                    status_text="${YELLOW}(Disabled)${NC}"
                fi
                # Check Active Status
                if systemctl is-active "$service_name" &>/dev/null; then
                    status_text="$status_text ${GREEN}[Running]${NC}"
                else
                    status_text="$status_text ${RED}[Stopped]${NC}"
                fi
            fi

            echo -e "\n${YELLOW}Systemd Service Configuration${NC}"
            echo -e "Current Status: $status_text"
            echo "1) Install/Update Service File"
            if [ $is_installed -eq 1 ]; then
                echo "2) Enable (Start on boot)"
                echo "3) Disable (Don't start on boot)"
                echo "4) Start Service Now"
                echo "5) Stop Service Now"
            fi
            echo "b) Back"
            
            read -p "Selection: " sys_opt
            case $sys_opt in
                1)
                    local gen_script="$PROJECT_ROOT/scripts/setup/generate_service.sh"
                    chmod +x "$gen_script"
                    "$gen_script" "$instance"
                    read -p "Service generated. Press Enter..."
                    ;;
                2) sudo systemctl enable "$service_name"; read -p "Enabled. Press Enter..." ;;
                3) sudo systemctl disable "$service_name"; read -p "Disabled. Press Enter..." ;;
                4) sudo systemctl start "$service_name"; read -p "Signal sent. Press Enter..." ;;
                5) sudo systemctl stop "$service_name"; read -p "Signal sent. Press Enter..." ;;
            esac
            ;;
        7)
            local backup_script="$PROJECT_ROOT/scripts/backup.sh"
            chmod +x "$backup_script"
            
            # Check existing cron job
            local current_cron=$(crontab -l 2>/dev/null | grep "$backup_script $instance")
            
            echo -e "\n${YELLOW}Auto-Backup Configuration${NC}"
            if [ -n "$current_cron" ]; then
                echo -e "Status: ${GREEN}Active${NC}"
                echo "Current Schedule: $current_cron"
                echo "1) Remove Auto-Backup"
            else
                echo -e "Status: ${RED}Disabled${NC}"
                echo "1) Enable Auto-Backup"
            fi
            echo "2) Run Backup Now (Manual)"
            echo "3) Configure Cloud Storage (Google Drive)"
            echo "b) Back"
            
            read -p "Selection: " bk_opt
            if [ "$bk_opt" == "1" ]; then
                if [ -n "$current_cron" ]; then
                    # Remove
                    crontab -l 2>/dev/null | grep -v "$backup_script $instance" | crontab -
                    echo "Auto-Backup disabled."
                else
                    # Add
                    echo "Select Frequency:"
                    echo "1) Every Hour (0 * * * *)"
                    echo "2) Every 6 Hours (0 */6 * * *)"
                    echo "3) Daily (0 0 * * *)"
                    echo "4) Custom"
                    read -p "Freq: " freq
                    local schedule=""
                    case $freq in
                        1) schedule="0 * * * *" ;;
                        2) schedule="0 */6 * * *" ;;
                        3) schedule="0 0 * * *" ;;
                        4) read -p "Enter Cron Expression (e.g. '0 12 * * *'): " schedule ;;
                    esac
                    
                    if [ -n "$schedule" ]; then
                        (crontab -l 2>/dev/null; echo "$schedule $backup_script $instance") | crontab -
                        echo "Auto-Backup enabled: $schedule"
                    fi
                fi
                read -p "Press Enter..."
            elif [ "$bk_opt" == "2" ]; then
                "$backup_script" "$instance"
                read -p "Press Enter..."
            elif [ "$bk_opt" == "3" ]; then
                echo -e "${YELLOW}Cloud Backup Configuration (Rclone)${NC}"
                echo "You need to configure a remote named 'gdrive'."
                echo "1) Start Rclone Config Wizard"
                echo "2) Check Connection"
                echo "b) Back"
                read -p "Option: " cloud_opt
                
                if [ "$cloud_opt" == "1" ]; then
                    rclone config
                elif [ "$cloud_opt" == "2" ]; then
                    echo "Checking 'gdrive'..."
                    if rclone listremotes | grep -q "^gdrive:"; then
                        echo -e "${GREEN}Remote 'gdrive' found.${NC}"
                        rclone about gdrive:
                    else
                        echo -e "${RED}Remote 'gdrive' not configured.${NC}"
                    fi
                    read -p "Press Enter..."
                fi
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
    
    # --- System Health Checks ---
    # 1. Disk Space (< 1GB warning)
    DISK_FREE=$(df -k . | tail -1 | awk '{print $4}')
    if [ "$DISK_FREE" -lt 1048576 ]; then
        echo -e "${RED}[WARNING] Low Disk Space: $((DISK_FREE/1024))MB free${NC}"
    fi

    # 2. RAM (< 500MB warning)
    MEM_FREE=$(free -m | grep Mem | awk '{print $7}')
    if [ "$MEM_FREE" -lt 500 ]; then
        echo -e "${RED}[WARNING] Low RAM: ${MEM_FREE}MB available${NC}"
    fi
    
    # 3. Cloud Config Check
    if command -v rclone &> /dev/null; then
        if ! rclone listremotes | grep -q "^gdrive:"; then
             echo -e "${YELLOW}[INFO] Cloud Backups not configured (No 'gdrive' remote)${NC}"
        fi
    fi
    echo "-------------------------------------"
    
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