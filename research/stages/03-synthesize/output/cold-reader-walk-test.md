---
type: cold-reader-walk-test
date: 2026-09-07
status: passed
owner_review: pending
checks: 42
failures: 0
---

# Cold-reader walk test

## Scenario

A fresh agent must select evaluated research for one recommendation without loading the full workspace, inventing owner facts, or creating downstream-owned artifacts.

## Walk

### Read 1: `CLAUDE.md`

The root router identifies `research/CONTEXT.md` for selecting evaluated evidence and instructs the agent to load one selected card plus only named source rows when needed.

Result: pass.

### Read 2: `research/CONTEXT.md`

The research router maps five needs to five cards, defines E/D/R/S/A evidence namespaces, and states that research never supplies current steps, owner quotations, retained-decision rules, baseline values, access claims, or approval status.

Result: pass.

### Read 3: one selected card

Each card contains:

- one claim;
- evidence and limitations;
- contradictions;
- applicability conditions;
- supported and forbidden package fields;
- owner evidence still required;
- candidate practice;
- deterministic form;
- human checkpoint;
- proposed pilot test;
- RLP and Skill Architect boundaries;
- and resolvable source IDs.

Result: pass for all five cards.

## Deterministic checks

| Check | Result |
|---|---|
| Layer 0 routes evidence selection | Pass |
| Layer 1 routes evidence selection | Pass |
| Five expected cards exist and are routed | Pass |
| Every card declares applicability | Pass |
| Every card declares owner evidence still required | Pass |
| Every card forbids inappropriate package fields | Pass |
| Every card names a human checkpoint | Pass |
| Every card defines a proposed pilot test | Pass |
| Canonical source register is reachable | Pass |
| Router forbids owner-state inference | Pass |
| Workflow Package Builder output files are absent | Pass |

Automated walk: 42 checks, 42 passed, 0 failed.

## Human correction path

A card remains `pending-owner-review`. The agent presents applicability and missing owner evidence, then stops. The owner may accept, correct, reject, or leave the recommendation unselected. No downstream state transition follows from file existence.

## Boundary result

- No Workflow Package Builder output was created.
- No RLP candidate or promotion decision was created.
- No Skill Architect audit or rewrite was created.
- No plugin, merge, deploy, or production artifact was created.

## Verdict

The research library passes the cold-reader test for the research spike. It is navigable in three reads, keeps facts in one canonical location, preserves human correction, and does not blur research with owner evidence. Owner review remains the final pre-commit gate.
