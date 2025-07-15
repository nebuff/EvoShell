#!/bin/bash
# EvoShell Simple Installer - Minimal version for pipe-to-bash compatibility

set -e

echo "=== EvoShell Installer ==="
echo "Installing EvoShell..."

# Check for forced package manager
FORCE_PKG_MANAGER=${FORCE_PKG_MANAGER:-""}

# Detect OS and set package manager
if [ -n "$FORCE_PKG_MANAGER" ]; then
    case $FORCE_PKG_MANAGER in
        apt|debian)
            PKG_MANAGER="apt"
            INSTALL_CMD="sudo apt update && sudo apt install -y gcc make git build-essential"
            ;;
        dnf|fedora)
            PKG_MANAGER="dnf"
            INSTALL_CMD="sudo dnf install -y gcc make git"
            ;;
        yum)
            PKG_MANAGER="yum"
            INSTALL_CMD="sudo yum install -y gcc make git"
            ;;
        pacman|arch)
            PKG_MANAGER="pacman"
            INSTALL_CMD="sudo pacman -S --noconfirm gcc make git base-devel"
            ;;
        *)
            echo "Error: Invalid FORCE_PKG_MANAGER value: $FORCE_PKG_MANAGER"
            echo "Supported values: apt, debian, dnf, fedora, yum, pacman, arch"
            exit 1
            ;;
    esac
    echo "Using forced package manager: $PKG_MANAGER"
elif command -v apt >/dev/null 2>&1; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt update && sudo apt install -y gcc make git build-essential"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y gcc make git"
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
    INSTALL_CMD="sudo yum install -y gcc make git"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm gcc make git base-devel"
else
    echo "Error: Unsupported package manager. Please install gcc, make, and git manually."
    echo "Or force a package manager with: FORCE_PKG_MANAGER=apt curl -sSL ... | bash"
    exit 1
fi

echo "Detected package manager: $PKG_MANAGER"

# Check for required tools
missing_tools=""
for tool in gcc make git; do
    if ! command -v $tool >/dev/null 2>&1; then
        missing_tools="$missing_tools $tool"
    fi
done

# Install missing tools
if [ -n "$missing_tools" ]; then
    echo "Installing missing tools:$missing_tools"
    eval $INSTALL_CMD
else
    echo "All required tools are available."
fi

# Download and build
TEMP_DIR=$(mktemp -d)
echo "Working in temporary directory: $TEMP_DIR"
cd "$TEMP_DIR"

echo "Downloading source code..."
if ! git clone https://github.com/nebuff/EvoShell.git . 2>/dev/null; then
    echo "Git clone failed. Trying alternative download..."
    if command -v curl >/dev/null 2>&1; then
        curl -L https://github.com/nebuff/EvoShell/archive/main.zip -o evoshell.zip
    elif command -v wget >/dev/null 2>&1; then
        wget https://github.com/nebuff/EvoShell/archive/main.zip -O evoshell.zip
    else
        echo "Error: Cannot download source code. Install curl or wget."
        exit 1
    fi
    
    if command -v unzip >/dev/null 2>&1; then
        unzip -q evoshell.zip
        mv EvoShell-main/* . 2>/dev/null || true
        rm -rf EvoShell-main evoshell.zip
    else
        echo "Error: unzip not available."
        exit 1
    fi
fi

echo "Building EvoShell..."
if ! make >/dev/null 2>&1; then
    echo "Error: Build failed."
    exit 1
fi

echo "Installing EvoShell..."
if ! sudo cp evoshell /usr/local/bin/evos 2>/dev/null; then
    echo "Error: Installation failed. Trying without sudo..."
    if ! cp evoshell /usr/local/bin/evos 2>/dev/null; then
        echo "Error: Cannot install to /usr/local/bin. Check permissions."
        exit 1
    fi
fi

sudo chmod +x /usr/local/bin/evos 2>/dev/null || chmod +x /usr/local/bin/evos

echo "Cleaning up..."
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Installation complete!"
echo "Run 'evos' to start EvoShell."
echo "If 'evos' command is not found, try:"
echo "  hash -r && evos"
echo "  source ~/.bashrc"
echo ""
