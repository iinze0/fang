#!/usr/bin/env bash
# authorized assessment against saved targets
# name lookup, l2cap ping, SDP browse — no exploit payloads

attack_cmd() {
  local sub="${1:-name}"
  shift || true
  case "$sub" in
    name)   attack_name "$@" ;;
    ping)   attack_ping "$@" ;;
    sdp)    attack_sdp "$@" ;;
    all)    attack_name; attack_ping; attack_sdp ;;
    *) die "usage: fang assess [name|ping|sdp|all]" ;;
  esac
}

attack_need_targets() {
  common_init
  if [[ ! -s "$FANG_TARGETS" ]]; then
    die "no targets — fang targets add ADDR"
  fi
}

attack_name() {
  attack_need_targets
  common_confirm_authorized
  common_require_cmd hcitool
  local addr log
  log="$(common_logfile assess-name)"
  info "remote-name on saved targets"
  while IFS= read -r addr; do
    printf '== %s ==\n' "$addr" | tee -a "$log"
    hcitool -i "$FANG_HCI" name "$addr" 2>&1 | tee -a "$log" || warn "$addr name failed"
  done < <(targets_each)
  ok "log: $log"
}

attack_ping() {
  attack_need_targets
  common_confirm_authorized
  if ! command -v l2ping >/dev/null 2>&1; then
    die "l2ping not installed (bluez)"
  fi
  local addr log count="${1:-3}"
  log="$(common_logfile assess-ping)"
  info "l2ping x$count"
  while IFS= read -r addr; do
    printf '== %s ==\n' "$addr" | tee -a "$log"
    common_sudo l2ping -i "$FANG_HCI" -c "$count" "$addr" 2>&1 | tee -a "$log" || warn "$addr ping failed"
  done < <(targets_each)
  ok "log: $log"
}

attack_sdp() {
  attack_need_targets
  common_confirm_authorized
  if ! command -v sdptool >/dev/null 2>&1; then
    die "sdptool not installed (bluez)"
  fi
  local addr log
  log="$(common_logfile assess-sdp)"
  info "SDP browse (public records only)"
  while IFS= read -r addr; do
    printf '== %s ==\n' "$addr" | tee -a "$log"
    sdptool browse "$addr" 2>&1 | tee -a "$log" || warn "$addr sdp failed"
  done < <(targets_each)
  ok "log: $log"
}
