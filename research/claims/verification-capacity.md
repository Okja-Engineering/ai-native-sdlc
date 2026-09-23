---
id: R-VERIFY-001
title: Verification capacity constrains AI-assisted delivery
domain: verification
kind: empirical-claim
status: evaluated
verdict: supported-with-conditions
confidence: high
review_status: pending-owner-review
reviewer: NOT FOUND
reviewed_at: NOT FOUND
supersedes: []
source_locator: ../sources/source-register.md
---

# Verification capacity constrains AI-assisted delivery

## Claim

When AI increases implementation output faster than a team increases specification, testing, review, and release capacity, local coding gains attenuate before production and can increase rework or instability.

## Evidence

| Source ID | Class | Population | Measured outcome | Finding | Limitation |
|---|---|---|---|---|---|
| S-NBER-2026-01 | Observational event study | 100,000+ GitHub developers and marketplace outcomes | Commits, projects, releases, usage | Gains attenuated from coding activity to releases and did not establish proportional usage value | Observational and proxy outcomes |
| S-DORA-2024-01 | Global survey | Approximately 3,000 professionals | Delivery throughput and stability | Higher AI adoption correlated with lower throughput and stability in 2024 despite individual gains | Correlation and self-report |
| S-DORA-2025-01 | Global survey and qualitative research | Nearly 5,000 professionals | Throughput, stability, organizational performance | Throughput association improved, but stability remained pressured; AI amplified existing systems | Correlation and self-report |
| S-METR-2025-01 | Randomized controlled trial | 16 experienced maintainers, 246 tasks | Completion time | AI-allowed tasks took 19% longer | Small sample and early-2025 tools |

## Contradictions

S-FIELD-2025-01 reports a roughly 26% increase in completed tasks. This is not a direct contradiction: it measures bounded task completion in company field experiments, while the claim concerns attenuation across the delivery system. The evidence establishes conditional acceleration, not universal slowdown.

## Applicability conditions

- The team uses AI for implementation work.
- Work passes through at least one downstream specification, verification, review, integration, or release boundary.
- Local coding activity and production outcomes can be distinguished.

## Package-builder use

```yaml
supports:
  - value.hypothesis
  - barriers.why
  - workspace.reason
  - build.why
does_not_support:
  - overview.sentence
  - overview.strongestNumber
  - steps.current
  - judgment.rule
owner_evidence_required:
  - actual current bottleneck
  - baseline queue and active time by step
  - current stability or rework measure
  - accountable decision maker
```

## Candidate practice

Baseline the complete owner workflow and increase AI-generated volume only after identifying and protecting the current constraint.

## Deterministic form

Require separately named measures for implementation activity, review/rework, production-qualified changes, and outcome. Reject a baseline that uses commits, pull requests, or generated lines as the sole value measure.

## Human checkpoint

The workflow owner confirms which constraint is real and whether the selected baseline reflects useful completion rather than activity.

## Pilot test

- Input: matched pre-pilot and pilot cases from one change class.
- Expected behavior: local speed and downstream cost are reported separately.
- Manual comparison: owner compares stage timestamps, review effort, rework, and production result.
- Pass/fail rule: pass when the pilot improves lead time or effort without worsening agreed stability and comprehension guardrails; otherwise fail or remain inconclusive.
- Failure or exception case: no reliable baseline; record a measurement plan and do not claim savings.

## RLP and skill implications

- RLP trigger: a confirmed repeated correction caused by optimizing generation while omitting required downstream evidence.
- Strongest likely tier: deterministic metric or gate before scoped context or skill.
- Skill Architect trigger: only if RLP selects a reusable skill after stronger tiers are considered.

## Source register

Canonical metadata: `../sources/source-register.md` entries S-NBER-2026-01, S-DORA-2024-01, S-DORA-2025-01, S-METR-2025-01, and S-FIELD-2025-01.
