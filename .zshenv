# ~/.config/zsh/.zshenv
# /etc/zshenv will run before this script

# ========== XDG base directories ==========
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"

# ========== Editor & Pager ==========
export EDITOR="nvim"
export VISUAL="nvim"

if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ========== GPG ==========
export GPG_TTY=$(tty)

# ========== Path & FPath ==========
if [[ -n "$ZSH_VERSION" ]]; then
    typeset -U path
    path=(
        "$HOME/bin"
        "$HOME/.local/bin"
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
        "/usr/local/bin"
        "/usr/local/sbin"
        "/opt/homebrew/opt/llvm/bin"
        "$HOME/.lmstudio/bin"
        $path
    )

    typeset -U fpath
    fpath=(
        "$HOME/.docker/completions"
        $fpath
    )
else
    export PATH="$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:/opt/homebrew/opt/llvm/bin:$HOME/.lmstudio/bin:$PATH"
fi

if [[ -f "$HOME/.local/bin/env" ]]; then
    . "$HOME/.local/bin/env"
fi
