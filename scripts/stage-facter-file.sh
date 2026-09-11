# shellcheck shell=bash
#
# Stages the facter file for a target machine
#
# Usage:
#   bash scripts/stage-facter-file.sh <target-host-name>
#
# Arguments:
#   <target-host-name>: The name of the target machine in the data.local directory

FILE_NAME="facter.json"

setup() {
    local target_host_name="${1:?}"

    echo "Staging facter file for '${1:?}'..."

    [ -f data.local/"${target_host_name}".facter.json ] || { 
        echo "facter file not found for target ${target_host_name}"
        exit 1
    } >&2

    cp data.local/"${target_host_name}".facter.json "${FILE_NAME}"

    # `nixos-rebuild` will ignore everything not tracked by git, which includes the target machine's `facter.json`, 
    # because it is gitignored. We need to git add it before executing the following command.
    git add -f "${FILE_NAME}"

    trap cleanup EXIT
}

cleanup() {
    echo "Cleaning up..."
    git rm --cached "${FILE_NAME}"
    rm "${FILE_NAME}"
}

set -e
setup "$1"