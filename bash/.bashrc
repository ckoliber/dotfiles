# Bashrc

# Auto-start tmux if not already in tmux and not in VS Code terminal and not in Termux
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -z "$VSCODE_INJECTION" ] && [ -z "$TERMUX_VERSION" ]; then
    # Check if any tmux sessions exist
    if tmux ls 2>/dev/null | grep -q .; then
        # Attach to the first available session
        exec tmux attach-session
    else
        # Create a new session
        exec tmux new-session
    fi
fi

# Initialize starship
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# Aliases
alias g='git'
alias k='kubectl'
alias ll='ls -lah'
