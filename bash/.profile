#!/bin/bash

# Path setup
export PATH="$PATH:$HOME/.local/bin"

# SSH agent (should only start ONCE per session)
if command -v ssh-agent &>/dev/null && [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent) && ssh-add 2>/dev/null
fi

# Initialize mise
if command -v mise &>/dev/null; then
    if command -v cmd.exe &>/dev/null; then
        eval "$(mise activate bash --shims)"
    else
        eval "$(mise activate bash)"
    fi
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
