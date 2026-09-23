---
slice_id: 20260922-gap-report-contract
status: proof-pending
review_status: pending
reviewer:
reviewed_at:
decision: accept | revise | reject
residual_manual_judgments:
---

# Evidence plan — falsification before implementation

## What the contract must require — derived from the consumer's decision

The gap report's consumer is the owner deciding whether a stopped run
stopped *correctly* and what to supply next. For that decision the report
must carry:

1. Run identity — run id, skill version, input/output roots.
2. The missing required input, verbatim, with its question ID.
3. What was searched and why each candidate fails — so "stopped" is
   auditable, not just asserted.
4. Verbatim deterministic results (validator output, exit codes).
5. An explicit no-recommendation boundary statement.
6. Review fields (`review_status`, `reviewer`, `reviewed_at`, `decision`)
   per the repository's artifact conventions.

Run-09's `gap-report.md` is *evidence* for these requirements, not their
source. Checked against them it carries 1–5 but **lacks formal review
fields (6)** — recorded here as a gap in the historical artifact, which
is preserved unchanged; the contract must not be weakened to guarantee
it passes. If it is copied as a fixture it is first sanitized
(run-specific host/model and path details reduced to fixture-neutral
values) and its missing review fields are either added and disclosed as
a fixture edit, or the fixture is marked expected-fail on that field.

## What the deterministic check proves — and what it cannot

- **Structural conformance (script):** required fields present, fences
  well-formed, review markers present, no fabricated provenance.
- **Not proven by structure:** that the agent actually stopped at the
  right point, searched honestly, or avoided recommendations. A missing
  "recommendations" heading does not prove absence of recommendation —
  text could smuggle one under any heading. **Semantic review of the
  report's content is human/AI judgment, declared, not scripted.**

## Deterministic checks (structural proof)

1. Validator exits non-zero and names the field on: missing run
   identity, missing missing-input statement, missing
   searched-candidates section, missing review fields.
2. A *new* minimal conforming fixture passes — proving the contract is
   implementable, not just run-09-shaped.
3. Each single-field mutation of the conforming fixture fails closed.
4. `tests/test_evidence_to_intent.sh` and `tests/test_structure.sh`
   green; no other suite touched.
5. Identical input → identical validator output.

## Behavioral proof — a separate, named evaluation

Fixture-only implementation stays bounded, but it cannot establish that
a live run stops correctly and writes a conforming report. Before this
slice may be called a dogfood success, a **live missing-input
evaluation** is required: invoke `evidence-to-intent` with a required
input withheld, confirm it stops, and validate the emitted gap report —
recorded in `.devin/eval/` with host/model, inputs, and reviewer, like
runs 01/09. Claiming dogfood success on fixtures alone is out of bounds.

## Acceptance evidence for slice review

- Executed check output (exit codes + named findings) pasted into
  `05-evidence-receipt.md` at verify time — not now.
- The live missing-input evaluation record.
- Owner can answer, from the artifacts alone: "when the skill stops,
  what exactly must the report contain, and did this run produce it?"

## Residual manual judgments (declared, not hidden)

- Whether the required-field set is the *right* minimum is owner
  judgment; the validator only enforces the declared set.
- Whether a given report's searched-candidates account is *adequate* is
  review judgment; the validator checks only that the section exists.
