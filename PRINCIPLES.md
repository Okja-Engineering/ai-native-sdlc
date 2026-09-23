# AI-Native SDLC principles

## Core beliefs

1. **Augmentation before automation.** Agents prepare work and evidence; humans retain judgment at consequence-bearing boundaries.
2. **Value is the flow unit.** Optimize for the smallest independently valuable, reviewable, verifiable change—not prompts, sessions, commits, pull requests, or lines of code.
3. **Determinism first.** If an invariant can be proven by a script, type, test, policy, or protected gate, do not delegate it to model judgment.
4. **Sequential HITL processing.** Every stage produces an inspectable artifact and an explicit human decision before risk expands.
5. **Evidence before confidence.** An agent reports what was run and observed; it does not self-certify correctness.
6. **Small batches de-risk production.** Slice by customer-visible or operator-visible value and preserve a working system after every slice.
7. **The constraint governs throughput.** Increasing code generation without increasing specification, verification, or review capacity creates queues and instability.
8. **Least agency.** Grant the smallest set of decisions and actions needed for the current stage, in addition to least-privilege access.
9. **Production closes the loop.** Runtime behavior and customer outcomes feed tests, controls, context, and future intent.
10. **Learning is filtered.** Corrections enter RLP; only repeated, proven, scoped, deletable knowledge becomes durable.

## The 60/30/10 heuristic

### Deterministic actions — 60%

Exact commands, file locations, schemas, policy checks, test expectations, provenance, and pass/fail criteria. These form the reliable skeleton.

### Orchestration — 30%

Routing, stage order, bounded retries, human checkpoints, risk escalation, handoffs, and stop conditions. This makes the skeleton usable without hiding workflow in code.

### AI judgment — 10%

Interpreting ambiguity, comparing conflicting sources, identifying semantic risk, and drafting recommendations. Every judgment must expose its evidence and uncertainty.

The ratio is directional, not arithmetic compliance. High-risk workflows should shift further toward determinism and human approval.

## Influences

- ICM: progressive context disclosure and artifact-based stage handoffs.
- RLP: capture broadly, promote rarely, prefer checks and tests, delete stale knowledge.
- Lean Startup: test assumptions with the smallest experiment and measure outcomes.
- Extreme Programming: small releases, simple design, continuous integration, collective ownership, and rapid feedback.
- TDD: establish falsifiable behavior before changing implementation.
- DORA and DevEx: optimize the delivery system and developer experience, not activity metrics.
- NIST, OWASP, SSDF, and SLSA: bounded authority, secure development, and verifiable provenance.
