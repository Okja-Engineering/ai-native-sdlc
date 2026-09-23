---
name: describe-workflow
description: Inspect a repository (plus an optional interview record) and produce a versioned observation snapshot of its current delivery workflow — claims with source locators, unresolved conflicts, and a gap report. Use to describe what a team's workflow actually is before proposing changes. Never accepts, exports, or modifies the inspected repository.
license: MIT
compatibility: Markdown files, repository read access, sha256 tooling.
metadata:
  version: "0.1.0"
---

# Describe workflow

Produce a faithful, provenance-backed observation of a repository's current
delivery workflow across three planes — topology, workflow, and context
routing — as a versioned snapshot plus gap report.

## When to use

Use when a team's current workflow is undocumented or disputed and a grounded
description is needed before improvement selection or export. Skip when the
workflow is already expressed as an accepted contract — this skill observes,
it does not accept.

Read the contracts in `references/` progressively:
`observation-contract.md` first, `interview-input.md` only when a WPB
interview record is supplied.

## Inputs

- Inspected repository root (read-only).
- An output root that resolves **outside** the inspected repository.
- A unique run ID for this snapshot.
- Optional: inspection scope (paths relative to the root); default is the
  whole tree excluding `.git`.
- Optional: a WPB interview record conforming to `references/interview-input.md`.

## Process

1. Run `new-snapshot.sh` to create the snapshot skeleton — it refuses
   overlapping output roots and existing run IDs before writing.
2. Inspect routers, config, CI definitions, scripts, docs, and tests.
3. Draft claims as contract blocks: one observed fact each, with plane,
   basis class, and source locators.
4. Record disagreements between sources as conflict blocks — retained
   verbatim, marked unresolved.
5. Record missing facts in `GAP-REPORT.md` as gap blocks with `needed_from`.
6. Validate with `validate-observation.sh`; on rerun, generate
   `COMPARISON.md` against the prior snapshot.

## Deterministic actions

```bash
scripts/new-snapshot.sh "$repo" "$output_root" "$run_id" [--scope paths] [--compare-with "$prior"]
scripts/validate-observation.sh "$snapshot"            # structural + staleness
scripts/compare-observations.sh "$prior" "$snapshot"   # comparison report
scripts/check-interview-record.sh "$interview"         # optional input gate
```

1. Refuse output roots inside the inspected repo (symlink-resolved).
2. Refuse existing run IDs — snapshots are never overwritten.
3. Validate envelope fields, locator syntax, basis enums, conflict integrity.
4. Report staleness when the inspected content no longer matches the snapshot.
5. Reject unsupported interview formats with an explicit diagnostic.

## Orchestration

1. Choose inspection scope and run ID.
2. Sequence the inspection: routers first, then per-plane evidence.
3. Present the snapshot and gap report for owner follow-up.

## AI judgment

- Classify each claim's basis honestly: `declared` for stated policy,
  `configured` for existing config, `executed` only with an execution record
  tied to the inspected revision — a CI definition is never `executed`.
- Draft claims faithfully; mark conflicts unresolved rather than picking a side.
- Decide which missing facts matter enough to list as gaps.

## Outputs

- `OBSERVATION.md` — envelope + claim/conflict blocks.
- `GAP-REPORT.md` — missing facts with who could supply them.
- `SNAPSHOT-MANIFEST` — content hashes of the inspected scope.
- `COMPARISON.md` — on rerun, differences from the prior snapshot.

## Human check

The owner reviews the snapshot for recognition ("is this our workflow?"),
follows up on the gap report, and decides separately whether any observation
should be promoted into a candidate workflow contract.

## Example

```bash
scripts/new-snapshot.sh ../client-repo /tmp/observations run-01 \
  --scope 'AGENTS.md,.github,src'
scripts/validate-observation.sh /tmp/observations/run-01
```

## Constraints

- Never modify the inspected repository; the output root must resolve outside it.
- Never treat an observation as an accepted or executable workflow contract.
- Missing facts are gaps with `needed_from` — never invent locators or claims.
- Conflicting claims keep their own sources and stay `unresolved`.
- `executed` requires an execution record bound to the inspected revision.
- Reruns create new snapshots; prior observations and owner edits are preserved.
- No workflow acceptance, applied export, learning promotion, merge, or
  publication artifacts are produced.
