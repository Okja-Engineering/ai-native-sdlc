# Controls (fixture — a refusal code that cannot be read)

A fixture for tests/test_controls.sh. The gate this control names has one refuse call
whose code is a variable, so nothing can say which refusal that site emits.

## CTRL-F · a fixture control over a gate with an unreadable call

**Enforced by** `tests/fixtures/controls/unreadable-site.sh`.

| Refusal | Condition |
|---|---|
| `fixture-refusal` | the condition the readable call checks |
