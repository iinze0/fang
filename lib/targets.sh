#!/usr/bin/env bash
# data/targets.txt  —  ADDR<TAB>NOTE

targets_cmd() {
  local sub="${1:-list}"
  shift || true
  case "$sub" in
    list|ls)     targets_list ;;
    add)         targets_add "${1:-}" "${*:2}" ;;
    remove|rm)   targets_remove "${1:-}" ;;
    import)      targets_import "${1:-}" ;;
    clear)       targets_clear ;;
    *)           die "usage: fang targets [list|add ADDR [note]|remove ADDR|import FILE|clear]" ;;
  esac
}

targets_list() {
  common_init
  if [[ ! -s "$FANG_TARGETS" ]]; then
    info "no targets in $FANG_TARGETS"
    return 0
  fi
  ui_hr
  printf '  %-17s  %s\n' "ADDR" "NOTE"
  ui_hr
  while IFS=$'\t' read -r addr note; do
    [[ -z "${addr:-}" || "$addr" == \#* ]] && continue
    printf '  %-17s  %s\n' "$addr" "${note:-}"
  done < "$FANG_TARGETS"
}

targets_add() {
  local raw="${1:-}" note="${2:-}"
  [[ -n "$raw" ]] || die "usage: fang targets add ADDR [note]"
  local addr
  addr="$(common_norm_addr "$raw")" || die "bad address: $raw"
  common_init
  if grep -qi "^${addr}" "$FANG_TARGETS"; then
    warn "already present: $addr"
    return 0
  fi
  printf '%s\t%s\n' "$addr" "$note" >> "$FANG_TARGETS"
  ok "added $addr"
}

targets_remove() {
  local raw="${1:-}"
  [[ -n "$raw" ]] || die "usage: fang targets remove ADDR"
  local addr
  addr="$(common_norm_addr "$raw")" || die "bad address: $raw"
  common_init
  local tmp
  tmp="$(mktemp)"
  grep -vi "^${addr}" "$FANG_TARGETS" > "$tmp" || true
  mv "$tmp" "$FANG_TARGETS"
  ok "removed $addr (if it existed)"
}

targets_import() {
  local file="${1:-}"
  [[ -n "$file" && -f "$file" ]] || die "usage: fang targets import FILE"
  local line addr note
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | tr -s '[:space:]' ' ')"
    [[ -z "$line" ]] && continue
    addr="${line%% *}"
    note="${line#*"$addr"}"
    note="${note## }"
    targets_add "$addr" "$note" || warn "skipped $line"
  done < "$file"
}

targets_clear() {
  common_init
  : > "$FANG_TARGETS"
  ok "targets cleared"
}

targets_each() {
  common_init
  local addr note
  while IFS=$'\t' read -r addr note; do
    [[ -z "${addr:-}" || "$addr" == \#* ]] && continue
    printf '%s\n' "$addr"
  done < "$FANG_TARGETS"
}
