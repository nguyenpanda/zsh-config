# Zoxide (Smart cd)
eval "$(zoxide init zsh)"

# Zsh Syntax Highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Docker CLI completions
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/nguyenpanda/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
