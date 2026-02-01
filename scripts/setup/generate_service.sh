#!/bin/bash
# Systemd Service Generator for Game Servers

INSTANCE_NAME="$1"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/configs/$INSTANCE_NAME"

if [ -z "$INSTANCE_NAME" ] || [ ! -d "$CONFIG_DIR" ]; then
    echo "Usage: $0 <instance_name>"
    exit 1
fi

# Load Instance Settings
source "$CONFIG_DIR/settings.sh"

SERVICE_NAME="game-$INSTANCE_NAME"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
USER=$(whoami)

echo "Generating systemd service for $INSTANCE_NAME..."

# Build the start command logic
# We need absolute paths for systemd
START_SCRIPT="$PROJECT_ROOT/games/$GAME/start.sh"
if [ -n "$SAVE_FILE" ]; then
    if [[ "$SAVE_FILE" == */* ]]; then
        ABS_SAVE_FILE="$CONFIG_DIR/$SAVE_FILE"
    else
        ABS_SAVE_FILE="$SAVE_FILE"
    fi
elif [ "$GAME" == "terraria" ]; then
    ABS_SAVE_FILE="${SAVE_NAME:-$INSTANCE_NAME}"
fi
ABS_SETTINGS_FILE="$CONFIG_DIR/$SETTINGS_FILE"

# Create the service file
sudo bash -c "cat << EOF > $SERVICE_FILE
[Unit]
Description=Game Server: $INSTANCE_NAME ($GAME)
After=network.target

[Service]
Type=forking
User=$USER
WorkingDirectory=$PROJECT_ROOT
# Start in a detached screen session, but only if it's not already running
# We check 'screen -list' for the exact session name to prevent duplicates.
ExecStart=/bin/bash -c "! /usr/bin/screen -list | grep -q '\.${SERVICE_NAME}\s' && /usr/bin/screen -dmS ${SERVICE_NAME} /bin/bash -c '${START_SCRIPT} ${INSTALL_PATH} ${ABS_SAVE_FILE} ${ABS_SETTINGS_FILE}'"
# Stop by sending quit command to screen
ExecStop=/usr/bin/screen -S $SERVICE_NAME -X quit
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd
sudo systemctl daemon-reload

echo "Service created at $SERVICE_FILE"
echo "To enable on boot: sudo systemctl enable $SERVICE_NAME"
echo "To start now: sudo systemctl start $SERVICE_NAME"
