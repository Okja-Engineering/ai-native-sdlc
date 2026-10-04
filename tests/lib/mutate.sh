# Apply a mutation to a fixture, and refuse to continue quietly if it matched
# nothing. Source this after lib/assert.sh.
#
# WHY THIS EXISTS
#
# Several suites here build a fixture by copying the live artifacts and then
# editing the copy with a pattern matched out of that artifact —
# `s/\*\*7 findings · mostly `high`/.../`. When the artifact changes, or when
# somebody tampers with it, the pattern stops matching. The mutation then does
# nothing, the fixture is identical to the shipped file, and the assertions below
# it are about an unmodified file.
#
# What a reader sees is a failure naming the wrong check. The deletion exploit in
# issue #56 turned tests/test_validate_define.sh red with
#
#   not ok 15 - moving a count between themes is NOT detected — the documented limit
#
# which is about neither deletion nor counts. The suite was reporting its own
# broken mutation as a defect somewhere else entirely, so the one thing a test
# suite owes — pointing at what is wrong — was exactly what it could not do.
#
# A mutation that matches nothing is therefore a suite failure in its own right,
# named as one.
#
# USE
#
#   mutate <file> <perl -0 expression> <what the mutation is for>
#
# The count of mutations run and applied is asserted once by `mutate_done`, so the
# denominator is printed rather than taken on trust.

MUTATIONS_RUN=0
MUTATIONS_APPLIED=0

mutate() { # <file> <perl expression> <description>
  local f="$1" expr="$2" what="$3" before after
  MUTATIONS_RUN=$((MUTATIONS_RUN + 1))
  if [ ! -f "$f" ]; then
    assert_fail "the fixture to mutate does not exist: $what" "file: $f"
    return 1
  fi
  before="$(cksum < "$f")"
  if ! perl -0pi -e "$expr" "$f"; then
    assert_fail "the mutation could not run: $what" "expr: $expr"
    return 1
  fi
  after="$(cksum < "$f")"
  if [ "$before" = "$after" ]; then
    assert_fail "the mutation matched nothing: $what" \
      "expr: $expr" \
      "file: $f" \
      "The fixture is unchanged, so every assertion below it is about the" \
      "shipped artifact and will name the wrong check."
    return 1
  fi
  MUTATIONS_APPLIED=$((MUTATIONS_APPLIED + 1))
  return 0
}

# mutate_done <lowest acceptable number of mutations>
# One assertion carrying the denominator. A suite whose mutations all stopped
# matching would otherwise report a shrinking set of facts as a pass.
mutate_done() {
  assert_eq "$MUTATIONS_RUN" "$MUTATIONS_APPLIED" \
    "every fixture mutation applied ($MUTATIONS_RUN run)"
  if [ "$MUTATIONS_RUN" -lt "${1:-1}" ]; then
    assert_fail "fewer mutations ran than this suite holds" \
      "ran:      $MUTATIONS_RUN" "expected: at least ${1:-1}"
  else
    assert_pass "at least ${1:-1} mutations ran"
  fi
}
