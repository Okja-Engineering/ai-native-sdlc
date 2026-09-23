---
slice_id: 20260907-fix-leaked-db-errors
acceptance_checks:
  - name: leaked-details-test
    command: make test TEST=leaked_details
    expected_signal: exit 1
commands:
  - make test
expected_signals:
  - exit 0
evidence_locations:
  - test-output.log
failure_behavior: Stop.
protected_checks: []
residual_manual_judgment: None.
review_status: reviewed
reviewer: John Smith
reviewed_at: 2026-09-07
decision: accept
---

# Evidence plan

Run the failing test before implementation.
