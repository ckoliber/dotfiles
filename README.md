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
