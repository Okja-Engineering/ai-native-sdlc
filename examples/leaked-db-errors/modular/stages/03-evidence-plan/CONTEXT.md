# Stage 03: Evidence plan

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

## Inputs

| Source | Item | Why |
|---|---|---|
| Stage 02 | `changes/{slice-id}/02-slice.md` | Selected slice |
| Repository | repo-commands, existing-failing-case | Executable checks and the leak to reproduce |

## Process

1. Map every acceptance condition to a check or explicit retained judgment.
2. Record commands, expected signals, evidence locations, failure behavior.
3. Name protected checks the implementer must not weaken.

## Human check

The engineer confirms the evidence would falsify a wrong implementation and
accepts residual manual checks explicitly.

## Outputs

| Artifact | Location |
|---|---|
| Evidence plan | `changes/{slice-id}/03-evidence-plan.md` |
