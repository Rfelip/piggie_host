#!/bin/bash
# Environment Setup Script
# Installs basic dependencies for the manager and games.

echo "Setting up environment..."

# Detect OS/Distro (Simple check for apt/yum)
if command -v apt-get &> /dev/null; then
    PKG_MGR="apt-get"
    INSTALL_CMD="sudo apt-get install -y"
    UPDATE_CMD="sudo apt-get update"
elif command -v yum &> /dev/null; then
    PKG_MGR="yum"
    INSTALL_CMD="sudo yum install -y"
    UPDATE_CMD="sudo yum check-update"
else
    echo "Warning: Unsupported package manager. Please install dependencies manually."
fi

# Update and Install Dependencies
if [ -n "$PKG_MGR" ]; then
    echo "Updating package lists..."
    $UPDATE_CMD
    
    echo "Installing core dependencies..."
    # screen: for backgrounding
    # git: for version control
    # wget, tar, xz-utils: for downloading/extracting servers
    $INSTALL_CMD screen git wget tar xz-utils
fi

echo "Environment setup complete."
echo "Run './manager.sh' to start the manager."
