autoload -U add-zsh-hook

_auto_venv() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_parent=$(dirname "$VIRTUAL_ENV")
    
    if [[ "$PWD" != "$venv_parent" && "$PWD" != "$venv_parent"/* ]]; then
      echo "🐍 Leaving Python virtual environment."
      deactivate
    fi
  fi

  if [[ -z "$VIRTUAL_ENV" && -f ".venv/bin/activate" ]]; then
    echo "🐍 Activating Python virtual environment ($PWD/.venv)."
    source ".venv/bin/activate"
  fi
}

add-zsh-hook chpwd _auto_venv

