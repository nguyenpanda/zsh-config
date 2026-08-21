_hw_mac() {
    echo "--------------------------------"
    echo " 💻 APPLE SILICON SUMMARY"
    echo "--------------------------------"
    echo "Chip: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown')"
    echo "RAM:  $(sysctl -n hw.memsize 2>/dev/null | awk '{print $0/1073741824" GB"}')"

    echo ""
    echo "--- CPU & Core Topology ---"

    S_CORES=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo "0")
    P_CORES=$(sysctl -n hw.perflevel1.physicalcpu 2>/dev/null || echo "0")
    TOTAL_CORES=$(sysctl -n hw.physicalcpu 2>/dev/null || echo "0")
    echo "Cores: $TOTAL_CORES Total ($S_CORES Super, $P_CORES Performance)"

    L1I=$(sysctl -n hw.perflevel0.l1icachesize 2>/dev/null | awk '{print $0/1024" KB"}')
    L1D=$(sysctl -n hw.perflevel0.l1dcachesize 2>/dev/null | awk '{print $0/1024" KB"}')
    L2=$(sysctl -n hw.perflevel0.l2cachesize 2>/dev/null | awk '{print $0/1048576" MB"}')
    echo "Cache per Core: L1-Instruction: $L1I | L1-Data: $L1D | L2: $L2"

    ARCH=$(uname -m)
    echo "Architecture: $ARCH"

    EXTENSIONS=$(sysctl -a 2>/dev/null | command grep hw.optional | command grep -E "AdvSIMD|armv8|neon|fp16" | awk -F. '{print $3}' | awk -F: '{print $1}' | paste -sd "," - | sed 's/,/, /g')
    echo "Extensions: $EXTENSIONS"

    echo ""
    echo "--- GPU Details ---"
    system_profiler SPDisplaysDataType 2>/dev/null | command grep -E "Chipset Model|Total Number of Cores|Metal Support"
    echo "--------------------------------"
}

_hw_linux() {
    echo "--------------------------------"
    echo " 🐧 LINUX HARDWARE SUMMARY"
    echo "--------------------------------"
    
    # CPU Model
    local cpu_model=$(command grep -m 1 "model name" /proc/cpuinfo | cut -d ':' -f2 | sed 's/^[ \t]*//')
    if [[ -z "$cpu_model" ]]; then
        cpu_model=$(command grep -m 1 "Model" /proc/cpuinfo | cut -d ':' -f2 | sed 's/^[ \t]*//')
    fi
    echo "CPU:  ${cpu_model:-Unknown}"
    
    # RAM
    if command -v free >/dev/null 2>&1; then
        local ram=$(free -h | awk '/^Mem:/ {print $2}')
        echo "RAM:  $ram"
    fi

    echo ""
    echo "--- CPU & Core Topology ---"
    if command -v lscpu >/dev/null 2>&1; then
        local sockets=$(lscpu | command grep "^Socket(s):" | awk '{print $2}')
        local cores_per_socket=$(lscpu | command grep "^Core(s) per socket:" | awk '{print $4}')
        local threads_per_core=$(lscpu | command grep "^Thread(s) per core:" | awk '{print $4}')
        local total_threads=$(lscpu | command grep "^CPU(s):" | awk '{print $2}')
        echo "Sockets: $sockets | Cores/Socket: $cores_per_socket | Threads/Core: $threads_per_core"
        echo "Total Logical Cores: $total_threads"
    fi

    ARCH=$(uname -m)
    echo "Architecture: $ARCH"

    echo ""
    echo "--- GPU Details ---"
    if command -v lspci >/dev/null 2>&1; then
        lspci | command grep -i vga | cut -d ':' -f3 | sed 's/^[ \t]*//'
    else
        echo "lspci not available (install pciutils)"
    fi
    echo "--------------------------------"
}

hw() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        _hw_mac
    else
        _hw_linux
    fi
}
