#!/usr/bin/env bash
set -euo pipefail

# check-acceptance.sh CONTRACT_PATH RECORD_PATH — verify a sibling
# contract-acceptance record (schema _config/contract-acceptance-schema.md):
# exactly one block, required fields, supported versions, decision: accept,
# `contract` resolving to CONTRACT_PATH, and a digest matching the
# contract's current normalized content. Prints findings; exits non-zero on
# failure. Read-only — this script never creates or updates approval.

here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib-contract.sh"

SUPPORTED_ACCEPTANCE="contract-acceptance/0.1.0"
SUPPORTED_CONTRACT="workflow-contract/0.1.0 outcome-targets/0.1.0"

note() { printf '%s:%s:%s\n' "$1" "$2" "$3"; }

contract="${1:-}"
record="${2:-}"
fails=0
fail() { note "$record" "$1" "$2"; fails=$((fails + 1)); }

[[ -n "$contract" && -e "$contract" ]] || { note "$record" contract "contract path missing or does not exist"; exit 2; }
[[ -n "$record" && -f "$record" ]]    || { note "${record:-<missing>}" record "acceptance record not supplied or not a file"; exit 2; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Structural checks precede any field evaluation: an unterminated or nested
# fence means the record's content is undefined; duplicate keys make values
# ambiguous (block_value takes the first) — a contradictory record must never
# pass the gate.
unterm="$(awk '
  /^```contract[[:space:]]*$/ { if (inb) print "nested contract fence"; inb=1; next }
  /^```[[:space:]]*$/ { if (inb) inb=0; next }
  END { if (inb) print "unterminated contract block" }
' "$record")"
[[ -z "$unterm" ]] || fail record "malformed acceptance file: $unterm"

extract_blocks_to "$record" "$tmp"
blocks=("$tmp"/*.contract)
[[ -f "${blocks[0]}" ]] || { fail record "no contract block found"; exit 1; }
[[ "${#blocks[@]}" -eq 1 ]] || fail record "expected exactly one block, found ${#blocks[@]}"
b="${blocks[0]}"

bad="$(awk 'NF && $0 !~ /^[A-Za-z_][A-Za-z_0-9]*:/ { print FNR ": " $0 }' "$b")"
[[ -z "$bad" ]] || fail record "malformed line(s): $bad"
dup="$(awk -F: '/^[A-Za-z_][A-Za-z_0-9]*:/ { k=$1; gsub(/[[:space:]]/, "", k); print k }' "$b" | sort | uniq -d)"
[[ -z "$dup" ]] || fail record "duplicate field(s): $dup"

kind="$(block_value "$b" kind)"
[[ "$kind" == "contract-acceptance" ]] || fail kind "expected kind contract-acceptance, found '${kind:-<none>}'"

for key in id schema_version contract contract_schema contract_digest reviewer reviewed_at decision rationale; do
  block_has "$b" "$key" || fail "$key" "missing required acceptance field"
done

sv="$(block_value "$b" schema_version)"
[[ -z "$sv" || "$sv" == "$SUPPORTED_ACCEPTANCE" ]] || \
  fail schema_version "unsupported version '$sv' (supported: $SUPPORTED_ACCEPTANCE)"

cs="$(block_value "$b" contract_schema)"
[[ -z "$cs" || " $SUPPORTED_CONTRACT " == *" $cs "* ]] || \
  fail contract_schema "unsupported contract schema '$cs' (supported: $SUPPORTED_CONTRACT)"

# The record's `contract` must resolve (relative to the record file) to the
# supplied contract path after canonicalization — symlink-resolved on both
# sides, directories included.
canon_path() { # PATH -> canonical absolute path (must exist)
  local p="$1"
  if [[ -d "$p" ]]; then
    (cd "$p" && pwd -P)
  else
    printf '%s/%s' "$(cd "$(dirname "$p")" && pwd -P)" "$(basename "$p")"
  fi
}
crel="$(block_value "$b" contract)"
if [[ -n "$crel" ]]; then
  rdir="$(cd "$(dirname "$record")" && pwd -P)"
  resolved=""
  if [[ -e "$rdir/$crel" || -d "$rdir/$crel" ]]; then
    resolved="$(canon_path "$rdir/$crel")"
  fi
  canon="$(canon_path "$contract")"
  [[ -n "$resolved" && "$resolved" == "$canon" ]] || \
    fail contract "record covers '$crel' which does not resolve to the supplied contract"
fi

dec="$(block_value "$b" decision)"
[[ "$dec" == "accept" ]] || fail decision "decision is '${dec:-<none>}'; export requires accept"

digest="$(block_value "$b" contract_digest)"
if [[ -n "$digest" && "$digest" != sha256:* ]]; then
  fail contract_digest "digest must be sha256:<hex>, found '$digest'"
elif [[ -n "$digest" ]]; then
  actual="sha256:$(norm_form "$contract" | shasum -a 256 | awk '{print $1}')"
  if [[ "$actual" != "$digest" ]]; then
    fail contract_digest "contract content differs from reviewed digest (recorded $digest, current $actual)"
  fi
fi

[[ "$fails" -eq 0 ]]
