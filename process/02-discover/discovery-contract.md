# Discovery contract

**Status:** derived from one artifact, then tested against a second. `topics/classifier-models.md` was written first and this describes the shape it needed. `topics/agent-pr-approval.md` (2026-10-01) was the test.

**What the second topic showed.** The required sections all held on a question shaped differently — the first was *"is this substance or marketing"*, the second product mechanics with a partly documented answer. Nothing had to be added and nothing was dead weight. Two parts earned their place rather than merely surviving:

- **Quoting the question verbatim.** The second topic was selected because *"it has a clock"*, and discovery established the clock did not apply to the feature. Had the question been tidied, the artifact would have answered a question nobody asked and the falsified premise would have left no trace.
- **"Verified by hand", and the three-part coverage.** That topic ran two agent passes and the assembling author re-verified ten claims directly, correcting one — a reported 15% rate that recomputation put at 10%. Without a section separating *an agent reported this* from *someone checked it*, the wrong figure would have shipped as a fact.

**What turned out to be the first topic's accident.** *"Several independent passes, briefed to fail differently"* was written from a run of three. The second ran **two**: the first topic's third pass existed to advocate a counter-case against a marketing judgment and had nothing distinct to do on a mechanics question. The rule is the independence and the differing briefs; the number scales to the question. Corrected below.

**Gated**, as `validate-discovery.sh`, with every refusal asserted by message in `tests/test_validate_discovery.sh`. No count is stated here: the contract said twelve while the gate emitted seventeen, and a number in prose beside a number in code is the duplicated-declaration failure this repository keeps finding. `tests/test_controls.sh` checks that every refusal the gate emits is documented. Both shipped topics pass despite differing in markup, which is the property that mattered — a gate keyed to the newer artifact's formatting would have encoded its accidents as rules. See *The gate* at the end, including the two checks named here that turned out **not** to be mechanisable.

## What discovery is for

Taking a question the team actually has and establishing **what is true about it**, with every claim traceable and graded, so that a later phase can decide what to do without re-litigating the facts.

It is the divergent half of the first diamond. It goes wide, records what it finds, and stops.

## What it must never do

**Discovery contains no recommendation.** Not "we should", not "this suggests we", not a next step, not a preferred option. The moment an artifact says what to do, the decision has been made without a human gate — and Deliver, the phase that owns that decision, has been bypassed. This said *"the phase that owns that decision does not exist yet"* until 2026-10-03. Deliver is built, and it was the phase being referred to.

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

Grades are the `STANDARDS.md` scheme: `[E]` empirical · `[S]` standard · `[V]` vendor, never outcome evidence · `[P]` practitioner, unmeasured · `[O]` open. <!-- not-a-claim: this is the grade key, it declares what each marker means rather than using one -->

**No source, no claim.** Same rule as the scan, for the same reason.

**A vendor's claim is recorded as a claim.** *"X states Y"* is the finding. *"Y"* is not. This applies to a vendor disclosing its own limitation too — credit the disclosure, do not upgrade its class.

### What could not be established

A mandatory section, listing `[O]` items explicitly. Not a footnote.

This is the section a reader checks to find out whether the question was actually answered. In the worked artifact it carried the most consequential item of all — that the comparison the question implies *does not exist publicly and would have to be run.* An artifact with no `[O]` section is claiming completeness it has not earned.

**An item is a list item carrying its `[O]` grade.** A list item is a line beginning, flush left, with a list marker — `-`, `*`, `+`, `1.` or `1)` — followed by a space. The grade goes on that line.

```
- **Whether a Copilot approval satisfies `require_code_owner_review`. [O]**
- Whether a Copilot approval satisfies `require_code_owner_review`. [O]
1. Whether a Copilot approval satisfies `require_code_owner_review`. [O]
```

All three are items. Emphasis is a matter of taste and plays no part in the rule.

**A bold label is not a list marker**, so `**Whether … [O]**` with no bullet is not an item. Neither is an indented line — four spaces is a code block in Markdown, so a reader sees no item where a gate would have counted one — and neither is a line of prose carrying an `[O]` somewhere in it.

**This is the one statement of the rule, and [`define-contract.md`](../03-define/define-contract.md) cites it** for its Outliers section rather than restating it. Two sections in two phases are held to the same shape and two gates count them, so a rule written down twice is a rule that can drift — and did.

**Why the bold-label form was dropped on 2026-10-04.** This paragraph used to say the marker *"may be a bullet, a number or a bold label — the two shipped topics differ on that and both are within the contract"*, and in the next sentence that *"a line of prose carrying an `[O]` somewhere in it is not one."* The gate implemented the first sentence. So a bold-led sentence counted as an open item, including `**Nothing remains open.** … the grade [O] is not used in this artifact.` — a line denying the grade satisfying a check for an item carrying it, which emptied the section this contract calls the one a reader checks.

The distinction the paragraph was reaching for is real: a bold label used *as a label*, with the grade inside it, is not a sentence that mentions the grade. It can be drawn mechanically here, because an item in this section carries a grade. **It cannot be drawn in the Outliers section at all**, because an outlier carries no grade and there is nothing there to anchor it to. A form only one of the two gates can police is how the two came to disagree, so the form both can police is the one that survives. One shipped topic wrote its seven items as bold labels and they now carry a bullet; no sentence in them changed.

**Why the rule is not narrower than this.** `- **` was the obvious answer — it is what the Define gate already counted and what all three shipped artifacts write, and it loosens nothing. It was rejected because no sentence can say *why* bold, which would make one artifact's markup the rule for two gates. That is the failure this contract deferred its gate to avoid in the first place. A bullet has a reason behind it: it is what makes the line a list item.

**An empty section is permitted, and it declares itself empty.** A phase that genuinely left nothing open is a real state. Saying so is a declaration in the section, naming the reason:

`<!-- declared-empty: every question in scope was answered, and the searches that found nothing are recorded under Coverage -->`

Same shape as `<!-- not-a-claim: … -->` and `<!-- dead-pointer: … -->` in `STANDARDS.md` and `SOURCES.md`, and the same two things are checked: the declaration is present, and it carries a reason. **Inside a fenced block it declares nothing**, so an artifact that shows the reader what the form looks like does not thereby satisfy it. **A sentence is not a declaration**, and that distinction is the whole of why this is written down. Until 2026-10-04 the gate searched the section's prose for one of three short words, so an artifact could delete all seven of its items, write *"the discovery was exhaustive and nothing of consequence remains outstanding"*, and pass on the word "nothing". The declared form cannot be arrived at by accident, which is the only property that makes the section load-bearing.

**What the declaration does not establish.** That nothing was found. It records that the author says the section is empty and why; whether that is true is a reader's job, and `CONTROLS.md` carries it under *what is not controlled*.

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

## The gate

Built as `validate-discovery.sh` once discovery had run twice on differently shaped questions, which was the condition this contract set for itself.

**Two of the four checks this section used to call mechanical are not.** Writing the gate is what established that, and it is recorded rather than quietly dropped:

| The check this contract named | Outcome |
|---|---|
| every claim carries a grade from the enum, and a source | **Not mechanisable.** See below |
| the `[O]` section exists and is not empty without declaring why | Built — `no-open-section`, `silent-empty-open` |
| no recommendation language appears anywhere | **Deliberately not built.** See below |
| the required sections are present, including *verified by hand* | Built — `no-question`, `no-coverage`, `no-not-reached`, `no-verified-by-hand`, `no-where-this-stops` |

**Why "every claim carries a grade and a source" is not mechanisable.** It needs a claim to be a delimited thing. The two topics write claims as prose paragraphs in different markup — one uses bare `[E]`, the other bold `**[E]**` — with no boundary a script can find. Checking it would mean inventing a claim convention mid-gate and then testing both artifacts against a rule neither was written to. What is checked instead is narrower and honest: that every grade *used* is from the enum, that the enum is declared, and that the artifact carries graded claims at all. <!-- not-a-claim: this quotes the two markup forms the topics use in order to explain why a grade cannot be gated here, it grades nothing -->

**Why "no recommendation language" is deliberately not built.** It looks like the easiest of the four and is the trap. A pattern match on *recommend* fires on the sentence *"No option set, no recommendation, no decision"* — a correct disclaimer flagged as the thing it disclaims, which happened while self-checking the second topic. The real failure is a neutral-sounding paragraph that steers, which no pattern catches. Mechanising the proxy would spend reader trust on false positives while the actual failure walks through. `tests/test_validate_discovery.sh` asserts the gate does **not** refuse on it, so a later edit cannot quietly add it back.

**Section presence is matched loosely on purpose.** The two topics carry the same required sections in different form — `## 5 · What we could not establish` with bold inline labels in one, `## What could not be established` with `###` subheadings in the other. A gate keyed to exact headings would have made the newer artifact's markup the rule, which is exactly what deferring the gate was meant to avoid.

**One portability note, recorded because it nearly shipped.** The first version used `\?` in a `sed` address. That is a GNU extension to basic regular expressions: BSD `sed` does not support it, so the range matched nothing on macOS and the gate refused every artifact, while passing on the Linux CI leg. Same class of bug as `\b` in `git grep`, found the same way — by running it on both. The gate now uses only POSIX constructs and runs on both legs in CI.
