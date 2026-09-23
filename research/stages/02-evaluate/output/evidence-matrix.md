# Evidence matrix

| Claim | Verdict | Confidence | Basis | Key limitation | Pilot implication |
|---|---|---|---|---|---|
| AI usually accelerates bounded coding work. | Qualified | High | Controlled field experiments show gains; METR shows a real negative case. | Tool, task, experience, and repository effects are large. | Segment results by task class and compare elapsed total effort. |
| Coding gains attenuate before release and customer value. | Supported | High | NBER and DORA distinguish local activity from delivery outcomes. | Business-value evidence remains limited. | Measure production-qualified slices and product outcomes. |
| The next constraint is commonly verification or review. | Qualified | High | DORA stability findings and broad empirical/practitioner convergence. | Some organizations remain constrained by intent, integration, or deployment batching. | Baseline queue and active time across the whole value stream. |
| Durable intent and acceptance criteria reduce ambiguity. | Supported | Medium | Agent-task studies and practitioner experience identify implicit requirements as a major failure source. | Optimal artifact size is not established. | Test a minimal intent/evidence contract, not a document-heavy process. |
| Telling an agent to use TDD guarantees a valid feedback loop. | Contradicted | Medium | Practitioner experiments and agent behavior show skipped or self-serving red steps. | Newer harnesses may improve enforcement. | Preserve independent failing tests and protect verification integrity. |
| AI review can safely replace accountable human review. | Unsupported | High | Model review has false positives/negatives; security research shows material generated-code risk. | Human review quality also varies. | Use AI to prepare and prioritize evidence; retain risk-tiered human approval. |
| Skills and prompts are security controls. | Qualified | High | They influence behavior but do not create an external enforcement boundary. | They can materially reduce common errors. | Back mandatory policy with deterministic checks, permissions, sandboxing, and gates. |
| Broad production autonomy is the natural target. | Unsupported | High | Standards and practitioner guidance favor least agency and bounded delegation. | Narrow pre-approved runbooks can be safe. | Increase authority by action class only after measured evidence. |
| Production telemetry should close the development loop. | Supported | High | Established DevOps/SRE practice and observability principles. | Automated diagnosis and remediation can be wrong. | Automate evidence gathering first; keep novel remediation human-approved. |
| More code, commits, or PRs means more productivity. | Contradicted | High | SPACE, DevEx, DORA, and NBER reject activity-only measurement. | Activity can be a diagnostic metric when not used as a target. | Use constrained system and product outcomes. |
| The smallest reviewable value slice is the right flow unit. | Hypothesis | Medium | Aligns with Lean, XP, DORA small batches, and human cognitive limits. | No universal definition or threshold exists. | Make flow-unit validity a central pilot test. |

## Pilot-testable unknowns

1. Whether a minimal intent and evidence contract reduces rework enough to offset preparation cost.
2. Whether smaller value slices reduce review time without increasing coordination overhead.
3. Whether deterministic evidence lets humans review intent and risk faster while preserving comprehension.
4. Which agent actions can advance from recommend to prepare or execute without degrading outcomes.
5. Whether filtered repository learning reduces repeated corrections without expanding context load.
