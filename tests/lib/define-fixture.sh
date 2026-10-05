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
# A QUIET CYCLE is `define_fixture <dir> "" 0`: no themes, no outliers, and a source
# marked `nothing found: yes` with no findings table. That is a state the scan
# contract protects deliberately, and until 2026-10-05 the Define gate had no passing
# state over it at all — every body for the accounting block drew `no-accounting`, and
# CI runs that gate over the directory, so recording one quiet month would have made
# every branch red. It is a fixture rather than a hand-built file because the shape is
# the point and because the next cycle may really be one.
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
    printf '# Scan cycle — 2026-12-01\n\nsince: 2026-11-01\n'
    if [ "$total" -eq 0 ]; then
      printf 'nothing found: yes\n'
    else
      printf 'nothing found: no\n'
    fi
    printf 'example: no\n\n'
    printf '## Looked at\n\n'
    printf -- '- web: a built fixture, 2026-11-01 to 2026-12-01.\n'
    printf -- '- X: a built fixture, 2026-11-01 to 2026-12-01.\n'
    printf -- '- YouTube: a built fixture, 2026-11-01 to 2026-12-01.\n\n'
    if [ "$total" -gt 0 ]; then
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
    fi
  } > "$src"

  local cyc="$dir/process/03-define/cycles/2026-12-01.md"
  {
    printf '# Define — cycle 2026-12-01\n\n'
    printf 'dated: 2026-12-01\n'
    printf 'from: [`process/01-scan/findings/2026-12-01.md`](../../01-scan/findings/2026-12-01.md), %s findings\n' "$total"
    printf 'method: built by tests/lib/define-fixture.sh\n'
    printf 'status: defined, not decided\n\n'
    printf -- '---\n\n## Themes\n\n'
    if [ -z "$themes" ]; then
      printf '<!-- declared-empty: the source recorded no findings, so there is nothing to group -->\n\n'
    fi
    i=1
    for n in $themes; do
      printf '### %s · A theme that is a claim\n**%s findings · `practice-change`**\n\n' "$i" "$n"
      printf 'Why we think it is a theme: it is a built fixture.\n\n'
      i=$((i + 1))
    done
    printf -- '---\n\n## Outliers — surfaced because they fit no theme\n\n'
    if [ "$outl" -eq 0 ]; then
      # The declared form, not a sentence. define-contract.md requires an empty
      # outlier section to declare itself empty in band and with a reason; a
      # fixture writing "None this cycle." would be building an artifact the gate
      # refuses and calling it the zero case.
      printf '<!-- declared-empty: this fixture was built with no outliers -->\n\n'
    else
      i=1
      while [ "$i" -le "$outl" ]; do
        printf -- '- **An outlier that clusters with no theme, numbered %s.**\n' "$i"
        i=$((i + 1))
      done
      printf '\n'
    fi
    printf -- '---\n\n## Accounting\n\n<!-- accounting:ids -->\n'
    if [ "$total" -eq 0 ]; then
      # A declared EMPTY set, which is a different state from an absent block. The
      # same form the Themes and Outliers sections use, and the gate reads it the same
      # way: present, and carrying a reason.
      printf '<!-- declared-empty: the source is a quiet cycle and records no findings, so there is nothing to account for -->\n'
    else
      i=1
      while [ "$i" -le "$total" ]; do
        printf 'F%02d' "$i"
        if [ "$i" -lt "$total" ]; then printf ' '; fi
        i=$((i + 1))
      done
      printf '\n'
    fi
    printf '<!-- /accounting:ids -->\n\n'
    printf -- '---\n\n## Where this stops\n\nA person decides per theme. Nothing here records that.\n'
  } > "$cyc"

  printf '%s' "$cyc"
}
