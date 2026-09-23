#!/usr/bin/env bash
set -euo pipefail

# export-proposal.sh — render an accepted workflow contract into compact
# and/or modular proposal files under a separate output root (proposal §12).
#
#   --input PATH       contract instance (a compact .md file or a modular dir)
#   --acceptance PATH  sibling contract-acceptance record for that contract
#   --client DIR       client repository root the proposal describes
#   --output DIR       proposal destination (must exist; must not overlap the
#                      input or client roots, symlink-resolved)
#   --form FORM        compact | modular | both
#
# Pipeline: acceptance gate -> contract validation -> render to staging ->
# staged validation (contract + loading rules) -> destination preflight ->
# publish. Any failure before publish writes nothing. A destination conflict
# (REFUSE) also writes nothing — the check is all-or-nothing, which is NOT
# crash-safe atomicity: a write failure mid-publish can leave a partial
# package; rerunning converges because CREATE/SAME are idempotent. Reports
# name which files were written and which remain.

here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib-contract.sh"
. "$here/lib-loading.sh"
. "$here/lib-export.sh"

usage() {
  printf 'usage: export-proposal.sh --input PATH --acceptance PATH --client DIR --output DIR --form compact|modular|both\n' >&2
  exit 2
}

input="" acceptance="" client="" output="" form=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)      input="${2:-}"; shift 2 ;;
    --acceptance) acceptance="${2:-}"; shift 2 ;;
    --client)     client="${2:-}"; shift 2 ;;
    --output)     output="${2:-}"; shift 2 ;;
    --form)       form="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done
[[ -n "$input" && -n "$acceptance" && -n "$client" && -n "$output" && -n "$form" ]] || usage
case "$form" in compact|modular|both) ;; *) usage ;; esac
[[ -e "$input" ]]      || { printf 'export: input contract not found: %s\n' "$input" >&2; exit 2; }
[[ -d "$client" ]]     || { printf 'export: client root not a directory: %s\n' "$client" >&2; exit 2; }
[[ -d "$output" ]]     || { printf 'export: output root not a directory: %s\n' "$output" >&2; exit 2; }
[[ -f "$acceptance" ]] || { printf 'export: acceptance record not a file: %s\n' "$acceptance" >&2; exit 2; }

# --- Root isolation (symlink-resolved) -------------------------------------
in_path="$(canon_any "$input")"
if [[ -d "$input" ]]; then in_root="$in_path"; else in_root="$(canon_dir "$(dirname "$input")")"; fi
client_root="$(canon_dir "$client")"
out_root="$(canon_dir "$output")"

overlap=""
is_within "$out_root" "$in_root"     && overlap="output root is inside the input root"
is_within "$in_root" "$out_root"     && overlap="input root is inside the output root"
is_within "$out_root" "$client_root" && overlap="output root is inside the client repository"
is_within "$client_root" "$out_root" && overlap="client repository is inside the output root"
if [[ -n "$overlap" ]]; then
  printf 'export: refused — %s (symlink-resolved)\n' "$overlap" >&2
  exit 2
fi

# --- Gates: acceptance record, then contract validity ----------------------
"$here/check-acceptance.sh" "$in_path" "$acceptance" || {
  printf 'export: refused — contract is not accepted\n' >&2; exit 1; }
"$here/validate-workflow-contract.sh" "$in_path" || {
  printf 'export: refused — contract failed validation\n' >&2; exit 1; }

digest="$("$here/normalize-workflow.sh" "$in_path" | shasum -a 256 | awk '{print $1}')"

# --- Collect blocks --------------------------------------------------------
btmp="$(mktemp -d)"; staging="$(mktemp -d)"
trap 'rm -rf "$btmp" "$staging"' EXIT
collect_contract_blocks "$in_path" "$btmp"

wf_block=""
: > "$btmp/idmap.tsv"
while IFS=$'\t' read -r bfile ofile; do
  id="$(block_value "$bfile" id)"
  kind="$(block_value "$bfile" kind)"
  if [[ "$kind" == "workflow" ]]; then wf_block="$bfile"; continue; fi
  printf '%s\t%s\t%s\n' "$id" "$bfile" "$ofile" >> "$btmp/idmap.tsv"
done < "$btmp/manifest.tsv"
[[ -n "$wf_block" ]] || { printf 'export: no workflow block\n' >&2; exit 1; }

block_items "$wf_block" stages > "$btmp/stage-order"
# Stage ids become directory names; refuse anything that is not a safe slug.
while IFS= read -r sid; do
  [[ "$sid" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || {
    printf 'export: refused — stage id %s is not a safe path component\n' "'$sid'" >&2
    exit 1
  }
done < "$btmp/stage-order"

# --- Render each requested form into staging -------------------------------
reloc_rc=0
for f in compact modular; do
  [[ "$form" == "$f" || "$form" == "both" ]] || continue
  fdir="$staging/$f"; mkdir -p "$fdir"
  : > "$btmp/$f.jobs"; : > "$btmp/$f.report"
  # Declaring-file-relative destinations: compact emits SDLC.md at the form
  # root; modular emits ROUTER.md at root and stages/<id>/CONTEXT.md.
  case "$f" in
    compact) render_compact "$wf_block" "$btmp/idmap.tsv" "$btmp/stage-order" "$fdir" "$digest" ;;
    modular) render_modular "$wf_block" "$btmp/idmap.tsv" "$btmp/stage-order" "$fdir" "$digest" ;;
  esac
  # Relocate context_entry references: workflow block declares at form root,
  # stage blocks at "" (compact) or stages/<id> (modular).
  wf_origin="$(awk -F'\t' -v b="$wf_block" '$1==b{print $2}' "$btmp/manifest.tsv")"
  relocate_block "$wf_block" "$wf_origin" "" "$btmp/$f.jobs" "$btmp/$f.report" "$client_root" || reloc_rc=1
  while IFS=$'\t' read -r sid bfile ofile; do
    case "$f" in
      compact) drel="" ;;
      modular) drel="stages/$sid" ;;
    esac
    relocate_block "$bfile" "$ofile" "$drel" "$btmp/$f.jobs" "$btmp/$f.report" "$client_root" || reloc_rc=1
  done < "$btmp/idmap.tsv"
  # Perform bundled copies; identical-destination collisions must be identical
  # content, otherwise the relocation is ambiguous.
  if [[ -s "$btmp/$f.jobs" ]]; then
    sort -u "$btmp/$f.jobs" > "$btmp/$f.jobs.u"
    while IFS=$'\t' read -r src dest; do
      target="$fdir/$dest"
      if [[ -f "$target" ]] && ! cmp -s "$src" "$target"; then
        printf 'export: bundled reference collision at %s (different sources)\n' "$dest" >&2
        reloc_rc=1; continue
      fi
      mkdir -p "$(dirname "$target")"; cp "$src" "$target"
    done < "$btmp/$f.jobs.u"
  fi
  emit_report "$fdir" "$f" "$digest" "$btmp/$f.report"
done
if [[ "$reloc_rc" -ne 0 ]]; then
  printf 'export: refused — unrelocatable or conflicting references (see above)\n' >&2
  exit 1
fi

# --- Staged validation: contract + loading rules on the rendered package ---
stage_rc=0
for f in compact modular; do
  [[ "$form" == "$f" || "$form" == "both" ]] || continue
  "$here/validate-workflow-contract.sh" "$staging/$f" || stage_rc=1
  "$here/check-loading-rules.sh" "$staging/$f" --client "$client_root" || stage_rc=1
done
if [[ "$form" == "both" ]]; then
  "$here/normalize-workflow.sh" "$staging/compact" > "$btmp/c.norm"
  "$here/normalize-workflow.sh" "$staging/modular" > "$btmp/m.norm"
  if ! diff -q "$btmp/c.norm" "$btmp/m.norm" >/dev/null; then
    printf 'export: rendered forms are not semantically equivalent\n' >&2
    diff -u "$btmp/c.norm" "$btmp/m.norm" | head -20 || true
    stage_rc=1
  fi
fi
if [[ "$stage_rc" -ne 0 ]]; then
  printf 'export: refused — staged package failed validation; nothing written\n' >&2
  exit 1
fi

# --- Destination preflight: classify every file before writing any ---------
# Every destination path is verified through check_dest: symlinks must
# resolve inside the output root (dangling links fail closed), existing
# ancestors must be directories, and a directory at the file's own path is a
# conflict. Plan rows: <op>\t<rel>\t<staged-src>\t<canonical-dest-or-empty>.
if [[ "$form" == "both" ]]; then base="$staging"; else base="$staging/$form"; fi
: > "$btmp/plan"; refuses=0
while IFS= read -r f; do
  rel="${f#"$base"/}"
  if ! dest="$(check_dest "$rel" "$out_root")"; then
    printf 'UNSAFE\t%s\t%s\t\n' "$rel" "$f" >> "$btmp/plan"
    refuses=$((refuses + 1)); continue
  fi
  if [[ -d "$dest" ]]; then
    printf 'export: refused — destination is a directory: %s\n' "$dest" >&2
    printf 'UNSAFE\t%s\t%s\t%s\n' "$rel" "$f" "$dest" >> "$btmp/plan"
    refuses=$((refuses + 1)); continue
  fi
  if [[ ! -e "$dest" ]]; then
    printf 'CREATE\t%s\t%s\t%s\n' "$rel" "$f" "$dest" >> "$btmp/plan"
  elif cmp -s "$f" "$dest"; then
    printf 'SAME\t%s\t%s\t%s\n' "$rel" "$f" "$dest" >> "$btmp/plan"
  else
    printf 'REFUSE\t%s\t%s\t%s\n' "$rel" "$f" "$dest" >> "$btmp/plan"
    refuses=$((refuses + 1))
  fi
done < <(find "$base" -type f | sort)

if [[ "$refuses" -gt 0 ]]; then
  printf 'export: refused — %s destination conflict(s); destination unchanged\n' "$refuses" >&2
  while IFS=$'\t' read -r op rel src dest; do
    case "$op" in
      REFUSE)
        printf 'REFUSE %s (existing content differs; not overwritten)\n' "$rel"
        diff -u "$dest" "$src" | head -20 || true
        ;;
      UNSAFE)
        printf 'REFUSE %s (unsafe destination path; see above)\n' "$rel"
        ;;
    esac
  done < "$btmp/plan"
  exit 1
fi

# --- Publish: CREATE only; SAME untouched. Containment is rechecked per
# file immediately before writing. Not crash-atomic — see header -----------
written=0; failed=0
while IFS=$'\t' read -r op rel src dest; do
  case "$op" in
    SAME)   printf 'SAME %s\n' "$rel" ;;
    CREATE)
      if dest="$(check_dest "$rel" "$out_root")" \
         && mkdir -p "$(dirname "$dest")" && cp "$src" "$dest"; then
        printf 'CREATE %s\n' "$rel"; written=$((written + 1))
      else
        printf 'WRITE-FAIL %s\n' "$rel" >&2; failed=$((failed + 1))
      fi
      ;;
  esac
done < "$btmp/plan"
if [[ "$failed" -gt 0 ]]; then
  printf 'export: %s file(s) failed to write after %s succeeded; rerun to converge (publish is not atomic)\n' "$failed" "$written" >&2
  exit 3
fi
printf 'export: proposal written to %s (%s file(s) created)\n' "$out_root" "$written"
