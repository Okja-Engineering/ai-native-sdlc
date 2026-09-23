# Fixture: stale evidence — verified revision no longer matches current

```contract
id: test-workflow
kind: workflow
schema_version: workflow-contract/0.1.0
stages: 01-intent | 02-slice
risk_scaling: test
owner: test-owner
current_revision: def5678
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
id: 02-slice
kind: internal
purpose: p
inputs: changes/{slice-id}/01-intent.md@runtime:01-intent
outputs: changes/{slice-id}/02-slice.md
acceptance: independent-value
decides: accountable-engineer
may_not: hide-dependencies
decisions: select | reject
runtime_deps: 01-intent
adoption_deps: none
context_entry: intent
context_explore: none
context_never: none
on_missing_input: stop
on_conflict: retain-both
reentry: slice-pending
review_fields: review_status | decision
verified_revision: abc1234
```
