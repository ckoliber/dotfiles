#!/usr/bin/env bash
set -euo pipefail

export DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

copy() {
  local SRC=$1
  local DEST=$2

  mkdir -p "$(dirname "$DEST")"
  cp -rf "$SRC" "$DEST"
}

link() {
  local SRC=$1
  local DEST=$2

  mkdir -p "$(dirname "$DEST")"
  ln -sf "$SRC" "$DEST"
}

render() {
  local SRC=$1
  local DEST=$2

  mkdir -p "$(dirname "$DEST")"
  awk -f "$DOTFILES/render.awk" "$SRC" >"$DEST"
}

update() {
  if command -v winget >/dev/null 2>&1; then
    export WINDOWS=1
    export DESKTOP=1
    winget source update
    powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('MSYS2_PATH_TYPE', 'inherit', 'User')"
  elif command -v termux-info >/dev/null 2>&1; then
    export ANDROID=1
    pkg update -y
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "linux" ]]; then
    export LINUX=1
    if command -v apt >/dev/null 2>&1; then
      apt update -y
      if [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        export DESKTOP=1
        if ! command -v flatpak >/dev/null 2>&1; then
          apt install -y flatpak
          flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        fi
      fi
    elif command -v dnf >/dev/null 2>&1; then
      dnf makecache
      if ! command -v flatpak >/dev/null 2>&1 && [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        export DESKTOP=1
        dnf install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    elif command -v yum >/dev/null 2>&1; then
      yum makecache
      if ! command -v flatpak >/dev/null 2>&1 && [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        export DESKTOP=1
        yum install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    elif command -v pacman >/dev/null 2>&1; then
      pacman -Sy
      if ! command -v flatpak >/dev/null 2>&1 && [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        export DESKTOP=1
        pacman -S --noconfirm flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    elif command -v zypper >/dev/null 2>&1; then
      zypper refresh
      if ! command -v flatpak >/dev/null 2>&1 && [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        export DESKTOP=1
        zypper install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    else
      echo "Unsupported Linux package manager"
      exit 1
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "darwin" ]]; then
    export OSX=1
    export DESKTOP=1
    if ! command -v brew >/dev/null 2>&1; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  else
    echo "Unsupported OS for installation"
    exit 1
  fi
}

install() {
  local item type command package
  for item in "$@"; do
    IFS=':' read -r type command package <<<"$item"

    if [ "$command" == "winget" ]; then
      if winget list --id "$package" >/dev/null 2>&1; then
        echo "$package is already installed"
        continue
      fi
    elif [ "$command" == "flatpak" ]; then
      if flatpak info "$package" >/dev/null 2>&1; then
        echo "$package is already installed"
        continue
      fi
    elif [ "$command" == "brew" ]; then
      if brew list --cask "$package" >/dev/null 2>&1; then
        echo "$package is already installed"
        continue
      fi
    else
      if command -v "$command" >/dev/null 2>&1; then
        echo "$package is already installed"
        continue
      fi
    fi

    if [ "$type" == "run" ]; then
      echo "Installing $command by running: $package"
      eval "$package"
    elif [ "$type" == "gui" ]; then
      if comamnd -v winget >/dev/null 2>&1; then
        echo "Installing $package using winget"
        winget install -e --disable-interactivity "$package"
      elif command -v flatpak >/dev/null 2>&1; then
        echo "Installing $package using flatpak"
        flatpak install -y flathub "$package"
      elif command -v brew >/dev/null 2>&1; then
        echo "Installing $package using brew"
        brew install --cask "$package"
      else
        echo "Unsupported installation"
        continue
      fi
    elif [ "$type" == "cli" ]; then
      if command -v winget >/dev/null 2>&1; then
        echo "Installing $package using winget"
        winget install -e --disable-interactivity "$package"
      elif command -v pkg >/dev/null 2>&1; then
        echo "Installing $package using pkg"
        pkg install -y "$package"
      elif command -v apt >/dev/null 2>&1; then
        echo "Installing $package using apt"
        apt install -y "$package"
      elif command -v dnf >/dev/null 2>&1; then
        echo "Installing $package using dnf"
        dnf install -y "$package"
      elif command -v yum >/dev/null 2>&1; then
        echo "Installing $package using yum"
        yum install -y "$package"
      elif command -v pacman >/dev/null 2>&1; then
        echo "Installing $package using pacman"
        pacman -S --noconfirm "$package"
      elif command -v zypper >/dev/null 2>&1; then
        echo "Installing $package using zypper"
        zypper install -y "$package"
      elif command -v brew >/dev/null 2>&1; then
        echo "Installing $package using brew"
        brew install "$package"
      else
        echo "Unsupported installation"
        continue
      fi
    else
      echo "Unsupported installation type: $type"
      continue
    fi
  done
}

setup_home() {
  link "$DOTFILES/home/.vimrc" "$HOME/.vimrc"
  link "$DOTFILES/home/.bashrc" "$HOME/.bashrc"
  link "$DOTFILES/home/.profile" "$HOME/.profile"
  link "$DOTFILES/home/.profile" "$HOME/.zprofile"
  link "$DOTFILES/home/.gitconfig" "$HOME/.gitconfig"
  render "$DOTFILES/home/.tmux.conf" "$HOME/.tmux.conf"
  link "$DOTFILES/home/mise.toml" "$HOME/.config/mise/mise.toml"
  link "$DOTFILES/home/starship.toml" "$HOME/.config/starship.toml"
  git clone https://github.com/morhetz/gruvbox.git "$HOME/.vim" || true
  mise install -y

  if [ ! -f "$HOME/.gitconfig.local" ]; then
    touch "$HOME/.gitconfig.local"
  fi
  if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -b 4096 -C "$(hostname)" -f "$HOME/.ssh/id_rsa" -N ""
  fi
}

setup_fonts() {
  if [ -n "${WINDOWS:-}" ]; then
    for font in "$DOTFILES/fonts/"*.ttf; do
      copy "$font" "/c/Windows/Fonts/$(basename "$font")"
    done
  elif [ -n "${ANDROID:-}" ]; then
    copy "$DOTFILES/fonts/MesloLGMNerdFont-Regular.ttf" "$HOME/.termux/font.ttf"
    termux-reload-settings
  elif [ -n "${LINUX:-}" ]; then
    for font in "$DOTFILES/fonts/"*.ttf; do
      copy "$font" "$HOME/.local/share/fonts/$(basename "$font")"
    done
  elif [ -n "${OSX:-}" ]; then
    for font in "$DOTFILES/fonts/"*.ttf; do
      copy "$font" "/Library/Fonts/$(basename "$font")"
    done
  else
    echo "Unsupported OS for Fonts setup"
    return
  fi
}

setup_docker() {
  if [ -n "${WINDOWS:-}" ]; then
    DOCKER_HOME="$HOME/.docker"
  elif [ -n "${LINUX:-}" ]; then
    DOCKER_HOME="/etc/docker"
  elif [ -n "${OSX:-}" ]; then
    DOCKER_HOME="$HOME/.docker"
  else
    echo "Unsupported OS for Docker setup"
    return
  fi

  copy "$DOTFILES/docker/daemon.json" "$DOCKER_HOME/daemon.json"
}

setup_vscode() {
  if [ -n "${WINDOWS:-}" ]; then
    VSCODE_HOME="$HOME/AppData/Roaming/Code/User"
  elif [ -n "${LINUX:-}" ]; then
    VSCODE_HOME="$HOME/.var/app/com.visualstudio.code/config/Code/User"
  elif [ -n "${OSX:-}" ]; then
    VSCODE_HOME="$HOME/Library/Application Support/Code/User"
  else
    echo "Unsupported OS for VSCode setup"
    return
  fi

  link "$DOTFILES/vscode/settings.json" "$VSCODE_HOME/settings.json"
  link "$DOTFILES/vscode/keybindings.json" "$VSCODE_HOME/keybindings.json"
  if [ ! -f "$VSCODE_HOME/extensions.txt" ]; then
    link "$DOTFILES/vscode/extensions.txt" "$VSCODE_HOME/extensions.txt"
    sed 's/\r$//' "$VSCODE_HOME/extensions.txt" | while read -r extension; do
      code --install-extension "$extension"
    done
  fi
}

setup_alacritty() {
  if [ -n "${WINDOWS:-}" ]; then
    ALACRITTY_HOME="$HOME/AppData/Roaming/alacritty"
    powershell -NoProfile -Command '$lnk="C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Alacritty\Alacritty.lnk"; $ws=New-Object -ComObject WScript.Shell; $sc=$ws.CreateShortcut($lnk); $sc.WorkingDirectory=$env:USERPROFILE; $sc.Save()'
  elif [ -n "${LINUX:-}" ]; then
    ALACRITTY_HOME="$HOME/.var/app/com.alacritty.Alacritty/config/alacritty"
  elif [ -n "${OSX:-}" ]; then
    ALACRITTY_HOME="$HOME/.config/alacritty"
  else
    echo "Unsupported OS for Alacritty setup"
    return
  fi

  render "$DOTFILES/alacritty/alacritty.toml.tpl" "$ALACRITTY_HOME/alacritty.toml"
  read rows columns < <(alacritty -v -o 'window.startup_mode="Maximized"' -e echo | awk '/PTY dimensions:/{print $7, $9}') && lines=$(($rows * 2 / 3))
  sed -i.bak -e "s/lines = 0/lines = $lines/" -e "s/columns = 0/columns = $columns/" "$ALACRITTY_HOME/alacritty.toml" && rm "$ALACRITTY_HOME/alacritty.toml.bak"
  # TODO: Add Alacritty toggle hotkey setup (on-boot => first run)
}

update
if [ -n "${WINDOWS:-}" ]; then
  install \
    "cli:git:Git.Git" \
    "cli:vim:vim.vim" \
    "cli:wget:JernejSimoncic.Wget" \
    "run:tmux:cp -Rf \"$DOTFILES/home/tmux/\"* /usr/bin/" \
    "cli:mise:jdx.mise" \
    "cli:ssh:Microsoft.OpenSSH.Beta" \
    "cli:starship:Starship.Starship" \
    "gui:winget:Alacritty.Alacritty" \
    "gui:winget:Microsoft.VisualStudioCode" \
    "gui:winget:Docker.DockerDesktop" \
    "gui:winget:Mozilla.Firefox" \
    "gui:winget:SoftDeluxe.FreeDownloadManager" \
    "gui:winget:mpv.net"
elif [ -n "${ANDROID:-}" ]; then
  install \
    "cli:git:git" \
    "cli:vim:vim" \
    "cli:bash:bash" \
    "cli:curl:curl" \
    "cli:wget:wget" \
    "cli:tmux:tmux" \
    "cli:mise:mise" \
    "cli:ssh:openssh" \
    "cli:starship:starship"
elif [ -n "${LINUX:-}" ]; then
  install \
    "cli:git:git" \
    "cli:bash:bash" \
    "cli:curl:curl" \
    "cli:wget:wget" \
    "cli:tmux:tmux" \
    "cli:ssh:openssh openssh-client" \
    "cli:vim:vim" \
    "run:mise:curl https://mise.run | sh" \
    "run:starship:curl -sS https://starship.rs/install.sh | sh" \
    "gui:flatpak:com.alacritty.Alacritty" \
    "gui:flatpak:com.visualstudio.code" \
    "run:docker:curl -fsSL https://get.docker.com | sh" \
    "gui:flatpak:org.mozilla.firefox" \
    "gui:flatpak:org.freedownloadmanager.Manager" \
    "gui:flatpak:io.mpv.Mpv"
elif [ -n "${OSX:-}" ]; then
  install \
    "cli:git:git" \
    "cli:bash:bash" \
    "cli:curl:curl" \
    "cli:wget:wget" \
    "cli:tmux:tmux" \
    "cli:ssh:openssh" \
    "cli:vim:vim" \
    "cli:mise:mise" \
    "cli:starship:starship" \
    "gui:brew:alacritty" \
    "gui:brew:visual-studio-code" \
    "gui:brew:docker" \
    "gui:brew:firefox" \
    "gui:brew:free-download-manager" \
    "gui:brew:mpv"
fi

setup_home
setup_fonts
setup_docker
setup_vscode
setup_alacritty
