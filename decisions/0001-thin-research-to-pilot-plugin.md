---
id: ADR-0001
status: deferred-pending-workflow-specification
date: 2026-09-07
owner: Matthew Van Dusen
decision_scope: downstream plugin boundary
research_revision: uncommitted
---

# Deferred decision: thin research-to-pilot plugin

> Candidate boundary only. The owner directed the research to establish and approve the workflow specification before skills, phases, and subskills are selected.

## Context

The research identifies a rate mismatch: AI can increase implementation output faster than teams clarify intent, verify correctness, review risk, and absorb changes in production. Existing local systems already own adjacent responsibilities:

- Workflow Package Builder discovers and packages an owner's real workflow.
- Scuba Stack orchestrates substantive software work.
- RLP captures and filters repository learning.
- Skill Architect audits and improves Agent Skills.

Two public AI-native SDLC implementations demonstrate a faithful article companion and a broad full-lifecycle plugin. Both are useful precedents, but neither fills the narrow research-applicability and HITL pilot boundary without duplicating existing ownership.

## Decision

Create a future `sdlc-architect` plugin that prepares and evaluates evidence for one bounded, sequential HITL pilot.

Its initial responsibilities are:

1. Audit atomic AI-native SDLC research cards.
2. Check whether selected research applies to an owner-reviewed workflow package.
3. Assess whether the proposed first test is a reviewable value slice with a real sample, expected result, retained human decision, baseline or measurement plan, and stop condition.

The first implementation slice is only `research-audit` with five reviewed cards, a deterministic validator, and three fixture classes.

## Human authority

The plugin may surface ambiguity, alternatives, evidence, and applicability. Humans retain decisions about workflow truth, value, risk, review boundaries, pilot acceptance, production promotion, and durable learning.

## Ownership boundaries

| Concept or artifact | Owner |
|---|---|
| Owner interview, workflow audit, HTML package, starter files | Workflow Package Builder |
| Software-work orchestration | Scuba Stack or the team's existing process |
| Research cards, applicability, and pilot-readiness checks | SDLC Architect |
| Learning candidates, recurrence, tier, promotion, expiry | RLP |
| Skill audit and rewrite quality | Skill Architect |
| Pilot-run evidence | Pilot workspace |
| Production approval | Named human authority in the pilot team |

## Rejected alternatives

### Full lifecycle plugin

Rejected because it duplicates orchestration, assumes a universal stage model, and optimizes toward autonomous throughput rather than human comprehension.

### Bundle Workflow Package Builder

Rejected because the builder is self-contained and owns a different lifecycle. Bundling would couple releases and blur owner-evidence boundaries.

### Research bundle with no skills

Retained as the fallback if the first pilot shows deterministic research auditing or applicability checks do not reduce error or review effort.

### Automatic learning or skill creation

Rejected because recurrence is only a triage signal. RLP must choose the strongest durable tier, and Skill Architect acts only after RLP selects a skill.

## Consequences

- Research must be atomic, source-addressable, and explicit about owner evidence still required.
- The plugin needs a versioned research snapshot and source-to-artifact map.
- Runtime flow and capability-adoption prerequisites remain separate.
- No plugin skill may create package-builder, RLP-decision, Skill Architect, merge, deploy, or production artifacts.
- Human approval is a recorded state transition, not file existence.
- Package selection may result in a saved prompt rather than an ICM pipeline.

## Acceptance required

The owner must accept, correct, or reject this boundary before implementation begins. Until then, status remains `proposed-for-owner-acceptance`.
