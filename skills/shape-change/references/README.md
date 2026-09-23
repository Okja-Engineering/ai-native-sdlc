# Shape-change phase contracts

Canonical detail: `../../../research/stages/03-synthesize/output/workflow-specification.md`, Phases A–C.

## Intent contract

Required: ID, source, request owner, outcome, affected user/operator, constraints, non-goals, open questions, review status, reviewer, date, and decision.

Pass: the owner recognizes the problem and desired outcome. File existence is not approval.

## Slice contract

Required: independent value, boundaries, dependencies, acceptance evidence, merge condition, rollback/containment, alternatives, reviewer, date, decision, and rationale.

Pass: useful independently and understandable as one coherent review decision.

## Evidence-plan contract

Required: acceptance-to-check map, commands, expected signals, evidence locations, failure behavior, protected checks, residual manual judgment, reviewer, date, and decision.

Pass: an incorrect implementation can be falsified. Missing tool capability is explicit.

## Handoff

The implementation process receives reviewed artifacts only. Any intent or slice expansion returns to the relevant human decision.
