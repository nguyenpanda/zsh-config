# lib/10-env.zsh — compilation flags and tool-wide environment.

# --- Compilation ----------------------------------------------------------
export ARCHFLAGS="-arch $ZSH_ARCH"

# Homebrew's LLVM and OpenMP are keg-only, so they need explicit flags.
# Resolve the prefix instead of hardcoding /opt/homebrew: Intel Macs use
# /usr/local and Linuxbrew uses /home/linuxbrew/.linuxbrew.
if (( $+commands[brew] )); then
    _brew_prefix="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
    for _keg in llvm libomp; do
        if [[ -d "$_brew_prefix/opt/$_keg" ]]; then
            export LDFLAGS="-L$_brew_prefix/opt/$_keg/lib $LDFLAGS"
            export CPPFLAGS="-I$_brew_prefix/opt/$_keg/include $CPPFLAGS"
        fi
    done
    unset _brew_prefix _keg
fi

# --- fd / fzf ignore list -------------------------------------------------
# See fd-ignore for why this is a file rather than a variable.
export FD_IGNORE_FILE="$ZDOTDIR/fd-ignore"

# Assembled as an array so it can be passed as real arguments. Any code that
# needs it as a single command string can use "${FD_OPTS[*]}".
typeset -ga FD_OPTS
FD_OPTS=()
[[ -r "$FD_IGNORE_FILE" ]] && FD_OPTS=(--ignore-file "$FD_IGNORE_FILE")
