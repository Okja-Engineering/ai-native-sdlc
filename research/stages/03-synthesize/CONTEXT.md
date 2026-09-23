# Stage 03: Synthesize

Derive vendor-neutral SDLC principles and practices from evaluated evidence, with augmentation and human comprehension as constraints.

## Inputs

| Source | File/Location | Scope | Why |
|---|---|---|---|
| Evaluation | `../02-evaluate/output/evidence-matrix.md` | Supported, qualified, and unknown claims | Evidence base. |
| Principles | `../../PRINCIPLES.md` | Full file | Design constraints. |
| Flow unit | `../../shared/flow-unit.md` | Full file | Working unit to test or revise. |

## Process

1. Group evaluated claims by intent, flow, verification, governance, operations, learning, and measurement.
2. Derive the minimum practice supported in each domain.
3. Classify each practice as deterministic action, orchestration, or AI judgment.
4. Check the overall design against the 60/30/10 heuristic.
5. Define human checkpoints and evidence required before risk expands.
6. Revise the flow-unit definition if the evidence contradicts it.
7. Record rejected alternatives and unresolved questions.
8. Save the packet to `output/research-packet.md`.

## Checkpoints

| After step | Agent presents | Human decides |
|---|---|---|
| 4 | Practice architecture and ratio allocation | Whether it is augmentation rather than disguised automation. |
| 7 | Recommendations, alternatives, and unknowns | Whether the packet is ready to inform a pilot. |

## Audit

| Check | Pass condition |
|---|---|
| Traceability | Every recommendation points to evaluated evidence or is labeled hypothesis. |
| HITL | Consequence-bearing judgments have named human owners. |
| Determinism | Machine-provable invariants are not assigned to AI judgment. |
| Cognitive load | Handoffs fit one coherent human decision. |

## Outputs

| Artifact | Location | Format |
|---|---|---|
| Research packet | `output/research-packet.md` | Findings, principles, 60/30/10 map, flow unit, and unknowns. |
| Workflow specification | `output/workflow-specification.md` | Research-derived expected intent-to-merge workflow for owner correction before skill design. |
| Research audit | `output/research-audit.md` | Structural and semantic audit of the initial card set. |
| Cold-reader walk test | `output/cold-reader-walk-test.md` | Router, card-boundary, and downstream-output checks. |
| Workflow specification review | `output/workflow-specification-review.md` | Adversarial findings, repairs, and current CLEAN verdict. |
| Skill-system options | `output/skill-system-options.md` | Competing decompositions and research recommendation derived from the accepted specification. |
