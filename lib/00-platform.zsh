# lib/00-platform.zsh — detect the platform once, up front.
#
# Everything downstream branches on these instead of re-testing $OSTYPE ad
# hoc, and the names match install/lib.sh's detect_platform() so the shell and
# the installer always agree about what machine they are on.
#
#   ZSH_OS            macos | linux
#   ZSH_DISTRO        macos | rocky | debian | ubuntu | ...
#   ZSH_DISTRO_FAMILY macos | rhel | debian | unknown
#   ZSH_DISTRO_VER    major version only ("8", "9", "12", "26")
#   ZSH_ARCH          x86_64 | aarch64

case "$OSTYPE" in
    darwin*) ZSH_OS=macos ;;
    linux*)  ZSH_OS=linux ;;
    *)       ZSH_OS=unknown ;;
esac

case "$(uname -m)" in
    arm64|aarch64) ZSH_ARCH=aarch64 ;;
    x86_64|amd64)  ZSH_ARCH=x86_64 ;;
    *)             ZSH_ARCH="$(uname -m)" ;;
esac

if [[ "$ZSH_OS" == macos ]]; then
    ZSH_DISTRO=macos
    ZSH_DISTRO_FAMILY=macos
    ZSH_DISTRO_VER="${$(sw_vers -productVersion 2>/dev/null)%%.*}"
elif [[ -r /etc/os-release ]]; then
    # Read the file directly rather than sourcing it: sourcing would dump
    # NAME, VERSION, HOME_URL and friends into the interactive shell.
    ZSH_DISTRO="${$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"'):-unknown}"
    ZSH_DISTRO_VER="${$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')%%.*}"
    _id_like="$(sed -n 's/^ID_LIKE=//p' /etc/os-release | tr -d '"')"

    case "$ZSH_DISTRO" in
        rocky|rhel|centos|almalinux|fedora|ol) ZSH_DISTRO_FAMILY=rhel ;;
        debian|ubuntu|linuxmint|pop|raspbian)  ZSH_DISTRO_FAMILY=debian ;;
        *)
            case " $_id_like " in
                *rhel*|*fedora*|*centos*) ZSH_DISTRO_FAMILY=rhel ;;
                *debian*|*ubuntu*)        ZSH_DISTRO_FAMILY=debian ;;
                *)                        ZSH_DISTRO_FAMILY=unknown ;;
            esac ;;
    esac
    unset _id_like
else
    ZSH_DISTRO=unknown
    ZSH_DISTRO_FAMILY=unknown
    ZSH_DISTRO_VER=0
fi

: "${ZSH_DISTRO_VER:=0}"

export ZSH_OS ZSH_DISTRO ZSH_DISTRO_FAMILY ZSH_DISTRO_VER ZSH_ARCH
