# Encrypting the stick

Portable Hermes carries your API keys, OAuth tokens, and full conversation
history. A plain USB stick with those files is a walking security incident —
lose it and you've handed someone every credential on it. This guide sets up
transparent encryption so a lost stick is a non-event.

We use [gocryptfs](https://github.com/rfjakob/gocryptfs): a well-audited,
single-binary encrypted overlay filesystem. Your files live encrypted at rest
in `hermes-portable.vault/`; unlocking mounts a decrypted *view* you use like a
normal folder. Nothing plaintext is ever written to the host machine's disk.

## One-time setup

1. Put your payload on the stick next to the scripts: `.env`, `auth.json`,
   `hermes-default.tar.gz`, and (optionally) `state.db`.
2. Get the `gocryptfs` binary onto the stick (or install it on the host):

   ```bash
   # Linux x86_64 example — check the releases page for the current version
   curl -L -o gocryptfs.tar.gz \
     https://github.com/rfjakob/gocryptfs/releases/latest/download/gocryptfs_v2.6.1_linux-static_amd64.tar.gz
   tar xzf gocryptfs.tar.gz gocryptfs && rm gocryptfs.tar.gz
   ```

3. Run the setup helper. It creates the vault, asks for a passphrase, and moves
   your sensitive files inside:

   ```bash
   bash encrypt-stick.sh
   ```

   **Store the passphrase in a password manager.** Lose it and the data is gone
   — there is no recovery.

## Daily use

```bash
bash open-hermes-vault.sh          # prompts for passphrase
cd ~/hermes-portable.open          # the decrypted view
./run-hermes                       # use Hermes normally
# ... when done ...
bash close-hermes-vault.sh         # lock it, then unplug
```

## Why the mountpoint is in your home directory

FUSE cannot mount a decrypted view *onto a folder inside* a FAT/exFAT stick —
it fails with `fusermount: mount failed: Permission denied`. So the encrypted
files stay on the stick and the decrypted window opens at
`~/hermes-portable.open` on the host instead. This is by design and completely
standard for encrypted removable media. Override the location with:

```bash
HERMES_MOUNT=/some/other/path bash open-hermes-vault.sh
```

Because it's a live FUSE view, closing the vault makes the plaintext vanish —
it was never written to the host's physical disk.

## Notes and gotchas

- **exFAT drops the execute bit**, so always invoke the scripts with
  `bash script.sh`, not `./script.sh`. The scripts re-`chmod +x` the bundled
  `gocryptfs` binary automatically.
- **Eject cleanly** before unplugging: `bash close-hermes-vault.sh`, then
  unmount the stick itself (`udisksctl unmount -b /dev/sdX1` or your file
  manager's eject). Your desktop file manager may keep the stick busy by
  watching its trash folder — close its window if unmount reports "busy".
- **Never commit the vault and the passphrase together.** The `.gitignore`
  already blocks `hermes-portable.vault/` and `*.passphrase`; keep them on the
  physical stick only. Publishing both would make the encryption worthless.
- **Other platforms:** gocryptfs has builds for macOS and Windows (via WinFsp).
  Grab the matching binary from the releases page.
- **Full-disk alternative:** if you'd rather encrypt the whole stick instead of
  a folder, LUKS (Linux) or VeraCrypt (cross-platform) also work — but they
  require the host to support that container format. gocryptfs travels as a
  single binary, which is why it's the default here.
