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

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PLATFORM="${PLATFORM:-linux/amd64}"
CACHE_VOLUME=zshconfig-ghcache

# name  ->  base image
declare -A BASES=(
    [rocky8]="rockylinux/rockylinux:8"
    [rocky9]="rockylinux/rockylinux:9"
    [debian12]="debian:12"
    [ubuntu2404]="ubuntu:24.04"
)
ORDER=(rocky8 rocky9 debian12 ubuntu2404)

TARGETS=("$@")
[[ ${#TARGETS[@]} -eq 0 ]] && TARGETS=("${ORDER[@]}")

RED=$'\033[31m'; GREEN=$'\033[32m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

docker info >/dev/null 2>&1 || {
    echo "${RED}Docker is not running.${RESET} Start Docker Desktop and re-run." >&2
    exit 1
}

docker volume create "$CACHE_VOLUME" >/dev/null

declare -A RESULT
LOGDIR=$(mktemp -d)
echo "logs: $LOGDIR"

for name in "${TARGETS[@]}"; do
    base="${BASES[$name]:-}"
    if [[ -z "$base" ]]; then
        echo "${RED}unknown target: $name${RESET}" >&2
        RESULT[$name]="unknown"
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
        echo "${RED}build failed${RESET} — see $log"
        tail -20 "$log" | sed 's/^/    /'
        RESULT[$name]="build-failed"
        continue
    fi
    echo "  image built"

    if [[ "${KEEP:-0}" == 1 ]]; then
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
        RESULT[$name]="pass"
    else
        echo "  ${RED}FAIL${RESET} — see $log"
        # Show the smoke-test section, which is what usually matters.
        sed -n '/running smoke test/,$p' "$log" | tail -40 | sed 's/^/    /'
        RESULT[$name]="fail"
    fi
done

printf '\n%s══ summary ══%s\n' "$BOLD" "$RESET"
failed=0
for name in "${TARGETS[@]}"; do
    r="${RESULT[$name]:-skipped}"
    case "$r" in
        pass) printf '  %s%-12s PASS%s\n' "$GREEN" "$name" "$RESET" ;;
        *)    printf '  %s%-12s %s%s\n' "$RED" "$name" "$r" "$RESET"; failed=1 ;;
    esac
done
printf '\nlogs: %s\n' "$LOGDIR"
[[ $failed -eq 0 ]] || exit 1
printf '%sAll distros passed.%s\n' "$GREEN" "$RESET"
