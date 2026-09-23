# Research packet: sequential HITL AI-native SDLC

## Mandate

Design an evidence-backed approach that helps a pilot engineering team move from automation pressure to human augmentation. The system must deliver smaller, safer, human-reviewable chunks of value and must not hide judgment inside autonomous agent loops.

## Finding

The central problem is a mismatch of rates: AI can increase implementation output faster than teams can clarify intent, produce independent evidence, review semantic risk, and absorb changes in production. Maximizing generation therefore optimizes the wrong stage.

The correct intervention is a sequential evidence pipeline. At each stage, deterministic machinery prepares a bounded artifact; orchestration routes it; AI performs a narrow interpretive task; and a named human decides whether risk may expand.

## Flow unit

Use the **reviewable value slice** as the pilot hypothesis: the smallest independently valuable, bounded, verifiable, shippable, reversible, and traceable change. A prompt, session, commit, ticket, or PR is a container, not the unit itself.

## Proposed stage model

| Stage | Deterministic preparation | AI augmentation | Human decision |
|---|---|---|---|
| Intent | Required outcome, owner, constraints, non-goals, risk fields | Surface ambiguity and competing interpretations | Confirm the problem and acceptable risk. |
| Slice | Independence, rollback, boundary, and dependency checks | Propose alternative decompositions | Select the smallest coherent value slice. |
| Evidence | Acceptance checks and baseline outcome definition for the selected slice | Suggest missing failure modes | Confirm what would prove or falsify success. |
| Build | Isolated workspace, scoped tools, exact commands, continuous tests | Implement and explain deviations | Intervene only on ambiguity or policy escalation. |
| Verify | Types, tests, scans, policy, provenance, CI-integrity checks | Compare intent, plan, diff, and evidence semantically | Judge architecture, intent, exceptions, and residual risk. |
| Promote | Protected branch, artifact identity, environment policy, rollback readiness | Summarize evidence receipt | Authorize consequence-bearing promotion. |
| Observe | Deployment correlation, SLOs, product metrics, agent/action logs | Triage anomalies and draft hypotheses | Decide rollback, follow-up intent, or no action. |
| Learn | RLP capture, recurrence count, expiry, promotion checks | Classify candidate learning | Approve check, test, scoped context, skill, or discard. |

## 60/30/10 design test

- The **60% deterministic** layer establishes the truth surface: required fields, executable checks, immutable evidence, permissions, provenance, metrics, and stop conditions.
- The **30% orchestration** layer keeps the process legible: stages, routing, risk tiers, bounded retries, checkpoints, and handoffs.
- The **10% AI judgment** layer is explicit and reviewable: ambiguity detection, alternative slicing, semantic review, and evidence synthesis.

The human role is outside the ratio: humans own intent, risk acceptance, exceptions, and promotion. The ratio describes the agent-facing workflow, not a reduction of human accountability to zero.

## Best practices selected

1. Baseline the complete value stream before intervention.
2. Start with one team, one repository, and one representative change class.
3. Use a minimal intent/evidence contract rather than mandatory document volume.
4. Establish the failing condition or acceptance evidence before implementation.
5. Keep one value slice per bounded workspace and review decision.
6. Protect tests, CI, policy, and provenance from silent weakening.
7. Use AI review as a second perspective, never as self-approval.
8. Scale concurrency only while human review remains coherent.
9. Grant least agency and increase authority by proven action class.
10. Connect production outcomes and corrections back to the generating repository system.

## Measurement model

Primary candidate metric:

> Lead time and total cost per production-qualified value slice, constrained by stability, security, and demonstrated human comprehension.

Guardrail metrics:

- rework after approval;
- change failure and rollback rate;
- escaped defects and vulnerabilities;
- review time and intervention rate;
- first-pass evidence success;
- stage queue time;
- cognitive-load and comprehension checks;
- model, CI, review, and operational cost;
- customer or operator outcome.

## Rejected alternatives

- **End-to-end autonomous factory:** rejected because it optimizes automation rate and hides consequence-bearing judgment.
- **Document-heavy stage gates:** rejected because replacing meetings with Markdown can preserve the same queue and cognitive burden.
- **PR or agent session as flow unit:** rejected because neither guarantees independent value, verification, or safe promotion.
- **AI-only review:** rejected because probabilistic review cannot enforce hard invariants or carry accountability.

## Package Builder boundary

Industry research may support a proposed practice, its rationale, applicability questions, control patterns, and pilot tests. It cannot establish an owner's current steps, retained judgment, access, baseline, quotations, or approval. Workflow Package Builder owns `workflow-audit.md`, `my-workflow-package.html`, and `starter-files.md`; this research does not generate or pre-compose them.

The atomic research library under `research/` separates R-prefixed evaluated cards from S-prefixed sources. Owner interview evidence uses a separate E namespace, and inspected owner documents use D. A recommendation becomes locally grounded only when the owner evidence establishes its applicability.

## Plugin-family boundary

The selected downstream direction is a thin research-to-pilot plugin:

- SDLC Architect owns research auditing, package applicability checks, pilot readiness, and reviewable-slice analysis.
- Workflow Package Builder owns owner-specific audit and package rendering.
- Scuba Stack may own implementation orchestration.
- RLP owns correction capture, recurrence, promotion tier, provenance, and expiry.
- Skill Architect owns Agent Skill audit and rewrite quality.

The plugin will not own the full Plan → Maintain lifecycle, autonomous agent organizations, package outputs, implementation, deployment, RLP decisions, or Skill Architect findings.

## Adoption and runtime are distinct

Capability adoption proceeds from reviewed research cards to research audit, owner-reviewed package applicability, pilot readiness, and only then a human-confirmed learning handoff. One pilot run follows the owner's actual repeating unit and checkpoints; it is not forced into a six-stage pipeline or universal `intent.md`, `spec.md`, and `plan.md` chain.

## Learning correction

A second occurrence is evidence for RLP triage, not permission to write directly to repository context or create a skill. RLP still selects the strongest durable tier:

```text
check > regression test > scoped context > skill > discard
```

Only an RLP-approved skill candidate proceeds to Skill Architect.

## First downstream implementation slice

When implementation is separately authorized, begin with only `research-audit`, five reviewed bundled research cards, one deterministic validator, and valid/missing-evidence/conflicting-evidence fixtures. The initial slice must prove that it detects research defects and does not create downstream-owned artifacts.

## Open questions for Stage 04

- How should the pilot test human comprehension without surveillance or vanity scoring?
- Which existing team workflow offers enough baseline history for comparison?
- What risk tier and change class are representative but safely bounded?
- Which plugin behavior is essential for one end-to-end slice, and which belongs after the pilot?
- What negative result would cause the approach or flow-unit hypothesis to be revised?
