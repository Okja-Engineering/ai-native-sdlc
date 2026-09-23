#!/usr/bin/env bash
set -euo pipefail

# normalize-workflow.sh PATH — print the canonical normalized contract
# (one `id::key=item` line per list item, sorted) for a compact file or a
# modular directory. This is the equivalence surface (schema §7) and the
# content the acceptance digest binds to.

here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib-contract.sh"

path="${1:-}"
if [[ -z "$path" || ! -e "$path" ]]; then
  printf 'normalize-workflow: contract path not supplied or does not exist\n' >&2
  exit 2
fi

norm_form "$path"
