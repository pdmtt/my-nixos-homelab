# shellcheck shell=bash
#
# Replaces the NixOS configuration on an existing installation
#
# Usage:
#   bash scripts/nixos-replace-config.sh <target-host-name>
#
# Arguments:
#   <target-host-name>: The name of the target machine in the data.local directory

cleanup() {
    echo "Cleaning up..."
    git rm --cached facter.json
    rm facter.json
}

setup_and_output_target_ip() {
    echo "Setting up..." >&2

    local target_host_name="${1:?}"

    [ -f data.local/"${target_host_name}".facter.json ] || { 
        echo "facter file not found for target ${target_host_name}"
        exit 1
    } >&2


    cp data.local/"${target_host_name}".facter.json facter.json

    # `nixos-rebuild` will ignore everything not tracked by git, which includes the target machine's `facter.json`, 
    # because it is gitignored. We need to git add it before executing the following command.
    git add -f facter.json

    cat data.local/"${target_host_name}".ip.txt
}

nix_rebuild_switch_target() {
    local target_host_ip="${1:?}"
    nix run nixpkgs#nixos-rebuild -- switch \
        --flake ".#default" \
        --target-host "admin@${target_host_ip:?}" \
        --build-host "admin@${target_host_ip:?}" \
        --sudo \
        --ask-sudo-password
}

reboot_target() {
    local target_host_ip="${1:?}"
    ssh -t "admin@${target_host_ip:?}" sudo reboot
}

prompt_for_luks_password() {
    local target_host_ip="${1:?}"
    ssh -o "ConnectTimeout=10" -o "ConnectionAttempts=15" -p 2222 -t "root@${target_host_ip:?}" cryptsetup-askpass
}

set -ex
TARGET_HOST_IP="$(setup_and_output_target_ip "${1:?}")"
trap cleanup EXIT # required after setup
nix_rebuild_switch_target "$TARGET_HOST_IP"
reboot_target "$TARGET_HOST_IP"
sleep 10 # give the target machine some time to reboot
prompt_for_luks_password "$TARGET_HOST_IP"