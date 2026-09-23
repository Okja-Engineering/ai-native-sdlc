---
type: schema
id: workflow-observation
schema_version: workflow-observation/0.1.0
status: provisional — owner review pending; does not freeze v1.0
---

# Workflow observation schema (provisional 0.1.0)

The document kind `describe-workflow` emits. An **observation** records what
repository inspection (plus optional interview record) found — claims with
source locators, unresolved conflicts, and gaps. It is not an executable or
accepted workflow contract: `NOT FOUND` and `unresolved` are legal here and
would not be in a `workflow-contract` instance. Promotion to a candidate
contract is a separate human decision, not an output of this artifact.

## 1. Snapshot semantics

Each run writes a new observation directory under an explicitly selected
output root that must resolve **outside** the inspected repository
(symlink-resolved). Prior snapshots are never overwritten or modified.

- `inspected_revision` — the repository's commit at inspection time, or
  `none` when no VCS is present. A commit alone does not identify a dirty
  working tree.
- `snapshot_id` — `sha256:` of the snapshot manifest: one line per inspected
  entry in `inspection_scope`:
  - `<content-hash>  <relpath>` — regular file content;
  - `LINK  <relpath>  ->  <target>  [in-repo|external|broken]` — a symlink's
    identity and literal target. Target content is covered only when the
    resolved target itself falls inside `inspection_scope`; links resolving
    outside the inspected root are marked `external` and never read, and
    links are never followed during expansion;
  - `MISSING  <path>` — a declared-but-absent scope entry.
- `inspection_scope` — comma-separated paths (files or directories) relative
  to the inspected root that the manifest covers.

## 2. Envelope — exactly one `kind: observation` block

| Field | Rule |
|---|---|
| `id` | `obs-<run-id>`; unique per snapshot |
| `kind` | `observation` |
| `schema_version` | must equal `workflow-observation/0.1.0`; anything else fails closed |
| `inspected_repo` | canonical path of the inspected root |
| `inspected_revision` | commit id or `none` |
| `tree_state` | `clean`, `dirty`, or `no-git` |
| `snapshot_id` | `sha256:<hex>` manifest digest |
| `inspection_scope` | comma-separated scope entries |
| `observed_at` | date of the run |
| `observer` | agent/tool identity that produced the snapshot |

## 3. Claim blocks — `kind: claim`

A claim asserts one observed fact about one plane.

| Field | Rule |
|---|---|
| `id` | `claim-NN` |
| `statement` | the observed fact, one line |
| `plane` | `topology`, `workflow`, or `routing` |
| `basis` | `declared` (policy/doc states it), `configured` (config/code exists), or `executed` (an execution record proves it ran) |
| `source` | `|`-separated source locators; required for every claim |
| `execution_ref` | required when `basis: executed` — `<record>@rev:<rev>` with both record and rev nonempty (`rev:x`, `@rev:x`, `r@rev:` all rejected); the rev must equal `inspected_revision` when the latter is a commit. Validates reference shape only — whether the record proves execution is human review |
| `status` | `observed` |

A CI configuration supports `configured` at most; `executed` requires an
execution record tied to the relevant revision.

### Source locators

- `path:line-range` — e.g. `AGENTS.md:14-22` or `SKILL.md:9`
- `interview:<evidence-id>` — a row of an accepted interview record

## 4. Conflict blocks — `kind: conflict`

| Field | Rule |
|---|---|
| `subject` | what the sources disagree about |
| `positions` | `value@locator` items, `|`-separated; each position keeps its own locator; ≥2 required |
| `status` | `unresolved` |

Conflicts are retained verbatim. Resolution is a human act elsewhere.

## 5. Gap blocks — `kind: gap`

| Field | Rule |
|---|---|
| `missing` | the absent fact |
| `needed_from` | the role or source that could supply it |
| `searched` | optional: paths checked before declaring the gap |

A gap must not carry `source` — a missing fact has no evidence locator, and
inventing one is a violation.

## 6. Staleness

An observation is **stale** when the inspected repository no longer matches
the snapshot: recomputing the manifest over `inspection_scope` produces a
different `snapshot_id`, or `inspected_revision` no longer equals HEAD.
Validation reports stale observations as failures; reruns create new
snapshots rather than updating old ones.
