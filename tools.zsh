# Zoxide (Smart cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

update_zsh_plugins() {
  local zsh_custom="${ZSH_CUSTOM:-${ZSH:-$ZDOTDIR/.oh-my-zsh}/custom}"
  local plugin_dir="$zsh_custom/plugins"
  
  if [[ ! -d "$plugin_dir" ]]; then
    echo "Directory not found: $plugin_dir"
    return 1
  fi

  echo "Checking for updates in $plugin_dir..."
  
  for d in "$plugin_dir"/*(/); do
    if [[ -d "$d/.git" ]]; then
      local name=$(basename "$d")
      echo -n "Updating $name... "

      (
        cd "$d" || exit
        # Capture output to check if anything actually changed
        local output
        output=$(git pull --rebase --autostash 2>&1)
        local status=$?

        if [[ $status -eq 0 ]]; then
          if [[ "$output" == *"Already up to date"* ]]; then
            echo "Already up to date."
          else
            echo "Updated!"
          fi
        else
          echo "FAILED"
          echo "$output" | sed 's/^/  /' # Show error details indented
        fi
      )
    fi
  done
  echo "All plugins processed."
}
