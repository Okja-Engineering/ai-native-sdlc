# Develop — producing themes

dated: 2026-09-30
problem: [`../../03-define/problems/producing-themes.md`](../../03-define/problems/producing-themes.md)
status: options developed, none chosen

**What this is.** The divergent half of the second diamond. Several genuinely different ways to produce themes, each with what it costs, what it assumes, and how it fails. Written so a reader can pick, not so they can agree with a preference.

**What this is not.** No recommendation, no ranking, no preferred option. Choosing is Deliver, which did not exist when this was written. *[Annotated 2026-10-03: Deliver was built, and this option set was decided — option F. The original sentence is preserved rather than corrected, for the reason above.]* If this document reveals which way the author leans, it has failed.

**These are different approaches, not settings on one dial.** Options that differ only by a threshold belong in one entry.

---

## A · Keep theming by hand, and cap the cadence to match

The convergence stays a person's job. Cadence is set by what a person will actually do — monthly, perhaps fortnightly — rather than by what the scan can afford.

**Costs.** One person's attention per cycle; the 64-finding pass took roughly the time of reading them plus the judgment. Caps the cadence at human throughput, which gives up the "because it becomes cheap, maybe daily" ambition.

**Assumes.** That cadence is negotiable, and that the value is in the themes being *right* rather than in them being *frequent*.

**Fails when.** Volume grows past a person's patience, or the cycle silently stops happening — the failure named in `intent.md`, where facing the work means the cycle quietly doesn't get run. That failure leaves no trace, which is what makes it dangerous.

**Would be right if.** The daily finding rate turns out to be small, or the themes prove hard to produce mechanically without losing the *why*.

---

## B · A large model proposes themes; a person accepts, edits or rejects

The themer drafts; the human stays the author. The artifact records that a model proposed and a person signed.

**Costs.** One substantial model call per cycle — real but not large. Human time drops from producing to checking, which is the cheaper half.

**Assumes.** That checking a grouping is meaningfully cheaper than making one. Plausible but **untested**, and anchoring runs the other way: a plausible wrong grouping is harder to reject than a blank page is to fill.

**Fails when.** The human rubber-stamps. This is the exact failure `STANDARDS.md` §3 describes — a reviewer talking itself into accepting — and the discovery this repo already ran found agents praise work they are shown. Being human does not exempt you from anchoring.

**Would be right if.** Draft quality is high enough that editing beats authoring, and the accept/edit/reject record is kept so rubber-stamping is visible as a rate rather than invisible.

---

## C · A small classifier assigns findings to a pre-declared theme set

Themes are declared up front, in a contract. Each finding is scored against them — the shape SemIf offers: supply the options, read probabilities. Cheap enough per item for any cadence.

**Costs.** Near-zero per finding; local inference, nothing leaves the machine, which matters in a regulated setting. The cost moves to maintaining the theme list and calibrating.

**Assumes.** That themes can be known in advance. **This is the load-bearing assumption and the first cycle contradicts it.** Theme 7 — people naming new disciplines — did not exist until the data produced it, and was only found because an accounting check forced a second pass over five unassigned items. A pre-declared set cannot discover a theme that is new.

**Fails when.** Something genuinely new arrives and gets filed under the nearest existing label. Also: the discovery established 27.8% flips on option reordering and 25.0% on meaning-preserving rewording, so the assignment is sensitive to how the themes are *phrased*, not only what they mean. And out of domain it claims ~90% confidence at ~64% accuracy, with calibration that does not transfer between workloads.

**Would be right if.** Themes prove stable across cycles and the job is really *assignment* rather than *discovery* — with something else responsible for noticing when a new theme is needed.

---

## D · Mechanical clustering first, naming second, person last

Group by similarity without pre-declared labels, have a model name each cluster and write its *why*, then a person checks. Discovery and naming are separated from each other.

**Costs.** Two steps instead of one, and a similarity measure to choose and maintain. More machinery than B, less than building a trained system.

**Assumes.** That findings cluster on something a machine can see. Untested here — the seven themes came from meaning ("these are all about review authority"), not from shared vocabulary, and two of them share almost no words.

**Fails when.** Clusters are coherent but not *useful* — grouping by source, date or format rather than by what a reader needs. A cluster of "all the arXiv preprints" is coherent and worthless.

**Would be right if.** The cluster-then-name split lets the outlier surface fall out naturally, since anything clustering with nothing is already identified rather than needing a separate rule.

---

## E · Produce fewer findings instead of summarising more

Leave the convergence alone and attack the input. Narrow the scan's sources, tighten what counts as a finding, or run it more often over shorter windows so each cycle is small enough to read directly.

**Costs.** Nothing to build. The cost is coverage — a narrower scan misses things, and the repo's own rules say an item dropped silently leaves no trace.

**Assumes.** That much of the 64 was not worth recording. The cycle gives some support: 16 of 64 were folded as routine tooling that does not change how a team works.

**Fails when.** Narrowing removes counter-evidence, which is the kind nothing markets and the kind `STANDARDS.md` already records us having missed once. A scan tuned for signal density drops quiet corrections first.

**Would be right if.** The folded 16 turn out to be genuinely inert across several cycles — which is checkable, since they are recorded rather than dropped.

---

## F · Do nothing yet, and measure first

Run two or three more cycles by hand, recording the finding rate, the time the pass takes, and which themes recur. Decide with data instead of one month.

**Costs.** Delay, and the hand cost paid two or three more times. Carries the risk in A: a cycle that is work may quietly not happen.

**Assumes.** That the cost of deciding wrong exceeds the cost of waiting. Defensible — every other option is cheaper to choose once the daily rate and theme stability are known, and both are unknown now.

**Fails when.** Waiting becomes the decision, which is how a thing quietly dies without anyone choosing to stop.

**Would be right if.** The next cycle or two answers the two open questions in the problem statement cheaply, which they plausibly would.

---

## The test that cuts across most of these

Several options turn on one unanswered question: **does a model, cheap or otherwise, produce these same seven themes from the same 64 rows?**

Both halves exist to compare — the source rows and a hand-made answer, with the hand-made one carrying a known defect that was caught and corrected, which makes it a better yardstick than a clean one would be.

Running that costs very little and would sharpen B, C and D considerably. It does not decide between them, which is why it is recorded here rather than treated as the answer.

## What none of these options solves

**The outlier surface.** Every option above produces themes; none has a good story for the item that fits nothing. A, B and F rely on a person noticing. C cannot by construction — a pre-declared set has no "none of these" that means *interesting*. D is the only one where it might fall out for free, and that is a hypothesis.

Given that the first cycle's most valuable finding was an outlier, this is a gap in the option set rather than a tiebreaker between them, and it is stated here so Deliver cannot choose without seeing it.
