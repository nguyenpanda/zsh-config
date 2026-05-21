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
