#!/bin/sh
# install/10-packages.sh — install the CLI tools listed in manifests/tools.tsv.
#
# Four tiers per tool, tried in order:
#
#   0  already present and >= min_ver        -> skip
#   1  system package manager (brew/apt/dnf) -> requires root (except brew)
#   2  prebuilt GitHub release binary        -> ~/.local/bin, no root needed
#   3  cargo install                         -> ~/.cargo/bin, last resort
#
# Tier 1 is re-verified against min_ver afterwards: an ancient distro package
# must fall THROUGH to tier 2, not be silently accepted. That single rule is
# what makes Rocky 8 usable — its EPEL fzf is too old for `fzf --zsh`.
#
# A tool that fails every tier is recorded and reported at the end; it never
# aborts the run, because a missing `duf` should not cost you a working shell.

set -u

FAILED=''
INSTALLED=''

install_one() {
    name="$1"; bins="$2"; brew_p="$3"; apt_p="$4"; dnf_p="$5"
    min_ver="$6"; gh_repo="$7"; gh_tag="$8"; layout="$9"; cargo_c="${10}"

    # --- tier 0: already good enough --------------------------------------
    if tool_satisfied "$bins" "$min_ver"; then
        skip "$name ($(resolve_bin "$bins") already present)"
        return 0
    fi

    # --- tier 1: system package manager -----------------------------------
    case "$DISTRO_FAMILY" in
        macos)  sys_pkg="$brew_p" ;;
        debian) sys_pkg="$apt_p" ;;
        rhel)   sys_pkg="$dnf_p" ;;
        *)      sys_pkg='-' ;;
    esac
    # Linuxbrew, when present, is a better source than an old distro package.
    if [ "$DISTRO_FAMILY" != macos ] && have brew && [ "$brew_p" != '-' ]; then
        sys_pkg="$brew_p"
    fi

    if [ "$sys_pkg" != '-' ]; then
        if pkg_install "$sys_pkg"; then
            if tool_satisfied "$bins" "$min_ver"; then
                ok "$name (system package: $sys_pkg)"
                INSTALLED="$INSTALLED $name"
                return 0
            fi
            # Present but too old — keep going.
            warn "$name: $sys_pkg is older than $min_ver, trying a prebuilt binary"
        fi
    fi

    # --- tier 2: prebuilt GitHub release binary ---------------------------
    if [ "$gh_repo" != '-' ]; then
        tag=$(field_for_platform "$gh_tag")
        if install_from_github "$gh_repo" "$tag" "$bins" "$name" "$layout"; then
            if tool_satisfied "$bins" "$min_ver"; then
                ok "$name (prebuilt $gh_repo@$tag -> $BIN_DIR)"
                INSTALLED="$INSTALLED $name"
                return 0
            fi
            warn "$name: prebuilt binary still below $min_ver"
        fi
    fi

    # --- tier 3: build from source ----------------------------------------
    if [ "$cargo_c" != '-' ]; then
        log "$name: falling back to building from source (this can take a while)"
        if install_from_cargo "$cargo_c"; then
            if tool_satisfied "$bins" "$min_ver"; then
                ok "$name (cargo: $cargo_c)"
                INSTALLED="$INSTALLED $name"
                return 0
            fi
        fi
    fi

    err "$name: no install route succeeded"
    FAILED="$FAILED $name"
    return 1
}

run_packages() {
    head1 "Installing CLI tools"

    mkdir -p "$BIN_DIR" "$SHARE_DIR" "$GH_CACHE_DIR"

    # Tabs are the field separator; the manifest is authored with real tabs.
    # The `read` loop runs in this shell (no pipe) so FAILED/INSTALLED persist.
    while IFS="$(printf '\t')" read -r name bins brew_p apt_p dnf_p min_ver gh_repo gh_tag layout cargo_c; do
        case "$name" in
            '' | '#'* | 'name') continue ;;
        esac
        [ -n "${cargo_c:-}" ] || continue          # malformed / short row
        install_one "$name" "$bins" "$brew_p" "$apt_p" "$dnf_p" \
                    "$min_ver" "$gh_repo" "$gh_tag" "$layout" "$cargo_c" || true
    done < "$ZSH_SRC/manifests/tools.tsv"

    if [ -n "$FAILED" ]; then
        warn "could not install:$FAILED"
        warn "the shell will still work; those tools just stay unavailable"
    fi
}
