# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# LLVM
if [[ -d /opt/homebrew/opt/llvm ]]; then
  export LDFLAGS="-L/opt/homebrew/opt/llvm/lib $LDFLAGS"
  export CPPFLAGS="-I/opt/homebrew/opt/llvm/include $CPPFLAGS"
fi

# OpenMP
if [[ -d /opt/homebrew/opt/libomp ]]; then
  export LDFLAGS="-L/opt/homebrew/opt/libomp/lib $LDFLAGS"
  export CPPFLAGS="-I/opt/homebrew/opt/libomp/include $CPPFLAGS"
fi

# CLI tools
local excludes=(
  # OS & Version Control
  "--exclude .git"
  "--exclude .DS_Store"
  "--exclude .Trash"
  "--exclude .Trashes"
  "--exclude .Spotlight-V100"

  # Virtual Environments & Dependencies
  "--exclude node_modules"
  "--exclude .venv"
  "--exclude venv"
  "--exclude env"

  # C/C++, CUDA & Compiled Binaries
  "--exclude build"
  "--exclude out"
  "--exclude target"
  "--exclude 'cmake-build-*'"
  "--exclude .clangd"
  "--exclude .ccls-cache"
  "--exclude .nv"
  "--exclude nsight-workspace"

  # Python Caches & Build Artifacts
  "--exclude .cache"
  "--exclude __pycache__"
  "--exclude .pytest_cache"
  "--exclude .mypy_cache"
  "--exclude .ruff_cache"
  "--exclude '*.egg-info'"

  # Logs, Temp Files & Infrastructure
  "--exclude tmp"
  "--exclude temp"
  "--exclude logs"
  "--exclude '*.log'"
  "--exclude .docker"

  # AI, LLMs & Weights
  "--exclude .ollama"
  "--exclude .huggingface"

  # IDEs & Editor Workspaces
  "--exclude .idea"
  "--exclude .vscode"
)

export FD_EXCLUDES="${excludes[*]}"