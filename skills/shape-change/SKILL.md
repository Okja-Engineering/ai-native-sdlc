---
name: shape-change
description: Turn a raw software request into an accepted intent, selected reviewable value slice, and approved evidence plan. Use before non-trivial implementation when problem boundaries or proof are not already explicit.
license: MIT
compatibility: Markdown files and repository read access.
metadata:
  version: "0.1.0"
---

# Shape change

Prepare the smallest implementation handoff that preserves product intent, independent value, and falsifiable evidence.

## When to use

Use before non-trivial implementation when intent, slice boundaries, or proof are ambiguous. Skip formal artifacts for low-risk work that already has approved intent and executable acceptance evidence.

Read the phase contracts in `references/README.md` progressively.

## Inputs

- Raw request in the owner's words.
- Existing repository rules and supplied examples.
- Named request owner and accountable engineer.

## Process

Apply the deterministic fields at each sequential stage, then use orchestration and AI judgment only as assigned below.

## Deterministic actions

```bash
scripts/validate-shape-change.sh "$output_root"
```

1. Assign a stable ID and required status fields.
2. Mark absent facts `NOT FOUND` rather than inferring them.
3. Validate required intent, slice, evidence, reviewer, and decision fields.
4. Block handoff when independent value, dependencies, or proof are missing.

## Orchestration

1. Frame intent and stop for request-owner acceptance.
2. Produce alternative decompositions and stop for engineer slice selection.
3. Map acceptance conditions to deterministic evidence or retained judgment.
4. Stop for evidence-plan acceptance.
5. Write only the reviewed implementation handoff.

## AI judgment

- Draft intent faithfully and expose ambiguity.
- Propose genuinely different value slices and semantic dependencies.
- Suggest failure modes and evidence gaps without selecting or approving.

## Outputs

- Accepted intent.
- Selected reviewable value slice.
- Approved evidence plan.
- Explicit implementation handoff with unresolved questions.

## Human check

The request owner owns intent. The accountable engineer owns slice and proof acceptance. Missing value, hidden dependencies, or unfalsifiable acceptance blocks handoff.

## Example

```text
Request: stop raw database errors reaching API clients
Slices: one endpoint patch | shared error boundary | all service errors
Human selects: shared boundary only if neighboring endpoint evidence fits one review
```

## Constraints

- Do not implement code.
- Do not turn industry research into owner facts.
- Do not treat file existence or AI prose as human approval.
- Do not create RLP or Skill Architect artifacts.
