# Interactive only
[[ $- == *i* ]] || return

# Initialize mise
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi

# Auto-start tmux if not already in tmux and not in VS Code terminal
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -z "$VSCODE_INJECTION" ]; then
  exec tmux new-session -A -s main
fi

# Initialize starship
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

# Aliases
alias g='git'
alias k='kubectl'
alias ll='ls -lah'
