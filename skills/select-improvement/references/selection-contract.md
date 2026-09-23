# Selection contract — selection-card/0.1.0 (provisional)

The deterministic improvement selector (`scripts/select-eligible.sh`) reads
two document kinds. Both are provisional; neither freezes v1.0.

## owner-facts file

`_config/owner-facts-schema.md` — a thin selection view over existing
evidence. Each `fact` item is `ID = VALUE ; SOURCE ; STATE` with
`STATE ∈ {established, unknown, conflicted}`. Referencing an observation or
interview record in `SOURCE` does not promote it: only `established` counts.

## selection-card file

One `.md` file per candidate practice under `cards/`, carrying exactly one
```` ```contract ```` block:

```contract
id: C-01
kind: selection-card
schema_version: selection-card/0.1.0
title: Reviewable value slice
practice: one-line statement of the practice
research_card: R-FLOW-001
research_path: research/patterns/reviewable-value-slice.md
research_status: pending-owner-review
applies_when: outcome-decomposable = true
requires_capability: named-reviewer = assigned
depends_on: none
status: proposed
```

| Field | Rule |
|---|---|
| `id` | `C-` prefixed card id; unique across the card set |
| `applies_when` | `FACT-ID = value` predicates — does the practice apply to this client at all; `none` permitted |
| `requires_capability` | `FACT-ID = value` predicates naming an **established client capability** — gates readiness, not applicability; `none` permitted |
| `depends_on` | card ids — **card relationships**; the prerequisite must be adopted (fact `CARD-ID = adopted` established) before this card is ready; `none` permitted |
| `research_card` / `research_path` / `research_status` | provenance into the research inventory; `pending-owner-review` stays visibly provisional in the report |
| `status` | always `proposed` — the selector never labels a candidate accepted |

Structural rules: one closed contract block per file; `key: value` lines
with nonempty values; `applies_when`/`requires_capability`/`depends_on`
may repeat, all other fields are singletons (duplicates fail validation).

## Evaluation

1. **Applicability** — every `applies_when` predicate must be `established`
   with a matching value. An established different value is decisive
   (inapplicable); conflicted or unknown facts are not.
   Bucket precedence: inapplicable > conflicted > unknown > applicable.
2. **Readiness** (only if applicable) — every `requires_capability` must be
   established-matching, and every `depends_on` card must have an
   established `CARD-ID = adopted` fact. A selected-but-unadopted
   prerequisite blocks readiness: selection ≠ implementation.
3. **Graph validation** — `depends_on` targets must exist in the card set;
   a cycle is a graph error (exit 3), not an ineligible result.

Report sections: `eligible and ready`, `applicable — blocked`,
`inapplicable`, `unknown`, `conflicted`, `missing-fact gaps`. Each card
line carries its research-card id, path, and review status (provisional
unless `reviewed`); beneath it, successful checks are listed as evidence
lines — `fact:`, `capability:`, `adoption:` — each `ID = value
[established · source]`. Missing or unknown adoption facts appear in the
gap list as `CARD-ID = adopted (needed by …)`; conflicted adoption
evidence and established-but-not-adopted values block with distinct
reasons but are not gaps. Deterministic: same inputs → same report. The
selector performs no writes.
