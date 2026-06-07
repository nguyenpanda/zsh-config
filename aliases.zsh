# Some useful command
# samply        (Command-line tool for sampling and profiling programs on MacOS)
# ruff          (Python formatter and linter)
# hyperfine     (Command-line benchmarking tool)
# lazygit       (Git UI)
# termshark     (TUI for Wireshark)
# iperf3        (Network performance measurement tool)
# httpie        (Command-line HTTP client - like curl, but easier to use)
# glow          (To view Markdown file)
# tlmgr         (Tex Live package management)

# eza (Modern replacement for ls)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --git'
    alias ll='eza -lh --icons --git'
    alias la='eza -A --icons --git'
    alias lla='eza -lAh --icons --git'
    alias lt='eza --tree --level=2 --icons'
    alias tree='eza --tree --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -A'
    alias lla='ls -lAh'
fi

# zoxide (Smart cd)
if command -v zoxide >/dev/null 2>&1; then
    alias cd='z'
fi

# ripgrep
if command -v rg >/dev/null 2>&1; then
    alias grep='rg --color=auto'
fi

# diff
alias diff='diff --color=auto'

# Disk
alias df='df -h'
alias du='du -h'

# Nguyenpanda's Directories
alias desk='cd ~/Desktop'
alias docs='cd ~/Documents'
alias dl='cd ~/Downloads'
alias cdds="cd /Users/Shared"

# Tools
alias rm='trash'
alias code='code .'
alias vim='nvim'
alias szsh='source $ZDOTDIR/.zshrc'
alias uzp='update_zsh_plugins'

alias macinfo="system_profiler SPHardwareDataType SPDisplaysDataType SPSoftwareDataType SPStorageDataType"
alias topo='lstopo --whole-io --physical --verbose --output-format'

# python
alias python='python3'
alias pip='pip3'
alias senv='source .venv/bin/activate'
