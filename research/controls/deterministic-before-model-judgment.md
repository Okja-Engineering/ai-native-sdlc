---
id: R-CONTROL-001
title: Deterministic checks before model judgment
domain: controls
kind: control-pattern
status: evaluated
verdict: supported
confidence: high
review_status: pending-owner-review
reviewer: NOT FOUND
reviewed_at: NOT FOUND
supersedes: []
source_locator: ../sources/source-register.md
---

# Deterministic checks before model judgment

## Claim

When an invariant can be established by a type, parser, script, test, policy engine, protected configuration, or reproducible command, that deterministic mechanism should run before probabilistic model review.

## Evidence

| Source ID | Class | Population | Measured outcome | Finding | Limitation |
|---|---|---|---|---|---|
| S-NIST-SSDF-2022-01 | Standard/framework | Secure software development | Practice expectations | Security practices should be integrated into repeatable development controls | Does not specify model-review order |
| S-CISA-SBD-2023-01 | Government guidance | Software products | Structural security responsibility | Safe defaults and structural controls reduce reliance on users | Broad guidance |
| S-SEC-2022-01 | Security evaluation | 1,689 generated programs | Security weaknesses | Generated code can contain material weaknesses | Earlier model and synthetic scenarios |
| S-SEC-2023-01 | Controlled user study | Security-sensitive tasks | Secure output and confidence | AI assistance can produce insecure output and miscalibrated confidence | Bounded tasks and older models |
| S-SKILL-ARCH-2026-01 | Inspected owner project | Agent Skill quality | Static validation | Frontmatter, paths, structure, and scripts can be checked cheaply before semantic judgment | Static checks do not prove live effectiveness |
| S-RLP-2026-01 | Inspected owner project | Repository learning | Promotion hierarchy | Checks and regression tests are stronger durable tiers than context or skills | Pilot effectiveness remains unmeasured |

## Contradictions

Deterministic checks encode only known, formalizable invariants and can be incomplete or wrong. Passing them does not establish product intent, architecture quality, or acceptable residual risk. Model and human review remain necessary for semantic concerns.

## Applicability conditions

- The condition has an observable, reproducible pass/fail form.
- The checker and its configuration are protected from silent weakening.
- Failure output can be traced to the tested revision.

## Package-builder use

```yaml
supports:
  - steps.proposed
  - barriers.why
  - workspace.documents
  - build.tests
does_not_support:
  - steps.current
  - outputs.acceptance
  - judgment.rule
owner_evidence_required:
  - current tools and commands
  - actual invariant or policy owner
  - ability to run and protect the check
  - failure handling
```

## Candidate practice

Partition every requirement into deterministic evidence, AI-assisted semantic review, and retained human judgment. Run in that order and expose gaps.

## Deterministic form

For each required check, record command, revision, exit status, output location, configuration version, and timestamp. A summary without tool evidence remains unverified.

## Human checkpoint

The responsible engineer confirms that deterministic checks cover the intended invariant and judges semantic or policy exceptions they cannot decide.

## Pilot test

- Input: one valid change, one deterministic failure, and one semantically wrong change that passes mechanical checks.
- Expected behavior: the validator blocks the mechanical failure; semantic review flags the third case for human judgment.
- Manual comparison: engineer checks the command output and intent/evidence mismatch.
- Pass/fail rule: pass when known invariants fail closed and passing checks are not represented as complete correctness.
- Failure or exception case: checker unavailable; stop or explicitly downgrade readiness rather than infer success.

## RLP and skill implications

- RLP trigger: a repeated correction that could have been caught by an executable invariant.
- Strongest likely tier: deterministic check or regression test.
- Skill Architect trigger: only when the remaining work is a reusable interpretive procedure after mechanical enforcement.

## Source register

Canonical metadata: `../sources/source-register.md` entries S-NIST-SSDF-2022-01, S-CISA-SBD-2023-01, S-SEC-2022-01, S-SEC-2023-01, S-SKILL-ARCH-2026-01, and S-RLP-2026-01.
