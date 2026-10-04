# Build a findings file and a Define cycle that reads it, from nothing.
#
# WHY NOT COPY THE LIVE ARTIFACTS
#
# tests/test_validate_define.sh copies the shipped tree and edits the copy by
# matching literals out of it. Two costs, and the second is the one that bites:
#
#   * the suite is pinned to today's artifact, so editing a count in a record of a
#     moment breaks a test that is about something else
#   * a tampered artifact breaks the test's own mutation rather than being
#     detected, and the suite then reports the wrong check — see tests/lib/mutate.sh
#
# A fixture built here knows its own answer. `define_fixture "$dir" "3 2" 1`
# produces six findings, two themes of three and two, and one outlier, and the
# only reason it would stop passing the gate is that the gate changed.
#
# The live artifacts are still worth asserting against, and
# tests/test_validate_define.sh does. What belongs on a built fixture is anything
# about SHAPE, because shape is what a record of a moment should not be asked to
# demonstrate.

# define_fixture <dir> <theme sizes, space separated> <outlier count>
# Writes <dir>/process/01-scan/findings/2026-12-01.md and
#        <dir>/process/03-define/cycles/2026-12-01.md
# and prints the path of the cycle file.
define_fixture() {
  local dir="$1" themes="$2" outl="$3"
  local total=0 n i id
  for n in $themes; do total=$((total + n)); done
  total=$((total + outl))

  # Only the two artifacts. The gate resolves its harvester relative to its own
  # directory, not to the fixture's, so copying a contract or a script in here
  # would be a second copy nobody reads.
  mkdir -p "$dir/process/01-scan/findings" "$dir/process/03-define/cycles"

  local src="$dir/process/01-scan/findings/2026-12-01.md"
  {
    printf '# Scan cycle — 2026-12-01\n\nsince: 2026-11-01\nnothing found: no\nexample: no\n\n'
    printf '## Looked at\n\n'
    printf -- '- web: a built fixture, 2026-11-01 to 2026-12-01.\n'
    printf -- '- X: a built fixture, 2026-11-01 to 2026-12-01.\n'
    printf -- '- YouTube: a built fixture, 2026-11-01 to 2026-12-01.\n\n'
    printf '## Findings\n\n'
    printf '| id | what | source | dated | kind | might affect (guess) | consequence guess |\n'
    printf '|---|---|---|---|---|---|---|\n'
    i=1
    while [ "$i" -le "$total" ]; do
      id="$(printf 'F%02d' "$i")"
      printf '| %s | A thing numbered %s happened | https://example.com/%s | 2026-11-15 | practice-change | build (guess) | low |\n' \
        "$id" "$i" "$i"
      i=$((i + 1))
    done
  } > "$src"

  local cyc="$dir/process/03-define/cycles/2026-12-01.md"
  {
    printf '# Define — cycle 2026-12-01\n\n'
    printf 'dated: 2026-12-01\n'
    printf 'from: [`process/01-scan/findings/2026-12-01.md`](../../01-scan/findings/2026-12-01.md), %s findings\n' "$total"
    printf 'method: built by tests/lib/define-fixture.sh\n'
    printf 'status: defined, not decided\n\n'
    printf -- '---\n\n## Themes\n\n'
    i=1
    for n in $themes; do
      printf '### %s · A theme that is a claim\n**%s findings · `practice-change`**\n\n' "$i" "$n"
      printf 'Why we think it is a theme: it is a built fixture.\n\n'
      i=$((i + 1))
    done
    printf -- '---\n\n## Outliers — surfaced because they fit no theme\n\n'
    if [ "$outl" -eq 0 ]; then
      printf 'None this cycle.\n\n'
    else
      i=1
      while [ "$i" -le "$outl" ]; do
        printf -- '- **An outlier that clusters with no theme, numbered %s.**\n' "$i"
        i=$((i + 1))
      done
      printf '\n'
    fi
    printf -- '---\n\n## Accounting\n\n<!-- accounting:ids -->\n'
    i=1
    while [ "$i" -le "$total" ]; do
      printf 'F%02d' "$i"
      if [ "$i" -lt "$total" ]; then printf ' '; fi
      i=$((i + 1))
    done
    printf '\n<!-- /accounting:ids -->\n\n'
    printf -- '---\n\n## Where this stops\n\nA person decides per theme. Nothing here records that.\n'
  } > "$cyc"

  printf '%s' "$cyc"
}
