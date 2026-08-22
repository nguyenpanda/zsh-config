# ~/.config/zsh/.profile — POSIX login shells (sh, bash, dash).
#
# zsh does NOT read this file (it reads .zprofile); it exists for the case
# where a login process falls back to /bin/sh. Symlink it to ~/.profile if you
# want it used.
#
# It used to hardcode /Users/nguyenpanda/.lmstudio/bin and source
# ~/.local/bin/env unguarded, both of which fail on any other machine.
# Machine-specific paths now belong in local.zsh (gitignored).

# uv / rustup and friends drop a PATH snippet here.
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

for _dir in "$HOME/bin" "$HOME/.local/bin" "$HOME/.cargo/bin"; do
    if [ -d "$_dir" ]; then
        case ":$PATH:" in
            *":$_dir:"*) ;;
            *) PATH="$_dir:$PATH" ;;
        esac
    fi
done
unset _dir
export PATH
