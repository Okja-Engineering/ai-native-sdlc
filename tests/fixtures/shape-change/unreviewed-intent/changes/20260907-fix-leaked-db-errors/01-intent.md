---
slice_id: 20260907-fix-leaked-db-errors
source: owner-request
request_owner: Jane Doe
outcome: Prevent internal database error details from reaching API clients.
affected_user_or_operator: API clients
constraints: []
non_goals: []
open_questions:
  - Which client-visible error contract should replace raw messages?
review_status: pending
reviewer:
reviewed_at:
decision:
---

# Intent

Prevent internal database error details from reaching API clients.
