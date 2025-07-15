#!/bin/bash

# EvoShell Demo Script
# Shows basic usage examples

echo "EvoShell Usage Examples"
echo "======================"
echo ""

echo "1. Starting EvoShell:"
echo "   ./evoshell"
echo ""

echo "2. Once in EvoShell, try these commands:"
echo "   help       - Show available commands"
echo "   version    - Display version info"
echo "   cd /tmp    - Change to /tmp directory"
echo "   ls -la     - List files (system command)"
echo "   pwd        - Show current directory (system command)"
echo "   whoami     - Show current user (system command)"
echo "   exit       - Exit EvoShell"
echo ""

echo "3. Installation command (for end users):"
echo "   # Primary method:"
echo "   curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash"
echo ""
echo "   # Force specific package manager:"
echo "   FORCE_PKG_MANAGER=apt curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash"
echo "   FORCE_PKG_MANAGER=dnf curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash"
echo "   FORCE_PKG_MANAGER=pacman curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash"
echo ""
echo "   # Alternative methods if curl doesn't work:"
echo "   wget -O - https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash"
echo "   curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/simple-install.sh | bash"
echo "   # Or download first, then run:"
echo "   wget https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh"
echo "   chmod +x installer.sh"
echo "   ./installer.sh"
echo ""

echo "4. Manual build and install:"
echo "   make"
echo "   sudo make install"
echo "   evos"
echo ""

echo "Note: After installation, use 'evos' command to start EvoShell"
