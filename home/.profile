#!/bin/bash

# Path setup
unset PROMPT_COMMAND
export PATH="$PATH:$HOME/.local/bin"

# SSH agent (should only start ONCE per session)
if command -v ssh-agent &>/dev/null && [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent | sed 's/SSH_AUTH_SOCK=\([^;]*\);/SSH_AUTH_SOCK="\1";/')
    ssh-add 2>/dev/null
fi

# Initialize mise
if command -v mise &>/dev/null; then
    eval "$(mise activate bash --shims)"
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
