#!/bin/bash
# EvoShell Ultra Debug Installer - Maximum verbosity for troubleshooting

# Enable all debugging
set -x  # Print commands as they're executed
set -e  # Exit on any error
set -u  # Exit on undefined variables

# Force output to stderr and stdout
exec 1> >(tee -a /tmp/evoshell-install-debug.log)
exec 2> >(tee -a /tmp/evoshell-install-debug.log >&2)

echo "===== ULTRA DEBUG INSTALLER START ====="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Shell: $0"
echo "Environment variables related to terminal:"
echo "TERM: ${TERM:-unset}"
echo "SHELL: ${SHELL:-unset}"
echo "TTY: $(tty 2>/dev/null || echo 'not a tty')"
echo "Interactive test: $([[ -t 0 ]] && echo 'interactive' || echo 'non-interactive')"
echo "===== ENVIRONMENT CHECK ====="

# Check basic commands
echo "Checking basic commands..."
for cmd in bash curl wget git gcc make sudo; do
    if command -v $cmd >/dev/null 2>&1; then
        echo "✓ $cmd: $(which $cmd)"
    else
        echo "✗ $cmd: not found"
    fi
done

echo "===== SYSTEM INFO ====="
echo "OS Release:"
cat /etc/os-release 2>/dev/null || echo "No /etc/os-release found"
echo ""
echo "Kernel: $(uname -a)"
echo "CPU: $(nproc) cores"
echo "Memory: $(free -h | head -2)"
echo "Disk space: $(df -h . | tail -1)"

echo "===== PACKAGE MANAGER DETECTION ====="
FORCE_PKG_MANAGER=${FORCE_PKG_MANAGER:-""}
echo "FORCE_PKG_MANAGER environment variable: '${FORCE_PKG_MANAGER}'"

# Check all possible package managers
echo "Checking package managers:"
for pm in apt dnf yum pacman; do
    if command -v $pm >/dev/null 2>&1; then
        echo "✓ $pm: $(which $pm)"
        case $pm in
            apt)
                echo "  - apt version: $(apt --version 2>/dev/null | head -1)"
                ;;
            dnf)
                echo "  - dnf version: $(dnf --version 2>/dev/null | head -1)"
                ;;
            yum)
                echo "  - yum version: $(yum --version 2>/dev/null | head -1)"
                ;;
            pacman)
                echo "  - pacman version: $(pacman --version 2>/dev/null | head -1)"
                ;;
        esac
    else
        echo "✗ $pm: not found"
    fi
done

echo "===== DEPENDENCY CHECK ====="
missing_deps=()
for dep in gcc make git; do
    if command -v $dep >/dev/null 2>&1; then
        echo "✓ $dep: $(which $dep) - $($dep --version | head -1)"
    else
        echo "✗ $dep: missing"
        missing_deps+=($dep)
    fi
done

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "Missing dependencies: ${missing_deps[*]}"
    echo "Attempting to install..."
    
    # Auto-detect package manager if not forced
    if [ -z "$FORCE_PKG_MANAGER" ]; then
        if command -v apt >/dev/null 2>&1; then
            FORCE_PKG_MANAGER="apt"
        elif command -v dnf >/dev/null 2>&1; then
            FORCE_PKG_MANAGER="dnf"
        elif command -v yum >/dev/null 2>&1; then
            FORCE_PKG_MANAGER="yum"
        elif command -v pacman >/dev/null 2>&1; then
            FORCE_PKG_MANAGER="pacman"
        else
            echo "ERROR: No supported package manager found!"
            exit 1
        fi
    fi
    
    echo "Using package manager: $FORCE_PKG_MANAGER"
    
    case $FORCE_PKG_MANAGER in
        apt)
            echo "Running: sudo apt update"
            sudo apt update
            echo "Running: sudo apt install -y gcc make git build-essential"
            sudo apt install -y gcc make git build-essential
            ;;
        dnf)
            echo "Running: sudo dnf install -y gcc make git"
            sudo dnf install -y gcc make git
            ;;
        yum)
            echo "Running: sudo yum install -y gcc make git"
            sudo yum install -y gcc make git
            ;;
        pacman)
            echo "Running: sudo pacman -S --noconfirm gcc make git base-devel"
            sudo pacman -S --noconfirm gcc make git base-devel
            ;;
        *)
            echo "ERROR: Unknown package manager: $FORCE_PKG_MANAGER"
            exit 1
            ;;
    esac
else
    echo "All dependencies satisfied!"
fi

echo "===== DOWNLOAD SOURCE CODE ====="
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"
cd "$TEMP_DIR"
echo "Changed to directory: $(pwd)"

echo "Attempting git clone..."
if git clone https://github.com/nebuff/EvoShell.git . 2>&1; then
    echo "✓ Git clone successful"
else
    echo "✗ Git clone failed, trying alternative download..."
    
    if command -v curl >/dev/null 2>&1; then
        echo "Using curl to download archive..."
        curl -L https://github.com/nebuff/EvoShell/archive/main.zip -o evoshell.zip
    elif command -v wget >/dev/null 2>&1; then
        echo "Using wget to download archive..."
        wget https://github.com/nebuff/EvoShell/archive/main.zip -O evoshell.zip
    else
        echo "ERROR: Cannot download source code. No curl or wget available."
        exit 1
    fi
    
    if command -v unzip >/dev/null 2>&1; then
        echo "Extracting archive..."
        unzip -q evoshell.zip
        echo "Moving files..."
        mv EvoShell-main/* . 2>/dev/null || true
        rm -rf EvoShell-main evoshell.zip
        echo "✓ Archive extraction successful"
    else
        echo "ERROR: unzip not available"
        exit 1
    fi
fi

echo "===== SOURCE CODE VERIFICATION ====="
echo "Contents of working directory:"
ls -la
echo ""
echo "Checking required files:"
for file in evoshell.c Makefile; do
    if [ -f "$file" ]; then
        echo "✓ $file exists ($(wc -l < $file) lines)"
    else
        echo "✗ $file missing"
        exit 1
    fi
done

echo "===== BUILD PROCESS ====="
echo "Running: make clean (if target exists)"
make clean 2>/dev/null || echo "No clean target or already clean"

echo "Running: make"
if make 2>&1; then
    echo "✓ Build successful"
else
    echo "✗ Build failed"
    echo "Makefile contents:"
    cat Makefile
    echo ""
    echo "Build output:"
    make 2>&1 || true
    exit 1
fi

echo "Checking built binary:"
if [ -f "evoshell" ]; then
    echo "✓ evoshell binary exists"
    echo "Binary info: $(file evoshell)"
    echo "Binary size: $(ls -lh evoshell | awk '{print $5}')"
    echo "Testing binary (version check):"
    ./evoshell --help 2>/dev/null || echo "Binary exists but no --help option"
else
    echo "✗ evoshell binary not found"
    exit 1
fi

echo "===== INSTALLATION ====="
echo "Creating install directory if needed..."
sudo mkdir -p /usr/local/bin || echo "Directory already exists"

echo "Installing binary..."
if sudo cp evoshell /usr/local/bin/evos; then
    echo "✓ Binary copied to /usr/local/bin/evos"
else
    echo "✗ Failed to copy binary"
    exit 1
fi

echo "Setting permissions..."
if sudo chmod +x /usr/local/bin/evos; then
    echo "✓ Permissions set"
else
    echo "✗ Failed to set permissions"
    exit 1
fi

echo "===== VERIFICATION ====="
echo "Checking PATH:"
echo "$PATH" | tr ':' '\n'
echo ""

echo "Checking if evos is accessible:"
if command -v evos >/dev/null 2>&1; then
    echo "✓ evos found in PATH: $(which evos)"
    echo "✓ evos permissions: $(ls -l $(which evos))"
    echo "Testing evos execution:"
    evos version 2>/dev/null || echo "Binary found but version command failed"
else
    echo "✗ evos not found in PATH"
    echo "Direct test of /usr/local/bin/evos:"
    if [ -x /usr/local/bin/evos ]; then
        echo "✓ /usr/local/bin/evos is executable"
        /usr/local/bin/evos version 2>/dev/null || echo "Direct execution failed"
    else
        echo "✗ /usr/local/bin/evos not executable"
    fi
fi

echo "===== CLEANUP ====="
cd /
rm -rf "$TEMP_DIR"
echo "✓ Temporary directory cleaned up"

echo "===== INSTALLATION COMPLETE ====="
echo "Log file saved to: /tmp/evoshell-install-debug.log"
echo ""
echo "If evos command is not found, try:"
echo "  export PATH=\"/usr/local/bin:\$PATH\""
echo "  hash -r"
echo "  source ~/.bashrc"
echo "  evos"
echo ""
echo "===== ULTRA DEBUG INSTALLER END ====="
