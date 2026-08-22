# zsh-config

[![zsh](https://img.shields.io/badge/zsh-5.9%2B-blue)](https://www.zsh.org/)
[![platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Rocky%208%2F9%20%7C%20Debian%20%7C%20Ubuntu-lightgrey)](#supported-platforms)
[![license](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modular, XDG-compliant Zsh configuration that installs itself with one
command and works the same on a Mac laptop and a bare Rocky 8 box.

---

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/nguyenpanda/zsh-config/main/install.sh | sh
```

Then:

```sh
exec zsh
```

That is the whole thing. The installer clones the config, installs every CLI
tool it references, fetches the plugins, writes a `~/.zshenv` stub and sets zsh
as your login shell. It is idempotent — re-running it is a no-op.

It also works **without root**, falling back to user-local installs in
`~/.local/bin`, which is what you want on a shared HPC or Rocky box.

### Supported platforms

| Platform | Package source | Notes |
| :--- | :--- | :--- |
| macOS (Apple Silicon & Intel) | Homebrew | |
| Rocky / RHEL / Alma 8 | dnf + EPEL, then prebuilt binaries | `eza` and a modern `fzf` come from GitHub releases; neovim is pinned to 0.9.5 (glibc 2.28) |
| Rocky / RHEL / Alma 9 | dnf + EPEL + CRB | |
| Debian 12 | apt | `bat`→`batcat`, `fd`→`fdfind` are handled |
| Ubuntu 22.04 / 24.04 | apt | |

Windows is not supported.

---

## Layout

```
~/.config/zsh/
├── .zshenv              XDG dirs, PATH, EDITOR       (every zsh)
├── .zprofile            Homebrew shellenv            (login shells)
├── .zshrc               orchestrator: sources lib/*  (interactive shells)
├── .p10k.zsh            prompt configuration (tracked, so new machines match)
├── install.sh           the one command
├── manifests/
│   ├── plugins.tsv      plugin repos + pinned refs
│   └── tools.tsv        CLI tools + how to install each, per platform
├── install/             installer internals
├── lib/                 the actual configuration
└── tests/               smoke test + Docker matrix
```

`lib/` is loaded in filename order, and the numeric prefixes **are** the load
order:

| File | Responsibility |
| :--- | :--- |
| `00-platform.zsh` | Detects the platform into `ZSH_OS`, `ZSH_DISTRO`, `ZSH_DISTRO_FAMILY`, `ZSH_DISTRO_VER`, `ZSH_ARCH` |
| `10-env.zsh` | Compilation flags, fd ignore list |
| `20-omz.zsh` | Oh My Zsh settings, plugin list, and load |
| `30-aliases.zsh` | Aliases — every one guarded on the tool existing |
| `40-tools.zsh` | zoxide, argcomplete, delta, uv integrations |
| `50-fzf.zsh` | fzf key bindings, preview, custom widgets |
| `60-hooks.zsh` | Auto-activate a project's `.venv` |
| `70-cmd.zsh` | `hw` — hardware summary |
| `90-update.zsh` | `zsh-update` and the throttled background check |

Order matters: platform detection has to come first, Oh My Zsh has to load
before our aliases can override its own, and fzf needs the ignore list from
`10-env.zsh`.

---

## How tools get installed

Every CLI tool is a row in [`manifests/tools.tsv`](manifests/tools.tsv), and
the installer tries four tiers in order:

| Tier | Source | Needs root |
| :--- | :--- | :--- |
| 0 | Already installed and new enough — skip | – |
| 1 | System package manager (`brew` / `apt` / `dnf`+EPEL) | yes (except brew) |
| 2 | Prebuilt release binary from GitHub → `~/.local/bin` | no |
| 3 | `cargo install` | no |

Tier 1 is **re-verified against `min_ver`**, so an ancient distro package falls
through instead of being accepted. That one rule is what makes Rocky 8 work:
its EPEL `fzf` predates the `fzf --zsh` flag this config needs, so it gets a
musl release binary instead. `eza` isn't in RHEL repos at all and takes the
same route.

Release tags are **pinned**, not `latest`, so installs are reproducible.

**To add a tool:** add one row to `manifests/tools.tsv`, then `zsh-update --tools`.

---

## Keeping it current

```sh
zsh-update              # config repo + plugins
zsh-update --plugins    # plugins only              (alias: uzp)
zsh-update --tools      # CLI tools only
zsh-update --all        # everything
```

A background check runs **at most once every 7 days**, detached, so it never
blocks your prompt and never touches the network on a normal shell start.
Disable it with `ZSH_AUTO_UPDATE=0`, or change the interval with
`ZSH_UPDATE_DAYS`.

Oh My Zsh manages its own updates, so `manifests/plugins.tsv` tracks it by
branch and the installer never force-resets it. The other plugins are pinned
to exact commits.

---

## Machine-specific settings and secrets

Three files are gitignored and sourced last, so they override everything:

| File | For |
| :--- | :--- |
| `local.zsh` | Host-specific PATH entries, work proxies, per-box settings |
| `secrets.zsh` | API keys and tokens (created mode 600) |
| `p10k.local.zsh` | Per-machine prompt tweaks — e.g. a box without Nerd Fonts |

The installer creates the first two with a template. A `pre-commit` hook in
`.githooks/` refuses to commit obvious credentials; bypass it deliberately with
`git commit --no-verify`.

**Never put a secret in any other file in this repo.**

---

## Key bindings

| Shortcut | Action |
| :--- | :--- |
| `Ctrl-R` | Fuzzy history search |
| `Ctrl-T` | Fuzzy file search |
| `Ctrl-F` | Custom picker: files, excluding hidden |
| `Alt-C` | Fuzzy `cd` |
| `⌥ C` / `⌥ T` / `⌥ F` | macOS Option-key equivalents of the above |

---

## Testing

```sh
zsh tests/smoke.zsh          # 34 assertions against a live interactive shell
bash tests/matrix.sh         # clean install on all four Linux distros
bash tests/matrix.sh rocky8  # just one
KEEP=1 bash tests/matrix.sh rocky8   # ...then drop into a shell inside it
```

The matrix needs Docker running. Set `GITHUB_TOKEN` to avoid GitHub's
unauthenticated API rate limit.

Static checks:

```sh
shellcheck -s sh install.sh install/*.sh
zsh -n .zshenv .zshrc lib/*.zsh
```

---

## Notes

**Entry point.** The installer writes a three-line `~/.zshenv` that sets
`ZDOTDIR` and sources this directory's `.zshenv`. Older setups did the same
thing from `/etc/zshenv`, which needed sudo and was not in the repo. If you
have that file it still works and is left alone — the installer will tell you
it is there.

**`grep` is not aliased to ripgrep.** ripgrep rejects grep's flags and recurses
by default, so aliasing it silently breaks scripts. Use `rgg`.

---

*Maintained by nguyenpanda*
