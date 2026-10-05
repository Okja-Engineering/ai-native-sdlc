# Build a discovery topic from nothing, with a caller-supplied open section.
#
# WHY THIS IS A LIB AND NOT A FUNCTION IN ONE SUITE
#
# It was a function in tests/test_validate_discovery.sh. Two suites now need the
# same artifact: that one, and tests/test_item_rule.sh, which drives the same
# section through the Discover gate and the Define gate and asserts they agree.
# A second copy of a fixture builder is the duplicated declaration this repository
# keeps being burnt by — the two copies would drift and the cross-gate assertion
# would then be comparing two different artifacts.
#
# It sits beside tests/lib/define-fixture.sh, which exists for the same reason: a
# record of a moment should not be asked to demonstrate shape, so a case about
# shape gets a fixture that knows its own answer.

# topic_fixture <path> <open-section body>
# Writes a topic that is within the contract apart from whatever the body is, and
# prints the path.
#
# The fixture carries the trailing `---` every shipped topic has, so every case
# built on it is also the separator case — an open section whose own separator used
# to be inside the body the emptiness check read.
topic_fixture() { # <path> <open-section body>
  local p="$1" body="$2"
  cat > "$p" <<EOF
# Discovery — whether to turn the thing on

dated: 2026-10-04
status: discovery complete, not assessed

## The question, in the asker's own words

> should we turn it on

## 2 · Coverage

**Reached:** the GitHub REST API, and the SemIf source at commit 23cf1f3
**Not reached:** JevBench
**Verified by hand:** the GitHub REST API

## Claims

The GitHub REST API returned 300 pull requests, and the SemIf source was read at commit 23cf1f3. JevBench was not read at all. [E]

Grades are the STANDARDS.md scheme: [V] vendor, never outcome evidence, [S] standard, [P] practitioner, [O] open.

## What could not be established

$body

---

## Where this stops

Here.
EOF
  printf '%s' "$p"
}
