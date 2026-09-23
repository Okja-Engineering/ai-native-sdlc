# Stage 01: Intent

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

## Inputs

| Source | Item | Why |
|---|---|---|
| Owner | raw-request | The request in the owner's words |
| Repository | repo-rules | Existing contribution and architecture boundaries |

## Process

1. Record source, owner, outcome, affected users, constraints, non-goals,
   open questions.
2. Mark absent required facts `NOT FOUND`.
3. Save to the declared output with `review_status: pending`.

## Human check

The request owner confirms the artifact describes the intended problem and
outcome — not merely a plausible solution. Only `decision: accept` advances.

## Outputs

| Artifact | Location |
|---|---|
| Intent | `changes/{slice-id}/01-intent.md` |
