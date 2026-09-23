---
slice_id: 20260907-fix-leaked-db-errors
acceptance_checks:
  - name: leaked-details-test
    command: make test TEST=leaked_details
    expected_signal: exit 1
  - name: sanitized-response-test
    command: make test TEST=sanitized_response
    expected_signal: exit 0
commands:
  - make test
  - make lint
  - make typecheck
expected_signals:
  - exit 0
evidence_locations:
  - test-output.log
failure_behavior: Stop and report missing evidence.
protected_checks:
  - Existing endpoint tests must not be weakened.
residual_manual_judgment: Confirm neighboring endpoint families are unaffected.
review_status: reviewed
reviewer: John Smith
reviewed_at: 2026-09-07
decision: accept
---

# Evidence plan

Reproduce the leak with a failing test before implementation. After the shared boundary change, the same test must pass and server logging must remain structured.
