---
type: schema
id: outcome-evaluation
schema_version: outcome-evaluation/0.1.0
status: provisional — owner review pending; does not freeze v1.0
---

# Outcome evaluation schemas (provisional 0.1.0)

Three fenced-`contract` document kinds behind `evaluate-outcome`
(proposal §14). One closed, non-nested block per file; `key: value` lines
with nonempty values; singleton fields unique; repeatable fields named
below.

## outcome-targets/0.1.0 — intended outcomes

```contract
id: targets-<name>
kind: outcome-targets
schema_version: outcome-targets/0.1.0
intent_digest: sha256:<full normalized digest of the accepted contract>
target: O-1 ; product ; <description> ; measure:<m> ; unit:<u> ; scope:<s> ; duration:<N>d ; basis:<b>
```

- `intent_digest` binds the targets to the exact accepted contract content;
  the evaluator recomputes the digest from the supplied contract and
  refuses on mismatch — targets cannot silently retain a stale basis.
- `target` items are repeatable; fields are `;`-separated and
  fixed-order: id, `product|process`, description, then
  `measure`/`unit`/`scope`/`duration`/`basis` (the declared comparability
  surface — `duration` is elapsed days between period endpoints).
- Targets are accepted via a sibling `contract-acceptance` record whose
  `contract:` resolves to the targets file and whose digest covers the
  normalized targets (the S8 acceptance mechanism, reused).

## outcome-evidence/0.1.0 — observations and candidate lessons

```contract
id: evidence-<name>
kind: outcome-evidence
schema_version: outcome-evidence/0.1.0
evidence: O-1 ; <observed-value> ; <locator> ; period:<YYYY-MM-DD..YYYY-MM-DD> ; unit:<u> ; basis:<b> ; rev:<implementation-rev> [; measure:<m>] [; scope:<s>] [; sampling:<m>] [; conditions:<c>]
lesson: <text> ; <locator>
```

- `evidence` items are repeatable. Positions 4–7 carry fixed field names
  (`period`, `unit`, `basis`, `rev`) — a present field with the wrong key,
  or any undocumented field name, is malformed input (exit 2). An absent
  field or a declared-empty value (`unit:`) is missing comparison
  information — reported `non-comparable`, never inferred.
- `measure`/`scope` are optional trailing fields checked independently
  against the target's declared values; absent → missing comparison
  information on that row.
- `sampling`/`conditions` are optional trailing fields checked pairwise
  between evidence and baseline: a `supported` comparison requires both
  sides to declare each and agree. Undeclared or differing values leave
  the comparison `unsupported` with the gap named — equivalence is never
  assumed.
- `rev` records the implementation revision the observation was made
  against; rows recorded at other revisions are preserved verbatim and
  mark the outcome for re-evaluation only when no current-revision
  observation exists.
- `lesson` items are candidate lessons/corrections for human review —
  never confirmations; reviewer names alone do not promote them.
- Locators use the documented prefixes (`obs:`, `interview:`, `path:`,
  `owner:`).
- The baseline is a second `outcome-evidence` file measured before
  adoption; absent baseline → observation reported, improvement claim
  `NOT FOUND`; conflicting baseline rows → `comparison: unsupported` with
  every record preserved.

## outcome-receipt/0.1.0 — the emitted artifact

```contract
id: receipt-<targets-id>
kind: outcome-receipt
schema_version: outcome-receipt/0.1.0
intent_digest: sha256:<full digest>
targets_digest: sha256:<normalized targets digest>
implementation_rev: <rev being evaluated>
reevaluation: current|required
contract_acceptance: <path of the contract's verified acceptance record>
targets_acceptance: <path of the targets' verified acceptance record>
outcome: <id> ; <product|process> ; <status> ; <detail>
lesson: <text> ; <locator> ; status:candidate
```

Two acceptance bindings are explicit and independent: the workflow
contract must validate and carry its own content-bound acceptance record,
and the targets file carries a second record bound to its normalized
content plus the `intent_digest` link to the accepted contract.

`status` ∈ `observed | missing | conflicted | stale | non-comparable` —
`observed` means evidence exists, never that the outcome succeeded.
Detail fields carry every recorded observation verbatim
(`"value" [locator · period · rev]`, with per-row `non-comparable` field
names where a row fails the target's declared surface), earlier-revision
records under `earlier revision(s) preserved`, the baseline records or
`NOT FOUND`, and `comparison: supported|unsupported` (unsupported names
the blocking comparability gap). The receipt is deterministic —
identical inputs produce identical bytes; it carries no timestamp and no
verdict.
