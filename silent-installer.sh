#!/bin/bash
# EvoShell Silent Installer - No interactive prompts, auto-detect everything

set -e

# Configuration
TEMP_DIR=$(mktemp -d)
REPO_URL="https://github.com/nebuff/EvoShell.git"

# Silent function - no prompts, just auto-detect and install
silent_install() {
    # Auto-detect package manager
    PKG_MANAGER=""
    INSTALL_CMD=""
    
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        INSTALL_CMD="apt update && apt install -y gcc make git build-essential"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="dnf install -y gcc make git"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        INSTALL_CMD="yum install -y gcc make git"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="pacman -S --noconfirm gcc make git base-devel"
    else
        echo "Error: No supported package manager found"
        exit 1
    fi
    
    # Check and install dependencies silently
    missing=""
    for tool in gcc make git; do
        if ! command -v $tool >/dev/null 2>&1; then
            missing="yes"
            break
        fi
    done
    
    if [ "$missing" = "yes" ]; then
        sudo $INSTALL_CMD >/dev/null 2>&1
    fi
    
    # Download source
    cd "$TEMP_DIR"
    if ! git clone "$REPO_URL" . >/dev/null 2>&1; then
        # Fallback download
        if command -v curl >/dev/null 2>&1; then
            curl -sL "${REPO_URL}/archive/main.zip" -o evoshell.zip
        else
            wget -q "${REPO_URL}/archive/main.zip" -O evoshell.zip
        fi
        unzip -q evoshell.zip
        mv EvoShell-main/* . 2>/dev/null || true
        rm -rf EvoShell-main evoshell.zip
    fi
    
    # Build and install
    make >/dev/null 2>&1
    sudo cp evoshell /usr/local/bin/evos
    sudo chmod +x /usr/local/bin/evos
    
    # Cleanup
    cd /
    rm -rf "$TEMP_DIR"
    
    echo "EvoShell installed successfully!"
    echo "Run 'evos' to start."
}

# Override any existing installation without prompting
if command -v evos >/dev/null 2>&1; then
    sudo rm -f /usr/local/bin/evos 2>/dev/null || true
fi

silent_install
