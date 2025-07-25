# EvoShell

A Simple and Intuitive Shell written in C!

EvoShell is a lightweight, basic shell implementation that provides essential shell functionality with a clean and colorful interface. It's designed to be easy to install and use across different Linux distributions.

## Features

- **Cross-platform support**: Works on Fedora, Debian, and Arch-based systems
- **Built-in commands**: `cd`, `help`, `version`, `exit`
- **Colorful interface**: Enhanced user experience with ANSI colors
- **Easy installation**: One-command installation script
- **Lightweight**: Minimal resource usage
- **Standard compliance**: Written in C99 standard

## Quick Installation

You can install EvoShell with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash
```

When multiple package managers are detected, you'll be prompted:
```
Type the name of your package manager, or press Enter for default (apt): 
```

You can type: `apt`, `dnf`, `yum`, or `pacman`, or just press Enter for the default.

**Force a specific package manager (skip prompt):**

```bash
# Force APT (Debian/Ubuntu)
FORCE_PKG_MANAGER=apt curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash

# Force DNF (Fedora)
FORCE_PKG_MANAGER=dnf curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash

# Force Pacman (Arch Linux)
FORCE_PKG_MANAGER=pacman curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash
```

**Alternative installation methods:**

```bash
# Using wget instead of curl
wget -O - https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash

# Simple installer (more reliable for piping)
curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/simple-install.sh | bash

# Silent installer (no prompts, auto-detect everything)
curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/silent-installer.sh | bash

# Ultra-verbose debug installer (for troubleshooting)
curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/ultra-debug-installer.sh | bash

# Or download first, then run
wget https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh
chmod +x installer.sh
./installer.sh
```

## Manual Installation

### Prerequisites

Make sure you have the following packages installed:

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install gcc make git
```

**Debian/Ubuntu:**
```bash
sudo apt update
sudo apt install gcc make git build-essential
```

**Arch Linux:**
```bash
sudo pacman -S gcc make git base-devel
```

### Build and Install

1. Clone the repository:
```bash
git clone https://github.com/nebuff/EvoShell.git
cd EvoShell
```

2. Build the shell:
```bash
make
```

3. Install system-wide:
```bash
sudo make install
```

4. Run EvoShell:
```bash
evos
```

## Usage

Once installed, you can start EvoShell by running:

```bash
evos
```

### Built-in Commands

- `cd [directory]` - Change the current directory
- `help` - Display available commands
- `version` - Show version information
- `exit` - Exit the shell

All other commands are passed to the system for execution.

### Examples

```bash
evos$ help
evos$ cd /home/user/Documents
evos$ ls -la
evos$ version
evos$ exit
```

## Development

### Building for Development

```bash
make debug
```

### Running Tests

```bash
./test.sh
```

### Cleaning Build Files

```bash
make clean
```

## Uninstallation

To remove EvoShell from your system:

```bash
sudo rm /usr/local/bin/evos
```

Or if you have the source code:

```bash
sudo make uninstall
```

## Supported Systems

EvoShell has been tested on:

- **Fedora** 35+
- **Ubuntu** 20.04+
- **Debian** 11+
- **Arch Linux** (rolling)
- **CentOS** 8+
- **Linux Mint** 20+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source. See the LICENSE file for details.

## Changelog

### v1.0.0
- Initial release
- Basic shell functionality
- Built-in commands: cd, help, version, exit
- Colorful prompt and interface
- Cross-platform installer script

## Troubleshooting

If you're experiencing issues with the installation, try these solutions:

### Installation Not Working?

1. **Run the troubleshooter first:**
```bash
curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/troubleshoot.sh | bash
```

2. **Try alternative installers:**
```bash
# Silent installer (no interactive prompts)
curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/silent-installer.sh | bash

# Ultra-debug installer (verbose output for diagnosis)
curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/ultra-debug-installer.sh | bash
```

3. **Force specific package manager:**
```bash
FORCE_PKG_MANAGER=apt curl -sSL https://raw.githubusercontent.com/nebuff/EvoShell/main/installer.sh | bash
```

### Common Issues

**"No output from installer":**
- Check internet connection: `curl -s https://github.com`
- Try the debug installer: `curl -sSL .../ultra-debug-installer.sh | bash`
- Use the troubleshooter: `curl -sSL .../troubleshoot.sh | bash`

**"evos command not found":**
```bash
# Add /usr/local/bin to PATH
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc

# Refresh command cache
hash -r

# Test the command
evos version
```

**"Permission denied":**
- Ensure you have sudo access
- Check if /usr/local/bin exists: `ls -ld /usr/local/bin`
- Manual permission fix: `sudo chmod +x /usr/local/bin/evos`

**"Dependencies not found":**
```bash
# Debian/Ubuntu
sudo apt update && sudo apt install gcc make git build-essential

# Fedora
sudo dnf install gcc make git

# Arch Linux
sudo pacman -S gcc make git base-devel
```

### Still Having Issues?

1. Run the ultra-debug installer to get detailed logs
2. Check the log file: `/tmp/evoshell-install-debug.log`
3. Try manual installation (see Manual Installation section)
