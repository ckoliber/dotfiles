#!/usr/bin/env bash
# Picked up automatically by GitHub Codespaces, Dev Containers, DevPod, Coder, etc.
set -euo pipefail

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

case "$(uname -s)" in
MINGW* | MSYS* | CYGWIN*) OS=windows ;;
Linux) OS=linux ;;
Darwin) OS=osx ;;
*) echo "Unsupported OS: $(uname -s)" >&2 && exit 1 ;;
esac

# Containers and display-less Linux get the CLI setup only
DESKTOP=1
if [ -n "${CODESPACES:-}${REMOTE_CONTAINERS:-}" ] || [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
  DESKTOP=
elif [ "$OS" = linux ] && [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  DESKTOP=
fi

[ "$(id -u)" -ne 0 ] || sudo() { "$@"; }
has() { command -v "$1" >/dev/null 2>&1; }

link() {
  mkdir -p "$(dirname "$2")"
  if [ "$OS" = windows ]; then
    cp -f "$DOTFILES/$1" "$2"
  else
    [ ! -e "$2" ] || [ -L "$2" ] || mv "$2" "$2.bak"
    ln -sfn "$DOTFILES/$1" "$2"
  fi
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

packages_windows() {
  local id
  for id in Git.Git jdx.mise JernejSimoncic.Wget Microsoft.OpenSSH.Beta marlocarlo.psmux Alacritty.Alacritty AutoHotkey.AutoHotkey Bitwarden.Bitwarden VSCodium.VSCodium Docker.DockerDesktop Brave.Brave mpv.net; do
    # Fails when there's nothing newer to upgrade to
    winget install -e --id "$id" --disable-interactivity --accept-source-agreements --accept-package-agreements || true
  done
  # Installers update PATH in the registry only, pick it up for the rest of this run
  PATH="$PATH:$(cygpath -p "$(powershell -NoProfile -Command '[Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")' | tr -d '\r')")"
}

packages_linux() {
  local pkgs="git bash curl wget tmux"
  local key=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
  local repo="[vscodium]\nname=VSCodium\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=$key\n"
  local bitwarden="https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant"

  if has apt-get; then
    if [ -n "$DESKTOP" ]; then
      curl -fsSL "$key" | sudo tee /usr/share/keyrings/vscodium.asc >/dev/null
      echo "deb [signed-by=/usr/share/keyrings/vscodium.asc] https://download.vscodium.com/debs vscodium main" | sudo tee /etc/apt/sources.list.d/vscodium.list >/dev/null
      curl -fsSL "$bitwarden=deb" -o /tmp/bitwarden.deb
      pkgs+=" alacritty mpv codium /tmp/bitwarden.deb $(has docker || echo docker.io)"
    fi
    sudo apt-get update
    sudo env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y openssh-client $pkgs
  elif has dnf; then
    if [ -n "$DESKTOP" ]; then
      sudo rpmkeys --import "$key"
      printf "$repo" | sudo tee /etc/yum.repos.d/vscodium.repo >/dev/null
      curl -fsSL "$bitwarden=rpm" -o /tmp/bitwarden.rpm
      pkgs+=" alacritty mpv codium /tmp/bitwarden.rpm $(has docker || echo moby-engine)"
    fi
    sudo dnf install -y openssh-clients $pkgs
  elif has zypper; then
    if [ -n "$DESKTOP" ]; then
      sudo rpmkeys --import "$key"
      printf "$repo" | sudo tee /etc/zypp/repos.d/vscodium.repo >/dev/null
      curl -fsSL "$bitwarden=rpm" -o /tmp/bitwarden.rpm
      pkgs+=" alacritty mpv codium /tmp/bitwarden.rpm $(has docker || echo docker)"
    fi
    sudo zypper --non-interactive --gpg-auto-import-keys install --allow-unsigned-rpm openssh $pkgs
  elif has pacman; then
    [ -z "$DESKTOP" ] || pkgs+=" alacritty mpv code bitwarden $(has docker || echo docker)"
    sudo pacman -Syu --needed --noconfirm openssh $pkgs
  else
    echo "Unsupported Linux package manager" >&2 && exit 1
  fi

  [ -z "$DESKTOP" ] || curl -fsS https://dl.brave.com/install.sh | sh || echo "Brave failed to install, skipping" >&2
}

packages_osx() {
  export PATH="/opt/homebrew/bin:$PATH" HOMEBREW_NO_ASK=1
  has brew || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install git bash curl wget openssh tmux
  brew install --cask alacritty hammerspoon bitwarden vscodium docker-desktop brave-browser stolendata-mpv
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
  link home/.profile "$HOME/.bash_profile"
  [ -e "$HOME/.vim" ] || git clone --depth 1 https://github.com/morhetz/gruvbox.git "$HOME/.vim"
}

tools() {
  export PATH="$HOME/.local/bin:$PATH"
  has mise || curl -fsSL https://mise.run | sh
  mise install -y || echo "Some mise tools failed to install, run: mise install" >&2
}

apps() {
  local codium=${4:-codium}
  mkdir -p "$1" && cp -f "$DOTFILES"/fonts/*.ttf "$1/"
  render alacritty/alacritty.toml.tpl "$2/alacritty.toml"
  link vscode/settings.json "$3/settings.json"
  link vscode/keybindings.json "$3/keybindings.json"
  ! has "$codium" || sed 's/\r$//; s/^/--install-extension /' "$DOTFILES/vscode/extensions.txt" | xargs "$codium" --force
}

desktop_windows() {
  local startup="$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
  apps "$HOME/AppData/Local/Microsoft/Windows/Fonts" "$HOME/AppData/Roaming/alacritty" "$HOME/AppData/Roaming/VSCodium/User"
  setx MSYS2_PATH_TYPE inherit >/dev/null
  powershell -NoProfile -Command 'Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\*.ttf" | ForEach-Object { New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "$($_.BaseName) (TrueType)" -Value $_.FullName -Force | Out-Null }'
  powershell -NoProfile -Command '$lnk="C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Alacritty\Alacritty.lnk"; if (Test-Path $lnk) { $ws=New-Object -ComObject WScript.Shell; $sc=$ws.CreateShortcut($lnk); $sc.WorkingDirectory=$env:USERPROFILE; $sc.Save() }'

  link alacritty/quake.ahk "$startup/quake.ahk"
  cmd //c start "" "$(cygpath -w "$startup/quake.ahk")"
}

desktop_linux() {
  # Arch ships VSCodium's open source build as `code`
  if has pacman; then
    apps "$HOME/.local/share/fonts" "$HOME/.config/alacritty" "$HOME/.config/Code - OSS/User" code
  else
    apps "$HOME/.local/share/fonts" "$HOME/.config/alacritty" "$HOME/.config/VSCodium/User"
  fi
  ! has fc-cache || fc-cache -f "$HOME/.local/share/fonts"

  [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]] || { echo "Quake mode needs GNOME, skipping" >&2 && return; }
  local favorites
  favorites=$(gsettings get org.gnome.shell favorite-apps | sed -E "s/@as //; s/'Alacritty\.desktop',? ?//; s/^\[/['Alacritty.desktop', /; s/, \]$/]/")
  gsettings set org.gnome.shell favorite-apps "$favorites"
  gsettings set org.gnome.shell.keybindings switch-to-application-1 "['<Control>1']"
  # Ubuntu's dock replaces the shell's app hotkeys with its own
  ! gsettings writable org.gnome.shell.extensions.dash-to-dock app-hotkey-1 >/dev/null 2>&1 ||
    gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-1 "['<Control>1']"
}

desktop_osx() {
  apps "$HOME/Library/Fonts" "$HOME/.config/alacritty" "$HOME/Library/Application Support/VSCodium/User"
  xattr -r -d com.apple.quarantine /Applications/Alacritty.app 2>/dev/null || true

  link alacritty/quake.lua "$HOME/.hammerspoon/init.lua"
  killall Hammerspoon 2>/dev/null || true
  open -g -a Hammerspoon
}

"packages_$OS"
home
tools
[ -z "$DESKTOP" ] || "desktop_$OS"
echo "Dotfiles installed, open a new terminal to load them."
