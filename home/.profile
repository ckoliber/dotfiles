#!/bin/bash

# Path setup
unset PROMPT_COMMAND
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

# Homebrew environment (Apple Silicon or Intel), the installer doesn't add it to shells
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# SSH agent (should only start ONCE per session)
if command -v ssh-agent &>/dev/null && [ -z "$SSH_AUTH_SOCK" ]; then
  eval $(ssh-agent | sed 's/SSH_AUTH_SOCK=\([^;]*\);/SSH_AUTH_SOCK="\1";/')
  ssh-add 2>/dev/null
fi

# Load .bashrc when running bash
if [ -n "$BASH_VERSION" ] && [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
