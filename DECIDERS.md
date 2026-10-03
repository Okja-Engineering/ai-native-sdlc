# Authorized deciders

A decision record's `decided_by:` must name someone on this list. `process/05-deliver/validate-decision.sh` refuses one that does not.

| Name | Since |
|---|---|
| Matthew Van Dusen | 2026-10-01 |

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

**That the person, rather than an agent, wrote the field.** Issue #38 covers that: two git identities currently share one email, and the agent alias authored the commit that wrote the name into the record. An allowlist narrows the gap; it does not close it.
