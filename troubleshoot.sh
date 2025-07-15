#!/bin/bash
# EvoShell Installation Troubleshooter

echo "=== EvoShell Installation Troubleshooter ==="
echo "This script will help diagnose installation issues."
echo ""

# Check if we can reach GitHub
echo "1. Testing GitHub connectivity..."
if curl -s --max-time 10 https://github.com >/dev/null 2>&1; then
    echo "✓ GitHub is reachable"
else
    echo "✗ Cannot reach GitHub - check your internet connection"
fi

# Check if we can download the installer
echo ""
echo "2. Testing installer download..."
if curl -s --max-time 10 https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh >/dev/null 2>&1; then
    echo "✓ Installer can be downloaded"
else
    echo "✗ Cannot download installer from GitHub"
fi

# Check basic tools
echo ""
echo "3. Checking required tools..."
for tool in bash curl wget git gcc make sudo; do
    if command -v $tool >/dev/null 2>&1; then
        echo "✓ $tool: $(which $tool)"
    else
        echo "✗ $tool: not found"
    fi
done

# Check package managers
echo ""
echo "4. Checking package managers..."
for pm in apt dnf yum pacman; do
    if command -v $pm >/dev/null 2>&1; then
        echo "✓ $pm: $(which $pm)"
    else
        echo "✗ $pm: not found"
    fi
done

# Check permissions
echo ""
echo "5. Checking permissions..."
if [ -w /usr/local/bin ] 2>/dev/null; then
    echo "✓ Can write to /usr/local/bin directly"
elif sudo -n true 2>/dev/null; then
    echo "✓ Sudo access available (passwordless)"
elif sudo -l >/dev/null 2>&1; then
    echo "⚠ Sudo access available (requires password)"
else
    echo "✗ No sudo access"
fi

# Check existing installation
echo ""
echo "6. Checking existing installation..."
if command -v evos >/dev/null 2>&1; then
    echo "✓ evos found at: $(which evos)"
    echo "  Version: $(evos version 2>/dev/null || echo 'unknown')"
else
    echo "ℹ evos not found in PATH"
fi

if [ -f /usr/local/bin/evos ]; then
    echo "✓ Binary exists at /usr/local/bin/evos"
    echo "  Permissions: $(ls -l /usr/local/bin/evos)"
else
    echo "ℹ No binary at /usr/local/bin/evos"
fi

# Check PATH
echo ""
echo "7. Checking PATH..."
if echo "$PATH" | grep -q "/usr/local/bin"; then
    echo "✓ /usr/local/bin is in PATH"
else
    echo "✗ /usr/local/bin not in PATH"
    echo "  Current PATH: $PATH"
fi

# Test compilation
echo ""
echo "8. Testing compilation capability..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
cat > test.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Hello, World!\n");
    return 0;
}
EOF

if gcc -o test test.c 2>/dev/null && ./test >/dev/null 2>&1; then
    echo "✓ C compilation works"
else
    echo "✗ C compilation failed"
fi

cd /
rm -rf "$TEMP_DIR"

echo ""
echo "=== Troubleshooting Complete ==="
echo ""
echo "Common solutions:"
echo "1. If GitHub is unreachable: Check firewall/proxy settings"
echo "2. If tools missing: Install with package manager first"
echo "3. If no sudo: Contact system administrator"
echo "4. If PATH issue: Add 'export PATH=\"/usr/local/bin:\$PATH\"' to ~/.bashrc"
echo "5. If compilation fails: Install build-essential (apt) or Development Tools (yum/dnf)"
echo ""
echo "Alternative installation commands to try:"
echo "  # Ultra verbose debugging:"
echo "  curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/ultra-debug-installer.sh | bash"
echo ""
echo "  # Silent installer (no prompts):"
echo "  curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/silent-installer.sh | bash"
echo ""
echo "  # Force specific package manager:"
echo "  FORCE_PKG_MANAGER=apt curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash"
