# Develop contract

**Status:** derived from `options/producing-themes.md`, which was written first, and **not re-derived against the second artifact.** This said *"derived from one artifact"* until 2026-10-04, by which time `options/agent-pr-approval.md` had existed since 2026-10-03. What the second artifact showed is recorded under *Why there is no gate*; the body of this contract is still the shape the first one turned out to need.

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

**The reason this section used to give has expired, and the new reason is weaker.** It said *"Develop has run once, on one problem, in one shape"*, and that a gate would encode one problem's accidents. Develop has run twice:

```
$ ls process/04-develop/options/
agent-pr-approval.md  producing-themes.md
$ sed -n 's/^dated:[[:space:]]*//p' process/04-develop/options/*.md | head -2
2026-10-03
2026-09-30
```

The second artifact was written on 2026-10-03, three days after the first, and nothing re-read this sentence. So the deferral's condition — a second problem showing which parts are real — was spent while the contract went on claiming it was not. **The honest reason there is no gate now is that nobody has decided to build one**, which is a different statement and belongs on the record as one.

### What the second artifact showed

The condition did its job. Measured over both option sets:

- **Held in both.** The three required fields; six options each, headed `## A · …` through `## F · …`; a do-nothing or defer option, at F in both; a section naming the test that cuts across options; and a *what none of these options solves* section.
- **Held in both, as a labelled field.** Four of the five things required of an option — *Costs*, *Assumes*, *Fails when*, *Would be right if* — are written as `**Costs.**` and so on in both artifacts.
- **Did not hold.** *What it is.* `agent-pr-approval` labels it `**What it is.**` six times; `producing-themes` writes it as the option's unlabelled opening paragraph, zero times. Both satisfy what this contract asks for. A gate keyed to the label would have made the newer artifact's markup the rule, which is the exact failure the Discover gate records avoiding, and the reason this deferral was worth having.

```
$ for f in process/04-develop/options/*.md; do grep -c '^\*\*What it is' "$f"; done
6
0
```

### What a gate could now check, and what it still could not

All mechanical, and all now derivable from two artifacts rather than one:

- `problem` is declared and resolves
- every option carries *Costs*, *Assumes*, *Fails when* and *Would be right if*
- at least one option is a do-nothing or defer option
- a *what none of these options solves* section exists, and declares itself empty when it is — the declared form `<!-- declared-empty: reason -->`, which `discovery-contract.md` and `define-contract.md` already use, rather than a search of its prose for a word
- **not** *what it is*, because the two artifacts write it differently and both are correct
- **not** "no decision or preference language". The Discover contract already records why a pattern match on this class is the trap: it fires on a correct disclaimer, and the real failure is a neutral-sounding paragraph that steers. The rule this contract calls *the thing most likely to decay* is the one a gate cannot hold.

**Whether to build it is the owner's.** It is surfaced here rather than built: the cost is a gate, a control in `CONTROLS.md` to claim its refusals, and a suite, against a repository whose machinery already outweighs its output several times over. What `CONTROLS.md` records in the meantime is that Develop has no gate and why — see *what is not controlled*, item 5.

**This contract is asserted, not enforced**, and should be described that way. The risk that carries is named above: an author who has already decided writes five options and one answer wearing an option's clothes, and nothing here would notice.

## Open

1. **Whether option count should be bounded.** Six felt close to the limit of what stays comparable. Too few is not diverging; too many is a catalogue nobody reads — the same reading-wall problem Define exists to solve, reappearing one phase later.
2. **Whether Develop should be run more than once on a problem**, as new evidence lands, or produced once and closed.
3. **Where the choice gets recorded.** Settled: `process/05-deliver/`, which did not exist when this was written. An option set resolves to a decision record naming the person who chose.
