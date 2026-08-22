#!/usr/bin/env bash
# tests/matrix.sh — run a clean install of this config on every supported
# Linux distro, in real containers, and assert the resulting shell works.
#
#   bash tests/matrix.sh                  # all distros
#   bash tests/matrix.sh rocky8 debian12  # just these
#   KEEP=1 bash tests/matrix.sh rocky8    # drop into a shell afterwards
#
# Requires Docker to be running. On Apple Silicon everything runs under
# --platform linux/amd64: several upstream projects publish x86_64-only
# release binaries, and testing the arm64 path would silently exercise
# different assets than the machines this config is actually deployed to.
#
# A single named volume caches GitHub API responses across distros. Without
# it, four distros x ~16 tools would exceed GitHub's 60 requests/hour
# unauthenticated limit and the later distros would fail for the wrong reason.
# Set GITHUB_TOKEN to raise that limit to 5000/hour.
#
# Written for bash 3.2 — no associative arrays, because that is what macOS
# still ships and this script has to run on the machine it is developed on.

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PLATFORM="${PLATFORM:-linux/amd64}"
CACHE_VOLUME=zshconfig-ghcache

ALL_TARGETS="rocky8 rocky9 debian12 ubuntu2404"

base_image_for() {
    case "$1" in
        rocky8)     echo "rockylinux/rockylinux:8" ;;
        rocky9)     echo "rockylinux/rockylinux:9" ;;
        debian12)   echo "debian:12" ;;
        ubuntu2404) echo "ubuntu:24.04" ;;
        *)          return 1 ;;
    esac
}

if [ "$#" -gt 0 ]; then
    TARGETS="$*"
else
    TARGETS="$ALL_TARGETS"
fi

RED=$'\033[31m'; GREEN=$'\033[32m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

docker info >/dev/null 2>&1 || {
    echo "${RED}Docker is not running.${RESET} Start Docker Desktop and re-run." >&2
    exit 1
}

docker volume create "$CACHE_VOLUME" >/dev/null

LOGDIR=$(mktemp -d)
echo "logs: $LOGDIR"

SUMMARY=""
failed=0

for name in $TARGETS; do
    if ! base=$(base_image_for "$name"); then
        echo "${RED}unknown target: $name${RESET}" >&2
        SUMMARY="$SUMMARY$name:unknown "
        failed=1
        continue
    fi

    printf '\n%s══ %s (%s) ══%s\n' "$BOLD" "$name" "$base" "$RESET"
    log="$LOGDIR/$name.log"

    if ! docker build \
            --platform "$PLATFORM" \
            --build-arg "BASE=$base" \
            -t "zshconfig-test:$name" \
            -f "$REPO_ROOT/tests/Dockerfile" \
            "$REPO_ROOT/tests" >"$log" 2>&1; then
        echo "  ${RED}build failed${RESET} — see $log"
        tail -20 "$log" | sed 's/^/    /'
        SUMMARY="$SUMMARY$name:build-failed "
        failed=1
        continue
    fi
    echo "  image built"

    if [ "${KEEP:-0}" = 1 ]; then
        exec docker run --rm -it --platform "$PLATFORM" \
            -v "$REPO_ROOT:/src:ro" \
            -v "$CACHE_VOLUME:/root/.cache/zsh-config/gh" \
            -e "GITHUB_TOKEN=${GITHUB_TOKEN:-}" \
            "zshconfig-test:$name" -c '/src/tests/container-run.sh; exec sh'
    fi

    if docker run --rm --platform "$PLATFORM" \
            -v "$REPO_ROOT:/src:ro" \
            -v "$CACHE_VOLUME:/root/.cache/zsh-config/gh" \
            -e "GITHUB_TOKEN=${GITHUB_TOKEN:-}" \
            "zshconfig-test:$name" /src/tests/container-run.sh >>"$log" 2>&1; then
        echo "  ${GREEN}PASS${RESET}"
        SUMMARY="$SUMMARY$name:pass "
    else
        echo "  ${RED}FAIL${RESET} — see $log"
        # The smoke-test section is what usually explains the failure.
        sed -n '/running smoke test/,$p' "$log" | tail -40 | sed 's/^/    /'
        SUMMARY="$SUMMARY$name:fail "
        failed=1
    fi
done

printf '\n%s══ summary ══%s\n' "$BOLD" "$RESET"
for entry in $SUMMARY; do
    n="${entry%%:*}"; r="${entry##*:}"
    if [ "$r" = pass ]; then
        printf '  %s%-12s PASS%s\n' "$GREEN" "$n" "$RESET"
    else
        printf '  %s%-12s %s%s\n' "$RED" "$n" "$r" "$RESET"
    fi
done
printf '\nlogs: %s\n' "$LOGDIR"

if [ "$failed" -ne 0 ]; then
    exit 1
fi
printf '%sAll distros passed.%s\n' "$GREEN" "$RESET"
