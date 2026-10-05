# Deliver contract

**Status:** derived alongside the first decision record. This said the record was drafted first; git shows the contract committed one second earlier, so the two were produced as one batch and the order is unverifiable from the repository. Stated that way rather than left as a claim git contradicts.

**The one gate the contract named is now built, and one field is declared and not yet enforced.** See *The gate* at the end.

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
| `expires` | when this decision expires, as `YYYY-MM-DD` — or `none` with the reason it does not. **Declared, not yet enforced** |
| `amends` | the claim this decision changes — the document, **linked**, carrying the `#anchor` of the heading that holds the claim — or `none` with the reason nothing changed |

### `expires`, and why a date in prose was not a tripwire

**Added because the only open decision in this repository set itself a deadline that nothing could read.** `producing-themes` chose to wait and measure, and the record is explicit that what makes that a choice rather than drift is the tripwire attached to it — *"F without one is indistinguishable from the thing it fails at."* The date was in one prose sentence. No contract declared an expiry, no script read the date, and the condition the record relied on to stay honest was going to be remembered or lost. *What would reverse this* was already a required section; what it lacked was a field.

**The form is a plain `YYYY-MM-DD` date.** Not a duration, not "in two cycles": a date is what a person can check against a calendar without knowing when the record was written, and it is what the only record that has one already says. `none` plus the reason is the other valid value, and it is expected to be the ordinary one, because most decisions are not waiting on anything. Bare `none` is refused by the same reasoning as `amends: none` and `rests on: none`: on its own it cannot be told apart from the field being forgotten.

**Only one of the two shipped records carries the field.** `producing-themes` was backfilled, because its expiry was already stated in its own prose and the field only makes that readable — the same move as adding the `id` column to a findings file. `agent-pr-approval` carries nothing: whether that decision expires, and the reason if it does not, is the decider's judgement and not a structural edit, so it is left for them rather than guessed at here. A reader should not take the absence as a declaration.

**An expiry is not the only reversal condition, and it is not meant to be.** The `producing-themes` record also reverses on a missed cycle and on the finding rate roughly doubling, neither of which is a date. This field makes the dated part machine-readable; *What would reverse this* goes on carrying the rest in prose, because a condition like "the comparison test comes back strongly either way" is a judgement and writing it as a field would be pretending otherwise.

**Declared, not yet enforced.** `bin/next.sh` scaffolds it — it reads this table, so it needed no edit — and `bin/cycle.sh` reports days to the nearest expiry alongside days since the last scan, which is the part that puts the tripwire in front of a person. Nothing refuses a decision that omits the field, and nothing refuses one whose expiry has passed.

**What would make gating it right.** A second decision carrying the field. One record cannot show whether `expires` is a field every decision wants or a field this decision wanted: `agent-pr-approval` would write `none` and the next real expiry has not been written yet. When two records carry it, the gate worth building is the one in the same shape as the rest of this contract's checks — the field is declared, a date parses, and a bare `none` is refused — and a report that an expiry has passed is a separate question, because refusing an expired decision would refuse the record that is telling the truth about itself.

### `amends`, and why Update is not a sixth phase

Added after the second decision, derived from making the change rather than designed ahead of it.

The repository's stated output is *"a proposed change to our standards and our skills"*. Five phases ran without ever producing one, because nothing carried a decision from the record to the document. `README.md` drew a stage called **Update** that was never built, and the implemented phases quietly replaced it.

Building it as `process/06-update/` was the obvious move and would have been wrong. Its only artifact would be a diff to a file that already exists, with a contract describing how to edit Markdown. The decision has already passed a human gate; applying it needs a link, not a phase.

So Update is **a field on the decision plus a reciprocal link on the claim**, and both halves are checked:

- the decision carries `amends:` naming and linking the document
- the amended claim carries `decided:` linking back to the record

A one-way pointer would be the duplicated-declaration failure again: the standard says one thing, the decision another, and nothing notices. `validate-decision.sh` refuses `amends-not-reciprocated` for exactly that.

**The pair is a decision and a claim, not a decision and a file.** `amends:` carries an `#anchor`, so it names the claim it changes, and the `decided:` link has to sit inside that claim — its subsections included, because a back-link under a deeper heading has not left the claim. The anchor was stripped before the comparison until 2026-10-04, so deleting §3's back-link and re-inserting the identical line in §7, while `amends:` still named §3, passed. The gate established that two documents pointed at each other and not that they pointed at the same claim.

**The anchor is required**, refused as `amends-no-claim` when it is absent. Without it the claim-level half of the check could be switched off by leaving the anchor out, which is the control-disabled-by-omission shape `AGENTS.md` rules against. An anchor the amended document carries no heading for is refused as `amends-claim-unresolved`: the record then names a claim that does not exist, so there is nothing for the two halves to agree about. The anchor is compared against the headings the document actually has, each one slugged the way a forge slugs it, rather than against a pattern. A fenced block is outside the claim, so a document can show what a back-link looks like without that example reciprocating the real thing.

**One document is amended more than once, and that is the ordinary case.** `STANDARDS.md` is *the* document decisions amend, so a second decision landing on a different claim in it is expected rather than exceptional. Each amended claim carries its own `decided:` link, and the check reads every one of them and asks whether any names the record under test. It read only the first until 2026-10-04, which made the second correctly-formed amendment refuse — with a message accusing a correct pair of disagreeing — and meant no further decision could land on `STANDARDS.md` at all. One amendment per document was never the rule; it was an artefact of reading one line.

**`amends: none` is valid and expected.** A decision to measure before acting changes nothing about how we work. Bare `none` is refused — `bare-none-amends` — because on its own it cannot be told apart from an oversight, which is the same reasoning as the Define contract requiring an empty outlier section to say it is empty.

**What this leaves open.** The stated output is standards *and skills*. Skills are not in this repository, so `amends` currently reaches one of the two, and saying so is better than implying coverage.

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

That is mechanical, cheap, and guards the only thing in the repository that cannot be reconstructed afterwards. Everything else about Deliver's shape was to wait for a second decision.

**Built**, as `validate-decision.sh`, with two companions that are equally shape-independent: a chosen option must exist in the option set it claims to choose from, and a decided record must be dated. A `decided_by` naming a role, a team or a model is refused as not a person.

Every refusal carries its own message and is asserted by that message in `tests/test_validate_decision.sh`.

**That deferral has been spent, and this said otherwise until 2026-10-04.** The second decision arrived on 2026-10-03, Deliver's shape changed because of it — `amends:` is a required field this contract added *"after the second decision"*, thirty lines above the sentence saying the shape still waits for one — and the gate grew to hold it:

```
$ bash bin/list-refusals.sh process/05-deliver/validate-decision.sh | wc -l
23
$ bash bin/list-refusals.sh process/05-deliver/validate-decision.sh \
    | cut -d: -f3 | grep -c amends
11
```

Eleven of the twenty-three emission sites are the `amends` family — seven distinct refusals covering the field's presence, a bare `none`, the link, the anchor, and the reciprocal link in both directions. None of that is shape-independent; all of it is Deliver's shape, derived from the second decision exactly as the deferral said it should be.

**What is still deferred, and now for a stated reason rather than a count.** The two questions under *Open* below — whether a decision needs a review period, and where a reversal lives — are not deferred for want of a second artifact. They are undecided, and a gate cannot be written for a rule nobody has stated. That is the honest form of this sentence: nothing is waiting on arithmetic.

**`expires` is declared and not yet enforced**, which is a different state from deferred: the field exists, `bin/next.sh` scaffolds it, `bin/cycle.sh` reports days to the nearest expiry, and no gate reads it. What would make gating it right is a second record carrying it, and the reasoning is above under *`expires`, and why a date in prose was not a tripwire*. A reporting tool is not a gate: the report makes the date visible to a person and refuses nothing.

<!-- declared-not-enforced: expires — no gate reads the field and none refuses a decision whose expiry has passed; bin/cycle.sh reports days to the nearest expiry and a report refuses nothing -->

**The declaration above is read by `bin/validate-controls.sh`.** Until 2026-10-04 the sentence before it was the only record of this anywhere, and `CONTROLS.md` — the document an assessor is told to start from — did not carry it at all. The binding between that document and the gates runs through refusal codes, and a field nothing enforces emits none, so an honest disclosure in prose was unrepresentable there. The marker makes it enumerable; the gate refuses when a declaration here is absent from that document, and when a row there names a declaration this contract no longer carries.

## Open

1. **Whether a decision needs a review period** before it binds, or takes effect when written.
2. **Where a reversal lives** — a new record superseding, or an append to the original. The contract forbids silent editing; it does not yet say what replaces it.
3. ~~**Whether the chosen option should be fed back into `STANDARDS.md`** when it changes how we work, and what keeps those two in step.~~ **Settled 2026-10-03** by the `amends:` field and the reciprocal `decided:` link, described above. Left struck through rather than deleted so the question and its answer stay next to each other.
