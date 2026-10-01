# Decision — producing themes

problem: [`../../03-define/problems/producing-themes.md`](../../03-define/problems/producing-themes.md)
options: [`../../04-develop/options/producing-themes.md`](../../04-develop/options/producing-themes.md)
chosen: pending
decided_by:
dated:

**Awaiting a human.** Six options are open. The work up to this point is done; the gate has not been passed.

This file is drafted rather than decided, which is a valid state the contract names. `bin/cycle.sh` reports it as `AWAITING A HUMAN`, and that is the honest reading — nothing here should be read as a choice until `chosen:` and `decided_by:` are filled by a person.

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

## What the decider should know before choosing

**Two facts are missing and both are cheap to get.** The daily finding rate is unknown; one month is one data point. And nobody has tested whether a model produces these same seven themes from the same 64 rows, although both halves exist to compare. Options B, C and D all turn partly on that second one.

**No option answers the outlier surface**, and the first cycle's most valuable finding was an outlier. Whatever is chosen leaves that open, and the decision record should say so rather than imply the problem is closed.

**The repository's own history leans one way.** Its predecessor died of building faster than it validated, and the standards document it ships says determinism should be earned by observation rather than allocated in advance. That is context for a decision, not a steer toward F — the opposite failure, a cycle that quietly stops because it is work, is named in `intent.md` and is just as real.

---

## What was chosen, and why

*To be completed by the decider.*

## What we are accepting

*Every option carries a failure mode. This names the one being taken on.*

## Why not the others

*One line each, for the five not chosen.*

## What would reverse this

*A date, a measurement, or an event.*

## What this does not settle

The outlier surface, which no option in the set addresses.
