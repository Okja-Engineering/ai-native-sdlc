# Plugin design considerations

> Status: competing design notes. This file does not define the skill system. Derive candidate skills only after the owner accepts `research/stages/03-synthesize/output/workflow-specification.md`.

## Product boundary

The future plugin should prepare and evaluate sequential HITL delivery practices. It should not generate Workflow Package Builder's `workflow-audit.md`, `my-workflow-package.html`, or `starter-files.md`; the builder owns those artifacts.

The plugin should support the builder by supplying:

- atomic evaluated research cards;
- applicability questions;
- deterministic evidence and control patterns;
- pilot test patterns;
- measurement definitions;
- and explicit handoff contracts to RLP and Skill Architect.

## Design options

### 1. Bundle the package builder

Make package construction one of this plugin's skills.

- Benefit: one installation and entry point.
- Cost: duplicates a self-contained skill, couples release cycles, and obscures ownership.
- Decision: reject.

### 2. Publish only a research bundle

Ship references with no executable skills.

- Benefit: smallest surface and no workflow duplication.
- Cost: users must manually find applicable evidence; no validation or pilot loop.
- Decision: retain as fallback if pilot shows no need for automation.

### 3. Thin research-to-pilot plugin

Ship research selectors, readiness checks, and HITL pilot contracts while leaving package rendering, RLP promotion, and skill auditing to their owners.

- Benefit: fills the missing seam and supports incremental adoption.
- Cost: requires small versioned handoff contracts.
- Decision: recommended.

## Earlier candidate v0 skill surface

These names are hypotheses to compare against the accepted workflow specification, not an approved decomposition.

```text
/sdlc-architect:research-audit <research-root>
/sdlc-architect:pilot-readiness <workflow-package-dir>
/sdlc-architect:slice-review <slice-artifact>
```

### `research-audit`

Checks research cards for atomic claims, source provenance, visible contradictions, package-field boundaries, applicability conditions, and proposed-but-unrun tests.

It owns research quality. It does not audit Agent Skills; `skill-architect:skill-audit` owns that.

### `pilot-readiness`

Reads an owner-corrected package and the selected research cards. It reports whether one small trial has a real sample, expected result, baseline or measurement plan, retained human decision, and stop condition.

It must not build or rewrite the package.

### `slice-review`

Tests whether the proposed first trial is independently valuable, human-reviewable, verifiable, reversible, and traceable. It returns alternatives and asks the owner to choose.

It does not plan or implement product code.

A future `reflect` skill may route observed corrections after a pilot. Defer it until the first pilot demonstrates a real handoff need.

## ICM shape inside each skill

Follow the local converted Scuba pattern: a concise `SKILL.md` owns trigger, inputs, process, outputs, and human check; detailed schemas and tests load from `references/` only when needed.

```markdown
---
name: research-audit
description: Audit AI-native SDLC research cards for evidence provenance, package-builder boundaries, and pilot usability. Use before research informs a workflow package or pilot recommendation.
license: MIT
compatibility: POSIX shell (bash 3.2+ or zsh), git, awk, find, sort.
metadata:
  version: "0.1.0"
---

# Research audit

Use [references/README.md](references/README.md) for the card schema and audit matrix.

## Inputs

- Plugin root containing `research/claims/`, `research/patterns/`, `research/measures/`, and `research/controls/`.

## Process

1. Run `scripts/check-research-cards.sh <research-root>`.
2. Review semantic findings the script cannot decide.
3. Present blocking gaps and affected card IDs.
4. Stop for human correction; do not rewrite cards automatically.

## Outputs

- `research-audit.md` with deterministic failures and judgment findings.

## Human check

The research owner confirms source interpretation, applicability, and unresolved contradictions.
```

This mirrors `scuba-intake` and `scuba-ship-gate`: the body remains a stage contract, and detail stays behind a reference link.

## Deterministic validation sample

```bash
#!/usr/bin/env bash
set -euo pipefail
root="${1:?usage: check-research-cards.sh RESEARCH_ROOT}"
for collection in claims patterns measures controls; do
  while IFS= read -r card; do
    for field in id title domain kind status verdict confidence review_status; do
      grep -q "^${field}:" "$card" || {
        printf '%s:%s:missing required field\n' "$card" "$field"
        exit 2
      }
    done
    for heading in Claim Evidence Contradictions 'Applicability conditions' 'Package-builder use' 'Candidate practice' 'Human checkpoint' 'Pilot test'; do
      grep -q "^## ${heading}$" "$card" || {
        printf '%s:section:missing %s\n' "$card" "$heading"
        exit 2
      }
    done
  done < <(find "$root/$collection" -type f -name '*.md' | sort)
done
```

The production validator should additionally reject duplicate IDs, unresolved source IDs, invalid package-field names, and reviewed cards without reviewer and date.

## Applicability selection sample

```yaml
id: R-CONTROL-003
title: Human approval before production promotion
domain: governance
kind: control-pattern
requires_owner_facts:
  - production promotion exists
  - promotion can cause customer impact
supports_package_fields:
  - judgment.decision
  - barriers.why
  - workspace.documents
forbidden_package_fields:
  - steps.current
  - overview.strongestNumber
```

A deterministic selector compares every `requires_owner_facts` entry with the supplied owner-fact IDs and reports the missing set. It may say a pattern is eligible; it cannot say the owner accepted it.

## RLP handoff sample

After a real pilot correction, the plugin may prepare—not promote—a candidate:

```yaml
source: pilot/P-2026-001/decision.md
slug: weakened-verification
observation: The authoring agent changed the acceptance test while fixing the implementation.
evidence:
  - pilot/P-2026-001/evidence.md#E7
human_confirmation: pending
```

Only after the owner confirms the observation should the existing RLP capture flow receive it. RLP owns recurrence and promotion tier.

## Skill Architect handoff sample

If RLP decides that a skill is the strongest durable tier:

```yaml
candidate_id: C-014
source_learning: docs/learnings/decisions.md#C-014
trigger_cases:
  - modifying an existing acceptance test during a bug fix
non_trigger_cases:
  - adding a new acceptance test for a new feature
required_determinism:
  - detect changed protected test paths from the current diff
retained_judgment:
  - whether the task is a bug fix or intentional behavior change
```

`skill-architect:skill-audit` then validates the resulting skill. This plugin must not duplicate its ten-dimension audit.

## Proposed repository scaffold

Match the proven sibling layout while keeping research and runtime payload separate:

```text
sdlc-architect/
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
├── .cursor-plugin/plugin.json
├── .devin-plugin/plugin.json
├── .github/workflows/test.yml
├── .out-of-scope.md
├── README.md
├── PRINCIPLES.md
├── CHANGELOG.md
├── RELEASE_NOTES.md
├── LICENSE
├── skills/
│   ├── research-audit/
│   │   ├── SKILL.md
│   │   ├── references/README.md
│   │   └── scripts/check-research-cards.sh
│   ├── pilot-readiness/
│   │   ├── SKILL.md
│   │   ├── references/README.md
│   │   └── scripts/check-pilot-readiness.sh
│   └── slice-review/
│       ├── SKILL.md
│       └── references/README.md
├── research/
│   ├── CONTEXT.md
│   ├── claims/
│   ├── patterns/
│   ├── measures/
│   ├── controls/
│   └── sources/
└── tests/
    ├── test_skill.sh
    ├── test_walk.sh
    └── fixtures/
        ├── valid-research/
        ├── missing-owner-evidence/
        └── conflicting-evidence/
```

The plugin should package a curated subset of reviewed research. The broader `ai-native-sdlc` repository remains the research factory and source of truth.

## Manifest sample

Use the sibling plugin convention and one canonical `skills/` directory:

```json
{
  "name": "sdlc-architect",
  "version": "0.1.0",
  "description": "Evidence and HITL pilot skills for turning AI-native SDLC research into small, reviewable workflow experiments.",
  "license": "MIT",
  "skills": "skills"
}
```

Cross-agent manifests may need `./skills/` instead of `skills`; tests should assert each platform's actual requirement rather than copying one repository's historical inconsistency.

## Required tests

### Static plugin test

- All four manifests parse and agree on name and version.
- Every skill directory contains a matching `SKILL.md` name.
- Descriptions stay within the Agent Skills limit.
- Referenced scripts and references exist.
- Executable scripts have executable permission.
- Research cards validate against the deterministic schema.
- No skill declares ownership of package-builder, RLP, or Skill Architect outputs.

### Walk test

Use three fixtures:

1. Valid owner-reviewed package plus applicable research card.
2. Package with missing baseline and retained decision.
3. Package with contradictory owner evidence and a card whose applicability is unestablished.

For each, verify exact files, exit status, blocking findings, and that no package, RLP decision, or rewritten skill is created.

## External implementation precedents

The public implementations reviewed in `EXTERNAL-IMPLEMENTATIONS.md` reinforce four design choices:

1. Add a source-to-artifact `research-map.md`, adapted from the faithful implementation's article map.
2. Keep runtime flow separate from capability-adoption prerequisites, adapted from the reusable implementation's directed graphs.
3. Validate manifests, copied assets, references, scripts, and idempotent scaffolding deterministically.
4. State unavailable product/admin capabilities instead of creating runnable-looking placeholders.

They also strengthen the decision not to ship a full lifecycle skill, autonomous agent organization, automatic second-mistake context promotion, or universal `intent/spec/plan` document chain.

## Deliberate non-goals

- Rendering Workflow Package Builder outputs.
- Running the discovery interview.
- General agent orchestration or implementation.
- Automatic code review, merge, deploy, or production access.
- RLP capture without human confirmation.
- RLP recurrence or promotion decisions.
- Skill auditing or rewriting.
- A universal stage pipeline for every team.
- Copying the full research corpus into agent context.

## First verifiable implementation slice

When implementation is authorized, build only `research-audit` with five reviewed research-card fixtures and one deterministic validator. Run it against its own bundled cards, then pass the skill through Skill Architect. Do not implement package selection or pilot execution in the first slice.
