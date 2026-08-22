#!/bin/sh
# install/lib.sh — shared helpers for the installer.
#
# POSIX sh on purpose: a minimal Rocky 8 image has no zsh and no bash-isms
# worth relying on. `local` is used despite not being in POSIX because every
# real /bin/sh (dash, busybox ash, bash, Rocky's bash) supports it; shellcheck
# is told to allow it via SC3043 in .shellcheckrc.

# --------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET=$(printf '\033[0m')
    C_DIM=$(printf '\033[2m')
    C_RED=$(printf '\033[31m')
    C_GREEN=$(printf '\033[32m')
    C_YELLOW=$(printf '\033[33m')
    C_BLUE=$(printf '\033[34m')
    C_BOLD=$(printf '\033[1m')
else
    C_RESET='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_BOLD=''
fi

log()   { printf '%s==>%s %s\n' "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf '%s  ok%s %s\n' "$C_GREEN"  "$C_RESET" "$*"; }
skip()  { printf '%s    -%s %s\n' "$C_DIM"   "$C_RESET" "$*"; }
warn()  { printf '%s warn%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()   { printf '%s fail%s %s\n' "$C_RED"    "$C_RESET" "$*" >&2; }
die()   { err "$*"; exit 1; }
head1() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; }

have() { command -v "$1" >/dev/null 2>&1; }

# --------------------------------------------------------------------------
# Platform detection
#
# Exports: OS, DISTRO, DISTRO_FAMILY, DISTRO_VER, ARCH, PLATFORM_KEYS
# PLATFORM_KEYS is the match list used by per-platform manifest overrides,
# most specific first, e.g. "rocky8 rhel8 rhel linux".
# --------------------------------------------------------------------------
os_release_get() {
    [ -r /etc/os-release ] || return 1
    sed -n "s/^$1=//p" /etc/os-release | tr -d '"' | head -1
}

detect_platform() {
    case "$(uname -s)" in
        Darwin) OS=macos ;;
        Linux)  OS=linux ;;
        *)      die "unsupported operating system: $(uname -s)" ;;
    esac

    case "$(uname -m)" in
        arm64 | aarch64) ARCH=aarch64 ;;
        x86_64 | amd64)  ARCH=x86_64 ;;
        *)               ARCH=$(uname -m) ;;
    esac

    if [ "$OS" = macos ]; then
        DISTRO=macos
        DISTRO_FAMILY=macos
        DISTRO_VER=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)
        PLATFORM_KEYS="macos$DISTRO_VER macos darwin"
        return 0
    fi

    DISTRO=$(os_release_get ID || echo unknown)
    DISTRO_VER=$(os_release_get VERSION_ID | cut -d. -f1)
    : "${DISTRO_VER:=0}"

    case "$DISTRO" in
        rocky | rhel | centos | almalinux | fedora | ol)
            DISTRO_FAMILY=rhel ;;
        debian | ubuntu | linuxmint | pop | raspbian)
            DISTRO_FAMILY=debian ;;
        *)
            case " $(os_release_get ID_LIKE) " in
                *rhel* | *fedora* | *centos*) DISTRO_FAMILY=rhel ;;
                *debian* | *ubuntu*)          DISTRO_FAMILY=debian ;;
                *)                            DISTRO_FAMILY=unknown ;;
            esac ;;
    esac

    PLATFORM_KEYS="$DISTRO$DISTRO_VER $DISTRO $DISTRO_FAMILY$DISTRO_VER $DISTRO_FAMILY linux"
}

# --------------------------------------------------------------------------
# Privilege handling
#
# The installer must work unprivileged: these configs get deployed onto
# shared Rocky boxes where sudo is not on offer. Without root we simply skip
# tier 1 (system packages) and let tier 2 drop binaries into ~/.local/bin.
# --------------------------------------------------------------------------
setup_privileges() {
    SUDO=''
    CAN_ROOT=0
    if [ "$(id -u)" -eq 0 ]; then
        CAN_ROOT=1
    elif have sudo; then
        SUDO='sudo'
        CAN_ROOT=1
    fi
    [ "$CAN_ROOT" -eq 1 ] || warn "no root available — using user-local installs only (~/.local/bin)"
}

# --------------------------------------------------------------------------
# System package manager
# --------------------------------------------------------------------------
PKG_REFRESHED=0

pkg_refresh() {
    [ "$PKG_REFRESHED" -eq 1 ] && return 0
    PKG_REFRESHED=1
    case "$DISTRO_FAMILY" in
        debian)
            $SUDO apt-get update -qq >/dev/null 2>&1 || warn "apt-get update failed; continuing"
            ;;
        rhel)
            # EPEL carries most of the modern CLI tools on RHEL-likes.
            $SUDO dnf install -y -q epel-release >/dev/null 2>&1 || true
            # Several EPEL packages need the CRB/PowerTools repo for their deps.
            $SUDO dnf install -y -q dnf-plugins-core >/dev/null 2>&1 || true
            if [ "$DISTRO_VER" -ge 9 ] 2>/dev/null; then
                $SUDO dnf config-manager --set-enabled crb >/dev/null 2>&1 || true
            else
                $SUDO dnf config-manager --set-enabled powertools >/dev/null 2>&1 || true
            fi
            ;;
    esac
}

pkg_install() {
    [ "$CAN_ROOT" -eq 1 ] || [ "$DISTRO_FAMILY" = macos ] || return 1
    pkg_refresh
    case "$DISTRO_FAMILY" in
        macos)  have brew || return 1
                brew install "$1" >/dev/null 2>&1 ;;
        debian) DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq "$1" >/dev/null 2>&1 ;;
        rhel)   $SUDO dnf install -y -q "$1" >/dev/null 2>&1 ;;
        *)      return 1 ;;
    esac
}

# --------------------------------------------------------------------------
# Version helpers
# --------------------------------------------------------------------------

# ver_ge A B  ->  true when A >= B  (semver-ish, via sort -V)
ver_ge() {
    [ -n "$1" ] || return 1
    [ "$1" = "$2" ] && return 0
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

# First dotted-numeric token from `<bin> --version`.
bin_version() {
    "$1" --version 2>/dev/null | head -1 \
        | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
}

# resolve_bin BINS  -> echo the first name in the comma list that is on PATH
resolve_bin() {
    local b
    for b in $(printf '%s' "$1" | tr ',' ' '); do
        if have "$b"; then printf '%s' "$b"; return 0; fi
    done
    return 1
}

# tool_satisfied BINS MIN_VER -> true if installed and new enough
tool_satisfied() {
    local bin ver
    bin=$(resolve_bin "$1") || return 1
    [ "$2" = '-' ] && return 0
    ver=$(bin_version "$bin")
    # A binary that refuses to report a version still counts as present.
    [ -n "$ver" ] || return 0
    ver_ge "$ver" "$2"
}

# --------------------------------------------------------------------------
# Manifest field helpers
# --------------------------------------------------------------------------

# Per-platform override syntax:  DEFAULT|key=VALUE|key2=VALUE2
# Keys are matched against PLATFORM_KEYS, most specific first.
# e.g. "v0.12.4|rhel8=v0.9.5" yields v0.9.5 on Rocky 8, v0.12.4 elsewhere.
field_for_platform() {
    local spec part key val k
    spec="$1"
    for k in $PLATFORM_KEYS; do
        # shellcheck disable=SC2086
        for part in $(printf '%s' "$spec" | tr '|' ' '); do
            case "$part" in
                *=*)
                    key=${part%%=*}
                    val=${part#*=}
                    [ "$key" = "$k" ] && { printf '%s' "$val"; return 0; }
                    ;;
            esac
        done
    done
    printf '%s' "${spec%%|*}"
}

# --------------------------------------------------------------------------
# Download helpers
# --------------------------------------------------------------------------
fetch() { # fetch URL OUTFILE
    if have curl; then
        curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 20 -o "$2" "$1"
    elif have wget; then
        wget -qO "$2" "$1"
    else
        return 1
    fi
}

gh_api_fetch() { # gh_api_fetch URL OUTFILE
    if have curl; then
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            curl -fsSL --retry 2 --connect-timeout 20 \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $GITHUB_TOKEN" -o "$2" "$1"
        else
            curl -fsSL --retry 2 --connect-timeout 20 \
                -H "Accept: application/vnd.github+json" -o "$2" "$1"
        fi
    elif have wget; then
        wget -qO "$2" --header="Accept: application/vnd.github+json" "$1"
    else
        return 1
    fi
}

# List a release's asset download URLs, cached on disk.
#
# The cache is what keeps the Docker matrix under GitHub's 60 req/hr
# unauthenticated limit: four distros x ~16 tools would blow straight
# through it otherwise. Set GITHUB_TOKEN to raise the limit to 5000/hr.
gh_release_urls() {
    local repo tag cache url
    repo="$1"; tag="$2"
    cache="$GH_CACHE_DIR/$(printf '%s@%s' "$repo" "$tag" | tr '/@.' '___').json"

    if [ ! -s "$cache" ]; then
        if [ "$tag" = latest ]; then
            url="https://api.github.com/repos/$repo/releases/latest"
        else
            url="https://api.github.com/repos/$repo/releases/tags/$tag"
        fi
        gh_api_fetch "$url" "$cache" || { rm -f "$cache"; return 1; }
    fi

    grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$cache" \
        | sed 's/.*"\(https[^"]*\)"$/\1/'
}

# Choose the best asset URL for this platform from a list on stdin.
pick_asset() {
    local arch_re os_re urls
    case "$ARCH" in
        x86_64)  arch_re='x86[_-]?64|amd64|x64' ;;
        aarch64) arch_re='aarch64|arm64' ;;
        *)       arch_re="$ARCH" ;;
    esac
    case "$OS" in
        linux) os_re='linux|unknown-linux' ;;
        macos) os_re='darwin|apple|macos|osx' ;;
    esac

    urls=$(grep -Ei "($arch_re)" \
        | grep -Ei "($os_re)" \
        | grep -Eiv '\.(sha256|sha256sum|sha512|asc|sig|pem|txt|deb|rpm|msi|exe|apk|pkg|dmg)$' \
        | grep -Eiv 'sha256sum|checksum|sources?\.tar')

    [ -n "$urls" ] || return 1

    # NOTE: `... | head -1` exits 0 even on empty input, so each candidate
    # must be captured and tested rather than chained with &&.
    local pick

    # Preference order, most wanted first:
    #   1. musl + .tar.gz  — statically linked (Rocky 8 has glibc 2.28, and
    #      many -gnu assets need something newer) and needs only gzip, which
    #      even a minimal image has. .tar.xz/.tbz would need extra tools.
    #   2. musl, any container
    #   3. .tar.gz
    #   4. whatever is left
    pick=$(printf '%s\n' "$urls" | grep -i musl | grep -Ei '\.(tar\.gz|tgz)$' | head -1)
    [ -n "$pick" ] && { printf '%s\n' "$pick"; return 0; }

    pick=$(printf '%s\n' "$urls" | grep -i musl | head -1)
    [ -n "$pick" ] && { printf '%s\n' "$pick"; return 0; }

    pick=$(printf '%s\n' "$urls" | grep -Ei '\.(tar\.gz|tgz)$' | head -1)
    [ -n "$pick" ] && { printf '%s\n' "$pick"; return 0; }

    printf '%s\n' "$urls" | head -1
}

extract_archive() { # extract_archive FILE DESTDIR
    case "$1" in
        *.tar.gz | *.tgz)   tar -xzf "$1" -C "$2" ;;
        *.tar.xz | *.txz)   tar -xJf "$1" -C "$2" ;;
        *.tar.bz2 | *.tbz | *.tbz2) tar -xjf "$1" -C "$2" ;;
        *.zip)              have unzip || return 1; unzip -qo "$1" -d "$2" ;;
        *.gz)               gunzip -c "$1" > "$2/$(basename "$1" .gz)" ;;
        *)                  cp "$1" "$2/" ;;   # bare binary asset
    esac
}

# --------------------------------------------------------------------------
# Tier 2 — prebuilt binary from a GitHub release
# --------------------------------------------------------------------------
# install_from_github REPO TAG BINS NAME LAYOUT
#
# LAYOUT is 'binary' (default) or 'tree'. A few tools are not a single
# relocatable file: neovim needs its runtime/ directory and btop needs its
# themes, so for those the whole extracted tree is kept under
# ~/.local/share/<name> and the binary is symlinked into ~/.local/bin.
install_from_github() {
    local repo tag bins name layout url tmp archive found b top dest rc
    repo="$1"; tag="$2"; bins="$3"; name="$4"; layout="${5:-binary}"
    [ "$repo" = '-' ] && return 1

    url=$(gh_release_urls "$repo" "$tag" | pick_asset) || return 1
    [ -n "$url" ] || return 1

    tmp=$(mktemp -d) || return 1
    archive="$tmp/$(basename "$url")"
    fetch "$url" "$archive"             || { rm -rf "$tmp"; return 1; }
    mkdir -p "$tmp/x"
    extract_archive "$archive" "$tmp/x" || { rm -rf "$tmp"; return 1; }

    mkdir -p "$BIN_DIR"
    rc=1

    if [ "$layout" = tree ]; then
        top=$(find "$tmp/x" -mindepth 1 -maxdepth 1 -type d | head -1)
        [ -n "$top" ] || top="$tmp/x"
        dest="$SHARE_DIR/$name"
        rm -rf "$dest"
        mkdir -p "$dest"
        cp -R "$top"/. "$dest"/ || { rm -rf "$tmp"; return 1; }
        for b in $(printf '%s' "$bins" | tr ',' ' '); do
            found=$(find "$dest" -type f -name "$b" 2>/dev/null | head -1)
            if [ -n "$found" ]; then
                chmod 0755 "$found"
                ln -sf "$found" "$BIN_DIR/$b"
                rc=0
                break
            fi
        done
        rm -rf "$tmp"
        return "$rc"
    fi

    for b in $(printf '%s' "$bins" | tr ',' ' '); do
        found=$(find "$tmp/x" -type f -name "$b" 2>/dev/null | head -1)
        if [ -z "$found" ]; then
            # Assets like jq's are a single renamed binary (jq-linux-amd64).
            if [ "$(find "$tmp/x" -type f | wc -l)" -eq 1 ]; then
                found=$(find "$tmp/x" -type f | head -1)
            fi
        fi
        if [ -n "$found" ]; then
            install -m 0755 "$found" "$BIN_DIR/$b" 2>/dev/null \
                || { cp "$found" "$BIN_DIR/$b" && chmod 0755 "$BIN_DIR/$b"; }
            rc=0
            break
        fi
    done

    rm -rf "$tmp"
    return "$rc"
}

# --------------------------------------------------------------------------
# Tier 3 — build from source with cargo
# --------------------------------------------------------------------------
ensure_cargo() {
    have cargo && return 0
    [ -x "$HOME/.cargo/bin/cargo" ] && { PATH="$HOME/.cargo/bin:$PATH"; return 0; }
    log "bootstrapping Rust toolchain (needed to build a tool from source)"
    have curl || return 1
    curl -fsSL --proto '=https' --tlsv1.2 https://sh.rustup.rs \
        | sh -s -- -y --no-modify-path --profile minimal >/dev/null 2>&1 || return 1
    PATH="$HOME/.cargo/bin:$PATH"
    have cargo
}

install_from_cargo() { # install_from_cargo CRATE
    [ "$1" = '-' ] && return 1
    ensure_cargo || return 1
    cargo install --locked --quiet "$1" >/dev/null 2>&1
}
