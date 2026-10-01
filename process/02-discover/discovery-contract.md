# Discovery contract

**Status:** derived from one artifact, then tested against a second. `topics/classifier-models.md` was written first and this describes the shape it needed. `topics/agent-pr-approval.md` (2026-10-01) was the test.

**What the second topic showed.** The required sections all held on a question shaped differently — the first was *"is this substance or marketing"*, the second product mechanics with a partly documented answer. Nothing had to be added and nothing was dead weight. Two parts earned their place rather than merely surviving:

- **Quoting the question verbatim.** The second topic was selected because *"it has a clock"*, and discovery established the clock did not apply to the feature. Had the question been tidied, the artifact would have answered a question nobody asked and the falsified premise would have left no trace.
- **"Verified by hand", and the three-part coverage.** That topic ran two agent passes and the assembling author re-verified ten claims directly, correcting one — a reported 15% rate that recomputation put at 10%. Without a section separating *an agent reported this* from *someone checked it*, the wrong figure would have shipped as a fact.

**What turned out to be the first topic's accident.** *"Several independent passes, briefed to fail differently"* was written from a run of three. The second ran **two**: the first topic's third pass existed to advocate a counter-case against a marketing judgment and had nothing distinct to do on a mechanics question. The rule is the independence and the differing briefs; the number scales to the question. Corrected below.

**Still no gate**, and the reason has changed. It is no longer that one artifact cannot separate shape from accident — two now can, for the sections. It is that the checks worth mechanising are the ones a careful reader will not reliably perform, and the second topic is what showed which those are. See *Why there is no gate* at the end.

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

**Several independent passes, briefed to fail differently.** Separately briefed, no shared context. The first topic ran three — technical novelty, claims-and-practice, and the counter-case. The second ran two — mechanics and the counter-case.

**The counter-case pass is the one that does not scale away**, because *nothing markets a limitation*: without a pass whose only job is finding reasons not to, the others will not find them. It earned its place on the second topic too, where it independently caught that the feature's supposed deadline did not apply to it.

**The number of other passes scales to the question.** Three was right when the question was "is this substance or marketing" and the counter-case needed an advocate against a judgment. Two was right for product mechanics with a partly documented answer; a third pass had nothing distinct to do. A pass with no angle of its own is overhead that produces agreement.

**Both passes corrected their own briefs on the second topic**, and both corrections were more consequential than the findings they were sent for. A brief that cannot be contradicted by the pass it commissions is not a brief, it is an instruction to confirm.

**A pass reporting against its own angle is recorded, not quietly dropped.** The counter-case pass found two things that undercut its own brief — that a suspected failure mode was contradicted by the evidence, and that a body of literature cut in favour of the design. Both are in the artifact. A pass that only ever confirms its own angle is not a pass, it is an advocate.

**A pass correcting the brief is recorded.** The counter-case brief asked whether 0.813 was "barely above guessing for a two-option decision." It is a three-option task, so chance is 0.333 and the premise was wrong. The correction is in the artifact because the brief's error would otherwise propagate into every downstream phase.

**`nothing found` is a result.** *"No one has published an account of running SemIf in production. Not one."* is one of the most useful lines in the artifact. An absence, stated plainly and with the search that failed to find it, beats a padded list.

**Numbers get recomputed where the data is public.** The counter-case pass did its own arithmetic on committed prediction files rather than restating the project's tables. Two of those recomputations changed what the headline meant.

## Why there is no gate

The scan has one because it runs monthly and produces a comparable artifact each time, so a drift in shape is a real risk worth mechanising against.

Discovery has now run **twice**, on questions shaped differently, and the sections held both times. That removes the original reason to wait — but it does not by itself argue for a gate.

**What the second run changed is which checks are worth mechanising.** A gate earns its place where a careful reader will *not* reliably catch the failure. On that test the four checks below separate into two kinds:

- **Worth mechanising.** A missing grade, a claim with no resolving source, an absent `[O]` section. These are countable, a reader skims past them, and the second topic carried 55 graded claims — past the point where checking by eye is dependable.
- **Not safely mechanisable.** "No recommendation language" looks like the easiest of the four and is the trap. A grep for *recommend* fires on the sentence *"No option set, no recommendation, no decision"* — a correct disclaimer flagged as the thing it disclaims. The real failure is a neutral-sounding paragraph that steers, which no pattern catches. Mechanising the proxy would spend trust on false positives while the actual failure walks through.

The prototype's central failure was building enforcement faster than the thing being enforced. The remaining argument for waiting is narrower than it was: a gate on the countable three is defensible now, and the fourth should stay a reader's job.

What a gate should check when it is written, all of which are mechanical:

- every claim carries a grade from the enum, and a source
- the `[O]` section exists and is not empty without saying why
- no recommendation language appears anywhere
- the required sections are present, including *verified by hand*

**Until then this contract is asserted, not enforced**, and should be described that way.
