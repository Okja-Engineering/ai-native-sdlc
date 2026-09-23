# Fixture: on_conflict outside the declared enum

```contract
id: test-workflow
kind: workflow
schema_version: workflow-contract/0.1.0
stages: 01-intent
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
on_conflict: silently-merge
reentry: intent-pending
review_fields: review_status | decision
```
