#!/usr/bin/env zsh
# tests/smoke.zsh — assert a freshly installed shell actually works.
#
# Run natively:      zsh tests/smoke.zsh
# Run in a container: tests/matrix.sh does it for every distro.
#
# Queries a real interactive shell (zsh -i) rather than checking files,
# because the things that break in practice — an unguarded eval, an alias
# pointing at a missing binary — only show up when the shell starts.

emulate -L zsh
setopt no_unset pipe_fail

typeset -i PASS=0 FAIL=0
typeset -a FAILURES

pass() { print -- "  \e[32mPASS\e[0m  $1"; (( PASS++ )) }
fail() { print -- "  \e[31mFAIL\e[0m  $1"; (( FAIL++ )); FAILURES+=("$1") }

# check <description> <zsh code evaluated inside an interactive shell>
check() {
    local desc="$1" code="$2"
    if ZSH_AUTO_UPDATE=0 zsh -i -c "$code" >/dev/null 2>&1; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

# check_out <description> <code> — passes when the code prints something
check_out() {
    local desc="$1" code="$2" out
    out=$(ZSH_AUTO_UPDATE=0 zsh -i -c "$code" 2>/dev/null)
    if [[ -n "$out" ]]; then
        pass "$desc  ($out)"
    else
        fail "$desc"
    fi
}

print "\n\e[1mzsh-config smoke test\e[0m"
print "  zsh      $ZSH_VERSION"
print "  ZDOTDIR  ${ZDOTDIR:-unset}"

# --------------------------------------------------------------------------
print "\n\e[1m1. Startup is silent\e[0m"
# The single most important assertion: a config that prints errors on every
# new terminal is broken even if every feature works.
#
# This must run under a pty. Without one, zsh cannot enable the `zle` and
# `monitor` options and powerlevel10k's gitstatus refuses to start, so a
# perfectly healthy config still emits several errors. `script` gives us a
# pty; its arguments differ between util-linux and BSD/macOS.
startup_capture() {
    if command -v script >/dev/null 2>&1; then
        if script --version 2>&1 | grep -qi util-linux; then
            script -qec "ZSH_AUTO_UPDATE=0 zsh -i -c exit" /dev/null 2>&1
            return
        fi
        script -q /dev/null env ZSH_AUTO_UPDATE=0 zsh -i -c exit 2>&1
        return
    fi
    ZSH_AUTO_UPDATE=0 zsh -i -c exit 2>&1 </dev/null
}

startup_output=$(startup_capture)
# A pty echoes the EOF/exit keystroke back; that is the terminal, not us.
# macOS echoes it as the literal two-character string "^D".
startup_output="${startup_output//$'\004'/}"
startup_output="${startup_output//$'\b'/}"
startup_output="${startup_output//$'\r'/}"
startup_output="${startup_output//'^D'/}"
startup_output="${startup_output##[[:space:]]#}"
startup_output="${startup_output%%[[:space:]]#}"
if [[ -z "$startup_output" ]]; then
    pass "interactive startup produces no output"
else
    fail "interactive startup printed:"
    print -- "$startup_output" | sed 's/^/        /'
fi

# --------------------------------------------------------------------------
print "\n\e[1m2. Environment\e[0m"
check_out "ZDOTDIR is set"        'print -r -- $ZDOTDIR'
check_out "ZSH_OS is set"         'print -r -- $ZSH_OS'
check_out "ZSH_DISTRO is set"     'print -r -- "$ZSH_DISTRO $ZSH_DISTRO_VER"'
check_out "ZSH_ARCH is set"       'print -r -- $ZSH_ARCH'
check_out "HISTFILE is under XDG" '[[ $HISTFILE == $XDG_STATE_HOME/* ]] && print -r -- $HISTFILE'
check_out "EDITOR resolves"       'command -v $EDITOR'

# --------------------------------------------------------------------------
print "\n\e[1m3. Oh My Zsh and plugins\e[0m"
check     "oh-my-zsh.sh loaded"        '[[ -n $ZSH ]] && [[ -r $ZSH/oh-my-zsh.sh ]]'
check     "powerlevel10k theme present" '[[ -r $ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme ]]'
check     "p10k function defined"       '(( $+functions[p10k] ))'
check     "zsh-autosuggestions active"  '[[ -n $ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE ]]'
check     "zsh-syntax-highlighting active" '(( $+ZSH_HIGHLIGHT_VERSION )) || [[ -n ${ZSH_HIGHLIGHT_HIGHLIGHTERS[1]:-} ]]'

# --------------------------------------------------------------------------
print "\n\e[1m4. Core tools\e[0m"
for tool in git zsh fzf rg jq; do
    check "$tool is installed" "command -v $tool"
done
check "fd or fdfind is installed"  'command -v fd || command -v fdfind'
check "bat or batcat is installed" 'command -v bat || command -v batcat'

# The Rocky 8 regressions this whole project exists to fix:
check_out "eza runs (absent from Rocky 8 repos)" 'eza --version | head -1'
check     "fzf --zsh works (needs fzf >= 0.48)"  'fzf --zsh >/dev/null'
check_out "nvim runs (EDITOR must not be a lie)" 'nvim --version | head -1'

# --------------------------------------------------------------------------
print "\n\e[1m5. Aliases point at real commands\e[0m"
# An alias to a missing binary is worse than no alias: it turns a working
# command into command-not-found. This is what `rm` did on Linux.
check "rm alias resolves to an existing command" \
      'local t=${aliases[rm]:-rm}; command -v ${t%% *}'
check "ls alias resolves to an existing command" \
      'local t=${aliases[ls]:-ls}; command -v ${t%% *}'
check "grep is NOT aliased to ripgrep" \
      '[[ ${aliases[grep]:-} != rg* ]]'
check "code is a function, not a self-appending alias" \
      '(( $+functions[code] )) || ! (( $+aliases[code] ))'

# --------------------------------------------------------------------------
print "\n\e[1m6. Custom commands\e[0m"
check "hw() is defined"         '(( $+functions[hw] ))'
check "hw() runs"               'hw >/dev/null'
check "zsh-update() is defined" '(( $+functions[zsh-update] ))'
check "fd ignore file is readable" '[[ -r $ZDOTDIR/fd-ignore ]]'
check "FD_OPTS is an array"     '[[ ${(t)FD_OPTS} == array* ]]'

# --------------------------------------------------------------------------
print "\n\e[1m7. Local override convention\e[0m"
check "local.zsh is gitignored"   'cd $ZDOTDIR && git check-ignore -q local.zsh'
check "secrets.zsh is gitignored" 'cd $ZDOTDIR && git check-ignore -q secrets.zsh'
check "plugin dirs are gitignored" 'cd $ZDOTDIR && git check-ignore -q .oh-my-zsh'

# --------------------------------------------------------------------------
print ""
if (( FAIL == 0 )); then
    print -- "\e[32m\e[1mAll $PASS checks passed.\e[0m\n"
    exit 0
else
    print -- "\e[31m\e[1m$FAIL of $(( PASS + FAIL )) checks failed:\e[0m"
    for f in $FAILURES; do print -- "    - $f"; done
    print ""
    exit 1
fi
