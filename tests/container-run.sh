#!/bin/sh
# tests/container-run.sh — run inside a test container by tests/matrix.sh.
#
# Copies the repo out of the read-only mount at /src into the place a real
# user would have it, runs the installer exactly as a new machine would, then
# runs the smoke test.
#
# The copy matters: /src is mounted read-only precisely so a container can
# never write plugin checkouts or local.zsh back into the developer's repo.

set -eu

DEST="$HOME/.config/zsh"

printf '\n=== preparing %s ===\n' "$DEST"
mkdir -p "$DEST"
# A fresh machine has no plugins, so they are excluded rather than copied and
# deleted: the installer's clone path is exactly what we want to exercise, and
# the developer's checkout carries ~100 MB of them.
(cd /src && tar -cf - \
    --exclude=./.oh-my-zsh \
    --exclude=./omz-custom \
    --exclude=./local.zsh \
    --exclude=./secrets.zsh \
    .) | (cd "$DEST" && tar -xf -)

# git needs an identity before the repo is usable, and the mounted checkout
# is owned by a different uid than root inside the container.
git config --global --add safe.directory "$DEST" 2>/dev/null || true
git config --global user.email "test@example.invalid" 2>/dev/null || true
git config --global user.name  "matrix test" 2>/dev/null || true

printf '\n=== running install.sh ===\n'
sh "$DEST/install.sh"

printf '\n=== verifying idempotency (second run must change nothing) ===\n'
sh "$DEST/install.sh" > /tmp/second-run.log 2>&1 || {
    echo "SECOND RUN FAILED:"; cat /tmp/second-run.log; exit 1
}
if grep -qE '^\s+ok ' /tmp/second-run.log; then
    echo "note: second run still installed things:"
    grep -E '^\s+ok ' /tmp/second-run.log | sed 's/^/    /'
else
    echo "second run was a no-op"
fi

printf '\n=== running smoke test ===\n'
export ZDOTDIR="$DEST"
exec zsh "$DEST/tests/smoke.zsh"
