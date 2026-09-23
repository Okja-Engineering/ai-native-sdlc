---
type: schema
id: workflow-contract
schema_version: workflow-contract/0.1.0
status: provisional — owner review pending; does not freeze v1.0
---

# Workflow contract schema (provisional 0.1.0)

The canonical model a team's delivery workflow is expressed in. Compact and
modular exports are representations of this contract; the contract and its
semantics — not file names or layouts — are the compatibility surface.

## 1. Document kinds

- `workflow` — one contract block describing the whole workflow: stage list,
  schema version, risk-scaling rule, named owner.
- `stage` — one contract block per stage. `kind: internal` stages are executed
  under this toolkit's contracts. `kind: external` stages are executed by an
  actor outside this toolkit (e.g., the team's implementation process); their
  contract names the handoff, the external actor, required outputs, and the
  evidence returned.

## 2. Contract block format

A contract block is a fenced ```` ```contract ```` section containing one
`key: value` per line. List values are `|`-separated. This line-oriented form
is deliberate: it is the normalized semantic surface that deterministic
validators and the equivalence check read. Prose around the block may explain;
it may not contradict the block.

```contract
id: 01-intent
kind: internal
purpose: Record the owner's problem and desired outcome.
inputs: raw-request@E | repo-rules@D
outputs: changes/{slice-id}/01-intent.md
acceptance: required-fields-present | unknowns-marked-not-found
decides: request-owner
may_not: self-approve | infer-missing-facts
decisions: accept | correct | reject
runtime_deps: none
adoption_deps: named-request-owner
context_entry: raw-request | router
context_explore: repo-rules-scope
context_never: other-slice-folders | run-transcripts
on_missing_input: stop
on_conflict: retain-both
reentry: intent-pending
review_fields: review_status | reviewer | reviewed_at | decision
```

## 3. Fields

### Required for every stage

| Field | Rule |
|---|---|
| `id` | `NN-kebab-slug`; unique within the workflow |
| `kind` | `internal` or `external` |
| `purpose` | one line |
| `inputs` | `name@provenance` entries; provenance from E, D, R, A, Q, S, or `runtime:<stage-id>` |
| `outputs` | relative paths; `{slice-id}` and similar `{placeholder}` allowed for runtime artifacts |
| `acceptance` | named checks or `retained:<judgment>` entries — what would falsify this stage's product |
| `decides` | the single role that decides this stage's outcome; `external-actor` only when `kind: external` |
| `may_not` | actions this stage's executor must not take |
| `decisions` | allowed terminal values; `none` only when the stage emits no decision |
| `runtime_deps` | stage ids whose outputs this stage consumes; `none` if empty |
| `adoption_deps` | capabilities that must exist before this stage is safe; `none` if empty |
| `context_entry` | required reads — entry points, not an allow-list |
| `context_explore` | scoped rules for additional reading and how conflicts surface; `none` permitted |
| `context_never` | hard exclusions |
| `on_missing_input` | `stop`, `not-found`, or `escalate` |
| `on_conflict` | `retain-both`, `stop`, or `escalate` — `escalate` surfaces the conflict to the deciding human rather than resolving it in-stage |
| `reentry` | state returned to on failure |
| `review_fields` | review marker fields this stage's output must carry |

### Additional required fields when `kind: external`

| Field | Rule |
|---|---|
| `external_actor` | who executes (team agent, orchestrator, manual process) |
| `handoff` | what crosses the boundary outward |
| `return_evidence` | what must come back for the next internal stage |

### Workflow-level block — required fields

| Field | Rule |
|---|---|
| `id` | stable workflow identifier |
| `kind` | `workflow` |
| `schema_version` | must equal a supported version (see §6) |
| `stages` | ordered stage id list; must match the declared stage blocks exactly |
| `risk_scaling` | named rule scaling required evidence/review depth by risk and coupling — never by file count |
| `owner` | named owner or explicit `NOT FOUND` |

### Optional fields

`example`, `notes`, `supersedes`, `basis` — informational; ignored by
equivalence.

## 4. Unknowns and defaults

- An absent required fact is written `NOT FOUND`, never inferred.
- `none` is the explicit empty list, not an omission.
- No field has a hidden default. If a field is absent it is a validation
  failure, not an implied value.

## 5. Context semantics

`context_entry` items are required entry points. `context_explore` declares
where controlled exploration is permitted (e.g., `declared-runtime-deps`,
`repo:<path-prefix>`) and the surfacing rule: exploration that uncovers a
contradiction with declared inputs stops the stage and presents the conflict
for human decision. `context_never` items are hard exclusions; referencing one
fails validation. Write and authority boundaries remain strict regardless of
exploration scope.

Path-valued context entries resolve relative to the file containing the block.
Entries without `/` are named resources, not checked for existence. Runtime
artifact paths (`changes/`, `output/`, `{placeholder}` paths) are exempt from
resolution checks.

## 6. Versioning and compatibility

- `schema_version: workflow-contract/0.1.0` is the only supported version.
- An unrecognized version fails closed; a validator must not guess semantics.
- The compatibility surface is the normalized contract (§7): stage id set and,
  per stage, `kind`, `decides`, `decisions`, `may_not`, `runtime_deps`,
  `adoption_deps`, `acceptance`, `inputs`, `outputs`, `on_missing_input`,
  `on_conflict`, `reentry`, `review_fields`, `context_*`, and external-stage
  fields. Prose, filenames, and directory layout are not part of it.
- Risk scaling may change required evidence and review depth between workflow
  instances. It must not remove authority, provenance, or review fields.
- Migration policy: until 1.0, breaking changes require a new schema version
  and owner review of this file. No automatic migration exists yet.

## 7. Equivalence

Two export forms are equivalent iff their normalized contract blocks are
identical under §6's field set. Normalization: parse each block into
`key → sorted items`, emit one `id::key=item` line per item, sort, compare.
One line per item keeps boundaries unambiguous — items may contain commas or
other punctuation, so no in-line joiner is safe. Any difference is a failure
listing both values — not an average.

## 8. Acceptance vs application

A reviewed workflow contract records human acceptance of the workflow. That is
distinct from permission to apply an export into a target repository. Export
produces reviewable proposals; it must not overwrite owner-authored text and
does not imply installation authority.
