# fang

Modular network toolkit for Kali.

Made by [iinze0](https://github.com/iinze0) · [MIT](LICENSE)

Interactive menu: pick an interface, discover hosts, set targets, run sessions, watch traffic, toggle anonymity helpers.

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
git clone git@github.com:iinze0/fang.git
cd fang
chmod +x fang.sh update.sh lib/*.sh
sudo ./fang.sh
```

HTTPS works too if you prefer a token over SSH:

```bash
git clone https://github.com/iinze0/fang.git
```

Root is required. Option `99` in the menu installs packages the script expects.

## Update

From the clone directory:

```bash
chmod +x update.sh
./update.sh
```

Or by hand:

```bash
cd fang
git pull origin main
chmod +x fang.sh update.sh lib/*.sh
```

If you copied files without `git clone`, there is nothing to pull — clone the repo once, then use `update.sh`.

Docs: [docs/index.html](docs/index.html)

## Menu

- **Discovery** — scan, list hosts, nicknames, single or multi target, protect this host, vendor filter
- **Sessions** — start, stop, reapply, ping check, session status
- **Monitor** — live traffic, rule / latency view
- **Anonymity** — ghost mode and anon menu
- **System** — custom dir, persistence, save / log, deps install, quit

## Disclaimer

Only use on networks you own or have written permission to test.

<p align="center">
  <a href="https://github.com/iinze0">iinze0</a> ·
  <a href="https://github.com/iinze0/fang">fang</a>
</p>
