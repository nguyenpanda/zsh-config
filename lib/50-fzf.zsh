# lib/50-fzf.zsh — fuzzy finder integration.

(( $+commands[fzf] )) || return 0

# --- Key bindings & completion --------------------------------------------
# `fzf --zsh` only exists from fzf 0.48. Rocky 8's EPEL fzf is older, so this
# used to abort the file (and take the widgets below with it). The installer
# enforces >= 0.48 via manifests/tools.tsv, but a system fzf can still be
# older than that, so fall back to the distro-packaged shell snippets.
if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
else
    for _d in /usr/share/fzf/shell /usr/share/doc/fzf/examples \
              /usr/share/fzf "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell"; do
        [[ -r "$_d/key-bindings.zsh" ]] && source "$_d/key-bindings.zsh"
        [[ -r "$_d/completion.zsh"   ]] && source "$_d/completion.zsh"
    done
    unset _d
fi

# --- Search backend -------------------------------------------------------
# FZF_*_COMMAND values are command strings re-parsed by a shell, so the
# ignore-file arguments are joined here rather than passed as an array.
if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --strip-cwd-prefix ${FD_OPTS[*]}"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d --hidden --strip-cwd-prefix ${FD_OPTS[*]}"
elif (( $+commands[fdfind] )); then
    export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --strip-cwd-prefix ${FD_OPTS[*]}"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fdfind --type d --hidden --strip-cwd-prefix ${FD_OPTS[*]}"
fi

# --- Appearance -----------------------------------------------------------
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer=" "
  --marker=" "
  --color="header:italic"
  --preview-window=right:65%:wrap:border-left
'

# --- Preview --------------------------------------------------------------
# Debian and Ubuntu ship bat as `batcat` (the name `bat` belongs to another
# package there).
if (( $+commands[bat] )); then
    export _FZF_PREVIEW_CMD='bat --color=always --style=numbers,changes --line-range=:500 {}'
elif (( $+commands[batcat] )); then
    export _FZF_PREVIEW_CMD='batcat --color=always --style=numbers,changes --line-range=:500 {}'
else
    export _FZF_PREVIEW_CMD='cat {}'
fi

export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# --- Custom widget: Ctrl+F, files excluding hidden ------------------------
_fzf_file_no_hidden() {
    local finder result
    if (( $+commands[fd] )); then
        finder=fd
    elif (( $+commands[fdfind] )); then
        finder=fdfind
    fi

    if [[ -n "$finder" ]]; then
        result=$("$finder" --type f --strip-cwd-prefix "${FD_OPTS[@]}" \
            | fzf --preview "$_FZF_PREVIEW_CMD")
    else
        result=$(find . -maxdepth 4 -type f | fzf --preview "$_FZF_PREVIEW_CMD")
    fi

    if [[ -n "$result" ]]; then
        LBUFFER+="${(q)result} "
    fi
    zle reset-prompt
}

zle -N _fzf_file_no_hidden
bindkey '^f' _fzf_file_no_hidden

# --- macOS Option-key patches ---------------------------------------------
# Terminal.app and friends send these characters for Option+C/T/F rather than
# a meta prefix, so bind them directly. Meaningless on Linux.
if [[ "$ZSH_OS" == macos ]]; then
    typeset -A _mac_fzf_map=(
        'ç' fzf-cd-widget        # Option+C
        '†' fzf-file-widget      # Option+T
        'ƒ' _fzf_file_no_hidden  # Option+F
    )
    for _key _widget in ${(kv)_mac_fzf_map}; do
        # Only bind widgets that actually got defined above.
        (( $+widgets[$_widget] )) && bindkey "$_key" "$_widget"
    done
    unset _mac_fzf_map _key _widget
fi
