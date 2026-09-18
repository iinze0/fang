#!/bin/bash
# FANG — scanning

do_scan() {
    local mode=${1:-quick}
    local wait=8
    [[ $mode == deep ]] && wait=15

    info "Scan mode: ${mode^^}"
    stop_bettercap 2>/dev/null || true
    local NEW=0

    info "bettercap..."
    local RES
    RES=$(bettercap -iface "$IFACE" -eval \
        "set net.probe.throttle 5; set net.probe.mdns true; set net.probe.upnp true; \
         net.probe on; sleep $wait; net.show; quit" 2>/dev/null)

    while IFS= read -r line; do
        local ip host
        ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        valid_ip "$ip" || continue
        [[ $ip == *.0 || $ip == *.255 ]] && continue
        host=$(echo "$line" | awk '{print $NF}' | sed 's/│//g' | xargs)
        [[ $host == *"─"* || $host == "$ip" || -z $host ]] && host=""
        if [[ ! " ${SCANNED[*]} " =~ " $ip " ]]; then
            SCANNED+=("$ip"); ((NEW++))
        fi
        [[ -n $host ]] && HOSTNAMES[$ip]="$host"
    done <<< "$RES"

    if command -v arp-scan &>/dev/null; then
        info "arp-scan..."
        while read -r ip _ vendor; do
            valid_ip "$ip" || continue
            if [[ ! " ${SCANNED[*]} " =~ " $ip " ]]; then
                SCANNED+=("$ip"); ((NEW++))
            fi
            [[ -z ${HOSTNAMES[$ip]:-} && -n $vendor ]] && HOSTNAMES[$ip]="$vendor"
        done < <(arp-scan -I "$IFACE" --localnet 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}.*')
    fi

    if command -v nmap &>/dev/null; then
        info "nmap..."
        local SUBNET
        SUBNET=$(ip -4 addr show "$IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -1)
        if [[ -n $SUBNET ]]; then
            while read -r ip; do
                valid_ip "$ip" || continue
                if [[ ! " ${SCANNED[*]} " =~ " $ip " ]]; then
                    SCANNED+=("$ip"); ((NEW++))
                fi
            done < <(nmap -sn "$SUBNET" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
        fi
    fi

    save_targets
    ok "Scan done — new: $NEW | total: ${#SCANNED[@]}"
    echo -e "\n  ${Y}Results:${N}"
    for ip in "${SCANNED[@]}"; do show_ip "$ip"; done
    pause
}
