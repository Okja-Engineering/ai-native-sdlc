# Preparing AI-native SDLC research for Workflow Package Builder

## Boundary

Workflow Package Builder turns an owner's reviewed account into three deliverables. This research repository must not pre-compose those deliverables or substitute industry claims for owner evidence.

The research should enter the builder as a stable **recommendation evidence library** after the builder has established the current workflow from an `interview-record.md`.

```text
Owner account                         Industry research
interview-record.md                   evaluated research cards
        │                                      │
        ├── establishes current facts          ├── supports candidate practices
        ├── retained judgment                  ├── names applicability conditions
        ├── baseline and value                  ├── offers tests and controls
        └── actual constraints                  └── never claims owner state
                 \                              /
                  workflow-package-builder
                            │
             audit → recommendation → first test
```

## Why the current research packet is not enough

A prose synthesis is useful for humans but expensive and unsafe for a package-building agent. It mixes claims, prescriptions, limitations, sources, and implications. The builder needs atomic, addressable records so it can cite a recommendation without accidentally turning it into a current workflow fact.

The canonical research format should therefore be **one evaluated claim or practice per research card**, conforming to `_config/research-card-schema.md`.

## Required research collections

```text
research/
├── CONTEXT.md
├── claims/
│   ├── verification-capacity.md
│   ├── small-batch-delivery.md
│   └── bounded-delegation.md
├── patterns/
│   ├── reviewable-value-slice.md
│   ├── sequential-human-checks.md
│   └── deterministic-evidence-gates.md
├── measures/
│   ├── production-qualified-slice.md
│   ├── review-and-rework-cost.md
│   └── comprehension-check.md
├── controls/
│   ├── least-agency.md
│   ├── evidence-receipt.md
│   └── promotion-boundary.md
└── sources/
    └── source-register.md
```

These are research-library forms, not the folder structure recommended to every pilot team.

## Mapping research to package data

| Package section | Owner evidence required | Research may contribute | Research must not do |
|---|---|---|---|
| Overview | Trigger, actual work, deliverable, recipient | Candidate outcome language | Invent the workflow sentence or strongest number |
| Current steps | Actors, tools, inputs, checks, sequence | Questions and known failure patterns | Add recommended stages as current work |
| Inputs/outputs | Actual formats, access, owners, recipients | Capability-neutral access patterns | Claim a connector or file exists |
| Value | Baseline, scope, units, provenance | Measurement formulas and cost categories | Supply decorative ROI or savings |
| Judgment | Owner's retained decision, cues, authority | Examples of decisions usually retained | Delegate or invent thresholds |
| Barriers | Actual constraints and decisions | Evidence-backed risk patterns | Turn general risk into local fact |
| Workspace | Repeat unit and real checkpoints | ICM form-selection patterns | Force a pipeline or stage count |
| First build | Real completed sample and expected result | Test design patterns | Claim a proposed test passed |
| Questions | Actual unresolved facts | Applicability questions | Answer for the owner |
| Evidence | Interview IDs and inspected files | External source IDs for recommendations | Mix owner evidence and research provenance |

## Stable evidence IDs

Use separate namespaces:

```text
E01...  owner interview evidence
D01...  inspected owner documents
R-...   evaluated research cards
S...    external sources inside a research card
A...    explicit design assumptions
```

This prevents a research paper from being cited as evidence that a team currently follows a step.

## Recommendation provenance

Every proposed package action should carry both local and external support when available:

```yaml
recommendation: Require an independently checkable acceptance condition before implementation.
local_basis:
  - E14  # owner reports repeated rework from misunderstood requests
research_basis:
  - R-INTENT-002
applicability:
  - change has observable behavior
  - expected result can be stated before implementation
dependency:
  - owner confirms who accepts the result
status: proposed
```

Without `local_basis`, the item may remain an industry-informed option, but it should not be presented as the answer to an evidenced owner bottleneck.

## Research card to package-builder adapter

Implemented (S9): `skills/select-improvement/scripts/select-eligible.sh`
evaluates `selection-card/0.1.0` blocks (`cards/`) against an
`owner-facts/0.1.0` file and emits a deterministic report — eligible and
ready, applicable-but-blocked, inapplicable, unknown, conflicted, and the
missing-fact gap list — without writing package output. Matching is exact
fact-ID/value equality; `established`/`unknown`/`conflicted` are separate
states and a twice-declared fact fails validation. See
`references/selection-contract.md` for the formats.

This selection is deterministic. AI judgment is reserved for explaining relevance and surfacing conflicts; the owner still accepts or rejects the recommendation.

## Minimum card set before the builder pilot

Do not encode the entire research corpus. Start with five cards:

1. Reviewable value slice.
2. Verification before expanded autonomy.
3. Deterministic checks before model judgment.
4. Human decision at consequence-bearing boundaries.
5. Production-qualified outcome measurement.

Each needs a normal case, missing/conflicting-evidence case, and known exception. This matches the builder's first-test requirements without creating package output.

## Readiness gate

Research is package-ready when:

- every material recommendation links to an evaluated card;
- each card separates evidence, practice, applicability, and owner facts required;
- source classes and independence are visible;
- contradictions remain visible;
- measures include review, rework, setup, and matched-period requirements;
- proposed tests are labeled unrun;
- no research artifact claims to describe a pilot team's current workflow;
- a cold agent can select a card using the research router and at most two more reads.
