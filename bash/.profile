#!/bin/bash

# Path setup
export PATH="$PATH:$HOME/.local/bin"

# SSH agent
if command -v ssh-agent &>/dev/null && command -v ssh-add &>/dev/null; then
    eval $(ssh-agent) && ssh-add 2>/dev/null
fi

# Initialize mise
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
