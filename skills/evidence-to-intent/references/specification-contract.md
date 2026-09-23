# Intent and specification contract

Write one file at `OUTPUT_ROOT/RUN_ID/intent-specification.md`.

## Required frontmatter

```yaml
run_id:
status: provisional
implementation_authorized: false
review_status: pending
reviewer:
reviewed_at:
decision:
rationale:
source_revision:
```

When `review_status` becomes `reviewed`, `reviewer`, `reviewed_at`, `decision`, and `rationale` must be non-empty. Allowed decisions are `accept`, `revise`, and `reject`.

## Required sections

1. Purpose and explicit boundary
2. Owner facts and unresolved questions
3. Evidence inventory by E/D/R/A class
4. Contradictions, exclusions, and applicability
5. Independently derived responsibility map
6. Proposed intent and acceptance evidence
7. Deterministic/orchestration/AI/human split
8. External handoffs and non-responsibilities
9. Candidate-name comparison
10. Assumptions and NOT FOUND items
11. Owner decision block

Each recommendation cites owner evidence and research support separately. The output may recommend later boundaries but may not contain target-repository implementation steps.

## Human check

The owner verifies fidelity, applicability, exclusions, responsibilities, and acceptance cues. `accept` permits later workflow design only; it does not change `implementation_authorized: false`.
