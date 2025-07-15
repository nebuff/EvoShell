#!/bin/bash
# EvoShell Simple Installer - Minimal version for compatibility

set -e

echo "Installing EvoShell..."

# Check for required tools
for tool in gcc make git; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "Error: $tool is required but not installed."
        echo "Please install build tools first:"
        echo "  Debian/Ubuntu: sudo apt install gcc make git build-essential"
        echo "  Fedora/RHEL:   sudo dnf install gcc make git"
        echo "  Arch Linux:    sudo pacman -S gcc make git base-devel"
        exit 1
    fi
done

# Download and build
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "Downloading source..."
git clone https://github.com/nebuff/EvoShell.git .

echo "Building..."
make

echo "Installing..."
sudo cp evoshell /usr/local/bin/evos
sudo chmod +x /usr/local/bin/evos

echo "Cleaning up..."
cd /
rm -rf "$TEMP_DIR"

echo "Installation complete! Run 'evos' to start EvoShell."
echo "If 'evos' is not found, try: hash -r && evos"
