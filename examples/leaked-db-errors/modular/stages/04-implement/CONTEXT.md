# Stage 04: Implement — external

Implementation is executed by the team's own process (coding agent, Scuba, or
manual work). This contract defines the boundary, not the work: reviewed
artifacts go out; changed surface, current revision, and raw check output come
back. This package never implements code.

```contract
id: 04-implement
kind: external
purpose: Implement the accepted slice inside granted authority.
inputs: changes/{slice-id}/01-intent.md@runtime:01-intent | changes/{slice-id}/02-slice.md@runtime:02-slice | changes/{slice-id}/03-evidence-plan.md@runtime:03-evidence-plan
outputs: changes/{slice-id}/04-implementation-plan.md | repo-diff | raw-check-evidence
acceptance: plan-approved-or-inline-exception | scope-held | raw-evidence-preserved
external_actor: team-implementation-process
handoff: reviewed-intent-slice-evidence-plan
return_evidence: changed-surface | current-revision | raw-check-output
decides: accountable-engineer
may_not: self-approve-merge | weaken-required-evidence | expand-slice-silently
decisions: accept | revise | inline-plan-sufficient | reject
runtime_deps: 01-intent | 02-slice | 03-evidence-plan
adoption_deps: scoped-workspace | bounded-tool-permissions
context_entry: changes/{slice-id}/01-intent.md | changes/{slice-id}/02-slice.md | changes/{slice-id}/03-evidence-plan.md | repo-rules
context_explore: repo:source-tree
context_never: credentials | unrelated-branches
on_missing_input: stop
on_conflict: escalate
reentry: plan-pending
review_fields: review_status | reviewer | reviewed_at | decision | base_revision
```

## Inputs

| Source | Item | Why |
|---|---|---|
| Stages 01–03 | reviewed intent, slice, evidence plan | The only artifacts the external actor may receive |

## Human check

The accountable engineer approves the implementation plan before work, or
records an `inline-plan-sufficient` exception. Slice or intent deviation
reopens the upstream decision — the actor cannot self-classify expansion.

## Outputs

| Artifact | Location |
|---|---|
| Implementation plan | `changes/{slice-id}/04-implementation-plan.md` |
| Changed surface | host repository diff |
| Return evidence | raw check output, current revision |
