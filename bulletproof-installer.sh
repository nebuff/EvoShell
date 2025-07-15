#!/bin/bash
# EvoShell Bulletproof Installer - Always produces output, handles all edge cases

# Force all output to be displayed
exec 2>&1

echo "=== EvoShell Bulletproof Installer ==="
echo "Starting installation process..."
echo "Date: $(date)"
echo "User: $(whoami)"
echo "System: $(uname -a)"
echo ""

# Ensure we always show what we're doing
set -x

# Create a cleanup function
cleanup() {
    echo "Cleaning up temporary files..."
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        echo "Cleaned up $TEMP_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Check for basic requirements
echo "Checking basic requirements..."

# Check if we have curl or wget
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl -L"
    echo "✓ curl found"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget -O-"
    echo "✓ wget found"
else
    echo "✗ Neither curl nor wget found. Cannot download source code."
    exit 1
fi

# Check if we have git
if command -v git >/dev/null 2>&1; then
    echo "✓ git found"
    HAS_GIT=true
else
    echo "⚠ git not found, will try alternative download"
    HAS_GIT=false
fi

# Check if we have sudo
if sudo -n true 2>/dev/null; then
    echo "✓ sudo access available (passwordless)"
    SUDO_PREFIX="sudo"
elif command -v sudo >/dev/null 2>&1; then
    echo "⚠ sudo available but may require password"
    SUDO_PREFIX="sudo"
else
    echo "⚠ no sudo, will try without"
    SUDO_PREFIX=""
fi

# Auto-detect package manager
echo "Detecting package manager..."
PKG_MANAGER=""
INSTALL_CMD=""

if command -v apt >/dev/null 2>&1; then
    PKG_MANAGER="apt"
    INSTALL_CMD="$SUDO_PREFIX apt update && $SUDO_PREFIX apt install -y gcc make git build-essential"
    echo "✓ Found apt (Debian/Ubuntu)"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="$SUDO_PREFIX dnf install -y gcc make git"
    echo "✓ Found dnf (Fedora)"
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
    INSTALL_CMD="$SUDO_PREFIX yum install -y gcc make git"
    echo "✓ Found yum (RHEL/CentOS)"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="$SUDO_PREFIX pacman -S --noconfirm gcc make git base-devel"
    echo "✓ Found pacman (Arch)"
else
    echo "✗ No supported package manager found"
    echo "Please install gcc, make, and git manually, then try again"
    exit 1
fi

# Check for required build tools
echo "Checking for build tools..."
missing_tools=()
for tool in gcc make; do
    if command -v $tool >/dev/null 2>&1; then
        echo "✓ $tool found"
    else
        echo "✗ $tool missing"
        missing_tools+=($tool)
    fi
done

# Install missing tools if needed
if [ ${#missing_tools[@]} -gt 0 ]; then
    echo "Installing missing tools: ${missing_tools[*]}"
    echo "Running: $INSTALL_CMD"
    eval $INSTALL_CMD
    if [ $? -ne 0 ]; then
        echo "✗ Failed to install dependencies"
        exit 1
    fi
    echo "✓ Dependencies installed"
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"
cd "$TEMP_DIR"

# Download source code
echo "Downloading EvoShell source code..."
if [ "$HAS_GIT" = true ]; then
    echo "Trying git clone..."
    if git clone https://github.com/nebuff/EvoShell.git . 2>&1; then
        echo "✓ Git clone successful"
    else
        echo "✗ Git clone failed, trying alternative download..."
        HAS_GIT=false
    fi
fi

if [ "$HAS_GIT" = false ]; then
    echo "Downloading archive..."
    if $DOWNLOADER https://github.com/nebuff/EvoShell/archive/main.zip > evoshell.zip 2>/dev/null; then
        echo "✓ Download successful"
        if command -v unzip >/dev/null 2>&1; then
            echo "Extracting archive..."
            unzip -q evoshell.zip
            mv EvoShell-main/* . 2>/dev/null || true
            rm -rf EvoShell-main evoshell.zip
            echo "✓ Archive extracted"
        else
            echo "✗ unzip not available, cannot extract archive"
            exit 1
        fi
    else
        echo "✗ Download failed"
        exit 1
    fi
fi

# Verify source files
echo "Verifying source files..."
if [ -f "evoshell.c" ] && [ -f "Makefile" ]; then
    echo "✓ Source files found"
    echo "Files in directory:"
    ls -la
else
    echo "✗ Required source files not found"
    echo "Contents of directory:"
    ls -la
    exit 1
fi

# Build
echo "Building EvoShell..."
if make 2>&1; then
    echo "✓ Build successful"
else
    echo "✗ Build failed"
    echo "Build output:"
    make 2>&1 || true
    exit 1
fi

# Verify binary
if [ -f "evoshell" ]; then
    echo "✓ Binary created: evoshell"
    ls -l evoshell
else
    echo "✗ Binary not found after build"
    exit 1
fi

# Install
echo "Installing EvoShell..."
echo "Creating installation directory..."
$SUDO_PREFIX mkdir -p /usr/local/bin

echo "Copying binary..."
if $SUDO_PREFIX cp evoshell /usr/local/bin/evos; then
    echo "✓ Binary copied to /usr/local/bin/evos"
else
    echo "✗ Failed to copy binary"
    exit 1
fi

echo "Setting permissions..."
if $SUDO_PREFIX chmod +x /usr/local/bin/evos; then
    echo "✓ Permissions set"
else
    echo "✗ Failed to set permissions"
    exit 1
fi

# Verify installation
echo "Verifying installation..."
if [ -f /usr/local/bin/evos ]; then
    echo "✓ Binary exists at /usr/local/bin/evos"
    echo "Binary info: $(ls -l /usr/local/bin/evos)"
else
    echo "✗ Binary not found at /usr/local/bin/evos"
    exit 1
fi

# Check if it's in PATH
if command -v evos >/dev/null 2>&1; then
    echo "✓ evos command is available in PATH"
    echo "Location: $(which evos)"
else
    echo "⚠ evos not found in PATH"
    echo "Current PATH: $PATH"
    echo "You may need to add /usr/local/bin to your PATH:"
    echo "  export PATH=\"/usr/local/bin:\$PATH\""
    echo "  echo 'export PATH=\"/usr/local/bin:\$PATH\"' >> ~/.bashrc"
fi

# Test the binary
echo "Testing the binary..."
if /usr/local/bin/evos version 2>/dev/null; then
    echo "✓ Binary is working correctly"
else
    echo "⚠ Binary exists but version command failed"
    echo "You can still try running: evos"
fi

echo ""
echo "=== INSTALLATION COMPLETED SUCCESSFULLY ==="
echo ""
echo "EvoShell has been installed as 'evos'"
echo ""
echo "To start EvoShell, run:"
echo "  evos"
echo ""
echo "If the command is not found, try:"
echo "  export PATH=\"/usr/local/bin:\$PATH\""
echo "  hash -r"
echo "  evos"
echo ""
echo "To make the PATH change permanent, add this to your ~/.bashrc:"
echo "  echo 'export PATH=\"/usr/local/bin:\$PATH\"' >> ~/.bashrc"
echo ""
echo "To uninstall later, run:"
echo "  sudo rm /usr/local/bin/evos"
echo ""
echo "=== Installation log complete ==="

# Turn off command tracing for final message
set +x
echo ""
echo "🎉 EvoShell installation finished!"
