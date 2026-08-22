# ~/.config/zsh/.zprofile — login shells only.
#
# Previously this was a single unguarded line:
#     eval "$(/opt/homebrew/bin/brew shellenv zsh)"
# which is a hard error on Intel Macs, on Linux, and on any Mac without
# Homebrew. Probe for brew instead, and only run shellenv if it is really
# there.

for _brew_root in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [[ -x "$_brew_root/bin/brew" ]]; then
        eval "$("$_brew_root/bin/brew" shellenv zsh)"
        break
    fi
done
unset _brew_root
