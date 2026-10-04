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

**Git still cannot tell them apart.** Both commits that set `chosen:` are authored by the identity an agent uses, and the identity declared above authors nothing at all. `bin/validate-authorship.sh` refuses on the first and prints the second every time it runs.

**The separation has started, and it started from the wrong end.** A distinct agent address was configured on 2026-10-03, so agent-driven commits made after that date are separable from everyone else's. *What turns it on* below asks for the other move — the decider committing under the declared identity — and that has not happened. The half that was done is not the half this control needs, because the act being gated is the decider's. This said *"every commit on `main` is authored under one address"* until 2026-10-04; it stopped being true on 2026-10-03 and nothing noticed, which is what the check named at the end of this section now exists to stop. <!-- corrected-claim: under one address — the correction has to quote the sentence it corrects -->

Measured in a fresh clone, against `main` at `12ca5cd`, on 2026-10-04:

```
$ git clone https://github.com/Okja-Engineering/ai-native-sdlc.git && cd ai-native-sdlc
$ git log 12ca5cd --format='%an <%ae>' | sort | uniq -c | sort -rn
    89 imagineux <imagineux@gmail.com>               <- agent-driven, including both decisions
    74 Matthew Van Dusen <imagineux@gmail.com>       <- 73 web merges, plus 6142a91 Initial commit
    43 ai-native-sdlc agent <agent@noreply.invalid>  <- configured 2026-10-03
$ git rev-list 12ca5cd --count
206
```

**And the declared identity authors nothing:**

```
$ git log 12ca5cd --format='%an <%ae>%n%cn <%ce>' | grep -c 'matt.vandusen@okja.io'
0
```

Zero as an author and zero as a committer. Its only occurrence in the repository is this file.

**Why the measurement is labelled with a commit rather than a branch.** The first version of this block read `71 / 29 / 7` across three variants totalling 107 commits, and so did `AGENTS.md`, `CONTROLS.md` and `bin/validate-authorship.sh`. All four were taken from a working tree carrying branches that were never pushed, so no reader of the public repository could reproduce any of them. Labelling them `main` and a date fixed less than it looked: `main` moves, so the numbers went stale again the next time anyone committed, and a reader running the command got a different answer with no way to tell which of the two was wrong. A commit hash is the same measurement for everybody forever. `--all` is worse than either, because it also counts whatever branches happen to be open when it runs.

`bin/validate-authorship.sh` prints the same tally from the live history every time it runs, so this block can be checked against the repository rather than trusted. It also prints how many commits each declared identity authors, which is the line that would have caught the claim below. `tests/test_doc_claims.sh` now runs that command: a transcribed tally has to equal what git prints at the ref it names, and a present-tense sentence about author identities has to agree with what the gate prints.

`STANDARDS.md` §3 convicts a vendor of this exact shape: *"Two accounts belonging to one vendor's one product is a separation of identity, not of duties."* The two display names sharing `imagineux@gmail.com` are that shape, in the document that says so, and splitting the agent off to its own address did not touch them.

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

1. **Configure the decider's declared identity on the machine the decider commits from.** This step used to be written the other way round — configure a distinct address for the agent and leave the decider where he was — and that half was done on 2026-10-03, which is why `ai-native-sdlc agent <agent@noreply.invalid>` appears in the tally above. It separates agent commits from everything else and it does nothing for this control, because the identity being checked is the decider's and `matt.vandusen@okja.io` still authors nothing. The remaining step is to start using the declared address, not to reuse something already present. One address per party, and the separation is then readable from `git log` alone.
2. **Make the decision commit yourself.** The act being gated is setting `chosen:`. An agent may draft the record and leave it `pending` — which the contract already treats as a valid state — and the commit that fills it is the human's. That is a workflow change, not a code change, and it is what makes the control real rather than described.

**Neither waits on anything.** Both were deferred to a history cleanup on `main` until 2026-10-04, when that was weighed and refused: 85 of the commits on `main` are authored and committed by `imagineux` locally, by either the owner or an agent, so a rewrite could only assign them an identity by guessing, and the guess would land in this file. It would also force a push past the `non_fast_forward` rule and break the commit citations in `spec.md`, `SOURCES.md` and `STANDARDS.md`, `fa7538a` among them, which `bin/validate-standards.sh` now resolves. `CONTROLS.md` carries the measurement under *what is not controlled*, item 10.

**What the two existing decisions get instead is a start date.** They are unsigned and cannot be made otherwise, so CTRL-1 now records that proof a person recorded a decision begins with the next decision, by commit signature, and that `59b7cd2` and `f808ff5` predate the obligation. Signing for decision commits is not configured; CTRL-1 carries the command that shows no commit in the published history is signed, and the measurement beside it.

Until it lands, `CONTROLS.md` carries this under *what is not controlled*.
