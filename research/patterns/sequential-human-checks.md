---
id: R-HITL-001
title: Sequential human checks at consequence boundaries
domain: governance
kind: design-pattern
status: evaluated
verdict: supported-with-conditions
confidence: medium-high
review_status: pending-owner-review
reviewer: NOT FOUND
reviewed_at: NOT FOUND
supersedes: []
source_locator: ../sources/source-register.md
---

# Sequential human checks at consequence boundaries

## Claim

AI-assisted work should stop for a named human decision before ambiguity, authority, blast radius, or production consequence materially expands.

## Evidence

| Source ID | Class | Population | Measured outcome | Finding | Limitation |
|---|---|---|---|---|---|
| S-NIST-AIRMF-2023-01 | Standard/framework | AI risk management | Governance expectations | Accountability, mapping, measurement, and management remain explicit | Does not prescribe exact checkpoints |
| S-OWASP-GENAI-2026-01 | Community security guidance | LLM and agentic systems | Risk taxonomy | Excessive agency and improper tool use require bounded authority | Guidance, not control-effectiveness proof |
| S-WPB-2026-01 | Inspected workflow method | Workflow packaging | Human-check contract | Current checkpoints and retained judgment determine the recommended structure | Private method; no controlled outcome evidence |
| S-SCUBA-2026-01 | Inspected workflow precedent | Software-work orchestration | Stage and review contracts | Explicit mandates, evidence gates, and current-revision verdicts preserve human authority | Implementation precedent, not outcome study |
| S-DORA-2025-01 | Global survey and qualitative research | Nearly 5,000 professionals | Organizational performance and stability | AI amplifies the surrounding system; control maturity matters | Correlational |

## Contradictions

A human gate on every generated artifact can recreate bureaucracy, increase queues, and encourage approval theater. The pattern applies at consequence boundaries, not every mechanical action. Deterministic checks should remove mechanical work from human review.

## Applicability conditions

- The next action changes authority, risk, customer impact, irreversible state, or interpretive commitment.
- A named person has real authority and enough evidence to decide.
- The gate can record correction, rejection, or escalation—not only approval.

## Package-builder use

```yaml
supports:
  - judgment
  - barriers
  - workspace.documents
  - build.done
does_not_support:
  - judgment.rule
  - judgment.authority
  - steps.current
  - meta.reviewNote
owner_evidence_required:
  - decision the owner retains
  - actual decision cues
  - final authority
  - consequence of a wrong or skipped check
```

## Candidate practice

Place explicit human checks only where consequence expands. Each check names the reviewer, compared evidence, pass condition, failure behavior, and review marker consumed by the next step.

## Deterministic form

Require `review_status`, `reviewer`, `reviewed_at`, `evidence_revision`, and `decision` fields before a downstream stage reads an artifact. Reject file existence as proof of review.

## Human checkpoint

The owner decides where human judgment is necessary and removes gates that merely repeat deterministic checks.

## Pilot test

- Input: one normal case, one missing-evidence case, and one known exception.
- Expected behavior: normal work stops only at named consequence boundaries; missing evidence blocks advancement; exceptions route to the stated authority.
- Manual comparison: owner checks whether each gate changed or protected a real decision.
- Pass/fail rule: pass when no consequential transition occurs without recorded human judgment and no human gate exists solely for machine-provable work.
- Failure or exception case: emergency rollback through a pre-approved runbook; record action and require retrospective human review.

## RLP and skill implications

- RLP trigger: repeated confirmed bypass, ambiguous ownership, or approval theater at the same boundary.
- Strongest likely tier: protected gate or status validator before context or skill.
- Skill Architect trigger: only if RLP selects a skill for a recurring interpretive review.

## Source register

Canonical metadata: `../sources/source-register.md` entries S-NIST-AIRMF-2023-01, S-OWASP-GENAI-2026-01, S-WPB-2026-01, S-SCUBA-2026-01, and S-DORA-2025-01.
