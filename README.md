# Dotfiles

Personal development environment for Windows, Linux and macOS.

## Install

```bash
git clone https://github.com/ckoliber/dotfiles.git
bash dotfiles/install.sh
```

Rerun both to update. In Codespaces and Dev Containers, set this repo as your dotfiles repo (CLI setup only).

- **Windows:** first install Git Bash, then run the above from Git Bash as **Administrator**:
  ```powershell
  winget install -e --disable-interactivity Git.Git --custom "/o:SSHOption=ExternalOpenSSH"
  ```
- **macOS:** to swap Command and Control, go to **System Settings → Keyboard → Modifier Keys**.

## Orgs

Each org is a folder with its own `mise.toml`; nothing is logged in machine-wide. This repo sets up `~/github`, `~/gitea` (on the VPN) and `~/gitlab`, one folder per Git provider account. Clone repos into their provider's folder, then run once per folder:

```bash
mise run setup
```

It logs the provider CLI in, creates this machine's SSH key, adds it to the account (auth and signing) and writes the git identity from the account. Repos in the folder then commit, sign and push with it, from terminals and GUIs alike; repos outside any org folder have no identity. All state stays in the folder's `.config`, plus one `includeIf` line in `~/.gitconfig` (machine-local, untracked).

To retire an org, delete its folder and its key on the provider.
