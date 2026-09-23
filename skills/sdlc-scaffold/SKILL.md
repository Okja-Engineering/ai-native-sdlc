---
name: sdlc-scaffold
description: Propose minimal sequential HITL intent-to-merge workspace contracts for a repository. Use when a team has accepted the workflow specification and wants to evaluate project-local wiring without overwriting its existing router or process.
license: MIT
compatibility: POSIX shell, git.
metadata:
  version: "0.1.0"
---

# SDLC scaffold

Propose the smallest project-local form that can preserve reviewed intent, evidence, and merge-readiness decisions.

## When to use

Use after the owner accepts the workflow specification and identifies a target repository. Skip when a saved prompt or existing process already carries the required checks and human decisions.

Read `references/README.md` for proposed paths and validation.

## Inputs

- Accepted workflow specification.
- Target repository's existing routers, rules, tests, CI, ownership, and planning artifacts.
- Owner decision on whether a saved prompt, existing workflow, or folder scaffold is the smallest useful form.

## Process

Run the deterministic inspection first, then the orchestration and human checkpoint below.

## Deterministic actions

```bash
scripts/validate-scaffold-input.sh "$target_repo" "$workflow_spec"
```

1. Confirm the target repository and accepted workflow specification are supplied and exist.
2. Inspect existing files and resolve every proposed path.
3. Compare content before proposing an edit.
4. Produce an exact create/modify/unchanged map.
5. Validate review markers, idempotency, and cold-session routing when implementation is later authorized.

### Export an accepted contract to proposal files

```bash
scripts/export-proposal.sh --input "$contract" --acceptance "$record" \
  --client "$client_repo" --output "$proposal_root" --form compact|modular|both
```

Requires a sibling `contract-acceptance` record (`_config/contract-acceptance-schema.md`)
whose digest matches the contract's normalized content. Renders into staging,
validates the package (contract + loading rules), then publishes CREATE/SAME
only — a conflicting destination file refuses the whole export. The output
root must sit outside both the input and client roots, symlink-resolved.
Read `references/export-contract.md` before use.

## Orchestration

1. Classify the smallest useful form; default to no scaffold when existing files suffice.
2. Present proposed files, modifications, dependencies, and exclusions.
3. Stop for explicit owner approval before any write to the target repository.
4. If separately approved, route creation and validation as a later implementation task.

## AI judgment

- Determine whether existing files satisfy the accepted contract.
- Recommend saved prompt, merged route, or folder scaffold without selecting for the owner.

## Outputs

- Proposed scaffold map and unchanged-file report.
- No target-repository files during research or without explicit approval.

## Human check

The repository owner confirms every proposed file has one job, fits existing conventions, and adds less burden than the current process.

## Example

```text
Input: existing AGENTS.md already routes planning and verification
Recommendation: amend one route and add one value-slice template
Not recommended: replace AGENTS.md or create a parallel router
```

## Constraints

- Do not overwrite owner text or duplicate routes.
- Do not imply that a proposed workspace already exists.
- Do not scaffold the full lifecycle when a smaller form works.
- Do not implement during the research phase.
