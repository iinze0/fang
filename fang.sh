#!/usr/bin/env bash
# fang — Kali Bluetooth recon CLI (wraps redfang / BlueZ tools)
set -euo pipefail

FANG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FANG_ROOT
export FANG_DATA="${FANG_DATA:-$FANG_ROOT/data}"
export FANG_LOG_DIR="${FANG_LOG_DIR:-$FANG_DATA/logs}"
export FANG_TARGETS="${FANG_TARGETS:-$FANG_DATA/targets.txt}"
export FANG_HCI="${FANG_HCI:-hci0}"

# shellcheck source=lib/common.sh
source "$FANG_ROOT/lib/common.sh"
source "$FANG_ROOT/lib/ui.sh"
source "$FANG_ROOT/lib/targets.sh"
source "$FANG_ROOT/lib/scan.sh"
source "$FANG_ROOT/lib/attack.sh"
source "$FANG_ROOT/lib/anon.sh"

fang_usage() {
  cat <<EOF
$(ui_banner)

Usage: $(basename "$0") <command> [args]

Commands:
  scan      Inquiry / range hunt / name lookup
  targets   Add, list, remove, import BD_ADDRs
  assess    Authorized checks against saved targets (alias: attack)
  anon      Adapter hygiene (noscan, down, restore)
  hci       Show / select HCI adapter
  menu      Interactive menu
  help      This text

Examples:
  $(basename "$0") hci
  $(basename "$0") scan inquiry
  $(basename "$0") scan range 00803789EE76-00803789EEff
  $(basename "$0") targets add 00:11:22:33:44:55 lab-speaker
  $(basename "$0") assess name
  $(basename "$0") anon harden

Env:
  FANG_HCI       adapter (default: hci0)
  FANG_DATA      data directory
  FANG_TARGETS   targets file
  FANG_AUTHORIZED=1   skip assess confirmation prompt

Only use against devices you own or have written permission to test.
EOF
}

fang_hci_cmd() {
  local sub="${1:-show}"
  case "$sub" in
    show|status)
      common_require_cmd hciconfig
      hciconfig -a || true
      ;;
    set)
      local dev="${2:-}"
      [[ -n "$dev" ]] || die "usage: fang hci set hciN"
      export FANG_HCI="$dev"
      ok "FANG_HCI=$FANG_HCI"
      hciconfig "$FANG_HCI" 2>/dev/null || warn "adapter not visible yet"
      ;;
    up)
      common_sudo hciconfig "$FANG_HCI" up
      ok "$FANG_HCI up"
      ;;
    down)
      common_sudo hciconfig "$FANG_HCI" down
      ok "$FANG_HCI down"
      ;;
    *)
      die "usage: fang hci [show|set hciN|up|down]"
      ;;
  esac
}

fang_menu() {
  while true; do
    ui_banner
    echo "  1) HCI status"
    echo "  2) Inquiry scan (discoverable devices)"
    echo "  3) Range hunt (redfang / fang)"
    echo "  4) Targets"
    echo "  5) Assess targets"
    echo "  6) Adapter hygiene"
    echo "  0) Quit"
    echo
    read -r -p "  select> " choice
    case "$choice" in
      1) fang_hci_cmd show; ui_pause ;;
      2) scan_inquiry; ui_pause ;;
      3)
        read -r -p "  range (12hex-12hex)> " rng
        scan_range "$rng"
        ui_pause
        ;;
      4)
        echo "  a) list  b) add  c) remove"
        read -r -p "  targets> " t
        case "$t" in
          a) targets_list ;;
          b)
            read -r -p "  addr> " a
            read -r -p "  note> " n
            targets_add "$a" "$n"
            ;;
          c)
            read -r -p "  addr> " a
            targets_remove "$a"
            ;;
        esac
        ui_pause
        ;;
      5)
        echo "  a) name  b) ping  c) sdp"
        read -r -p "  assess> " t
        case "$t" in
          a) attack_name ;;
          b) attack_ping ;;
          c) attack_sdp ;;
        esac
        ui_pause
        ;;
      6)
        echo "  a) harden  b) restore  c) status"
        read -r -p "  anon> " t
        case "$t" in
          a) anon_harden ;;
          b) anon_restore ;;
          c) anon_status ;;
        esac
        ui_pause
        ;;
      0|q|Q) exit 0 ;;
      *) warn "unknown choice" ;;
    esac
  done
}

common_init

cmd="${1:-menu}"
shift || true

case "$cmd" in
  scan)
    scan_cmd "$@"
    ;;
  targets)
    targets_cmd "$@"
    ;;
  attack|assess)
    attack_cmd "$@"
    ;;
  anon)
    anon_cmd "$@"
    ;;
  hci)
    fang_hci_cmd "$@"
    ;;
  menu)
    fang_menu
    ;;
  help|-h|--help)
    fang_usage
    ;;
  *)
    fang_usage
    exit 1
    ;;
esac
