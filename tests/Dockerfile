# tests/Dockerfile — a bare base image with only what is needed to BOOTSTRAP.
#
# Deliberately minimal: it installs curl, git and tar, and nothing else. zsh
# itself, and every CLI tool, must be installed by install.sh. If this file
# pre-installed them the matrix would be testing Docker, not the installer.
#
# Built once per distro by tests/matrix.sh, which then mounts the repo and
# runs tests/container-run.sh inside it.

ARG BASE=debian:12
FROM ${BASE}

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    ZSH_CONFIG_NONINTERACTIVE=1 \
    ZSH_AUTO_UPDATE=0

# One RUN, branching on whichever package manager exists.
#   util-linux  -> `script`, needed by smoke.zsh to get a pty
#   procps      -> `free`, used by hw()
#   findutils   -> `find`, used by the installer to locate extracted binaries
RUN set -eux; \
    if command -v dnf >/dev/null 2>&1; then \
        dnf install -y --setopt=install_weak_deps=False \
            curl git tar gzip bzip2 unzip ca-certificates \
            findutils procps-ng util-linux which diffutils; \
        dnf clean all; \
    elif command -v apt-get >/dev/null 2>&1; then \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            curl git tar gzip bzip2 unzip ca-certificates \
            findutils procps util-linux locales; \
        rm -rf /var/lib/apt/lists/*; \
    else \
        echo "unsupported base image: no dnf or apt-get" >&2; exit 1; \
    fi

WORKDIR /root
ENTRYPOINT ["/bin/sh"]
