#!/bin/bash
# FANG anon — Ghost Mode, kill-switch, identity restore

GHOST_ON=0

save_identity() {
    local mac host
    mac=$(cat /sys/class/net/"$IFACE"/address 2>/dev/null)
    host=$(hostname 2>/dev/null)
    cat > "$IDENTITY_FILE" << EOF
ORIGINAL_MAC=$mac
ORIGINAL_HOST=$host
ORIGINAL_IFACE=$IFACE
EOF
    [[ -f /etc/resolv.conf ]] && cp /etc/resolv.conf "${DATA_DIR}/resolv.conf.bak" 2>/dev/null
    ok "Identity saved"
}

restore_identity() {
    [[ -f $IDENTITY_FILE ]] || { err "No saved identity"; return 1; }
    # shellcheck source=/dev/null
    source "$IDENTITY_FILE"

    info "Restoring identity..."
    if [[ -n ${ORIGINAL_MAC:-} && -n ${ORIGINAL_IFACE:-} ]]; then
        ip link set "$ORIGINAL_IFACE" down 2>/dev/null
        ip link set "$ORIGINAL_IFACE" address "$ORIGINAL_MAC" 2>/dev/null
        ip link set "$ORIGINAL_IFACE" up 2>/dev/null
    fi
    [[ -n ${ORIGINAL_HOST:-} ]] && {
        hostnamectl set-hostname "$ORIGINAL_HOST" 2>/dev/null || hostname "$ORIGINAL_HOST"
        echo "$ORIGINAL_HOST" > /etc/hostname
    }
    [[ -f ${DATA_DIR}/resolv.conf.bak ]] && cp "${DATA_DIR}/resolv.conf.bak" /etc/resolv.conf 2>/dev/null

    disable_killswitch
    GHOST_ON=0
    ok "Identity restored"
}

spoof_mac() {
    local iface=${1:-$IFACE}
    ip link set "$iface" down 2>/dev/null
    if command -v macchanger &>/dev/null; then
        macchanger -r "$iface" 2>/dev/null
    else
        local new
        new=$(printf '02:%02x:%02x:%02x:%02x:%02x' \
            $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
        ip link set "$iface" address "$new"
        ok "MAC → $new"
    fi
    ip link set "$iface" up 2>/dev/null
}

random_hostname() {
    local new="node-$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)"
    hostnamectl set-hostname "$new" 2>/dev/null || hostname "$new"
    echo "$new" > /etc/hostname
    ok "Hostname → $new"
}

start_tor() {
    if command -v anonsurf &>/dev/null; then
        anonsurf start && ok "Anonsurf ON"
    elif systemctl start tor 2>/dev/null; then
        ok "Tor service ON"
    else
        err "Tor/Anonsurf not available"
        return 1
    fi
}

stop_tor() {
    command -v anonsurf &>/dev/null && anonsurf stop 2>/dev/null
    systemctl stop tor 2>/dev/null
    ok "Tor stack OFF"
}

# Kill-switch: block non-Tor outbound (best-effort)
enable_killswitch() {
    info "Enabling kill-switch (block clearnet if Tor dies)"
    # Allow loopback + established
    iptables -I OUTPUT -o lo -m comment --comment "$COMMENT_TAG-KS" -j ACCEPT 2>/dev/null
    iptables -I OUTPUT -m state --state ESTABLISHED,RELATED -m comment --comment "$COMMENT_TAG-KS" -j ACCEPT 2>/dev/null
    # Allow Tor user if present (Debian/Kali often 'debian-tor')
    if id debian-tor &>/dev/null; then
        iptables -I OUTPUT -m owner --uid-owner debian-tor -m comment --comment "$COMMENT_TAG-KS" -j ACCEPT 2>/dev/null
    fi
    # Allow DNS to localhost
    iptables -I OUTPUT -p udp --dport 53 -d 127.0.0.1 -m comment --comment "$COMMENT_TAG-KS" -j ACCEPT 2>/dev/null
    # Drop the rest of outbound (aggressive)
    iptables -A OUTPUT -m comment --comment "$COMMENT_TAG-KS" -j DROP 2>/dev/null
    ok "Kill-switch rules applied (tagged $COMMENT_TAG-KS)"
}

disable_killswitch() {
    local nums n
    while true; do
        nums=$(iptables -L OUTPUT -n --line-numbers 2>/dev/null | grep "$COMMENT_TAG-KS" | awk '{print $1}' | sort -rn)
        [[ -z $nums ]] && break
        for n in $nums; do iptables -D OUTPUT "$n" 2>/dev/null; done
    done
}

test_anon() {
    info "Anonymity test"
    echo -ne "  Direct IP : "
    curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "fail"
    echo -ne "  Tor IP    : "
    proxychains4 curl -s --max-time 12 ifconfig.me 2>/dev/null || \
    torsocks curl -s --max-time 12 ifconfig.me 2>/dev/null || echo "fail"
    echo
    pause
}

ghost_mode() {
    info "Ghost Mode — hardening YOUR identity"
    save_identity
    spoof_mac "$IFACE"
    random_hostname
    start_tor || true
    if [[ -f /etc/resolv.conf ]]; then
        echo -e "nameserver 127.0.0.1\nnameserver 1.1.1.1" > /etc/resolv.conf
    fi
    if ask "Enable kill-switch (blocks non-Tor outbound)?"; then
        enable_killswitch
    fi
    GHOST_ON=1
    ok "Ghost Mode ON"
    echo -e "  ${D}Note: Local ARP attacks on this LAN are still visible to the network.${N}"
    test_anon
}

ghost_off() {
    info "Ghost Mode OFF"
    stop_tor
    disable_killswitch
    restore_identity
    pause
}

anon_menu() {
    echo -e "\n  ${Y}Anonymity${N}"
    echo "  1) Ghost Mode ON"
    echo "  2) Ghost Mode OFF"
    echo "  3) Spoof MAC"
    echo "  4) Random hostname"
    echo "  5) Start Tor"
    echo "  6) Stop Tor"
    echo "  7) Test anonymity"
    echo "  8) Kill-switch ON"
    echo "  9) Kill-switch OFF"
    read -p "  Choice: " a
    case $a in
        1) ghost_mode ;;
        2) ghost_off ;;
        3) spoof_mac ;;
        4) random_hostname ;;
        5) start_tor ;;
        6) stop_tor ;;
        7) test_anon ;;
        8) enable_killswitch ;;
        9) disable_killswitch; ok "Kill-switch off" ;;
    esac
}
