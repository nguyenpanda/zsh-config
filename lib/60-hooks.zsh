# lib/60-hooks.zsh — directory-change hooks.

autoload -U add-zsh-hook

# Activate a project's .venv on entry, deactivate it on leaving.
_auto_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_parent="${VIRTUAL_ENV:h}"

        if [[ "$PWD" != "$venv_parent" && "$PWD" != "$venv_parent"/* ]]; then
            print "🐍 Leaving Python virtual environment."
            if (( $+functions[deactivate] )); then
                deactivate
            else
                unset VIRTUAL_ENV
            fi
        fi
    fi

    if [[ -z "$VIRTUAL_ENV" && -f ".venv/bin/activate" ]]; then
        print "🐍 Activating Python virtual environment ($PWD/.venv)."
        source ".venv/bin/activate"
    fi
}

add-zsh-hook chpwd _auto_venv

# Also run once at startup: opening a new terminal that is already inside a
# project should activate its venv, not wait for the first `cd`.
_auto_venv
