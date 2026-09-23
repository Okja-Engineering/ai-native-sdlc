# Observation contract quick reference

Canonical schema: `_config/workflow-observation-schema.md`
(`workflow-observation/0.1.0`, provisional).

An observation records what was found — it is not an accepted or executable
workflow contract. `NOT FOUND` facts become gap blocks; conflicts stay
`unresolved`.

## Envelope (exactly one, `kind: observation`)

`id` (obs-<run-id>) · `schema_version` · `inspected_repo` ·
`inspected_revision` (commit or `none`) · `tree_state` (clean|dirty|no-git) ·
`snapshot_id` (sha256 of the scope manifest — covers uncommitted/untracked
files) · `inspection_scope` · `observed_at` · `observer`.

## Claim (`kind: claim`)

`id` · `statement` · `plane` (topology|workflow|routing) ·
`basis` (declared|configured|executed) · `source` (locators, `|`-separated) ·
`status` (observed) · `execution_ref` (required when basis is `executed`;
form `record@rev:<id>` bound to the inspected revision).

Locators: `path:line-range` or `interview:<evidence-id>`.

## Conflict (`kind: conflict`)

`subject` · `positions` (`value@locator`, ≥2, each keeps its own source) ·
`status: unresolved`.

## Gap (`kind: gap`)

`missing` · `needed_from` · optional `searched`. Never carries `source`.
