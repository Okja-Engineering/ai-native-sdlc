# Fixture: external stage without the required boundary fields

```contract
id: test-workflow
kind: workflow
schema_version: workflow-contract/0.1.0
stages: 01-intent | 04-implement
risk_scaling: test
owner: test-owner
```

```contract
id: 01-intent
kind: internal
purpose: p
inputs: raw-request@E
outputs: changes/{slice-id}/01-intent.md
acceptance: required-fields
decides: request-owner
may_not: self-approve
decisions: accept | reject
runtime_deps: none
adoption_deps: none
context_entry: raw-request
context_explore: none
context_never: none
on_missing_input: stop
on_conflict: retain-both
reentry: intent-pending
review_fields: review_status | decision
```

```contract
id: 04-implement
kind: external
purpose: p
inputs: changes/{slice-id}/01-intent.md@runtime:01-intent
outputs: repo-diff
acceptance: scope-held
decides: accountable-engineer
may_not: self-approve-merge
decisions: accept | reject
runtime_deps: 01-intent
adoption_deps: scoped-workspace
context_entry: intent
context_explore: repo:source-tree
context_never: credentials
on_missing_input: stop
on_conflict: escalate
reentry: plan-pending
review_fields: review_status | decision
```
