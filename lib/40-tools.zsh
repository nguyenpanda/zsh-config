# lib/40-tools.zsh — third-party shell integrations.
#
# Every one of these is guarded. An unguarded integration is a startup error
# on any machine that lacks the tool, which is every freshly provisioned
# Linux box.

# --- zoxide (smarter cd) --------------------------------------------------
# --cmd cd makes zoxide define `cd` itself (plus `cdi` for the interactive
# picker). Do NOT go back to `alias cd='z'`: zoxide's z calls cd internally,
# so on any zoxide build that calls plain `cd` rather than `builtin cd` the
# alias points straight back at z and every cd dies with
#     z:1: maximum nested function level reached; increase FUNCNEST?
# Debian 12's zoxide does exactly this. Ubuntu 24.04's does not, which is
# what made the bug look platform-specific.
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh --cmd cd)"
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
