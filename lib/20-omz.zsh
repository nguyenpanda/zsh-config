# lib/20-omz.zsh — Oh My Zsh configuration and load.
#
# Must run before 30-aliases.zsh: OMZ defines aliases of its own, and ours
# are meant to win.

export ZSH="$ZDOTDIR/.oh-my-zsh"
export ZSH_CUSTOM="$ZDOTDIR/omz-custom"

# Keep the completion dump out of $HOME.
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"

# If OMZ is missing the shell should still be usable — say what to do and
# bail out rather than dying inside oh-my-zsh.sh with a confusing error.
if [[ ! -r "$ZSH/oh-my-zsh.sh" ]]; then
    print -u2 "zsh-config: Oh My Zsh is not installed at $ZSH"
    print -u2 "zsh-config: run  sh \"$ZDOTDIR/install.sh\"  to set it up"
    return 0
fi

# --- Update policy --------------------------------------------------------
# OMZ manages its own updates. install/20-plugins.sh deliberately does not
# pin .oh-my-zsh to a SHA, so these two no longer fight each other the way
# they did when OMZ was a git submodule.
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7

# --- ssh-agent (plugin currently disabled below) --------------------------
zstyle ':omz:plugins:ssh-agent' identities id_ed25519 id_rsa
zstyle ':omz:plugins:ssh-agent' lifetime 8h
# --apple-load-keychain only exists in Apple's ssh-add.
[[ "$ZSH_OS" == macos ]] && \
    zstyle ':omz:plugins:ssh-agent' ssh-add-args --apple-load-keychain

# --- Behaviour ------------------------------------------------------------
CASE_SENSITIVE="true"
ENABLE_CORRECTION="true"
HIST_STAMPS="yyyy:mm:dd"

ZSH_THEME="powerlevel10k/powerlevel10k"

# --- Plugins --------------------------------------------------------------
# zsh-syntax-highlighting must stay last: it wraps widgets defined by
# everything loaded before it.
plugins=(
    git
    extract
)

(( $+commands[docker] )) && plugins+=(docker docker-compose)
[[ "$ZSH_OS" == macos ]] && plugins+=(macos)

plugins+=(
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"
