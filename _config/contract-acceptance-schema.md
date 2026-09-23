---
type: schema
id: contract-acceptance
schema_version: contract-acceptance/0.1.0
status: provisional — owner review pending; does not freeze v1.0
---

# Contract acceptance record schema (provisional 0.1.0)

A sibling record binding a human review decision to the exact content of a
reviewed workflow contract. It is its own document kind — it does not extend
`workflow-contract/0.1.0`, and it is never part of the contract it covers.
Exporters read it; nothing in this toolkit creates or updates it. Approval
is recorded by a human, not generated.

## 1. Format

One fenced ```` ```contract ```` block in a `.md` file placed beside the
contract it covers (not inside a modular contract tree — a non-workflow
block there is a validation failure).

```contract
id: acceptance-<ref>
kind: contract-acceptance
schema_version: contract-acceptance/0.1.0
contract: <path to the contract instance, relative to this file>
contract_schema: workflow-contract/0.1.0
contract_digest: sha256:<64-hex digest of the normalized contract>
reviewer: <named human>
reviewed_at: <YYYY-MM-DD>
decision: accept
rationale: <one line>
```

## 2. Fields

| Field | Rule |
|---|---|
| `id` | unique record identifier |
| `kind` | `contract-acceptance` |
| `schema_version` | must equal `contract-acceptance/0.1.0` |
| `contract` | path to the accepted contract (compact file or modular directory), resolved relative to this record's file |
| `contract_schema` | the contract's declared schema version |
| `contract_digest` | `sha256:` + hex of `normalize-workflow.sh` output over the contract — binds acceptance to content, not to a name |
| `reviewer` | the named human who reviewed; required, never a tool |
| `reviewed_at` | review date |
| `decision` | `accept`, `revise`, or `reject` — only `accept` authorizes export |
| `rationale` | one line; why this decision was made |

## 3. Semantics

- The digest is over the **normalized** contract (schema §7 encoding), so
  reformats that preserve semantics do not invalidate acceptance — but any
  change to contract content does. Editing after review requires re-review.
- A missing, malformed, digest-mismatched, or non-`accept` record must be
  refused by consumers. Absence is not approval; a stale digest is not
  approval.
- `decision: revise` or `reject` records are valid records of review — they
  carry the same fields and are retained as history.
