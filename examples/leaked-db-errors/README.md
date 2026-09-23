# Worked example: leaked DB errors → shared error boundary

The same workflow contract expressed in the toolkit's two export forms:

- `compact/SDLC.md` — a single module a repository drops next to its router.
- `modular/ROUTER.md` — an ICM-style package: router, task routing, config,
  shared definition, and one contract per stage under `modular/stages/`.

Both forms carry identical `contract` blocks — the normalized semantic surface
defined by `../../_config/workflow-contract-schema.md`. Prose may differ; the
contract may not. `../../tests/test_export_equivalence.sh` proves it.

## The scenario

A service returns raw database error messages from one API endpoint family.
Desired value: prevent internal details from reaching clients while preserving
server-side diagnostics. The selected slice is a shared error boundary for one
endpoint family — the same case used by the workflow specification's walk test
and the `shape-change`/`verify-change` fixtures.

## What the example teaches

| Lifecycle stage | This tooling |
|---|---|
| Plan, Design | stages 01–03 — intent, slice, evidence plan |
| Build | stage 04 — explicit external boundary: handoff, external actor, return evidence |
| Test | evidence plan + revision-pinned receipt (not CI-integrated evals) |
| Deploy | stage 06 stops at a recorded `merge-ready`; never merges |
| Maintain | out of scope — outcome evaluation is a separate capability |

## What the example demonstrates

- Required entry points plus scoped exploration, not an allow-list or an
  open door.
- Human decisions as recorded fields (`decides`, `decisions`,
  `review_fields`), never inferred from file existence.
- Runtime dependencies (whose artifacts feed whom) kept distinct from
  adoption prerequisites (what must exist before a stage is safe).
- Failure and re-entry behavior declared per stage.
- Risk scaling by risk and coupling, never file count.
