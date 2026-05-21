# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# LLVM
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib:$LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include:$CPPFLAGS"

# OpenMP
export LDFLAGS="-L/opt/homebrew/opt/libomp/lib:$LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/libomp/include:$CPPFLAGS"
