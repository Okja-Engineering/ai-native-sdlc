---
name: verify-change
description: Reconcile an implemented software slice with accepted intent, plan, current changed surface, and executed evidence, then stop for a human merge-readiness decision. Use after implementation and before merge or handoff.
license: MIT
compatibility: POSIX shell, git, and repository-specific verification commands.
metadata:
  version: "0.1.0"
---

# Verify change

Prepare revision-pinned evidence for an accountable human merge-readiness decision.

## When to use

Use after implementation and before merge or reviewed handoff. Reopen whenever the verified revision changes.

Read the evidence and decision contracts in `references/README.md`.

## Inputs

- Reviewed intent, slice, evidence plan, and implementation plan.
- Complete current changed surface and revision.
- Repository verification commands and policies.
- Existing review findings.

## Process

Establish revision-linked deterministic evidence before orchestration, semantic review, and the terminal human decision.

## Deterministic actions

```bash
scripts/validate-verify-change.sh "$output_root"
```

1. Pin the current revision and enumerate the complete changed surface.
2. Map every acceptance condition to executed revision-linked evidence.
3. Run required checks and record command, status, timestamp, and output.
4. Verify required tests and controls were not silently weakened.
5. Block merge-ready status for missing evidence or blocking findings.

## Orchestration

1. Compare intent, slice, plan, diff, and evidence.
2. Reconcile deterministic, AI-assisted, and human findings.
3. Route repairs through the authorized implementation process.
4. Restart affected checks after every change.
5. Produce the evidence receipt and stop for the terminal human decision.

## AI judgment

- Identify intent mismatch, hidden coupling, architecture drift, and residual risk.
- Explain findings and decision consequences without approving.

## Outputs

- Reviewed evidence receipt pinned to a revision.
- Human `merge-ready`, `revise`, `split`, or `reject` decision when supplied by the merge authority.
- Explicit unperformed actions.

## Human check

An independent reviewer accepts the receipt. The merge authority owns the terminal decision. Any revision change reopens verification.

## Example

```text
verified_revision: abc123
missing_evidence: []
blocking_findings: []
decision: pending-human
```

## Constraints

- Do not merge, deploy, or approve.
- Do not infer execution from a test summary.
- Do not accept evidence from a different revision.
- Do not promote learning or audit a candidate skill.
