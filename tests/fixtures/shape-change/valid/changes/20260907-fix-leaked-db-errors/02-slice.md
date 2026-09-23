---
slice_id: 20260907-fix-leaked-db-errors
independent_value: Reduces exposure of internal database details for one endpoint family.
boundaries:
  - Affected endpoint family
  - Shared error boundary
dependencies: []
acceptance_evidence:
  - Failing test showing leaked details
  - Passing test showing sanitized client response
  - Preserved structured server logging
merge_condition: All acceptance evidence passes and lint/type checks pass.
rollback_containment: Revert the shared error boundary change.
alternatives:
  - Patch only the affected endpoint
  - Update all service errors at once
review_status: reviewed
reviewer: John Smith
reviewed_at: 2026-09-07
decision: select
rationale: Shared boundary addresses the root cause without expanding scope.
---

# Slice

Apply a shared error boundary to the affected endpoint family only. Keep structured server logging unchanged.
