#!/bin/bash
# FANG — target management

TARGETS=()
WHITELIST=()
SCANNED=()
FAVORITES=()
TARGET=""
declare -A NICKS HOSTNAMES

load_targets() {
    [[ -f $WHITE ]] && mapfile -t WHITELIST < <(grep -v '^$' "$WHITE" 2>/dev/null)
    [[ -f $SAVE  ]] && mapfile -t TARGETS   < <(grep -v '^$' "$SAVE"  2>/dev/null)
    [[ -f $HIST  ]] && mapfile -t SCANNED   < <(grep -v '^$' "$HIST"  2>/dev/null)
    [[ -f $FAV   ]] && mapfile -t FAVORITES < <(grep -v '^$' "$FAV"   2>/dev/null)

    NICKS=(); HOSTNAMES=()
    [[ -f $NICKF ]] && while IFS='=' read -r ip n; do
        ip=${ip// /}; n=${n// /}
        valid_ip "$ip" && [[ -n $n ]] && NICKS[$ip]=$n
    done < "$NICKF"
    [[ -f $HOSTF ]] && while IFS='=' read -r ip n; do
        ip=${ip// /}; n=${n// /}
        valid_ip "$ip" && [[ -n $n ]] && HOSTNAMES[$ip]=$n
    done < "$HOSTF"
}

save_targets() {
    printf "%s\n" "${SCANNED[@]}"   > "$HIST"  2>/dev/null
    printf "%s\n" "${TARGETS[@]}"   > "$SAVE"  2>/dev/null
    printf "%s\n" "${WHITELIST[@]}" > "$WHITE" 2>/dev/null
    printf "%s\n" "${FAVORITES[@]}" > "$FAV"   2>/dev/null
    : > "$NICKF"
    for ip in "${!NICKS[@]}"; do echo "$ip=${NICKS[$ip]}" >> "$NICKF"; done
    : > "$HOSTF"
    for ip in "${!HOSTNAMES[@]}"; do echo "$ip=${HOSTNAMES[$ip]}" >> "$HOSTF"; done
}

is_protected() {
    local ip=$1
    [[ -z $ip ]] && return 1
    [[ $ip == "$MY_IP" || $ip == "$GATEWAY" ]] && return 0
    for w in "${WHITELIST[@]}"; do [[ $ip == "$w" ]] && return 0; done
    return 1
}

get_targets() {
    if ((${#TARGETS[@]} > 0)); then
        local IFS=','; echo "${TARGETS[*]}"
    else
        echo "$TARGET"
    fi
}

need_target() {
    local t; t=$(get_targets)
    [[ -z $t ]] && { err "No target selected"; sleep 1.2; return 1; }
    return 0
}

show_ip() {
    local ip=$1
    printf "  ${C}%-15s${N}" "$ip"
    [[ -n ${HOSTNAMES[$ip]} ]] && printf " ${G}%-18s${N}" "${HOSTNAMES[$ip]}"
    [[ -n ${NICKS[$ip]} ]] && printf " ${Y}(%s)${N}" "${NICKS[$ip]}"
    is_protected "$ip" && printf " ${R}[protected]${N}"
    echo
}

protect_self() {
    [[ $TARGET == "$MY_IP" ]] && TARGET=""
    local new=()
    for ip in "${TARGETS[@]}"; do [[ $ip != "$MY_IP" ]] && new+=("$ip"); done
    TARGETS=("${new[@]}")
    [[ -n $MY_IP ]] && ! is_protected "$MY_IP" && WHITELIST+=("$MY_IP")
    save_targets
    ok "You are protected"
}
