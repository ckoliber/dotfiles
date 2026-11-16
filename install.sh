#!/usr/bin/env bash
# Picked up automatically by GitHub Codespaces, Dev Containers, DevPod, Coder, etc.
set -euo pipefail

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

case "$(uname -s)" in
Linux) OS=linux ;;
Darwin) OS=macos ;;
MINGW* | MSYS* | CYGWIN*) OS=windows ;;
*) echo "Unsupported OS: $(uname -s)" >&2 && exit 1 ;;
esac

# Containers (Codespaces, Dev Containers) and display-less Linux get the CLI setup only
[ -n "${CODESPACES:-}${REMOTE_CONTAINERS:-}" ] || [ -f /.dockerenv ] || [ -f /run/.containerenv ] && CONTAINER=1 || CONTAINER=
[ -z "$CONTAINER" ] && { [ "$OS" != linux ] || [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; } && DESKTOP=1 || DESKTOP=

[ "$(id -u)" -ne 0 ] || sudo() { "$@"; }
has() { command -v "$1" >/dev/null 2>&1; }

# Print the items for which `<check> <item>` fails, e.g. missing "brew list --cask" mpv
missing() {
  local check=$1 item
  shift
  for item; do $check "$item" >/dev/null 2>&1 || printf '%s ' "$item"; done
}

link() {
  mkdir -p "$(dirname "$2")"
  [ "$OS" != windows ] || { cp -f "$DOTFILES/$1" "$2" && return; }
  [ ! -e "$2" ] || [ -L "$2" ] || mv "$2" "$2.bak"
  ln -sfn "$DOTFILES/$1" "$2"
}

# Renders the `{% if os() == "..." %}` / elif / else / endif subset of Tera, one directive per line
render() {
  mkdir -p "$(dirname "$2")" && rm -f "$2"
  awk -v os="$OS" '
    /^[{]%/ {
      n = $0; sub(/.*os\(\) == "/, "", n); sub(/".*/, "", n)
      if ($0 ~ /^[{]%-? *if /) { done = (n == os); skip = !done }
      else if ($0 ~ /^[{]%-? *elif /) { skip = done || n != os; done = done || n == os }
      else if ($0 ~ /^[{]%-? *else/) { skip = done; done = 1 }
      else if ($0 ~ /^[{]%-? *endif/) { skip = 0 }
      next
    }
    !skip
  ' "$DOTFILES/$1" >"$2"
}

packages() {
  local pkgs
  case "$OS" in
  linux)
    pkgs=$(missing has git bash curl wget ssh tmux ${DESKTOP:+flatpak})
    if [ -z "$pkgs" ]; then
      :
    elif has apt-get; then
      sudo apt-get update -y && sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y ${pkgs/ssh /openssh-client }
    elif has dnf; then
      sudo dnf install -y ${pkgs/ssh /openssh-clients }
    elif has pacman; then
      sudo pacman -Sy --noconfirm ${pkgs/ssh /openssh }
    elif has zypper; then
      sudo zypper install -y ${pkgs/ssh /openssh }
    else
      echo "Unsupported Linux package manager" >&2 && exit 1
    fi
    [ -n "$CONTAINER" ] || has docker || curl -fsSL https://get.docker.com | sh
    [ -n "$DESKTOP" ] || return 0
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    pkgs=$(missing "flatpak info" com.alacritty.Alacritty com.bitwarden.desktop com.vscodium.codium com.brave.Browser io.mpv.Mpv)
    [ -z "$pkgs" ] || sudo flatpak install -y flathub $pkgs
    [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]] || return 0
    for pkg in $(missing "gnome-extensions info" quake-terminal@diegodario88.github.io); do
      curl -fsSL "https://extensions.gnome.org/download-extension/$pkg.shell-extension.zip?shell_version=$(gnome-shell --version | awk '{print int($3)}')" -o "/tmp/$pkg.zip"
      gnome-extensions install --force "/tmp/$pkg.zip" && rm "/tmp/$pkg.zip"
    done
    ;;
  macos)
    has brew || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ ! -x /opt/homebrew/bin/brew ] || eval "$(/opt/homebrew/bin/brew shellenv)"
    pkgs=$(missing "brew list --formula" git bash curl wget openssh tmux)
    [ -z "$pkgs" ] || brew install $pkgs
    pkgs=$(missing "brew list --cask" alacritty hammerspoon bitwarden vscodium docker-desktop brave-browser mpv)
    [ -z "$pkgs" ] || brew install --cask $pkgs
    ;;
  windows)
    for pkg in $(missing "winget list -e --id" Git.Git jdx.mise JernejSimoncic.Wget Microsoft.OpenSSH.Beta marlocarlo.psmux Alacritty.Alacritty AutoHotkey.AutoHotkey Bitwarden.Bitwarden VSCodium.VSCodium Docker.DockerDesktop Brave.Brave mpv.net); do
      winget install -e --id "$pkg" --disable-interactivity --accept-source-agreements --accept-package-agreements
    done
    ;;
  esac
}

# home/ mirrors $HOME: *.tpl files are rendered, everything else is linked
home() {
  (cd "$DOTFILES/home" && find . -type f) | while read -r file; do
    file=${file#./}
    case "$file" in
    *.tpl) render "home/$file" "$HOME/${file%.tpl}" ;;
    *) link "home/$file" "$HOME/$file" ;;
    esac
  done
  link home/.profile "$HOME/.zprofile"
  [ -e "$HOME/.vim" ] || git clone --depth 1 https://github.com/morhetz/gruvbox.git "$HOME/.vim"
  [ -n "$CONTAINER" ] || [ -f "$HOME/.ssh/id_rsa" ] || { mkdir -p "$HOME/.ssh" && ssh-keygen -t rsa -b 4096 -C "$(hostname)" -f "$HOME/.ssh/id_rsa" -N ""; }
}

tools() {
  export PATH="$HOME/.local/bin:$HOME/AppData/Local/Microsoft/WinGet/Links:$PATH"
  has mise || curl -fsSL https://mise.run | sh
  mise install -y
}

desktop() {
  local fonts alacritty codium uuid=quake-terminal@diegodario88.github.io
  case "$OS" in
  linux)
    fonts=$HOME/.local/share/fonts
    alacritty=$HOME/.var/app/com.alacritty.Alacritty/config/alacritty
    codium=$HOME/.var/app/com.vscodium.codium/config/VSCodium/User
    ;;
  macos)
    fonts=$HOME/Library/Fonts
    alacritty=$HOME/.config/alacritty
    codium="$HOME/Library/Application Support/VSCodium/User"
    ;;
  windows)
    fonts=$HOME/AppData/Local/Microsoft/Windows/Fonts
    alacritty=$HOME/AppData/Roaming/alacritty
    codium=$HOME/AppData/Roaming/VSCodium/User
    ;;
  esac

  mkdir -p "$fonts" && cp -f "$DOTFILES"/fonts/*.ttf "$fonts/"
  render alacritty/alacritty.toml.tpl "$alacritty/alacritty.toml"
  link vscode/settings.json "$codium/settings.json"
  link vscode/keybindings.json "$codium/keybindings.json"
  ! has codium || sed 's/\r$//; s/^/--install-extension /' "$DOTFILES/vscode/extensions.txt" | xargs codium

  # Quake mode: a global Ctrl+1 shows Alacritty, resized to the top half of the screen on every show
  case "$OS" in
  linux)
    ! has fc-cache || fc-cache -f "$fonts"
    [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]] || { echo "Quake mode needs GNOME, skipping" >&2 && return; }
    dconf load /org/gnome/shell/extensions/quake-terminal/ <"$DOTFILES/alacritty/quake.dconf"
    gnome-extensions enable "$uuid" 2>/dev/null || echo "Log out and back in, then run: gnome-extensions enable $uuid" >&2
    ;;
  macos)
    xattr -r -d com.apple.quarantine /Applications/Alacritty.app 2>/dev/null || true
    link alacritty/quake.lua "$HOME/.hammerspoon/init.lua"
    killall Hammerspoon 2>/dev/null || true
    open -g -a Hammerspoon
    ;;
  windows)
    local startup="$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
    setx MSYS2_PATH_TYPE inherit >/dev/null
    powershell -NoProfile -Command 'Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\*.ttf" | ForEach-Object { New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "$($_.BaseName) (TrueType)" -Value $_.FullName -Force | Out-Null }'
    powershell -NoProfile -Command '$lnk="C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Alacritty\Alacritty.lnk"; if (Test-Path $lnk) { $ws=New-Object -ComObject WScript.Shell; $sc=$ws.CreateShortcut($lnk); $sc.WorkingDirectory=$env:USERPROFILE; $sc.Save() }'
    link alacritty/quake.ahk "$startup/quake.ahk"
    cmd //c start "" "$(cygpath -w "$startup/quake.ahk")"
    ;;
  esac
}

packages
home
tools
[ -z "$DESKTOP" ] || desktop
echo "Dotfiles installed, open a new terminal to load them."
