#!/usr/bin/env bash
# terminal chrome

ui_banner() {
  cat <<'EOF'
  ____
 |  __| __ _ _ __   __ _
 | |_  / _` | '_ \ / _` |
 |  _|| (_| | | | | (_| |
 |_|   \__,_|_| |_|\__, |
                    |___/  bluetooth recon  ·  kali
EOF
}

ui_hr() { printf '%s\n' "----------------------------------------"; }

ui_pause() {
  echo
  read -r -p "  [enter] " _
}

ui_kv() {
  printf '  %-14s %s\n' "$1" "$2"
}
