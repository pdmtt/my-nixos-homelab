# shellcheck shell=bash
#
# Performs a dry build of the NixOS configuration
#
# Usage:
#   bash scripts/nixos-rebuild-dry-build.sh
#
# Arguments:
#   <target-host-name>: The name of the target machine in the data.local directory

if [ ! -f facter.json ]; then
    source scripts/stage-facter-file.sh "${1:?}"
fi

nix run nixpkgs#nixos-rebuild -- dry-build --flake .#default