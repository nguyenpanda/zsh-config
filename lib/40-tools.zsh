# lib/40-tools.zsh — third-party shell integrations.
#
# Every one of these is guarded. An unguarded integration is a startup error
# on any machine that lacks the tool, which is every freshly provisioned
# Linux box.

# --- zoxide (smarter cd) --------------------------------------------------
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
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
