#!/bin/bash
# Generic Factorio Installer
# Expects: $INSTALL_PATH (where to install), $VERSION (optional, default stable)

INSTALL_PATH="${1:-$HOME/servers/factorio}"
VERSION="${2:-stable}"
FACTORIO_URL="https://www.factorio.com/get-download/$VERSION/headless/linux64"

echo "Installing Factorio ($VERSION) to $INSTALL_PATH..."

mkdir -p "$INSTALL_PATH"
cd "$INSTALL_PATH" || exit 1

# Download if not exists
if [ ! -f "factorio_headless.tar.xz" ]; then
    echo "Downloading Factorio..."
    wget -O factorio_headless.tar.xz "$FACTORIO_URL"
else
    echo "Archive found, skipping download."
fi

# Extract
if [ ! -d "factorio" ]; then
    echo "Extracting..."
    tar -xJf factorio_headless.tar.xz
fi

# Setup default settings if missing
if [ ! -f "factorio/data/server-settings.json" ]; then
    cp factorio/data/server-settings.example.json factorio/data/server-settings.json
    echo "Created default server-settings.json"
fi

echo "Factorio installed successfully at $INSTALL_PATH/factorio"
