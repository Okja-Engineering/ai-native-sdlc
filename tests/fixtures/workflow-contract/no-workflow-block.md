# Fixture: stage blocks with no workflow block
#
# Without the workflow block there is no schema_version, owner, risk_scaling,
# or declared stage list to validate against — must fail, not exempt.

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
