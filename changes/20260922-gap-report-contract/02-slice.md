---
slice_id: 20260922-gap-report-contract
status: slice-pending
review_status: pending
reviewer:
reviewed_at:
decision: select | revise | split | reject
rationale:
---

# Slice — gap-report contract + validation

## Selected unit

One coherent review: the gap-report contract and its deterministic check.
Independently mergeable — the artifact is additive; existing valid runs
are unaffected because a gap report is only produced when a run already
stops.

## In scope

1. `skills/evidence-to-intent/references/gap-report-contract.md` — the
   document contract. Required fields are derived from the consumer's
   decision (see `03-evidence-plan.md`), not lifted from run-09's shape.
2. Deterministic validation for that contract — **recommended: a sibling
   `scripts/validate-gap-report.sh`.** Rationale: a gap report is a
   different document kind produced on the stop path, not a
   specification; extending `validate-specification.sh` would couple a
   stop-artifact to the success-path contract and widen its regression
   surface. A sibling script reuses `lib-contract.sh` helpers and keeps
   each validator's contract single-purpose.
3. Fixtures + `tests/test_evidence_to_intent.sh` cases: valid report,
   missing required field, report containing a recommendation section
   (must fail — a gap report never recommends).
4. `SKILL.md` pointer to the contract (one line).

## Out of scope

- Re-running run-09 or any live eval.
- Changing what triggers a gap report (the SKILL.md stop rule stands).
- `source_revision` semantics — blocked on the baseline-commit decision
  (roadmap, Decisions needed #1); the contract must tolerate
  `NOT FOUND`/`uncommitted-worktree-*` values, not resolve them.

## Dependencies

- None on other slices. Authoritatively blocked only on owner selection
  of this slice (ADR-0004 names it a *candidate*).

## Slice boundaries

The change touches `skills/evidence-to-intent/` and its tests only. If
validation cannot be added without touching `evidence-contract.md` or
`specification-contract.md`, that is a slice expansion requiring renewed
approval — it must not be silently folded in.
