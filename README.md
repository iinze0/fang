# fang

Kali-oriented Bluetooth recon CLI. Layout:

```
fang/
├── fang.sh
├── lib/
│   ├── common.sh
│   ├── targets.sh
│   ├── ui.sh
│   ├── scan.sh
│   ├── attack.sh
│   └── anon.sh
└── data/
```

Wraps BlueZ (`hcitool`, `l2ping`, `sdptool`, `hciconfig`) and Kali’s **redfang** binary (`fang`) for authorized lab work.

## Install

```bash
sudo apt update
sudo apt install redfang bluez
git clone https://github.com/iinze0/fang.git
cd fang
chmod +x fang.sh
```

Adapter:

```bash
sudo hciconfig hci0 up
./fang.sh hci
```

## Usage

```bash
./fang.sh                 # menu
./fang.sh help

./fang.sh scan inquiry
./fang.sh scan range 00803789EE76-00803789EEff
./fang.sh scan name 00:11:22:33:44:55
./fang.sh scan lescan 10

./fang.sh targets add 00:11:22:33:44:55 lab-speaker
./fang.sh targets list

./fang.sh assess name     # also: ping | sdp | all
./fang.sh anon harden     # local radio: noscan
./fang.sh anon restore
```

`assess` is an alias for `attack`. It only runs name lookup, L2CAP echo, and public SDP browse against **saved** targets, and asks you to type `YES` unless `FANG_AUTHORIZED=1`.

## Env

| Variable | Default |
|---|---|
| `FANG_HCI` | `hci0` |
| `FANG_DATA` | `./data` |
| `FANG_TARGETS` | `./data/targets.txt` |
| `FANG_AUTHORIZED` | unset (prompt) |
| `SCAN_TIMEOUT` | redfang default |
| `SCAN_DISCOVERY` | `0` (`1` adds redfang `-s`) |

## Scope

- Inquiry and LE scan for devices that are advertising
- redfang range hunt for classic addresses you already have a prefix for
- Operator hygiene: hide *your* adapter (`noscan`)

Not in scope: exploit payloads, pairing attacks, spoofing other devices, or unattended wide scans of third parties.

Use only on equipment you own or have written permission to test.

## Upstream

Kali package: `redfang` — https://www.kali.org/tools/redfang/
