# 🚀 Professional Zsh Configuration

[![Zsh Version](https://img.shields.io/badge/zsh-v5.9%2B-blue)](https://www.zsh.org/)
[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey)](https://apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-performance, modular, and XDG-compliant Zsh configuration. Tailored for macOS power users and engineered for seamless cross-machine synchronization.

---

## 📑 Table of Contents

- [Architecture](#-architecture)
- [Key Features](#-key-features)
- [Installation](#-installation)
- [Key Bindings](#-key-bindings)
- [Maintenance](#-maintenance)

---

## 🏗️ Architecture

This configuration adopts a modular design, decoupling core logic from environment-specific settings.

| File | Responsibility |
| :--- | :--- |
| **`.zshrc`** | Main initialization and plugin orchestration. |
| **`.zshenv`** | Global environment variables and XDG directory definitions. |
| **`aliases.zsh`** | Command shortcuts and robust tool abstractions. |
| **`fzf.zsh`** | Advanced fuzzy finder logic and Mac-specific keyboard patches. |
| **`tools.zsh`** | Custom utility functions and lifecycle management scripts. |
| **`env.zsh`** | Machine-level compilation flags and path exports. |

---

## ✨ Key Features

### 🛡️ XDG Compliance

Keep your `$HOME` directory pristine. All transient data is redirected:

- **Cache**: `$XDG_CACHE_HOME/zsh` (Completion dumps, etc.)
- **State**: `$XDG_STATE_HOME/zsh` (Command history)

### ⚡ Git Submodules

Plugins and themes are robustly managed via Git submodules, ensuring locked versions and deterministic setups across machines:

- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) (Theme)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

### 🔍 Professional FZF Integration

- **Modern Core**: Built on the native `fzf --zsh` integration.
- **Mac Hardware Fixes**: Native support for **Option (⌥) Key** shortcuts (Option+C, Option+T) without needing terminal-specific configuration.
- **Rich Previews**: Real-time file previews powered by `bat`.

### 🛠️ Plugin Lifecycle Management

Includes a custom `update_zsh_plugins` utility (alias: `uzp`) to programmatically update all custom Git-based plugins with rebase and autostash protection.

---

## 🛠️ Installation

### 1. Prerequisites

Install the core toolset via Homebrew:

```bash
brew install fzf fd bat zoxide ripgrep eza trash
```

### 2. Deployment

1. **Clone the repository**:

   ```bash
   git clone --recurse-submodules https://github.com/nguyenpanda/zsh-config.git ~/.config/zsh
   ```

2. **Establish entry points**:

   ```bash
   ln -sf ~/.config/zsh/.zshrc ~/.zshrc
   ln -sf ~/.config/zsh/.zshenv ~/.zshenv
   ```

3. **Launch**: Restart your terminal.

---

## ⌨️ Key Bindings

| Shortcut | Action | Tool |
| :--- | :--- | :--- |
| **`Option + C`** | Fuzzy search directories and `cd` | `fzf` + `fd` |
| **`Option + T`** | Fuzzy search all files | `fzf` + `fd` |
| **`Option + F`** | **Custom**: Search non-hidden project files | `fzf` + `fd` |
| **`Ctrl + R`** | Interactive history search | `fzf` |
| **`Ctrl + F`** | Shortcut to custom file picker | `fzf` |

---

## 🧹 Maintenance

Use the following aliases to manage your environment:

- `uzp`: Update all custom Git-based plugins.
- `szsh`: Instantly reload the shell configuration.

---

*Maintained with ❤️ by nguyenpanda*
