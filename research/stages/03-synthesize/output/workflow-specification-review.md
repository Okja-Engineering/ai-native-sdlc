---
type: adversarial-review
artifact: workflow-specification.md
date: 2026-09-07
status: clean-working-copy
owner_review: direction-confirmed-not-durable
---

# Workflow specification review

## Mandate

Review the research-derived intent-to-merge workflow before any candidate skills, phases, or subskills are derived.

## Denominator

- Intent-to-merge boundary and exclusions.
- Reviewable value-slice definition.
- Actors and retained human authority.
- Stable and per-slice artifacts.
- State transitions and backward routes.
- Six phase contracts and their inputs, actions, outputs, and human checks.
- 60/30/10 layer placement.
- Failure rules.
- Synthetic normal, missing-data, split, reject, revision-drift, and weakened-check cases.
- Stage 03 output contract.

## Findings and repairs

The first pass found:

1. Missing explicit review fields on downstream artifacts.
2. A plan-approval gate absent from the state model.
3. Incomplete terminal and failure coverage in the synthetic test.
4. Implementation assigned inconsistently across 60/30/10 layers.
5. Evidence/slice order inconsistent with the research packet.
6. Workflow specification and review files absent from the Stage 03 output contract.
7. Stable test inputs not explicitly supplied.

The specification and Stage 03 contract were repaired. A confirming pass found the implementation action in orchestration only and no regressions.

## Verdict

CLEAN for owner review. This verdict applies to the current uncommitted artifact. It authorizes no skill derivation or implementation until the owner accepts the specification.
