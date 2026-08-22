# lib/40-tools.zsh — third-party shell integrations.
#
# Every one of these is guarded. An unguarded integration is a startup error
# on any machine that lacks the tool, which is every freshly provisioned
# Linux box.

# --- zoxide (smarter cd) --------------------------------------------------
# Letting zoxide own `cd` is only safe on versions whose generated code uses
# `builtin cd`. Older ones emit a plain `cd "$@"`, which under --cmd cd (or
# the old `alias cd='z'`) calls straight back into itself, and every cd dies:
#     z:1: maximum nested function level reached; increase FUNCNEST?
#
# Debian 12 ships zoxide 0.4.3, which does exactly this. Ubuntu 24.04 ships
# 0.9.3, which is fine — that difference is what made the bug look
# platform-specific rather than version-specific.
#
# manifests/tools.tsv sets min_ver 0.9 so the installer replaces an old
# zoxide, but guard here too: a working `cd` must not depend on the installer
# having run.
if (( $+commands[zoxide] )); then
    autoload -Uz is-at-least
    _zoxide_ver="${$(zoxide --version 2>/dev/null)##* }"
    if [[ -n "$_zoxide_ver" ]] && is-at-least 0.9 "$_zoxide_ver"; then
        eval "$(zoxide init zsh --cmd cd)"
    else
        # Too old to own cd safely: provide `z` only and leave cd alone.
        eval "$(zoxide init zsh)"
    fi
    unset _zoxide_ver
fi

# --- Python argcomplete ---------------------------------------------------
# Previously unguarded, so every shell on a machine without `tmpl` opened
# with a "command not found" error.
if (( $+commands[register-python-argcomplete] )) && (( $+commands[tmpl] )); then
    eval "$(register-python-argcomplete tmpl)"
fi

# --- delta as git's pager -------------------------------------------------
if (( $+commands[delta] )); then
    export GIT_PAGER='delta'
fi

# --- uv (Python package manager) ------------------------------------------
if (( $+commands[uv] )); then
    eval "$(uv generate-shell-completion zsh 2>/dev/null)" 2>/dev/null
fi
