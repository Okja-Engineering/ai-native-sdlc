---
type: schema
id: owner-facts
schema_version: owner-facts/0.1.0
status: provisional — owner review pending; does not freeze v1.0
---

# Owner facts schema (provisional 0.1.0)

A thin selection view over existing evidence. It is **not** a separate
evidence system: every fact carries the source reference and confirmation
status of the evidence it reuses, and referencing an observation or interview
record never promotes it automatically — only `established` counts, and
recording that state is a human act.

One fenced ```` ```contract ```` block per file:

```contract
id: owner-facts-<ref>
kind: owner-facts
schema_version: owner-facts/0.1.0
fact: FACT-ID = value ; source-ref ; established
fact: OTHER-FACT = - ; obs:run-07 ; unknown
fact: CONTESTED-FACT = - ; obs:run-03+interview:i2 ; conflicted
```

## Fact item grammar

Each `fact` list item is exactly `ID = VALUE ; SOURCE ; STATE`:

| Part | Rule |
|---|---|
| `ID` | stable fact identifier: `[A-Za-z0-9][A-Za-z0-9_-]*`; unique within the file — the same ID twice fails validation, so a fact can never sit in two states at once |
| `VALUE` | the explicit confirmed value; `-` when `STATE` is `unknown` or `conflicted` |
| `SOURCE` | source locator for the evidence the fact reuses — one of the documented prefixes `obs:<run-id>`, `interview:<id>`, `path:<file>`, `owner:<ref>`; adding locator types requires a schema change |
| `STATE` | `established` (owner-confirmed value), `unknown` (required fact unavailable), `conflicted` (sources or owner statements disagree) |

## Structural rules (enforced by the selector)

- Exactly one closed, non-nested contract block per file; an unterminated
  fence fails validation before any evaluation.
- Every in-block line is `key: value` with a nonempty trimmed value.
- `fact` is the only repeatable field; all other fields are singletons —
  duplicates fail validation.
- `established` requires an explicit `VALUE`; `unknown`/`conflicted` carry
  `-`. Values and sources must be nonempty after trimming.

## Semantics

- `established` with a false-valued entry (e.g. `X = none`) is evidence the
  condition does **not** hold — distinct from the fact being absent.
- `unknown` and absent both leave a requirement unmet; `unknown` additionally
  acknowledges the gap.
- `conflicted` retains the dispute; the selector must not resolve it.
- No fuzzy matching: selectors compare `ID` and `VALUE` verbatim.
