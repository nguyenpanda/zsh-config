# ~/.config/zsh/.zshrc — interactive shell setup.
#
# This file is an orchestrator: the actual configuration lives in lib/, loaded
# in filename order. The numeric prefixes ARE the load order, and it matters:
# platform detection has to come first, Oh My Zsh has to load before our
# aliases can override its own, and fzf needs the ignore list from 10-env.

# Powerlevel10k's instant prompt must stay at the very top: it has to run
# before anything that could write to stdout.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ========== History =======================================================
# Set before OMZ loads so its own defaults do not win.
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# ========== Shell behaviour ===============================================
setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT

# ========== Modules =======================================================
# (N) is nullglob: a missing or empty lib/ must not break the login shell.
for _zshrc_part in "$ZDOTDIR"/lib/*.zsh(N); do
    source "$_zshrc_part"
done
unset _zshrc_part

# ========== Completion styles =============================================
# After OMZ's compinit, or they get overwritten.
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ========== Prompt ========================================================
[[ -r "$ZDOTDIR/.p10k.zsh" ]]      && source "$ZDOTDIR/.p10k.zsh"
# Per-machine prompt tweaks (gitignored) — e.g. a box without Nerd Fonts.
[[ -r "$ZDOTDIR/p10k.local.zsh" ]] && source "$ZDOTDIR/p10k.local.zsh"

# ========== Machine-local overrides =======================================
# Both gitignored. Sourced last so they can override anything above.
[[ -r "$ZDOTDIR/local.zsh" ]]   && source "$ZDOTDIR/local.zsh"
[[ -r "$ZDOTDIR/secrets.zsh" ]] && source "$ZDOTDIR/secrets.zsh"

true  # never let the last conditional set a non-zero exit status
