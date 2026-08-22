#!/bin/sh
# install/20-plugins.sh — sync the plugin checkouts named in
# manifests/plugins.tsv. Idempotent: safe to re-run any number of times.
#
# These directories are gitignored by the parent repo. They used to be git
# submodules, which broke the one-command promise (a clone without
# --recurse-submodules produced empty directories) and fought Oh My Zsh's
# own auto-updater. A manifest plus plain clones fixes both.

set -u

clone_repo() { # clone_repo URL TARGET
    # A partial clone keeps this fast; older gits reject --filter, so retry
    # without it rather than failing the install.
    git clone --quiet --filter=blob:none "$1" "$2" 2>/dev/null \
        || git clone --quiet "$1" "$2"
}

run_plugins() {
    head1 "Installing zsh plugins and theme"

    have git || die "git is required to install plugins"

    while IFS="$(printf '\t')" read -r url dest ref; do
        case "$url" in
            '' | '#'* | 'url') continue ;;
        esac
        [ -n "${ref:-}" ] || continue

        target="$ZSH_SRC/$dest"

        if [ ! -d "$target/.git" ]; then
            [ -d "$target" ] && rm -rf "$target"
            mkdir -p "$(dirname "$target")"
            if clone_repo "$url" "$target"; then
                ok "cloned $dest"
            else
                err "failed to clone $dest from $url"
                continue
            fi
        fi

        # Oh My Zsh updates itself (zstyle ':omz:update' mode auto in
        # lib/20-omz.zsh). Pinning it here would mean the installer and OMZ
        # tug the checkout back and forth on every run, so leave it alone
        # once it exists.
        if [ "$dest" = '.oh-my-zsh' ]; then
            skip "$dest (self-updating, left at $(git -C "$target" rev-parse --short HEAD))"
            continue
        fi

        current=$(git -C "$target" rev-parse HEAD 2>/dev/null || echo none)
        if [ "$current" = "$ref" ]; then
            skip "$dest (already at pinned $(printf '%.7s' "$ref"))"
            continue
        fi

        git -C "$target" fetch --quiet --tags origin 2>/dev/null || true
        if git -C "$target" checkout --quiet --force "$ref" 2>/dev/null; then
            ok "$dest -> $(git -C "$target" rev-parse --short HEAD)"
        else
            err "$dest: could not check out ref '$ref'"
        fi
    done < "$ZSH_SRC/manifests/plugins.tsv"
}
