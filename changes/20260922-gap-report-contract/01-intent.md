---
slice_id: 20260922-gap-report-contract
status: intent-pending
review_status: pending
reviewer:
reviewed_at:
decision: accept | correct | reject
rationale:
---

# Intent — gap-report contract for evidence-to-intent

## Problem (in the request owner's terms)

`skills/evidence-to-intent/SKILL.md` promises twice that a run missing
required inputs or acceptance cues produces "a gap report and stop[s]"
(lines 26, 60). No contract defines that report's shape, and no validator
can check it — a stopped run leaves an unverifiable artifact. Observed
twice independently: the SKILL.md promise itself, and run-09
(`.devin/eval/20260922-skill-architect-intent/`), which produced a real
gap report there was nothing to check against.

## Desired outcome

A stopped `evidence-to-intent` run leaves a *checkable* artifact: a
documented `gap-report` contract and deterministic validation that fails
closed on malformed reports, so the owner can trust that "stopped" means
"stopped with reviewable evidence," not "wrote anything."

## Affected user/operator

The owner reviewing a stopped run; any later stage that consumes the gap
report as evidence of a clean stop.

## Constraints

- Bash only (ADR-0003); no new runtime dependencies.
- Preserve `implementation_authorized: false` semantics and the
  NOT FOUND vocabulary.
- The contract documents the artifact run-09 already produced in shape;
  it does not retroactively redefine it.

## Non-goals

- No changes to evidence or specification schemas (`*/0.1.0` stays).
- Run-09's other findings stay out: validator ID-suffix false positives,
  `source_revision` unavailability, describe-workflow composition, and
  Q17 tooling are separate slices, not this workspace's decision.
- No implementation authority is granted by this intent.

## Open questions

- Which header fields the contract requires vs. recommends — folded into
  the consolidated owner decision (`CONTEXT.md`), since it is the same
  accept/revise moment, not a separate ask.

## Source

ADR-0004 (proposed pilot contract — not itself authorization);
`.devin/eval/eval-log.md` run-09 yield finding (2).
