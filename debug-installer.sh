#!/bin/bash
# EvoShell Debug Installer - Provides verbose output for troubleshooting

echo "=== EvoShell Debug Installer Started ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Shell: $0"
echo "Arguments: $@"
echo "Environment variables:"
echo "  FORCE_PKG_MANAGER=${FORCE_PKG_MANAGER:-not set}"
echo "  DEBUG=${DEBUG:-not set}"
echo "==========================================="

set -e

# Detect package manager
if [ -n "$FORCE_PKG_MANAGER" ]; then
    echo "Using forced package manager: $FORCE_PKG_MANAGER"
    case $FORCE_PKG_MANAGER in
        apt|debian)
            INSTALL_CMD="sudo apt update && sudo apt install -y gcc make git build-essential"
            ;;
        dnf|fedora)
            INSTALL_CMD="sudo dnf install -y gcc make git"
            ;;
        yum)
            INSTALL_CMD="sudo yum install -y gcc make git"
            ;;
        pacman|arch)
            INSTALL_CMD="sudo pacman -S --noconfirm gcc make git base-devel"
            ;;
        *)
            echo "Error: Invalid FORCE_PKG_MANAGER: $FORCE_PKG_MANAGER"
            exit 1
            ;;
    esac
elif command -v apt >/dev/null 2>&1; then
    INSTALL_CMD="sudo apt update && sudo apt install -y gcc make git build-essential"
elif command -v dnf >/dev/null 2>&1; then
    INSTALL_CMD="sudo dnf install -y gcc make git"
elif command -v yum >/dev/null 2>&1; then
    INSTALL_CMD="sudo yum install -y gcc make git"
elif command -v pacman >/dev/null 2>&1; then
    INSTALL_CMD="sudo pacman -S --noconfirm gcc make git base-devel"
else
    echo "Error: No supported package manager found"
    exit 1
fi

echo "Package manager command: $INSTALL_CMD"

# Check for dependencies
echo "Checking for required tools..."
missing_tools=""
for tool in gcc make git; do
    if ! command -v $tool >/dev/null 2>&1; then
        missing_tools="$missing_tools $tool"
    fi
done

if [ -n "$missing_tools" ]; then
    echo "Installing missing tools:$missing_tools"
    eval $INSTALL_CMD
else
    echo "All required tools are available."
fi

# Download and install
TEMP_DIR=$(mktemp -d)
echo "Working directory: $TEMP_DIR"
cd "$TEMP_DIR"

echo "Downloading EvoShell..."
if ! git clone https://github.com/nebuff/EvoShell.git . 2>/dev/null; then
    echo "Git clone failed, trying wget..."
    if command -v wget >/dev/null 2>&1; then
        wget https://github.com/nebuff/EvoShell/archive/main.zip -O evoshell.zip
        unzip -q evoshell.zip
        mv EvoShell-main/* . 2>/dev/null || true
        rm -rf EvoShell-main evoshell.zip
    else
        echo "Error: Cannot download source code"
        exit 1
    fi
fi

echo "Building EvoShell..."
if ! make >/dev/null 2>&1; then
    echo "Error: Build failed"
    exit 1
fi

echo "Installing EvoShell..."
sudo cp evoshell /usr/local/bin/evos
sudo chmod +x /usr/local/bin/evos

echo "Cleaning up..."
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Installation completed successfully!"
echo "Run 'evos' to start EvoShell"
echo "=== Debug Installer Finished ==="
