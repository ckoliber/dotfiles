#!/usr/bin/env bash
# Picked up automatically by GitHub Codespaces, Dev Containers, DevPod, Coder, etc.
set -euo pipefail

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

KERNEL=$(uname -s)
if [[ $KERNEL == MINGW* || $KERNEL == MSYS* || $KERNEL == CYGWIN* ]]; then
  OS=windows
elif [ "$KERNEL" = Linux ]; then
  OS=linux
elif [ "$KERNEL" = Darwin ]; then
  OS=osx
else
  echo "Unsupported OS: $KERNEL" >&2 && exit 1
fi

# Containers and display-less Linux get the CLI setup only
DESKTOP=1
if [ -n "${CODESPACES:-}${REMOTE_CONTAINERS:-}" ] || [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
  DESKTOP=
elif [ "$OS" = linux ] && [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  DESKTOP=
fi

has() { command -v "$1" >/dev/null 2>&1; }
root() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

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
  local id ids=(jdx.mise JernejSimoncic.Wget Microsoft.OpenSSH.Beta)
  [ -z "$DESKTOP" ] || ids+=(Alacritty.Alacritty AutoHotkey.AutoHotkey VSCodium.VSCodium Docker.DockerDesktop Brave.Brave mpv.net)
  for id in "${ids[@]}"; do
    local args=(--id "$id" --exact --source winget --accept-source-agreements --disable-interactivity)
    winget list "${args[@]}" >/dev/null || winget install "${args[@]}" --accept-package-agreements
  done
  # Installers update PATH in the registry only, pick it up for the rest of this run
  PATH="$PATH:$(cygpath -p "$(powershell -NoProfile -Command '[Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")' | tr -d '\r')")"
}

packages_linux() {
  local pm name install refresh= ssh=openssh docker=docker editor=codium repos=/etc/yum.repos.d
  for pm in apt dnf zypper pacman; do has "$pm" && break; done
  has "$pm" || { echo "Unsupported Linux package manager" >&2 && exit 1; }

  if [ "$pm" = apt ]; then
    install=(env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y)
    ssh=openssh-client docker=docker.io refresh=1
  elif [ "$pm" = dnf ]; then
    install=(dnf install -y)
    ssh=openssh-clients docker=moby-engine
  elif [ "$pm" = zypper ]; then
    install=(zypper --non-interactive --gpg-auto-import-keys install)
    repos=/etc/zypp/repos.d
  elif [ "$pm" = pacman ]; then
    install=(pacman -S --needed --noconfirm)
    # Arch ships VSCodium's open source build as `code`, and mise in its own repos
    editor=code
    root pacman -Syu --noconfirm
  fi

  for name in git bash curl wget; do need "$name"; done
  need ssh "$ssh"
  has mise || [ "$pm" = pacman ] || repo mise https://mise.jdx.dev/gpg-key.pub "https://mise.jdx.dev/deb stable main" https://mise.jdx.dev/rpm/mise.repo
  need mise

  [ -n "$DESKTOP" ] || return 0
  need alacritty
  need mpv
  need docker "$docker"
  has "$editor" || [ "$pm" = pacman ] || repo vscodium https://repo.vscodium.dev/vscodium.gpg "https://repo.vscodium.dev/deb vscodium main" https://repo.vscodium.dev/vscodium.repo
  need "$editor"
  has brave-browser || curl -fsS https://dl.brave.com/install.sh | sh || echo "Brave failed to install, skipping" >&2
}

# Installs package $2 (default $1) unless command $1 exists, refreshing apt's lists first if a repo was added
need() {
  has "$1" && return 0
  if [ -n "$refresh" ]; then
    root apt-get update
    refresh=
  fi
  root "${install[@]}" "${2:-$1}"
}

# Adds repo $1: for apt its signing key $2 and source $3, else the .repo file $4
repo() {
  if [ "$pm" = apt ]; then
    need gpg
    curl -fsSL "$2" | gpg --dearmor | root tee "/usr/share/keyrings/$1.gpg" >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/$1.gpg] $3" | root tee "/etc/apt/sources.list.d/$1.list" >/dev/null
    refresh=1
  else
    root curl -fsSLo "$repos/$1.repo" "$4"
  fi
}

packages_osx() {
  export PATH="/opt/homebrew/bin:$PATH" HOMEBREW_NO_ASK=1 HOMEBREW_NO_INSTALL_UPGRADE=1
  has brew || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install git bash curl wget openssh mise

  [ -n "$DESKTOP" ] || return 0
  brew install mpv
  brew install --cask hammerspoon vscodium docker-desktop brave-browser
  # Homebrew disabled its cask (it fails Gatekeeper), so Alacritty comes from its release DMG
  if [ ! -d /Applications/Alacritty.app ] && [ ! -d "$HOME/Applications/Alacritty.app" ]; then
    local work version=v0.17.0
    work=$(mktemp -d)
    curl -fsSLo "$work/alacritty.dmg" "https://github.com/alacritty/alacritty/releases/download/$version/Alacritty-$version.dmg"
    hdiutil attach -nobrowse -readonly -mountpoint "$work/mount" "$work/alacritty.dmg" >/dev/null
    mkdir -p "$HOME/Applications"
    ditto "$work/mount/Alacritty.app" "$HOME/Applications/Alacritty.app"
    hdiutil detach "$work/mount" >/dev/null
    rm -rf "$work"
  fi
}

# home/ mirrors $HOME: *.tpl files are rendered, everything else is linked
home() {
  (cd "$DOTFILES/home" && find . -type f) | while read -r file; do
    file=${file#./}
    if [[ $file == *.tpl ]]; then
      render "home/$file" "$HOME/${file%.tpl}"
    else
      link "home/$file" "$HOME/$file"
    fi
  done
  touch "$HOME/.gitconfig"
  link home/.profile "$HOME/.zprofile"
  link home/.profile "$HOME/.bash_profile"
  [ -e "$HOME/.vim" ] || git clone --depth 1 https://github.com/morhetz/gruvbox.git "$HOME/.vim"
}

agent_windows() {
  powershell -NoProfile -Command 'Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent'
  # Git outside Git Bash (e.g. VSCodium) must use Windows OpenSSH too
  setx GIT_SSH 'C:\Program Files\OpenSSH\ssh.exe' >/dev/null
}

agent_linux() {
  # Containers without systemd get the host's agent forwarded instead
  systemctl --user show-environment >/dev/null 2>&1 || return 0
  # The unit publishes its socket to the session, so terminals and desktop apps started from it get SSH_AUTH_SOCK
  mkdir -p "$HOME/.config/systemd/user"
  printf '%s\n' \
    '[Unit]' \
    'Description=SSH key agent' \
    '' \
    '[Service]' \
    'ExecStartPre=-/bin/rm -f %t/ssh-agent.socket' \
    'ExecStart=/usr/bin/ssh-agent -D -a %t/ssh-agent.socket' \
    'ExecStartPost=/usr/bin/systemctl --user set-environment SSH_AUTH_SOCK=%t/ssh-agent.socket' \
    'ExecStopPost=/usr/bin/systemctl --user unset-environment SSH_AUTH_SOCK' \
    '' \
    '[Install]' \
    'WantedBy=default.target' >"$HOME/.config/systemd/user/ssh-agent.service"
  systemctl --user daemon-reload
  systemctl --user enable --now ssh-agent
}

agent_osx() {
  : # launchd already runs it for every login session
}

tools() {
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
"agent_$OS"
[ -z "$DESKTOP" ] || "desktop_$OS"
echo "Dotfiles installed, open a new terminal to load them."
