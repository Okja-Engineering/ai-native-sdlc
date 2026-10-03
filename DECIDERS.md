# Authorized deciders

A decision record's `decided_by:` must name someone on this list. `process/05-deliver/validate-decision.sh` refuses one that does not.

| Name | Since | git identity |
|---|---|---|
| Matthew Van Dusen | 2026-10-01 | `Matthew Van Dusen <matt.vandusen@okja.io>` |

**The git identity column is not yet true, and `bin/validate-authorship.sh` says so.** It declares the identity a decision commit *must* carry. Today no decision commit carries it — both were authored as `imagineux <imagineux@gmail.com>`, the same identity agent-driven commits use. See *Who committed the decision* below.

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

**Git cannot currently tell them apart.** Three identity variants exist in this repository's history and two share an address:

```
71  imagineux <imagineux@gmail.com>          <- agent-driven commits, including both decisions
29  Matthew Van Dusen <imagineux@gmail.com>  <- the web merges
 7  imagineux <matt.vandusen@okja.io>
```

`STANDARDS.md` §3 convicts a vendor of this exact shape: *"Two accounts belonging to one vendor's one product is a separation of identity, not of duties."* Here it is one account with two display names, in the document that says so.

**`bin/validate-authorship.sh` checks it and refuses today.** A commit that sets `chosen:` to anything but `pending` must be authored by the identity declared above, and that identity must not be shared. Neither holds:

```
refuse[author-not-a-decider]  59b7cd2 set chosen: D, authored by "imagineux <imagineux@gmail.com>"
refuse[identity-shared]       <imagineux@gmail.com> carries 2 different author names
```

**It is deliberately not wired into CI**, because a gate that cannot pass blocks every branch and this one needs a change an agent should not make.

### What turns it on

Two things, and both are the decider's:

1. **Configure a distinct identity for agent-driven commits**, so `git log` separates them without anyone's testimony. The address above already appears in this history and is distinct from the one agent commits use.
2. **Make the decision commit yourself.** The act being gated is setting `chosen:`. An agent may draft the record and leave it `pending` — which the contract already treats as a valid state — and the commit that fills it is the human's. That is a workflow change, not a code change, and it is what makes the control real rather than described.

Until both hold, `CONTROLS.md` carries this under *what is not controlled*.
