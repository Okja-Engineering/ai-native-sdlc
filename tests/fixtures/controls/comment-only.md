# Controls (fixture — the code is only mentioned)

A fixture for tests/test_controls.sh. The gate this control names mentions the
refusal code in a comment and never emits it, so the forward check has to refuse.

Its pair is `emission-site.md`, which differs only in the path on the Enforced by
line.

## CTRL-F · a fixture control whose gate only mentions the code

**Enforced by** `tests/fixtures/controls/mentions-in-a-comment.sh`.

| Refusal | Condition |
|---|---|
| `fixture-refusal` | a condition the fixture gate does not check |
