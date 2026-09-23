# SDLC: intent-to-merge-ready — compact module

> Synthetic worked example: a service leaks raw database errors from one API
> endpoint family; the slice adds a shared error boundary. This file teaches
> the full lifecycle and is itself a valid compact export. It never merges,
> deploys, implements, or promotes learning.
>
> Conforms to `../../../_config/workflow-contract-schema.md` (`workflow-contract/0.1.0`).

```contract
id: intent-to-merge-ready
kind: workflow
schema_version: workflow-contract/0.1.0
stages: 01-intent | 02-slice | 03-evidence-plan | 04-implement | 05-verify | 06-merge-decision
risk_scaling: low-collapses-01-03 | high-requires-independent-reviewer
owner: example-owner
```

## Route by current artifact

| You hold | Go to |
|---|---|
| Raw request, no reviewed intent | §01 Intent |
| Accepted intent | §02 Slice |
| Selected slice | §03 Evidence plan |
| Accepted evidence plan | §04 Implement — external actor |
| Implemented change + raw evidence | §05 Verify |
| Reviewed evidence receipt | §06 Merge decision — human |

## Loading rules

- Always: this file.
- On entering §NN: the stage's `context_entry` items only.
- Exploration: only within each stage's `context_explore` scope; a discovered
  contradiction stops the stage and surfaces for a human.
- Never: items in `context_never`; other slices' folders; run transcripts.

## §01 Intent

Record the problem and desired outcome in the request owner's terms. For the
example: stop raw DB errors reaching API clients while preserving server-side
diagnostics.

```contract
id: 01-intent
kind: internal
purpose: Record the problem and desired outcome in the request owner's terms.
inputs: raw-request@E | repo-rules@D
outputs: changes/{slice-id}/01-intent.md
acceptance: required-fields-present | unknowns-marked-not-found | owner-recognizes-problem
decides: request-owner
may_not: decide-acceptance | infer-missing-facts | propose-solution-as-problem
decisions: accept | correct | reject
runtime_deps: none
adoption_deps: named-request-owner | shared-changes-home
context_entry: raw-request | repo-rules
context_explore: repo:router-and-rules
context_never: research-corpus | other-slice-folders | run-transcripts
on_missing_input: stop
on_conflict: retain-both
reentry: intent-pending
review_fields: review_status | reviewer | reviewed_at | decision
```

Human check: the request owner confirms the artifact describes the intended
problem and outcome — not merely a plausible solution.

## §02 Slice

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

Human check: the accountable engineer selects, revises, splits, or rejects; the
choice stays one coherent review decision.

## §03 Evidence plan

Define, before implementation, how an incorrect implementation is falsified.
Example: a failing leaked-details test, a passing sanitized-response test,
preserved structured logging.

```contract
id: 03-evidence-plan
kind: internal
purpose: Define how an incorrect implementation would be falsified before it starts.
inputs: changes/{slice-id}/02-slice.md@runtime:02-slice | repo-commands@D | existing-failing-case@D
outputs: changes/{slice-id}/03-evidence-plan.md
acceptance: every-acceptance-mapped | protected-checks-named | failure-reproduced-when-feasible
decides: accountable-engineer
may_not: invent-tool-capability | weaken-protected-checks
decisions: accept | revise | reject
runtime_deps: 02-slice
adoption_deps: deterministic-test-commands
context_entry: changes/{slice-id}/02-slice.md | repo-commands | existing-failing-case
context_explore: declared-runtime-deps | repo:test-paths
context_never: implementation-diffs
on_missing_input: stop
on_conflict: retain-both
reentry: proof-pending
review_fields: review_status | reviewer | reviewed_at | decision | accepted_manual_checks
```

Human check: the engineer confirms the evidence would falsify a wrong
implementation and accepts any residual manual checks explicitly.

## §04 Implement — external stage

Implementation is executed by the team's own process (coding agent, Scuba,
or manual work). This module defines the boundary, not the work: reviewed
artifacts go out; changed surface, current revision, and raw check output come
back. Nothing here implements code.

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

## §05 Verify

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

## §06 Merge decision

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

## Risk scaling

- **low:** §01–§03 may collapse into one reviewed file; all authority,
  provenance, and review fields are still required.
- **medium:** all stages, standard review depth.
- **high or coupling > 1 topology edge:** independent reviewer mandatory at
  §05; plan approval mandatory at §04.

## Coverage map — what this module executes vs describes

| Lifecycle stage | Status |
|---|---|
| Plan, Design | Covered (§01–§03) |
| Build | External boundary only (§04) |
| Test | Evidence plan + receipt; not CI-integrated evals |
| Deploy | Stops at merge-ready; gates described, not installed |
| Maintain | Out of scope — outcome evaluation is a separate capability |
