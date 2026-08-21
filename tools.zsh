# Zoxide (Smart cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# tmpl
eval "$(register-python-argcomplete tmpl)"

# Update Zsh Plugins (via Git Submodules)
update_zsh_plugins() {
  echo "🔄 Updating all Zsh plugins and themes via Git Submodules..."
  (
    cd "$ZDOTDIR" || return 1
    git submodule update --remote --merge
  )
  echo "✅ All plugins updated successfully."
}
