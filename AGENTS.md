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

  **"The author field is the author" is not currently true, and the rule needs revisiting rather than quietly contradicting.** Every commit on `main` is authored under one address, `imagineux@gmail.com`, under two display names, so `git log` does not separate an agent-driven commit from a person's — including the two commits that recorded a decision. Run `bin/validate-authorship.sh` for the live tally, or `git log main --format='%an <%ae>' | sort | uniq -c` in a clone; `DECIDERS.md` carries the measurement with the ref and date it was taken against, and this file deliberately does not repeat the numbers. Trailers were banned to keep tool credit out of commit messages; separating authorship needs the opposite of that ban, for a different reason. `DECIDERS.md` sets out the two changes that fix it properly, both of which are the decider's; a trailer would be the weaker substitute, because a trailer can be omitted and an author field cannot.
- One logical change per commit.
- **A merge subject is exempt from the convention, and only the subject.** It is generated — by git for a local `git merge`, by the forge for a pull request — so refusing it refuses something nobody wrote. The attribution ban still applies to a merge, because a merge message can be edited.

Enforced by `.githooks/commit-msg`, re-checked by `.githooks/pre-push`, and enforced where it cannot be skipped by the `commit-messages` job. **All three now carry the merge exemption; until 2026-10-03 only the CI job did.** `git merge main` on a branch was refused locally for the subject git had just written, and a force-push of a rebased branch was refused for a merge on `main` that the forge wrote — in both cases the only way through was `--no-verify`, which also turns off the secret scan. One rule enforced in three places with the exemption in one of them is the drift CTRL-9 exists to prevent, pointing the other way. `tests/test_hooks.sh` drives both hooks against a throwaway repository and a bare remote.

## Issues and pull requests

Two artifacts, each with one job.

**The issue** carries the intent, at the feature or capability level: title as the problem statement, background, the problem, proposed solution, expected outcome, validation method. The validation method is decided **before** the work starts. Template: [`.github/ISSUE_TEMPLATE/capability.md`](.github/ISSUE_TEMPLATE/capability.md).

**The pull request** links the issue and stays short: what changed, how it was proved and what wasn't, and what is deliberately out of scope. It does not repeat the intent. Template: [`.github/pull_request_template.md`](.github/pull_request_template.md).

Together they give an auditable chain: the issue states the intended change and how it will be validated, the pull request shows what was done and the evidence, and the merge is the approval by a named person.

### Two chains, and only one of them is in git

This said *"All of it in git."* It is not, and an external audit caught it. <!-- corrected-overclaim: all of it in git — this sentence is the correction, so it has to quote what it corrects -->

<!-- The declaration above is read by tests/test_doc_claims.sh. It exempts that one
     phrase on that one line, and nothing else. It replaced a rule that discarded
     any line carrying the word "claimed", which let the overclaim back in. -->


| | Where it lives | Readable from a clone? |
|---|---|---|
| **The process chain** — findings → topic → problem → options → decision → the `STANDARDS.md` amendment | Tracked files, each linked to the next by a `from:`, `rests on:`, `problem:`, `options:` or `amends:` field | **Yes, end to end** |
| **The engineering chain** — issue → pull request → merge | Issue and pull request bodies are in GitHub's database. The merge commit carries only the number and the title | **No** |

```
$ git log --format='%s%n%b' -1 --merges
Merge pull request #47 from Okja-Engineering/doc-drift
The documents describe a repository that no longer exists, in six confirmed places
```

No validation method, no evidence section, no approval record.

**What this means for an assessor.** The chain the loop produces — the one being assessed — is complete in a clone. The chain by which this repository was *built* is not: a clone can see that a change was reviewed and merged, and cannot see what it was intended to do or how that was to be validated.

**References to issue numbers in tracked documents therefore carry their own context.** `#19` means nothing offline, so a document naming an issue states the gap in the same sentence rather than pointing at it.

### Why these are short

An earlier draft of this section had six required headings. The evidence is against that:

- **Length has a measured cost.** Kubernetes audited 1,146 pull requests in release 1.37 and removed a template section that about 92% of contributors ignored — 43.4% deleted it, 39.5% left it empty, 9.2% wrote a placeholder. A stated reason for removing it: contributors who stop reading partway down miss the sections below. `[E]`
- **Real templates are small.** Of the projects checked, `microsoft/vscode`'s renders nothing at all — 344 bytes, entirely an instruction comment to the author. `rust-lang/rust` renders fourteen lines. `rails` tells contributors to discard the template if they want. `[E]`
- **Description richness has never been shown to help.** No controlled study measures it. The one direct observation runs the other way: reviewers who read descriptions thoroughly were slower to first comment, and file familiarity rather than description quality predicted depth of feedback (Bacchelli & Bird, ICSE 2013). `[E]`
- **Accuracy is the thing that has been measured.** Across 23,247 agentic pull requests, those whose description misdescribed the code saw 28.3% acceptance against 80.0%, and took 3.5 times longer to merge; the most common failure was a description claiming changes that were not implemented, at 45.4% (arXiv 2601.04886, correlational). `[E]`

So the rule is **true, not thorough**. A short description that matches the diff beats a complete one that does not.

The widely quoted "200–400 lines, 70–90% defect discovery" figure is **not** evidence for any of this. It is self-published vendor material from 2006 with no stated method and no dataset. `[V]` For scale, Google's median changelist across roughly 9 million changes is **24 lines modified**, and its own written guidance suggests about 100 lines as a judgment call, not a measured threshold. `[E]`

### Declaring what you could not verify

State it. A test you could not run, a claim taken on trust, a platform you did not check. The Linux kernel requires this of patch submissions — *"If the fix could not be built or tested, or if no reproducer could be produced, say so explicitly."* This repository already holds the same rule for scan findings, where `nothing found` is a result.

### Gates: enumerate what is allowed, not what is not

A denylist fails **open**. Every miss is silent, and the set of things that are wrong is usually unbounded.

`decided_by` was checked against twenty words — `team`, `reviewer`, `claude`, `bot`. An external audit passed `the Platform Engineering Team` and `Claude Opus 5` through it in one try. Widening the list would not have fixed it; the shape was wrong. It is now an allowlist in [`DECIDERS.md`](DECIDERS.md), and a missing list refuses rather than passing everything.

The model already in the repository is the Discover gate's grade check — `case "$g" in E|S|V|P|O)`. It enumerates the five valid grades rather than guessing at the invalid ones.

### Tests: pin the invariant, not the literals

The tests that were supposed to catch the `decided_by` defect asserted exactly `the team`, `Claude` and `reviewer` — **the three strings the regex was written for.** They proved the list contained three words. They never tested whether `decided_by` denotes a person, so the gate and its suite agreed with each other and both were wrong.

Two rules follow:

- **Include inputs the implementation was not written for.** Multi-word forms, versioned names, truncations, case variants, a plausible value that is simply not authorized. If a reasonable rewrite of the check would still pass the suite, the suite is pinning behaviour; if only this implementation passes, it is pinning the implementation.
- **Mutation-test the comparison, not just the guard.** Deleting a check and seeing red proves the check is *reachable*. Loosening it — exact match to substring, anchored to unanchored, threshold to zero, an enumerated list to anything — proves it is *sufficient*.

  **Run the sweep with `tests/mutate-sweep.sh`, and read its denominator before its result.** This said "a sweep of all five gates found two more instances of this the first way had missed". That sweep was by hand and by pattern, and the sentence was wrong about its own coverage: it missed a whole guard. The `id` refusal in the scan gate had no test at all, and replacing its condition with `if false` left every suite green. A sweep decides what exists by how it enumerates, so the enumeration is the part to argue with — `tests/mutate-sweep.sh --list` prints it and runs nothing.

### Write it the way you would say it

- **Plain words.** "This went stale three times" — not "the duplicate exhibited repeated staleness."
- **No aphorisms.** Lines like *"documenting a symptom is not repairing it"* sound clever and tell the reader nothing. If a sentence would feel strange said out loud to a colleague, rewrite it.
- **Don't bold a one-liner for drama.** Bold the word that matters.
- **Numbers and quotes instead of adjectives.** "875 pull requests, 10% sole approver" beats "a significant proportion."
- **Say what you are unsure about in the same plain voice.** "I couldn't get the PCI text, so this is unverified" beats a hedge.

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
| `claims` | A **tripwire** for the obvious forms of a speed or velocity claim in anything **we** write. Runs `bin/validate-claims.sh`, which is also runnable locally. Not enforcement of the rule — see below |

Merge commit subjects are generated by the forge rather than authored, so they are exempt.

**`claims` excludes `process/*/findings/` and `process/*/topics/`.** Those files are the record of what other people said, and the scan and discovery contracts *require* recording a vendor's claim as a claim. A row reading *"vendor X states its product is N times quicker"* is this repository doing its job, not claiming speed. (Stated in words rather than quoted verbatim, because this file is one the guard checks — an illustrative example written literally would trip it, which is how this exclusion came to be written in the first place.) The exclusion is by directory rather than by phrasing on purpose — a lexical rule trying to tell *we claim X* from *they claim X* would be guessing at attribution, whereas the directory boundary already exists in the design. Those files carry their own constraint instead: every row needs a resolving source, so an unattributed claim cannot live there anyway.

**The pattern carries no `\b` anchors, deliberately.** macOS `git grep` does not honour them and silently matches nothing while Linux git does — so the anchored version fired in CI and did nothing on a developer's machine, which is worse than either alone. If you tighten this pattern, test it on both.

## Conventions that apply to writing, not just code

- **No claim about speed, throughput, velocity or cycle time.** Not in documents, not in commit messages, not in comments. The north star is better software, not faster.

  **The check is a tripwire, not enforcement, and the difference matters.** `bin/validate-claims.sh` catches the obvious forms. It cannot be categorical, because a lexical rule never is — *"our engineers spend less time waiting"* is a speed claim and passes, and a test asserts that it passes so nobody mistakes the gate for coverage. The rule is yours to keep; the gate catches the careless version.

  An external audit wrote a document with six explicit speed claims and the job printed ok. Two reasons, and the second is the one worth remembering: the pattern had no entry for **quicker** — the word used as the example in this very file — and after it was widened the pattern contained an empty alternative, which made it an invalid expression. `git grep` errored, a non-zero exit was read as "nothing found", and the gate reported the tree clean having evaluated nothing. It now exits 2 if the pattern does not compile.
- **A prose promise is not a control.** If a boundary matters, something has to refuse. If nothing refuses, say the boundary is asserted rather than enforced.
- **Grade every claim.** `STANDARDS.md` has the scheme. Vendor material is vendor methodology, never independent outcome evidence.
- **State what is unresolved as unresolved.** An open question written down is worth more than a confident answer that is wrong.
- **Do not describe a capability this repository does not have.** Mark state honestly: drafted, specified, built.
