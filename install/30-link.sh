#!/bin/sh
# install/30-link.sh — wire zsh up to this config and make it the login shell.
#
# The only file we place outside the repo is ~/.zshenv, a three-line stub that
# points ZDOTDIR here. Everything else lives in $ZDOTDIR.
#
# This deliberately replaces the previous mechanism, a hand-written
# /etc/zshenv: that needed sudo, was not in the repo, and was undocumented, so
# a new machine could never be set up without tribal knowledge.
#
# Note on ordering: zsh reads /etc/zshenv, then $ZDOTDIR/.zshenv (ZDOTDIR
# defaulting to $HOME). Because our stub sets ZDOTDIR *itself*, zsh will not
# go back and re-read a .zshenv from the new location — so the stub sources it
# explicitly. An existing /etc/zshenv that sets the same ZDOTDIR is harmless
# and is left alone.

set -u

# Single-quoted on purpose: the stub must be written out with $ZDOTDIR and
# $HOME unexpanded, so it resolves at shell-startup time on any machine.
# shellcheck disable=SC2016
ZSHENV_STUB='# Managed by zsh-config (install/30-link.sh). Edit $ZDOTDIR/.zshenv instead.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[ -f "$ZDOTDIR/.zshenv" ] && . "$ZDOTDIR/.zshenv"
'

link_zshenv() {
    stub="$HOME/.zshenv"

    if [ -e "$stub" ] || [ -L "$stub" ]; then
        if [ -f "$stub" ] && grep -q 'Managed by zsh-config' "$stub" 2>/dev/null; then
            skip "$HOME/.zshenv already managed"
            printf '%s' "$ZSHENV_STUB" > "$stub"
            return 0
        fi
        backup="$stub.bak.$(date +%Y%m%d-%H%M%S)"
        mv "$stub" "$backup"
        warn "existing ~/.zshenv moved to $backup"
    fi

    printf '%s' "$ZSHENV_STUB" > "$stub"
    ok "wrote ~/.zshenv -> ZDOTDIR=$ZSH_SRC"
}

# Older installs of this config set ZDOTDIR from /etc/zshenv. That still works
# and takes effect before ~/.zshenv, so it is left in place — but say so, or
# it becomes a mystery the next time something looks wrong.
note_etc_zshenv() {
    if [ -f /etc/zshenv ] && grep -q 'ZDOTDIR' /etc/zshenv 2>/dev/null; then
        skip "/etc/zshenv also sets ZDOTDIR (legacy, harmless — remove it if you like)"
    fi
}

set_login_shell() {
    zsh_path=$(command -v zsh 2>/dev/null) || {
        warn "zsh is not installed; skipping login-shell change"
        return 0
    }

    case "${SHELL:-}" in
        */zsh) skip "login shell is already zsh"; return 0 ;;
    esac

    # chsh refuses shells that are not listed in /etc/shells.
    if [ -r /etc/shells ] && ! grep -qx "$zsh_path" /etc/shells; then
        if [ "$CAN_ROOT" -eq 1 ]; then
            printf '%s\n' "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null 2>&1 || true
        fi
    fi

    if [ "${ZSH_CONFIG_NONINTERACTIVE:-0}" = 1 ]; then
        skip "non-interactive run; not changing the login shell"
        return 0
    fi

    if chsh -s "$zsh_path" >/dev/null 2>&1; then
        ok "login shell set to $zsh_path"
    else
        warn "could not change the login shell automatically. Run:"
        warn "    chsh -s $zsh_path"
    fi
}

install_git_hooks() {
    have git || return 0
    [ -d "$ZSH_SRC/.git" ] || return 0

    # Report only a real change, so a second run is visibly a no-op.
    if [ "$(git -C "$ZSH_SRC" config --get core.hooksPath 2>/dev/null)" = .githooks ]; then
        skip "pre-commit secret guard already enabled"
        return 0
    fi

    git -C "$ZSH_SRC" config core.hooksPath .githooks
    ok "enabled the pre-commit secret guard (.githooks)"
}

seed_local_files() {
    # local.zsh is where machine-specific paths and secrets go. Both are
    # gitignored and sourced last by .zshrc.
    if [ ! -f "$ZSH_SRC/local.zsh" ]; then
        cat > "$ZSH_SRC/local.zsh" <<'EOF'
# local.zsh — machine-specific settings. Gitignored; sourced last by .zshrc.
#
# Put anything here that should NOT be shared across machines: host-specific
# PATH entries, work proxies, per-box tool locations.
#
# Example:
#   path=("$HOME/.lmstudio/bin" $path)

EOF
        ok "created local.zsh (machine-specific settings)"
    else
        skip "local.zsh already exists"
    fi

    if [ ! -f "$ZSH_SRC/secrets.zsh" ]; then
        cat > "$ZSH_SRC/secrets.zsh" <<'EOF'
# secrets.zsh — API keys and tokens. Gitignored; sourced last by .zshrc.
#
# Never commit this file. The pre-commit hook in .githooks will refuse
# obvious key patterns, but the real protection is that it is gitignored.
#
# Example:
#   export OPENAI_API_KEY="..."

EOF
        chmod 600 "$ZSH_SRC/secrets.zsh"
        ok "created secrets.zsh (mode 600)"
    else
        skip "secrets.zsh already exists"
    fi
}

run_link() {
    head1 "Wiring up the shell"
    link_zshenv
    note_etc_zshenv
    seed_local_files
    install_git_hooks
    set_login_shell
}
