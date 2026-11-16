# Dotfiles

Personal configuration files for development environment setup.

## Quick Start

### Windows Users

First, install Git Bash:

```powershell
winget install -e --disable-interactivity Git.Git
```

Now open your **Git Bash** shell in **Administrator** mode.

---

### Android Users

<!-- TODO -->

---

### OSX Users

To swap the Command and Control keys in OSX:

1. Open **System Settings**
2. Go to **Keyboard**
3. Open **Modifier Keys**
4. Set **Control** to **Command**
5. Set **Command** to **Control**

---

### Codespaces / Dev Containers Users

Set this repository as your dotfiles repository, `install.sh` runs automatically (CLI setup only).

---

### Installation

```bash
git clone https://github.com/ckoliber/dotfiles.git
bash dotfiles/install.sh
```

To update later, run `git -C dotfiles pull` and `bash dotfiles/install.sh` again.

---

### Git Identities

Names, emails and SSH keys are kept per machine, never in this repo. Create one identity per org:

```bash
git identity <org> "<name>" <email> [dir]
```

Repos under `dir` (default `~/<org>/`) commit as that identity and use `~/.ssh/<org>` for both SSH and commit signing; add the printed public key to the org's Git host as an authentication and signing key. Commits outside an org folder are refused.
