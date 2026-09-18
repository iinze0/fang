# fang

**fang** is a modular CLI for authorized Bluetooth recon on Kali / Debian-style boxes.

By [iinze0](https://github.com/iinze0).

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

## Install

```bash
git clone https://github.com/iinze0/fang.git
cd fang
chmod +x fang.sh
./fang.sh help
```

Needs BlueZ tools (`hcitool`, `hciconfig`, optionally `l2ping` / `sdptool`).

```bash
sudo apt install bluez
sudo hciconfig hci0 up
```

## Commands

```bash
./fang.sh                 # menu
./fang.sh scan inquiry
./fang.sh scan range START-END
./fang.sh scan name ADDR
./fang.sh targets add ADDR [note]
./fang.sh assess name     # name | ping | sdp | all
./fang.sh anon harden
```

`assess` / `attack` only runs against addresses in `data/targets.txt` and asks for `YES` unless `FANG_AUTHORIZED=1`.

## License

MIT — see `LICENSE`.

Use only on systems and radios you own or have written permission to test.
