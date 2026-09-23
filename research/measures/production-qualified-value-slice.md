---
id: R-MEASURE-001
title: Production-qualified value-slice measurement
domain: measurement
kind: measurement-pattern
status: evaluated
verdict: supported-pilot-hypothesis
confidence: medium-high
review_status: pending-owner-review
reviewer: NOT FOUND
reviewed_at: NOT FOUND
supersedes: []
source_locator: ../sources/source-register.md
---

# Production-qualified value-slice measurement

## Claim

AI-native SDLC performance should be evaluated using production-qualified outcomes and total delivery cost, not generated code, commit count, or pull-request volume alone.

## Evidence

| Source ID | Class | Population | Measured outcome | Finding | Limitation |
|---|---|---|---|---|---|
| S-NBER-2026-01 | Observational event study | 100,000+ developers and marketplace outcomes | Commits, projects, releases, usage | Large coding activity gains attenuated at release and did not establish proportional usage | Observational and proxy outcomes |
| S-DORA-2025-01 | Global survey and qualitative research | Nearly 5,000 professionals | Throughput, stability, product performance | Delivery outcomes depend on organizational system; stability remained pressured | Correlational and self-report |
| S-SPACE-2021-01 | Research framework | Developer productivity | Multidimensional productivity | Activity is only one dimension and should not stand in for performance | Not AI-specific |
| S-DEVEX-2023-01 | Research framework | Developer experience | Feedback, cognitive load, flow | Human checking and cognitive load are part of effectiveness | Not a direct metric validation study |
| S-WPB-2026-01 | Inspected workflow method | Workflow value analysis | Baseline and calculation rules | Measures require units, periods, scope, provenance, review/rework/setup cost, and matched comparison | Private method; not outcome evidence |

## Contradictions

Activity metrics can diagnose flow and capacity when used alongside outcomes. The rejected claim is that activity alone establishes productivity or value. Some pilots will lack enough production volume for statistical outcome conclusions and should report uncertainty.

## Applicability conditions

- A value slice has an agreed recipient and acceptance condition.
- Production, operator, risk-reduction, or validated-learning outcome can be observed.
- Review, rework, setup, model, CI, and operational effort can be recorded proportionately.

## Package-builder use

```yaml
supports:
  - value.formula
  - value.measures
  - build.done
  - overview.primaryValue
does_not_support:
  - overview.strongestNumber
  - value.calculation
  - value.inputs
  - value.points.evidenceStatus
owner_evidence_required:
  - baseline values with unit, period, scope, and provenance
  - acceptance condition and recipient
  - checking, rework, and setup cost
  - matched measurement period
```

## Candidate practice

Use lead time and total cost per production-qualified value slice as a candidate primary measure, constrained by stability, security, and demonstrated human comprehension.

## Deterministic form

```text
total effort per qualified slice = framing + implementation + checking + rework + release + follow-up
```

Every input records value, unit, period, scope, basis, and source. If any essential input is missing, output `not yet calculable` and a measurement plan.

## Human checkpoint

The owner confirms that the observed outcome represents useful completion and that no waiting time, team effort, or benefit is double-counted.

## Pilot test

- Input: matched completed cases before and during the pilot.
- Expected behavior: activity, qualified completion, guardrails, and cost appear separately.
- Manual comparison: owner verifies units, periods, scope, provenance, and customer/operator outcome.
- Pass/fail rule: pass when a claimed improvement survives inclusion of checking, rework, setup, and stability guardrails; otherwise fail or remain not calculable.
- Failure or exception case: low-volume workflow; report case evidence and uncertainty without extrapolating annual savings.

## RLP and skill implications

- RLP trigger: repeated confirmed misuse of activity as value or repeated calculation/provenance errors.
- Strongest likely tier: schema or deterministic calculation validator.
- Skill Architect trigger: only if RLP selects a recurring measurement-interpretation skill after mechanical checks.

## Source register

Canonical metadata: `../sources/source-register.md` entries S-NBER-2026-01, S-DORA-2025-01, S-SPACE-2021-01, S-DEVEX-2023-01, and S-WPB-2026-01.
