# lib/30-aliases.zsh — shortcuts and tool abstractions.
#
# Every alias to an optional tool is guarded. An alias pointing at a missing
# binary is worse than no alias: it turns a working command into
# "command not found", which is exactly what `rm` did on Linux.

# --- Listing --------------------------------------------------------------
if (( $+commands[eza] )); then
    alias ls='eza --icons --git'
    alias ll='eza -lh --icons --git'
    alias la='eza -A --icons --git'
    alias lla='eza -lAh --icons --git'
    alias lt='eza --tree --level=2 --icons'
    alias tree='eza --tree --icons'
else
    # GNU ls uses --color=auto; BSD/macOS ls uses -G.
    if [[ "$ZSH_OS" == macos ]]; then
        alias ls='ls -G'
    else
        alias ls='ls --color=auto'
    fi
    alias ll='ls -lh'
    alias la='ls -A'
    alias lla='ls -lAh'
fi

# --- Navigation -----------------------------------------------------------
(( $+commands[zoxide] )) && alias cd='z'

# --- Search ---------------------------------------------------------------
# NOTE: `grep` is deliberately NOT aliased to rg. ripgrep does not accept
# grep's flags (-q, -l, -E, POSIX classes) and recurses by default, so
# aliasing it silently breaks scripts and functions. The old alias forced
# lib/70-cmd.zsh to write `command grep` six times to work around itself.
(( $+commands[rg] )) && alias rgg='rg --color=auto'

# --- Diff / disk ----------------------------------------------------------
alias diff='diff --color=auto'
alias df='df -h'
alias du='du -h'

# --- Directories ----------------------------------------------------------
alias desk='cd ~/Desktop'
alias docs='cd ~/Documents'
alias dl='cd ~/Downloads'

# --- Tools ----------------------------------------------------------------
# macOS ships /usr/bin/trash; Linux's trash-cli installs `trash-put`.
if (( $+commands[trash] )); then
    alias rm='trash'
elif (( $+commands[trash-put] )); then
    alias rm='trash-put'
fi

(( $+commands[nvim] )) && alias vim='nvim'
(( $+commands[lstopo] )) && alias topo='lstopo --whole-io --physical --verbose --output-format'

# A function, not an alias: `code file.txt` must open that file, whereas
# `alias code='code .'` expanded it to `code . file.txt`.
if (( $+commands[code] )); then
    code() { command code "${@:-.}" }
fi

alias szsh='exec zsh'
alias uzp='zsh-update --plugins'

# --- Platform specifics ---------------------------------------------------
if [[ "$ZSH_OS" == macos ]]; then
    alias cdds='cd /Users/Shared'
    alias macinfo='system_profiler SPHardwareDataType SPDisplaysDataType SPSoftwareDataType SPStorageDataType'
else
    # Give Linux the macOS clipboard verbs, when a clipboard exists at all.
    if (( $+commands[xclip] )); then
        alias pbcopy='xclip -selection clipboard'
        alias pbpaste='xclip -selection clipboard -o'
    elif (( $+commands[xsel] )); then
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
    elif (( $+commands[wl-copy] )); then
        alias pbcopy='wl-copy'
        alias pbpaste='wl-paste'
    fi
fi

# --- Python ---------------------------------------------------------------
(( $+commands[python3] )) && alias python='python3'
(( $+commands[pip3] ))    && alias pip='pip3'
alias senv='source .venv/bin/activate'
