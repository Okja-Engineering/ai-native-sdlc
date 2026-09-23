---
slice_id: 20260907-fix-leaked-db-errors
independent_value: Reduces exposure of internal database details for one endpoint family.
boundaries:
  - Affected endpoint family
dependencies: []
acceptance_evidence:
  - Failing test showing leaked details
merge_condition: Tests pass.
rollback_containment: Revert.
alternatives: []
review_status: reviewed
reviewer: John Smith
reviewed_at: 2026-09-07
decision: select
rationale: One slice.
---

# Slice

One endpoint family.
