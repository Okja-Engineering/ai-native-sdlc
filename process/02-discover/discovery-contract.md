# Discovery contract

**Status:** derived from one artifact, not designed in advance. `topics/classifier-models.md` was written first; this describes the shape it turned out to need. A second topic will show which parts are real and which are that topic's accidents.

**No gate yet.** See *Why there is no gate* at the end — that is a deliberate call, not an omission.

## What discovery is for

Taking a question the team actually has and establishing **what is true about it**, with every claim traceable and graded, so that a later phase can decide what to do without re-litigating the facts.

It is the divergent half of the first diamond. It goes wide, records what it finds, and stops.

## What it must never do

**Discovery contains no recommendation.** Not "we should", not "this suggests we", not a next step, not a preferred option. The moment an artifact says what to do, the decision has been made without a human gate — and the phase that owns that decision does not exist yet.

The test: a reader should finish the artifact able to reach their own conclusion, and unable to tell which one the author reached.

## Required fields

| Field | |
|---|---|
| `dated` | when discovery was run |
| `status` | `discovery complete, not assessed` — or what is still open |

## Required sections

### The question, in the asker's own words

Quoted, not paraphrased. `classifier-models.md` quotes *"it kind of feels like really good marketing"* — the skepticism is a load-bearing part of the question, and a tidied-up restatement would have lost it. A discovery that answers a cleaned-up version of the question answers a different question.

### Coverage — in three parts, not two

**Reached** · **Not reached** · **Verified by hand**

The third is the one that matters and the one a findings-style coverage line does not have. It separates *an agent reported this* from *someone checked it*. In the worked artifact, the mechanism claim was verified by reading two codebases side by side rather than by trusting a summary — and that verification is what turned the headline finding from a report into a fact.

A discovery artifact without a "verified by hand" section is a pile of agent output.

### Claims, each with a grade and a resolving source

Grades are the `STANDARDS.md` scheme: `[E]` empirical · `[S]` standard · `[V]` vendor, never outcome evidence · `[P]` practitioner, unmeasured · `[O]` open.

**No source, no claim.** Same rule as the scan, for the same reason.

**A vendor's claim is recorded as a claim.** *"X states Y"* is the finding. *"Y"* is not. This applies to a vendor disclosing its own limitation too — credit the disclosure, do not upgrade its class.

### What could not be established

A mandatory section, listing `[O]` items explicitly. Not a footnote.

This is the section a reader checks to find out whether the question was actually answered. In the worked artifact it carried the most consequential item of all — that the comparison the question implies *does not exist publicly and would have to be run.* An artifact with no `[O]` section is claiming completeness it has not earned.

### Where this stops

What a later phase will need that this phase could not supply, recorded so it is not rediscovered.

## Rules the worked artifact established

**Several independent passes, briefed to fail differently.** Three passes, separately briefed, no shared context — technical novelty, claims-and-practice, and the counter-case. The counter-case pass exists because *nothing markets a limitation*: without a pass whose only job is finding reasons not to, the other two will not find them.

**A pass reporting against its own angle is recorded, not quietly dropped.** The counter-case pass found two things that undercut its own brief — that a suspected failure mode was contradicted by the evidence, and that a body of literature cut in favour of the design. Both are in the artifact. A pass that only ever confirms its own angle is not a pass, it is an advocate.

**A pass correcting the brief is recorded.** The counter-case brief asked whether 0.813 was "barely above guessing for a two-option decision." It is a three-option task, so chance is 0.333 and the premise was wrong. The correction is in the artifact because the brief's error would otherwise propagate into every downstream phase.

**`nothing found` is a result.** *"No one has published an account of running SemIf in production. Not one."* is one of the most useful lines in the artifact. An absence, stated plainly and with the search that failed to find it, beats a padded list.

**Numbers get recomputed where the data is public.** The counter-case pass did its own arithmetic on committed prediction files rather than restating the project's tables. Two of those recomputations changed what the headline meant.

## Why there is no gate

The scan has one because it runs monthly and produces a comparable artifact each time, so a drift in shape is a real risk worth mechanising against.

Discovery has run **once**. A gate written now would encode this topic's accidents as rules — a section ordering that suited a "is this new or marketing" question may be wrong for a question shaped differently. The prototype's central failure was building enforcement faster than the thing being enforced, and this is exactly where that would start.

What a gate should check when it is written, all of which are mechanical:

- every claim carries a grade from the enum, and a source
- the `[O]` section exists and is not empty without saying why
- no recommendation language appears anywhere
- the required sections are present, including *verified by hand*

**Until then this contract is asserted, not enforced**, and should be described that way.
