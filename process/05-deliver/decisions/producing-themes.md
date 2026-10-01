# Decision — producing themes

problem: [`../../03-define/problems/producing-themes.md`](../../03-define/problems/producing-themes.md)
options: [`../../04-develop/options/producing-themes.md`](../../04-develop/options/producing-themes.md)
chosen: F
decided_by: Matthew Van Dusen
dated: 2026-10-01

**Decided.** F — do nothing yet, and measure first, with a tripwire attached.

This is the first decision the loop has produced. Four phases ran before it: 64 findings scanned, seven themes and three outliers converged, one problem stated, six options developed with no recommendation. The choice below was made against that option set and nothing else.

---

## The options, in one line each

| | | |
|---|---|---|
| **A** | Hand-theme, cap the cadence | Costs attention every cycle. Fails if the cycle quietly stops happening |
| **B** | Model drafts, person signs | Cheaper to check than to author — **untested**. Fails by rubber-stamping |
| **C** | Small classifier, declared theme set | Near-free per item, runs locally. **Contradicted by cycle one** — cannot discover a theme that is new |
| **D** | Cluster, then name, then check | Only option where the outlier surface might fall out for free. Clustering basis **untested** |
| **E** | Produce fewer findings instead | Nothing to build. Risks dropping counter-evidence, which nothing markets |
| **F** | Measure two or three more cycles first | Answers the two unknowns cheaply. Fails if waiting becomes the decision |

Full text, with every cost, assumption and failure mode, is in the options file. This table is a reading aid and is **not** a ranking — the order is the order they were written.

---

## What was chosen, and why

**F, with a tripwire.** Two more cycles by hand, recording the finding rate, the time the convergence pass takes, and which themes recur. Then this record is superseded by one that chooses how themes get produced.

The reasoning is that **every other option is cheaper to choose correctly once two unknown numbers are known**, and both are cheap to get. The daily finding rate is unknown — one month is one data point, and options A and E both turn on whether 64 was typical or an artefact of a first pass sweeping a backlog. Theme stability across cycles is unknown, and B, C and D all depend on it: C is only viable if the job is assignment rather than discovery, and cycle one already contradicted that.

**The cross-cutting test is part of this decision, not a separate task.** Before the next cycle's convergence, run the comparison the option set names: does a model produce these same seven themes from the same 64 rows? Both halves already exist, including a hand-made answer carrying a known defect that was caught and corrected — which makes it a better yardstick than a clean one. This costs very little and sharpens B, C and D considerably. It does not decide between them, which is why it is a measurement here rather than an option.

**What makes this F and not drift** is the tripwire in *What would reverse this*. F without one is indistinguishable from the thing it fails at.

## What we are accepting

**F's stated failure: that waiting becomes the decision, which is how a thing quietly dies without anyone choosing to stop.** That is the cost being taken on, and it is a real one — `intent.md` names the same failure from the other direction, a cycle that silently stops happening because facing the work is work, and notes that such a failure *leaves no trace*.

Two more hand passes are also being accepted. The 64-finding convergence took roughly the time of reading them plus the judgment, and that is now being paid twice more before anything is built to reduce it. If the finding rate turns out to be much higher than 64 a month, that cost lands harder than this record assumes.

**This record does not get the benefit of the doubt on either.** The tripwire below is dated precisely so the first failure is detectable, and a missed tripwire is itself the evidence that F was the wrong call.

## Why not the others

- **A — keep it by hand, cap the cadence.** Not rejected on the merits; it is what F does for two more cycles. The difference is that A *settles* on human throughput as the permanent answer, and there is no evidence yet to settle that.
- **B — model drafts, person signs.** Rests on checking being cheaper than authoring, which is untested, and anchoring runs the other way. The test named above is largely a test of B, so choosing it now would be choosing before the cheap evidence arrives.
- **C — small classifier, declared theme set.** The load-bearing assumption is contradicted by the only cycle we have run. Theme 7 did not exist until the data produced it, and was found only because an accounting check forced a second pass. `intent.md` is blunter: a classifier that wrongly suppresses something is worse than no classifier.
- **D — cluster, then name.** The most interesting of the build options and the only one with any story for the outlier surface, but it assumes findings cluster on something a machine can see, and the seven themes came from meaning rather than shared vocabulary — two of them share almost no words. Worth revisiting with the test's output in hand.
- **E — produce fewer findings instead.** Attacks the input rather than the convergence, and collides with a rule this repository already holds: an item dropped silently leaves no trace that it was ever seen. The 16 folded as routine are recorded rather than dropped, so whether they are genuinely inert is checkable — which makes E a candidate *after* the measurement, not instead of it.

## What would reverse this

**This decision expires on 2026-11-30.** By then two further cycles should have run. On that date a successor record chooses a production method, and the choice is made with the finding rate, the pass duration and the theme recurrence in hand.

It reverses earlier than that on any of:

- **The comparison test comes back strongly either way.** If a model reproduces the seven themes closely, B moves to the front; if it produces a plausible but differently-shaped grouping, that is evidence about anchoring and B gets harder to choose, not easier.
- **A cycle is missed.** A scheduled cycle that does not happen is F's failure mode arriving, not a scheduling hiccup. One missed cycle ends F and forces the choice early with whatever data exists.
- **The finding rate roughly doubles.** If a cycle produces materially more than 64, the hand pass stops being affordable and the question becomes which build option rather than whether to wait.

A reversal is a **new record pointing at this one**, per the contract. This file is not edited to change its answer.

## What this does not settle

**The outlier surface.** No option in the set addresses the item that fits nothing, and choosing F does not create an answer — it defers the question alongside the rest. This matters more than its placement at the end of this record suggests: the first cycle's most valuable finding *was* an outlier, and D is the only option where a solution might fall out for free. If the measurement period produces a second valuable outlier, that is an argument about the option set rather than about this decision.

**Whether a decision needs a review period before it binds**, and **whether a chosen option feeds back into `STANDARDS.md`** — both open in the deliver contract, both untouched here.

**The cadence itself.** F says measure two more cycles; it does not say monthly is right. The cadence is currently whatever a person gets to, which is the same unexamined default it was before this decision.
