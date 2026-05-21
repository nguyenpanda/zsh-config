# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ========== Oh My Zsh Configuration ==========
export ZSH="$ZDOTDIR/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Move .zcompdump to cache directory
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"

# OMZ Settings
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7
zstyle ':omz:plugins:ssh-agent' identities id_ed25519 id_rsa
zstyle ':omz:plugins:ssh-agent' ssh-add-args --apple-load-keychain
zstyle ':omz:plugins:ssh-agent' lifetime 8h

# Case-sensitive completion
CASE_SENSITIVE="true"
ENABLE_CORRECTION="true"
HIST_STAMPS="yyyy:mm:dd"

# Plugins
plugins=(
  git
  docker
  docker-compose
  ssh-agent
  macos
  extract

  # Custom
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# ========== Nguyenpanda Customizations ==========

### History
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

### Shell behaviour
setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT

### Completion Styles (Applied after OMZ compinit)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

### Load Custom Files
source "$ZDOTDIR/env.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/tools.zsh"
source "$ZDOTDIR/fzf.zsh"

# Syntax Highlighting (Must be last)
# if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
#   source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# fi

# Powerlevel10k Theme (Must be after syntax highlighting or at least at the end)
[[ ! -f "$ZDOTDIR/.p10k.zsh" ]] || source "$ZDOTDIR/.p10k.zsh"
