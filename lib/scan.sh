#!/usr/bin/env bash
# discovery wrappers

scan_cmd() {
  local sub="${1:-inquiry}"
  shift || true
  case "$sub" in
    inquiry|inq) scan_inquiry "$@" ;;
    range|redfang|fang) scan_range "$@" ;;
    name) scan_name "${1:-}" ;;
    lescan) scan_lescan "$@" ;;
    *) die "usage: fang scan [inquiry|range RANGE|name ADDR|lescan]" ;;
  esac
}

scan_inquiry() {
  info "inquiry on $FANG_HCI (discoverable devices only)"
  common_require_cmd hcitool
  common_sudo hciconfig "$FANG_HCI" up >/dev/null 2>&1 || true
  local log
  log="$(common_logfile inquiry)"
  if hcitool -i "$FANG_HCI" scan --flush 2>&1 | tee "$log"; then
    ok "log: $log"
  else
    warn "hcitool scan failed — is $FANG_HCI up?"
  fi
}

# RANGE like 00803789EE76-00803789EEff (redfang)
scan_range() {
  local range="${1:-}"
  [[ -n "$range" ]] || die "usage: fang scan range START-END"
  local bin=""
  if command -v fang >/dev/null 2>&1 && [[ "$(command -v fang)" != "$FANG_ROOT/fang.sh" ]]; then
    bin="$(command -v fang)"
  elif command -v redfang >/dev/null 2>&1; then
    bin="$(command -v redfang)"
  fi
  [[ -n "$bin" ]] || die "redfang not installed (sudo apt install redfang)"

  local extra=()
  [[ "${2:-}" == "-s" || "${SCAN_DISCOVERY:-0}" == "1" ]] && extra+=(-s)
  local timeout="${SCAN_TIMEOUT:-}"
  [[ -n "$timeout" ]] && extra+=(-t "$timeout")

  info "redfang range $range on $FANG_HCI"
  common_sudo hciconfig "$FANG_HCI" up >/dev/null 2>&1 || true
  local log
  log="$(common_logfile range)"
  "$bin" -r "$range" "${extra[@]}" 2>&1 | tee "$log"
  ok "log: $log"
}

scan_name() {
  local raw="${1:-}"
  [[ -n "$raw" ]] || die "usage: fang scan name ADDR"
  local addr
  addr="$(common_norm_addr "$raw")" || die "bad address: $raw"
  common_require_cmd hcitool
  info "remote name $addr"
  hcitool -i "$FANG_HCI" name "$addr"
}

scan_lescan() {
  info "LE scan on $FANG_HCI (Ctrl-C to stop)"
  if command -v bluetoothctl >/dev/null 2>&1; then
    common_sudo bluetoothctl --timeout "${1:-10}" scan on || true
  elif command -v hcitool >/dev/null 2>&1; then
    common_sudo timeout "${1:-10}" hcitool -i "$FANG_HCI" lescan || true
  else
    die "need bluetoothctl or hcitool"
  fi
}
