---
type: design-proposal
status: proposed-for-owner-review
date: 2026-09-13
author: agent draft under owner direction
implementation_authorized: false
supersedes: nothing; extends ADR-0001 and the workflow specification
requires_owner_decision: true
---

# Toolkit design proposal: understand → describe → select → export → evaluate

> **Status: proposed.** Nothing in this document is authorized. It is a generated
> artifact for owner review. Accept, revise, or reject decisions are recorded in
> `decisions/` or `.devin/roadmap.md`, never inside this file.

## 0. Provenance key

Every material statement below carries one of these labels. They are kept
distinct per `PACKAGE-BUILDER-INTEGRATION.md` and the evidence schema:

- **[RF]** repository fact — verified by reading this repository on 2026-09-13.
- **[VG]** vendor guidance — Anthropic publications; methodological source, not
  outcome evidence (per `AGENTS.md`: vendor docs are not independent evidence).
- **[OR]** owner requirement — stated by the owner in this request or a recorded
  correction/decision.
- **[DD]** proposed design decision — a recommendation awaiting owner review.
- **[UH]** unverified hypothesis — plausible, untested; must not be presented as fact.
- **[SB]** sibling-project fact — verified in `../skill-architect`,
  `../repo-learning-protocol`, or the local Workflow Package Builder skill.

Two provenance sources are independently preserved throughout:

- **Interpretable Context Methodology (ICM)** — folder structure as agent
  architecture; numbered stage folders; `output/` as the only handoff surface;
  layered loading (L0 router → L4 working artifacts). Origin: the ICM reference
  implementation and the local `icm-architect` conversion. [SB]
- **60/30/10 heuristic** — deterministic actions / orchestration / AI judgment,
  directional not arithmetic; human authority sits outside the allocation.
  Origin: owner correction E07 and `PRINCIPLES.md`. [OR][RF]

## 1. Current capability and gap assessment

### 1.1 Verified current state [RF]

| Area | State | Evidence |
|---|---|---|
| Plugin packaging | `evidence-led-delivery` v0.1.0; four manifests (Devin, Claude, Codex, Cursor) | `.devin-plugin/plugin.json`, siblings; `tests/test_structure.sh` passes |
| `evidence-to-intent` | Implemented with two Bash validators; three live eval runs recorded | `skills/evidence-to-intent/`; `.devin/eval/eval-log.md` |
| `shape-change`, `verify-change`, `sdlc-scaffold` | Promoted to `skills/`; each has a validator script and fixture tests | `tests/test_{shape_change,verify_change,sdlc_scaffold}.sh` all pass on 2026-09-13 |
| Workflow specification | Phases A–F, state model, failure rules, synthetic walk test; `implementation_authorized: false`, owner review "direction-confirmed-not-durable" | `research/stages/03-synthesize/output/workflow-specification.md` |
| Research corpus | Five evaluated cards + source register + router | `research/`; `validate-evidence.sh research` passes |
| Live eval harness | `.devin/eval/` with input/output roots per run | `.devin/eval/` |
| Baseline | No git commit; all files untracked | `git status`, `git log` (no commits) |

Stale documentation found while reconciling (doc vs implementation):

- `CONTEXT.md` line 51: "Only `evidence-to-intent` has validators today" — false
  as of today; all four skills have scripts and passing fixture tests. [RF]
- `CONTEXT.md` line 46 / README table: "pending scripts/validators" and
  "scripts pending" for `shape-change`/`verify-change` — stale. [RF]
- `interview-record.md` is marked `superseded-research-note`; retained as a
  correction record only. [RF]
- ADR-0001 status is `deferred-pending-workflow-specification`; the workflow
  specification now exists but its owner acceptance is still not durable. [RF]

### 1.2 Gap assessment against the five target capabilities [OR][RF]

| # | Capability | Current support | Gap |
|---|---|---|---|
| 1 | Understand the lifecycle via a concrete worked example | Workflow spec §10 has a synthetic walk test (leaked DB error); fixtures exist for it | No owner-facing worked example expressed as an installable workflow; the walk test is a spec appendix, not a teachable artifact |
| 2 | Describe current workflow via repo inspection + owner evidence | `sdlc-scaffold` inspects routers to *propose* contracts; evidence E/D/R/A/Q namespaces exist | No skill produces a *description* of a team's actual current workflow (topology, flow, routing) as a first-class artifact |
| 3 | Select the smallest justified improvement | `evidence-to-intent` synthesizes supplied evidence into a provisional spec; card applicability fields exist; deterministic `eligible()` selector is sketched in `PACKAGE-BUILDER-INTEGRATION.md` | No current-vs-target comparison; no implementation of the applicability selector; no adoption-prerequisite graph at runtime |
| 4 | Export accepted workflow as compact module or modular package | `sdlc-scaffold` proposes minimal workspace contracts (modular-leaning only) | No compact form; no canonical contract both forms serialize; no equivalence check; no export at all |
| 5 | Evaluate result and adjust from observed outcomes | `verify-change` ends at merge-readiness; eval log captures skill runs | No post-merge outcome receipt; no observed-vs-intended comparison; no eval-suite integration; RLP handoff is a documented note, not an artifact contract |

Cross-cutting gaps:

- No gap-report contract/validator (already identified as ADR-0004's proposed
  dogfood slice). [RF]
- No `research-map.md` (required by `EXTERNAL-IMPLEMENTATIONS.md` consequence 1). [RF]
- Session state and durable learning are separated by convention but no
  validator enforces the boundary (e.g., nothing prevents a skill from writing
  run output into a durable path). [RF]
- Roadmap items still open: owner spec review of `run-01`, `devin auth login`,
  baseline commit, ADR-0004 acceptance. These gate pilot claims, not design. [RF]

## 2. Proposed product boundary [DD]

**Product contract (owner-stated, unchanged):** define intent, reviewable work,
acceptable evidence, and accountable decisions. [OR]

**Proposal:** the `evidence-led-delivery` plugin becomes a toolkit for
*expressing and improving a team's delivery workflow*, not for executing it.
Five capabilities map onto existing structure with minimal new surface:

| Capability | Proposed home | Status |
|---|---|---|
| Understand (worked example) | `examples/` payload + walkthrough reference — static, not a skill | new slice |
| Describe current workflow | new skill `describe-workflow` (repo inspection + owner evidence → canonical contract instance) | new skill, reuse of E/D/A/Q machinery |
| Select smallest justified improvement | `evidence-to-intent` + deterministic applicability selector; a separate `select-improvement` skill is deferred until a real second trigger appears | reuse |
| Export compact or modular | extend `sdlc-scaffold` (its job is already "smallest useful form"; compact vs modular is that decision, now with emit-on-approval) | reuse |
| Evaluate and adjust | new skill `evaluate-outcome` (observed signals vs accepted intent → outcome receipt; confirmed corrections → RLP handoff) | new skill |

Explicitly retained exclusions [RF][OR]: no implementation, merge, deployment,
RLP promotion, skill creation/audit, Workflow Package Builder outputs, or
autonomous orchestration. The plugin prepares evidence and contracts; humans
and external systems hold authority.

### 2.1 Workflow Package Builder boundary — proposed resolution [DD]

The unresolved overlap: WPB's `starter-files.md` recommends workspace contracts
(a router, context, stage contracts) — the same artifact class as a modular
export; and WPB's interview overlaps with "describe current workflow."

Proposed rule, **as corrected by the owner on 2026-09-13**:

- **WPB** (private sibling skill, [SB]) owns *elicitation and human-facing
  packaging* of any owner's actual workflow: `interview-record.md`,
  `workflow-audit.md`, `my-workflow-package.html`, `starter-files.md`.
  Domain-neutral; the deliverable is a package a person corrects.
- **This plugin** owns the canonical workflow contract *and the single
  implementation that renders it* into compact or modular workspace files.
  WPB's `starter-files.md` references or incorporates those rendered files; it
  does not independently generate equivalent SDLC contracts. (Owner correction:
  without this delegation, "WPB owns starter-files" overlaps "this plugin owns
  repo-native serialization.")
- `describe-workflow` inspects and reconciles repository evidence; it may
  consume a WPB `interview-record.md` as E/D-class evidence and must surface
  missing owner facts — it does not duplicate WPB's discovery interview.
- **Acceptance of a workflow is distinct from permission to apply an export.**
  Generated files remain reviewable proposals; exporting must not overwrite
  owner edits or imply installation authority.
- The plugin never emits WPB's other artifacts; WPB never emits installable
  SDLC contract sets on its own.

This preserves `PACKAGE-BUILDER-INTEGRATION.md` unchanged: research enters the
builder as a recommendation library; owner evidence outranks it.

### 2.2 Sibling boundaries (unchanged, restated for the new surface) [RF][OR]

| Concept | Owner |
|---|---|
| Delivery workflow definition, shaping, evidence, verification | This plugin |
| Confirmed corrections, promotion tier, provenance, expiry | RLP (`capture`, `triage`, `audit`, `scaffold` exist [SB]) |
| Static skill audit and runtime evaluation | Skill Architect (`skill-audit`, `skill-gate`, `skill-rewrite` exist [SB]) |
| Implementation, merge, deployment authority | Client systems and humans |
| Interview, audit, HTML package, starter files | Workflow Package Builder |

`evaluate-outcome` hands a *human-confirmed* correction to RLP's inbox format;
it never promotes. Skill candidates reach Skill Architect only via RLP, per the
existing consequence list.

## 3. Canonical workflow contract [DD]

The export problem decomposes into one canonical model serialized two ways.
Both forms must carry equivalent contracts — equivalence is a testable
property, not a convention.

### 3.1 Three planes, modeled separately [DD][VG]

The design requirement to separate topology, workflow, and context routing maps
onto the playbook's structure (committed artifacts + gates) and the context-
engineering guidance (smallest high-signal token set; context is finite) [VG]:

| Plane | Question | Owns | Example fields |
|---|---|---|---|
| `topology` | What is the software? | Units, owners, coupling edges, protected paths, risk tags | `units[]`, `edges[]`, `protected_paths[]`, `risk_tags[]` |
| `workflow` | How does a change flow? | Stages, artifacts, gates, decisions, state model, failure/re-entry | `stages[]`, `decisions`, `transitions` |
| `context-routing` | What loads when? | Loading rules per stage, session vs durable split, budgets | `always_load[]`, `on_trigger[]`, `never_load[]`, `budget` |

Reason for separation [DD]: they change for different reasons. Topology changes
with the codebase; workflow changes with team decisions; context routing changes
with model/harness behavior. Coupling them produces the failure mode Anthropic's
context-engineering post warns about — stale always-on context consuming the
attention budget [VG].

### 3.2 Per-stage contract fields [DD]

Every workflow stage — in either export form — must declare:

```yaml
id:                  # stable, kebab-case
kind:                # internal | external
purpose:             # one sentence
inputs:              # [{path|fact, provenance: E|D|R|A|Q|S, scope}]
outputs:             # [{path, format}]
acceptance_evidence: # [{check|retained-judgment, falsifies, evidence_path}]
authority:           # {decides: <role>, may_not: [...]}
depends_on:
  runtime:           # [stage ids whose output this stage consumes]
  adoption:          # [capabilities/prerequisites that must exist before this stage is safe]
context:
  entry: []          # required reads — the entry points an agent MUST load
  explore: []        # scoped permission for additional reading (rules, not a file list)
  never: []          # hard exclusions
failure:
  on_missing_input:  # stop | NOT FOUND | escalate
  on_conflict:       # retain-both | stop
  reentry:           # state to return to
review:
  fields: [review_status, reviewer, reviewed_at, decision]
  decisions: [...]   # allowed terminal values for this stage
```

Owner corrections applied (2026-09-13):

- `kind: external` marks stages this plugin does not execute (implementation
  is the canonical example). An external stage must additionally name
  `external_actor`, `handoff`, and `return_evidence`. Omitting the stage from
  the model was rejected: the contract must teach the full lifecycle and name
  the boundary explicitly.
- `context` is entry-point semantics, not an absolute reading allow-list.
  Agents need controlled exploration to discover dependencies; write and
  authority boundaries stay strict. `explore` declares when additional reading
  is allowed and how discovered conflicts are surfaced.

`depends_on.adoption` vs `depends_on.runtime` encodes the requirement to
distinguish adoption prerequisites from runtime dependencies — the pattern
adapted from `bashebr/ai-native-sdlc` in `EXTERNAL-IMPLEMENTATIONS.md` §4 [RF]
and matching the playbook's "Prerequisites" per play, which are adoption-order,
not runtime-order [VG].

### 3.2a What the v1.0 compatibility surface is — owner correction [OR]

The versioned **canonical contract and its semantics** are the compatibility
surface. Compact and modular exports are *representations*; their filenames,
directory layout, and prose are not independently frozen APIs. Before v1.0 is
frozen the schema must define:

- required vs optional fields, defaults, and explicit unknown values
  (`NOT FOUND` semantics);
- stable identifiers and reference-resolution rules;
- schema versioning, unsupported-version handling (fail closed), and migration
  policy;
- the distinction between workflow acceptance and permission to apply an
  export;
- semantic equivalence across authority, dependencies, acceptance evidence,
  context rules, and failure/re-entry behavior.

Both forms must normalize to the same canonical contract. Risk-tier scaling may
change required evidence and review depth but must not silently remove core
authority or provenance fields.

### 3.3 Risk-scaled process [DD][RF]

Process scales by declared `risk_tier` and coupling — not file count:

- `risk_tier` (low|medium|high, per repository policy — the workflow spec's open
  question 6 stays open) gates which stages and evidence are mandatory.
  Low-risk changes may collapse intent+slice+proof into one reviewed artifact —
  this is already licensed by workflow spec §5 ("logical jobs, not a requirement
  of six files") and open question 3. [RF]
- Coupling (topology `edges` crossed by the changed surface) raises the tier.
- Evidence needs: any stage may declare a manual check, but a named human must
  accept it (`accepted_manual_checks` in spec §7C). [RF]

### 3.4 State model and failure/re-entry

Reuse the workflow specification's state model unchanged
(`intent-pending → slice-pending → proof-pending → plan-pending →
implementation-active → review-pending → merge-ready|revise|split|reject`),
including backward transitions and the rule that any revision change reopens
`review-pending`. [RF] Exports serialize this; they do not redefine it.

## 4. The worked example, in both export forms [DD]

Same example the repo already uses: *a service leaks raw database errors from
one API endpoint; the slice adds a shared error boundary* (workflow spec §10;
`tests/fixtures/shape-change/`, `tests/fixtures/verify-change/`). [RF]

### 4.1 Compact form — single module

One file a repository drops next to `AGENTS.md`. Educational and functional:
a cold agent routes from it; a human reads the whole contract in one screen.

```markdown
# SDLC: intent-to-merge-ready (compact)

Product contract: intent, reviewable work, acceptable evidence, accountable
decisions. This module never merges, deploys, or promotes learning.

## Route by current artifact
| You have | Go to |
|---|---|
| Raw request | §1 Intent |
| Accepted intent | §2 Slice |
| Accepted slice | §3 Evidence plan |
| Accepted plan | §4 Implement (external process) |
| Implemented change | §5 Verify |
| Verified receipt | §6 Merge decision (human) |

## Loading rules
- Always: this file.
- On entry to §N: only the artifacts named in that stage's Inputs.
- Never: prior run transcripts, other slices' folders, research corpus.

## Stages
### §1 Intent
- Inputs: raw request; repo rules. Outputs: `changes/{id}/01-intent.md`.
- Evidence: required fields present; unknowns marked NOT FOUND.
- Authority: request owner decides accept|correct|reject. Agent may not decide.
- Failure: missing trigger/owner/outcome → stop, one focused question.

### §2 Slice … ### §3 Evidence plan … ### §5 Verify … ### §6 Decision …
(same field set as §3.2; ~120 lines total)

## Risk scaling
low → §1–§3 may merge into one reviewed file; medium → all stages;
high + coupling>1 → independent reviewer required at §5.
```

### 4.2 Modular form — repository package

The ICM shape [SB], installable beside an existing router without overwriting
it (per `sdlc-scaffold` rules):

```text
sdlc/
├── ROUTER.md            # L0: where am I; route by current artifact
├── CONTEXT.md           # L1: task routing + shared resource table
├── _config/
│   ├── stage-contract-schema.md
│   └── risk-tiers.md
├── shared/
│   └── value-slice.md   # flow-unit definition (canonical home)
└── stages/
    ├── 01-intent/CONTEXT.md       # fields per §3.2
    ├── 02-slice/CONTEXT.md
    ├── 03-evidence-plan/CONTEXT.md
    ├── 04-implement/CONTEXT.md    # kind: external — names the handoff,
    ├── 05-verify/CONTEXT.md       #   external actor, required outputs,
    └── 06-merge-decision/CONTEXT.md  #   and return evidence
```

Stage `04-implement` is present as an **explicit external stage** (owner
correction 2026-09-13): its contract names the handoff, the external actor
(team agent / Scuba / manual process), the outputs it must produce, and the
evidence it must return — while this plugin never executes it. This keeps the
exported lifecycle complete and the boundary honest, per
`EXTERNAL-IMPLEMENTATIONS.md` §2. [RF][OR]

### 4.3 Equivalence rule — owner-corrected [OR]

Compact and modular forms are equivalent iff both **normalize to the same
canonical contract**: identical stage id sets and, per stage, identical
authority, dependencies, acceptance evidence, context rules, and
failure/re-entry behavior. The check compares normalized contract semantics —
never text, headings, or file layout. A meaningful semantic difference between
forms must fail the check.

### 4.4 What the tooling supports vs the full lifecycle [OR][VG]

The worked example must state, and the export must carry, a coverage map:

| Lifecycle stage (playbook) | Covered by this toolkit? |
|---|---|
| Plan (`intent.md`) | Yes — `shape-change` §1/equivalent stage |
| Design (`spec.md`) | Partially — folded into intent/slice artifacts |
| Build (`plan.md`, implementation) | No — external agent/process; boundary kept explicit |
| Test (feedback loop, evals) | Partially — evidence plan + outcome receipt; not CI-integrated evals |
| Deploy (review loop, gates) | Stops at merge-ready; gates/hooks described, not installed |
| Maintain (loop closure) | No — `evaluate-outcome` produces receipts and RLP handoffs only |

This is the "full lifecycle educationally, honest coverage functionally"
requirement: the example shows all six stages; the contract marks which the
tooling executes. [OR]

## 5. Context-loading and cross-module dependency rules [DD]

Progressive disclosure as explicit, testable rules — extending ICM's five
layers into checkable constraints. Corrected per owner (2026-09-13): context
inputs are **required entry points**, not an absolute reading allow-list.

1. **Entry points are required; exploration is scoped.** Each stage declares
   `context.entry` (must be read), `context.explore` (when and where
   additional reading is permitted — e.g., only declared runtime
   dependencies' outputs, or paths under a named root), and `context.never`
   (hard exclusions). A validator checks that declared entry/explore/never
   paths resolve and that `never` paths are not referenced; exploration beyond
   `explore` scope requires surfacing the discovery for a human. When
   exploration uncovers a contradiction with declared inputs, the stage stops
   and surfaces the conflict rather than resolving it silently.
2. **Every referenced path resolves.** Broken-reference fixtures must fail.
3. **Router budget.** L0 router ≤150 lines; stage contracts ≤80 lines
   (ICM limits). [SB] Measured, not asserted.
4. **No whole-workspace loads.** No contract may name a directory as an input
   without a scope qualifier (section or file list).
5. **Stage internals are private.** `stages/NN-*/references/` load only via
   that stage's contract; cross-stage reads go through declared `inputs`.
6. **Cross-module dependencies are typed.** A module declares
   `depends_on.runtime` (artifact-producing predecessors) and
   `depends_on.adoption` (capabilities that must exist). A validator fails when
   a runtime dependency's declared outputs don't exist and aren't marked
   owner-supplied; an unmet adoption prerequisite produces a warning surfaced
   for human decision, not a hard block (adoption order ≠ runtime order [RF][VG]).
7. **Session state never enters durable paths.** Run artifacts write only
   under `changes/{slice-id}/` or a declared `output/`; durable learning moves
   only through RLP handoff. Validator: no stage `outputs[]` path may point
   into `_config/`, `shared/`, router files, or RLP paths.

## 6. Session state vs durable repository learning [DD][RF]

| Class | Lives in | Lifetime | Mutation rule |
|---|---|---|---|
| Session/run state | `changes/{slice-id}/`, `OUTPUT_ROOT/RUN_ID/`, eval scratch | per run | written by skills; never imported by later skills except via declared inputs |
| Accepted artifacts | the same paths, once review fields are complete | until superseded | owner review markers only; file existence ≠ approval [RF] |
| Durable learning | RLP inbox → promoted checks/tests/context/skills | until pruned | only via human-confirmed correction → `capture` → `triage` [SB] |
| Exported workflow | `sdlc/` package or compact module in target repo | until re-exported | idempotent; never overwrites owner-authored text |

## 7. Ordered implementation slices toward v1.0 [DD]

Each slice is independently reviewable, leaves tests green, and names its
acceptance evidence. Pre-existing roadmap Slices 1–5 (live eval, install,
baseline, pilot contract, pilot gate) remain the near-term sequence; these are
the *next* ordered units.

| Slice | Deliverable | Depends on | Acceptance evidence |
|---|---|---|---|
| S6 — Canonical contract + worked example | `_config/workflow-contract-schema.md`; `examples/leaked-db-errors/{compact,modular}/`; `tests/test_workflow_contract.sh`, `tests/test_export_equivalence.sh`, `tests/test_loading_rules.sh` | none (docs+tests only) | §8 tests pass; equivalence check green; walk test from AGENTS.md reaches the example |
| S7 — `describe-workflow` skill | repo inspection (+ optional WPB interview record) → versioned observation snapshot + gap report — not an executable contract | S6 | §11 contract; fixtures incl. missing facts, retained conflicts, owner-edit preservation, unsupported interview input, missing source locators, stale observations, configured-but-unrun checks |
| S8 — export in `sdlc-scaffold` | accepted contract + sibling acceptance record → compact/modular proposal under a separate output root | S6, S7 | §12 contract (revised); staged render + validate; all-or-nothing writes; acceptance is content-bound via normalized digest |
| S9 — improvement selection | deterministic card-applicability selector (`eligible()` from PACKAGE-BUILDER-INTEGRATION) + adoption graph feeding `evidence-to-intent` | S6, S7 | §13 contract; selector returns eligible set + missing owner facts; never asserts acceptance |
| S10 — `evaluate-outcome` skill | outcome receipt (observed vs intended); stale-evidence re-entry; RLP handoff artifact for human-confirmed corrections | S6 | receipt requires revision + observed evidence; revision drift reopens; handoff emitted only with human_confirmation |
| S11 — release gate for v1.0 | `research-map.md`; stale-doc repairs; full test suite + live evals; skill-audit pass; owner sign-off | S6–S10 | CLEAN adversarial review; pilot evidence recorded |

Rationale for order: S6 is the foundation both export forms and later skills
serialize through; S7/S8/S9 can proceed in parallel after S6 but are listed in
usage-pipeline order; S10 needs the contract's re-entry states; S11 is the gate.
Rejected alternative: build `describe-workflow` first (educational value later,
no machinery to check the description against) — rejected because the contract
schema is what every later slice must conform to; building producers before the
contract invites rework. [DD]

## 8. First-slice acceptance tests (S6) [DD]

`tests/test_workflow_contract.sh`, `tests/test_export_equivalence.sh`,
`tests/test_loading_rules.sh` — Bash, fixture-driven, matching the existing
`run_case` convention. Fixtures under `tests/fixtures/workflow-contract/` and
`tests/fixtures/export/`.

| Required test class [OR] | Fixture | Expected |
|---|---|---|
| Missing facts | `missing-required-field/` (stage lacks `authority.decides`) | validator fails; names the field |
| Conflicting policy | `conflicting-decisions/` (two stages claim same decision) | fail; both positions reported, not averaged |
| Stale evidence | `stale-revision/` (decision references non-current `verified_revision`) | fail; re-entry state named |
| Cross-module change | `cross-module/` (stage B consumes renamed output of stage A) | dependency check fails with module pair |
| Broken references | `broken-ref/` (Inputs path absent; undeclared path referenced) | both directions fail |
| Repeated exports | run export fixture twice | second run produces zero diff |
| Owner edits | `owner-edited/` (target file carries `owner-edited` marker) | export refuses to overwrite; reports diff instead |
| Fresh-session navigation | walk: `AGENTS.md` → example → stage contract with ≤2 reads | pass |
| Outcome evaluation (not just structure) | run `describe`/export path on the worked example and grade the *outcome*: does the produced module let a fresh agent answer "what loads at §3?" correctly? | recorded in `.devin/eval/`; structure + token counts logged |

Token usage is measured per loading tier (always / per-stage / total for a
stage) and recorded in the eval log — structure and token usage, plus task
outcome grading per Anthropic's eval guidance (grade the outcome state, not the
transcript; code-based graders first, human calibration where needed). [VG][DD]

## 9. Bounded client pilot [DD]

Per owner direction (dogfood first, then `../skill-architect` demo) [OR][RF]:

- **Pilot 1 (this repo):** express this repository's own shape→verify flow as a
  canonical contract, then export compact and modular forms. Owner compares
  both against `skills/shape-change` + `skills/verify-change` behavior. One
  repo, one slice, all decisions recorded.
- **Pilot 2 (sibling demo):** run `describe-workflow` against
  `../skill-architect` — inspect its routers/skills, produce a current-state
  description, mark unknowns NOT FOUND. Owner verifies the description
  recognizes the real workflow.
- Boundaries (from ADR-0004, extended): no network, no sibling-repo mutation,
  no RLP promotion, negative/null results retained in `.devin/eval/`.
- Measures: whether the owner can answer "what does this workflow load, decide,
  and produce at each stage" from the exported artifact alone; correction count
  during review; zero provenance errors.

## 10. Decisions required from the owner

1. ~~Accept / revise / reject this proposal's product boundary (§2), including
   the Workflow Package Builder resolution (§2.1).~~ **Resolved with
   corrections 2026-09-13** — see §2.1: the plugin owns the canonical contract
   and the single renderer; WPB's starter-files incorporates rendered files
   rather than generating equivalent contracts.
2. ~~Approve or amend the canonical contract field set (§3.2).~~ **Resolved
   with corrections** — the versioned canonical contract and its semantics are
   the compatibility surface; both export forms are representations that must
   normalize to it (§3.2a). Field set itself still awaits owner inspection.
3. Confirm the worked example may reuse the leaked-DB-error case and whether
   `examples/` ships in the plugin payload or stays repo-only.
4. ~~Authorize S6.~~ **Authorized with changes 2026-09-13** — isolated
   schema + validators + examples + tests; existing skill behavior preserved;
   schema provisional, does not freeze v1.0; no install, client-repo
   modification, merge, or publish.
5. Unrelated but blocking per roadmap: `run-01` spec review, `devin auth
   login`, baseline-commit decision, ADR-0004 review.
6. ~~Authorize, revise, or defer S7~~ **Authorized with clarifications
   2026-09-14** — implemented per §11 plus: output root must exist outside the
   inspected repo (symlink-resolved); `workflow-observation/0.1.0` implemented,
   `workflow-contract/0.2.0` design-only; content-based snapshot identity over
   dirty trees; `executed` requires a revision-bound execution record.
7. ~~Authorize, revise, or defer S8~~ **Authorized 2026-09-20** — implemented
   per §12: `skills/sdlc-scaffold/scripts/` now carries the callable contract
   interface (`lib-contract.sh`, `validate-workflow-contract.sh`,
   `normalize-workflow.sh`, `lib-loading.sh`, `check-loading-rules.sh`),
   `check-acceptance.sh`, and `export-proposal.sh` + `lib-export.sh`.
   `contract-acceptance/0.1.0` documented at
   `_config/contract-acceptance-schema.md`. `tests/test_export_proposal.sh`
   covers the eleven acceptance criteria.
8. ~~Authorize, revise, or defer S9~~ **Authorized + implemented
   2026-09-20** — `skills/select-improvement/` carries the selector
   (`scripts/select-eligible.sh`), five starter cards mapped to the
   evaluated research inventory, and the `selection-card/0.1.0` format;
   `owner-facts/0.1.0` documented at `_config/owner-facts-schema.md`.
   `tests/test_select_improvement.sh` covers the nine proposed criteria
   plus the six authorized additions.
9. ~~Authorize, revise, or defer S10~~ **Authorized 2026-09-20; implemented**
   per §14 — `skills/evaluate-outcome/` (evaluator + `outcome-targets`/
   `outcome-evidence`/`outcome-receipt` schemas at
   `_config/outcome-evaluation-schema.md`), `tests/test_evaluate_outcome.sh`
   (37 checks). Four round-1 review findings resolved. **Pending:** owner
   receipt review; one open finding — `pairwise_gap` can mask a per-record
   missing `sampling`/`conditions` declaration (`.devin/eval/eval-log.md`
   run-08 open finding). Prior text, for the record: per §14 (revised) — named outcome
   targets separate from workflow checks, product/process split, full
   digest + independent revision binding, no RLP artifact, one reviewable
   receipt outside the inspected repo, illustrative dogfood case, and the
   five-step readiness sequence.

## 11. S7 — `describe-workflow` contract (revised 2026-09-14, pending authorization) [DD]

S7 produces **observations and gaps only** — no workflow acceptance, applied
export, learning promotion, merge, or publication. Owner decisions applied:

### Output location and write boundary

- Inspection writes only to an explicitly selected output root —
  `docs/workflow/observations/{run-id}/` for this repository.
- A current-workflow description is not a delivery change: the inspected
  repository is never modified automatically. Acceptance test: file inventory
  + checksums of the target repo are identical before and after a run.

### Observation ≠ contract

- An observation may be incomplete or conflicted and still be a **structurally
  valid observation**. It is not yet an executable or accepted workflow
  contract and is never validated by `test_workflow_contract.sh` — S6
  validation is not weakened.
- Observations use their own provisional document kind, proposed as
  `workflow-observation/0.1.0`: an envelope (run-id, inspected repo, inspected
  revision or working-tree snapshot identity, observed-at) plus per-claim
  entries carrying source locators, basis class, and unresolved-conflict
  markers. `NOT FOUND` is legal in an observation; it is a recorded gap, not
  a validation escape.
- Promotion observation → candidate contract is a separate human step
  (informs S8), not an S7 output.

### Three-plane coverage

- **Workflow:** covered by existing stage fields (`kind: internal|external`
  blocks).
- **Context routing:** partially covered — stage `context_*` fields exist, but
  no package-level routing map (entry points, write boundaries, transient vs
  durable state).
- **Topology:** not covered — no component/boundary/coupling model.
- Proposed versioned extension `workflow-contract/0.2.0` (provisional): adds
  optional `kind: topology` (components, boundary edges, observed coupling
  with basis) and `kind: context-map` (entry points, write boundaries,
  transient vs durable routing) blocks. Observation snapshots may carry these
  blocks in observed form; the extension ships for owner review inside S7 —
  it does not alter 0.1.0 semantics.

### Provenance, basis, and conflicts

- Every factual claim carries a **source locator** — `path:line-range` for
  inspected files, `interview:{evidence-id}` for WPB records — not merely an
  E/D class.
- The envelope records the inspected revision or working-tree snapshot hash;
  observations pinned to a superseded revision are reported stale.
- Basis classes distinguish **declared** (policy/doc states it) from
  **configured** (config/code exists) from **executed** (evidence it ran).
  A CI configuration is `configured`, never promoted to `executed`.
- Conflicting claims are retained verbatim with their source locators and
  marked `unresolved` — never averaged or silently preferred.

### WPB interview input (optional)

- Repository-only inspection works standalone; the interview record is
  optional input.
- Minimal input contract: `evidence-id`, `statement`, `source-ref`,
  `review-status` per row. Unsupported formats produce a clear diagnostic and
  a non-zero exit — never silently interpreted as verified owner facts.
- Missing facts become a **gap report** for owner follow-up, not an interview.

### Reruns and owner edits

- Each run writes a **new** observation snapshot plus a comparison report
  diffing it against the prior snapshot.
- Prior observations and owner-authored content are never modified or
  appended to automatically. An older owner correction is labeled
  owner-authored — it is not re-emitted as newly observed evidence.

### Ordering

- S7 is sequential before S8 implementation. S8 design may be discussed now;
  its implementation waits for the observation-to-contract boundary and any
  0.2.0 schema changes S7 establishes.

### Acceptance criteria

| # | Criterion |
|---|---|
| 1 | Inspected repo byte-identical before/after; writes confined to the selected output root |
| 2 | Snapshot carries run-id, inspected revision/tree identity, per-claim source locators, basis classes, unresolved markers |
| 3 | Missing facts appear in the gap report with what/who-to-ask; nothing is inferred |
| 4 | Conflicting policy retained with both sources, marked unresolved |
| 5 | Unsupported interview input → explicit diagnostic + non-zero exit |
| 6 | Observation validator fails closed on missing locators, bad basis labels, malformed envelope — and accepts incomplete/conflicted observations that are structurally sound |
| 7 | Stale observations (inspected revision superseded) are flagged |
| 8 | `configured` is never reported as `executed` — configured-but-unrun fixture fails if upgraded |
| 9 | Rerun produces new snapshot + comparison report; owner edits and prior snapshots untouched |
| 10 | No acceptance, export, RLP, Skill Architect, merge, or publication artifact is produced |

## 12. S8 — export contract (revised 2026-09-14; authorized and implemented 2026-09-20) [DD]

S8 renders an **accepted** workflow contract into compact or modular proposal
files under a separate proposal root. It produces reviewable output only —
applying, merging, or installing that output is a separate authorized step.

### 12.1 Acceptance record — separate, content-bound

Acceptance lives in a sibling record, not on the contract. Proposed format
(its own document kind; `workflow-contract/0.1.0` is unchanged):

```contract
id: acceptance-<ref>
kind: contract-acceptance
schema_version: contract-acceptance/0.1.0
contract: <path to the accepted contract instance>
contract_schema: workflow-contract/0.1.0
contract_digest: sha256:<digest of the normalized canonical contract>
reviewer: <named human>
reviewed_at: <date>
decision: accept
rationale: <one line>
```

- The digest binds acceptance to content: editing the contract after review
  invalidates it — the renderer recomputes the digest over the normalized
  contract (S6 encoding) and requires a match plus `decision: accept`.
- The renderer **reads** this record; it never creates or updates approval.
- Missing, malformed, digest-mismatched, or non-`accept` records → explicit
  refusal, nothing written.

### 12.2 Target — separate proposal root

- Three explicit roots: **input root** (where the contract + acceptance
  record live), **client root** (the repository the proposal describes),
  **output root** (proposal destination).
- The output root must resolve **outside** the client root, symlink-resolved
  — same rule as S7's inspected-repo boundary. Overlapping destinations are
  rejected before any write.
- Applying proposals into the client repository is a separate authorized
  step, outside S8.

### 12.3 Regeneration semantics

- No byte-identical reproduction of the hand-authored example is required.
- Required instead:
  - both forms preserve the accepted canonical semantics (S6 equivalence);
  - identical inputs + renderer version → byte-identical output;
  - repeated export → `SAME`, files unmodified;
  - owner-differing destination → `REFUSE` plus a useful diff report.

### 12.4 Context relocation

Every `context_entry` / declared reference is classified before render:

| Class | Resolution in the export |
|---|---|
| Bundled reference | Shipped inside the package; rewritten to its exported-relative path |
| Client-repository reference | Rewritten to resolve from the exported location to the client root (documented relative path the applier preserves) |
| Named resource | Non-path token; carried through verbatim |
| Runtime artifact | `changes/`, `output/`, `{placeholder}` — carried through; resolves at run time, not export time |

- Arbitrary referenced files are not blindly copied; relative paths that
  only worked in the source layout are rewritten, not preserved.
- Both rendered forms are validated **in staging** (contract validation +
  loading rules against the rendered tree) before any destination write.
- If correct relocation requires a schema change (e.g., a declared
  `reference_class` field), that change is proposed for owner review first —
  not implemented inside S8.

### 12.5 Preflight and failure handling

- Render into temporary staging; validate the complete package there.
- Check **every** destination conflict before writing any proposal file.
  Any conflict → destination left byte-identical, including files that would
  have been new (no partial emission). Staging is cleaned up; the report
  names each conflict.

### 12.6 Product validation interface

- S6 validation/normalization is extracted into a callable interface (a
  `scripts/` validator + normalizer the exporter invokes directly). S6 test
  suites remain — as consumers of that interface. The exporter never shells
  a test suite as its input validator.

### Acceptance criteria

| # | Criterion |
|---|---|
| 1 | Unaccepted contract, missing/malformed record, or `decision ≠ accept` → refusal, nothing written |
| 2 | Contract modified after acceptance (digest mismatch) → refusal naming the drift |
| 3 | Observation input → refusal (observation ≠ contract) |
| 4 | Invalid contract or unrelocatable reference → preflight fails before any write |
| 5 | Identical inputs + renderer version → byte-identical output, both forms |
| 6 | Both forms normalize identically under the S6 equivalence check |
| 7 | Repeat export → all `SAME`, zero diff |
| 8 | Mixed destination (new files + one owner-edited file) → `REFUSE` on the edited file, destination unchanged including the would-be-new files |
| 9 | Output root overlapping the client root (incl. symlink-resolved) → refused |
| 10 | Broken references after relocation fail validation in either form |
| 11 | No acceptance creation, client application, install, merge, RLP, or publication artifact |

### Explicitly outside S8

Observation→contract promotion, applying proposals to client repos,
installation, merge, publication, and unrelated schema expansion.

## 13. S9 — improvement-selection contract (authorized + implemented 2026-09-20) [DD]

S9 implements the deterministic card-applicability selector sketched in
`PACKAGE-BUILDER-INTEGRATION.md` (`eligible()`), plus the
adoption-prerequisite graph. It selects; it never asserts acceptance.
Implemented as `skills/select-improvement/` (skill, five starter cards,
`scripts/select-eligible.sh`) with formats in
`_config/owner-facts-schema.md` and
`skills/select-improvement/references/selection-contract.md`.

### Inputs (as authorized)

- **Card set** — `selection-card/0.1.0` blocks: `applies_when` (applicability
  predicates), `requires_capability` (established client capabilities),
  `depends_on` (card relationships), plus `research_card`/`research_path`/
  `research_status` provenance. Inventory: the five agreed practices mapped
  to `R-FLOW-001`, `R-VERIFY-001`, `R-CONTROL-001`, `R-HITL-001`,
  `R-MEASURE-001` — all `pending-owner-review`, surfaced as provisional.
- **Owner facts** — `owner-facts/0.1.0`, a thin selection view over existing
  evidence (not a separate evidence system): each `fact` item is
  `ID = VALUE ; SOURCE ; STATE` with `STATE ∈ {established, unknown,
  conflicted}`. Referencing an observation does not promote it.

### Semantics (as authorized)

- Exact fact-ID and declared-value matching only; unsupported predicate
  syntax rejected; no fuzzy matching, inference, or automatic promotion.
- `established` false values are distinct from absent facts; `unknown` and
  `conflicted` are separate states. A fact ID declared twice fails
  validation — matching order never decides.
- Applicability is reported separately from readiness. `requires_capability`
  gates readiness, not applicability; `depends_on` prerequisites require an
  established `CARD-ID = adopted` fact — selection is not implementation.
- Missing dependency targets and cycles are graph errors (exit 3), not
  ordinary ineligibility.

### Output

Deterministic stdout report: `eligible and ready`, `applicable — blocked`,
`inapplicable`, `unknown`, `conflicted`, `missing-fact gaps` — with
per-card provenance. No writes; no card marked accepted; AI ranking and
human adoption remain outside.

### Acceptance criteria (all verified in tests/test_select_improvement.sh)

The nine proposed criteria plus: established-false vs. absent, conflicting
fact states in both orders, unpromoted observation references, missing
dependency targets, cycles, and selected-but-not-adopted prerequisites —
18 checks total.

## 14. S10 — outcome-evaluation contract (revised 2026-09-20, pending authorization) [DD]

S10 implements `evaluate-outcome`: a deterministic evaluator producing one
reviewable `outcome-receipt/0.1.0` for the dogfood pilot — the smallest
slice that answers two distinct questions with real evidence:

- **Product** — did the delivered change achieve its intended effect?
- **Process** — did the workflow improvement help delivery, accounting for
  clarification, review, rework, and artifact-maintenance effort?

It reports classified evidence with provenance; it never certifies
success, marks anything accepted, or promotes corrections.

### Inputs

- **Outcome targets** — an `outcome-targets/0.1.0` file (provisional):
  named, stable outcome IDs, each with `kind: product|process`, the
  explicit link to accepted intent (the accepted contract's full digest),
  the declared measure, unit, population/scope, observation period, and
  measurement basis. Outcome targets are *not* workflow checks: a
  stage/check reference may supply evidence for an outcome, but a passing
  check never establishes the outcome.
- **Outcome evidence** — an `outcome-evidence/0.1.0` file reusing the S9
  item grammar and locator types:
  `evidence: <outcome-id> ; <observed-value> ; <locator> ; <period> ;
  <implementation-rev>` — source identity and observation period are
  first-class, not annotations.
- **Baseline facts** — an `owner-facts/0.1.0` file with pre-adoption
  measurements (the `baseline-captured` capability from C-05). Absent
  baseline → the observation is still reportable, but the receipt cannot
  support an improvement claim — `NOT FOUND`, never fabricated.
- **Accepted contract + acceptance record** — the full canonical contract
  digest (S8 machinery) identifies the accepted intent the targets link
  to. The evaluated implementation revision is recorded independently;
  evidence is never re-bound to a newer contract.

### Semantics

- Per outcome: `observed` means *evidence is available* — not that the
  outcome succeeded. `missing`, `conflicted`, `stale`, and
  `non-comparable` (evidence whose unit/scope/period/basis doesn't match
  the declared measure) are preserved verbatim, not resolved.
- A newer contract revision triggers applicability/re-evaluation handling
  on the receipt — it does not erase or re-label a historical observation
  that was valid for its recorded revision and period.
- Comparison is minimal and declared: measure, unit, population/scope,
  observation period, measurement basis must match between baseline and
  observation for any before/after line; mismatches → `non-comparable`
  with the mismatch named. No general metrics engine.
- **Candidate lessons/corrections only.** The receipt may list candidate
  lessons or corrections for human review. A reviewer-name field alone is
  not confirmation, and no RLP handoff artifact is produced — a later
  handoff will reuse RLP's actual contract rather than one invented here.

### Outputs and boundaries

- One reviewable receipt written to an explicitly chosen destination
  **outside** the inspected repository, using the S8 safe-output
  discipline: preflight the destination; an existing differing file →
  `REFUSE` and preserve it; identical → `SAME`. Stdout summarizes the
  receipt; the file is the artifact.
- Inputs and evidence are read-only; the receipt retains input/evidence
  provenance (contract digest, implementation revision, locators,
  periods).
- No verdict, no adoption marking, no RLP artifact.

### Illustrative dogfood receipt (labeled illustrative data)

Evaluating this repository's own `describe-workflow` adoption (product)
and the S6–S9 contract-first process (process), with invented numbers:

```contract
id: receipt-dogfood-01
kind: outcome-receipt
schema_version: outcome-receipt/0.1.0
contract_digest: sha256:<full-digest-of-accepted-contract>
implementation_rev: <commit-at-delivery>
outcome: O-PROD-1 ; product ; "snapshot claims resolvable to sources" ; observed ; 19/20 claims with locators ; period:2026-09-14..2026-09-20 ; rev:<impl-rev>
outcome: O-PROC-1 ; process ; "review effort per slice" ; non-comparable ; baseline unit=review-hours vs evidence unit=wall-clock-days
outcome: O-PROC-2 ; process ; "clarification rounds per slice" ; observed ; 2 rounds avg (illustrative) ; baseline: NOT FOUND — improvement claim not supported
lesson: "acceptance records caught a post-review edit once" ; status: candidate
```

Deterministically checkable: field grammar, digest binding, period/rev
consistency, unit-scope comparability rules, `NOT FOUND` handling,
destination preflight. Owner judgment required: whether 19/20 locators is
adequate, whether the process measures capture real effort, whether a
negative or inconclusive receipt warrants design change — the evaluator
must be able to emit all three (success, negative, inconclusive) without
collapsing them into a score.

### Prerequisites

- S6 (contract + validation), S8 (acceptance record, digest machinery,
  safe-output discipline). S9 supplies adopted-practice context but is not
  mechanically required.

### Acceptance criteria

| # | Criterion |
|---|---|
| 1 | Outcome targets carry stable IDs, `kind`, and an explicit accepted-intent link (full contract digest); stage/check references supply evidence only — a passing check never establishes an outcome |
| 2 | Product and process questions reported as separate sections; process outcomes include effort accounting fields (clarification, review, rework, artifact maintenance) |
| 3 | Evidence identities separated: full contract digest for intent, independent `implementation_rev`, observation period and source locator carried per item — no digest-prefix binding |
| 4 | `observed` = evidence available, not success; `missing`, `conflicted`, `stale`, `non-comparable` preserved verbatim |
| 5 | Newer contract revision → re-evaluation flag on the receipt; historical observations keep their recorded revision/period |
| 6 | Missing baseline → observation still reported, improvement claim marked `NOT FOUND` |
| 7 | Comparability enforced on declared fields only (measure, unit, scope, period, basis); mismatch → `non-comparable` naming the field |
| 8 | Candidate lessons listed for review; no RLP artifact; reviewer name alone does not confirm |
| 9 | Receipt written to an explicit destination outside the inspected repo; differing file → `REFUSE`, identical → `SAME`; stdout summarizes; inputs read-only |
| 10 | Deterministic: identical inputs → identical receipt; illustrative dogfood receipt in tests exercises success, negative, and inconclusive outcomes |

### Readiness sequence after authorization

1. Documentation reconciliation — `_config/` schema docs, AGENTS/CONTEXT
   routing, proposal §14 status.
2. Reproducible baseline — record the dogfood baseline facts (effort and
   product measures) in an `owner-facts` file before the run.
3. One-host installation — `devin plugins install .` once `devin auth
   login` is done; verify the skill loads in one host only.
4. Dogfood run — evaluate this repository's own pilot slice against the
   baseline.
5. Owner evaluation — review the receipt; decide accept/revise/reject and
   whether negative/inconclusive outcomes warrant design change.

### Explicitly outside S10

RLP handoff artifact (deferred to a later slice using RLP's contract),
re-running describe-workflow, S11 release gate, commits, installation,
client application, merge, or publication.

| Correction | Applied at |
|---|---|
| WPB delegates contract rendering to this plugin's single renderer; starter-files references rendered files | §2.1 |
| `describe-workflow` inspects/reconciles repo evidence; may consume WPB interview records; no interview duplication | §2.1 |
| Workflow acceptance ≠ permission to apply an export; exports never overwrite owner edits | §2.1, §3.2a |
| Implementation is an explicit `kind: external` stage (handoff, external actor, outputs, return evidence) — not an omitted folder | §3.2, §4.2 |
| Context inputs are required entry points plus scoped exploration, not an absolute reading allow-list | §3.2, §5 rule 1 |
| Compatibility surface is the versioned canonical contract + semantics, not export representations | §3.2a |
| Equivalence = normalized semantic comparison incl. authority, dependencies, evidence, context, re-entry | §4.3 |
| S6 scope: schema + validators + examples + tests; provisional; no freeze, install, client mutation, merge, or publish | §7, §8 |
