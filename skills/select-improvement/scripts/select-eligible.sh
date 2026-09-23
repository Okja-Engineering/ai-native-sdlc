#!/usr/bin/env bash
set -euo pipefail

# select-eligible.sh CARDS_DIR FACTS_FILE — deterministic improvement
# selector (proposal §13). Reads selection-card/0.1.0 blocks under CARDS_DIR
# and an owner-facts/0.1.0 file, then prints a report:
#   eligible-and-ready / applicable-blocked / inapplicable / unknown /
#   conflicted / missing-fact gaps.
# Exit 0 on a completed report, 2 on input/validation failure, 3 on a
# dependency-graph error (missing target or cycle). Performs no writes
# outside its temp dir and never labels a candidate accepted.

here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../../sdlc-scaffold/scripts/lib-contract.sh"

cards_dir="${1:-}"
facts_file="${2:-}"
[[ -d "$cards_dir" && -f "$facts_file" ]] || {
  printf 'usage: select-eligible.sh CARDS_DIR FACTS_FILE\n' >&2; exit 2; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
err() { printf 'select: %s\n' "$1" >&2; exit "${2:-2}"; }

# --- Owner facts -------------------------------------------------------------
if ! serr="$(check_structure "$facts_file" "fact" 2>&1)"; then
  printf 'select: %s\n' "$serr" >&2; exit 2
fi
mkdir -p "$tmp/fb"; extract_blocks_to "$facts_file" "$tmp/fb"
fblocks=("$tmp/fb"/*.contract)
[[ -f "${fblocks[0]}" && "${#fblocks[@]}" -eq 1 ]] \
  || err "facts file must contain exactly one contract block"
fb="${fblocks[0]}"
[[ "$(block_value "$fb" kind)" == "owner-facts" ]] \
  || err "facts block kind must be owner-facts"
[[ "$(block_value "$fb" schema_version)" == "owner-facts/0.1.0" ]] \
  || err "unsupported owner-facts schema_version"

# fact map rows: ID \t STATE \t VALUE \t SOURCE
fmap="$tmp/facts.map"; : > "$fmap"
while IFS= read -r item; do
  [[ "$item" == "none" || -z "$item" ]] && continue
  # grammar: ID = VALUE ; SOURCE ; STATE
  printf '%s' "$item" | grep -qE '^[A-Za-z0-9][A-Za-z0-9_-]* = [^;]+ ; [^;]+ ; (established|unknown|conflicted)$' \
    || err "malformed fact item: '$item' (expected 'ID = VALUE ; SOURCE ; STATE')"
  fid="$(trim "${item%% =*}")"
  rest="${item#* = }"
  fval="$(trim "${rest%% ;*}")"
  fsrc="$(trim "$(printf '%s' "$rest" | awk -F' ; ' '{print $2}')")"
  fstate="$(trim "${rest##* ; }")"
  [[ -n "$fval" && -n "$fsrc" ]] \
    || err "fact '$fid' has an empty value or source"
  printf '%s' "$fsrc" | grep -qE '^(obs|interview|path|owner):[^ ;]+$' \
    || err "fact '$fid' source '$fsrc' is not a documented locator (obs:|interview:|path:|owner:)"
  if [[ "$fstate" == "established" ]]; then
    [[ "$fval" != "-" ]] || err "fact '$fid' is established but carries no explicit value"
  else
    [[ "$fval" == "-" ]] || err "fact '$fid' with state $fstate must carry value '-'"
  fi
  map_has "$fmap" "$fid" \
    && err "fact '$fid' declared twice — incompatible states are a validation failure, not first-match"
  printf '%s\t%s\t%s\t%s\n' "$fid" "$fstate" "$fval" "$fsrc" >> "$fmap"
done < <(block_items "$fb" fact)

fact_state() { map_get "$fmap" "$1" 2; }
fact_value() { map_get "$fmap" "$1" 3; }
fact_source() { map_get "$fmap" "$1" 4; }
fact_evidence() { # ID — 'ID = VALUE [STATE · SRC]' provenance line
  printf '%s = %s [%s · %s]' "$1" "$(fact_value "$1")" "$(fact_state "$1")" "$(fact_source "$1")"
}
fact_present() { [[ -n "$(fact_state "$1")" ]]; }

# --- Cards -------------------------------------------------------------------
# card map rows: ID \t BLOCKFILE \t TITLE \t RESEARCH_CARD \t RESEARCH_STATUS
cmap="$tmp/cards.map"; : > "$cmap"
deps="$tmp/deps"; : > "$deps"
while IFS= read -r cf; do
  if ! serr="$(check_structure "$cf" "applies_when requires_capability depends_on" 2>&1)"; then
    printf 'select: %s: %s\n' "$cf" "$serr" >&2; exit 2
  fi
  cdir="$(mktemp -d "$tmp/card.XXXX")"
  extract_blocks_to "$cf" "$cdir"
  cb=("$cdir"/*.contract)
  [[ -f "${cb[0]}" && "${#cb[@]}" -eq 1 ]] \
    || err "card file $cf must contain exactly one contract block"
  b="${cb[0]}"
  [[ "$(block_value "$b" kind)" == "selection-card" ]] \
    || err "$cf: block kind must be selection-card"
  [[ "$(block_value "$b" schema_version)" == "selection-card/0.1.0" ]] \
    || err "$cf: unsupported selection-card schema_version"
  for k in id title practice research_card research_path research_status applies_when requires_capability depends_on status; do
    block_has "$b" "$k" || err "$cf: missing field '$k'"
  done
  [[ "$(block_value "$b" status)" == "proposed" ]] \
    || err "$cf: status must be proposed — the selector never accepts"
  cid="$(block_value "$b" id)"
  map_has "$cmap" "$cid" && err "duplicate card id '$cid'"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$cid" "$b" \
    "$(block_value "$b" title)" "$(block_value "$b" research_card)" \
    "$(block_value "$b" research_status)" "$(block_value "$b" research_path)" >> "$cmap"
  # Predicate grammar is exactly 'ID = value' — no fuzzy operators.
  for field in applies_when requires_capability; do
    while IFS= read -r p; do
      [[ "$p" == "none" || -z "$p" ]] && continue
      printf '%s' "$p" | grep -qE '^[A-Za-z0-9][A-Za-z0-9_-]* = [^;=]+$' \
        || err "$cf: unsupported predicate syntax in $field: '$p' (expected 'FACT-ID = value')"
    done < <(block_items "$b" "$field")
  done
  while IFS= read -r d; do
    [[ "$d" == "none" || -z "$d" ]] && continue
    printf '%s' "$d" | grep -qE '^[A-Za-z0-9][A-Za-z0-9_-]*$' \
      || err "$cf: depends_on entries must be card ids, found '$d'"
    printf '%s\t%s\n' "$cid" "$d" >> "$deps"
  done < <(block_items "$b" depends_on)
done < <(find "$cards_dir" -type f -name '*.md' | sort)
[[ -s "$cmap" ]] || err "no selection cards found in $cards_dir"

# Missing dependency targets and cycles are graph errors, not ineligibility.
while IFS=$'\t' read -r c d; do
  map_has "$cmap" "$d" || err "card '$c' depends on unknown card '$d'" 3
done < "$deps"

# Kahn removal: emit cards whose remaining deps are all emitted; a non-empty
# leftover means a cycle.
cut -f1 "$cmap" | sort > "$tmp/nodes.left"
while [[ -s "$tmp/nodes.left" ]]; do
  : > "$tmp/emitted"
  while IFS= read -r n; do
    if ! awk -F'\t' -v n="$n" 'NR==FNR{live[$1]=1;next} $1==n && live[$2]{f=1} END{exit !f}' \
         "$tmp/nodes.left" "$deps"; then
      printf '%s\n' "$n" >> "$tmp/emitted"
    fi
  done < "$tmp/nodes.left"
  [[ -s "$tmp/emitted" ]] || break
  grep -vxF -f "$tmp/emitted" "$tmp/nodes.left" > "$tmp/nodes.next" || true
  mv "$tmp/nodes.next" "$tmp/nodes.left"
done
[[ ! -s "$tmp/nodes.left" ]] \
  || err "dependency cycle among cards: $(tr '\n' ' ' < "$tmp/nodes.left")" 3

# --- Evaluation ---------------------------------------------------------------
# Per applies_when/requires_capability item 'ID = want': established with a
# different value is decisive (inapplicable/blocked); conflicted or
# unknown/absent is not. Bucket precedence: inapplicable > conflicted >
# unknown. requires_capability gates readiness; depends_on requires an
# established 'CARD-ID = adopted' fact — selection is not implementation.
eval_pred() { # PRED -> prints "state<TAB>reason"; state: ok|false|conflicted|unknown
  local p="$1" fid want st got
  fid="$(trim "${p%% =*}")"; want="$(trim "${p#*= }")"
  st="$(fact_state "$fid")"; got="$(fact_value "$fid")"
  case "$st" in
    established)
      if [[ "$got" == "$want" ]]; then printf 'ok';
      else printf 'false\t%s established %s != required %s' "$fid" "'$got'" "'$want'"; fi ;;
    conflicted) printf 'conflicted\t%s conflicted' "$fid" ;;
    *)          printf 'unknown\t%s not established' "$fid" ;;
  esac
}

: > "$tmp/final.map"; : > "$tmp/gaps"
while IFS=$'\t' read -r cid b title rcard rstatus; do
  res_false=0 res_conf=0 res_unk=0 reasons=""
  while IFS= read -r p; do
    [[ "$p" == "none" || -z "$p" ]] && continue
    IFS=$'\t' read -r st rsn <<< "$(eval_pred "$p")"
    fact_present "$(trim "${p%% =*}")" \
      && printf 'fact: %s\n' "$(fact_evidence "$(trim "${p%% =*}")")" >> "$tmp/prov-$cid"
    case "$st" in
      ok) ;;
      false)      res_false=1; reasons="$reasons; $rsn" ;;
      conflicted) res_conf=1;  reasons="$reasons; $rsn" ;;
      unknown)    res_unk=1;   reasons="$reasons; $rsn"
                  printf '%s\t%s\n' "$(trim "${p%% =*}")" "$cid" >> "$tmp/gaps" ;;
    esac
  done < <(block_items "$b" applies_when)
  if [[ "$res_false" -eq 1 ]]; then bucket=inapplicable
  elif [[ "$res_conf" -eq 1 ]]; then bucket=conflicted
  elif [[ "$res_unk" -eq 1 ]]; then bucket=unknown
  else bucket=ready
  fi
  if [[ "$bucket" == "ready" ]]; then
    while IFS= read -r p; do
      [[ "$p" == "none" || -z "$p" ]] && continue
      IFS=$'\t' read -r st rsn <<< "$(eval_pred "$p")"
      fact_present "$(trim "${p%% =*}")" \
        && printf 'capability: %s\n' "$(fact_evidence "$(trim "${p%% =*}")")" >> "$tmp/prov-$cid"
      case "$st" in
        ok) ;;
        *)  bucket=blocked; reasons="$reasons; capability: $rsn"
            [[ "$st" == "unknown" ]] && printf '%s\t%s\n' "$(trim "${p%% =*}")" "$cid" >> "$tmp/gaps" ;;
      esac
    done < <(block_items "$b" requires_capability)
    while IFS=$'\t' read -r c d; do
      [[ "$c" == "$cid" ]] || continue
      dst="$(fact_state "$d")"; dval="$(fact_value "$d")"
      fact_present "$d" \
        && printf 'adoption: %s\n' "$(fact_evidence "$d")" >> "$tmp/prov-$cid"
      if [[ "$dst" == "established" && "$dval" == "adopted" ]]; then
        continue
      fi
      bucket=blocked
      case "$dst" in
        established)
          reasons="$reasons; prerequisite $d adoption fact established '$dval' != 'adopted' (selection is not implementation)" ;;
        conflicted)
          reasons="$reasons; prerequisite $d adoption evidence conflicted (selection is not implementation)" ;;
        *)
          reasons="$reasons; prerequisite $d not adopted — adoption fact '$d = adopted' not established (selection is not implementation)"
          printf '%s\t%s\n' "$d = adopted" "$cid" >> "$tmp/gaps" ;;
      esac
    done < "$deps"
  fi
  printf '%s\t%s\t%s\n' "$cid" "$bucket" "${reasons#; }" >> "$tmp/final.map"
done < "$cmap"

# --- Report --------------------------------------------------------------------
line_for() { # CID -> display line with provenance
  local cid="$1" title rcard rstatus rpath prov
  title="$(map_get "$cmap" "$cid" 3)"
  rcard="$(map_get "$cmap" "$cid" 4)"
  rstatus="$(map_get "$cmap" "$cid" 5)"
  rpath="$(map_get "$cmap" "$cid" 6)"
  prov="$rcard, $rpath"
  [[ "$rstatus" != "reviewed" ]] && prov="$prov (provisional: $rstatus)"
  printf '%s — %s  [%s]' "$cid" "$title" "$prov"
}

section() { # TITLE BUCKET
  printf '\n%s:\n' "$1"
  local any=0 cid rb reasons
  while IFS=$'\t' read -r cid rb reasons; do
    [[ "$rb" == "$2" ]] || continue
    any=1
    printf '  %s\n' "$(line_for "$cid")"
    [[ -s "$tmp/prov-$cid" ]] && sed 's/^/      /' "$tmp/prov-$cid"
    [[ -n "$reasons" ]] && printf '      %s\n' "${reasons//; /$'\n'      }"
  done < "$tmp/final.map"
  if [[ "$any" -eq 0 ]]; then printf '  (none)\n'; fi
}

printf 'selection report\n================\n'
printf 'cards: %s   facts: %s\n' "$(wc -l < "$cmap" | tr -d ' ')" "$(wc -l < "$fmap" | tr -d ' ')"
section "eligible and ready" ready
section "applicable — blocked on prerequisites or capabilities" blocked
section "inapplicable" inapplicable
section "unknown" unknown
section "conflicted" conflicted
printf '\nmissing-fact gaps:\n'
if [[ -s "$tmp/gaps" ]]; then
  sort -u "$tmp/gaps" | while IFS=$'\t' read -r fid cid; do
    printf '  %s (needed by %s)\n' "$fid" "$cid"
  done
else
  printf '  (none)\n'
fi
