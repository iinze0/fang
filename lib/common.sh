#!/usr/bin/env bash
# shared helpers

die()  { printf '[-] %s\n' "$*" >&2; exit 1; }
ok()   { printf '[+] %s\n' "$*"; }
info() { printf '[*] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }

common_init() {
  mkdir -p "$FANG_DATA" "$FANG_LOG_DIR"
  [[ -f "$FANG_TARGETS" ]] || : > "$FANG_TARGETS"
}

common_require_cmd() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || die "missing command: $c"
  done
}

common_sudo() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "need root or sudo for: $*"
  fi
}

# 00:11:22:33:44:55 or 001122334455 -> colon form
common_norm_addr() {
  local raw="${1//[:.-]/}"
  raw="$(printf '%s' "$raw" | tr '[:lower:]' '[:upper:]')"
  [[ "$raw" =~ ^[0-9A-F]{12}$ ]] || return 1
  printf '%s:%s:%s:%s:%s:%s\n' \
    "${raw:0:2}" "${raw:2:2}" "${raw:4:2}" \
    "${raw:6:2}" "${raw:8:2}" "${raw:10:2}"
}

# colon form -> 12 hex no separators (redfang -r style)
common_flat_addr() {
  local n
  n="$(common_norm_addr "$1")" || return 1
  printf '%s\n' "${n//:/}"
}

common_ts() { date +'%Y%m%d-%H%M%S'; }

common_logfile() {
  local name="${1:-fang}"
  printf '%s/%s-%s.log\n' "$FANG_LOG_DIR" "$name" "$(common_ts)"
}

common_confirm_authorized() {
  if [[ "${FANG_AUTHORIZED:-0}" == "1" ]]; then
    return 0
  fi
  warn "Authorized testing only. Type YES to continue."
  read -r -p "  confirm> " ans
  [[ "$ans" == "YES" ]] || die "aborted"
}
