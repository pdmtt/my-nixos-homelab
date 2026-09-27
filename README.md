# My NixOS Homelab

The setup of my self-hosted services using the `nix` ecosystem.

## Features

- Works on both BIOS and UEFI machines
- Disk encryption at rest using LVM on LUKS
- Allows LAN decryption of disk by SSHing into initrd
- Stage 2 is reachable from the internet using Tailscale
- Security hardened: /boot readable only by root, SSH pass auth off and root login blocked

## Requirements

You need `nix` installed.

## Installing NixOS on a new machine

[`nixos-anywhere`](https://nix-community.github.io/nixos-anywhere/) is used to install NixOS remotely on a new machine 
with the configuration specified in `config/`.

The following script SHOULD be executed once per machine:

> [!WARNING]
>
> After installing NixOS for the first time on the target, the `admin` user has the default password of `admin`.
>
> You SHOULD change it using `passwd admin` out-of-band for security reasons.

```bash
export TMP_SECRETS_DIR="/tmp/_secrets"
export INITRD_SECRETS_DIR="${TMP_SECRETS_DIR}/etc/secrets/initrd"
mkdir -p "$INITRD_SECRETS_DIR" \
    && ssh-keygen -t ed25519 -N "" -f "${INITRD_SECRETS_DIR:?}/initrd_host_key" \
    && nix run github:nix-community/nixos-anywhere -- \
        --flake ".#default" \
        --disk-encryption-keys /tmp/secret.key <(echo -n "your-passphrase") \
        --generate-hardware-config nixos-facter ./facter.json \
        --extra-files "${TMP_SECRETS_DIR:?}" \
        <root-or-sudoer>@<target-host>
```

> [!IMPORTANT]
>
> This command will write a `facter.json` file to your local machine. This file is gitignored, but SHOULD be kept because
> it is needed for future configuration changes.

To allow secure access to the machine from the internet, SSH into the machine, run the following command and complete
the login process:
```bash
sudo tailscale up
```

## Switching to a new NixOS configuration on an existing installation

> [!WARNING]
>
> This script will reboot the target and requires manual intervention when providing the LUKS decrypt key.

```bash
bash scripts/nixos-replace-config.sh
```

## Shipping logs from other devices

The homelab aggregates systemd journals in [VictoriaLogs](https://docs.victoriametrics.com/victorialogs/), listening
on port 9428 over the tailnet only. Its web UI is available at `http://homelab:9428/select/vmui`.

Any systemd-based device in the tailnet can ship its journal with `systemd-journal-upload`, no extra agent needed.

1. Install `systemd-journal-upload`. It is packaged as `systemd-journal-remote` on Debian/Ubuntu:
   ```bash
   sudo apt install systemd-journal-remote
   ```

2. Point it at the homelab by setting `URL` in the `[Upload]` section of `/etc/systemd/journal-upload.conf`:
   ```ini
   [Upload]
   URL=http://homelab:9428/insert/journald
   ```

3. Enable the service:
   ```bash
   sudo systemctl enable --now systemd-journal-upload
   ```

The upload service saves its position in the journal, so a device that goes offline resumes where it stopped. 
On the first run it uploads the whole local journal. 
Entries older than the retention period (see `config/logs.nix`) are discarded.

To check that the device's entries are arriving:
```bash
curl -s http://homelab:9428/select/logsql/query \
    --data-urlencode 'query=_time:5m | stats by (_HOSTNAME) count() entries'
```
