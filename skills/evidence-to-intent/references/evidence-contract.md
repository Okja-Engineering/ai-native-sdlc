# Evidence contract

## Required identity

Every standalone evidence item has YAML frontmatter with non-empty `id`, `kind`, `title`, `status`, `review_status`, and `source_locator`.

- `E...`: owner answer or correction with source locator.
- `D...`: inspected document with path or public URL and inspection date.
- `R-...`: evaluated research claim, applicability, contradiction, and status.
- `A...`: assumption with reason and resolution path.
- `Q...`: open question with blocked decision and owner.

## Allowed statuses

Research-card `review_status` values:

```text
pending-owner-review | reviewed | superseded | rejected
```

## Filtering rules

1. Owner corrections outrank summaries about owner intent.
2. Implementation structure is precedent, not outcome evidence.
3. Research supports recommendations only under recorded applicability.
4. Preserve contradictions; do not average them into certainty.
5. Record missing owner facts as `NOT FOUND — fact; ask: focused question`.
6. Deterministic validation cannot record human acceptance.

## Failure behavior

Duplicate IDs, empty or missing identity fields, invalid status values, malformed frontmatter, local paths outside the explicit input root, and unresolved declared local paths fail validation. `source_locator: NOT FOUND` is not valid evidence identity; keep the item as a question or gap until the owner supplies a locator. Missing applicability or acceptance does not fabricate a pass; retain the evidence but block dependent recommendations.
