# Outcome evaluation contract — provisional 0.1.0

Formats are specified in `_config/outcome-evaluation-schema.md`
(`outcome-targets`, `outcome-evidence`, `outcome-receipt`). This note
covers evaluator semantics.

## Bindings — two, explicit

- The `--contract` file must pass `validate-workflow-contract.sh` and
  carry its own content-bound `contract-acceptance` record
  (`--contract-acceptance`, `contract_schema: workflow-contract/0.1.0`).
  Accepted targets do not substitute for an accepted workflow.
- `intent_digest` on the targets names that contract's full normalized
  digest; the evaluator recomputes it and refuses on mismatch.
- The targets file itself carries a sibling `contract-acceptance` record
  (`--targets-acceptance`, `contract_schema: outcome-targets/0.1.0`) —
  editing targets after acceptance invalidates the digest.
- `implementation_rev` is recorded independently of intent; evidence
  items carry their own `rev:` and never re-bind to a newer contract.

## Evidence grammar

`evidence: OID ; value ; locator ; period:P ; unit:U ; basis:B ; rev:R`
followed by optional named fields `measure:` `scope:` `sampling:`
`conditions:` (each at most once). Positions 4–7 carry fixed field names:
a present field with the wrong key — or any undocumented field — is
malformed input and refuses evaluation (exit 2). An absent field or a
declared-empty value is *missing comparison information*, reported as
`non-comparable`, never inferred.

## Classification — every record evaluated

Per outcome, evidence rows are partitioned by recorded `rev`:

| Condition | Status |
|---|---|
| no evidence items | `missing` |
| items exist only at other revisions | `stale` — re-evaluation flagged; all rows preserved verbatim under their recorded revision/period |
| current-revision items disagree on value | `conflicted` — all preserved verbatim |
| any current-revision item fails comparability | `non-comparable` — field(s) named per row |
| otherwise | `observed` — evidence available, not success |

Equal values do not deduplicate: every row is rendered verbatim with its
locator, period, and revision. Historical-revision rows are appended
under `earlier revision(s) preserved` — never re-labeled or erased.

Comparability vs the target (declared fields only): `measure`, `unit`,
`scope`, `basis`, and `duration` (elapsed days between period endpoints)
must match the target's declared values. Different before/after dates
with equal declared duration are comparable.

## Baseline and comparison support

A second `outcome-evidence` file measured pre-adoption. Absent →
`baseline: NOT FOUND`, `comparison: unsupported` — the observation is
still reported. Conflicting baseline values → `comparison: unsupported`
with every record preserved. A `supported` comparison additionally
requires `sampling` and `conditions` declared on both sides and equal —
undeclared or differing values are named as insufficient comparability
information, never assumed equivalent. The evaluator does not judge
direction or magnitude.

## Destination

`--out` must resolve — canonicalized including its final component —
outside `--inputs-root`; an existing directory (or link to one),
dangling link, or path resolving inside the inspected repository →
REFUSE. Existing differing file → REFUSE (preserved); identical → SAME;
absent → CREATE. No timestamps — receipts are byte-deterministic.
