# FANG

Modular network toolkit for Kali. Interactive menu: pick an interface, discover hosts, set targets, run sessions, watch traffic, toggle anonymity helpers.

By [iinze0](https://github.com/iinze0).

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

Repo is **private**. Clone with HTTPS + a [personal access token](https://github.com/settings/tokens), or SSH.

```bash
git clone git@github.com:iinze0/fang.git
cd fang
chmod +x fang.sh update.sh lib/*.sh
sudo ./fang.sh
```

Root is required. Option `99` in the menu installs packages the script expects.

## Update

From the clone directory:

```bash
chmod +x update.sh
./update.sh
```

Same thing by hand:

```bash
cd fang
git pull origin main
chmod +x fang.sh update.sh lib/*.sh
```

If you copied files without `git clone`, there is nothing to pull — clone the repo once, then use `update.sh` after that.

Docs page: [docs/index.html](docs/index.html) (same install + update commands).

## Menu (high level)

- Discovery — quick / deep scan, list hosts, nicknames, set single or multi target, protect this host, vendor filter
- Sessions — lag / kill / timed session, stop, reapply, ping check, session status
- Monitor — live traffic, rule / latency view
- Anonymity — ghost mode and anon menu
- System — custom dir, persistence toggle, save / log, deps install, quit

## License

MIT — see `LICENSE`.

Only use on networks you own or have written permission to test.
