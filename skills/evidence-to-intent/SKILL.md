---
name: evidence-to-intent
description: Evaluate, filter, and synthesize explicitly supplied research into a provenance-preserving provisional intent and workflow specification for human review. Use before delivery planning when intent must be grounded in mixed evidence.
license: MIT
compatibility: Bash 3.2+, POSIX userland utilities, git.
metadata:
  version: "0.1.0"
---

# evidence-to-intent

Evaluate supplied evidence into a provisional intent and specification without turning research into owner facts or authorizing implementation.

## When to use

Use when the owner supplies selected evidence and acceptance cues before delivery planning. Do not use for implementation, merge, deployment, learning promotion, or skill generation.

Read `references/evidence-contract.md` and `references/specification-contract.md`.

## Inputs

- Explicit `run-id`, `input-root`, and `output-root`.
- Owner record with stable E, A, and Q IDs.
- Selected research cards with stable R IDs and applicability fields.
- Optional inspected-document register or expected-output reference labeled D.
- Owner acceptance cues. If absent, produce a gap report and stop.

## Process

1. Run `scripts/validate-evidence.sh INPUT_ROOT`.
2. Separate owner evidence, inspected documents, research, assumptions, and questions.
3. Compare source class, limitations, applicability, contradictions, and owner-evidence requirements.
4. Filter unsupported prescriptions while preserving credible disagreement.
5. Draft `OUTPUT_ROOT/RUN_ID/intent-specification.md` from the specification contract.
6. Run `scripts/validate-specification.sh SPEC --output-root OUTPUT_ROOT`.
7. Stop with review pending for the owner to accept, revise, or reject.

## Deterministic actions (60%)

```bash
scripts/validate-evidence.sh "$input_root"
scripts/validate-specification.sh \
  "$output_root/$run_id/intent-specification.md" \
  --output-root "$output_root"
```

Validate required fields, unique IDs, allowed statuses, local paths, output location, and specification shape. Failure stops the workflow.

## Orchestration (30%)

Run intake, evaluation/filtering, synthesis, output validation, and human review in order. An accepted output may be supplied to the deferred `reviewable-delivery` workflow. Do not invoke it automatically.

## AI judgment (10%)

Assess relevance, explain contradictions, synthesize bounded recommendations, and ask one focused question when an owner fact blocks useful work. Compare candidate names only after deriving responsibilities.

## Outputs

- `OUTPUT_ROOT/RUN_ID/intent-specification.md`.
- A gap report when required inputs or acceptance cues are absent.
- A contradiction note when credible evidence is inapplicable or conflicts.

## Human check

The owner verifies fidelity, applicability, exclusions, responsibility boundaries, and acceptance cues, then records `accept | revise | reject`. Acceptance permits later design only and leaves `implementation_authorized: false`.

## Example

```bash
run_id="20260907-pilot-sdlc-intent"
input_root="/tmp/evidence-input"
output_root="/tmp/evidence-output"
scripts/validate-evidence.sh "$input_root"
```

## Constraints

- Do not fetch unapproved sources or infer unavailable access.
- Do not implement or mutate a target repository.
- Do not merge, deploy, promote RLP learning, or invoke Skill Architect.
- Passing validation proves shape, not truth or owner approval.
