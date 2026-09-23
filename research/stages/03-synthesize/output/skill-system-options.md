---
type: skill-system-options
status: uncommitted-working-insight
workflow_specification: workflow-specification.md
implementation_authorized: false
---

# Skill-system options

## Decision criteria

A candidate structure should:

1. Preserve the accepted intent-to-merge workflow.
2. Keep human approval at intent, non-trivial slice/plan, evidence, and merge-readiness boundaries.
3. Put deterministic checks before model judgment.
4. Keep each skill focused and progressively disclose detail.
5. Avoid duplicating Scuba implementation orchestration, RLP learning promotion, Skill Architect auditing, or Workflow Package Builder packaging.
6. Support one small pilot without imposing a six-stage process on every repository.
7. Allow a saved prompt or existing repository process to remain sufficient when scaffolding adds no value.

## Option A: one skill per workflow phase

```text
frame-intent
select-slice
define-proof
plan-implement
verify-evidence
record-merge-readiness
```

### Strengths

- Direct correspondence between specification and runtime.
- Clear triggers and human checks.
- Easy to test each phase independently.

### Costs

- Six public commands for one value slice.
- `plan-implement` duplicates Scuba and general coding-agent behavior.
- Artifact handoffs can become process ceremony.
- Users must understand the full model before starting.

### Assessment

Better as internal ICM contracts than six public skills.

## Option B: one complete lifecycle skill

```text
ai-native-change
  frame → slice → prove → implement → verify → decide
```

### Strengths

- One obvious command.
- Similar to both public AI-native SDLC implementations.
- Easy to market as an end-to-end workflow.

### Costs

- Large context body and many conditional branches.
- Weak trigger precision for users entering mid-flow.
- Tends toward autonomous lifecycle ownership.
- Duplicates Scuba, testing skills, and ship-gate behavior.
- A single skill silently accumulates organization-specific policy.

### Assessment

Reject for the reference implementation. This is the shape already explored by `bashebr/ai-native-sdlc`; our research argues for smaller boundaries.

## Option C: scaffold plus two boundary skills

```text
sdlc-scaffold   # install minimal optional workspace contracts
shape-change    # intent → selected slice → accepted evidence contract
verify-change   # current diff → evidence receipt → human merge-readiness decision
```

Implementation between the boundaries uses the team's existing agent, Scuba Stack, or manual process.

### Strengths

- Exposes the two leverage points found by research: specification and verification.
- Leaves implementation orchestration with its existing owner.
- Three focused triggers.
- Human decisions remain explicit.
- Phase contracts can be loaded progressively from references/assets.
- A team can use `shape-change` or `verify-change` without adopting the scaffold.

### Costs

- The implementation handoff needs a precise contract.
- A gap can appear if the existing implementation process ignores the accepted evidence plan.
- Scaffold behavior needs idempotency and existing-router preservation tests.

### Assessment

Recommended research reference.

## Option D: generic gate skill plus configuration

```text
sdlc-gate --phase intent|slice|proof|plan|verify|merge
```

### Strengths

- Small code surface.
- One validator and state-transition model.
- Easy to extend with new phases.

### Costs

- Generic mode flags hide distinct human experiences.
- Broad trigger and complex branching move reader load into configuration.
- Harder to explain what evidence belongs to each boundary.
- Encourages configuration before concrete pilot evidence.

### Assessment

Reject initially. Generalize only after two real skills exhibit duplicated mechanics.

## Recommended responsibility map

| Accepted workflow phase | Reference component | Public trigger? | Owner |
|---|---|---|---|
| Frame intent | `shape-change` reference contract | Yes | SDLC reference plugin |
| Select value slice | `shape-change` reference contract | Yes, same task | SDLC reference plugin |
| Define proof | `shape-change` reference contract | Yes, same task | SDLC reference plugin |
| Plan and implement | Implementation handoff contract | No | Scuba/team/current coding agent |
| Verify evidence | `verify-change` reference contract | Yes | SDLC reference plugin |
| Record merge readiness | `verify-change` stops for human decision | Yes, same task | Human merge authority |
| Capture confirmed correction | Handoff schema only | No | RLP |
| Promote candidate skill | No direct action | No | RLP, then Skill Architect |

## Subskills versus references

Do not create subskills merely because phases exist. Keep phase detail as references until it has an independent trigger and reusable value.

Candidate reference files:

```text
shape-change/references/
├── intent-contract.md
├── slice-contract.md
└── evidence-plan-contract.md

verify-change/references/
├── evidence-receipt-contract.md
├── review-contract.md
└── merge-decision-contract.md
```

Promote a reference to a skill only when:

- users invoke it independently;
- it has distinct inputs and outputs;
- it has a complete human check;
- splitting reduces context or trigger ambiguity;
- and pilot evidence shows the split improves use.

## Comparison with precedents

| Precedent | What to retain | What the recommendation changes |
|---|---|---|
| `imsungbin/ai-native-sdlc-playbook` | Source-to-artifact map, honest non-implementation, deterministic validation, protected verbatim/source boundaries | Research rather than article fidelity is authoritative; no universal full lifecycle |
| `bashebr/ai-native-sdlc` | Asset/reference separation, adoption graph distinct from runtime graph, fixtures, idempotent scaffold, source-of-truth declaration | No autonomous agent org, full lifecycle skill, control-band default, or automatic context learning |
| Local Skill Architect | Compact skill body, deterministic scripts, progressive references, self-audit, cross-agent manifests | Audits SDLC research/workflow contracts rather than Agent Skill quality |
| Local RLP | Scaffold/capture/triage/audit separation, strongest-tier promotion, human approval, idempotency | No learning promotion in this reference plugin; handoff only after confirmed correction |
| Local ICM-converted Scuba | Mandate-first work, explicit Inputs/Process/Outputs/Human check, evidence-pinned verdicts | Implementation orchestration remains external rather than re-bundled |
| Workflow Package Builder | Smallest useful form, owner evidence outranks research, exact paths, real human checks, walk tests | Used later for a real team package; not embedded in the reference plugin |

## Research recommendation

Use Option C as the non-installable reference implementation. Treat `sdlc-scaffold`, `shape-change`, and `verify-change` as hypotheses for comparison and testing—not the final public plugin API.

For the routing logic that maps a team's current state to these skills, see [`skill-decision-tree.md`](skill-decision-tree.md).
