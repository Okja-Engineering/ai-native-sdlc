# Interview input contract (optional)

`describe-workflow` works from repository inspection alone. A Workflow
Package Builder interview record may additionally be supplied; it is input
evidence, not verified owner fact.

## Minimal row contract

One ```contract block per evidence row:

```contract
id: E3
kind: interview-evidence
statement: deploys require two approvals
source-ref: interview-2026-09-10
review-status: reviewed
```

Required per row: `id`, `statement`, `source-ref`, `review-status`.

## Rejection

`check-interview-record.sh` exits non-zero with an explicit diagnostic when:

- the file has no `kind: interview-evidence` blocks at all, or
- any row lacks a required field.

Unsupported formats are never silently interpreted. Claims sourced from
interview rows use the `interview:<evidence-id>` locator form.
