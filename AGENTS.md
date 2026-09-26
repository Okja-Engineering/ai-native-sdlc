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

## Conventions that apply to writing, not just code

- **No claim about speed, throughput, velocity or cycle time.** Not in documents, not in commit messages, not in comments. The north star is better software, not faster.
- **A prose promise is not a control.** If a boundary matters, something has to refuse. If nothing refuses, say the boundary is asserted rather than enforced.
- **Grade every claim.** `STANDARDS.md` has the scheme. Vendor material is vendor methodology, never independent outcome evidence.
- **State what is unresolved as unresolved.** An open question written down is worth more than a confident answer that is wrong.
- **Do not describe a capability this repository does not have.** Mark state honestly: drafted, specified, built.
