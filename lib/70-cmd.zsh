# lib/70-cmd.zsh — custom commands.
#
# The `command grep` calls that used to litter this file are gone: they were
# only there to escape `alias grep='rg'`, which 30-aliases.zsh no longer sets.

_hw_mac() {
    print "--------------------------------"
    print " 💻 APPLE SILICON SUMMARY"
    print "--------------------------------"
    print "Chip: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || print 'Unknown')"
    print "RAM:  $(sysctl -n hw.memsize 2>/dev/null | awk '{print $0/1073741824" GB"}')"

    print "\n--- CPU & Core Topology ---"
    # Ask the kernel what each performance level is called rather than
    # assuming: Apple's naming varies by chip (older Macs report
    # Performance/Efficiency, M5 reports Super/Performance).
    local total_cores level count name summary=""
    total_cores=$(sysctl -n hw.physicalcpu 2>/dev/null || print 0)
    for level in 0 1 2; do
        count=$(sysctl -n "hw.perflevel${level}.physicalcpu" 2>/dev/null) || continue
        [[ -n "$count" ]] || continue
        name=$(sysctl -n "hw.perflevel${level}.name" 2>/dev/null) || name="level $level"
        summary+="${summary:+, }$count ${name:-level $level}"
    done
    print "Cores: $total_cores total${summary:+ ($summary)}"

    local l1i l1d l2
    l1i=$(sysctl -n hw.perflevel0.l1icachesize 2>/dev/null | awk '{print $0/1024" KB"}')
    l1d=$(sysctl -n hw.perflevel0.l1dcachesize 2>/dev/null | awk '{print $0/1024" KB"}')
    l2=$(sysctl -n hw.perflevel0.l2cachesize  2>/dev/null | awk '{print $0/1048576" MB"}')
    print "Cache per core: L1i: $l1i | L1d: $l1d | L2: $l2"
    print "Architecture: $ZSH_ARCH"

    local extensions
    extensions=$(sysctl -a 2>/dev/null | grep hw.optional \
        | grep -E "AdvSIMD|armv8|neon|fp16" \
        | awk -F. '{print $3}' | awk -F: '{print $1}' | paste -sd "," - | sed 's/,/, /g')
    print "Extensions: $extensions"

    print "\n--- GPU Details ---"
    system_profiler SPDisplaysDataType 2>/dev/null \
        | grep -E "Chipset Model|Total Number of Cores|Metal Support"
    print "--------------------------------"
}

_hw_linux() {
    print "--------------------------------"
    print " 🐧 LINUX HARDWARE SUMMARY"
    print "--------------------------------"

    local cpu_model
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^[ \t]*//')
    [[ -z "$cpu_model" ]] && \
        cpu_model=$(grep -m1 "Model" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^[ \t]*//')
    print "CPU:  ${cpu_model:-Unknown}"
    print "OS:   $ZSH_DISTRO $ZSH_DISTRO_VER"

    if (( $+commands[free] )); then
        print "RAM:  $(free -h | awk '/^Mem:/ {print $2}')"
    fi

    print "\n--- CPU & Core Topology ---"
    if (( $+commands[lscpu] )); then
        local sockets cores_per threads_per total
        sockets=$(lscpu    | grep "^Socket(s):"          | awk '{print $2}')
        cores_per=$(lscpu  | grep "^Core(s) per socket:" | awk '{print $4}')
        threads_per=$(lscpu| grep "^Thread(s) per core:" | awk '{print $4}')
        total=$(lscpu      | grep "^CPU(s):"             | awk '{print $2}')
        print "Sockets: $sockets | Cores/socket: $cores_per | Threads/core: $threads_per"
        print "Total logical cores: $total"
    else
        print "Logical cores: $(nproc 2>/dev/null || print unknown)"
    fi
    print "Architecture: $ZSH_ARCH"

    print "\n--- GPU Details ---"
    if (( $+commands[lspci] )); then
        lspci | grep -i vga | cut -d: -f3 | sed 's/^[ \t]*//'
    else
        print "lspci not available (install pciutils)"
    fi
    print "--------------------------------"
}

# Print a hardware summary for whatever machine this is.
hw() {
    if [[ "$ZSH_OS" == macos ]]; then
        _hw_mac
    else
        _hw_linux
    fi
}
