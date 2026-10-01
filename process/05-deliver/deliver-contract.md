# Deliver contract

**Status:** derived alongside the first decision record. The record was drafted first and this describes the shape it needed.

**The one gate the contract named is now built.** See *The gate* at the end.

## What Deliver is for

Converging an option set into **one choice, made by a named person, with what is being given up written down**.

It is the closing half of the second diamond, and the only phase in the loop that decides anything.

## The rule everything else follows from

**A decision is made by a human, and the record says which one.**

Not "the team." Not "it was agreed." A name. This is the one place in four phases where the thing actually turns, and an unattributed decision is the failure `STANDARDS.md` §3 is about wearing different clothes — if nobody is named, nobody chose, and the record is describing an outcome rather than a decision.

**This is the one rule worth enforcing mechanically even on n=1.** A `chosen:` field with no `decided_by:` naming a person is a decision that did not happen, and a machine filling both is the loop quietly closing itself. See the gate note below.

## Required fields

| Field | |
|---|---|
| `problem` | the stated problem, linked |
| `options` | the option set it chose from, linked |
| `chosen` | the option id, or `pending` while it waits for a person |
| `decided_by` | a named human. **Not an agent, not a role, not "the team"** |
| `dated` | when the person decided, not when the record was drafted |

`chosen: pending` is a valid and expected state. A record can be drafted — problem, options, tradeoffs laid out — and wait. `bin/cycle.sh` reports a pending decision as awaiting a human, which is the honest reading: the work is done and the gate has not been passed.

## Required sections

### What was chosen, and why

The reasoning, in the decider's terms. Short is fine; a decision nobody can reconstruct in six months is not recorded, only logged.

### What we are accepting

**Every option in a Develop set carries a failure mode. Choosing one means accepting its failure mode**, and this section names it.

This is the section that makes a decision honest. Without it a record reads as a win, and the first thing anyone will want when the chosen option fails is evidence that the failure was foreseen rather than missed.

### Why not the others

One line each, for every option not chosen. Not a ranking — a reason.

This is what stops Develop becoming theatre. If the unchosen options cannot each be given a reason, either they were never real options or the choice was made before Develop ran.

### What would reverse this

The condition under which the decision gets revisited — a date, a measurement, an event. A decision with no reversal condition is permanent by accident rather than by intent.

### What this does not settle

The gaps the option set already named. The first set had no answer for the outlier surface; choosing an option does not create one, and a decision record implying otherwise is overclaiming.

## What Deliver must never do

- **Decide without a named person.** The whole loop exists to preserve this gate.
- **Choose an option that was not in the set.** If the right answer was not developed, go back to Develop; inventing it here means the alternatives were never weighed.
- **Drop the accepted cost.** A record with no "what we are accepting" is a sales document.
- **Silently supersede an earlier decision.** A reversal is a new record pointing at the old one. Editing a decision in place destroys the thing that made it a record.

## The gate

Three phases have deferred their gates on the grounds that one artifact cannot tell shape from accident. That reasoning holds here too — except for one check, which does not depend on shape at all:

**A record with `chosen:` set to anything but `pending` must carry a `decided_by:` naming a person.**

That is mechanical, cheap, and guards the only thing in the repository that cannot be reconstructed afterwards. Everything else about Deliver's shape should wait for a second decision.

**Built**, as `validate-decision.sh`, with two companions that are equally shape-independent: a chosen option must exist in the option set it claims to choose from, and a decided record must be dated. A `decided_by` naming a role, a team or a model is refused as not a person.

Every refusal carries its own message and is asserted by that message in `tests/test_validate_decision.sh`. Everything else about Deliver's shape still waits for a second decision.

## Open

1. **Whether a decision needs a review period** before it binds, or takes effect when written.
2. **Where a reversal lives** — a new record superseding, or an append to the original. The contract forbids silent editing; it does not yet say what replaces it.
3. **Whether the chosen option should be fed back into `STANDARDS.md`** when it changes how we work, and what keeps those two in step.
