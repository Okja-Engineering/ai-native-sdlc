---
name: select-improvement
description: Deterministically evaluate the starter practice cards against an owner-facts file and report which practices are eligible, blocked, inapplicable, unknown, or conflicted — with provenance and missing-fact gaps. Use to select the smallest justified improvement. Never accepts, adopts, or writes anything.
license: MIT
compatibility: Markdown files, Bash, repository read access.
metadata:
  version: "0.1.0"
---

# Select improvement

Given the card set under `cards/` and an `owner-facts/0.1.0` file, report
which candidate practices are eligible and ready, which apply but are
blocked on prerequisites or missing client capabilities, and which are
inapplicable, unknown, or conflicted — with a missing-fact gap list and
research provenance.

## When to use

After the owner has recorded established facts (promoted from observation
snapshots or interviews) and wants the smallest justified next improvement.

## Inputs

- `cards/` — `selection-card/0.1.0` blocks, one per candidate practice.
- An `owner-facts/0.1.0` file — established/unknown/conflicted facts with
  source references. See `references/selection-contract.md`.

## Process

1. Collect or promote owner facts into the owner-facts file. Referencing an
   observation does not promote it — `established` is a human act.
2. Run `scripts/select-eligible.sh CARDS_DIR FACTS_FILE`.
3. Read the report; a human decides which eligible candidate to adopt.

## Deterministic actions

- Parse and validate both document kinds; reject malformed facts,
  unsupported predicate syntax, duplicate fact IDs, and duplicate card IDs.
- Evaluate applicability (`applies_when`) separately from readiness
  (`requires_capability`, `depends_on` adoption).
- Detect missing dependency targets and cycles as graph errors (exit 3).
- Emit a deterministic stdout report; identical inputs → identical output.

## Orchestration

The selector is a leaf tool. It may feed a packaging step, but adoption,
ranking, and export are separate authorized acts.

## AI judgment

None. Matching is verbatim fact-ID/value equality; there is no fuzzy
matching, inference, or automatic promotion.

## Outputs

Stdout report: `eligible and ready`, `applicable — blocked`,
`inapplicable`, `unknown`, `conflicted`, `missing-fact gaps`. Exit 0 on a
completed report, 2 on input/validation failure, 3 on a graph error.

## Human check

The owner reviews the report and records adoption decisions themselves —
e.g. adding `CARD-ID = adopted` facts. The selector never labels a
candidate accepted and performs no writes.

## Example

```
skills/select-improvement/scripts/select-eligible.sh \
  skills/select-improvement/cards owner-facts.md
```

## Constraints

- Read-only; no repository or input mutation.
- Applicability is not adoption readiness; selection is not implementation.
- Unreviewed research stays visibly provisional in the report.
- AI ranking and human adoption are outside this skill.
