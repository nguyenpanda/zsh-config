hw() {
    echo "--------------------------------"
    echo " 💻 APPLE SILICON SUMMARY"
    echo "--------------------------------"
    echo "Chip: $(sysctl -n machdep.cpu.brand_string)"
    echo "RAM:  $(sysctl -n hw.memsize | awk '{print $0/1073741824" GB"}')"

    echo ""
    echo "--- CPU & Core Topology ---"

    S_CORES=$(sysctl -n hw.perflevel0.physicalcpu)
    P_CORES=$(sysctl -n hw.perflevel1.physicalcpu)
    TOTAL_CORES=$(sysctl -n hw.physicalcpu)
    echo "Cores: $TOTAL_CORES Total ($S_CORES Super, $P_CORES Performance)"

    L1I=$(sysctl -n hw.perflevel0.l1icachesize | awk '{print $0/1024" KB"}')
    L1D=$(sysctl -n hw.perflevel0.l1dcachesize | awk '{print $0/1024" KB"}')
    L2=$(sysctl -n hw.perflevel0.l2cachesize | awk '{print $0/1048576" MB"}')
    echo "Cache per Core: L1-Instruction: $L1I | L1-Data: $L1D | L2: $L2"

    ARCH=$(uname -m)
    echo "Architecture: $ARCH"

    EXTENSIONS=$(sysctl -a | command grep hw.optional | command grep -E "AdvSIMD|armv8|neon|fp16" | awk -F. '{print $3}' | awk -F: '{print $1}' | paste -sd "," - | sed 's/,/, /g')
    echo "Extensions: $EXTENSIONS"

    echo ""
    echo "--- GPU Details ---"
    system_profiler SPDisplaysDataType | command grep -E "Chipset Model|Total Number of Cores|Metal Support"
    echo "--------------------------------"
}

