# Controls (fixture — the code is emitted)

A fixture for tests/test_controls.sh. The gate this control names emits the
refusal code at a real call, so the forward check has to accept it.

Its pair is `comment-only.md`, which differs only in the path on the Enforced by
line.

## CTRL-F · a fixture control whose gate emits the code

**Enforced by** `tests/fixtures/controls/emits-at-a-site.sh`.

| Refusal | Condition |
|---|---|
| `fixture-refusal` | a condition the fixture gate does check |
