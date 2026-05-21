# ~/.config/zsh/.zshenv
# /etc/zshenv will run before this script

# ========== XDG base directories ==========
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ========== Editor ==========
export EDITOR="nvim"
export VISUAL="nvim"

# ========== Pager ==========
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ========== GPG ==========
export GPG_TTY=$(tty)

# ========== Path ==========
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# LLVM
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/nguyenpanda/.lmstudio/bin"
# End of LM Studio CLI section
