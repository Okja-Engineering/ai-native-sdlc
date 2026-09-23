# Stage 02: Evaluate

Assess the strength, applicability, and disagreement of evidence behind each discovered claim.

## Inputs

| Source | File/Location | Scope | Why |
|---|---|---|---|
| Discovery | `../01-discover/output/claim-inventory.md` | Full file | Claims and candidate evidence. |
| Schema | `../../_config/evidence-schema.md` | Precedence and verdict rules | Prevents vendor opinion from becoming fact. |
| Principles | `../../PRINCIPLES.md` | Core beliefs only | Tests fit with the intended HITL problem. |

## Process

1. Validate that each claim is atomic and supported by a retrievable source.
2. Separate measured outcomes from interpretations and prescriptions.
3. Rate study design, independence, population fit, and recency.
4. Reconcile conflicts by comparing what each source actually measured.
5. Assign verdict and confidence.
6. Identify what remains unknown and what a pilot could test.
7. Save the evidence matrix to `output/evidence-matrix.md`.

## Checkpoints

| After step | Agent presents | Human decides |
|---|---|---|
| 4 | Material disagreements and why they differ | Whether any claim needs more discovery. |
| 6 | Unknowns that could become pilot hypotheses | Which are worth testing. |

## Audit

| Check | Pass condition |
|---|---|
| Outcome fidelity | No activity metric is labeled as customer or business value. |
| Qualification | Findings are bounded to their studied population and tools. |
| Uncertainty | Every verdict has limitations and confidence. |

## Outputs

| Artifact | Location | Format |
|---|---|---|
| Evidence matrix | `output/evidence-matrix.md` | Claim-by-claim verdicts plus pilot-testable unknowns. |
