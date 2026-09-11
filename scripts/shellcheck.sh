# shellcheck shell=bash
#
# Validates the repository by running `shellcheck` on every `.sh` file it contains
#
# Usage:
#   bash scripts/repo-validate.sh

set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
shopt -s globstar # makes `**` match files in subdirectories

if command -v shellcheck > /dev/null; then
    shellcheck_cmd=(shellcheck)
else
    # `shellcheck` is not a hard requirement of this repository: when it is not installed, it is
    # fetched through `nix`, which is required anyway.
    shellcheck_cmd=(nix run nixpkgs#shellcheck --)
fi

"${shellcheck_cmd[@]}" ./**/*.sh
