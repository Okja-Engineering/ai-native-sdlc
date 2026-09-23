# AI-Native SDLC

A research workspace for designing sequential, human-in-the-loop software delivery that turns cheap AI-generated code into small, reviewable, production-qualified chunks of value.

This repository contains the research factory and the first slice of an installable plugin. The research defines the downstream product; the implemented `evidence-to-intent` skill turns explicitly supplied evidence into provisional intent and specification for human review.

## Thesis

AI reduces the marginal cost of implementation but does not remove the cost of intent, verification, coordination, security, or production learning. An effective AI-native SDLC therefore augments human judgment with deterministic evidence instead of maximizing autonomous action.

## Method

The workspace applies a 60/30/10 heuristic:

- **60% deterministic actions:** exact sources, schemas, checks, commands, evidence formats, and pass conditions.
- **30% orchestration:** stage routing, handoffs, checkpoints, risk tiers, and escalation.
- **10% AI judgment:** claim classification, synthesis across conflicting evidence, and context-sensitive recommendations.

The workflow is `discover → evaluate → synthesize → frame pilot`. Only stage `output/` directories hand work to another stage.

## Current research question

How should an engineering team move from AI automation pressure and cognitive dissonance toward sequential HITL augmentation, where the primary flow unit is the smallest independently valuable, human-reviewable, verifiable change?

## Layout

```text
ai-native-sdlc/
├── CLAUDE.md
├── CONTEXT.md
├── PRINCIPLES.md
├── RESEARCH.md
├── SOURCES.md
├── PACKAGE-BUILDER-INTEGRATION.md
├── PLUGIN-DESIGN.md
├── EXTERNAL-IMPLEMENTATIONS.md
├── _config/
├── decisions/
├── research/
├── skills/
│   ├── evidence-to-intent/
│   ├── sdlc-scaffold/
│   ├── shape-change/
│   └── verify-change/
├── examples/
│   └── leaked-db-errors/   # worked example: compact + modular export forms
├── tests/
├── setup/
├── shared/
└── research/stages/
    ├── 01-discover/
    ├── 02-evaluate/
    ├── 03-synthesize/
    └── 04-frame-pilot/
```

## Design references

- `PACKAGE-BUILDER-INTEGRATION.md` defines how research may inform a workflow package without replacing owner evidence or generating package-builder outputs.
- `PLUGIN-DESIGN.md` proposes a thin research-to-pilot plugin, sibling-compatible manifests and tests, and handoff contracts for RLP and Skill Architect.
- `EXTERNAL-IMPLEMENTATIONS.md` reviews two public article-derived implementations and records patterns to adopt, adapt cautiously, or reject.
- `_config/research-card-schema.md` defines the atomic evidence format that prepares research for package selection.
- `research/CONTEXT.md` routes a cold reader to five evaluated cards and their canonical source register.
- `decisions/0001-thin-research-to-pilot-plugin.md` records the proposed plugin boundary awaiting owner acceptance.
- `research/stages/03-synthesize/output/research-audit.md` and `cold-reader-walk-test.md` record the research-slice verification.
- `research/stages/03-synthesize/output/workflow-specification.md` is the accepted research reference for intent-to-merge behavior.
- `research/stages/03-synthesize/output/skill-system-options.md` compares four decompositions without treating skill names as final.
- `skills/` contains installable skill drafts. Former `reference-implementation/` skills were promoted here; they remain research-backed until scripts and validators are added.

## Plugin skills

The repository packages the `evidence-led-delivery` plugin for Devin, Claude Code, Codex, and Cursor. The exported skills are:

| Skill | Status | Purpose |
|---|---|---|
| `evidence-to-intent` | Implemented with validators | Evaluate research into a provisional intent/specification for human review. |
| `sdlc-scaffold` | Promoted; fixture tests added | Propose minimal project-local HITL workspace contracts; export an accepted contract to compact/modular proposal files under an isolated output root. |
| `shape-change` | Promoted; validators and fixture tests | Turn a raw request into reviewed intent, value slice, and evidence plan. |
| `verify-change` | Promoted; fixture tests added | Reconcile an implemented slice with accepted intent/evidence before merge review. |
| `describe-workflow` | Implemented with validators | Inspect a repository into a versioned observation snapshot — claims with source locators, unresolved conflicts, gap report. Read-only on the inspected repo; not an accepted contract. |

### First slice: `evidence-to-intent`

```text
explicit evidence
    → deterministic shape validation
    → applicability and contradiction review
    → provisional intent/specification
    → human accept | revise | reject
```

The skill never authorizes implementation. The deferred `reviewable-delivery` skill is deliberately absent from the first slice.

### Install locally

```bash
# Devin
devin plugins install .

# Claude Code
claude plugins install .
```

### Verify

```bash
tests/test_structure.sh
tests/test_evidence_to_intent.sh
tests/test_walk.sh
tests/test_shape_change.sh
tests/test_verify_change.sh
tests/test_sdlc_scaffold.sh
tests/test_workflow_contract.sh
tests/test_export_equivalence.sh
tests/test_loading_rules.sh
tests/test_describe_workflow.sh
tests/test_export_proposal.sh
```

## Status

First plugin slice (`evidence-to-intent`) implemented locally and uncommitted; three additional skills promoted to `skills/` and hardened by fixture tests. Research outputs remain working insight rather than promoted repository learning. Pilot execution, `reviewable-delivery`, target-repository scaffolding, merge, deployment, and publication remain out of scope.
