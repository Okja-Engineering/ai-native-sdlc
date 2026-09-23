# Research card schema

Research should prepare recommendations for Workflow Package Builder without impersonating the workflow owner. Store one material claim or practice per card.

```yaml
---
id: R-VERIFY-001
title: Verification capacity constrains AI-assisted delivery
domain: verification
kind: empirical-claim
status: evaluated
verdict: supported-with-conditions
confidence: high
review_status: reviewed
reviewer: research-owner
reviewed_at: YYYY-MM-DD
supersedes: []
---
```

## Claim

One falsifiable sentence.

## Evidence

| Source ID | Class | Population | Measured outcome | Finding | Limitation |
|---|---|---|---|---|---|
| S01 | controlled empirical | exact studied population | exact outcome | result with units | applicability limit |

## Contradictions

Name conflicting or null evidence. Reconcile differences in population, intervention, outcome, and date without averaging unlike measures.

## Applicability conditions

State what must be true before this evidence can support a recommendation for an owner's workflow.

## Package-builder use

```yaml
supports:
  - value.hypothesis
  - barriers[].why
  - workspace.reason
  - build.why
does_not_support:
  - overview.sentence
  - steps[].current
  - judgment.rule
owner_evidence_required:
  - actual bottleneck
  - current review time
  - retained decision maker
```

## Candidate practice

Describe the minimum vendor-neutral practice justified by the evidence.

## Deterministic form

Exact check, schema, command, or observable pass condition when one exists. Write `none` when the practice remains contextual.

## Human checkpoint

Name the decision a person must retain and the evidence they inspect.

## Pilot test

- Input:
- Expected behavior:
- Manual comparison:
- Pass/fail rule:
- Failure or exception case:

## RLP and skill implications

State only candidate routing:

- RLP trigger: what observed correction or recurrence would justify capture.
- Strongest likely tier: check, test, scoped context, skill, or discard.
- Skill Architect trigger: only after RLP selects a skill as the appropriate durable tier.

## Source register

| ID | Citation | URL | Date | Evidence class | Independence |
|---|---|---|---|---|---|

## Rules

- Industry research can justify a proposed practice; it cannot establish what an owner currently does.
- Owner interviews and inspected workflow files outrank general research for workflow facts.
- Vendor documentation proves capability, not outcome effectiveness.
- Unknown applicability remains a question or pilot hypothesis.
- One fact has one canonical card; indexes link rather than duplicate it.
