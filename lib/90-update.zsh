# lib/90-update.zsh — keeping the config current.
#
#   zsh-update              config repo + plugins
#   zsh-update --plugins    plugins only
#   zsh-update --tools      CLI tools only
#   zsh-update --all        everything, including tools
#
# A throttled background check runs at most once every $ZSH_UPDATE_DAYS days.
# It never blocks the prompt and never touches the network on a normal shell
# start. Set ZSH_AUTO_UPDATE=0 to disable it entirely (the Docker test matrix
# and air-gapped machines rely on this).

: "${ZSH_AUTO_UPDATE:=1}"
: "${ZSH_UPDATE_DAYS:=7}"

_zsh_update_stamp="$XDG_STATE_HOME/zsh/last-update"
_zsh_update_log="$XDG_STATE_HOME/zsh/update.log"

# Pull the config repo itself. Refuses on a dirty tree: this repo is edited
# in place, so an update must never clobber work in progress.
_zsh_update_repo() {
    [[ -d "$ZDOTDIR/.git" ]] || { print "    not a git checkout, skipping"; return 0 }

    if [[ -n "$(git -C "$ZDOTDIR" status --porcelain 2>/dev/null)" ]]; then
        print -u2 "    skipped: $ZDOTDIR has uncommitted changes"
        return 1
    fi

    if git -C "$ZDOTDIR" pull --ff-only --quiet 2>&1; then
        print "    ok"
    else
        print -u2 "    failed (run: git -C $ZDOTDIR pull)"
        return 1
    fi
}

# Re-run the installer for one concern only.
_zsh_update_install() {  # _zsh_update_install plugins|tools
    case "$1" in
        plugins) ZSH_SKIP_TOOLS=1   ZSH_CONFIG_NONINTERACTIVE=1 sh "$ZDOTDIR/install.sh" ;;
        tools)   ZSH_SKIP_PLUGINS=1 ZSH_CONFIG_NONINTERACTIVE=1 sh "$ZDOTDIR/install.sh" ;;
    esac
}

zsh-update() {
    local do_repo=1 do_plugins=1 do_tools=0

    case "${1:-}" in
        --plugins) do_repo=0; do_plugins=1; do_tools=0 ;;
        --tools)   do_repo=0; do_plugins=0; do_tools=1 ;;
        --all)     do_repo=1; do_plugins=1; do_tools=1 ;;
        '')        ;;
        *) print -u2 "usage: zsh-update [--plugins|--tools|--all]"; return 2 ;;
    esac

    (( do_repo ))    && { print "==> updating zsh-config"; _zsh_update_repo }
    (( do_plugins )) && _zsh_update_install plugins
    (( do_tools ))   && _zsh_update_install tools

    command mkdir -p "${_zsh_update_stamp:h}"
    command touch "$_zsh_update_stamp"
    print "==> done. Reload with: exec zsh"
}

# --- throttled background check -------------------------------------------
_zsh_update_due() {
    zmodload zsh/datetime 2>/dev/null || return 1
    [[ -f "$_zsh_update_stamp" ]] || return 0      # never run before

    zmodload -F zsh/stat b:zstat 2>/dev/null || return 1
    local -a st
    zstat -A st +mtime "$_zsh_update_stamp" 2>/dev/null || return 1

    (( (EPOCHSECONDS - st[1]) / 86400 >= ZSH_UPDATE_DAYS ))
}

_zsh_update_maybe() {
    (( ZSH_AUTO_UPDATE )) || return 0
    [[ -o interactive ]]  || return 0
    [[ -d "$ZDOTDIR/.git" ]] || return 0

    _zsh_update_due || return 0

    command mkdir -p "${_zsh_update_stamp:h}"
    # Stamp BEFORE starting the work: if the update fails, we must not retry
    # it on every single shell start.
    command touch "$_zsh_update_stamp"

    # &! detaches the job, so this never blocks the prompt and is not killed
    # when the shell exits. The next shell picks up whatever it fetched.
    {
        {
            print "=== $(date) ==="
            _zsh_update_repo
            _zsh_update_install plugins
        } >>"$_zsh_update_log" 2>&1
    } &!
}

_zsh_update_maybe
