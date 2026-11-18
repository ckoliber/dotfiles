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

Names, emails and SSH keys are kept per machine, never in this repo. Create one identity per Git host or org:

```bash
git identity <host>[/<path>] "<name>" "<email>"
# e.g. git identity github.com/ckoliber "Hoomaan Nemati" "ckoliber@gmail.com"
```

Repos with a remote on `host` (under `path`, in SSH or HTTPS form) commit as that identity and sign with `~/.ssh/<host>-<path>`. Each identity gets a `Host` block in `~/.ssh/config.d/<host>-<path>` with its key, so every tool (git, mise, ssh) uses it; an identity with a `path` (e.g. a second GitHub account) gets the alias `Host <host>-<path>` instead, and its URLs are rewritten to it. Add the printed public key to the Git host as an authentication and signing key. Repos without a matching remote refuse to commit.
