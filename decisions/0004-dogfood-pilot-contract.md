---
id: ADR-0004
status: proposed
date: 2026-09-13
owner: Matthew Van Dusen
scope: dogfood pilot contract for the evidence-led-delivery plugin
---

# Dogfood pilot contract

Proposed Slice 4 contract. Pending owner review — nothing here is authorized until the owner records accept / revise / reject.

## Pilot identity

- Team: owner plus one Devin agent session. On this one-person team the owner holds request-owner, accountable-engineer, independent-reviewer, and merge-authority roles; each decision is still recorded explicitly.
- Repository: `ai-native-sdlc` (this repository — dogfood first per owner direction 2026-09-13).
- Completed evidence-to-intent case: `.devin/eval/20260913-normal/output/run-01/intent-specification.md` (validator-passed, owner review pending).
- External demo target after the pilot: `../skill-architect` (owner direction 2026-09-13; not part of this pilot).

## Pilot slice candidate

The first dogfood change should be a real, bounded gap observed during live evaluation:

> The evidence-to-intent contract requires "a gap report when required inputs or acceptance cues are absent," but no gap-report contract or validator exists. Add a `references/gap-report-contract.md` and extend validation so a run that stops early leaves a checkable artifact.

Alternatives the owner may prefer: a missing negative test class, or another small change the owner names. The owner selects; this is a recommendation.

## Baseline measurement plan

No savings claims. Record, for the pilot slice and one comparable recent change made without the pipeline:

- time from raw request to owner-accepted intent;
- human checkpoints exercised and review effort per checkpoint;
- share of acceptance criteria with executed revision-linked evidence;
- rework cycles after acceptance;
- whether the owner can explain the merged change from its artifacts alone.

Matched comparison is weak on a one-person repository; results are pilot observations, not ROI.

## Boundaries

- Allowed inputs: this repository's files and the `research/` corpus. No network access, no external repository mutation.
- Output root: `changes/{slice-id}/` following the workflow-specification artifact layout.
- Human checks: every artifact carries review fields; no phase advances on AI text alone.
- Stop conditions: missing owner fact, unresolved contradiction, weakened or missing required check, scope expansion beyond the selected slice, or any request to implement `reviewable-delivery`, merge, deploy, promote learning, or audit skills.

## Guardrails

- Zero provenance errors (every claim cites E/D/R/A/Q or is marked NOT FOUND).
- Zero unsupported prescriptions reaching review.
- `implementation_authorized` semantics preserved everywhere except the single selected slice.
- Negative and null results retained in `.devin/eval/` or `changes/` records.

## Rollback

- `devin plugins remove evidence-led-delivery` if installed.
- Pilot artifacts are markdown and validators only; removal is file deletion plus roadmap status correction.
