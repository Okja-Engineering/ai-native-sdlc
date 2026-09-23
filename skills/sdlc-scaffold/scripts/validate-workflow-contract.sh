#!/usr/bin/env bash
set -euo pipefail

# validate-workflow-contract.sh PATH — check every ```contract block under
# PATH (a compact file or a modular directory) against the provisional
# workflow-contract schema. Prints one `path:kind:msg` finding per failure;
# exits non-zero if any. Callable interface for the exporter; the S6 test
# suite is a consumer (proposal §12.6).

here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib-contract.sh"

SUPPORTED_SCHEMA="workflow-contract/0.1.0"
STAGE_KEYS="purpose inputs outputs acceptance decides may_not decisions runtime_deps adoption_deps context_entry context_explore context_never on_missing_input on_conflict reentry review_fields"
EXTERNAL_KEYS="external_actor handoff return_evidence"
WORKFLOW_KEYS="schema_version stages risk_scaling owner"

note() { printf '%s:%s:%s\n' "$1" "$2" "$3"; }

# map_lookup MAP KEY — print the value from a tab-separated "key\tvalue" map.
map_lookup() {
  printf '%s' "$1" | awk -F'\t' -v k="$2" '$1 == k { sub(/^[^\t]*\t/, ""); print; exit }'
}

path="${1:-}"
if [[ -z "$path" || ! -e "$path" ]]; then
  note "${path:-<missing>}" input "contract path not supplied or does not exist" >&2
  exit 2
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
i=0
srcs_file="$tmp/srcs"; : > "$srcs_file"

if [[ -d "$path" ]]; then
  while IFS= read -r f; do
    i=$((i + 1)); printf '%s\n' "$f" >> "$srcs_file"
    BLOCK_PREFIX="f$i" extract_blocks_to "$f" "$tmp"
  done < <(find "$path" -type f -name '*.md' | sort)
else
  i=1; printf '%s\n' "$path" >> "$srcs_file"
  BLOCK_PREFIX="f1" extract_blocks_to "$path" "$tmp"
fi

blocks=()
while IFS= read -r b; do blocks+=("$b"); done \
  < <(find "$tmp" -name '*.contract' | sort)
if [[ "${#blocks[@]}" -eq 0 ]]; then
  note "$path" contract "no contract blocks found"
  exit 2
fi

fails=0
vfail() { note "$1" "$2" "$3"; fails=$((fails + 1)); }

local_origin() { # block-file -> origin path
  local n; n="$(basename "$1")"; n="${n%%-*}"; n="${n#f}"
  sed -n "${n}p" "$srcs_file"
}

# Pass 1: ids, per-stage outputs, workflow block, duplicates.
ids="" origins_map="" outputs_map="" workflow_id="" workflow_current="" wf_count=0
for b in "${blocks[@]}"; do
  origin="$(local_origin "$b")"
  # Structural: every non-blank line is `key: value`; no key repeats.
  bad="$(awk 'NF && $0 !~ /^[A-Za-z_][A-Za-z_0-9]*:/ { print FNR ": " $0 }' "$b")"
  if [[ -n "$bad" ]]; then
    vfail "$origin" format "malformed contract line(s): $bad"
  fi
  dup="$(awk -F: '/^[A-Za-z_][A-Za-z_0-9]*:/ { k=$1; gsub(/[[:space:]]/, "", k); print k }' "$b" | sort | uniq -d)"
  if [[ -n "$dup" ]]; then
    vfail "$origin" format "duplicate field(s) in contract block: $dup"
  fi
  first="$(grep -m1 . "$b" || true)"
  if [[ "$first" != id:* ]]; then
    vfail "$origin" id "contract block must begin with id:"
    continue
  fi
  id="$(block_value "$b" id)"; kind="$(block_value "$b" kind)"
  if [[ -z "$id" ]]; then vfail "$origin" id "empty id"; continue; fi
  if printf '%s' "$ids" | grep -qw "$id"; then
    vfail "$origin" id "duplicate contract id '$id' (also in $(map_lookup "$origins_map" "$id"))"
  fi
  ids="$ids $id"
  origins_map="${origins_map}${id}	${origin}
"

  if [[ "$kind" == "workflow" ]]; then
    wf_count=$((wf_count + 1))
    workflow_id="$id"
    workflow_current="$(block_value "$b" current_revision)"
  else
    outputs="$(block_value "$b" outputs)"
    outputs_map="${outputs_map}${id}	${outputs}
"
  fi
done

# Exactly one workflow block is required: it carries schema_version, owner,
# risk_scaling, and the declared stage list. Without it, version and
# authority checks have nothing to bind to — an absent block is a failure,
# not an exemption. More than one is ambiguous for the same reason.
if [[ "$wf_count" -eq 0 ]]; then
  vfail "$path" workflow "no workflow contract block — schema_version, owner, risk_scaling, stages unchecked"
elif [[ "$wf_count" -gt 1 ]]; then
  vfail "$path" workflow "multiple workflow contract blocks ($wf_count); exactly one required"
fi

# Pass 2: per-block checks.
for b in "${blocks[@]}"; do
  origin="$(local_origin "$b")"
  id="$(block_value "$b" id)"; kind="$(block_value "$b" kind)"

  case "$kind" in
    workflow)
      for key in $WORKFLOW_KEYS; do
        block_has "$b" "$key" || vfail "$origin" "$key" "missing required workflow field"
      done
      sv="$(block_value "$b" schema_version)"
      if [[ -n "$sv" && "$sv" != "$SUPPORTED_SCHEMA" ]]; then
        vfail "$origin" schema_version "unsupported version '$sv' (supported: $SUPPORTED_SCHEMA)"
      fi
      declared="$(block_value "$b" stages)"
      want="$(printf '%s' "$declared" | tr '|' '\n' | sed 's/^ *//;s/ *$//' | sort)"
      have="$(printf '%s\n' $ids | grep -v "^${workflow_id}$" | sort)"
      if [[ "$want" != "$have" ]]; then
        vfail "$origin" stages "workflow stage list does not match declared stage blocks"
      fi
      ;;
    internal|external)
      for key in $STAGE_KEYS; do
        block_has "$b" "$key" || vfail "$origin" "$key" "missing required stage field on '$id'"
      done
      if [[ "$kind" == "external" ]]; then
        for key in $EXTERNAL_KEYS; do
          block_has "$b" "$key" || vfail "$origin" "$key" "external stage '$id' missing $key"
        done
      fi
      # Enum constraints declared by the schema (§3). Presence was checked
      # above; here the value must be a member of the declared set.
      omi="$(block_value "$b" on_missing_input)"
      if [[ -n "$omi" ]]; then
        case "$omi" in
          stop|not-found|escalate) ;;
          *) vfail "$origin" on_missing_input "value '$omi' not in {stop, not-found, escalate}" ;;
        esac
      fi
      oc="$(block_value "$b" on_conflict)"
      if [[ -n "$oc" ]]; then
        case "$oc" in
          retain-both|stop|escalate) ;;
          *) vfail "$origin" on_conflict "value '$oc' not in {retain-both, stop, escalate}" ;;
        esac
      fi
      # runtime_deps entries are stage ids; 'none' cannot mix with real deps.
      rdeps="$(block_value "$b" runtime_deps)"
      if [[ "$rdeps" == *none* && "$rdeps" != "none" ]]; then
        vfail "$origin" runtime_deps "'none' cannot be combined with stage ids"
      elif [[ "$rdeps" != "none" ]]; then
        OLDIFS="$IFS"; IFS='|'
        for dep in $rdeps; do
          IFS="$OLDIFS"; dep="$(trim "$dep")"; IFS='|'
          printf '%s' "$ids" | grep -qw "$dep" \
            || vfail "$origin" runtime_deps "'$dep' is not a declared stage id"
        done
        IFS="$OLDIFS"
      fi
      # Inputs carry name@provenance. Provenance is E, D, R, A, Q, S, or
      # runtime:<stage-id>. A runtime input requires the producer in
      # runtime_deps and an exactly matching declared output path.
      inputs="$(block_value "$b" inputs)"
      OLDIFS="$IFS"; IFS='|'
      for item in $inputs; do
        IFS="$OLDIFS"; item="$(trim "$item")"; IFS='|'
        [[ -z "$item" || "$item" == "none" ]] && continue
        if [[ "$item" != *@* ]]; then
          vfail "$origin" inputs "entry '$item' lacks @provenance"
          continue
        fi
        prov="${item##*@}"
        case "$prov" in
          E|D|R|A|Q|S) ;;
          runtime:*)
            dep="${prov#runtime:}"
            if ! list_contains "$rdeps" "$dep"; then
              vfail "$origin" inputs "'$id' consumes runtime output of '$dep' not declared in runtime_deps"
              continue
            fi
            want_path="${item%@runtime:*}"
            depouts="$(map_lookup "$outputs_map" "$dep")"
            found=0
            OIFS2="$IFS"; IFS='|'
            for out in $depouts; do
              IFS="$OIFS2"; out="$(trim "$out")"; IFS='|'
              [[ "$out" == "$want_path" ]] && found=1
            done
            IFS="$OLDIFS"; IFS='|'
            if [[ "$found" -eq 0 ]]; then
              vfail "$origin" inputs "'$id' expects '$want_path' from '$dep' but that stage declares no such output (cross-module mismatch)"
            fi
            ;;
          *) vfail "$origin" inputs "unrecognized provenance '@$prov' on '$item'" ;;
        esac
      done
      IFS="$OLDIFS"
      # stale evidence: a pinned verified revision must match the workflow's current revision
      vrev="$(block_value "$b" verified_revision)"
      if [[ -n "$vrev" && -n "$workflow_current" && "$vrev" != "$workflow_current" ]]; then
        vfail "$origin" verified_revision "stale evidence: pinned '$vrev' != current revision '$workflow_current'"
      fi
      ;;
    *)
      vfail "$origin" kind "unknown or missing kind on '$id'"
      ;;
  esac
done

# Conflicting policy: two stages claiming the same output path.
out_seen=""
for b in "${blocks[@]}"; do
  kind="$(block_value "$b" kind)"
  [[ "$kind" == "workflow" ]] && continue
  origin="$(local_origin "$b")"
  id="$(block_value "$b" id)"
  outputs="$(block_value "$b" outputs)"
  OLDIFS="$IFS"; IFS='|'
  for item in $outputs; do
    IFS="$OLDIFS"; item="$(trim "$item")"; IFS='|'
    prior="$(map_lookup "$out_seen" "$item")"
    if [[ -n "$prior" ]]; then
      vfail "$origin" outputs "conflicting claim: '$item' also produced by '$prior'"
    else
      out_seen="${out_seen}${item}	${id}
"
    fi
  done
  IFS="$OLDIFS"
done

[[ "$fails" -eq 0 ]]
