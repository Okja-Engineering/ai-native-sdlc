# SDLC package router — intent-to-merge-ready

> Synthetic worked example (leaked DB errors → shared error boundary).
> This package teaches and enforces the full lifecycle boundary: it never
> merges, deploys, implements, or promotes learning.
> Conforms to schema `workflow-contract/0.1.0`.

```contract
id: intent-to-merge-ready
kind: workflow
schema_version: workflow-contract/0.1.0
stages: 01-intent | 02-slice | 03-evidence-plan | 04-implement | 05-verify | 06-merge-decision
risk_scaling: low-collapses-01-03 | high-requires-independent-reviewer
owner: example-owner
```

## Where am I

A sequential HITL delivery package for one reviewable value slice at a time.

## Route by current artifact

| You hold | Load |
|---|---|
| Raw request, no reviewed intent | `stages/01-intent/CONTEXT.md` |
| Accepted intent | `stages/02-slice/CONTEXT.md` |
| Selected slice | `stages/03-evidence-plan/CONTEXT.md` |
| Accepted evidence plan | `stages/04-implement/CONTEXT.md` — external actor boundary |
| Implemented change + raw evidence | `stages/05-verify/CONTEXT.md` |
| Reviewed evidence receipt | `stages/06-merge-decision/CONTEXT.md` — human authority |
| Task-type routing and shared resources | `CONTEXT.md` |

## Loading rules

- Always: this file.
- On entry to a stage: that stage's `CONTEXT.md` and its `context_entry`
  items only.
- Exploration: within `context_explore` scope; a discovered contradiction
  stops the stage and surfaces for a human.
- Never: `context_never` items; other slices' folders; run transcripts.

## Risk scaling

- low: stages 01–03 may collapse into one reviewed file; authority,
  provenance, and review fields are still required.
- medium: all stages, standard review depth.
- high or coupling > 1 topology edge: independent reviewer mandatory at
  05-verify; plan approval mandatory at 04-implement.
