---
id: R-FLOW-001
title: Reviewable value slice
domain: flow
kind: design-pattern
status: evaluated
verdict: supported-pilot-hypothesis
confidence: medium
review_status: pending-owner-review
reviewer: NOT FOUND
reviewed_at: NOT FOUND
supersedes: []
source_locator: ../sources/source-register.md
---

# Reviewable value slice

## Claim

The most useful candidate flow unit for sequential HITL delivery is the smallest independently valuable change a human can understand, verify, approve, and safely promote without depending on unmerged work.

## Evidence

| Source ID | Class | Population | Measured outcome | Finding | Limitation |
|---|---|---|---|---|---|
| S-DORA-CAP-2025-01 | Research-derived framework | Technology organizations | Conditions associated with AI value | Small batches, strong VCS, quality platforms, and user focus amplify AI value | Does not define a universal slice threshold |
| S-SPACE-2021-01 | Research framework | Developer productivity | Multidimensional productivity | Activity alone is insufficient; performance, satisfaction, communication, and flow matter | Not AI-specific |
| S-LEAN-2011-01 | Practitioner framework | Product experiments | Validated learning | Small experiments reduce untested investment | Not controlled AI-SDLC evidence |
| S-XP-1999-01 | Practitioner framework | Software delivery | Small-release and feedback practices | Small, frequent, feedback-rich change is preferred | Requires local fit |
| S-WPB-2026-01 | Inspected workflow method | Workflow discovery and package design | Structure-selection rule | The repeating unit and real human checkpoints should determine the smallest useful form | Private method; not outcome evidence |

## Contradictions

No source establishes a universal maximum size or proves this exact unit. Very small slices can increase coordination, integration, and release overhead or fail to deliver independent value. The pattern remains a pilot hypothesis rather than a law.

## Applicability conditions

- The intended outcome can be decomposed without creating inert partial work.
- The team can identify an observable user, operator, risk-reduction, or learning outcome.
- The slice can be verified and either reversed or contained proportionately.

## Package-builder use

```yaml
supports:
  - workspace.repeatUnit
  - workspace.reason
  - build.slice
  - build.why
does_not_support:
  - overview.sentence
  - steps.current
  - outputs.acceptance
  - judgment.rule
owner_evidence_required:
  - actual repeating unit
  - trigger and definition of done
  - real human checkpoints
  - accepted output and recipient
```

## Candidate practice

Before implementation, compare at least two decompositions and choose the smallest candidate that remains valuable, bounded, reviewable, verifiable, shippable, reversible, and traceable.

## Deterministic form

Validate presence of seven fields: value, boundary, reviewer, acceptance evidence, independent promotion, rollback or containment, and traceability ID. Field presence does not prove semantic adequacy.

## Human checkpoint

The accountable owner chooses the slice and confirms that it is useful on its own rather than merely small.

## Pilot test

- Input: one completed change and two proposed decompositions.
- Expected behavior: the selected slice preserves an independent outcome and one coherent review decision.
- Manual comparison: owner checks usefulness, dependencies, verification burden, and rollback.
- Pass/fail rule: pass when the slice can ship and be evaluated independently; fail when it is inert, hides dependencies, or requires several approvals to understand one outcome.
- Failure or exception case: an atomic migration or cross-system change that cannot be safely decomposed; retain a larger unit and strengthen evidence.

## RLP and skill implications

- RLP trigger: repeated confirmed corrections that slices are inert, oversized, or hide dependencies.
- Strongest likely tier: template/schema or planning check before a skill.
- Skill Architect trigger: only if RLP establishes a recurring judgment procedure that cannot be captured by a simpler check.

## Source register

Canonical metadata: `../sources/source-register.md` entries S-DORA-CAP-2025-01, S-SPACE-2021-01, S-LEAN-2011-01, S-XP-1999-01, and S-WPB-2026-01.
