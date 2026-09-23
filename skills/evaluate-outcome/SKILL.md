---
name: evaluate-outcome
description: Deterministically evaluate observed evidence against named outcome targets and emit one reviewable outcome receipt — product and process questions separated, honest missing/conflicted/stale/non-comparable states, no verdict. Use for the outcome-evaluation step of the pilot. Never accepts, ranks, or promotes corrections.
license: MIT
compatibility: Markdown files, Bash, sha256 tooling.
metadata:
  version: "0.1.0"
---

# Evaluate outcome

Compare declared outcome targets against observed evidence and emit one
reviewable `outcome-receipt/0.1.0`. Answers two questions separately: did
the delivered change achieve its intended effect (product), and did the
workflow improvement help delivery net of effort (process).

## When to use

After a pilot slice has run and evidence exists to evaluate — the
dogfood readiness sequence ends with this step plus owner review.

## Inputs

- `--contract` — the workflow contract; must pass the workflow validator
  and carry its own acceptance record (`--contract-acceptance`). Its
  normalized digest must equal the targets' `intent_digest`.
- `--targets` — `outcome-targets/0.1.0` with a matching
  `contract-acceptance` record (`--targets-acceptance`).
- `--evidence` — `outcome-evidence/0.1.0` observations and lessons.
- `--baseline` — optional `outcome-evidence/0.1.0` pre-adoption measures.
- `--implementation-rev` — revision being evaluated.
- `--inputs-root` — inspected repository the receipt must stay outside.
- `--out` — receipt destination (differing → REFUSE, identical → SAME,
  directory or in-repo path → REFUSE).

## Process

1. Validate the workflow contract and verify its acceptance record;
   verify target declarations, the contract-digest binding, and the
   targets' acceptance record — two explicit bindings.
2. Evaluate every evidence record per outcome: `observed`, `missing`,
   `conflicted`, `stale`, `non-comparable` — all rows preserved with
   per-item provenance; earlier revisions kept verbatim.
3. Compare against baseline only on declared comparability fields;
   `sampling`/`conditions` must be declared and equal on both sides.
4. Emit the receipt and a stdout summary; stop for owner review.

## Deterministic actions

All of it — parsing, field-name validation, classification,
comparability on declared fields (measure, unit, scope, duration, basis;
sampling and conditions pairwise), destination preflight.

## Orchestration

Leaf tool. Feeding lessons into RLP is a later slice using RLP's own
contract; nothing here promotes.

## AI judgment

None. No scoring, inference, or verdict — `observed` means evidence
exists, not that the outcome succeeded.

## Outputs

Receipt file at `--out` + stdout summary. Exit 0 on CREATE/SAME, 2 on
input failure, 4 on destination refusal.

## Human check

The owner reviews the receipt — including negative and inconclusive
outcomes — and decides whether design change is warranted.

## Example

```
skills/evaluate-outcome/scripts/evaluate-outcome.sh \
  --contract SDLC.md --contract-acceptance SDLC.accept.md \
  --targets targets.md --targets-acceptance targets.accept.md \
  --evidence observed.md --baseline baseline.md \
  --implementation-rev abc123 --inputs-root /path/to/repo \
  --out /path/outside/receipt.md
```

## Constraints

- A passing workflow check never establishes an outcome.
- Reviewer names are not confirmations; no RLP artifact is emitted.
- Inputs are read-only; only `--out` is written.
- Missing baselines permit observation but never improvement claims.
