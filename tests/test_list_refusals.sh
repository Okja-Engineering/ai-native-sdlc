#!/usr/bin/env bash
# bin/list-refusals.sh decides what a refusal emission site is.
#
# Two things depend on that answer and have to get the same one:
# bin/validate-controls.sh, which binds a cited code to the gate its control
# names, and tests/mutate-sweep.sh, which mutates every site by line number. When
# they disagree, a guard can be invisible to both at once — which is how the `id`
# refusal in the scan gate reached production with no test.
#
# So this suite is about the definition, not about any one gate. Every fixture
# below is a shape that exists in this repository, written as the smallest script
# that has it.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
LISTER="$ROOT/bin/list-refusals.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

assert_file_exists "$LISTER" "the emission-site lister exists"

# sites <file> — the lister's output with the directory stripped, so assertions
# read as `<line>:<code>`.
sites() { (cd "$TMP" && /bin/bash "$LISTER" "$(basename "$1")") | cut -d: -f2-; }

# --- the code is read from the call, whatever the signature --------------------
# The five gates that have a refuse function do not agree on where the code sits:
# four take <file> <line> <code> <message>, bin/validate-standards.sh takes
# <file> <code> <message>, and bin/validate-authorship.sh takes <code> <message>.
# Hard-coding a position would have silently mis-read two gates.
cat > "$TMP/signatures.sh" <<'SH'
#!/usr/bin/env bash
refuse() { printf '%s:%s: refuse[%s]: %s\n' "$1" "$2" "$3" "$4" >&2; }
refuse "$f" "-" "four-arg-code" "the message"
refuse "$f" - bare-word-code "the message"
refuse "$DOC" "three-arg-code" "the message"
refuse "one-arg-code" "the message"
SH
out="$(sites "$TMP/signatures.sh")"
assert_contains "$out" "3:four-arg-code" "reads the code from <file> <line> <code> <message>"
assert_contains "$out" "4:bare-word-code" "reads an unquoted code"
assert_contains "$out" "5:three-arg-code" "reads the code from <file> <code> <message>"
assert_contains "$out" "6:one-arg-code" "reads the code from <code> <message>"

# --- a mention is not an emission site ----------------------------------------
# This is the invariant the whole repair rests on. The old check in
# tests/test_controls.sh asked `grep -q -- "$code" "$gate"`, and one added comment
# line turned a fabricated refusal from red to green.
cat > "$TMP/mentions.sh" <<'SH'
#!/usr/bin/env bash
# commented-code: named here in a comment and nowhere else
refuse() { printf 'refuse[%s]\n' "$1" >&2; }
unused="string-literal-code"
# refuse "$f" - commented-call-code "a call inside a comment"
case "$x" in *) : ;; esac  # refuse "$f" - trailing-comment-code "after a hash"
SH
out="$(sites "$TMP/mentions.sh")"
assert_eq "" "$out" "a comment, a string literal and a commented-out call are not sites"

# --- the definition and its own printf are not sites --------------------------
cat > "$TMP/definition.sh" <<'SH'
#!/usr/bin/env bash
refuse() {
  printf '%s: refuse[%s]: %s\n' "$1" "$2" "$3" >&2
  refusals=$((refusals + 1))
}
SH
assert_eq "" "$(sites "$TMP/definition.sh")" "the refuse definition is not a site"

# --- a call reached through a shell operator is a site ------------------------
# Most calls in this repository are not at the start of a line. The first version
# of the gate pattern anchored at the line start and would have missed all of
# these, which is the same kind of miss as the one being repaired.
cat > "$TMP/operators.sh" <<'SH'
#!/usr/bin/env bash
refuse() { :; }
[ -n "$x" ] || refuse "$f" "-" "after-or" "m"
[ -n "$x" ] && refuse "$f" "-" "after-and" "m"
case "$x" in *) refuse "$f" - after-case "m" ;; esac
if true; then refuse "$f" "-" "after-then" "m"; fi
{ refuse "$f" "-" "after-brace" "m"; }
SH
out="$(sites "$TMP/operators.sh")"
for c in after-or after-and after-case after-then after-brace; do
  assert_contains "$out" ":$c" "a call reached through a shell operator is a site ($c)"
done

# --- a continuation line is part of the call above it, not a new call ---------
# Four gates write the code on the refuse line and the message on the next. A
# message containing the word "refuse" followed by a space read as a second call,
# which produced a phantom refusal code called `and` in bin/validate-controls.sh.
cat > "$TMP/continued.sh" <<'SH'
#!/usr/bin/env bash
refuse() { :; }
[ -n "$x" ] || refuse "$f" "-" "real-code" \
  "this line says refuse and no refusal code could be read, which used to count"
SH
out="$(sites "$TMP/continued.sh")"
assert_contains "$out" "3:real-code" "the call line is the site"
assert_eq "1" "$(printf '%s\n' "$out" | grep -c .)" "its message line is not a second site"

# --- a site whose code cannot be read is loud, not skipped -------------------
# A dropped site is a hole in the denominator, and a hole in the denominator is
# the defect this script exists to close. bin/validate-controls.sh refuses on `?`.
cat > "$TMP/unreadable.sh" <<'SH'
#!/usr/bin/env bash
refuse() { :; }
refuse "$f" "-" "$code" "a code the lister cannot resolve"
SH
assert_contains "$(sites "$TMP/unreadable.sh")" "3:?" "a site with no readable code reports ?"

# --- a missing script cannot be read as "no sites" ---------------------------
# `exit 0` on a path that does not exist would make every check downstream of
# this report a clean denominator of zero.
/bin/bash "$LISTER" "$TMP/absent.sh" >/dev/null 2>&1
assert_status 2 "$?" "a script that does not exist exits 2 rather than reporting no sites"
/bin/bash "$LISTER" >/dev/null 2>&1
assert_status 2 "$?" "no arguments exits 2"

# --- the real gates ----------------------------------------------------------
# A floor rather than an exact count, so adding a refusal does not fail this
# suite. The point is that the enumeration found the gates at all: if it returned
# nothing, every check built on it would pass vacuously.
gates="$(cd "$ROOT" && ls process/*/validate-*.sh bin/validate-*.sh)"
real="$(cd "$ROOT" && /bin/bash "$LISTER" $gates)"
n="$(printf '%s\n' "$real" | grep -c .)"
[ "$n" -ge 80 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the real gates yield at least 80 emission sites (found $n)"

assert_eq "" "$(printf '%s\n' "$real" | grep ':?$')" "every site in every real gate has a readable code"

ng="$(printf '%s\n' "$real" | cut -d: -f1 | sort -u | grep -c .)"
nall="$(printf '%s\n' "$gates" | grep -c .)"
[ "$ng" -ge $((nall - 1)) ] && ok=yes || ok=no
assert_eq "yes" "$ok" \
  "all but at most one gate emits a code (gates with sites: $ng of $nall)"

# The one that may have none is bin/validate-claims.sh, which refuses by exit
# status. Name it, so "all but one" cannot quietly become a different one.
assert_eq "" "$(printf '%s\n' "$real" | grep '^bin/validate-claims.sh:')" \
  "bin/validate-claims.sh is the gate with no refusal code"

assert_done
