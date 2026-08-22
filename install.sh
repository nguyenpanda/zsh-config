#!/bin/sh
# install.sh — one-command setup for nguyenpanda's zsh configuration.
#
#   curl -fsSL https://raw.githubusercontent.com/nguyenpanda/zsh-config/main/install.sh | sh
#
# or, from a clone:
#
#   sh install.sh
#
# Supported: macOS, Rocky/RHEL 8 & 9, Debian, Ubuntu (x86_64 and aarch64).
#
# Safe to re-run: every step is idempotent, and a second run should report
# everything as already present.
#
# Options (environment variables):
#   ZSH_CONFIG_REPO=<url>        override the source repository
#   ZSH_CONFIG_BRANCH=<branch>   override the branch (default: main)
#   ZSH_CONFIG_NONINTERACTIVE=1  never prompt, never run chsh (used by tests)
#   ZSH_SKIP_TOOLS=1             skip CLI tool installation
#   ZSH_SKIP_PLUGINS=1           skip plugin installation
#   GITHUB_TOKEN=<token>         raise the GitHub API rate limit
#   NO_COLOR=1                   plain output

set -eu

REPO_URL="${ZSH_CONFIG_REPO:-https://github.com/nguyenpanda/zsh-config.git}"
REPO_BRANCH="${ZSH_CONFIG_BRANCH:-main}"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

ZSH_SRC="$XDG_CONFIG_HOME/zsh"
BIN_DIR="$HOME/.local/bin"
SHARE_DIR="$XDG_DATA_HOME"
GH_CACHE_DIR="$XDG_CACHE_HOME/zsh-config/gh"

export ZSH_SRC BIN_DIR SHARE_DIR GH_CACHE_DIR

# Tools installed this run land in ~/.local/bin, which is very likely not on
# PATH yet in this process. Put it there so the tier-0 re-check and the final
# summary see what we just installed.
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) PATH="$BIN_DIR:$PATH"; export PATH ;;
esac

# --------------------------------------------------------------------------
# Obtain the sources.
#
# When piped from curl there is no repo yet, so clone one. When run from a
# clone, use it as-is and never touch the user's working tree.
# --------------------------------------------------------------------------
bootstrap_sources() {
    if [ -f "$ZSH_SRC/manifests/tools.tsv" ] && [ -d "$ZSH_SRC/install" ]; then
        return 0
    fi

    command -v git >/dev/null 2>&1 || {
        printf 'error: git is required to bootstrap. Install git and re-run.\n' >&2
        exit 1
    }

    if [ -d "$ZSH_SRC/.git" ]; then
        printf '==> updating existing checkout at %s\n' "$ZSH_SRC"
        git -C "$ZSH_SRC" fetch --quiet origin "$REPO_BRANCH"
        git -C "$ZSH_SRC" checkout --quiet "$REPO_BRANCH"
        git -C "$ZSH_SRC" merge --quiet --ff-only "origin/$REPO_BRANCH" || true
    elif [ -e "$ZSH_SRC" ]; then
        printf 'error: %s exists but is not a zsh-config checkout.\n' "$ZSH_SRC" >&2
        printf '       Move it aside and re-run.\n' >&2
        exit 1
    else
        printf '==> cloning %s into %s\n' "$REPO_URL" "$ZSH_SRC"
        mkdir -p "$(dirname "$ZSH_SRC")"
        git clone --quiet --branch "$REPO_BRANCH" "$REPO_URL" "$ZSH_SRC"
    fi
}

# When executed from a clone, prefer that clone's scripts over a stale
# $XDG_CONFIG_HOME/zsh. Resolves the directory this script lives in.
script_dir() {
    d=$(dirname -- "$0" 2>/dev/null) || d=.
    (cd -- "$d" 2>/dev/null && pwd) || printf '%s' "$PWD"
}

main() {
    self_dir=$(script_dir)
    if [ -f "$self_dir/manifests/tools.tsv" ] && [ -d "$self_dir/install" ]; then
        ZSH_SRC="$self_dir"
    else
        bootstrap_sources
    fi
    export ZSH_SRC

    # shellcheck source=install/lib.sh
    . "$ZSH_SRC/install/lib.sh"
    # shellcheck source=install/10-packages.sh
    . "$ZSH_SRC/install/10-packages.sh"
    # shellcheck source=install/20-plugins.sh
    . "$ZSH_SRC/install/20-plugins.sh"
    # shellcheck source=install/30-link.sh
    . "$ZSH_SRC/install/30-link.sh"

    detect_platform
    setup_privileges

    head1 "zsh-config installer"
    log "platform : $DISTRO ${DISTRO_VER:-} ($DISTRO_FAMILY / $ARCH)"
    log "source   : $ZSH_SRC"
    log "binaries : $BIN_DIR"

    [ "${ZSH_SKIP_TOOLS:-0}" = 1 ]   || run_packages
    [ "${ZSH_SKIP_PLUGINS:-0}" = 1 ] || run_plugins
    run_link

    head1 "Done"
    if [ "${SHELL:-}" != "$(command -v zsh 2>/dev/null)" ]; then
        log "start using it now with:  exec zsh"
    else
        log "reload with:  exec zsh"
    fi
}

main "$@"
