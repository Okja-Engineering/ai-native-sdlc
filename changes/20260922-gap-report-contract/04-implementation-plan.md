---
slice_id: 20260922-gap-report-contract
status: plan-pending
review_status: pending
reviewer:
reviewed_at:
decision: accept | revise | inline-plan-sufficient | reject
base_revision: NOT FOUND — this repository has no commits, so no
  reproducible revision identity exists. "Worktree as of 2026-09-22" is
  a descriptive label only, not a pinned revision. If revision-sensitive
  evidence is needed before a baseline commit, the receipt may record a
  manifest hash (sha256 over a declared file list) — that hash binds
  content, not Git history, and must not be presented as a commit.
---

# Implementation plan — skeleton pending slice selection

External-implementation stage per the workflow specification: execution
belongs to the team's own process; this artifact is the plan and handoff
record, and it is required — `kind: external` governs *who executes*, not
whether the plan exists. No implementation has occurred.

## Boundaries

- Files this slice may create: `references/gap-report-contract.md`,
  `scripts/validate-gap-report.sh`, fixtures.
- Files this slice may edit: `SKILL.md` (one pointer line),
  `tests/test_evidence_to_intent.sh`.
- Everything else is out of scope; touching it reopens `02-slice.md`.

## Order

1. Contract doc first — the consumer-derived required fields
   (`03-evidence-plan.md`) are the specification the validator checks.
2. `validate-gap-report.sh` (sibling script — recommended, see
   `02-slice.md`), then fixtures proving each refusal.
3. SKILL.md pointer line last.

## Risks

- Overfitting the contract to run-09's report shape — mitigated by
  evidence-plan check 2 (a new minimal conforming fixture must pass) and
  by deriving fields from the consumer decision rather than the artifact.
- Run-09's report lacks formal review fields — recorded as a gap in that
  historical artifact, not a reason to weaken the contract.
- Structure-pass ≠ behavior-proven — the live missing-input evaluation
  named in `03-evidence-plan.md` is required before dogfood success can
  be claimed.

## Proof

The `03-evidence-plan.md` checks, executed and pasted verbatim into
`05-evidence-receipt.md` by whoever implements — this workspace contains
no receipt.
