# materialize SRC_DIR DST_DIR — copy a package tree without ever overwriting
# owner-authored content. Idempotent: a second run changes nothing.
# Prints one line per action:  CREATE path | SAME path | REFUSE path.
# Exit 3 if any REFUSE occurred.
# Test scaffolding for the export contract — not a shipped export tool.

materialize() {
  local src="$1" dst="$2"
  local refuses=0
  while IFS= read -r -d '' f; do
    local rel="${f#"$src"/}"
    local target="$dst/$rel"
    if [[ ! -f "$target" ]]; then
      mkdir -p "$(dirname "$target")"
      cp "$f" "$target"
      printf 'CREATE %s\n' "$rel"
    elif cmp -s "$f" "$target"; then
      printf 'SAME %s\n' "$rel"
    else
      printf 'REFUSE %s (existing content differs; not overwritten)\n' "$rel"
      refuses=$((refuses + 1))
    fi
  done < <(find "$src" -type f -print0 | sort -z)
  [[ "$refuses" -eq 0 ]]
}
