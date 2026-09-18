# fang (redfang)

Kali Linux ships **redfang** as the command `fang`.

**fang** is a small proof-of-concept Bluetooth hunter. It finds devices that are *not* in discoverable mode by brute-forcing the last six bytes of a Bluetooth address (BD_ADDR) and calling `hci_read_remote_name()`.

- Package name: `redfang`
- Binary name: `fang`
- Version in Kali: 2.5
- Original authors: Ollie Whitehouse (@stake), Simon Halsall (threads), Stephen Kapp (device info)
- Year: 2003

This repository documents how to install and use the tool on Kali. It is **not** a rewrite of the original C source.

## Legal / ethics

Only scan devices and networks you own or have explicit written permission to test. Unauthorized Bluetooth scanning or pairing can be illegal.

## Install on Kali Linux

```bash
sudo apt update
sudo apt install redfang
```

Dependencies: `libbluetooth3`, `libc6`.

You need a working Bluetooth adapter (`hci0` or similar):

```bash
hciconfig
sudo hciconfig hci0 up
```

## Usage

```text
fang [options]

  -r    range      e.g. 00803789EE76-00803789EEff
  -o    filename   write scan results to a text logfile
  -t    timeout    connect timeout (default 10000)
  -n    num        number of Bluetooth dongles / threads
  -d               debug
  -s               also perform standard Bluetooth discovery
  -l               list device manufacturer codes
  -h               help
```

Addresses are 12 hex characters (no colons). You can also use `manf+nnnnnn` after listing manufacturers with `-l`.

HCI devices are assumed to be `hci0` … `hci(n-1)` when `-n` is set.

### Example (from Kali docs)

```bash
fang -r 00803789EE76-00803789EEff -s
```

Typical output starts like:

```text
redfang - the bluetooth hunter ver 2.5
(c)2003 @stake Inc
Scanning 138 address(es)
Address range 00:80:37:89:ee:76 -> 00:80:37:89:ee:ff
Performing Bluetooth Discovery...
```

### Practical notes

- Full 24-bit suffix space is large. Narrow the range using a known vendor OUI (`fang -l`) when you can.
- Increase `-t` if you miss devices; the default is faster but less reliable.
- Multiple USB dongles (`-n`) were the original way to speed up scans.
- Classic Bluetooth (BR/EDR) only. This is not a BLE advert scanner.

## Build from source (optional)

Upstream tarball is `redfang 2.5`. A public copy of the C sources lives at [deltj/redfang](https://github.com/deltj/redfang).

On Debian/Kali-style systems:

```bash
sudo apt install build-essential libbluetooth-dev
git clone https://github.com/deltj/redfang.git
cd redfang
make
# binary is named fang
```

You may need `#include <linux/limits.h>` in `fang.c` on modern kernels (Arch/Kali packaging already patches this).

## Official references

- [Kali tool page: redfang](https://www.kali.org/tools/redfang/)
- Install: `sudo apt install redfang`
- Historical announcement: RedFang 2.5, @stake / QinetiQ FORWARD project (2003)

## Why this repo exists

`fang` is easy to confuse with other projects of the same name (hash crackers, recon frameworks, DDoS kits, camera firmware hacks). This repo is specifically about **Kali’s Bluetooth hunter** (`redfang` / `fang`).
