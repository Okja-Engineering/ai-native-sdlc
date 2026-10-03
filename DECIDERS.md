# Authorized deciders

A decision record's `decided_by:` must name someone on this list. `process/05-deliver/validate-decision.sh` refuses one that does not.

**The list is the `Name` column of the table below, data rows only.** Nothing else in this file authorizes anybody: not the column heading, not an example in a code block, and not a second table added later. Until 2026-10-03 the gate read the first cell of every row in the file, which made `decided_by: Name` — the heading — an authorized decider.

| Name | Since | git identity |
|---|---|---|
| Matthew Van Dusen | 2026-10-01 | `Matthew Van Dusen <matt.vandusen@okja.io>` |

**The git identity column is a target, not a record, and `bin/validate-authorship.sh` says so.** It declares the identity a decision commit *must* carry. `Matthew Van Dusen <matt.vandusen@okja.io>` authors **no commits at all** — not the two decision commits, not anything else, on any ref. Both decisions were authored as `imagineux <imagineux@gmail.com>`, the same identity agent-driven commits use. Nothing in this file should be read as evidence that a commit exists under the declared address. See *Who committed the decision* below for the measurement and the command.

---

## Why this is a list and not a pattern

`decided_by` used to be checked against a **denylist** — an anchored exact match against twenty words like `team`, `reviewer`, `claude`, `bot`. An external audit walked straight through it:

```
decided_by: the Platform Engineering Team  ->  within the contract
decided_by: Claude Opus 5                  ->  within the contract
```

Any multi-word role and any model with a version number passed, because neither is in the list of twenty.

**Widening the denylist would not have fixed it.** The set of things that are not a person is unbounded, so a denylist is open by construction: it fails *open*, and every miss is silent. The invariant is *"`decided_by` denotes a natural person"*, and the only way to establish that mechanically is to enumerate the people.

This is the same shape as the grade enum in the Discover gate, which checks that a grade is one of `E S V P O` rather than listing grades that would be wrong. **Enumerate what is allowed.**

## Why this is the right control anyway

*Who is authorized to approve?* is a question an auditor asks directly. A denylist cannot answer it; this file can.

Adding a decider is now an explicit, reviewable change to a tracked file — which is what it should be. A new name arriving in a decision record without a corresponding change here is refused, and that refusal is the control working rather than an inconvenience.

## What this does not establish

**That the named person read the change.** `CONTROLS.md` records this under *what is not controlled*, and it is unchanged by this file. An allowlist makes `decided_by` attributable to an authorized individual. It cannot distinguish someone who reviewed carefully from someone who did not.

## Who committed the decision

An allowlist establishes that `decided_by` names an authorized person. It does not establish that the person, rather than an agent, wrote the field.

**Git cannot currently tell them apart, because every commit on `main` is authored under one address.** Two author identities exist and both use `imagineux@gmail.com`.

Measured against `main` in a fresh clone on 2026-10-03:

```
$ git clone https://github.com/Okja-Engineering/ai-native-sdlc.git && cd ai-native-sdlc
$ git log main --format='%an <%ae>' | sort | uniq -c | sort -rn
  63 imagineux <imagineux@gmail.com>          <- agent-driven commits, including both decisions
  32 Matthew Van Dusen <imagineux@gmail.com>  <- 31 web merges, plus 6142a91 Initial commit
$ git rev-list main --count
95
```

**And the declared identity is absent entirely:**

```
$ git log --all --format='%an <%ae>%n%cn <%ce>' | grep -c 'matt.vandusen@okja.io'
0
```

Zero as an author and zero as a committer, across every ref a clone fetches. Its only occurrence in the repository is this file.

**Why the measurement is labelled with a ref and a date.** The first version of this block read `71 / 29 / 7` across three variants totalling 107 commits, and so did `AGENTS.md`, `CONTROLS.md` and `bin/validate-authorship.sh`. All four were taken from a working tree carrying branches that were never pushed, so no reader of the public repository could reproduce any of them. `main` rather than `--all`, because `--all` also counts whatever branches happen to be open when it runs — a clone today sees 100 commits across all refs and 95 on `main`, and only the second number is stable enough to write down.

`bin/validate-authorship.sh` prints the same tally from the live history every time it runs, so this block can be checked against the repository rather than trusted. It also prints how many commits each declared identity authors, which is the line that would have caught the claim below.

`STANDARDS.md` §3 convicts a vendor of this exact shape: *"Two accounts belonging to one vendor's one product is a separation of identity, not of duties."* Here it is one account with two display names, in the document that says so.

**`bin/validate-authorship.sh` checks it and refuses today.** A commit that sets `chosen:` to anything but `pending` must be authored by the identity declared above, and that identity must not be shared. Neither holds:

Run `bin/validate-authorship.sh`. It emits both refusals for each of the two decision-setting commits — four in total — then prints the tally above:

```
refuse[author-not-a-decider]  59b7cd2 set chosen: D, authored by "imagineux <imagineux@gmail.com>"
refuse[identity-shared]       59b7cd2 is authored under <imagineux@gmail.com>, which carries 2 different author names
refuse[author-not-a-decider]  f808ff5 set chosen: F, authored by "imagineux <imagineux@gmail.com>"
refuse[identity-shared]       f808ff5 is authored under <imagineux@gmail.com>, which carries 2 different author names
```

**It is deliberately not wired into CI**, because a gate that cannot pass blocks every branch and this one needs a change an agent should not make.

### What turns it on

Two things, and both are the decider's:

1. **Configure a distinct identity for agent-driven commits**, so `git log` separates them without anyone's testimony. This said *"the address above already appears in this history"* until 2026-10-03 and it never did — `matt.vandusen@okja.io` authors nothing, as the measurement above shows. So the step is to start using it, not to reuse something already present: configure the decider's git identity on the machine the decider commits from, and leave agent-driven commits on `imagineux@gmail.com`. One address per party, and the separation is then readable from `git log` alone.
2. **Make the decision commit yourself.** The act being gated is setting `chosen:`. An agent may draft the record and leave it `pending` — which the contract already treats as a valid state — and the commit that fills it is the human's. That is a workflow change, not a code change, and it is what makes the control real rather than described.

**Both are deferred to a git history cleanup on `main`**, tracked as issue #51. That is a force-push to a public branch which rewrites every SHA, so it has to take the commit citations in `spec.md`, `SOURCES.md` and `STANDARDS.md` with it — `fa7538a` among them. Not an operation to run piecemeal, and not an agent's to run at all.

Until it lands, `CONTROLS.md` carries this under *what is not controlled*.
