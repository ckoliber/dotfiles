# Dotfiles

## Install mise

- **macOS / Linux:** `curl -fsSL https://mise.run | sh && export PATH="$HOME/.local/bin:$PATH"`
- **Windows** (PowerShell as Administrator): `winget install -e Git.Git jdx.mise`, then open **Git Bash** as Administrator

## Install dotfiles

```bash
mise -E dev bootstrap --from https://github.com/ckoliber/dotfiles.git --from-dir ~/.dotfiles
```

Open a new terminal when it finishes. To update later, run the same command with `--update`.

## Projects

Select shared profiles in the project's `.miserc.toml`:

```toml
env = ["always", "docker"]
```

CI workflow and Renovate preset:

```yaml
jobs:
  cicd:
    uses: ckoliber/dotfiles/.github/workflows/mise.yml@main
    with:
      script: mise run docker:build --version 1.0.0
```

```json
{ "extends": ["local>ckoliber/dotfiles"] }
```
