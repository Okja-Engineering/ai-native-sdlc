# External implementation review

Reviewed 2026-09-07:

- `imsungbin/ai-native-sdlc-playbook` — https://github.com/imsungbin/ai-native-sdlc-playbook
- `bashebr/ai-native-sdlc` — https://github.com/bashebr/ai-native-sdlc

These repositories are implementation precedents, not independent evidence that the underlying operating model improves delivery outcomes.

## Summary

| Repository | Primary intent | Strongest contribution | Main mismatch with this research |
|---|---|---|---|
| `imsungbin/ai-native-sdlc-playbook` | Faithful, runnable companion to Anthropic's article | Exact article-to-file traceability, deterministic validation, explicit separation of verbatim, completed, install, and repository-owned material | Optimizes fidelity to the vendor article rather than testing augmentation outcomes or owner-specific workflow fit |
| `bashebr/ai-native-sdlc` | Reusable full-lifecycle skill and plugin | Rich assets, staged adoption graph, machine-readable workflow graph, gate ledger, eval and scaffold tooling | Broad autonomous SDLC and agent-org scope overlaps orchestration systems and conflicts with the proposed thin HITL research-to-pilot boundary |

## Useful patterns to adopt

### 1. Source-to-artifact traceability

The `imsungbin` repository's `docs/article-map.md` records which article sentence justifies each file. Adapt this into a research-to-plugin map:

```markdown
| Plugin artifact | Origin | Research card | Adaptation decision | Verification |
|---|---|---|---|---|
| research-audit validator | authored | R-VERIFY-001 | deterministic schema check | fixture test |
| reviewable-value-slice card | adapted | R-FLOW-001 | owner facts remain required | card audit |
```

Use provenance classes that fit this project:

```text
R = evaluated research content
A = adaptation from an external implementation
P = plugin/runtime code authored here
T = test or fixture
I = installation/manifest layer
```

Do not use a verbatim lock for evolving research synthesis. Preserve exact quotations and source snapshots only where licensing and update policy justify it.

### 2. Honest completion boundaries

The `imsungbin` repository explicitly lists product/admin capabilities it cannot implement. Preserve this practice. The future plugin must not fake:

- owner workflow facts;
- package-builder outputs;
- connectors or filesystem access;
- managed policy enforcement;
- production identity;
- deployment authorization;
- RLP promotion decisions;
- or Skill Architect findings.

### 3. Deterministic repository validation

Both projects validate manifests, assets, scripts, and scaffolding. Adopt:

- manifest name/version/path checks;
- skill name-to-directory checks;
- referenced-file resolution;
- script syntax and executable-bit checks;
- idempotent scaffold tests;
- valid, missing-evidence, and conflicting-evidence fixtures;
- and a walk test proving no downstream-owned artifact is created.

### 4. Separate adoption graph from runtime flow

The `bashebr` repository correctly distinguishes:

- **runtime order:** how one change moves;
- **adoption order:** which capabilities must exist before another is safe.

Apply that distinction without inheriting its full autonomous loop.

```yaml
adoption:
  - id: research-cards
    requires: []
  - id: research-audit
    requires: [research-cards]
  - id: package-applicability
    requires: [research-audit, owner-reviewed-package]
  - id: pilot-readiness
    requires: [package-applicability, completed-sample]
  - id: rlp-handoff
    requires: [completed-pilot, human-confirmed-correction]
```

The runtime pilot remains sequential and human-gated. The adoption graph only describes capability prerequisites.

### 5. Assets are payload; references are instructions

The `bashebr` layout distinguishes templates copied into a target project from references read by the skill. Preserve this boundary:

```text
skills/pilot-readiness/references/   # criteria the skill reads
skills/pilot-readiness/assets/       # blank templates a user explicitly chooses to copy
research/                            # reviewed evidence bundled with the plugin
```

Never modify a bundled template in place during a run. Never present a blank template as an existing owner artifact.

### 6. One source of truth per artifact

Adopt the explicit source-of-truth decision from `bashebr`:

- the research factory owns full research cards;
- the plugin bundles a reviewed release snapshot;
- the owner's workflow package owns owner facts and proposed workspace;
- the pilot workspace owns run evidence;
- RLP owns learning candidates and promotion decisions;
- Skill Architect owns skill audit reports.

Every copy records its origin and version. No two locations are edited as peers.

## Patterns to adapt cautiously

### Artifact chain as audit trail

Git history is useful provenance but is not sufficient alone. A complete decision record also needs:

- stable artifact identity;
- review status;
- reviewer identity;
- review date;
- evidence revision;
- supersession;
- and the exact decision made.

### Hook-based gates

Hooks are one enforcement surface, not universal policy. Their strength depends on installation, precedence, bypass paths, sandboxing, and protected configuration. The plugin should describe required capabilities instead of promising that a hook makes a rule impossible to violate.

### Gate ledger

A hash-chained ledger may detect local record modification, but it does not by itself prove approver identity or prevent an authorized process from writing false data. Treat it as a candidate control only after defining the threat model, key management, and authoritative identity source.

### Workflow graph

A graph is helpful for explicit prerequisites and human gates. Avoid turning it into a hidden automation engine. In ICM, the readable folder and artifact contracts remain authoritative; a graph should be generated from or validated against those contracts rather than maintained as a second truth.

## Patterns to reject for the initial plugin

### Full Plan → Design → Build → Test → Deploy → Maintain ownership

Both repositories inherit the article's lifecycle wholesale. That is not justified for this plugin because Workflow Package Builder first selects the smallest structure that fits the owner's actual repeat unit and checkpoints. A saved prompt may be enough.

### Automatic second-mistake promotion

Both article-derived implementations encode variants of “same mistake twice → CLAUDE.md or skill.” This bypasses RLP's stronger rule:

```text
check > regression test > scoped context > skill > discard
```

Recurrence is a signal for triage, not permission to choose the artifact or promote it automatically.

### Autonomous agent organization

The `bashebr` agent-org model is deliberately aimed at less human steering. It conflicts with the proposed pilot's primary outcome: sequential human augmentation, smaller review decisions, and comprehension. Scuba Stack already owns broader orchestration where needed.

### Universal Markdown artifacts

`intent.md`, `spec.md`, and `plan.md` can be useful, but Workflow Package Builder correctly chooses among saved prompt, pipeline, record library, knowledge bundle, umbrella, context map, and system map. The plugin must not force three documents or six stages onto every workflow.

### Control-band remediation as a default

Statistical bands require distribution, independence, seasonality, and false-alarm analysis. They are not a general-purpose autonomy ladder. Initial pilots should use explicit outcome and risk thresholds derived from the owner's workflow.

## Consequences for plugin design

1. Add a `research-map.md` equivalent to the article map before implementation.
2. Maintain separate adoption and runtime views, with one canonical artifact source.
3. Scaffold only reviewed research and skill assets, never owner workflow state.
4. Test that downstream-owned files are not created.
5. Keep v0 focused on research audit; do not ship a full lifecycle skill.
6. Route repeated corrections through RLP instead of direct context mutation.
7. Route only RLP-approved skill candidates to Skill Architect.
8. Treat human approval as a recorded state transition, not a file's existence or an environment variable.

## Evidence status

The repository structures and documented behaviors above were inspected from their public README, skill/reference files, manifest, and article map. Their claimed delivery benefits, safety, and organizational outcomes were not independently verified and should not be entered as empirical research cards without additional evidence.
