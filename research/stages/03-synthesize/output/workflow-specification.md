---
type: research-derived-workflow-specification
status: uncommitted-working-insight
date: 2026-09-07
boundary: intent-to-merge-ready
repeat_unit: reviewable-value-slice
basis:
  - research/claims/verification-capacity.md
  - research/patterns/reviewable-value-slice.md
  - research/patterns/sequential-human-checks.md
  - research/controls/deterministic-before-model-judgment.md
  - research/measures/production-qualified-value-slice.md
implementation_authorized: false
owner_review: direction-confirmed-not-durable
---

# Workflow specification: sequential HITL intent to merge-ready

## 1. Purpose

Turn a raw software change request into the smallest coherent, independently verifiable, human-approved, merge-ready chunk of value.

The workflow augments human decisions with AI-prepared alternatives and deterministic evidence. It does not optimize autonomous completion, prescribe a particular coding agent, or authorize merge.

## 2. Boundary

### Begins

A person supplies a software change request, problem, defect, or desired outcome.

### Ends

A named human records one of four merge-readiness decisions against the current revision:

```text
merge-ready | revise | split | reject
```

Actual merge, deployment, production observation, RLP promotion, and skill creation are outside this workflow.

### Post-boundary interfaces

- A human-confirmed correction may be handed to RLP capture.
- An RLP decision may later identify a candidate skill.
- Skill Architect may audit that skill.
- None of these transitions is automatic or evidence that this workflow succeeded.

## 3. Repeating unit

The working unit is a **reviewable value slice**: the smallest independently valuable change a human can understand, verify, approve, and safely merge without depending on unmerged work.

A valid slice is:

- valuable to a user, operator, risk posture, or validated learning goal;
- bounded by explicit intent, non-goals, and affected system boundaries;
- reviewable as one coherent human decision;
- verifiable against observable acceptance evidence;
- independently mergeable while leaving the repository working;
- reversible or containable in proportion to its risk;
- traceable from request through evidence and final revision.

This is a research-backed pilot hypothesis, not a universal size rule.

## 4. Actors and authority

| Actor | Responsibilities | May not do |
|---|---|---|
| Request owner | State the problem, desired outcome, constraints, and non-goals; accept or correct intent | Delegate product intent implicitly to an agent |
| Accountable engineer | Select the slice and implementation direction; own repository and architecture judgment | Treat an AI plan or passing test as self-approval |
| Authoring agent or human | Explore, plan, implement, run checks, and report evidence inside granted authority | Approve its own merge readiness or weaken required evidence silently |
| Deterministic toolchain | Compile, type-check, lint, test, scan, validate policy, and record reproducible results | Decide semantic intent, architecture, or acceptable residual risk |
| Independent reviewer | Compare intent, slice, plan, diff, and evidence; identify residual risk | Infer evidence that was not executed |
| Merge authority | Record merge-ready, revise, split, or reject against an exact revision | Approve a different or later revision without reopening review |

One person may hold several human roles on a small team, but each decision remains explicit.

## 5. Stable and per-slice artifacts

### Stable inputs

- repository contribution and architecture rules;
- exact build, test, lint, and security commands;
- protected paths and policy checks;
- risk classification rules;
- evidence and review schemas;
- ownership and merge policy.

### Per-slice artifacts

```text
changes/{slice-id}/
├── 01-intent.md
├── 02-slice.md
├── 03-evidence-plan.md
├── 04-implementation-plan.md
├── 05-evidence-receipt.md
└── 06-merge-decision.md
```

The artifact names express logical jobs, not a requirement that every future implementation use six separate files. A later package may combine them when one smaller document preserves the same decisions and evidence.

### Slice ID

```text
{YYYYMMDD}-{short-kebab-description}
```

A repository may substitute its existing issue/change identifier if it is stable and unique.

## 6. State model

```text
request
  ↓
intent-pending
  ↓ human accepts intent
slice-pending
  ↓ human selects slice
proof-pending
  ↓ accountable engineer accepts evidence plan
plan-pending
  ↓ accountable engineer accepts plan or approved inline-plan exception
implementation-active
  ↓ deterministic checks complete
review-pending
  ↓ merge authority decision
merge-ready | revise | split | reject
```

Allowed backward transitions:

- intent correction returns to `intent-pending`;
- invalid or oversized slice returns to `slice-pending`;
- missing proof returns to `proof-pending`;
- rejected or materially incomplete plan returns to `plan-pending`;
- implementation deviation returns to plan or slice selection according to scope;
- any revision change after review reopens `review-pending`.

## 7. Phase contracts

## Phase A: Frame intent

### Inputs

- Raw request in the owner's words.
- Supplied constraints, examples, and source locators.
- Existing repository rules relevant to the request.

### Deterministic actions

1. Assign a stable slice ID.
2. Record source, request owner, date, desired outcome, affected user/operator, constraints, non-goals, open questions, and current status.
3. Mark absent required facts `NOT FOUND`; do not infer them from industry research.
4. Store the draft with `review_status: pending`.

### Orchestration

1. Separate current problem from proposed solution.
2. Surface contradictions and questions that block value or safety.
3. Present the smallest set of material interpretations together.
4. Route non-blocking unknowns forward visibly.

### AI judgment

- Draft a faithful intent statement.
- Identify ambiguity and materially different interpretations.
- Suggest questions; do not answer them for the owner.

### Output

`changes/{slice-id}/01-intent.md`

Required review fields:

```yaml
review_status: pending | reviewed
reviewer:
reviewed_at:
decision: accept | correct | reject
```

### Human check

The request owner confirms that the artifact describes the intended problem and outcome, not merely a plausible solution. Failure returns for correction. Only `decision: accept` permits slice selection.

## Phase B: Select the value slice

### Inputs

- Reviewed `01-intent.md`.
- Repository boundaries and known dependencies.

### Deterministic actions

1. Confirm the intent review marker exists.
2. Record candidate value, boundaries, dependencies, acceptance evidence, independent merge condition, and rollback/containment.
3. Check required fields for each candidate.
4. Reject candidates that depend on unmerged work without declaring the dependency.

### Orchestration

1. Produce at least two genuinely different decompositions for non-trivial work.
2. Compare value, review burden, verification cost, reversibility, and integration risk.
3. Recommend one candidate and preserve the rejected alternatives.

### AI judgment

- Propose decompositions.
- Explain semantic dependencies and likely review load.
- Recommend; do not select.

### Output

`changes/{slice-id}/02-slice.md`

Required review fields:

```yaml
review_status: pending | reviewed
reviewer:
reviewed_at:
decision: select | revise | split | reject
rationale:
```

### Human check

The accountable engineer selects, revises, splits, or rejects the candidate. Pass means the chosen slice remains independently useful and one coherent review decision. Record reviewer, date, decision, and rationale.

## Phase C: Define proof before implementation

### Inputs

- Reviewed `02-slice.md`.
- Exact repository commands and relevant policy.
- Existing behavior, failing case, or acceptance example.

### Deterministic actions

1. Map every acceptance condition to a check or explicit retained judgment.
2. Record command, expected signal, evidence location, and failure behavior.
3. For a defect, reproduce the failure before implementation when feasible.
4. Identify checks the authoring agent must not weaken without reopening approval.
5. Record missing test/tool capability as a blocker or explicit manual check.

### Orchestration

1. Order evidence from cheapest deterministic check to semantic and human review.
2. Separate required checks from optional diagnostics.
3. Define stop conditions for missing, contradictory, or unsafe evidence.

### AI judgment

- Suggest failure modes and neighboring behavior.
- Identify acceptance criteria not yet made executable.
- Explain residual semantic checks.

### Output

`changes/{slice-id}/03-evidence-plan.md`

Required review fields:

```yaml
review_status: pending | reviewed
reviewer:
reviewed_at:
decision: accept | revise | reject
accepted_manual_checks: []
```

### Human check

The accountable engineer confirms that the evidence would falsify an incorrect implementation and that protected checks reflect intended behavior. Pass records review status, reviewer, date, and accepted residual manual judgments.

## Phase D: Plan and implement

### Inputs

- Reviewed intent, slice, and evidence plan.
- Current repository revision.
- Scoped workspace and tool permissions.

### Deterministic actions

1. Record base revision and complete changed-surface expectation.
2. Create an isolated branch/worktree when concurrent work or tool policy requires it.
3. Run baseline checks named by the evidence plan.
4. Run required checks after changes and preserve raw evidence.
5. Record actual changed files and current revision.

### Orchestration

1. Draft an implementation plan naming boundaries, files, order, risks, and proof.
2. Stop when the plan exposes intent or slice ambiguity.
3. Implement only within the approved slice and granted authority.
4. During implementation, classify deviations as local-plan, slice, or intent changes.
5. Reopen the appropriate upstream human decision when scope changes.

### AI judgment

- Explore the repository and propose the implementation plan.
- Diagnose failed checks and explain deviations.

### Outputs

- `changes/{slice-id}/04-implementation-plan.md`
- Repository changes and tests.
- Raw tool evidence at repository-approved locations.

Required plan review fields:

```yaml
review_status: pending | reviewed
reviewer:
reviewed_at:
decision: accept | revise | inline-plan-sufficient | reject
base_revision:
```

### Human check

For non-trivial changes, the accountable engineer approves the plan before implementation or confirms that a short inline plan is sufficient. Any slice or intent deviation requires renewed approval; the agent cannot self-classify a material expansion as local.

## Phase E: Verify and prepare the merge decision

### Inputs

- All reviewed upstream artifacts.
- Complete current changed surface.
- Current revision.
- Raw deterministic evidence and existing review findings.

### Deterministic actions

1. Confirm reviewed upstream markers and revision linkage.
2. Map every acceptance criterion to executed evidence.
3. Run required build, type, test, lint, security, and policy checks.
4. Verify required checks and tests were not silently removed, skipped, or weakened.
5. Record command, exit status, timestamp, revision, and evidence location.
6. Enumerate the complete changed surface.
7. Mark missing evidence explicitly and block merge-ready status.

### Orchestration

1. Compare intent → selected slice → plan → diff → evidence.
2. Reconcile deterministic, AI-assisted, and human findings.
3. Classify remaining findings as blocking, accepted residual risk, or non-blocking.
4. Re-run affected evidence after every repair.
5. Pin the final decision packet to the last verified revision.

### AI judgment

- Perform independent semantic review.
- Identify intent mismatch, hidden coupling, architecture drift, and residual risk.
- Summarize evidence for the merge authority without issuing approval.

### Output

`changes/{slice-id}/05-evidence-receipt.md`

Required fields:

```yaml
slice_id:
base_revision:
verified_revision:
acceptance_coverage:
checks:
findings:
missing_evidence:
residual_risks:
review_status: pending | reviewed
reviewer:
reviewed_at:
decision: accept | revise | reject
```

### Human check

The independent reviewer confirms the evidence receipt reflects the current revision and complete changed surface. Corrections update the receipt and rerun affected checks.

## Phase F: Record merge readiness

### Inputs

- Reviewed evidence receipt.
- Current revision matching `verified_revision`.
- Named merge authority.

### Deterministic actions

1. Confirm the revision has not changed.
2. Confirm no blocking finding or missing required evidence remains.
3. Record decision, reviewer, timestamp, revision, rationale, and accepted residual risks.
4. Reopen review automatically if the revision changes later.

### Orchestration

Present four outcomes:

```text
merge-ready | revise | split | reject
```

Route `revise` to the affected phase. Route `split` to Phase B. Route `reject` to a closed record with rationale.

### AI judgment

- Explain the consequences of each available decision.
- Do not select or record a human decision.

### Output

`changes/{slice-id}/06-merge-decision.md`

Required decision fields:

```yaml
reviewer:
reviewed_at:
verified_revision:
decision: merge-ready | revise | split | reject
rationale:
accepted_residual_risks: []
```

### Human check

The merge authority owns the final decision. `merge-ready` means only that the recorded revision satisfies the accepted intent, slice, and evidence contract. It does not merge, deploy, or imply approval of future revisions.

## 8. 60/30/10 allocation

| Layer | Work placed here | Design target |
|---|---|---|
| Deterministic | IDs, required fields, status transitions, path checks, revision pins, commands, tests, evidence receipts, protected checks, missing-evidence blocks | Approximately 60% of agent-facing instructions |
| Orchestration | Phase routing, decomposition, bounded implementation execution under an approved plan, backward transitions, escalation, repair loops, handoffs | Approximately 30% |
| AI judgment | Ambiguity detection, alternatives, semantic dependency analysis, diagnosis, semantic review, risk explanation | Approximately 10% |

The ratio is a diagnostic heuristic, not a line-count requirement. Human authority is not part of the 10%; it sits outside the agent allocation.

## 9. Failure rules

- Missing trigger, desired outcome, or request owner blocks intent acceptance.
- Missing independent value or hidden dependency blocks slice acceptance.
- Missing acceptance evidence blocks implementation unless a named human accepts an explicit manual check.
- Changed intent or slice reopens upstream review.
- A passing tool summary without revision-linked output is not executed evidence.
- A changed verified revision reopens merge review.
- AI-generated approval text is never a human decision marker.
- Package, plugin, RLP, or Skill Architect artifacts are never created by this workflow unless a later, separately approved specification adds that boundary.

## 10. Synthetic walk test

### Case

A service returns raw database error messages from one API endpoint. The desired value is to prevent internal details from reaching clients while preserving useful server-side diagnostics.

This is synthetic and provides no evidence about an actual repository or team.

### Explicitly supplied stable inputs

The synthetic repository is assumed to supply these fixtures for the walk test only:

- `AGENTS.md` with architecture and contribution boundaries;
- `make test`, `make lint`, and `make typecheck`, each exiting non-zero on failure;
- an existing endpoint test and a redacted example of the leaked response;
- protected test configuration;
- a code owner who is also the merge authority;
- a policy that forbids internal database details in client responses.

If any fixture is absent in a real run, the workflow records it as owner-supplied or blocks the dependent phase.

### Normal path: merge-ready

1. Intent records the exposure, supplied policy, and desired client behavior; the request owner accepts it.
2. Slice limits work to one endpoint family and one error contract; the accountable engineer selects it.
3. Evidence plan requires a failing test that observes leaked details, a passing sanitized response, preserved structured server logging, and the supplied repository commands; the engineer accepts it.
4. The implementation plan names the shared error boundary, affected endpoints, protected tests, and proof; the engineer approves it.
5. Implementation changes only the selected boundary and preserves revision-linked raw evidence.
6. Verification checks acceptance behavior, neighboring errors, logging, lint, types, test integrity, and the complete diff; the independent reviewer accepts the receipt.
7. The merge authority records `merge-ready` against the unchanged verified revision.

Expected result: one independently valuable risk-reduction change with traceable evidence and no autonomous merge.

### Missing/conflicting-data case: revise

The owner cannot state whether clients require a stable error code. The workflow records `NOT FOUND` and returns `revise` to Phase A or C rather than inventing the contract.

Expected result: stop at the human check with one focused question and no implementation.

### Scope exception: split

The shared error boundary affects unrelated endpoints outside the selected slice. The merge authority or accountable engineer records `split`, and the workflow returns to Phase B.

Expected result: the agent cannot classify the expansion as a local implementation detail.

### Unsafe or valueless case: reject

Investigation shows that the supplied example contains only an internal log and no client-visible leak. The request owner records `reject` with the evidence locator.

Expected result: close the record without manufacturing implementation work.

### Revision-drift case

After the evidence receipt is reviewed, another commit changes the branch. The revision check fails and returns the record to `review-pending`.

Expected result: the earlier merge-ready decision cannot apply to the new revision; affected checks and review rerun.

### Weakened-check case

The implementation changes the pre-existing acceptance test so the leaked response now passes. Test-integrity verification flags the change and blocks merge-ready status.

Expected result: return to Phase D or C according to whether the test was wrong or the implementation attempted to weaken proof.

### Walk-test pass rule

Pass when every input is produced or explicitly supplied, every phase has one job and a recorded human check, all four terminal decisions route correctly, missing information stops at the correct boundary, changed revisions reopen review, weakened evidence fails closed, and no step depends on package, deployment, production, RLP, or Skill Architect behavior.

## 11. Design questions for owner review

1. Should intent acceptance always be explicit, or may low-risk work enter with an already-approved issue?
2. Which change classes require human plan approval before implementation?
3. Can `01-intent.md`, `02-slice.md`, and `03-evidence-plan.md` be one document when the decision remains readable?
4. Is merge-ready the correct terminal term, or should the workflow end at reviewed handoff?
5. What evidence demonstrates reviewer comprehension without surveillance or vanity scoring?
6. Which existing repository policy should define low, medium, and high risk?
7. After this specification is accepted, should candidate skills map one-to-one to phases or be cut by reusable responsibility?

## 12. Acceptance condition

This research specification is accepted when the owner recognizes the intended experience, corrects the phase and authority boundaries, and confirms that it is sufficient input for deriving candidate skills. Acceptance authorizes skill-system design only; it does not authorize implementation.
