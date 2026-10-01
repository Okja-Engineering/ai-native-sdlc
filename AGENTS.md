# Working in this repository

The portable conventions. This file is the cross-tool standard and is read by agentic tools directly — there is deliberately no `CLAUDE.md`, because when both exist `CLAUDE.md` shadows this file rather than merging with it.

## Where things are

| Task | Read |
|---|---|
| Why this repository exists | [`intent.md`](intent.md) |
| What V0 is, and is not yet | [`spec.md`](spec.md) |
| How mature AI-native teams work, Q3 2026 | [`STANDARDS.md`](STANDARDS.md) |
| The scan stage, specified | [`process/01-scan/README.md`](process/01-scan/README.md) |
| The shape of a findings file, declared once | [`process/01-scan/findings-contract.md`](process/01-scan/findings-contract.md) |
| How to run a scan cycle | [`process/01-scan/scan.md`](process/01-scan/scan.md) |
| Check a findings file before it is committed | `process/01-scan/validate-findings.sh` |
| Run every test suite | `tests/run-all.sh` |
| Commit and push conventions | this file, below |

## Commits

- **Conventional commits.** `type(scope): subject` — imperative, lower case, no trailing period.
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
- Subject ≤ 72 characters. Add a body only when the *why* isn't obvious from the subject.
- **No attribution trailers.** No `Co-Authored-By`, no tool or model credit, in commit messages or pull request bodies. The author field is the author.
- One logical change per commit.

Enforced by `.githooks/commit-msg`.

## Pull requests

There are no issues in this repository, so the PR carries the whole story. Use these headings, in this order. Drop one if it genuinely has nothing in it.

```markdown
## Background
What a reader needs to know to follow the rest. One short paragraph.

## The problem
What was wrong, or what the opportunity was. Be concrete.

## What we're not doing
The scope deliberately left out, so nobody goes looking for it.

## What we did
The change itself, described plainly.

## What you get for it
What is different now that someone can see or use.

## How it was checked
What was run, and what the result was.
```

### Write it the way you would say it

- **Plain words.** "This went stale three times" — not "the duplicate exhibited repeated staleness."
- **No aphorisms.** Lines like *"documenting a symptom is not repairing it"* sound clever and tell the reader nothing. Cut them. If a sentence would feel strange said out loud to a colleague, rewrite it.
- **Don't bold a one-liner for drama.** Bold the word that matters, not every third sentence.
- **Numbers and quotes instead of adjectives.** "875 pull requests, 10% sole approver" beats "a significant proportion."
- **Say what you are unsure about in the same plain voice.** "I couldn't get the PCI text, so this is unverified" beats a hedge.
- Short paragraphs. A table when comparing things. Code blocks for commands and their output.

## Pushing

A push is the moment work becomes public, and this repository is public. `.githooks/pre-push` runs three checks in parallel and is expected to finish in well under a second:

1. **Secrets** — a built-in pattern scan over the commits being pushed, plus `gitleaks` when it is installed. The built-in check always runs, so the guard is never simply absent.
2. **Commit messages** — the conventions above, re-checked across the whole pushed range. This catches anything that reached the branch by `--no-verify`, an amend, or a rebase.
3. **Publish disclosure** — prints exactly which commits and how many files would become newly public, and **refuses** if any of them touch a never-publish path.

Never-publish paths are listed in `.githooks/never-publish`. They currently cover the orchestration control plane and local working state.

> The disclosure check exists because of a real incident: a branch was pushed to this public repository carrying commits that had not been chosen for publication. Nothing in the tooling made the blast radius of a push visible beforehand. This makes it visible.

## Enable the hooks

```bash
git config core.hooksPath .githooks
```

Hooks live in the repository rather than each person's `.git/hooks`, so they apply to everyone and to any agent working here.

## CI

**The hooks are bypassable.** `--no-verify` defeats them, and they only run for someone who has set `core.hooksPath`. That makes them an aid, not a gate. `.github/workflows/ci.yml` runs the same checks where they cannot be skipped:

| Job | What it enforces |
|---|---|
| `tests` | The suite, on ubuntu **and macOS** — macOS ships bash 3.2 as `/bin/bash` and is the only place this repo's stated 3.2 compatibility is actually exercised. Also validates every findings file, and proves the runner still fails on a deliberately failing suite |
| `commit-messages` | Conventional subjects and no attribution trailers, across every non-merge commit a pull request would add |
| `claims` | Refuses a speed or velocity claim in anything **we** write — the rule below, which was previously only a prose promise |

Merge commit subjects are generated by the forge rather than authored, so they are exempt.

**`claims` excludes `process/*/findings/` and `process/*/topics/`.** Those files are the record of what other people said, and the scan and discovery contracts *require* recording a vendor's claim as a claim. A row reading *"vendor X states its product is N times quicker"* is this repository doing its job, not claiming speed. (Stated in words rather than quoted verbatim, because this file is one the guard checks — an illustrative example written literally would trip it, which is how this exclusion came to be written in the first place.) The exclusion is by directory rather than by phrasing on purpose — a lexical rule trying to tell *we claim X* from *they claim X* would be guessing at attribution, whereas the directory boundary already exists in the design. Those files carry their own constraint instead: every row needs a resolving source, so an unattributed claim cannot live there anyway.

**The pattern carries no `\b` anchors, deliberately.** macOS `git grep` does not honour them and silently matches nothing while Linux git does — so the anchored version fired in CI and did nothing on a developer's machine, which is worse than either alone. If you tighten this pattern, test it on both.

## Conventions that apply to writing, not just code

- **No claim about speed, throughput, velocity or cycle time.** Not in documents, not in commit messages, not in comments. The north star is better software, not faster.
- **A prose promise is not a control.** If a boundary matters, something has to refuse. If nothing refuses, say the boundary is asserted rather than enforced.
- **Grade every claim.** `STANDARDS.md` has the scheme. Vendor material is vendor methodology, never independent outcome evidence.
- **State what is unresolved as unresolved.** An open question written down is worth more than a confident answer that is wrong.
- **Do not describe a capability this repository does not have.** Mark state honestly: drafted, specified, built.
