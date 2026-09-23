---
type: workflow-interview
workflow: "Turn AI-native SDLC research into a pilotable HITL plugin design"
review_status: "superseded-research-note"
review_note: "Do not use as Workflow Package Builder input. The owner chose a research-derived workflow specification rather than a current-workflow interview."
readiness: "not-for-package-building"
---

# Superseded provisional workflow interview record

> Do not use this file to run Workflow Package Builder. It is retained only as a correction record. The active research deliverable is `research/stages/03-synthesize/output/workflow-specification.md`.

## 1. Person, purpose, and boundary

The owner is developing a family of plugins and methods for AI-assisted software work. Existing local projects include Skill Architect and Repository Learning Protocol, with private ICM-converted Scuba skills also available as structural precedents. [E01, D01, D02, D03]

The current work is a research-to-design workflow: turn industry research on AI-native software delivery into a package that can determine the smallest useful plugin structure, skills, phases, subskills, human checkpoints, and first pilot. [E02, E08]

The desired outcome is not a full autonomous SDLC. It is sequential human-in-the-loop augmentation that produces smaller, human-reviewable chunks of value and de-risks movement toward production. [E03]

Working repeat-unit hypothesis: one research-backed SDLC practice or capability moving from evaluated evidence to an owner-corrected workflow recommendation and one checkable pilot slice. This has not yet been confirmed by the owner. [A01]

Trigger: a reviewed body of research is ready to be translated into a plugin and pilot design. [E02, E08]

Done for the immediate next step: Workflow Package Builder has produced an owner-corrected package that identifies the appropriate form, skills/phases/subskills, retained human decisions, plugin boundaries, and smallest first test. [E08]

Outside the current step:

- implementing the plugin;
- migrating a pilot team's repository;
- connecting accounts or services;
- running live production work;
- creating RLP promotions;
- auditing an unbuilt skill;
- claiming pilot outcomes. [E04, E05]

## 2. One recent instance

The current repository itself is the recent instance. The owner began with Anthropic's AI-Native SDLC article and asked for its content, associated links, and claims to be explored. The research was abstracted into vendor-neutral claims and compared with empirical studies, standards, thought leaders, Workflow Package Builder, Scuba Stack, Skill Architect, RLP, and two public AI-native SDLC implementations. [E06, D04]

An initial misunderstanding treated “60/30/90” as a timeline. The owner corrected it to the 60/30/10 skill heuristic: deterministic actions, orchestration, and AI judgment. [E07]

A second design correction established that the immediate output was research, not a downstream plugin implementation. A sibling `ai-native-sdlc` repository was created to hold the research. [E02, D04]

A later proposal selected a thin research-to-pilot plugin with candidate skills. The owner then clarified the desired next state: switch into this repository and run Workflow Package Builder against the research so the package-building process determines the skills, phases, and subskills. Therefore the proposed skill list remains input to evaluate, not an accepted design. [E08, A02]

No Workflow Package Builder output has been generated yet. [D04]

## 3. Current workflow

| ID | Name | Input | Action | Actor/tool | Output | Next destination | Human check | Evidence |
|---|---|---|---|---|---|---|---|---|
| C01 | Discover claims | Article, associated links, external research | Extract claims, follow sources, distinguish vendor capability from outcome evidence | AI researcher with web/file tools | Claim inventory and source material | Evidence evaluation | Owner corrects scope and intent | E06, D04 |
| C02 | Evaluate evidence | Claims and sources | Compare empirical evidence, standards, vendor claims, practitioner opinion, contradictions, and limitations | AI researcher | Evidence matrix | Synthesis | Owner challenges unsupported conclusions | D04 |
| C03 | Synthesize practices | Evaluated claims | Derive HITL, deterministic-first, small-batch, verification, governance, and measurement principles | AI researcher | Research packet and principles | Structure research | Owner confirms augmentation boundary | E03, D04 |
| C04 | Structure research | Research packet, Workflow Package Builder contract, ICM, sibling plugins | Create atomic research schema, package-field boundaries, source IDs, plugin precedents, and ICM routing | AI researcher and repository files | Research library and design considerations | Package building | Owner corrects premature design commitments | E08, D04 |
| C05 | Build workflow package | Provisional interview record plus research library | Audit fidelity, feasibility, and value; select smallest useful form; recommend workspace/contracts/prompts and first test | Workflow Package Builder | `workflow-audit.md`, `my-workflow-package.html`, `starter-files.md` in a new output directory | Owner correction | Owner must correct package before pilot | E08, D05 |
| C06 | Pilot design and implementation | Owner-corrected package | NOT YET PERFORMED — determine and then build only the approved first slice | Future work | Pilot/plugin artifacts | Pilot execution | Separate explicit authorization required | E04, E08 |

Current loop-back: when the owner corrects an interpretation, the research or mandate is revised before downstream design continues. [E07, E08]

## 4. Inputs, outputs, and access

### Inputs

- Anthropic AI-Native SDLC article and linked documentation: public web content, inspected and summarized. [D04]
- Empirical studies, standards, frameworks, and thought-leader material: public sources registered in `research/sources/source-register.md`. [D06]
- Workflow Package Builder skill and references: available locally and inspected; private content must not be copied into a public plugin without permission. [D05]
- Skill Architect and RLP repositories: local sibling repositories, inspected as preferred plugin-structure precedents. [D01, D02]
- Private ICM-converted Scuba skills: locally available as structural precedents; distribution rights and intended public subset are not established. [D03]
- External implementation precedents: public GitHub repositories reviewed in `EXTERNAL-IMPLEMENTATIONS.md`. [D07]

### Immediate output

The required next output is a Workflow Package Builder package containing:

1. an evidence-based workflow audit;
2. an editable HTML package;
3. copyable starter-file recommendations.

The package must determine, rather than inherit, the appropriate plugin form, skills, phases, subskills, checks, and first trial. [E08, D05]

Acceptance condition: the owner recognizes and corrects the account, agrees that the package preserves augmentation and plugin-family boundaries, and explicitly approves a first test. Package completion alone does not authorize implementation. [E03, E04, D05]

## 5. Human judgment and exceptions

The owner retains:

- whether the research reflects the intended problem;
- whether the flow unit is useful;
- whether a plugin boundary supports the existing plugin family;
- which skills, phases, and subskills should exist;
- what constitutes a human-reviewable chunk of value;
- whether the package is ready for a pilot;
- and whether implementation may begin. [E03, E08]

The owner has already corrected:

- timeline interpretation versus 60/30/10 architecture;
- premature plugin implementation versus research first;
- premature acceptance of a proposed skill structure versus letting Workflow Package Builder determine it. [E07, E02, E08]

The owner distrusts designs that drift toward full agentic automation, impose a universal lifecycle, or optimize automation metrics rather than human augmentation and reviewability. [E03]

Final authority: the owner. The exact cues and threshold for accepting a plugin skill decomposition are NOT FOUND. This should be asked during package building. [Q01]

## 6. Value and measurements

Initial value hypothesis: improve AI-assisted SDLC maturity by replacing automation pressure and cognitive dissonance with sequential HITL processing and smaller de-risked units of value. [E03]

No measured baseline or saving exists yet. Research indicates that implementation activity, review/rework, production-qualified outcomes, stability, human comprehension, and total cost should be measured separately. [D08]

Candidate pilot measures, not owner-approved thresholds:

- lead time per production-qualified value slice;
- framing and review effort;
- rework after approval;
- first-pass verification;
- escaped defects and rollback;
- human ability to explain the accepted change;
- model, CI, setup, review, and rework cost. [D08]

Value is not yet calculable. The first package should produce a measurement plan, not an ROI claim. [D05, D08]

## 7. Stable context and per-instance material

Stable material:

- `PRINCIPLES.md` — current research principles. [D04]
- `research/` — evaluated cards, source register, router, and provenance map. [D06]
- `_config/research-card-schema.md` — research-card contract. [D04]
- `PACKAGE-BUILDER-INTEGRATION.md` — evidence boundary. [D04]
- `EXTERNAL-IMPLEMENTATIONS.md` — implementation precedents. [D07]
- local Skill Architect and RLP repository conventions. [D01, D02]

Per-instance material for the next package run:

- this `interview-record.md`;
- owner corrections to it;
- selected research cards;
- generated package files in a new output directory. [D05]

The package builder must not treat `PLUGIN-DESIGN.md` as an approved specification. It is a design alternative and code-sample source. [E08, A02]

## 8. Practical constraints and first sample

Available capabilities:

- local file reading and writing;
- Git repository inspection;
- Workflow Package Builder skill;
- browser preview where available;
- local sibling plugin examples;
- public web research. [D01-D07]

Constraints:

- do not generate package outputs before invoking Workflow Package Builder;
- do not implement or scaffold the downstream plugin during package building;
- do not publish private Workflow Package Builder or Scuba material;
- do not infer owner facts from industry research;
- do not commit or push without separate owner choice. [E04, E08]

First sample: this completed research spike. Expected result: the package identifies a smallest useful plugin/workspace form and one first test while preserving Workflow Package Builder, Scuba, RLP, and Skill Architect boundaries. [E08]

Likely failure test: the package simply reproduces the proposed `research-audit`, `pilot-readiness`, and `slice-review` skills without re-deriving them from evidence. That should fail. [A02]

Missing/conflicting-data test: the repeat unit and acceptance cues for the plugin skill decomposition remain unconfirmed. The package should ask rather than invent them. [A01, Q01]

## 9. Gaps, contradictions, and readiness

| Gap or conflict | Evidence | Why it matters | Question | Owner | Blocking |
|---|---|---|---|---|---|
| Repeat unit is only a hypothesis | A01 | ICM form and skill boundaries depend on it | Is one research-backed practice/capability the repeating unit, or is it one pilot/team transformation? | Owner | Blocks final design, not provisional package |
| Proposed skill list may anchor the design | E08, A02 | Package must independently derive skills/phases | Should `PLUGIN-DESIGN.md` be treated only as a rejected/competing option? | Owner | Blocks acceptance, not draft |
| Acceptance cues for skill decomposition are unknown | Q01 | The package needs a real human check | What must be true for the owner to accept the chosen skills/phases? | Owner | Blocks final package acceptance |
| Pilot team and repository are not selected | D08 | Live access, baseline, and first implementation depend on them | Which team and repository will supply the pilot? | Owner | Later implementation only |
| Public/private source boundary needs confirmation | D03, D05 | Public plugin cannot copy private methods without permission | Which local private assets may be adapted or distributed? | Owner | Blocks publication, not design |
| Thin-plugin decision is recorded as proposed | D09 | It should not predetermine package findings | Should package building supersede or confirm ADR-0001? | Owner | Package must evaluate it |

Readiness: **provisional but ready for a package draft**. Trigger, desired deliverable, current sequence, retained owner authority, and practical first sample are known. Final form selection remains intentionally open.

## 10. Evidence register

| ID | Evidence | Source locator | Kind |
|---|---|---|---|
| E01 | Owner is building a plugin that will support a pilot like Skill Architect and RLP | Conversation, plugin-target correction | Owner answer, paraphrased |
| E02 | Immediate work is research; plugin implementation is downstream | Conversation, research-first correction | Owner correction |
| E03 | Primary outcome is HITL augmentation over automation, smaller commits/chunks, and de-risking toward production | Conversation, outcome correction | Owner answer, paraphrased |
| E04 | Creation and live implementation are later choices; research/package work does not authorize them | Conversation and Workflow Package Builder constraint | Owner direction plus inspected method |
| E05 | RLP and Skill Architect should be supported rather than duplicated | Conversation, plugin ideation | Owner direction, paraphrased |
| E06 | Initial request was to inspect Anthropic's article, associated links, and claims, then abstract to industry research and best practices | Conversation, initial research request | Owner answer, paraphrased |
| E07 | 60/30/10 means deterministic actions, orchestration, and AI judgment—not calendar phases | Conversation, explicit correction | Owner correction |
| E08 | Desired next state is to switch into this repository and run Workflow Package Builder against the research to determine skills, phases, and subskills | Conversation, latest correction | Owner correction |
| A01 | One research-backed practice/capability is the tentative repeating unit | This provisional record | AI assumption requiring owner review |
| A02 | Existing proposed skill names are alternatives, not approved design | Latest owner correction interpreted against `PLUGIN-DESIGN.md` | AI interpretation requiring owner review |
| Q01 | Acceptance cues for skill/phase decomposition are unknown | Gap identified during record construction | Open question |
| D01 | Local `../skill-architect` repository | Inspected README, principles, manifests, skills, tests | Inspected owner project |
| D02 | Local `../repo-learning-protocol` repository | Inspected README, protocol, manifests, skills, tests | Inspected owner project |
| D03 | Local/private ICM-converted Scuba skills | Inspected selected intake, roadmap, and ship-gate skills | Inspected private project material |
| D04 | Current `ai-native-sdlc` repository | Root documents and staged research outputs | Inspected repository |
| D05 | Local Workflow Package Builder skill | SKILL.md, interview prompt, ICM rules, package data guide, contract and HTML assets | Inspected private method |
| D06 | Atomic research library | `research/CONTEXT.md`, cards, map, and source register | Inspected repository |
| D07 | External implementation review | `EXTERNAL-IMPLEMENTATIONS.md` and cited public repositories | Inspected document and public sources |
| D08 | Research packet and measurement synthesis | `research/stages/03-synthesize/output/research-packet.md`, `RESEARCH.md` | Inspected repository |
| D09 | Proposed plugin boundary decision | `decisions/0001-thin-research-to-pilot-plugin.md` | Inspected proposed decision |

## 11. Latest owner correction

E09 supersedes the open-form assumptions in A01/A02 where they imply that no plugin or a saved prompt may be the final product:

- The product form is fixed: an installable plugin following the structural pattern established by local `skill-architect` and `repo-learning-protocol` repositories.
- Workflow Package Builder must not debate whether a plugin should exist.
- The research phase uses gathered and evaluated evidence to define the plugin's intent and specification.
- The package should determine the plugin's internal skills, phases, subskills, contracts, checks, and first implementation slice within that fixed boundary.
- Implementation remains unauthorized until the owner approves the resulting specification.

Evidence: E09, owner correction in conversation on 2026-09-07.

## 12. Review and next handoff

This record has not been reviewed as a whole. The latest owner correction is reflected: Workflow Package Builder, not the current design draft, should determine the eventual skills, phases, and subskills.

Next handoff:

1. Start a fresh session in the `ai-native-sdlc` repository.
2. Invoke `/workflow-package-builder` with this file as the interview record and the repository research as supporting material.
3. Require the builder to preserve A01, A02, Q01, and the public/private boundary as visible questions.
4. Review and correct the generated package before authorizing any plugin implementation.
