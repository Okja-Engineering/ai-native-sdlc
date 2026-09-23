# Evidence-led delivery plugin router

This repository contains research and an installable plugin that turns evaluated evidence into owner-reviewed intent and specification. It never grants implementation, merge, deployment, RLP promotion, or skill-creation authority.

## Route by task

| Task | Read |
|---|---|
| Resume work or report pilot readiness | `.devin/roadmap.md` |
| Understand repository scope and research | `CONTEXT.md` |
| Evaluate, filter, or synthesize explicit research into a provisional intent/specification | `skills/evidence-to-intent/SKILL.md` |
| Change evidence fields or statuses | `skills/evidence-to-intent/references/evidence-contract.md` |
| Change specification output or review rules | `skills/evidence-to-intent/references/specification-contract.md` |
| Propose minimal project-local HITL workspace contracts | `skills/sdlc-scaffold/SKILL.md` |
| Export an accepted workflow contract to compact/modular proposal files | `skills/sdlc-scaffold/scripts/export-proposal.sh` |
| Turn a raw request into reviewed intent, value slice, and evidence plan | `skills/shape-change/SKILL.md` |
| Reconcile an implemented slice with accepted intent/evidence before merge review | `skills/verify-change/SKILL.md` |
| Understand the lifecycle through the worked example | `examples/leaked-db-errors/README.md` |
| Describe a repository's current workflow as an observation snapshot | `skills/describe-workflow/SKILL.md` |
| Select the smallest justified improvement from established owner facts | `skills/select-improvement/SKILL.md` |
| Evaluate observed evidence against accepted outcome targets and emit a receipt | `skills/evaluate-outcome/SKILL.md` |
| Change the workflow contract schema | `_config/workflow-contract-schema.md` |
| Change the observation schema | `_config/workflow-observation-schema.md` |
| Change the owner-facts selection view | `_config/owner-facts-schema.md` |
| Check plugin structure | `tests/test_structure.sh` |
| Run evidence-to-intent validator tests | `tests/test_evidence_to_intent.sh` |
| Walk the first slice | `tests/test_walk.sh` |
| Check workflow contracts, export equivalence, loading rules | `tests/test_workflow_contract.sh`, `tests/test_export_equivalence.sh`, `tests/test_loading_rules.sh` |
| Check observation snapshots, interview input, snapshot behavior | `tests/test_describe_workflow.sh` |
| Check improvement selection, fact states, dependency graph | `tests/test_select_improvement.sh` |

## Rules

- Load this router, the selected skill, and only references named by that skill.
- Preserve E, D, R, A, and Q provenance; owner corrections outrank summaries.
- Mark missing required facts `NOT FOUND` and stop at the stated human boundary.
- Deterministic checks validate shape, not truth, applicability, intent, or risk.
- Do not create delivery, merge, deployment, RLP, or Skill Architect artifacts.
- File existence is not approval; require explicit review fields.
- Use Bash for repository scripts. Use Go only when logic is too complex to keep safe and readable in Bash. Do not add Python scripts.
