# 🚀 Professional Zsh Configuration

A modular, performant, and professional Zsh configuration tailored for macOS (M-series) and engineered for portability.

## 🏗️ Architecture

This setup moves away from a monolithic \`.zshrc\` in favor of a clean, modular structure:

- **\`.zshrc\`**: The main entry point, handling Oh My Zsh and theme initialization.
- **\`.zshenv\`**: Defines XDG base directories and optimizes \`\$PATH\`/\`\$FPATH\`.
- **\`aliases.zsh\`**: Centralized command shortcuts and robust tool overrides.
- **\`env.zsh\`**: Compilation flags and environment-specific variables.
- **\`fzf.zsh\`**: Advanced fuzzy finder integration with Mac-specific fixes.
- **\`tools.zsh\`**: Custom utility functions (like the plugin updater).

## ✨ Key Features

- **XDG Compliance**: Keeps your \`\$HOME\` clean by moving \`.zcompdump\` and history to \`~/.cache\` and \`~/.local\`.
- **Professional FZF Integration**: 
  - Modern \`fzf --zsh\` integration.
  - Native support for **Mac Option (⌥) Keys** without terminal configuration.
  - Interactive previews using \`bat\` and fast searching via \`fd\`.
- **Custom Plugin Updater**: Use \`uzp\` (or \`update_zsh_plugins\`) to keep all your custom Git plugins up to date.
- **Optimized Startup**: Consolidated \`compinit\` calls and intelligent sourcing order for maximum speed.
- **Portable**: Includes a \`.gitignore\` designed to keep machine-specific state out of your repository.

## 🛠️ Installation

### 1. Prerequisites
Ensure you have the following tools installed (Homebrew is recommended):
\`\`\`bash
brew install fzf fd bat zoxide ripgrep eza
\`\`\`

### 2. Setup
1. **Clone this repository** into your config folder:
   \`\`\`bash
   git clone <your-repo-url> ~/.config/zsh
   \`\`\`

2. **Symlink the entry points**:
   \`\`\`bash
   ln -sf ~/.config/zsh/.zshrc ~/.zshrc
   ln -sf ~/.config/zsh/.zshenv ~/.zshenv
   \`\`\`

3. **Install Oh My Zsh** (if not already present):
   \`\`\`bash
   sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   \`\`\`

## ⌨️ Shortcuts

| Key | Action |
|-----|--------|
| \`Option + C\` | Fuzzy search directories and \`cd\` |
| \`Option + T\` | Fuzzy search files |
| \`Option + F\` | **Custom**: Clean file picker (excludes hidden/git) |
| \`Ctrl + R\` | Fuzzy search command history |
| \`uzp\` | Update all custom Zsh plugins |
| \`szsh\` | Reload Zsh configuration |

## 📦 Custom Plugins
This setup is optimized for:
- \`zsh-autosuggestions\`
- \`zsh-syntax-highlighting\`
- \`powerlevel10k\`

---
*Maintained by nguyenpanda*
