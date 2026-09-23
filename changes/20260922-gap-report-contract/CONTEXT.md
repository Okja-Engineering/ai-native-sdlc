# changes/20260922-gap-report-contract — workspace router

One bounded slice: give `evidence-to-intent`'s already-promised gap report a
contract and deterministic validation. **Draft — not authorized for
implementation.** Planning artifacts only; no implementation has occurred.

## Load order

| Step | Read | Never load |
|---|---|---|
| 1 | `AGENTS.md`, `.devin/roadmap.md` (decisions + this thread) | `research/` corpus (claims, patterns, controls, measures, sources), `research/stages/` other than the one file named below |
| 2 | This file, then `01-intent.md` → `02-slice.md` → `03-evidence-plan.md` | Other `changes/` workspaces |
| 3 | Planning or executing: `04-implementation-plan.md`, then `skills/evidence-to-intent/SKILL.md` + its two named references | Sibling skills' internals |

Parent references (canonical, do not copy):

- Method contract: `research/stages/03-synthesize/output/workflow-specification.md`
  — the single permitted `research/stages/` read for this workspace.
- Pilot frame: `decisions/0004-dogfood-pilot-contract.md` (`status: proposed`)
- Gap evidence: `skills/evidence-to-intent/SKILL.md` lines 26/60;
  `.devin/eval/20260922-skill-architect-intent/output/run-09/gap-report.md`
  (historical evidence of a real stop — an input to requirements, not the
  contract itself)

## Permitted writes (when the slice is separately authorized)

- `skills/evidence-to-intent/references/gap-report-contract.md` (new)
- `skills/evidence-to-intent/scripts/validate-gap-report.sh` (new —
  recommended approach, see `02-slice.md`)
- `skills/evidence-to-intent/SKILL.md` — one pointer line to the contract
- `tests/test_evidence_to_intent.sh`, `tests/fixtures/`
- This directory's artifacts; `.devin/eval/eval-log.md` entry; roadmap status

Not permitted: schema version bumps, sibling-skill changes, any write outside
this repository, commit/install/publish.

## Consolidated owner decision (one ask)

To begin this slice the owner answers one decision covering four parts —
accept / revise / reject as a whole or per part:

1. **Intent** — `01-intent.md` states the problem and non-goals correctly,
   and the CONTEXT.md "current product intent" deltas (root file) are the
   right unresolved set.
2. **Slice** — `02-slice.md`'s boundary is the right unit, including the
   recommended sibling-validator approach.
3. **Evidence plan** — `03-evidence-plan.md`'s structural/behavioral split
   and the named live missing-input evaluation are the right proof.
4. **Plan** — `04-implementation-plan.md`'s file set, order, and the
   revision-identity handling are acceptable.

Deferred, not in scope: run-09's other findings (validator ID-suffix false
positives, `source_revision` unavailability, describe-workflow composition,
Q17 tooling) — separate slices, not this workspace's decision.

## Re-entry

A change to `PRINCIPLES.md`, the workflow specification, or the evidence
schema reopens `01-intent.md`. A change to `evidence-to-intent`'s SKILL.md
contract reopens `02-slice.md`. Any revision change after review reopens
review (`review-pending`).
