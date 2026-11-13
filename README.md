# Dotfiles

## Install

### macOS / Linux

```bash
curl -fsSL https://mise.run | sh
~/.local/bin/mise -E desktop bootstrap --from https://github.com/ckoliber/dotfiles.git --from-dir ~/.dotfiles --save-env
```

### Windows

Open PowerShell as Administrator:

```powershell
winget install -e --disable-interactivity Git.Git
winget install -e --disable-interactivity jdx.mise
```

Then open **Git Bash** as Administrator:

```bash
mise -E desktop bootstrap --from https://github.com/ckoliber/dotfiles.git --from-dir ~/.dotfiles --save-env
```

Open a new terminal when it finishes.

On macOS, swap Command and Control in **System Settings → Keyboard → Modifier
Keys**.

## Update

```bash
mise bootstrap --from https://github.com/ckoliber/dotfiles.git --from-dir ~/.dotfiles --update
```

## Projects

Select shared profiles in the project's `.miserc.toml`:

```toml
env = ["base", "docker"]
```

In CI, use the reusable workflow:

```yaml
jobs:
  cicd:
    uses: ckoliber/dotfiles/.github/workflows/mise.yml@main
    with:
      script: mise run docker:build --version 1.0.0
```

Renovate:

```json
{
  "extends": ["local>ckoliber/dotfiles"]
}
```
