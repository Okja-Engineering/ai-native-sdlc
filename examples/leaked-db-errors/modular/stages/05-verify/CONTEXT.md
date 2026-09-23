# Stage 05: Verify

Reconcile intent → slice → plan → diff → executed evidence into a
revision-pinned receipt. A test summary is not executed evidence.

```contract
id: 05-verify
kind: internal
purpose: Reconcile intent, slice, plan, diff, and executed evidence into a revision-pinned receipt.
inputs: changes/{slice-id}/04-implementation-plan.md@runtime:04-implement | repo-diff@runtime:04-implement | raw-check-evidence@runtime:04-implement
outputs: changes/{slice-id}/05-evidence-receipt.md
acceptance: acceptance-mapped-to-executed-evidence | revision-pinned | complete-changed-surface | checks-not-weakened
decides: independent-reviewer
may_not: infer-execution | accept-other-revision | approve-merge
decisions: accept | revise | reject
runtime_deps: 04-implement
adoption_deps: deterministic-check-runner | revision-control
context_entry: changes/{slice-id}/04-implementation-plan.md | raw-check-evidence | repo-verification-commands
context_explore: declared-runtime-deps | repo:changed-paths
context_never: unexecuted-summaries-as-evidence
on_missing_input: stop
on_conflict: retain-both
reentry: review-pending
review_fields: review_status | reviewer | reviewed_at | decision
```

## Inputs

| Source | Item | Why |
|---|---|---|
| Stage 04 | implementation plan, diff, raw evidence | What was actually done |
| Repository | repo-verification-commands | The checks the evidence plan requires |

## Process

1. Pin the current revision; enumerate the complete changed surface.
2. Map every acceptance condition to executed, revision-linked evidence.
3. Verify required checks were not weakened; record findings.

## Human check

An independent reviewer accepts the receipt. Any revision change reopens
verification.

## Outputs

| Artifact | Location |
|---|---|
| Evidence receipt | `changes/{slice-id}/05-evidence-receipt.md` |
