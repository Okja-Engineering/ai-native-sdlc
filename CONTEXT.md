# Plugin and research router

Route each task to the smallest skill, test, or research artifact needed for sequential HITL delivery. The plugin surface is `skills/`; `research/` and `research/stages/` hold the derivation history and evaluated corpus.

## Current product intent

Drafted from recorded owner decisions (not from any single generated
document). **Current statement:** an installable, multi-host plugin that
helps a team understand, describe, select, export, and evaluate a
sequential human-in-the-loop delivery workflow — `understand → describe →
select → export → evaluate` per the owner-reviewed
`research/stages/04-frame-pilot/output/toolkit-design-proposal.md` §2 —
while implementation authority, merge, deployment, RLP promotion, and
skill creation stay outside its boundary. Sources: ADR-0001 (thin
research-to-pilot form), ADR-0002/0003 (first-slice + tooling
conventions), names and distribution boundary (2026-09-13), slice
authorizations S6–S10.

The delivery method the plugin encodes: sequential HITL
`intent → merge-ready` with per-slice artifacts under
`changes/{slice-id}/` (`research/stages/03-synthesize/output/workflow-specification.md`,
owner-corrected working basis).

**Unresolved differences needing owner review** (run-01's provisional
text vs. today's recorded state — accepting run-01 unchanged is *not*
required):

- run-01 describes a **four-skill** plugin; the authorized surface is now
  seven skills — does the owner accept the run-01 spec as historical,
  revise it, or supersede it with this statement?
- run-01 left **names and distribution** unresolved; both were decided
  2026-09-13 — the spec needs a recorded accept/revise to retire its
  open questions (`Q01` decomposition cues remain open).
- **Dogfood slice selection** — ADR-0004 (`status: proposed`) names the
  gap-report slice as a candidate; owner selects.
- run-09 owner actions `Q10`/`Q11`/`Q12`/`Q17` (`.devin/eval/eval-log.md`).

## Plugin task routing

| Task | Skill / script | Description |
|---|---|---|
| Resume or assess pilot readiness | `.devin/roadmap.md` | Reconcile verified state, owner decisions, blockers, and the next verifiable slice. |
| Evaluate research into a provisional intent/specification | `skills/evidence-to-intent/SKILL.md` | Filter and synthesize explicit evidence into a human-reviewed specification. |
| Propose minimal project-local HITL workspace contracts | `skills/sdlc-scaffold/SKILL.md` | Inspect existing routers and propose the smallest useful scaffold. |
| Turn a raw request into reviewed intent, slice, and evidence plan | `skills/shape-change/SKILL.md` | Prepare a bounded implementation handoff with explicit human checkpoints. |
| Reconcile an implemented slice with accepted intent/evidence | `skills/verify-change/SKILL.md` | Produce a revision-pinned evidence receipt and stop for merge-readiness review. |
| Describe a repository's current workflow as an observation snapshot | `skills/describe-workflow/SKILL.md` | Inspect a repo into claims+conflicts+gaps; never modifies the inspected repo; output root must resolve outside it. |
| Select the smallest justified improvement from owner facts | `skills/select-improvement/SKILL.md` | Deterministically evaluates selection cards against established/unknown/conflicted facts; reports eligible/blocked/inapplicable with provenance; no writes, never accepts. |
| Evaluate observed evidence against accepted outcome targets | `skills/evaluate-outcome/SKILL.md` | Emits one reviewable `outcome-receipt` comparing evidence to accepted outcome targets; two acceptance bindings (contract + targets); receipt destination must resolve outside the inspected repository; never certifies success. |
| Check plugin structure | `tests/test_structure.sh` | Manifests, skill directories, scripts, and references. |
| Run evidence-to-intent validators | `tests/test_evidence_to_intent.sh` | Evidence schema and specification shape. |
| Walk the first slice | `tests/test_walk.sh` | Cold-session route from `AGENTS.md` to skill to references. |

## Historical research routing

These stages produced the evaluated research corpus and workflow specification. They are read-only derivation history, not exported by the plugin.

| Task | Stage contract | Description |
|---|---|---|
| Source and claim discovery | `research/stages/01-discover/CONTEXT.md` | Capture material claims and primary sources. |
| Evidence evaluation | `research/stages/02-evaluate/CONTEXT.md` | Rate evidence, surface contradictions, and separate fact from prescription. |
| Practice synthesis | `research/stages/03-synthesize/CONTEXT.md` | Derive vendor-neutral principles, flow units, metrics, and controls. |
| Workflow specification review | `research/stages/03-synthesize/output/workflow-specification.md` | Correct the active intent-to-merge HITL specification. |
| Pilot framing | `research/stages/04-frame-pilot/CONTEXT.md` | Convert approved research into a bounded pilot/plugin research brief. |

## Shared resources

| Resource | Location | Contents |
|---|---|---|
| Operating principles | `PRINCIPLES.md` | HITL, deterministic-first, small-batch, and learning principles. |
| Current synthesis | `RESEARCH.md` | Evidence-weighted research findings. |
| Source index | `SOURCES.md` | Human-readable bibliography and research context. |
| Canonical source register | `research/sources/source-register.md` | Stable source IDs, scope, findings, and limitations used by cards. |
| Evaluated research library | `research/CONTEXT.md` | Card router and evidence-namespace boundary. |
| Evidence schema | `_config/evidence-schema.md` | Required fields and rating rules. |
| Flow-unit definition | `shared/flow-unit.md` | Working definition of the smallest reviewable chunk of value. |
| Research card schema | `_config/research-card-schema.md` | Atomic evidence, applicability, package boundary, and pilot-test fields. |
| Package-builder boundary | `PACKAGE-BUILDER-INTEGRATION.md` | Rules for informing packages without replacing owner evidence. |
| Plugin design | `PLUGIN-DESIGN.md` | Earlier competing skills, sibling scaffold, handoffs, samples, tests, and non-goals. |
| Skill-system options | `research/stages/03-synthesize/output/skill-system-options.md` | Four decompositions derived from the accepted workflow specification. |
| Skill decision tree | `research/stages/03-synthesize/output/skill-decision-tree.md` | Research-derived routing tree from current artifact to skill or human checkpoint. |
| Promoted skills | `skills/{sdlc-scaffold,shape-change,verify-change}/SKILL.md` | Former research-draft skills now in the installable surface; each has a validator script and fixture tests. |
| Worked example | `examples/leaked-db-errors/README.md` | Same workflow contract in compact and modular export forms; schema `workflow-contract/0.1.0`. |
| Workflow contract schema | `_config/workflow-contract-schema.md` | Provisional canonical contract both export forms normalize to; pending owner review. |
| Observation schema | `_config/workflow-observation-schema.md` | Provisional `workflow-observation/0.1.0` — describe-workflow's snapshot format; not an executable contract. |
| Acceptance record schema | `_config/contract-acceptance-schema.md` | Provisional `contract-acceptance/0.1.0` — content-bound review record the exporter requires; never generated by tooling. |
| Toolkit design proposal | `research/stages/04-frame-pilot/output/toolkit-design-proposal.md` | Proposed v1.0 product boundary, slices, and pilot; owner review pending. |
| External implementations | `EXTERNAL-IMPLEMENTATIONS.md` | Public precedents, reusable patterns, conflicts, and rejected scope. |

## Plugin runtime

The plugin currently exports `skills/evidence-to-intent/`, three promoted research-draft skills, `skills/describe-workflow/` (observation snapshots; no acceptance or export authority), `skills/select-improvement/` (deterministic improvement selection over owner facts; read-only, never accepts), and `skills/evaluate-outcome/` (outcome receipts; implemented, awaiting owner review). `skills/sdlc-scaffold/` additionally carries the contract export tooling (`export-proposal.sh`, callable validators) — it emits reviewable proposals only; applying them to a client repo is a separate authorized step. All seven skills have validators and passing fixture tests; installation in a host remains blocked on `devin auth login` (see `.devin/roadmap.md`).

| Responsibility | Owner |
|---|---|
| Evidence identity, status, path, and specification-shape checks | Deterministic scripts |
| Applicability, contradictions, filtering, and synthesis draft | AI under `evidence-to-intent` |
| Source selection and accept/revise/reject decision | Human owner |
| Implementation, merge, deployment, learning promotion, skill audit | External systems; not this plugin |

Canonical runtime paths:

- `skills/evidence-to-intent/SKILL.md`
- `skills/evidence-to-intent/references/evidence-contract.md`
- `skills/evidence-to-intent/references/specification-contract.md`
- `skills/evidence-to-intent/scripts/validate-evidence.sh`
- `skills/evidence-to-intent/scripts/validate-specification.sh`

Per run, callers provide explicit input root, output root, and run ID. Output is `OUTPUT_ROOT/RUN_ID/intent-specification.md`. Only `review_status: reviewed` with a named reviewer, date, rationale, and `decision: accept` makes it eligible for a later workflow; implementation remains unauthorized.

## Handoff rule

A research stage reads only the previous stage artifact named in its Inputs table. Plugin runs load the selected skill and only its named references and inputs. Each writes only to its declared output directory.
