# Stage 04: Frame pilot

Translate approved research into a falsifiable pilot brief and future plugin boundary without implementing either.

## Inputs

| Source | File/Location | Scope | Why |
|---|---|---|---|
| Synthesis | `../03-synthesize/output/research-packet.md` | Full file | Approved practices and unknowns. |
| Flow unit | `../../shared/flow-unit.md` | Current definition | Unit the pilot moves and measures. |
| Setup | `../../setup/questionnaire.md` | Completed answers | Pilot context and constraints. |

## Process

1. Select one pilot team and one representative value stream.
2. Establish baseline flow, stability, review-load, comprehension, and cost metrics.
3. Choose the smallest set of research practices needed for one end-to-end slice.
4. Define deterministic checks, stage routing, AI judgments, and human decisions.
5. Define treatment, comparison, stop conditions, and evidence collection.
6. State the future plugin's responsibilities and deliberate non-responsibilities.
7. Define case-study reporting that includes negative and null results.
8. Save the pilot brief to `output/pilot-brief.md`.

## Checkpoints

| After step | Agent presents | Human decides |
|---|---|---|
| 3 | Pilot scope and excluded practices | Whether the slice is small enough. |
| 6 | Plugin boundary and human authority model | Whether implementation may begin downstream. |

## Audit

| Check | Pass condition |
|---|---|
| Falsifiability | Success, failure, and stop conditions are measurable. |
| Baseline | Existing performance is measured before intervention. |
| Safety | Pilot cannot silently expand agent authority. |
| Publishability | Case study reports method, limitations, and adverse outcomes. |

## Outputs

| Artifact | Location | Format |
|---|---|---|
| Pilot brief | `output/pilot-brief.md` | Experiment, metrics, stage model, plugin boundary, and case-study plan. |
| Provisional workflow package | `output/workflow-package-provisional/` | Owner-authorized audit, editable HTML, and starter recommendations; does not authorize implementation. |
