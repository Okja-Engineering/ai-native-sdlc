# Shared contract helpers — the product library behind the callable
# validation/normalization interface (proposal §12.6).
# A contract block is a fenced ```contract section of `key: value` lines;
# list values are `|`-separated; `id` must be the first key.
# Sourced by scripts in this directory and by the test suites under tests/.

# extract_blocks_to FILE DIR — write each ```contract block in FILE to a
# numbered file DIR/<n>.contract. Prints nothing on success.
extract_blocks_to() {
  local file="$1" dir="$2"
  awk -v dir="$dir" -v prefix="${BLOCK_PREFIX:-blk}" '
    /^```contract[[:space:]]*$/ {
      inblock = 1
      n++
      out = sprintf("%s/%s-%d.contract", dir, prefix, n)
      next
    }
    inblock && /^```[[:space:]]*$/ { inblock = 0; close(out); next }
    inblock { print > out }
  ' "$file"
}

# trim STRING — strip leading/trailing whitespace.
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

# block_value FILE KEY — print the value of the first `key:` line.
block_value() {
  awk -v key="$2" '
    index($0, key ":") == 1 {
      sub("^[^:]*:[[:space:]]*", "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$1"
}

# block_has FILE KEY — exit 0 if a `key:` line exists with a non-empty value.
block_has() {
  local v
  v="$(block_value "$1" "$2")"
  [[ -n "$v" ]]
}

# list_contains LIST ITEM — exit 0 if ITEM is a `|`-separated member of LIST.
list_contains() {
  local list="$1" item="$2" part
  [[ "$list" == "$item" || "$list" == "$item |"* || "$list" == *"| $item" || "$list" == *"| $item |"* ]]
  return $?
}

# block_items FILE KEY — print every `|`-separated item across all `key:`
# lines, one trimmed item per line, in file order. Prints nothing when the
# key is absent.
block_items() {
  awk -v key="$2" '
    index($0, key ":") == 1 {
      sub("^[^:]*:[[:space:]]*", "")
      sub(/[[:space:]]+$/, "")
      n = split($0, p, "|")
      for (i = 1; i <= n; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", p[i])
        if (p[i] != "") print p[i]
      }
    }
  ' "$1"
}

# norm_file FILE — normalized semantic lines for every contract block:
# one "<id>::<key>=<item>" line per list item, sorted. One line per item is
# the unambiguous encoding: items may contain commas and other punctuation,
# but never newlines, so item boundaries cannot collide with the joiner.
norm_file() {
  awk '
    /^```contract[[:space:]]*$/ { inb = 1; id = ""; next }
    inb && /^```[[:space:]]*$/ { inb = 0; next }
    inb && /^[A-Za-z_]+:/ {
      key = $0; sub(/:.*/, "", key)
      val = $0; sub(/^[^:]*:[[:space:]]*/, "", val)
      n = split(val, p, "|")
      for (i = 1; i <= n; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", p[i])
      for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++)
        if (p[j] < p[i]) { t = p[i]; p[i] = p[j]; p[j] = t }
      if (key == "id") id = p[1]
      for (i = 1; i <= n; i++) printf "%s::%s=%s\n", id, key, p[i]
    }
  ' "$1"
}

# norm_form PATH — normalized contract for a compact file or modular dir.
norm_form() {
  local path="$1"
  if [[ -d "$path" ]]; then
    find "$path" -type f -name '*.md' | sort | while IFS= read -r f; do
      norm_file "$f"
    done | sort
  else
    norm_file "$path" | sort
  fi
}

# body_without_blocks FILE — file contents with ```contract blocks removed.
body_without_blocks() {
  awk '
    /^```contract[[:space:]]*$/ { inb = 1; next }
    inb && /^```[[:space:]]*$/ { inb = 0; next }
    !inb { print }
  ' "$1"
}

# map_has FILE KEY — exit 0 if column-1 key exists in a TSV map.
map_has() {
  awk -F'\t' -v k="$2" '$1==k{f=1} END{exit !f}' "$1"
}
# map_get FILE KEY COL — print column COL of first matching row.
map_get() {
  awk -F'\t' -v k="$2" -v c="$3" '$1==k{print $c; exit}' "$1"
}

# check_structure FILE REPEATABLE_KEYS — structural pass on the raw document
# before evaluation: exactly one closed, non-nested contract fence; every
# in-block line is 'key: value' with a nonempty value; singleton fields are
# unique. Keys listed in REPEATABLE_KEYS may repeat (e.g. fact, depends_on).
check_structure() {
  awk -v rep=" $2 " '
    /^```contract[[:space:]]*$/ {
      if (inb) { printf "nested contract fence at line %d\n", NR > "/dev/stderr"; bad=1 }
      inb=1; n++; next
    }
    /^```[[:space:]]*$/ { if (inb) { inb=0; next } }
    inb {
      if ($0 !~ /^[A-Za-z_][A-Za-z0-9_]*:/) {
        printf "malformed contract line %d: %s\n", NR, $0 > "/dev/stderr"; bad=1; next
      }
      k=$0; sub(/:.*/, "", k); cnt[k]++
      if (index(rep, " " k " ") == 0 && cnt[k] > 1)
        { printf "duplicate singleton field: %s\n", k > "/dev/stderr"; bad=1 }
      v=$0; sub(/^[^:]*:[[:space:]]*/, "", v)
      if (v ~ /^[[:space:]]*$/)
        { printf "empty value for field %s\n", k > "/dev/stderr"; bad=1 }
      next
    }
    END {
      if (inb)  { print "unterminated contract fence" > "/dev/stderr"; bad=1 }
      if (n!=1) { printf "expected exactly 1 contract block, found %d\n", n+0 > "/dev/stderr"; bad=1 }
      exit (bad ? 1 : 0)
    }
  ' "$1"
}
