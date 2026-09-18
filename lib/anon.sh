#!/usr/bin/env bash
# operator adapter hygiene — hide the local radio, do not spoof victims

anon_cmd() {
  local sub="${1:-status}"
  shift || true
  case "$sub" in
    status)  anon_status ;;
    harden)  anon_harden ;;
    restore) anon_restore ;;
    *) die "usage: fang anon [status|harden|restore]" ;;
  esac
}

anon_status() {
  info "adapter $FANG_HCI"
  if command -v hciconfig >/dev/null 2>&1; then
    hciconfig "$FANG_HCI" || hciconfig -a || true
  else
    warn "hciconfig missing"
  fi
}

# noscan: not discoverable, not connectable. radio stays up for outbound tests.
anon_harden() {
  common_require_cmd hciconfig
  common_sudo hciconfig "$FANG_HCI" up
  common_sudo hciconfig "$FANG_HCI" noscan
  common_sudo hciconfig "$FANG_HCI" noauth 2>/dev/null || true
  ok "$FANG_HCI noscan (not discoverable / not connectable)"
  info "outbound inquiry and name requests still work while the radio is up"
  anon_status
}

# pscan+iscan = visible again
anon_restore() {
  common_require_cmd hciconfig
  common_sudo hciconfig "$FANG_HCI" up
  common_sudo hciconfig "$FANG_HCI" piscan
  ok "$FANG_HCI piscan (inquiry + page scan restored)"
  anon_status
}
