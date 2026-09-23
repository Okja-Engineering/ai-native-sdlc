# Provisional workflow audit — evidence-grounded delivery plugin

> **PROVISIONAL · UNREVIEWED · IMPLEMENTATION UNAUTHORIZED**
>
> E09 is decisive: an installable plugin **will** be built using the local sibling-plugin pattern. E10 corrects the repository implementation contract: scripts use Bash; Go is reserved for logic that cannot remain safe and readable in Bash; Python scripts are prohibited. This package preserves its provisional recommendation and provenance; implementation was subsequently authorized via ADR-0002.

## Readiness and rationale

At package creation, this was ready for owner review of a proposed plugin specification only and was not implementation authority. E09 superseded A01/A02 only where they suggested that no plugin or a saved prompt could be the final form. E10 subsequently corrected the script language contract, and ADR-0002 subsequently authorized implementation of the first slice. The package itself remains a provisional record; its original `implementation_authorized: false` provenance is not retroactively rewritten.

## Source inventory

| ID | Source | Treatment |
|---|---|---|
| E01–E08 | `interview-record.md`, evidence register | Reported owner evidence |
| E09 | `interview-record.md`, lines 208–218 | Decisive owner correction: plugin form fixed |
| E10 | Owner correction after package creation | Repository scripts use Bash; Go only when Bash cannot stay safe/readable; Python scripts prohibited |
| ADR-0002 | Subsequent architecture decision | Historical implementation authorization for the first slice; does not alter provisional package provenance |
| A01–A02, Q01 | `interview-record.md`, lines 195–197 | Preserve except the no-plugin implication superseded by E09 |
| D01–D02 | `../skill-architect`, `../repo-learning-protocol` | Local installable-plugin structural precedents |
| D10 | `research/stages/03-synthesize/output/workflow-specification.md` | Accepted/working direction; not implementation authority |
| D11 | `research/stages/03-synthesize/output/skill-system-options.md` | Candidate comparison only |
| D12 | Canonical Workflow Package Builder materials | Method and output contract |
| D13 | `EXTERNAL-IMPLEMENTATIONS.md` | Two public implementation comparisons |
| R-* | Five evaluated cards under `research/` | Research support, pending owner review |

## Fidelity findings

1. **Product boundary is fixed.** Any recommendation of no plugin or a saved prompt as final form contradicts E09. Saved prompts/references may be internal plugin resources only.
2. **Implementation remains separate.** The package recommends files and contracts but creates none; owner review does not itself authorize implementation.
3. **Responsibilities precede names.** Independently derived boundaries are: (a) evidence intake/provenance, (b) evidence evaluation/filtering, (c) synthesis into intent/specification, (d) sequential delivery-boundary guidance, and (e) retained human decisions. Existing names were compared only afterward.
4. **Current research and future runtime are distinct.** C01–C04 are reported research work. The six-phase intent-to-merge-ready model is a working specification, not proven current practice.

## Feasibility findings and smallest internal architecture

The smallest credible plugin is one installable manifest set with **two candidate skills**, introduced sequentially:

1. **`evidence-to-intent` (first implementation slice):** pull only owner-supplied/local inputs; validate provenance and card shape; evaluate applicability and contradictions; filter unsupported claims; synthesize a provisional intent/specification; validate the output; stop for owner `accept | revise | reject`. Its phases are **intake → evaluate/filter → synthesize → human decision**. These are phases inside one skill, not four skills.
2. **`reviewable-delivery` (later candidate, not first slice):** consume only an owner-reviewed specification and guide one reviewable value slice through explicit sequential HITL boundaries. It must not merge, deploy, promote RLP learnings, or create/audit skills.

Shared responsibilities should remain references, not a third orchestration skill: `references/evidence-contract.md`, `references/specification-contract.md`, and later `references/delivery-boundaries.md`, `references/hitl-phase-contract.md`, and `references/reviewable-value-slice-contract.md`. Deterministic scripts should be narrow: `validate-evidence.sh` for IDs/schema/status/path resolution and `validate-specification.sh` for required output fields/review markers. AI handles comparison, applicability, contradiction explanation, and synthesis. Humans retain source selection, intent acceptance, slice selection, evidence-plan acceptance, plan exceptions, review, and merge-readiness decisions.

No connector, autonomous graph engine, scaffold, hook gate, or lifecycle-owning agent is justified for v0. “Pull” means ingest explicitly supplied paths/URLs supported by the host; absent access is `NOT FOUND`, never fabricated retrieval.

## Candidate-name comparison

| Boundary | Candidates compared | Recommendation | Reason |
|---|---|---|---|
| Research to accepted intent/spec | `research-audit`, `research-to-spec`, `evidence-to-intent` | `evidence-to-intent` | Names both evidence input and human-owned outcome; avoids implying audit-only or automatic truth |
| Sequential HITL delivery | `pilot-readiness`, `slice-guide`, `reviewable-delivery` | `reviewable-delivery` | Expresses bounded guidance without claiming merge/deploy ownership |
| Whole plugin | `ai-native-sdlc`, `hitl-delivery`, `evidence-led-delivery` | `evidence-led-delivery` | Avoids broad lifecycle/autonomy claim and connects both skills |

Names remain candidates pending owner review; responsibility boundaries are the recommendation.

## Comparison with public implementations

- `imsungbin/ai-native-sdlc-playbook`: adopt source-to-artifact traceability, honest completion boundaries, and deterministic repository validation; do not inherit article-faithful lifecycle scope.
- `bashebr/ai-native-sdlc`: adopt manifest/assets/reference separation and runtime-vs-adoption distinction; reject its broad autonomous lifecycle, agent organization, graph-as-engine, and gate-ledger scope for v0.
- Both are implementation precedents, not evidence of delivery outcomes. The local sibling pattern is the packaging authority: root `.devin-plugin/plugin.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`, canonical `skills/`, per-skill `SKILL.md`, local references/scripts, and repository-level tests.

## Value findings

Hypothesis: evidence filtering before specification plus explicit HITL delivery boundaries reduces unsupported intent, oversized changes, and review rework. Value is **not yet calculable**: no matched baseline, volume, total review/rework/setup effort, or observed outcome exists. Measure total effort per owner-accepted specification, provenance/anchoring errors, and later production-qualified slices; do not convert capacity to cash.

## Responsibility and non-responsibility boundaries

| Layer | Owns | Does not own |
|---|---|---|
| Plugin | Provenance checks, evidence comparison, synthesis drafts, boundary guidance, receipts | Truth, owner intent, repository policy, merge/deploy |
| Human owner/engineer | Source selection, applicability, accepted intent/spec, slice and risk decisions | Delegating consequential approval implicitly |
| Repository toolchain | Exact deterministic checks and reproducible results | Semantic intent or residual-risk acceptance |
| RLP | Correction capture/triage/promotion | Automatic handoff from this plugin |
| Skill Architect | Audit of an approved skill candidate | Designing or approving this workflow automatically |

## Contradictions and assumptions

- The former package selected a saved prompt; E09 supersedes that final-form conclusion.
- A01 remains a research question about useful repeating capability, but cannot negate the plugin decision.
- A02 remains: names are unapproved alternatives.
- D10 proposes six logical jobs; they must not automatically become six skills/files.
- Assumption A03: two externally invokable responsibilities are smaller and clearer than one mega-skill; owner review resolves it.
- Assumption A04: v0 can operate on explicitly supplied local evidence without network connectors.
- Assumption A05: the four per-platform manifest conventions match the inspected sibling repositories: `.devin` uses `skills`, `.claude` uses `displayName` and `./skills/`, `.codex` and `.cursor` use `./skills/`.
- E10 resolves the former language assumption: `validate-evidence.sh` and `validate-specification.sh` are portable Bash contracts in the implemented first slice. Go remains reserved for logic that cannot stay safe/readable in Bash.

## Manifest, checks, and first slice

Proposed manifest set, matching the inspected sibling per-platform conventions:

- `.devin-plugin/plugin.json`: `skills: "skills"`
- `.claude-plugin/plugin.json`: `displayName` + `skills: "./skills/"`
- `.codex-plugin/plugin.json`: `skills: "./skills/"`
- `.cursor-plugin/plugin.json`: `skills: "./skills/"`

Proposed repository tests:

1. `tests/test_structure.sh`: validate all four manifest files assert name/version/license and per-platform `skills` values; validate `evidence-to-intent` and `reviewable-delivery` SKILL.md frontmatter and required sections; check scripts are executable; confirm no nested plugin manifests.
2. `tests/test_evidence_to_intent.sh`: normal, missing/conflicting, and exception fixtures; prove deterministic validation fails closed and no downstream artifacts are created.
3. `tests/test_walk.sh`: fresh-session path walk from `AGENTS.md` to `skills/evidence-to-intent/SKILL.md`, at most two named references, the three tests, exact inputs/output/review marker, and no automatic transition to delivery, RLP, Skill Architect, merge, or deploy.

**First implementation slice (recommended here; subsequently authorized via ADR-0002 and implemented):** the four manifest files; root `AGENTS.md`/`CONTEXT.md`; only `skills/evidence-to-intent/` with `SKILL.md`, its two references, `validate-evidence.sh`, `validate-specification.sh`; and the three repository tests. `reviewable-delivery`, scaffolding, connectors, and target-repository mutation remain deferred from this slice.

## Three proposed acceptance cases

1. **Normal:** completed research spike and five selected cards produce a provenance-preserving provisional spec; owner records `accept | revise | reject`. Pass: every material claim traces to E/D/R/A, no candidate name is inherited as evidence, and no delivery artifact is created.
2. **Missing/conflicting:** absent owner acceptance cues or conflicting evidence status. Pass: deterministic validation reports exact failures, synthesis marks `NOT FOUND`, and the skill stops before a runnable specification.
3. **Exception:** credible but inapplicable/contradictory research — for example, one public implementation prescribes a full autonomous lifecycle while another selected research card supports sequential HITL augmentation, with neither directly applicable to the owner boundary without explicit owner choice. Pass: preserve both claims and limitations, exclude unsupported prescription, route the consequence to the owner, and do not average conflict into false certainty.

These tests were proposed by this package and are now present in the implemented first slice authorized via ADR-0002. Current repository verification covers manifest/path structure, Bash syntax and executable bits, validator fixtures, and the first-slice walk.

## Remaining questions

1. What exact cues make the owner accept the evidence-to-specification decomposition (Q01)?
2. Which D10 decisions are durable, and what terminal term should the later delivery skill use?
3. What evidence classes and minimum source fields are mandatory for v0?
4. Which plugin name and two public skill names does the owner approve?
5. Which content may be distributed given private-source boundaries?
