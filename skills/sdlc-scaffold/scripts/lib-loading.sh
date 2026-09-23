# Shared loading-rule checks — emit-style functions used by the exporter's
# staged validation and by tests/test_loading_rules.sh.
# Each check_FN FILE prints "  FAIL file:kind:msg" lines; callers count.
# Requires lib-contract.sh to be sourced first.
#
# CLIENT_ROOT (optional env): when set, a path-valued reference that does not
# resolve relative to the declaring file is tried against CLIENT_ROOT — the
# client-repository reference class of proposal §12.4. Exported proposals
# carry client-root-relative entries that only resolve there.

# runtime_exempt PATH — runtime artifact paths and placeholders can never
# resolve at authoring time; the exemption is declared once here and applies
# to both prose references and contract context fields.
runtime_exempt() {
  case "$1" in
    changes/*|output/*|*\{*) return 0 ;;
    *) return 1 ;;
  esac
}

# resolve_ref DIR PATH — exit 0 if PATH resolves to a file relative to DIR,
# or (when CLIENT_ROOT is set) relative to the client repository root.
resolve_ref() {
  local dir="$1" p="$2"
  [[ -e "$dir/$p" ]] && return 0
  [[ -n "${CLIENT_ROOT:-}" && -e "$CLIENT_ROOT/$p" ]] && return 0
  return 1
}

# ref_is_dir DIR PATH — exit 0 if PATH resolves to a directory by either rule.
ref_is_dir() {
  local dir="$1" p="$2"
  [[ -d "$dir/$p" ]] && return 0
  [[ -n "${CLIENT_ROOT:-}" && -d "$CLIENT_ROOT/$p" ]] && return 0
  return 1
}

# check_refs FILE — backtick-quoted relative paths in prose must resolve,
# unless runtime exempt (changes/, output/, {placeholder}, version strings).
check_refs() {
  local file="$1" dir; dir="$(dirname "$file")"
  local p
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    runtime_exempt "$p" && continue
    [[ "$p" == */[0-9]* ]] && continue  # namespaced version strings, e.g. workflow-contract/0.1.0
    if ! resolve_ref "$dir" "$p"; then
      printf '  FAIL %s:ref:referenced path %s does not resolve\n' "$file" "'$p'"
    elif ref_is_dir "$dir" "$p"; then
      printf '  FAIL %s:ref:%s is a directory — whole-directory loads are not allowed\n' "$file" "'$p'"
    fi
  done < <(body_without_blocks "$file" | grep -oE '`[^`]+`' | tr -d '`' \
           | grep -E '/|\.\w+$' || true)
}

# check_context_fields FILE — path-valued context_entry items must resolve
# relative to the declaring file (or the client root); entry∩never conflicts
# are contradictory contracts.
check_context_fields() {
  local file="$1" dir; dir="$(dirname "$file")"
  local tmp; tmp="$(mktemp -d)"
  extract_blocks_to "$file" "$tmp"
  local b ent nev item
  for b in "$tmp"/*.contract; do
    [[ -f "$b" ]] || continue
    ent="$(block_value "$b" context_entry)"
    nev="$(block_value "$b" context_never)"
    local OLDIFS="$IFS"; IFS='|'
    for item in $ent; do
      IFS="$OLDIFS"; item="$(trim "$item")"; IFS='|'
      [[ -z "$item" || "$item" == "none" ]] && continue
      # A required entry point that is also a hard exclusion is a
      # contradictory contract — fail regardless of whether it resolves.
      if list_contains "$nev" "$item"; then
        printf '  FAIL %s:context:%s is both context_entry and context_never\n' "$file" "'$item'"
        continue
      fi
      # Path-valued entries (contain '/') resolve relative to the declaring
      # file or the client root. Entries without '/' are named resources
      # (schema §5). Runtime artifact paths are exempt by the shared rule.
      [[ "$item" == */* ]] || continue
      runtime_exempt "$item" && continue
      if ! resolve_ref "$dir" "$item"; then
        printf '  FAIL %s:context_entry:entry path %s does not resolve relative to %s%s\n' \
          "$file" "'$item'" "$dir" "${CLIENT_ROOT:+ or client root}"
      elif ref_is_dir "$dir" "$item"; then
        printf '  FAIL %s:context_entry:entry %s is a directory — whole-directory loads are not allowed\n' "$file" "'$item'"
      fi
    done
    IFS="$OLDIFS"
  done
  rm -rf "$tmp"
}

# check_never FILE — context_never paths must not be referenced in prose.
check_never() {
  local file="$1" tmp; tmp="$(mktemp -d)"
  extract_blocks_to "$file" "$tmp"
  local b nev item
  for b in "$tmp"/*.contract; do
    [[ -f "$b" ]] || continue
    nev="$(block_value "$b" context_never)"
    local OLDIFS="$IFS"; IFS='|'
    for item in $nev; do
      IFS="$OLDIFS"; item="$(trim "$item")"; IFS='|'
      [[ "$item" == */* ]] || continue
      body_without_blocks "$file" | grep -qF "$item" \
        && printf '  FAIL %s:context_never:prose references excluded path %s\n' "$file" "'$item'"
    done
    IFS="$OLDIFS"
  done
  rm -rf "$tmp"
}
