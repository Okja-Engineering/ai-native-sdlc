# Verify-change contracts

Canonical detail: `../../../research/stages/03-synthesize/output/workflow-specification.md`, Phases E–F.

## Evidence receipt

Required:

- slice, base, and verified revisions;
- complete changed-surface denominator;
- acceptance coverage;
- commands, exit status, timestamp, and evidence location;
- test/check integrity result;
- reconciled findings;
- missing evidence;
- residual risks;
- reviewer, date, and decision.

Pass: all required evidence is present on the current revision and no blocking finding remains.

## Merge decision

Allowed decisions:

```text
merge-ready | revise | split | reject
```

The decision records merge authority, timestamp, verified revision, rationale, and accepted residual risks. It becomes stale immediately when the revision changes.

## Boundaries

- AI findings inform but do not approve.
- Passing checks do not establish intent or architecture automatically.
- The skill never merges, deploys, promotes an RLP learning, or audits a candidate skill.
