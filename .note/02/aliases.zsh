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

# eza
alias ls='eza --icons --git'
alias ll='eza -lh --icons --git'
alias la='eza -A --icons --git'
alias lla='eza -lAh --icons --git'
alias lt='eza --tree --level=2 --icons'
alias tree='eza --tree --icons'
compdef eza=ls

# zoxide
alias cd='z'

# ripgrep
alias grep='rg --color=auto'

# diff
alias diff='diff --color=auto'

# Disk
alias df='df -h'
alias du='du -h'

# Nguyenpanda's Directories
alias -- -='cd -'
alias docs='cd ~/Documents'
alias dl='cd ~/Downloads'
alias cdds="cd /Users/Shared"

# Tools
alias code='code .'
alias vim='nvim'
alias szsh='source $ZDOTDIR/.zshrc'

# python
alias python='python3'
alias pip='pip3'
alias senv='source .venv/bin/activate'
