# Initialize mise
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi

# Auto-start tmux if not already in tmux and not in VS Code terminal and not in Termux
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -z "$VSCODE_INJECTION" ] && [ -z "$TERMUX_VERSION" ]; then
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
