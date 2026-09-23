# Stage 06: Merge decision

The merge authority records the terminal decision against the unchanged
verified revision. `merge-ready` is a record, not a merge.

```contract
id: 06-merge-decision
kind: internal
purpose: Record the merge-readiness decision against the verified revision.
inputs: changes/{slice-id}/05-evidence-receipt.md@runtime:05-verify | current-revision@D
outputs: changes/{slice-id}/06-merge-decision.md
acceptance: revision-unchanged | no-blocking-findings | no-missing-evidence
decides: merge-authority
may_not: approve-different-revision | merge | deploy | promote-learning
decisions: merge-ready | revise | split | reject
runtime_deps: 05-verify
adoption_deps: named-merge-authority | branch-protection
context_entry: changes/{slice-id}/05-evidence-receipt.md
context_explore: declared-runtime-deps
context_never: future-revisions
on_missing_input: stop
on_conflict: stop
reentry: review-pending
review_fields: reviewer | reviewed_at | verified_revision | decision | rationale | accepted_residual_risks
```

## Inputs

| Source | Item | Why |
|---|---|---|
| Stage 05 | `changes/{slice-id}/05-evidence-receipt.md` | Reviewed receipt |
| Repository | current-revision | Must equal `verified_revision` |

## Process

1. Confirm the revision is unchanged and no blocking finding remains.
2. Present the four decisions; the merge authority records one with rationale.
3. A later revision change reopens `review-pending` automatically.

## Human check

The merge authority owns the decision. `merge-ready` asserts only that the
recorded revision satisfies the accepted contract — it does not merge, deploy,
or approve future revisions.

## Outputs

| Artifact | Location |
|---|---|
| Merge decision | `changes/{slice-id}/06-merge-decision.md` |
