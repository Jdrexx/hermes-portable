# Portable Hermes

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20WSL2-blue)
![Shell](https://img.shields.io/badge/shell-bash-121011?logo=gnu-bash&logoColor=white)

Run a fully self-contained [Hermes Agent](https://github.com/NousResearch/hermes-agent) from a USB stick. Your profile, skills, memories, sessions, and configuration — ready to plug into any Linux or macOS machine without installing anything on the host.

**This repo is the scaffolding only.** Your profile, API keys, and session history live on your USB and are never committed here (`.gitignore` enforces that).

## Quick Start

```bash
# Copy onto your USB stick
git clone https://github.com/Jdrexx/hermes-portable /path/to/usb && cd /path/to/usb

# First time on any machine
./bootstrap.sh

# Every time (including first)
./run-hermes
```

`bootstrap.sh` downloads the right `uv` for the current OS, installs the Hermes engine onto the stick (not the host), and unpacks your profile.

## Bring Your Own Profile

To carry your full Hermes identity, add these files next to `bootstrap.sh` (all gitignored):

| File                         | Purpose                                  | How to create                                            |
| ---------------------------- | ---------------------------------------- | -------------------------------------------------------- |
| `.env`                       | API keys                                 | `cp .env.example .env`, fill in                          |
| `hermes-default.tar.gz`      | Profile (config, skills, memories, cron) | `hermes profile export default -o hermes-default.tar.gz` |
| `auth.json`                  | OAuth tokens                             | Copy from `~/.hermes/auth.json`                          |
| `state.db` (+ `-wal`/`-shm`) | Session history (optional)               | Copy from `~/.hermes/`                                   |

Without them, bootstrap starts a fresh profile.

## How It Works

Portable Hermes sets `$HERMES_HOME` to the `data/` directory on the USB. Hermes reads all config, skills, memories, and sessions from there. The engine is installed per-machine onto the stick via `uv`, with tool directory, binaries, and cache all kept on the stick (`.uv-tools/`, `.uv-cache/`).

- Your identity is on the USB — config, skills, memories travel with you
- The engine lives on the stick too — nothing installed on the host
- Updates work normally — `./uv tool upgrade hermes-agent`

## Requirements

- Linux x86_64, macOS (Intel or ARM), or WSL2
- Python 3.10+
- Internet on first bootstrap per machine (to download uv + hermes-agent)

## Encrypt the Stick (Recommended)

The stick carries API keys, OAuth tokens, and full session history. Encrypt it with gocryptfs:

```bash
bash encrypt-stick.sh        # One-time: create vault, set passphrase
bash open-hermes-vault.sh    # Unlock → ~/hermes-portable.open
cd ~/hermes-portable.open && ./run-hermes
bash close-hermes-vault.sh   # Lock before unplugging
```

Full walkthrough: [docs/ENCRYPTION.md](docs/ENCRYPTION.md)

## Updating

```bash
./uv tool upgrade hermes-agent
hermes profile export default -o /path/to/usb/hermes-default.tar.gz
cp ~/.hermes/state.db /path/to/usb/
```

## Filesystem Layout

```
usb/
├── bootstrap.sh              # One-time setup per machine (this repo)
├── run-hermes                # Daily launcher (this repo)
├── encrypt-stick.sh          # One-time vault creation (this repo)
├── open-hermes-vault.sh      # Unlock vault (this repo)
├── close-hermes-vault.sh     # Lock vault (this repo)
├── .env.example              # API key template (this repo)
├── docs/ENCRYPTION.md        # Encryption walkthrough (this repo)
├── .env                      # Your API keys (you add)
├── auth.json                 # OAuth tokens (you add)
├── hermes-default.tar.gz     # Exported profile (you add)
├── state.db(-wal/-shm)       # Session history (you add)
├── hermes-portable.vault/    # Encrypted payload
├── uv                        # Downloaded by bootstrap
├── data/                     # Live $HERMES_HOME
└── .uv-tools/ .uv-cache/     # Engine + cache
```

## License

MIT © Jon Dreksler