# FANG

Modular network toolkit for Kali. Interactive menu: pick an interface, discover hosts, set targets, run sessions, watch traffic, toggle anonymity helpers.

By [iinze0](https://github.com/iinze0).

```
fang/
├── fang.sh          # FANG v42 — main dispatcher
├── lib/
│   ├── common.sh
│   ├── targets.sh
│   ├── ui.sh
│   ├── scan.sh
│   ├── attack.sh
│   └── anon.sh
└── data/
```

## Run

```bash
git clone https://github.com/iinze0/fang.git
cd fang
chmod +x fang.sh
sudo ./fang.sh
```

Root is required. Option `99` in the menu installs the packages the script expects (`bettercap`, `iptables`, `tshark`, `nmap`, `arp-scan`, `macchanger`, and related tools).

## Menu (high level)

- Discovery — quick / deep scan, list hosts, nicknames, set single or multi target, protect this host, vendor filter
- Sessions — lag / kill / timed session, stop, reapply, ping check, session status
- Monitor — live traffic, rule / latency view
- Anonymity — ghost mode and anon menu
- System — custom dir, persistence toggle, save / log, deps install, quit

## License

MIT — see `LICENSE`.

Only use on networks you own or have written permission to test.
