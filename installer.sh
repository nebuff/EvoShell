#!/bin/bash

# EvoShell Installer Script
# Supports Fedora, Debian, and Arch-based systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/nebuff/EvoShell.git"
INSTALL_DIR="/tmp/evoshell-install"
BINARY_NAME="evos"
INSTALL_PATH="/usr/local/bin"
DEBUG=${DEBUG:-false}
FORCE_PKG_MANAGER=${FORCE_PKG_MANAGER:-""}

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    if [ "$DEBUG" = "true" ]; then
        echo "[DEBUG] $(date): $1" >&2
    fi
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                        EvoShell Installer                        ║"
    echo "║                   Easy Installation Script                       ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to select package manager interactively
select_package_manager() {
    if [ -n "$FORCE_PKG_MANAGER" ]; then
        return  # Already forced, skip selection
    fi
    
    # Check if running interactively (not piped)
    if [ ! -t 0 ]; then
        return  # Not interactive, use auto-detection
    fi
    
    # Find available package managers and determine default
    available_managers=()
    default_manager=""
    
    if command -v apt &> /dev/null; then
        available_managers+=("apt")
        if [ -z "$default_manager" ]; then
            default_manager="apt"
        fi
    fi
    if command -v dnf &> /dev/null; then
        available_managers+=("dnf")
        if [ -z "$default_manager" ]; then
            default_manager="dnf"
        fi
    fi
    if command -v yum &> /dev/null; then
        available_managers+=("yum")
        if [ -z "$default_manager" ]; then
            default_manager="yum"
        fi
    fi
    if command -v pacman &> /dev/null; then
        available_managers+=("pacman")
        if [ -z "$default_manager" ]; then
            default_manager="pacman"
        fi
    fi
    
    # If multiple package managers are available, let user choose
    if [ ${#available_managers[@]} -gt 1 ]; then
        echo ""
        print_info "Multiple package managers detected: ${available_managers[*]}"
        echo ""
        echo "Available options:"
        echo "  apt     - For Debian, Ubuntu, Mint, etc."
        echo "  dnf     - For Fedora (newer versions)"
        echo "  yum     - For RHEL, CentOS (older versions)"
        echo "  pacman  - For Arch Linux, Manjaro, etc."
        echo ""
        
        while true; do
            read -p "Type the name of your package manager, or press Enter for default ($default_manager): " choice
            
            # Default to detected manager if empty
            if [ -z "$choice" ]; then
                choice="$default_manager"
                print_info "Using default package manager: $choice"
                break
            fi
            
            # Validate the choice
            case "$choice" in
                apt|debian)
                    if command -v apt &> /dev/null; then
                        choice="apt"
                        break
                    else
                        echo "Error: apt not found on this system."
                    fi
                    ;;
                dnf|fedora)
                    if command -v dnf &> /dev/null; then
                        choice="dnf"
                        break
                    else
                        echo "Error: dnf not found on this system."
                    fi
                    ;;
                yum)
                    if command -v yum &> /dev/null; then
                        choice="yum"
                        break
                    else
                        echo "Error: yum not found on this system."
                    fi
                    ;;
                pacman|arch)
                    if command -v pacman &> /dev/null; then
                        choice="pacman"
                        break
                    else
                        echo "Error: pacman not found on this system."
                    fi
                    ;;
                *)
                    echo "Invalid choice: $choice"
                    echo "Please enter one of: ${available_managers[*]}"
                    ;;
            esac
        done
        
        FORCE_PKG_MANAGER="$choice"
        print_info "Selected package manager: $FORCE_PKG_MANAGER"
        echo ""
    fi
}

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_FAMILY=""
        
        # Check if user forced a specific package manager
        if [ -n "$FORCE_PKG_MANAGER" ]; then
            case $FORCE_PKG_MANAGER in
                apt|debian)
                    DISTRO_FAMILY="debian"
                    print_info "Forced package manager: apt/debian"
                    ;;
                dnf|yum|fedora)
                    DISTRO_FAMILY="fedora"
                    print_info "Forced package manager: dnf/yum/fedora"
                    ;;
                pacman|arch)
                    DISTRO_FAMILY="arch"
                    print_info "Forced package manager: pacman/arch"
                    ;;
                *)
                    print_error "Invalid forced package manager: $FORCE_PKG_MANAGER"
                    print_info "Supported options: apt, debian, dnf, yum, fedora, pacman, arch"
                    exit 1
                    ;;
            esac
        else
            # Auto-detect distribution
            case $DISTRO in
                fedora|centos|rhel|rocky|almalinux)
                    DISTRO_FAMILY="fedora"
                    ;;
                ubuntu|debian|mint|pop|elementary)
                    DISTRO_FAMILY="debian"
                    ;;
                arch|manjaro|endeavouros|garuda)
                    DISTRO_FAMILY="arch"
                    ;;
                *)
                    print_warning "Unknown distribution: $DISTRO"
                    print_info "Attempting to detect package manager..."
                    if command -v dnf &> /dev/null; then
                        DISTRO_FAMILY="fedora"
                    elif command -v yum &> /dev/null; then
                        DISTRO_FAMILY="fedora"
                    elif command -v apt &> /dev/null; then
                        DISTRO_FAMILY="debian"
                    elif command -v pacman &> /dev/null; then
                        DISTRO_FAMILY="arch"
                    else
                        print_error "Unsupported distribution. Please install manually or use FORCE_PKG_MANAGER."
                        print_info "Example: FORCE_PKG_MANAGER=apt curl -sSL ... | bash"
                        exit 1
                    fi
                    ;;
            esac
        fi
    else
        print_error "Cannot detect Linux distribution. /etc/os-release not found."
        print_info "You can force a package manager with FORCE_PKG_MANAGER environment variable."
        print_info "Example: FORCE_PKG_MANAGER=apt curl -sSL ... | bash"
        exit 1
    fi
    
    print_info "Detected distribution: $DISTRO (family: $DISTRO_FAMILY)"
}

# Function to install dependencies
install_dependencies() {
    print_info "Installing dependencies..."
    
    case $DISTRO_FAMILY in
        fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf update -y
                sudo dnf install -y gcc make git
            else
                sudo yum update -y
                sudo yum install -y gcc make git
            fi
            ;;
        debian)
            sudo apt update
            sudo apt install -y gcc make git build-essential
            ;;
        arch)
            sudo pacman -Sy --noconfirm gcc make git base-devel
            ;;
        *)
            print_error "Unsupported distribution family: $DISTRO_FAMILY"
            exit 1
            ;;
    esac
    
    print_success "Dependencies installed successfully!"
}

# Function to check if dependencies are available
check_dependencies() {
    local missing_deps=()
    
    for cmd in gcc make git; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Function to clone or download the repository
get_source_code() {
    print_info "Downloading EvoShell source code..."
    
    # Clean up any existing installation directory
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
    fi
    
    # Try to clone the repository
    if git clone "$REPO_URL" "$INSTALL_DIR"; then
        print_success "Source code downloaded successfully!"
    else
        print_error "Failed to clone repository from $REPO_URL"
        print_info "Attempting to download as archive..."
        
        # Fallback: download as zip if git clone fails
        mkdir -p "$INSTALL_DIR"
        cd "$INSTALL_DIR"
        
        if command -v curl &> /dev/null; then
            curl -L "${REPO_URL}/archive/main.zip" -o evoshell.zip
        elif command -v wget &> /dev/null; then
            wget "${REPO_URL}/archive/main.zip" -O evoshell.zip
        else
            print_error "Neither curl nor wget available. Cannot download source code."
            exit 1
        fi
        
        if command -v unzip &> /dev/null; then
            unzip evoshell.zip
            mv EvoShell-main/* .
            rm -rf EvoShell-main evoshell.zip
        else
            print_error "unzip not available. Cannot extract source code."
            exit 1
        fi
    fi
}

# Function to build EvoShell
build_evoshell() {
    print_info "Building EvoShell..."
    
    cd "$INSTALL_DIR"
    
    if [ ! -f "Makefile" ] || [ ! -f "evoshell.c" ]; then
        print_error "Source files not found in $INSTALL_DIR"
        exit 1
    fi
    
    if make; then
        print_success "EvoShell built successfully!"
    else
        print_error "Failed to build EvoShell"
        exit 1
    fi
}

# Function to install EvoShell
install_evoshell() {
    print_info "Installing EvoShell..."
    
    cd "$INSTALL_DIR"
    
    if [ ! -f "evoshell" ]; then
        print_error "EvoShell binary not found. Build may have failed."
        exit 1
    fi
    
    # Install using make install (requires sudo)
    if sudo make install; then
        print_success "EvoShell installed successfully!"
    else
        print_error "Failed to install EvoShell"
        exit 1
    fi
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    if command -v evos &> /dev/null; then
        print_success "EvoShell (evos) is now available in your PATH!"
        print_info "Installation location: $(which evos)"
    else
        print_error "EvoShell installation verification failed"
        print_info "Try running: source ~/.bashrc or restart your terminal"
        return 1
    fi
}

# Function to clean up installation files
cleanup() {
    print_info "Cleaning up installation files..."
    
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        print_success "Cleanup completed!"
    fi
}

# Function to show usage instructions
show_usage() {
    echo -e "${GREEN}"
    echo "Installation completed successfully!"
    echo ""
    echo "You can now use EvoShell by running:"
    echo "  evos"
    echo ""
    echo "If 'evos' command is not found, try:"
    echo "  hash -r && evos    # Refresh command cache"
    echo "  source ~/.bashrc   # Reload shell profile"
    echo "  bash               # Start new shell session"
    echo ""
    echo "To uninstall EvoShell later, run:"
    echo "  sudo rm /usr/local/bin/evos"
    echo ""
    echo "Enjoy using EvoShell!"
    echo -e "${NC}"
}

# Function to handle script interruption
cleanup_on_exit() {
    print_warning "Installation interrupted. Cleaning up..."
    cleanup
    exit 1
}

# Main installation function
main() {
    # Set up signal handlers
    trap cleanup_on_exit INT TERM
    
    print_header
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. This is not recommended."
        print_info "The script will request sudo privileges when needed."
        sleep 2
    fi
    
    # Select package manager (interactive mode only)
    select_package_manager
    
    # Detect distribution
    detect_distro
    
    # Check for existing installation
    if command -v evos &> /dev/null; then
        print_warning "EvoShell (evos) is already installed at: $(which evos)"
        # Check if running interactively (not piped)
        if [ -t 0 ]; then
            read -p "Do you want to reinstall? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Installation cancelled."
                exit 0
            fi
        else
            print_info "Non-interactive mode detected. Proceeding with reinstallation..."
        fi
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        print_info "Installing missing dependencies..."
        install_dependencies
    else
        print_success "All dependencies are available!"
    fi
    
    # Download source code
    get_source_code
    
    # Build EvoShell
    build_evoshell
    
    # Install EvoShell
    install_evoshell
    
    # Verify installation
    if verify_installation; then
        # Clean up
        cleanup
        
        # Show usage instructions
        show_usage
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
