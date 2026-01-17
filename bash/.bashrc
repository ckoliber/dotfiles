# Bashrc

# Auto-start tmux if not already in tmux and not in VS Code terminal
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -z "$VSCODE_INJECTION" ]; then
    # Check if any tmux sessions exist
    if tmux ls 2>/dev/null | grep -q .; then
        # Attach to the first available session
        exec tmux attach-session
    else
        # Create a new session
        exec tmux new-session
    fi
fi

# Initialize direnv
if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi

# Initialize starship
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# Aliases
alias g='git'
alias ll='ls -lah'

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups

# Append to history file, don't overwrite
shopt -s histappend

# Save and reload history after each command
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
