#!/bin/bash
# FANG common — helpers, paths, health

set -o pipefail

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; P='\033[0;35m'; B='\033[1m'
D='\033[2m';   N='\033[0m'

FANG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${FANG_ROOT}/data"
CUSTOM_DIR="${FANG_ROOT}/fang_custom"
LOG_FILE="${DATA_DIR}/fang.log"
SAVE="${DATA_DIR}/targets.txt"
WHITE="${DATA_DIR}/whitelist.txt"
NICKF="${DATA_DIR}/nicks.txt"
HOSTF="${DATA_DIR}/hosts.txt"
HIST="${DATA_DIR}/history.txt"
FAV="${DATA_DIR}/favorites.txt"
SESSION_FILE="${DATA_DIR}/session.env"
IDENTITY_FILE="${DATA_DIR}/identity.env"
PERSIST="/etc/fang_persist.conf"
SERVICE="/etc/systemd/system/fang.service"

COMMENT_TAG="FANG"

ok()   { echo -e "\n  ${G}✔  $*${N}"; }
err()  { echo -e "\n  ${R}✖  $*${N}"; }
info() { echo -e "\n  ${Y}▸  $*${N}"; }
ask()  { read -p "$(echo -e "  ${Y}$* [y/N]: ${N}")" a; [[ $a =~ ^[Yy]$ ]]; }
pause(){ echo; read -p "  Press Enter..."; }
log()  { echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"; }

valid_ip() { [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }

require_root() {
    [[ $EUID -eq 0 ]] || { err "Run as root: sudo ./fang.sh"; exit 1; }
}

init_dirs() {
    mkdir -p "$DATA_DIR" "$CUSTOM_DIR"
    touch "$LOG_FILE"
}

# ── Health check ──────────────────────────────────────────
health_check() {
    local issues=0
    info "Health check"

    if [[ -z ${IFACE:-} ]] || ! ip link show "$IFACE" &>/dev/null; then
        err "Interface invalid or down"; ((issues++))
    else
        ok "Interface $IFACE exists"
    fi

    if [[ $(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null) != 1 ]]; then
        info "Enabling IP forwarding..."
        echo 1 > /proc/sys/net/ipv4/ip_forward
    fi
    [[ $(cat /proc/sys/net/ipv4/ip_forward) == 1 ]] && ok "IP forwarding ON" || { err "IP forwarding failed"; ((issues++)); }

    command -v bettercap &>/dev/null && ok "bettercap" || { err "bettercap missing"; ((issues++)); }
    command -v iptables  &>/dev/null && ok "iptables"  || { err "iptables missing"; ((issues++)); }

    command -v arp-scan &>/dev/null && ok "arp-scan" || info "arp-scan optional"
    command -v nmap     &>/dev/null && ok "nmap"     || info "nmap optional"
    command -v macchanger &>/dev/null && ok "macchanger" || info "macchanger optional"
    command -v tor &>/dev/null || command -v anonsurf &>/dev/null && ok "Tor/Anonsurf" || info "Tor optional"

    ((issues > 0)) && err "$issues critical issue(s)" || ok "Health OK"
    return $issues
}
