# fang

Modular network toolkit for Kali.

[![license](https://img.shields.io/badge/license-MIT-0b7285?style=flat-square)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Kali-2b8a3e?style=flat-square)](#install)

Made by [iinze0](https://github.com/iinze0)

Interactive menu: pick an interface, discover hosts, set targets, run sessions, watch traffic, and toggle anonymity helpers.

```
fang/
├── fang.sh          # main dispatcher
├── update.sh        # pull latest from GitHub
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
chmod +x fang.sh update.sh lib/*.sh
sudo ./fang.sh
```

SSH works if you already use keys:

```bash
git clone git@github.com:iinze0/fang.git
```

Root is required. Menu option `99` installs packages the script expects.

## Update

From the clone directory:

```bash
./update.sh
```

Or:

```bash
git pull origin main
chmod +x fang.sh update.sh lib/*.sh
```

`update.sh` only works on a git clone. A copied folder has nothing to pull.

## Menu

- **Discovery** — scan, list hosts, nicknames, single or multi target, protect this host, vendor filter
- **Sessions** — start, stop, reapply, ping check, session status
- **Monitor** — live traffic, rule / latency view
- **Anonymity** — ghost mode and anon menu
- **System** — custom dir, persistence, save / log, deps install, quit

## Disclaimer

Authorized lab and pentest use only. Run this only on networks you own or have written permission to test.

---

<p align="center">
  <a href="https://github.com/iinze0">iinze0</a> ·
  <a href="LICENSE">MIT</a>
</p>
