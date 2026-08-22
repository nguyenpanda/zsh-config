# ~/.config/zsh/.zshenv — runs for every zsh, interactive or not.
#
# Reached either via the ~/.zshenv stub written by install/30-link.sh, or via
# a legacy /etc/zshenv that sets ZDOTDIR. Keep this file cheap and free of
# output: it runs for every `zsh -c` and every scp/rsync session.

# ========== XDG base directories ==========================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"

[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"

# ========== PATH ==========================================================
# Must come before anything that probes $commands: tools installed by
# install/10-packages.sh live in ~/.local/bin, and the lookups below would
# miss them if PATH were still the system default.
typeset -U path
path=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "/usr/local/bin"
    "/usr/local/sbin"
    $path
)

# Homebrew: /opt/homebrew on Apple Silicon, /usr/local on Intel,
# /home/linuxbrew on Linux. Probe rather than hardcode.
for _brew_root in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [[ -x "$_brew_root/bin/brew" ]]; then
        path=("$_brew_root/bin" "$_brew_root/sbin" $path)
        [[ -d "$_brew_root/opt/llvm/bin" ]] && path=("$_brew_root/opt/llvm/bin" $path)
        break
    fi
done
unset _brew_root

typeset -U fpath
fpath=(
    "$HOME/.docker/completions"
    $fpath
)

# Machine-specific PATH entries belong in local.zsh (gitignored), not here.

# ========== Editor & pager ================================================
if (( $+commands[nvim] )); then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif (( $+commands[vim] )); then
    export EDITOR="vim"
    export VISUAL="vim"
else
    export EDITOR="vi"
    export VISUAL="vi"
fi

# Debian and Ubuntu ship bat as `batcat`.
if (( $+commands[bat] )); then
    export MANPAGER="bat -l man -p"
elif (( $+commands[batcat] )); then
    export MANPAGER="batcat -l man -p"
fi

# ========== GPG ===========================================================
# Only meaningful with a terminal attached, and the old `$(tty)` cost a fork
# in every non-interactive shell. $TTY is set by zsh itself, for free.
if [[ -o interactive ]]; then
    export GPG_TTY="$TTY"
fi
