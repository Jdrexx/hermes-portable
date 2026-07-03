# Portable Hermes

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20WSL2-blue)
![Shell](https://img.shields.io/badge/shell-bash-121011?logo=gnu-bash&logoColor=white)

Run a fully self-contained [Hermes Agent](https://github.com/NousResearch/hermes-agent) from a USB stick.
Your exact profile, skills, memories, sessions, and configuration —
ready to plug into any Linux or macOS machine, without installing
anything on the host.

This repo is the **scaffolding only**. Your profile, API keys, and
session history live on your USB stick and are never committed here
(the `.gitignore` enforces that).

## Quick Start

```bash
# 1. Copy this repo onto your USB stick
git clone https://github.com/Jdrexx/hermes-portable /path/to/usb && cd /path/to/usb

# 2. Add your own credentials (optional but recommended)
cp .env.example .env        # then fill in your API keys

# 3. First time on any machine:
./bootstrap.sh

# 4. Every time (including first):
./run-hermes
```

`bootstrap.sh` downloads the right `uv` for the current OS/architecture,
installs the Hermes engine *onto the stick* (not the host), and unpacks
your profile if one is present.

### Example session

```console
$ ./bootstrap.sh
============================================
  Portable Hermes — First Run Bootstrap
============================================
[1/5] Detected: Linux / x86_64
[2/5] Checking Python...       Found python3 3.11
[3/5] Checking uv...           Using bundled uv 0.11.26
[4/5] Installing Hermes Agent via uv...
       Installed 3 executables: hermes, hermes-acp, hermes-agent
[5/5] Seeding profile and configuration...
       Extracted profile to data/
  Bootstrap complete!  Run ./run-hermes to start.

$ ./run-hermes
Hermes ready. $HERMES_HOME=/media/usb/data
```

## Bring your own profile

To make the stick carry your full Hermes identity, add these files next
to `bootstrap.sh` (all are gitignored):

| File | Purpose | How to create it |
|------|---------|------------------|
| `.env` | API keys | `cp .env.example .env` and fill in |
| `hermes-default.tar.gz` | Profile: config, skills, memories, cron, SOUL.md | `hermes profile export default -o hermes-default.tar.gz` |
| `auth.json` | OAuth tokens | copy from `~/.hermes/auth.json` |
| `state.db` (+ `-wal`/`-shm`) | Session history (optional) | copy from `~/.hermes/` |

Without them, bootstrap starts a fresh profile — also fine.

## How it works

Portable Hermes sets `$HERMES_HOME` to the `data/` directory on the
USB. Hermes reads all config, skills, memories, and sessions from
there. The engine (hermes-agent) is installed per-machine onto the
stick via `uv`, with the tool directory, binaries, and cache all kept
on the stick (`.uv-tools/`, `.uv-cache/`).

- **Your identity is on the USB** — config, skills, memories travel with you
- **The engine lives on the stick too** — nothing is installed on the host
- **Updates work normally** — `./uv tool upgrade hermes-agent`

## Requirements

- Linux x86_64, macOS (Intel or ARM), or WSL2
- Python 3.10+
- Internet on the first bootstrap per machine (to download uv + hermes-agent)

## Encrypt the stick (recommended)

The stick carries every API key, OAuth token, and your full session
history — so encrypt it. This repo ships a [gocryptfs](https://github.com/rfjakob/gocryptfs)
workflow that keeps everything encrypted at rest and mounts a decrypted
view only while you're using it (nothing plaintext touches the host disk):

```bash
bash encrypt-stick.sh          # one-time: create the vault, set a passphrase
bash open-hermes-vault.sh      # unlock  → ~/hermes-portable.open
cd ~/hermes-portable.open && ./run-hermes
bash close-hermes-vault.sh     # lock before unplugging
```

Full walkthrough, platform notes, and gotchas: **[docs/ENCRYPTION.md](docs/ENCRYPTION.md)**.

## Security notes

- `.env`, `auth.json`, and `state.db` contain API keys, OAuth tokens,
  and your full conversation history. They belong on the physical
  stick only. **Never commit them, and wipe them before handing the
  stick to anyone else.**
- **Encrypt the stick** (see above). If you'd rather encrypt the whole
  device, LUKS (Linux) or VeraCrypt (cross-platform) also work.
- Never store the vault passphrase next to the vault, and never commit
  them together — the `.gitignore` blocks both by default.
- You can re-auth on any machine via `hermes auth` or by copying fresh
  credentials into `data/`.

## Updating

```bash
# Update the Hermes engine on the stick
./uv tool upgrade hermes-agent

# Re-export your profile (run on the machine that has it)
hermes profile export default -o /path/to/usb/hermes-default.tar.gz

# Refresh session history
cp ~/.hermes/state.db /path/to/usb/
```

## Filesystem layout

```
usb/
├── bootstrap.sh          # One-time setup per machine   (this repo)
├── run-hermes            # Daily launcher               (this repo)
├── encrypt-stick.sh      # One-time: create the vault   (this repo)
├── open-hermes-vault.sh  # Unlock the encrypted vault   (this repo)
├── close-hermes-vault.sh # Lock the encrypted vault     (this repo)
├── .env.example          # Template for your API keys   (this repo)
├── docs/ENCRYPTION.md    # Encryption walkthrough       (this repo)
├── gocryptfs             # Encryption binary            (you add)
├── .env                  # Your API keys                (you add)
├── auth.json             # OAuth tokens                 (you add)
├── hermes-default.tar.gz # Your exported profile        (you add)
├── state.db(-wal/-shm)   # Session history              (you add)
├── hermes-portable.vault/# Encrypted payload — created by encrypt-stick.sh
├── uv                    # Downloaded by bootstrap
├── data/                 # Your live $HERMES_HOME — created by bootstrap
└── .uv-tools/ .uv-cache/ # Engine + cache, on-stick only
```

## License

[MIT](LICENSE) © Jon Dreksler
