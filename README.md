# nix-self-hosted

The setup of my self-hosted services using the `nix` ecosystem.

## Features

- Works on both BIOS and UEFI machines
- Encryption at rest using LVM on LUKS
- Allows uncrypting remotely using SSH in initrd
- Security hardened: /boot readable only by root, SSH pass auth off and root login blocked

## Requirements

You need `nix` installed.

## Installing NixOS on a new machine

I use [`nixos-anywhere`](https://nix-community.github.io/nixos-anywhere/) to install NixOS on a new machine already set
up with this configuration.

As per its [Github repository](https://github.com/nix-community/nixos-anywhere)'s README:

> Setting up a new machine is time-consuming, and becomes complicated when it needs to be done remotely. If you're installing NixOS, the nixos-anywhere tool allows you to pre-configure the whole process including:
>
> - Disk partitioning and formatting
> - Configuring and installing NixOS
> - Installing additional files and software
>
> You can then initiate an unattended installation with a single CLI command. Since nixos-anywhere can access the new machine using SSH, it's ideal for remote installations.
>
> Once you have initiated the command, there is no need to 'babysit' the installation. It all happens automatically.
>
> You can use the stored configuration to repeat the same installation if you need to.

### Command

> [!WARNING]
>
> After installing NixOS for the first time on the target, the `admin` user has the default password of `admin`.
>
> You MUST change it using `passwd admin` for security reasons.

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

> [!INFO]
>
> This command will write a `facter.json` file to your local machine. This file is gitignored, but SHOULD be kept because
> it is needed for future configuration changes.

## Switching to a new NixOS configuration on an existing installation

> [!WARNING]
>
> This scripts will reboot the target and requires manual intervention when providing the LUKS decrypt key.

```bash
bash scripts/nixos-replace-config.sh
```
