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
sudo() { if [ "$(id -u)" -eq 0 ]; then "$@"; else command sudo "$@"; fi; }

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
  local pm repo name key rpm source install ssh=openssh docker=docker editor=codium repodir=/etc/yum.repos.d
  for pm in apt dnf zypper pacman; do has "$pm" && break; done
  has "$pm" || { echo "Unsupported Linux package manager" >&2 && exit 1; }

  case $pm in
  apt) install=(env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y) ssh=openssh-client docker=docker.io ;;
  dnf) install=(dnf install -y) ssh=openssh-clients docker=moby-engine ;;
  zypper) install=(zypper --non-interactive --gpg-auto-import-keys install) repodir=/etc/zypp/repos.d ;;
  # Arch ships mise in its own repos, and VSCodium's open source build as `code`
  pacman) install=(pacman -Syu --needed --noconfirm) editor=code ;;
  esac

  # Elsewhere mise and VSCodium come from their own repos: name, apt signing key, rpm .repo file, apt source
  local repos=(
    "mise https://mise.jdx.dev/gpg-key.pub https://mise.jdx.dev/rpm/mise.repo https://mise.jdx.dev/deb stable main"
    "vscodium https://repo.vscodium.dev/vscodium.gpg https://repo.vscodium.dev/vscodium.repo https://repo.vscodium.dev/deb vscodium main"
  )
  [ "$pm" = pacman ] || for repo in "${repos[@]}"; do
    read -r name key rpm source <<<"$repo"
    [ -n "$DESKTOP" ] || [ "$name" = mise ] || continue
    if [ "$pm" = apt ]; then
      sudo curl -fsSLo "/usr/share/keyrings/$name.asc" "$key"
      echo "deb [signed-by=/usr/share/keyrings/$name.asc] $source" | sudo tee "/etc/apt/sources.list.d/$name.list" >/dev/null
    else
      sudo curl -fsSLo "$repodir/$name.repo" "$rpm"
    fi
  done
  [ "$pm" != apt ] || sudo apt-get update

  local packages=(git bash curl wget "$ssh" mise)
  [ -z "$DESKTOP" ] || packages+=(alacritty mpv "$editor")
  # The distro's Docker conflicts with an existing docker-ce, so leave that one alone
  [ -z "$DESKTOP" ] || has docker || packages+=("$docker")
  sudo "${install[@]}" "${packages[@]}"

  [ -n "$DESKTOP" ] || return 0
  has brave-browser || curl -fsS https://dl.brave.com/install.sh | sh || echo "Brave failed to install, skipping" >&2
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

desktop_windows() {
  local fonts=$HOME/AppData/Local/Microsoft/Windows/Fonts user=$HOME/AppData/Roaming/VSCodium/User
  local startup="$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
  mkdir -p "$fonts" && cp -f "$DOTFILES"/fonts/*.ttf "$fonts/"
  render alacritty/alacritty.toml.tpl "$HOME/AppData/Roaming/alacritty/alacritty.toml"
  link vscode/settings.json "$user/settings.json"
  link vscode/keybindings.json "$user/keybindings.json"
  ! has codium || sed 's/\r$//; s/^/--install-extension /' "$DOTFILES/vscode/extensions.txt" | xargs codium --force
  setx MSYS2_PATH_TYPE inherit >/dev/null
  powershell -NoProfile -Command 'Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\*.ttf" | ForEach-Object { New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "$($_.BaseName) (TrueType)" -Value $_.FullName -Force | Out-Null }'
  powershell -NoProfile -Command '$lnk="C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Alacritty\Alacritty.lnk"; if (Test-Path $lnk) { $ws=New-Object -ComObject WScript.Shell; $sc=$ws.CreateShortcut($lnk); $sc.WorkingDirectory=$env:USERPROFILE; $sc.Save() }'

  link alacritty/quake.ahk "$startup/quake.ahk"
  cmd //c start "" "$(cygpath -w "$startup/quake.ahk")"
}

desktop_linux() {
  local fonts=$HOME/.local/share/fonts user=$HOME/.config/VSCodium/User codium=codium
  # Arch ships VSCodium's open source build as `code`
  ! has pacman || user="$HOME/.config/Code - OSS/User" codium=code
  mkdir -p "$fonts" && cp -f "$DOTFILES"/fonts/*.ttf "$fonts/"
  ! has fc-cache || fc-cache -f "$fonts"
  render alacritty/alacritty.toml.tpl "$HOME/.config/alacritty/alacritty.toml"
  link vscode/settings.json "$user/settings.json"
  link vscode/keybindings.json "$user/keybindings.json"
  ! has "$codium" || sed 's/\r$//; s/^/--install-extension /' "$DOTFILES/vscode/extensions.txt" | xargs "$codium" --force

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
  local user="$HOME/Library/Application Support/VSCodium/User"
  cp -f "$DOTFILES"/fonts/*.ttf "$HOME/Library/Fonts/"
  render alacritty/alacritty.toml.tpl "$HOME/.config/alacritty/alacritty.toml"
  link vscode/settings.json "$user/settings.json"
  link vscode/keybindings.json "$user/keybindings.json"
  ! has codium || sed 's/\r$//; s/^/--install-extension /' "$DOTFILES/vscode/extensions.txt" | xargs codium --force
  xattr -r -d com.apple.quarantine /Applications/Alacritty.app 2>/dev/null || true

  link alacritty/quake.lua "$HOME/.hammerspoon/init.lua"
  killall Hammerspoon 2>/dev/null || true
  open -g -a Hammerspoon
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

# home/ mirrors $HOME: *.tpl files are rendered, everything else is linked; then the global and per-org mise tools
home() {
  local dir
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

  for dir in "$HOME" "$HOME/github" "$HOME/gitlab" "$HOME/gitea"; do
    mise -C "$dir" install -y || echo "Some mise tools failed to install, run: mise -C $dir install" >&2
  done
}

"packages_$OS"
[ -z "$DESKTOP" ] || "desktop_$OS"
"agent_$OS"
home
echo "Dotfiles installed, open a new terminal to load them."
