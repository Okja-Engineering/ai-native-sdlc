# Starter files — proposed evidence-led-delivery plugin

> **PROVISIONAL · UNREVIEWED · IMPLEMENTATION UNAUTHORIZED**
>
> Every file below preserves the provisional recommendation as corrected by E10. Implementation was subsequently authorized via ADR-0002, and the first slice now exists; that later authorization does not change this package's provisional provenance. Paths are relative to the plugin root.

## Proposed tree (does not exist)

````text
.devin-plugin/plugin.json
.claude-plugin/plugin.json
.codex-plugin/plugin.json
.cursor-plugin/plugin.json
AGENTS.md
CONTEXT.md
skills/evidence-to-intent/SKILL.md
skills/evidence-to-intent/references/evidence-contract.md
skills/evidence-to-intent/references/specification-contract.md
skills/evidence-to-intent/scripts/validate-evidence.sh
skills/evidence-to-intent/scripts/validate-specification.sh
skills/reviewable-delivery/SKILL.md                     # deferred; excluded from first slice
skills/reviewable-delivery/references/delivery-boundaries.md  # deferred; excluded from first slice
skills/reviewable-delivery/references/hitl-phase-contract.md  # deferred; excluded from first slice
skills/reviewable-delivery/references/reviewable-value-slice-contract.md  # deferred; excluded from first slice
tests/test_structure.sh
tests/test_evidence_to_intent.sh
tests/test_walk.sh
````

Later, only after first-slice acceptance: `skills/reviewable-delivery/` with its `SKILL.md` and named references. Saved prompts may live inside `SKILL.md` or references; they are not the final product.

## `AGENTS.md` — recommended; does not exist

````markdown
# Evidence-led delivery plugin router

This repository is an installable plugin. It turns evaluated research into owner-reviewed intent/specification and, in a later slice, supports sequential human-in-the-loop delivery boundaries. It never grants implementation, merge, deployment, RLP promotion, or skill-creation authority.

## Route by task

| Task | Read |
|---|---|
| Understand scope and ownership | `CONTEXT.md` |
| Validate, evaluate, filter, or synthesize research | `skills/evidence-to-intent/SKILL.md` |
| Change an evidence field or status rule | `skills/evidence-to-intent/references/evidence-contract.md` |
| Change specification output/review rules | `skills/evidence-to-intent/references/specification-contract.md` |
| Check per-platform plugin structure | `tests/test_structure.sh` |
| Run evidence-to-intent tests | `tests/test_evidence_to_intent.sh` |
| Walk the first slice | `tests/test_walk.sh` |

## Rules

- Load this router, the selected skill, and only references named by that skill.
- Preserve E*, D*, R-*, and A* provenance; owner facts outrank summaries.
- Mark missing required facts `NOT FOUND` and stop at the stated human boundary.
- Deterministic checks may reject malformed evidence but may not decide truth, applicability, intent, or risk.
- Do not create delivery, merge, deployment, RLP, or Skill Architect artifacts.
- A file's existence is not approval; require its explicit review fields.
````

## `CONTEXT.md` — recommended; does not exist

````markdown
# Plugin context

## Purpose

Provide an installable, evidence-led workflow: ingest explicitly supplied research, evaluate and filter it, synthesize a provisional intent/specification, and stop for a named human decision. A later skill may guide an accepted specification through sequential HITL delivery boundaries.

## Current implementation boundary

The first slice contains only `evidence-to-intent` with its two references and two scripts. `reviewable-delivery`, connectors, target-repository scaffolding, autonomous workflow graphs, merge, deployment, RLP promotion, and Skill Architect invocation are out of scope.

## Responsibility split

- Scripts: syntax, required fields, IDs, statuses, duplicate IDs, resolvable local paths, and required specification output fields.
- AI: compare evidence classes, explain contradictions/limitations/applicability, filter unsupported prescriptions, and draft synthesis.
- Human owner: select sources and accept, revise, or reject intent/specification.
- External systems: repository checks, merge/deploy policy, RLP learning decisions, and Skill Architect audits.

## Canonical paths

- Skill contract: `skills/evidence-to-intent/SKILL.md`
- Evidence rules: `skills/evidence-to-intent/references/evidence-contract.md`
- Specification rules: `skills/evidence-to-intent/references/specification-contract.md`
- Deterministic scripts: `skills/evidence-to-intent/scripts/validate-evidence.sh`, `skills/evidence-to-intent/scripts/validate-specification.sh`
- Per-run owner-supplied input: `{input-root}/interview-record.md`, `{input-root}/research/**/*.md`, and optional `{input-root}/workflow-specification.md`
- Per-run proposed output: `{output-root}/{run-id}/intent-specification.md`

`run-id` is an owner-supplied stable identifier or `YYYYMMDD-short-kebab-description`. Input and output roots are explicit invocation arguments; the plugin never assumes filesystem access.

## Review transition

The next boundary recognizes review only when the output records `review_status: reviewed`, reviewer, reviewed_at, decision, and rationale. Only `decision: accept` makes the specification eligible for the later delivery skill. It does not authorize implementation.
````

## `.devin-plugin/plugin.json` — recommended; does not exist

````json
{
  "name": "evidence-led-delivery",
  "version": "0.1.0",
  "description": "Agent skills for evidence-grounded intent and sequential human-in-the-loop delivery boundaries.",
  "license": "MIT",
  "skills": "skills"
}
````

## `.claude-plugin/plugin.json` — recommended; does not exist

````json
{
  "name": "evidence-led-delivery",
  "displayName": "Evidence-Led Delivery",
  "version": "0.1.0",
  "description": "Agent skills for evidence-grounded intent and sequential human-in-the-loop delivery boundaries.",
  "license": "MIT",
  "skills": "./skills/"
}
````

## `.codex-plugin/plugin.json` — recommended; does not exist

````json
{
  "name": "evidence-led-delivery",
  "version": "0.1.0",
  "description": "Agent skills for evidence-grounded intent and sequential human-in-the-loop delivery boundaries.",
  "license": "MIT",
  "skills": "./skills/"
}
````

## `.cursor-plugin/plugin.json` — recommended; does not exist

````json
{
  "name": "evidence-led-delivery",
  "version": "0.1.0",
  "description": "Agent skills for evidence-grounded intent and sequential human-in-the-loop delivery boundaries.",
  "license": "MIT",
  "skills": "./skills/"
}
````

## `skills/evidence-to-intent/SKILL.md` — recommended first-slice skill; does not exist

````markdown
---
name: evidence-to-intent
description: Evaluate, filter, and synthesize explicitly supplied research into a provenance-preserving provisional intent and workflow specification for human review. Use before delivery planning when intent must be grounded in mixed evidence.
license: MIT
compatibility: Bash 3.2+, git, jq, grep, awk, sed, find, and standard POSIX utilities. Repository scripts use Bash; Go is reserved for logic that cannot remain safe and readable in Bash; Python scripts are prohibited.
metadata:
  version: "0.1.0"
---

# evidence-to-intent

Evaluate, filter, and synthesize explicitly supplied research into a provenance-preserving provisional intent and workflow specification for human review.

## When to use

Use this skill when:

- The owner has supplied an explicitly accepted research workflow specification, selected research cards, and acceptance cues.
- Intent and specification must be derived from evidence before any delivery planning.
- The boundary, applicability, or contradiction of the source material is uncertain.

Do not use this skill to authorize implementation, merge, deployment, or downstream skill creation.

## Inputs

- Explicit `run-id`, `input-root`, and `output-root`.
- Owner-supplied interview/correction record with stable E/A/Q IDs.
- Selected research cards with stable R-* IDs and review/applicability fields.
- Optional inspected-document register and working specification, labeled D*.
- Owner acceptance cues. If absent, produce a gap report and stop.

Read `references/evidence-contract.md` and `references/specification-contract.md`.

## Process

1. **Intake.** Run `scripts/validate-evidence.sh <input-root>`. Record exact files and revisions where available. Never claim unavailable URLs or paths were pulled.
2. **Evaluate and filter.** Separate owner evidence, inspected documents, research, and assumptions. Compare source class, limitations, applicability, contradictions, and owner-evidence requirements. Retain disagreement; exclude unsupported prescriptions.
3. **Synthesize.** Draft `{output-root}/{run-id}/intent-specification.md` using the specification contract. Derive responsibilities before names. Separate deterministic action, orchestration, AI judgment, retained human decision, and external-system handoff.
4. **Human decision.** Stop with `review_status: pending`. The owner records `accept | revise | reject`, reviewer, date, and rationale. Do not self-approve or invoke a later skill.

## Deterministic actions (60%)

### Evidence validation

```bash
scripts/validate-evidence.sh "$input_root"
```

- Validate required files/fields, unique IDs, declared status values, and local path resolution.
- Fail closed on malformed or conflicting identity/status data.

### Specification output validation

```bash
scripts/validate-specification.sh "$output_root/$run_id/intent-specification.md" --output-root "$output_root"
```

- Confirm the output file exists under the explicit output root, not a source location.
- Confirm required frontmatter fields: `run_id`, `status`, `implementation_authorized: false`, `review_status: pending`, `reviewer`, `reviewed_at`, `decision`, `source_revision`.

### Stop conditions

- Validation failure stops synthesis.
- Missing `run-id`, `input-root`, `output-root`, or owner acceptance cues stops after a gap report.
- Conflicting or inapplicable evidence is recorded, not averaged.

## Orchestration (30%)

- Separate current evidence from proposed expected output and research recommendations.
- Order the workflow: validate input, evaluate evidence, synthesize output, validate output, stop for human decision.
- Route `accept` only to a deferred `reviewable-delivery` skill; do not invoke it automatically.
- Route `revise` and `reject` back to the owner with a focused `NOT FOUND` or contradiction record.

## AI judgment (10%)

- Assess relevance and applicability without promoting opinion into fact.
- Explain contradictions and synthesize bounded recommendations.
- Ask one focused question when a missing owner fact blocks useful synthesis.
- Compare candidate skill names only after responsibilities are derived.

## Outputs

- `{output-root}/{run-id}/intent-specification.md` with required frontmatter and sections.
- A gap report when required inputs or acceptance cues are missing.
- A contradiction/applicability note when evidence is credible but inapplicable or contradictory.

## Human check

The owner verifies fidelity, applicability, exclusions, responsibility boundaries, and acceptance cues. On failure choose `revise` or `reject`; on pass choose `accept`. Acceptance permits later workflow design only and leaves `implementation_authorized: false`.

## Example

### Normal run

```bash
run_id="20260907-pilot-sdlc-intent"
input_root="/tmp/evidence-input"
output_root="/tmp/evidence-output"
scripts/validate-evidence.sh "$input_root"
# AI evaluates and filters supplied evidence
# AI drafts "$output_root/$run_id/intent-specification.md"
scripts/validate-specification.sh "$output_root/$run_id/intent-specification.md" --output-root "$output_root"
# Owner reviews and records accept | revise | reject
```

### Exception: inapplicable/contradictory research

A selected research card supports full autonomous lifecycle execution, while another selected card supports sequential HITL augmentation. The skill preserves both claims, records that each has a different applicability boundary, and marks the contradiction in the output. It does not average the sources into a single autonomy level, does not assume the owner wants either boundary, and stops with `decision:` empty and `review_status: pending`.

## Constraints

- No implementation, target-repository mutation, merge/deploy, connector assumption, RLP promotion, or Skill Architect invocation.
- No universal phase count or one-skill-per-phase mapping.
- Passing validation proves shape, not truth or owner approval.
- Do not fetch networks or claim access to paths the owner did not supply.
````

## `skills/evidence-to-intent/references/evidence-contract.md` — recommended; does not exist

````markdown
# Evidence contract

## Required identity

Every item has `id`, `kind`, `title`, `source_locator`, and `review_status`.

- `E*`: owner answer/correction; include paraphrase status and locator.
- `D*`: inspected document; include exact relative path or public URL and inspection date.
- `R-*`: evaluated research card; include claim, evidence class, limitations, applicability, contradiction, package use, owner-evidence requirement, and review status.
- `A*`: assumption; include why needed and how the owner resolves it.
- `Q*`: open question; include blocked decision and accountable owner.

## Allowed statuses

`pending-owner-review | reviewed | superseded | rejected`. A deterministic validator checks vocabulary and uniqueness only.

## Filtering rules

1. Owner corrections outrank summaries about owner intent.
2. Public implementation structure is precedent, not outcome evidence.
3. Research supports a recommendation only under its recorded applicability.
4. Contradictions remain paired; never average them into certainty.
5. Missing owner facts are `NOT FOUND — <fact>; ask: <focused question>`.
6. No evidence item can record its own human acceptance.

## Failure behavior

Duplicate IDs, absent required identity, invalid status, or unresolved declared local paths fail validation. Missing applicability or owner acceptance does not fabricate a pass: retain the item but block the dependent recommendation.
````

## `skills/evidence-to-intent/references/specification-contract.md` — recommended; does not exist

````markdown
# Intent/specification output contract

Write one file at `{output-root}/{run-id}/intent-specification.md`.

## Required frontmatter

```yaml
run_id:
status: provisional
implementation_authorized: false
review_status: pending
reviewer:
reviewed_at:
decision:
source_revision:
```

## Required sections

1. Purpose and explicit boundary
2. Owner facts and unresolved questions
3. Evidence inventory by E/D/R/A class
4. Contradictions, exclusions, and applicability
5. Independently derived responsibility map
6. Proposed intent and acceptance evidence
7. Deterministic/orchestration/AI/human split
8. External handoffs and non-responsibilities
9. Candidate-name comparison (last)
10. Assumptions and `NOT FOUND` items
11. Owner decision block

Each recommendation cites its local owner basis and research basis separately. The output may recommend later delivery boundaries but may not contain implementation steps against a target repository.

## Human check

The owner verifies fidelity, applicability, exclusions, responsibility boundaries, and acceptance cues. On failure choose `revise` or `reject`; on pass choose `accept`. Acceptance permits later workflow design only and leaves `implementation_authorized: false`.
````

## `skills/evidence-to-intent/scripts/validate-evidence.sh` — implemented first-slice contract

````text
#!/usr/bin/env bash
# Bash shebang and executable bit are required.
# CLI: validate-evidence.sh INPUT_ROOT
# Exit 0: discovered Markdown evidence records have unique valid E/D/R/A/Q IDs, required identity fields, allowed review_status values, and resolvable declared local paths contained by INPUT_ROOT.
# Exit 2: invalid input root, no records, schema/status/identity/path failure, duplicate ID, unresolved path, or path traversal; print stable `path:field:message` lines.
# Discovery is deterministic: find Markdown files below INPUT_ROOT, sort them, and inspect YAML-style frontmatter with Bash plus standard awk/grep/find utilities.
# Must not: fetch networks, assess truth/applicability, edit inputs, create output files, or record approval.
# Repository scripts use Bash. Go is reserved for logic that cannot remain safe and readable in Bash. Python scripts are prohibited.
````

## `skills/evidence-to-intent/scripts/validate-specification.sh` — implemented first-slice contract

````text
#!/usr/bin/env bash
# Bash shebang and executable bit are required.
# CLI: validate-specification.sh SPECIFICATION_PATH --output-root OUTPUT_ROOT
# Exit 0: the provisional specification has every required frontmatter field and non-empty required section, valid pending/reviewed state, and the exact path OUTPUT_ROOT/{run_id}/intent-specification.md.
# Exit 2: missing/empty required data, invalid review state, path mismatch, or missing/empty section; print stable `path:field:message` lines.
# Required frontmatter: run_id, status, implementation_authorized, review_status, reviewer, reviewed_at, decision, rationale, source_revision. Reviewed records require reviewer, reviewed_at, decision, and rationale.
# Must not: modify the file, set any approval value, or invoke the deferred delivery skill.
# Repository scripts use Bash. Go is reserved for logic that cannot remain safe and readable in Bash. Python scripts are prohibited.
````

## `skills/reviewable-delivery/SKILL.md` — recommended deferred skill; does not exist

````markdown
---
name: reviewable-delivery
description: Guide one owner-accepted specification through sequential human-in-the-loop delivery boundaries, ending at a reviewable value-slice handoff. Use only after evidence-to-intent has produced an accepted specification.
license: MIT
compatibility: Bash 3.2+, git, jq, grep, awk, sed, find, and standard POSIX utilities. Repository scripts use Bash; Go is reserved for logic that cannot remain safe and readable in Bash; Python scripts are prohibited.
metadata:
  version: "0.1.0"
---

# reviewable-delivery

Guide one owner-accepted specification through sequential human-in-the-loop delivery boundaries, ending at a reviewable value-slice handoff.

## When to use

Use this skill when:

- `evidence-to-intent` has produced an accepted `intent-specification.md`.
- The owner wants to convert that specification into one reviewable value slice.
- The terminal decision is a recorded human `merge-ready | revise | split | reject` against a pinned revision.

Do not use this skill without an accepted upstream specification, and do not merge, deploy, promote RLP learnings, or create Skill Architect artifacts.

## Inputs

- Explicit `run-id`, `input-root` containing the accepted `intent-specification.md`, and `output-root`.
- Repository rules, build/test/lint commands, and protected paths supplied by the owner.
- Current repository revision.

Read `references/delivery-boundaries.md`, `references/hitl-phase-contract.md`, and `references/reviewable-value-slice-contract.md`.

## Process

1. **Frame intent.** Confirm the accepted specification and record any corrections.
2. **Select slice.** Propose candidate value slices; the accountable engineer selects one.
3. **Define proof.** Map acceptance conditions to deterministic checks or explicit retained manual checks.
4. **Plan and implement.** Draft a plan; implement only after human approval; preserve raw evidence.
5. **Verify.** Run required checks and compare intent, slice, plan, diff, and evidence.
6. **Record merge readiness.** Stop with a human `merge-ready | revise | split | reject` decision.

## Deterministic actions (60%)

- Validate the accepted specification frontmatter and `decision: accept` marker.
- Assign or confirm a stable slice ID.
- Confirm build, test, lint, and security command presence and non-zero failure behavior.
- Record exact revision, command, exit status, timestamp, and evidence location.
- Verify the `verified_revision` has not changed before recording a terminal decision.

## Orchestration (30%)

- Route backward transitions to the correct phase when a correction, missing proof, or rejected plan occurs.
- Re-run affected evidence after every repair.
- Pin the final decision packet to the last verified revision.
- Keep `merge-ready | revise | split | reject` as terminal human decisions.

## AI judgment (10%)

- Propose candidate decompositions and compare value, review burden, and risk.
- Identify intent mismatch, hidden coupling, architecture drift, and residual risk.
- Explain the consequences of each terminal decision; do not select or record it.

## Outputs

- `changes/{slice-id}/01-intent.md`
- `changes/{slice-id}/02-slice.md`
- `changes/{slice-id}/03-evidence-plan.md`
- `changes/{slice-id}/04-implementation-plan.md`
- `changes/{slice-id}/05-evidence-receipt.md`
- `changes/{slice-id}/06-merge-decision.md`

The artifact names are logical jobs; one smaller document may preserve the same decisions if the owner accepts.

## Human check

Every phase ends with a named human decision:

| Phase | Human decision |
|---|---|
| Frame intent | Request owner accepts or corrects the problem and outcome. |
| Select slice | Accountable engineer selects, revises, splits, or rejects the candidate. |
| Define proof | Accountable engineer accepts the evidence plan. |
| Plan and implement | Accountable engineer approves the plan or accepts an inline-plan exception. |
| Verify | Independent reviewer accepts the evidence receipt. |
| Record | Merge authority records `merge-ready | revise | split | reject`. |

## Example

```bash
run_id="20260907-pilot-sdlc-slice"
input_root="/tmp/evidence-output/20260907-pilot-sdlc-intent"
output_root="/tmp/delivery-output"
# confirm accepted specification
# AI drafts slice and evidence plan; human selects/accepts
# AI drafts implementation plan; human approves
# AI runs required checks and drafts evidence receipt
# independent reviewer and merge authority record decisions
```

## Constraints

- No autonomous merge, deployment, RLP promotion, or Skill Architect invocation.
- No one-skill-per-phase mapping; these are logical jobs inside one delivery skill.
- A passing deterministic check proves execution, not semantic intent or residual-risk acceptance.
- External systems own merge, deploy, RLP, and skill-audit responsibilities.
````

## `skills/reviewable-delivery/references/delivery-boundaries.md` — recommended deferred reference; does not exist

````markdown
# Delivery boundaries

This skill guides a change from accepted intent to a recorded terminal decision. It does not own the repository, merge, deployment, or production.

## Responsibility split

- Plugin: asks the human, records the answer, validates required fields, and preserves evidence.
- Human owner: owns intent, slice selection, evidence plan, plan approval, review, and merge-readiness.
- Repository toolchain: runs deterministic commands and records raw, revision-linked results.
- Merge authority: records the terminal `merge-ready | revise | split | reject` decision.

## Stop conditions

- Missing `decision: accept` in the accepted specification stops the skill.
- Missing repository rules or required commands stops after `NOT FOUND`.
- Any revision change after a terminal decision reopens the review.
````

## `skills/reviewable-delivery/references/hitl-phase-contract.md` — recommended deferred reference; does not exist

````markdown
# HITL phase contract

A phase is a logical job with one human decision. It is not a separate skill by default.

## Required fields

```yaml
phase:
input:
output:
required_decision:
reviewer:
reviewed_at:
decision:
rationale:
```

## Transition rules

- `accept` permits the next phase.
- `revise` returns to the same phase.
- `split` returns to slice selection.
- `reject` closes the slice with rationale.
- A changed `verified_revision` after `review-pending` reopens review.
````

## `skills/reviewable-delivery/references/reviewable-value-slice-contract.md` — recommended deferred reference; does not exist

````markdown
# Reviewable value slice contract

A valid slice is the smallest independently valuable change a human can understand, verify, approve, and safely hand off without depending on unmerged work.

## Required fields

- `slice_id`: stable identifier.
- `value`: user, operator, risk, or learning value.
- `boundaries`: affected files, systems, and non-goals.
- `acceptance_evidence`: deterministic checks or explicit manual checks.
- `independent_merge_condition`: can be merged while leaving the repository working.
- `rollback_or_containment`: proportionate to risk.

## Selection rule

The accountable engineer selects, revises, splits, or rejects the candidate. AI may propose, compare, and explain; it may not select.
````

## `tests/test_structure.sh` — recommended; does not exist

````text
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Plugin manifests are valid JSON and follow per-platform conventions.
check_manifest() {
  local path="$1" expected_skills="$2"
  jq -e --arg skills "$expected_skills" '
    .name == "evidence-led-delivery" and
    .version == "0.1.0" and
    .license == "MIT" and
    .skills == $skills
  ' "$path" >/dev/null
}
check_manifest .devin-plugin/plugin.json skills
check_manifest .claude-plugin/plugin.json ./skills/
check_manifest .codex-plugin/plugin.json ./skills/
check_manifest .cursor-plugin/plugin.json ./skills/

# In the first slice, validate only the evidence-to-intent skill frontmatter and required sections.
skill=skills/evidence-to-intent/SKILL.md
test -f "$skill"
grep -q '^name: evidence-to-intent$' "$skill"
for field in description license compatibility metadata; do
  grep -q "^$field:" "$skill"
done
grep -q '^  version: "0.1.0"$' "$skill"
for heading in 'When to use' Inputs Process 'Deterministic actions' Orchestration 'AI judgment' Outputs 'Human check' Example Constraints; do
  grep -q "^## $heading" "$skill"
done

# reviewable-delivery is deferred and excluded from the first slice.
test ! -d skills/reviewable-delivery

# Bash validators exist, are executable, and parse successfully.
test -x skills/evidence-to-intent/scripts/validate-evidence.sh
test -x skills/evidence-to-intent/scripts/validate-specification.sh
bash -n skills/evidence-to-intent/scripts/validate-evidence.sh
bash -n skills/evidence-to-intent/scripts/validate-specification.sh

# No nested plugin manifests inside skills.
test ! -e skills/evidence-to-intent/.devin-plugin
````

## `tests/test_evidence_to_intent.sh` — recommended; does not exist

````text
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Fixture A: valid mixed evidence.
# - owner record with E*, D*, R-* evidence
# - selected research cards with applicability and limitations
# - explicit acceptance cues and run-id
# Expected: validate-evidence.sh exits 0; output specification has all required sections, distinct E/D/R/A namespaces, no inherited names, no downstream artifacts.

# Fixture B: missing/conflicting.
# - selected cards but no owner acceptance cues
# - duplicate R-* IDs and a status value outside the allowed set
# Expected: validate-evidence.sh exits 2 with one stable `path:field:message` per failure; skill stops after a gap report with NOT FOUND for acceptance cues and does not create a specification.

# Fixture C: exception — credible but inapplicable/contradictory research.
# - one public implementation claims full autonomous lifecycle execution is correct
# - another selected research card supports sequential HITL augmentation for this plugin
# - neither applies to the owner boundary without explicit owner choice
# Expected: output preserves both claims, records each applicability boundary, marks the contradiction visible, does not average autonomy levels, leaves decision empty, and does not create delivery/RLP/Skill-Architect/merge/deploy artifacts.
````

## `tests/test_walk.sh` — recommended; does not exist

````text
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# From AGENTS.md, reach the first-slice skill and no more than two named references.
# Confirm exact owner-supplied inputs, output path, review fields, and accept/revise/reject transition.
# Confirm the route to tests/test_evidence_to_intent.sh is documented.
# Assert acceptance never changes implementation_authorized: false or automatically invokes the deferred delivery skill.
````

## First implementation slice recommendation

The provisional recommendation was to implement only the four manifest files, root `AGENTS.md`/`CONTEXT.md`, `skills/evidence-to-intent/SKILL.md`, its two references, `validate-evidence.sh`, `validate-specification.sh`, and the three tests above. ADR-0002 subsequently authorized that first slice, which is now implemented. `skills/reviewable-delivery/` remains deferred.
