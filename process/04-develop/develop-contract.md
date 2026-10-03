# Develop contract

**Status:** derived from one artifact. `options/producing-themes.md` was written first; this describes the shape it turned out to need.

**No gate yet.** See *Why there is no gate* at the end.

## What Develop is for

Taking a stated problem and producing **several genuinely different ways to answer it**, each with its cost, its assumption, and how it fails — so that choosing is a decision made with the alternatives visible rather than a preference ratified after the fact.

It is the divergent half of the second diamond. Define converged. Develop opens back up, deliberately, before Deliver closes it for good.

## The rule everything else follows from

**Develop does not choose, and must not reveal a preference.**

No recommendation, no ranking, no ordering that implies merit, no option written weakly so another looks strong. The test: a reader should finish able to pick, and unable to tell which one the author would pick.

This is harder than it sounds and it is the thing most likely to decay. An author who has already decided writes five options and one answer wearing an option's clothes. If that happens the phase is theatre — the decision was made in Develop and Deliver only signed it.

## Required fields

| Field | |
|---|---|
| `dated` | when Develop was run |
| `problem` | the stated problem it diverges from, linked. **An option set without a problem is a wish list** |
| `status` | `options developed, none chosen` |

## Required of each option

| | |
|---|---|
| **What it is** | one paragraph, concrete enough to act on |
| **Costs** | what it actually takes — effort, money, attention, coverage given up. "Low cost" is not a cost |
| **Assumes** | the belief it rests on, and **whether that belief is established or untested**. The worked artifact marks two assumptions as untested and one as contradicted by the first cycle |
| **Fails when** | the conditions under which it is the wrong choice. An option with no failure mode has not been thought about |
| **Would be right if** | the condition that would make it the answer. This is what lets a reader match an option to their situation instead of to the author's argument |

## Rules the worked artifact established

**Options must be genuinely different, not settings on a dial.** Anything differing only by a threshold belongs in one entry. The point of diverging is to cover the space, and five variations of one approach cover nothing.

**An option may be contradicted by evidence already held, and that is stated rather than softened.** In the worked artifact, option C rests on themes being knowable in advance, and the first cycle produced a theme that did not exist until the data made it — found only because an accounting check forced a second pass. Saying so plainly is what makes the option set honest; quietly dropping C would have hidden a real possibility, and arguing around the contradiction would have been advocacy.

**"Do nothing yet, and measure" is a real option and is written like one.** It gets the same four fields as the others, including a failure mode — waiting becoming the decision. Omitting it biases the set toward action, and in a repository whose own history is over-building, that bias is the one to guard.

**A test that cuts across options is recorded, not used to pick.** The worked artifact names one experiment that would sharpen three of six options, and explicitly says it does not decide between them. A test treated as the answer is a decision smuggled into Develop.

**What no option solves is stated.** The worked artifact's option set has no good answer for the outlier surface — the thing the first cycle showed mattered most. That is a gap in the set, not a tiebreaker, and naming it stops Deliver choosing without seeing it.

## What Develop must never do

- **Choose.** Including by implication, ordering, or asymmetric effort.
- **Invent a problem.** It diverges from a stated one; if the problem is wrong, that is Define's to fix.
- **Hide an option it dislikes.** An option the author thinks is bad gets its fair version and an honest failure mode.
- **Claim evidence it does not have.** An assumption marked established must point at something.

## Why there is no gate

Develop has run once, on one problem, in one shape. A gate now would encode this problem's accidents — six options suited a build-or-wait question, and a problem with two real alternatives would look nothing like it.

What a gate should check when a second problem shows which parts are real, all mechanical:

- `problem` is declared and resolves
- every option carries all four required sections
- no decision or preference language — the vocabulary the scan's `assessment` check already refuses, plus comparatives like "best", "clearly", "obviously"
- at least one option is a do-nothing or defer option
- a "what none of these solves" section exists, and says so explicitly when empty

**Until then this contract is asserted, not enforced**, and should be described that way.

## Open

1. **Whether option count should be bounded.** Six felt close to the limit of what stays comparable. Too few is not diverging; too many is a catalogue nobody reads — the same reading-wall problem Define exists to solve, reappearing one phase later.
2. **Whether Develop should be run more than once on a problem**, as new evidence lands, or produced once and closed.
3. **Where the choice gets recorded.** Settled: `process/05-deliver/`, which did not exist when this was written. An option set resolves to a decision record naming the person who chose.
