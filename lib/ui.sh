#!/bin/bash
# FANG — UI

draw_banner() {
    clear
    echo -e "${R}${B}"
    echo "            __"
    echo "           /  \\"
    echo "          /    \\"
    echo "         /  __  \\"
    echo "        /  /  \\  \\"
    echo "       /  /    \\  \\"
    echo "      /  /  /\\  \\  \\"
    echo "     /__/  /  \\  \\__\\"
    echo "        \\  \\  /  /"
    echo "         \\  \\/  /"
    echo "          \\    /"
    echo "           \\  /"
    echo "            \/"
    echo -e "${N}"
    echo -e "  ${B}${R}███████╗ █████╗ ███╗   ██╗ ██████╗ ${N}"
    echo -e "  ${B}${R}██╔════╝██╔══██╗████╗  ██║██╔════╝ ${N}"
    echo -e "  ${B}${R}█████╗  ███████║██╔██╗ ██║██║  ███╗${N}"
    echo -e "  ${B}${R}██╔══╝  ██╔══██║██║╚██╗██║██║   ██║${N}"
    echo -e "  ${B}${R}██║     ██║  ██║██║ ╚████║╚██████╔╝${N}"
    echo -e "  ${B}${R}╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ${N}"
    echo -e "  ${D}────────────────────────────────────────${N}"
    echo -e "  ${B}     Modular Network Control  v42${N}"
    echo -e "  ${D}────────────────────────────────────────${N}\n"
}

draw_status() {
    local rt=""
    if [[ -n ${ATTACK_START:-} && ${ATTACK:-None} != "None" ]]; then
        local d=$(( $(date +%s) - ATTACK_START ))
        rt="  $((d/60))m $((d%60))s"
    fi
    echo -e "  ${D}┌────────────────────────────────────────────────┐${N}"
    printf "  ${D}│${N}  %-12s ${G}%-32s${N} ${D}│${N}\n" "Interface" "${IFACE:-—}"
    printf "  ${D}│${N}  %-12s ${G}%-32s${N} ${D}│${N}\n" "My IP"     "${MY_IP:-—}"
    printf "  ${D}│${N}  %-12s ${G}%-32s${N} ${D}│${N}\n" "Gateway"   "${GATEWAY:-—}"
    printf "  ${D}│${N}  %-12s ${G}%-32s${N} ${D}│${N}\n" "Devices"   "${#SCANNED[@]}"
    printf "  ${D}│${N}  %-12s ${P}%-32s${N} ${D}│${N}\n" "Attack"    "${ATTACK:-None}${rt}"
    if [[ -n ${TARGET:-} ]]; then
        local i=$TARGET
        [[ -n ${NICKS[$TARGET]:-} ]] && i+="  (${NICKS[$TARGET]})"
        printf "  ${D}│${N}  %-12s ${C}%-32s${N} ${D}│${N}\n" "Target" "$i"
    fi
    ((${#TARGETS[@]} > 0)) && printf "  ${D}│${N}  %-12s ${C}%-32s${N} ${D}│${N}\n" "Multi" "${TARGETS[*]}"
    echo -e "  ${D}└────────────────────────────────────────────────┘${N}\n"
}

draw_menu() {
    echo -e "  ${Y}${B}DISCOVERY${N}"
    echo "     1) Scan (Quick/Deep)     2) Show Devices"
    echo "     3) Nickname              4) Quick Select"
    echo "     5) Set Target            6) Multi-Target"
    echo "     7) Protect Me            8) Device Type"
    echo "     9) Attack All"
    echo ""
    echo -e "  ${Y}${B}ATTACK${N}"
    echo "    10) Smart Lag            11) Full Kill"
    echo "    12) Timed Kill           13) Restore / Stop Session"
    echo "    14) Re-apply             15) Online Check"
    echo "    16) Session Status"
    echo ""
    echo -e "  ${Y}${B}MONITOR${N}"
    echo "    17) Live Traffic         18) Rules / Latency"
    echo ""
    echo -e "  ${Y}${B}ANONYMITY${N}"
    echo "    19) Ghost Mode           20) Anon Menu"
    echo ""
    echo -e "  ${Y}${B}SYSTEM${N}"
    echo "    21) Custom Files         22) Persistence"
    echo "    23) Save / Log           99) Install Deps"
    echo "     0) Exit"
    echo ""
}
