# Dotfiles

Personal configuration files for development environment setup.

## Quick Start

### Windows Users

First, install Git Bash:

```powershell
winget install -e --disable-interactivity Git.Git
```

Reload your shell, then proceed with the installation steps below.

### Installation (All Platforms)

```bash
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
bash install.sh
```

## What's Included

- **Alacritty**: Terminal emulator configuration
- **Bash**: Shell configuration
- **Docker**: Docker daemon settings
- **Mise**: Development environment manager
- **Oh My Posh**: Prompt theme configuration
- **SSH**: SSH client configuration
- **Tmux**: Terminal multiplexer settings
- **Vim**: Text editor configuration
- **VS Code**: Editor settings, keybindings, and extensions

## Requirements

The installation script will handle most dependencies. You'll need:

- **Git** (on Windows, install via the command above to get Git Bash)
- **Bash** (included by default on Linux, macOS, and Android)

## Platform-Specific Configurations

Some tools have platform-specific configurations:

- **Alacritty**: Separate configs for Linux (`linux.toml`), macOS (`osx.toml`), and Windows (`windows.toml`)

The installation script automatically detects your platform and applies the appropriate configurations.
