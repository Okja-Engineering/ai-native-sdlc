# Stage 02: Slice

Select the smallest independently valuable, reviewable change. Example
candidates: patch one endpoint | shared error boundary | all service errors.

```contract
id: 02-slice
kind: internal
purpose: Select the smallest independently valuable, reviewable change.
inputs: changes/{slice-id}/01-intent.md@runtime:01-intent | repo-boundaries@D
outputs: changes/{slice-id}/02-slice.md
acceptance: independent-value | one-coherent-review | dependencies-declared
decides: accountable-engineer
may_not: select-unreviewed-intent | hide-dependencies
decisions: select | revise | split | reject
runtime_deps: 01-intent
adoption_deps: named-accountable-engineer
context_entry: changes/{slice-id}/01-intent.md | repo-boundaries
context_explore: declared-runtime-deps | repo:coupling-edges
context_never: unreviewed-intent-drafts | other-slice-folders
on_missing_input: stop
on_conflict: retain-both
reentry: slice-pending
review_fields: review_status | reviewer | reviewed_at | decision | rationale
```

## Inputs

| Source | Item | Why |
|---|---|---|
| Stage 01 | `changes/{slice-id}/01-intent.md` | Accepted intent |
| Repository | repo-boundaries | Known coupling and ownership edges |

## Process

1. Produce at least two genuinely different decompositions.
2. Compare value, review burden, verification cost, reversibility.
3. Recommend; preserve rejected alternatives; save with `pending` review.

## Human check

The accountable engineer selects, revises, splits, or rejects. The chosen
slice stays independently useful and one coherent review decision.

## Outputs

| Artifact | Location |
|---|---|
| Slice selection | `changes/{slice-id}/02-slice.md` |
