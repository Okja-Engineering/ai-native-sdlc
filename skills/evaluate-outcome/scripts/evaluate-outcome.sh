#!/usr/bin/env bash
set -euo pipefail

# evaluate-outcome.sh — deterministic outcome evaluator (proposal §14).
#   --contract FILE      accepted workflow contract (digest must match the
#                        targets' declared intent_digest)
#   --targets FILE       outcome-targets/0.1.0 (stable outcome IDs)
#   --acceptance FILE    contract-acceptance record covering the targets file
#   --evidence FILE      outcome-evidence/0.1.0 observations (+ lessons)
#   --baseline FILE      outcome-evidence/0.1.0 pre-adoption measures (optional)
#   --implementation-rev REV   revision being evaluated
#   --inputs-root DIR    the inspected repository the receipt must stay outside
#   --out FILE           receipt destination (differing file -> REFUSE,
#                        identical -> SAME, absent -> CREATE)
# Exit 0 on CREATE/SAME, 2 on input/validation failure, 4 on destination
# refusal. Inputs are read-only; only --out is ever written. The receipt
# classifies evidence — observed means available, never successful.

here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../../sdlc-scaffold/scripts/lib-contract.sh"
. "$here/../../sdlc-scaffold/scripts/lib-export.sh"

usage() {
  printf 'usage: evaluate-outcome.sh --contract C --contract-acceptance CA --targets T --targets-acceptance TA --evidence E [--baseline B] --implementation-rev R --inputs-root DIR --out FILE\n' >&2
  exit 2
}

contract="" contract_acceptance="" targets="" targets_acceptance=""
evidence="" baseline="" impl_rev="" inputs_root="" out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --contract) contract="$2"; shift 2 ;;
    --contract-acceptance) contract_acceptance="$2"; shift 2 ;;
    --targets) targets="$2"; shift 2 ;;
    --targets-acceptance) targets_acceptance="$2"; shift 2 ;;
    --evidence) evidence="$2"; shift 2 ;;
    --baseline) baseline="$2"; shift 2 ;;
    --implementation-rev) impl_rev="$2"; shift 2 ;;
    --inputs-root) inputs_root="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[[ -f "$contract" && -f "$contract_acceptance" && -f "$targets" \
  && -f "$targets_acceptance" && -f "$evidence" \
  && -n "$impl_rev" && -d "$inputs_root" && -n "$out" ]] || usage
[[ -z "$baseline" || -f "$baseline" ]] || usage

err() { printf 'evaluate: %s\n' "$1" >&2; exit "${2:-2}"; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

block_of() { # FILE KIND — structural check + extract; prints block path
  local f="$1" rep="$2"
  if ! serr="$(check_structure "$f" "$rep" 2>&1)"; then
    printf 'evaluate: %s: %s\n' "$f" "$serr" >&2; exit 2
  fi
  local d; d="$(mktemp -d "$tmp/blk.XXXX")"
  extract_blocks_to "$f" "$d"
  printf '%s' "$d/blk-1.contract"
}

# --- Targets ------------------------------------------------------------------
tb="$(block_of "$targets" "target")"
[[ "$(block_value "$tb" kind)" == "outcome-targets" ]] \
  || err "$targets: kind must be outcome-targets"
[[ "$(block_value "$tb" schema_version)" == "outcome-targets/0.1.0" ]] \
  || err "$targets: unsupported schema_version"
for k in id intent_digest; do
  block_has "$tb" "$k" || err "$targets: missing field '$k'"
done
tid="$(block_value "$tb" id)"
intent="$(block_value "$tb" intent_digest)"
[[ "$intent" == sha256:* ]] || err "$targets: intent_digest must be sha256:<hex>"

# target map: OID \t KIND \t DESC \t MEASURE \t UNIT \t SCOPE \t DURATION \t BASIS
tmap="$tmp/targets.map"; : > "$tmap"
while IFS= read -r item; do
  [[ -z "$item" || "$item" == "none" ]] && continue
  IFS=';' read -r oid okind odesc m u s d b _extra <<< "$item"
  oid="$(trim "$oid")"; okind="$(trim "$okind")"; odesc="$(trim "$odesc")"
  [[ -n "$oid" && "$okind" =~ ^(product|process)$ && -n "$odesc" && -z "$(trim "${_extra:-}")" ]] \
    || err "$targets: malformed target item: '$item'"
  kv_check() { [[ "$(trim "$1")" == "$2:"* && -n "$(trim "${1#*:}")" ]]; }
  kv_check "$m" measure || err "$targets: target '$oid' requires 'measure:<v>' in field 4"
  kv_check "$u" unit    || err "$targets: target '$oid' requires 'unit:<v>' in field 5"
  kv_check "$s" scope   || err "$targets: target '$oid' requires 'scope:<v>' in field 6"
  kv_check "$d" duration || err "$targets: target '$oid' requires 'duration:<N>d' in field 7"
  kv_check "$b" basis   || err "$targets: target '$oid' requires 'basis:<v>' in field 8"
  m="$(trim "${m#*:}")"; u="$(trim "${u#*:}")"; s="$(trim "${s#*:}")"
  d="$(trim "${d#*:}")"; b="$(trim "${b#*:}")"
  [[ "$d" =~ ^[0-9]+d$ ]] || err "$targets: target '$oid' duration must be <N>d"
  map_has "$tmap" "$oid" && err "$targets: duplicate outcome id '$oid'"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$oid" "$okind" "$odesc" "$m" "$u" "$s" "$d" "$b" >> "$tmap"
done < <(block_items "$tb" target)
[[ -s "$tmap" ]] || err "$targets: no outcome targets declared"

# --- Bindings -----------------------------------------------------------------
# Binding 1 — the contract must itself be a valid workflow contract AND
# carry a matching content-bound acceptance record. Accepted targets do not
# substitute for an accepted workflow.
if ! vlog="$("$here/../../sdlc-scaffold/scripts/validate-workflow-contract.sh" "$contract" 2>&1)"; then
  printf '%s\n' "$vlog" >&2
  err "workflow contract failed validation"
fi
if ! "$here/../../sdlc-scaffold/scripts/check-acceptance.sh" "$contract" "$contract_acceptance" > "$tmp/cacc.log" 2>&1; then
  cat "$tmp/cacc.log" >&2; err "contract acceptance record does not verify"
fi

# targets must name the exact accepted contract content
actual_intent="sha256:$(norm_form "$contract" | shasum -a 256 | awk '{print $1}')"
[[ "$actual_intent" == "$intent" ]] \
  || err "contract digest $actual_intent does not match targets' intent_digest $intent — the accepted-intent link is stale"

# Binding 2 — the targets file must itself carry a matching acceptance record
if ! "$here/../../sdlc-scaffold/scripts/check-acceptance.sh" "$targets" "$targets_acceptance" > "$tmp/acc.log" 2>&1; then
  cat "$tmp/acc.log" >&2; err "targets acceptance record does not verify"
fi
targets_digest="sha256:$(norm_form "$targets" | shasum -a 256 | awk '{print $1}')"

# --- Evidence ------------------------------------------------------------------
# Grammar: evidence: OID ; value ; locator ; period:P ; unit:U ; basis:B ; rev:R
# [; measure:M] [; scope:S] [; sampling:M] [; conditions:C]
# Positions 4-7 carry fixed field names — a present field with the wrong key
# is malformed (exit 2); an absent field or declared-empty value is missing
# comparison information (non-comparable), not malformed. Positions 8+ are
# optional named fields from the documented set, at most once each.
# Map rows: OID \t VALUE \t LOC \t PERIOD \t UNIT \t BASIS \t REV \t MEASURE \t SCOPE \t SAMPLING \t CONDITIONS
parse_evidence() { # FILE -> rows on stdout
  local eb; eb="$(block_of "$1" "evidence lesson")"
  [[ "$(block_value "$eb" kind)" == "outcome-evidence" ]] \
    || err "$1: kind must be outcome-evidence"
  [[ "$(block_value "$eb" schema_version)" == "outcome-evidence/0.1.0" ]] \
    || err "$1: unsupported schema_version"
  local item oid val loc pf uf bf rv rest extra
  local -a fixed=(period unit basis rev)
  local -a fv fxs=()
  local i fk me sc sa co
  while IFS= read -r item; do
    [[ -z "$item" || "$item" == "none" ]] && continue
    IFS=';' read -r oid val loc pf uf bf rv rest <<< "$item"
    oid="$(trim "$oid")"; val="$(trim "$val")"; loc="$(trim "$loc")"
    [[ -n "$oid" && -n "$val" ]] \
      || err "$1: malformed evidence item: '$item'"
    map_has "$tmap" "$oid" || err "$1: evidence for undeclared outcome '$oid'"
    printf '%s' "$loc" | grep -qE '^(obs|interview|path|owner):[^ ;]+$' \
      || err "$1: evidence '$oid' locator '$loc' is not a documented locator"
    fv=("$pf" "$uf" "$bf" "$rv")
    for i in 0 1 2 3; do
      fk="$(trim "${fv[$i]:-}")"
      if [[ -n "$fk" && "$fk" != "${fixed[$i]}:"* ]]; then
        err "$1: evidence '$oid' field $((i + 4)) must be '${fixed[$i]}:<v>' — found '$fk'"
      fi
    done
    me=""; sc=""; sa=""; co=""
    fxs=()
    if [[ -n "$(trim "${rest:-}")" ]]; then IFS=';' read -ra fxs <<< "$rest"; fi
    for extra in "${fxs[@]}"; do
      extra="$(trim "$extra")"
      [[ -z "$extra" ]] && continue
      case "$extra" in
        measure:*)    [[ -z "$me" ]] || err "$1: evidence '$oid' repeats 'measure'"; me="$(trim "${extra#*:}")" ;;
        scope:*)      [[ -z "$sc" ]] || err "$1: evidence '$oid' repeats 'scope'";   sc="$(trim "${extra#*:}")" ;;
        sampling:*)   [[ -z "$sa" ]] || err "$1: evidence '$oid' repeats 'sampling'"; sa="$(trim "${extra#*:}")" ;;
        conditions:*) [[ -z "$co" ]] || err "$1: evidence '$oid' repeats 'conditions'"; co="$(trim "${extra#*:}")" ;;
        *) err "$1: evidence '$oid' unsupported field '${extra%%:*}' — documented fields: period, unit, basis, rev, measure, scope, sampling, conditions" ;;
      esac
    done
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$oid" "$val" "$loc" \
      "$(trim "${pf#*:}")" "$(trim "${uf#*:}")" "$(trim "${bf#*:}")" "$(trim "${rv#*:}")" \
      "$me" "$sc" "$sa" "$co"
  done < <(block_items "$eb" evidence)
  while IFS= read -r item; do
    [[ -z "$item" || "$item" == "none" ]] && continue
    printf 'LESSON\t%s\n' "$item"
  done < <(block_items "$eb" lesson)
}

parse_evidence "$evidence" > "$tmp/ev.map"
if [[ -n "$baseline" ]]; then parse_evidence "$baseline" > "$tmp/base.map"; else : > "$tmp/base.map"; fi
grep -v '^LESSON' "$tmp/ev.map" > "$tmp/ev.only" || true
grep -v '^LESSON' "$tmp/base.map" > "$tmp/base.only" || true

# period duration in elapsed days; empty/unparseable -> empty
period_days() {
  awk -v p="$1" 'BEGIN{
    if (p !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}\.\.[0-9]{4}-[0-9]{2}-[0-9]{2}$/) { print ""; exit }
    split(substr(p,1,10),a,"-"); split(substr(p,13,10),b,"-")
    print dc(b[1]+0,b[2]+0,b[3]+0) - dc(a[1]+0,a[2]+0,a[3]+0)
  }
  function dc(y,m,d){ y-=(m<=2); e=int((y>=0?y:y-399)/400); yoe=y-e*400;
    doy=int((153*(m+(m>2?-3:9))+2)/5)+d-1; return e*146097+yoe*365+int(yoe/4)-int(yoe/100)+doy-719468 }'
}

# row_field ROW COL — print column COL of a tab-separated row. Uses awk so
# empty middle fields are preserved (IFS=tab read collapses them).
row_field() { printf '%s\n' "$1" | awk -F'\t' -v c="$2" '{print $c; exit}'; }

# comparability of an evidence row against the target's declared surface.
# measure and scope are independently checked — a row that does not declare
# them is missing comparison information, not silently equivalent.
incomparable() { # OID ROW -> prints missing/mismatch field names
  local oid="$1" row="$2" out=""
  local per un ba me sc tm tu ts td tb pd
  per="$(row_field "$row" 4)"; un="$(row_field "$row" 5)"; ba="$(row_field "$row" 6)"
  me="$(row_field "$row" 8)"; sc="$(row_field "$row" 9)"
  tm="$(map_get "$tmap" "$oid" 4)"; tu="$(map_get "$tmap" "$oid" 5)"
  ts="$(map_get "$tmap" "$oid" 6)"; td="$(map_get "$tmap" "$oid" 7)"
  tb="$(map_get "$tmap" "$oid" 8)"
  [[ -z "$per" ]] && out="$out period"
  [[ -z "$un" ]] && out="$out unit"
  [[ -z "$ba" ]] && out="$out basis"
  [[ -z "$me" ]] && out="$out measure"
  [[ -z "$sc" ]] && out="$out scope"
  [[ -n "$un" && "$un" != "$tu" ]] && out="$out unit!=$tu"
  [[ -n "$ba" && "$ba" != "$tb" ]] && out="$out basis!=$tb"
  [[ -n "$me" && "$me" != "$tm" ]] && out="$out measure!=$tm"
  [[ -n "$sc" && "$sc" != "$ts" ]] && out="$out scope!=$ts"
  pd="$(period_days "$per")"
  [[ -n "$per" && -z "$pd" ]] && out="$out period-unparseable"
  [[ -n "$pd" && "${td%d}" != "$pd" ]] && out="$out duration!=$td"
  printf '%s' "${out# }"
}

# render_row OID ROW — "value" [locator · period · rev:R] with an optional
# per-row non-comparable annotation; every record is preserved verbatim.
render_row() {
  local r="$2" nc; nc="$(incomparable "$1" "$r")"
  printf '"%s" [%s · %s · rev:%s]' \
    "$(row_field "$r" 2)" "$(row_field "$r" 3)" "$(row_field "$r" 4)" "$(row_field "$r" 7)"
  [[ -n "$nc" ]] && printf ' — non-comparable: %s' "$nc"
}

render_rows() { # OID ROWSFILE -> joined ' ; ' rendered rows
  local out="" r
  while IFS= read -r r; do out="$out$(render_row "$1" "$r") ; "; done < "$2"
  printf '%s' "${out% ; }"
}

# has_nc OID ROWSFILE — exit 0 if any row fails comparability vs the target
has_nc() {
  local r
  while IFS= read -r r; do
    [[ -n "$(incomparable "$1" "$r")" ]] && return 0
  done < "$2"
  return 1
}

# pairwise_gap COL NAME EVIDFILE BASEFILE — sampling/conditions are pairwise
# declarations: a supported comparison requires exactly one declared value on
# each side, and they must be equal. Prints the gap; nothing when satisfied.
pairwise_gap() {
  local col="$1" name="$2" ev bv en bn
  ev="$(cut -f"$col" "$3" | sort -u | awk 'NF')"
  bv="$(cut -f"$col" "$4" | sort -u | awk 'NF')"
  en="$(printf '%s\n' "$ev" | awk 'NF{n++}END{print n+0}')"
  bn="$(printf '%s\n' "$bv" | awk 'NF{n++}END{print n+0}')"
  if [[ "$en" -eq 0 || "$bn" -eq 0 ]]; then
    printf '%s not declared' "$name"
  elif [[ "$en" -gt 1 || "$bn" -gt 1 ]]; then
    printf '%s declared inconsistently' "$name"
  elif [[ "$ev" != "$bv" ]]; then
    printf '%s differs ("%s" vs "%s")' "$name" "$ev" "$bv"
  fi
}

# --- Evaluate ------------------------------------------------------------------
: > "$tmp/outcomes"      # OID \t KIND \t STATUS \t DETAIL
reeval=current
while IFS=$'\t' read -r oid okind odesc _m _u _s _d _b; do
  items="$tmp/items-$oid"
  awk -F'\t' -v k="$oid" '$1==k' "$tmp/ev.only" > "$items"
  cur="$tmp/cur-$oid"; hist="$tmp/hist-$oid"
  awk -F'\t' -v r="$impl_rev" '$7==r' "$items" > "$cur"
  awk -F'\t' -v r="$impl_rev" '$7!=r' "$items" > "$hist"
  n="$(wc -l < "$items" | tr -d ' ')"
  ncur="$(wc -l < "$cur" | tr -d ' ')"; nhist="$(wc -l < "$hist" | tr -d ' ')"
  status="" detail=""
  if [[ "$n" -eq 0 ]]; then
    status=missing; detail="no evidence — NOT FOUND"
  elif [[ "$ncur" -eq 0 ]]; then
    # Evidence exists only for earlier revisions: preserved verbatim, and the
    # outcome is marked for re-evaluation — never re-labeled or erased.
    status=stale; reeval=required
    detail="no evidence at revision $impl_rev — recorded earlier: $(render_rows "$oid" "$hist") ; re-evaluate"
  elif [[ "$(cut -f2 "$cur" | sort -u | awk 'NF' | wc -l | tr -d ' ')" -gt 1 ]]; then
    status=conflicted
    detail="conflicting observations: $(render_rows "$oid" "$cur")"
  elif has_nc "$oid" "$cur"; then
    status=non-comparable
    detail="$(render_rows "$oid" "$cur")"
  else
    status=observed
    detail="$(render_rows "$oid" "$cur")"
  fi
  # Historical rows are never dropped: appended verbatim whenever present.
  if [[ "$ncur" -gt 0 && "$nhist" -gt 0 ]]; then
    detail="$detail ; earlier revision(s) preserved: $(render_rows "$oid" "$hist")"
  fi
  # baseline — every record evaluated; conflicts and gaps stay unsupported
  bitems="$tmp/base-$oid"
  awk -F'\t' -v k="$oid" '$1==k' "$tmp/base.only" > "$bitems"
  nb="$(wc -l < "$bitems" | tr -d ' ')"
  if [[ "$nb" -eq 0 ]]; then
    detail="$detail ; baseline: NOT FOUND ; comparison: unsupported"
  elif [[ "$(cut -f2 "$bitems" | sort -u | awk 'NF' | wc -l | tr -d ' ')" -gt 1 ]]; then
    detail="$detail ; baseline: conflicting observations: $(render_rows "$oid" "$bitems") ; comparison: unsupported"
  elif has_nc "$oid" "$bitems"; then
    detail="$detail ; baseline: $(render_rows "$oid" "$bitems") ; comparison: unsupported"
  elif [[ "$status" == "observed" ]]; then
    pgaps="$(pairwise_gap 10 sampling "$cur" "$bitems")"
    cg="$(pairwise_gap 11 conditions "$cur" "$bitems")"
    [[ -n "$cg" ]] && pgaps="${pgaps:+$pgaps, }$cg"
    if [[ -n "$pgaps" ]]; then
      detail="$detail ; baseline: $(render_rows "$oid" "$bitems") ; comparison: unsupported — insufficient comparability information: $pgaps"
    else
      detail="$detail ; baseline: $(render_rows "$oid" "$bitems") ; comparison: supported"
    fi
  else
    detail="$detail ; baseline: $(render_rows "$oid" "$bitems") ; comparison: unsupported"
  fi
  printf '%s\t%s\t%s\t%s\n' "$oid" "$okind" "$status" "$detail" >> "$tmp/outcomes"
done < "$tmap"

# --- Receipt -------------------------------------------------------------------
rcp="$tmp/receipt.md"
{
  printf '# Outcome receipt — %s\n\n```contract\n' "$tid"
  printf 'id: receipt-%s\nkind: outcome-receipt\nschema_version: outcome-receipt/0.1.0\n' "$tid"
  printf 'intent_digest: %s\ntargets_digest: %s\nimplementation_rev: %s\nreevaluation: %s\n' \
    "$intent" "$targets_digest" "$impl_rev" "$reeval"
  printf 'contract_acceptance: %s\ntargets_acceptance: %s\n' \
    "$contract_acceptance" "$targets_acceptance"
  while IFS=$'\t' read -r oid okind status detail; do
    printf 'outcome: %s ; %s ; %s ; %s\n' "$oid" "$okind" "$status" "$detail"
  done < "$tmp/outcomes"
  { grep '^LESSON' "$tmp/ev.map" 2>/dev/null || true; } | while IFS=$'\t' read -r _ l; do
    printf 'lesson: %s ; status:candidate\n' "$l"
  done
  printf '```\n\n'
  for kind in product process; do
    case "$kind" in product) h=Product;; process) h=Process;; esac
    printf '## %s outcomes\n\n' "$h"
    while IFS=$'\t' read -r oid okind status detail; do
      [[ "$okind" == "$kind" ]] || continue
      printf -- '- **%s — %s**: %s\n' "$oid" "$status" "$detail"
    done < "$tmp/outcomes"
    printf '\n'
  done
  if grep -q '^LESSON' "$tmp/ev.map" 2>/dev/null; then
    printf '## Candidate lessons (human review required — not confirmations)\n\n'
    grep '^LESSON' "$tmp/ev.map" | while IFS=$'\t' read -r _ l; do printf -- '- %s\n' "$l"; done
    printf '\n'
  fi
  printf '## Gaps\n\n'
  gap=0
  while IFS=$'\t' read -r oid _k status _d; do
    [[ "$status" == "missing" ]] && { printf -- '- %s: evidence NOT FOUND\n' "$oid"; gap=1; }
  done < "$tmp/outcomes"
  [[ "$gap" -eq 0 ]] && printf -- '- (none)\n'
} > "$rcp"

# --- Destination ----------------------------------------------------------------
# Reuse the S8 destination checks: canonicalize the COMPLETE destination —
# every ancestor via canon_dir, and the final component itself when it exists
# (a symlink to a directory or file inside the inspected repository resolves
# there before isolation is enforced). Directories are not writable receipts;
# dangling links fail closed rather than materializing an unreviewed path.
root_canon="$(canon_dir "$inputs_root")"
outdir="$(dirname "$out")"
[[ -d "$outdir" ]] || err "destination directory does not exist: $outdir" 4
[[ -L "$out" && ! -e "$out" ]] \
  && err "refused — dangling symlink at destination: $out" 4
[[ -d "$out" ]] && err "refused — destination is a directory: $out" 4
if [[ -e "$out" ]]; then
  out_canon="$(canon_any "$out")"
else
  out_canon="$(canon_dir "$outdir")/$(basename "$out")"
fi
if is_within "$out_canon" "$root_canon"; then
  err "refused — receipt destination is inside the inspected repository: $out" 4
fi
if [[ -f "$out" ]]; then
  if cmp -s "$rcp" "$out"; then
    printf 'SAME %s\n' "$out"; cat "$rcp"; exit 0
  fi
  err "refused — existing differing file at destination preserved: $out" 4
fi
cp "$rcp" "$out"
printf 'CREATE %s\n\n' "$out"
cat "$rcp"
