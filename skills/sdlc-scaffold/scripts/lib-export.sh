# Export helpers — block collection, reference relocation, and rendering for
# export-proposal.sh (proposal §12). Requires lib-contract.sh and
# lib-loading.sh sourced first.
#
# Reference classes (§12.4):
#   runtime-artifact    changes/*, output/*, {placeholder} — resolves at run time
#   named-resource      no '/' — a name, not a path
#   bundled             resolves relative to the declaring file in the input —
#                       copied to the same declaring-file-relative path in the
#                       exported package so the contract text stays verbatim
#   client-repository   resolves under the client root — kept verbatim; the
#                       proposal documents client-root-relative resolution
#   broken              resolves nowhere — preflight failure, nothing written

RENDERER_VERSION="export-proposal/0.1.0"

# canon_dir DIR — canonical absolute path of an existing directory.
canon_dir() { (cd "$1" && pwd -P); }

# canon_any PATH — canonical absolute path of an existing file or directory.
canon_any() {
  local p="$1"
  if [[ -d "$p" ]]; then canon_dir "$p";
  else printf '%s/%s' "$(canon_dir "$(dirname "$p")")" "$(basename "$p")"; fi
}

# is_within A B — exit 0 if canonical path A equals or sits under B.
is_within() { [[ "$1" == "$2" || "$1" == "$2/"* ]]; }

# check_dest REL OUT_ROOT — verify every existing component of OUT_ROOT/REL:
# symlinks must resolve to an existing target inside OUT_ROOT (a dangling
# link fails closed — writing through it would silently materialize a path
# the owner never created); existing non-final components must be
# directories. Prints the canonical destination path on success; refuses
# (nonzero) otherwise.
check_dest() {
  local rel="$1" root="$2" cur="$2" comp tgt
  local -a parts=()
  IFS='/' read -ra parts <<< "$rel"
  local i n="${#parts[@]}"
  for ((i = 0; i < n; i++)); do
    comp="${parts[$i]}"
    cur="$cur/$comp"
    if [[ -L "$cur" ]]; then
      if [[ ! -e "$cur" ]]; then
        printf 'export: refused — dangling symlink in destination path: %s\n' "$cur" >&2
        return 1
      fi
      tgt="$(readlink "$cur")"
      case "$tgt" in /*) ;; *) tgt="$(dirname "$cur")/$tgt" ;; esac
      tgt="$(canon_any "$tgt")"
      if ! is_within "$tgt" "$root"; then
        printf 'export: refused — destination escapes the proposal root via symlink: %s -> %s\n' "$cur" "$tgt" >&2
        return 1
      fi
      cur="$tgt"
    fi
    # Intermediate components must be directories: a regular file here is a
    # pre-existing conflict, not a writable path.
    if [[ $i -lt $((n - 1)) && -e "$cur" && ! -d "$cur" ]]; then
      printf 'export: refused — ancestor %s exists and is not a directory\n' "$cur" >&2
      return 1
    fi
  done
  printf '%s\n' "$cur"
}

# norm_relpath PATH — lexical normalization of a relative path (collapse
# `.` and `..`); exits 1 if `..` would escape the root.
norm_relpath() {
  awk -v p="$1" 'BEGIN{
    n=split(p,a,"/"); m=0
    for(i=1;i<=n;i++){
      s=a[i]
      if(s==""||s==".") continue
      if(s==".."){ if(m==0) exit 1; m--; continue }
      m++; st[m]=s
    }
    out=""; for(i=1;i<=m;i++){ out=out st[i]; if(i<m) out=out "/" }
    print out
  }'
}

# collect_contract_blocks CONTRACT_PATH TMPDIR — extract every ```contract
# block under PATH into TMPDIR and write TMPDIR/manifest.tsv rows:
# <block-file>\t<origin-file>.
collect_contract_blocks() {
  local path="$1" tmp="$2" i=0 f b
  : > "$tmp/manifest.tsv"
  if [[ -d "$path" ]]; then
    while IFS= read -r f; do
      i=$((i + 1))
      BLOCK_PREFIX="f$i" extract_blocks_to "$f" "$tmp"
      for b in "$tmp"/f$i-*.contract; do
        [[ -f "$b" ]] || continue
        printf '%s\t%s\n' "$b" "$f" >> "$tmp/manifest.tsv"
      done
    done < <(find "$path" -type f -name '*.md' | sort)
  else
    BLOCK_PREFIX="f1" extract_blocks_to "$path" "$tmp"
    for b in "$tmp"/f1-*.contract; do
      [[ -f "$b" ]] || continue
      printf '%s\t%s\n' "$b" "$path" >> "$tmp/manifest.tsv"
    done
  fi
}

# classify_ref ITEM ORIGIN_DIR CLIENT_ROOT — print the item's class; for
# bundled, print "bundled\t<canonical source path>".
classify_ref() {
  local item="$1" odir="$2" client="$3"
  if runtime_exempt "$item"; then printf 'runtime'; return; fi
  if [[ "$item" != */* ]]; then printf 'named'; return; fi
  if [[ -f "$odir/$item" ]]; then
    printf 'bundled\t%s/%s\n' "$(canon_dir "$(dirname "$odir/$item")")" "$(basename "$item")"
    return
  fi
  if [[ -f "$client/$item" ]]; then printf 'client'; return; fi
  printf 'broken'
}

# relocate_block BLOCKFILE ORIGINFILE DECLARING_REL FORM_JOBS REPORT
# Classify each context_entry item; append bundled copy jobs (src\tdest_rel)
# to FORM_JOBS and one report row per item to REPORT. Non-zero if broken.
relocate_block() {
  local bfile="$1" ofile="$2" drel="$3" jobs="$4" report="$5" client="$6"
  local id odir ent item cls src dest rc=0
  id="$(block_value "$bfile" id)"
  odir="$(canon_dir "$(dirname "$ofile")")"
  ent="$(block_value "$bfile" context_entry)"
  local OLDIFS="$IFS"; IFS='|'
  for item in $ent; do
    IFS="$OLDIFS"; item="$(trim "$item")"; IFS='|'
    [[ -z "$item" || "$item" == "none" ]] && continue
    cls="$(classify_ref "$item" "$odir" "$client")"
    case "$cls" in
      runtime)   printf '%s\t%s\t%s\t%s\n' "$id" "$item" "runtime-artifact" "verbatim (resolves at run time)" >> "$report" ;;
      named)     printf '%s\t%s\t%s\t%s\n' "$id" "$item" "named-resource" "verbatim" >> "$report" ;;
      client)    printf '%s\t%s\t%s\t%s\n' "$id" "$item" "client-repository" "verbatim (resolves at client root)" >> "$report" ;;
      bundled*)
        src="${cls#*$'\t'}"
        if dest="$(norm_relpath "${drel:+$drel/}$item")"; then
          printf '%s\t%s\n' "$src" "$dest" >> "$jobs"
          printf '%s\t%s\t%s\t%s\n' "$id" "$item" "bundled" "\`$dest\`" >> "$report"
        else
          printf '%s\t%s\t%s\t%s\n' "$id" "$item" "broken" "path escapes package root" >> "$report"
          rc=1
        fi
        ;;
      *)         printf '%s\t%s\t%s\t%s\n' "$id" "$item" "broken" "resolves in neither input nor client root" >> "$report"; rc=1 ;;
    esac
  done
  IFS="$OLDIFS"
  return $rc
}

# join_display LIST — render a `|`-separated contract list for prose display.
join_display() { printf '%s' "$1" | sed 's/ *| */, /g'; }

# emit_report FORMDIR FORM DIGEST REPORT_TSV — write EXPORT-REPORT.md.
emit_report() {
  local fdir="$1" form="$2" digest="$3" tsv="$4"
  {
    printf '# Export report — %s\n\n' "$form"
    printf 'renderer: %s\n' "$RENDERER_VERSION"
    printf 'contract_digest: sha256:%s\n' "$digest"
    printf 'form: %s\n\n' "$form"
    printf 'Reviewable proposal only. Applying it to the client repository is a\n'
    printf 'separate authorized step; this export grants no installation,\n'
    printf 'merge, deployment, or publication authority.\n\n'
    printf '## Reference relocation\n\n'
    printf '| Declaring block | Entry | Class | Resolution |\n'
    printf '|---|---|---|---|\n'
    if [[ -s "$tsv" ]]; then
      while IFS=$'\t' read -r bid item cls res; do
        printf '| %s | %s | %s | %s |\n' "$bid" "$item" "$cls" "$res"
      done < "$tsv"
    else
      printf '| — | — | none declared | — |\n'
    fi
  } > "$fdir/EXPORT-REPORT.md"
}

# emit_proposal_note — the standard proposal banner.
emit_proposal_note() {
  local digest="$1"
  printf '> Exported proposal rendered by %s from contract digest\n' "$RENDERER_VERSION"
  printf '> sha256:%s. Reviewable proposal only — applying it to a repository is\n' "$digest"
  printf '> a separate authorized step. It never merges, deploys, implements, or\n'
  printf '> promotes learning.\n\n'
}

# emit_loading_rules — the fixed loading-rule boilerplate.
emit_loading_rules() {
  printf '## Loading rules\n\n'
  printf -- '- Always: this file.\n'
  printf -- '- On entering a stage: its `context_entry` items only.\n'
  printf -- '- Exploration: within `context_explore` scope; a discovered contradiction\n'
  printf '  stops the stage and surfaces for a human.\n'
  printf -- '- Never: `context_never` items.\n\n'
}

# stage_heading ID — "## 01-intent" style heading text from a stage id.
stage_heading() { printf '%s' "$1"; }

# render_compact WF_BLOCK IDMAP STAGE_ORDER FORMDIR DIGEST
# IDMAP rows: <stage-id>\t<block-file>\t<origin-file>; STAGE_ORDER: one id
# per line in declared order. Writes FORMDIR/SDLC.md.
render_compact() {
  local wfb="$1" idmap="$2" order="$3" fdir="$4" digest="$5"
  local wf_id sid bfile kind decides decisions purpose
  wf_id="$(block_value "$wfb" id)"
  {
    printf '# %s — compact workflow proposal\n\n' "$wf_id"
    emit_proposal_note "$digest"
    printf '```contract\n'; cat "$wfb"; printf '```\n\n'
    printf '## Route by stage\n\n'
    printf '| Stage | Kind | Decides | Decisions |\n|---|---|---|---|\n'
    while IFS= read -r sid; do
      bfile="$(awk -F'\t' -v k="$sid" '$1==k{print $2; exit}' "$idmap")"
      kind="$(block_value "$bfile" kind)"
      decides="$(block_value "$bfile" decides)"
      decisions="$(join_display "$(block_value "$bfile" decisions)")"
      printf '| %s | %s | %s | %s |\n' "$sid" "$kind" "$decides" "$decisions"
    done < "$order"
    printf '\n'
    emit_loading_rules
    printf '## Stages\n'
    while IFS= read -r sid; do
      bfile="$(awk -F'\t' -v k="$sid" '$1==k{print $2; exit}' "$idmap")"
      kind="$(block_value "$bfile" kind)"
      purpose="$(block_value "$bfile" purpose)"
      printf '\n### %s (%s)\n\n' "$sid" "$kind"
      printf '%s\n\n' "$purpose"
      printf '```contract\n'; cat "$bfile"; printf '```\n'
    done < "$order"
  } > "$fdir/SDLC.md"
}

# render_modular WF_BLOCK IDMAP STAGE_ORDER FORMDIR DIGEST
# Writes ROUTER.md, CONTEXT.md, stages/<id>/CONTEXT.md.
render_modular() {
  local wfb="$1" idmap="$2" order="$3" fdir="$4" digest="$5"
  local wf_id sid bfile kind purpose decides decisions in_item out_item
  wf_id="$(block_value "$wfb" id)"
  {
    printf '# %s — workflow router (modular proposal)\n\n' "$wf_id"
    emit_proposal_note "$digest"
    printf '```contract\n'; cat "$wfb"; printf '```\n\n'
    printf '## Route by stage\n\n'
    printf '| Stage | Load |\n|---|---|\n'
    while IFS= read -r sid; do
      printf '| %s | `stages/%s/CONTEXT.md` |\n' "$sid" "$sid"
    done < "$order"
    printf '\n'
    emit_loading_rules
  } > "$fdir/ROUTER.md"
  {
    printf '# %s — task routing\n\n' "$wf_id"
    printf 'Route each task to the smallest stage contract needed.\n\n'
    printf '| Stage | Stage contract | Decides | Decisions |\n|---|---|---|---|\n'
    while IFS= read -r sid; do
      bfile="$(awk -F'\t' -v k="$sid" '$1==k{print $2; exit}' "$idmap")"
      decides="$(block_value "$bfile" decides)"
      decisions="$(join_display "$(block_value "$bfile" decisions)")"
      printf '| %s | `stages/%s/CONTEXT.md` | %s | %s |\n' "$sid" "$sid" "$decides" "$decisions"
    done < "$order"
  } > "$fdir/CONTEXT.md"
  while IFS= read -r sid; do
    bfile="$(awk -F'\t' -v k="$sid" '$1==k{print $2; exit}' "$idmap")"
    kind="$(block_value "$bfile" kind)"
    purpose="$(block_value "$bfile" purpose)"
    decides="$(block_value "$bfile" decides)"
    decisions="$(join_display "$(block_value "$bfile" decisions)")"
    mkdir -p "$fdir/stages/$sid"
    {
      printf '# Stage %s (%s)\n\n' "$sid" "$kind"
      printf '%s\n\n' "$purpose"
      printf '```contract\n'; cat "$bfile"; printf '```\n\n'
      printf '## Inputs\n\n| Item | Provenance |\n|---|---|\n'
      while IFS= read -r in_item; do
        [[ "$in_item" == "none" ]] && { printf '| none | — |\n'; continue; }
        printf '| %s | %s |\n' "${in_item%@*}" "${in_item##*@}"
      done < <(block_items "$bfile" inputs)
      printf '\n## Outputs\n\n'
      while IFS= read -r out_item; do
        [[ "$out_item" == "none" ]] && { printf -- '- none\n'; continue; }
        case "$out_item" in
          */*) printf -- '- `%s`\n' "$out_item" ;;
          *)   printf -- '- %s\n' "$out_item" ;;
        esac
      done < <(block_items "$bfile" outputs)
      printf '\n## Human check\n\n'
      printf 'Decides: %s. Allowed decisions: %s. The stage output must carry the\n' "$decides" "$decisions"
      printf 'declared review fields; only an explicit decision by that role advances.\n'
    } > "$fdir/stages/$sid/CONTEXT.md"
  done < "$order"
}
