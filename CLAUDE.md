# AI-Native SDLC plugin workspace

This repository is an installable multi-agent plugin that exports sequential HITL delivery skills for AI-native software teams. It also retains the research corpus and derivation history that produced those skills.

## Folder map

- `.devin/roadmap.md` — durable current state, blockers, evidence, and ordered pilot-readiness slices.
- `AGENTS.md` — task router for the plugin surface.
- `CONTEXT.md` — shared resources and routing boundaries.
- `PRINCIPLES.md` — approved operating beliefs.
- `RESEARCH.md` — current synthesized findings.
- `SOURCES.md` — human-readable bibliography and research context.
- `_config/` — schemas and reusable templates.
- `shared/` — cross-skill definitions.
- `skills/` — installable skill directories (`evidence-to-intent`, `sdlc-scaffold`, `shape-change`, `verify-change`, `describe-workflow`, `select-improvement`).
- `research/` — evaluated claims, patterns, controls, measures, and canonical source register.
- `research/stages/` — historical derivation contracts used to produce the research corpus and workflow specification. Not exported by the plugin.
- `tests/` — plugin structure, behavior, and walk tests.

## Triggers

- `status` — read `.devin/roadmap.md`, reconcile it with tests and Git state, then report decisions and next action.
- `resume` — read `AGENTS.md` and `.devin/roadmap.md`, run current verification, and continue the next unblocked slice.
- `research <claim>` — route to Stage 01 (historical derivation, read-only).
- `evaluate <claim>` — route to Stage 02 (historical derivation, read-only).
- `synthesize` — route to Stage 03 (historical derivation, read-only).
- `frame pilot` — route to Stage 04 (historical derivation, read-only).

## Routing

| Task | Contract |
|---|---|
| Resume work or report pilot readiness | `.devin/roadmap.md` |
| Evaluate, filter, and synthesize explicit research into a provisional intent/specification | `skills/evidence-to-intent/SKILL.md` |
| Propose minimal project-local HITL workspace contracts | `skills/sdlc-scaffold/SKILL.md` |
| Turn a raw request into reviewed intent, value slice, and evidence plan | `skills/shape-change/SKILL.md` |
| Reconcile an implemented slice with accepted intent/evidence before merge review | `skills/verify-change/SKILL.md` |
| Select the smallest justified improvement from owner facts | `skills/select-improvement/SKILL.md` |
| Check plugin structure | `tests/test_structure.sh` |
| Run evidence-to-intent validator tests | `tests/test_evidence_to_intent.sh` |
| Walk the first slice | `tests/test_walk.sh` |

## What to load

| Task | Load | Skip |
|---|---|---|
| Use any skill | `AGENTS.md`, the selected `skills/*/SKILL.md`, and only its named references | Research stages, unrelated skills, owner workflow state |
| Discover/evaluate/synthesize/frame pilot | `CONTEXT.md`, relevant Stage contract, `research/` | Later-stage outputs unless explicitly named |
| Check plugin structure | `tests/test_structure.sh` and plugin manifests | Research content |
| Run validators | Named validator scripts and fixture paths | Unrelated skills |

## Rules

- Do not treat vendor documentation as independent outcome evidence.
- Separate empirical evidence, standards, vendor claims, and practitioner opinion.
- Prefer primary sources and record publication date and limitations.
- Do not optimize for autonomous completion; preserve explicit human checkpoints.
- Use Bash for repository scripts; use Go only when Bash would be unsafe or unreadable. Python scripts are prohibited.
