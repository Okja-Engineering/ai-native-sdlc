# Stage 1 — Scan

**Status:** specified, and partly built. The record shape is declared in [`findings-contract.md`](findings-contract.md) and a gate refuses a file that breaks it ([`validate-findings.sh`](validate-findings.sh)); the cycle itself is a written instruction a person runs ([`scan.md`](scan.md)). Nothing is scheduled and no classifier exists.

This document remains the specification, and the place to argue with the stage.

**Authority:** none. This stage reads, records, and stops. It does not assess impact, does not rank, does not decide, and cannot advance anything. Everything downstream is behind a human gate.

## The question it asks

> Since we last looked, what has come out about how AI-native teams build software — and has anyone actually changed the way they work because of it?

The second half is the point. A release note tells you a capability shipped. It does not tell you whether it matters. What matters is a team saying *"we moved our review gate,"* or *"we stopped doing X because the model handles it now,"* or *"we tried this and it made things worse."*

## What it looks for

| Kind | Example |
|---|---|
| **Release or capability** | a platform ships something that changes what's possible in a lifecycle stage |
| **Practice change** | a team describes changing how they work, and why |
| **Milestone or event** | something that shifts what's considered normal |
| **Counter-evidence** | a study, retraction, or supersession that undercuts something we currently believe |
| **Sentiment shift** | a previously-accepted practice now widely argued against |

**Counter-evidence is the highest-value kind and the easiest to miss**, because nothing markets it. `STANDARDS.md` already carries one: METR publicly superseded their own widely-cited slowdown figure, five months before our research reviewed it, and the corpus recorded no supersession. A scan that only finds new things is half a scan.

## Sources

| Source | What it's good for | What it's bad for |
|---|---|---|
| **The web** — vendor docs, release notes, engineering blogs, papers | knowing what shipped, and when | almost all of it is written by whoever is selling it |
| **X** | practitioners saying what they actually changed; sentiment turning | unrepresentative, confidently wrong, no durability |
| **YouTube** — talks, conference sessions, walkthroughs | the long-form "here's how we actually work now" that nobody writes down | slow to search, hard to cite precisely |

Each source is weak in a way the others are not, which is why the list has three entries rather than one.

**Unsettled:** the specific source list, whether paid search or fetch is in scope, and the per-cycle cost. One tool named in discussion did not transcribe cleanly and is deliberately not guessed at here — a wrong tool name in a standards document is worse than a missing one.

## What it produces

One findings file per cycle, at `process/01-scan/findings/<YYYY-MM-DD>.md`.

Each finding carries, and carries nothing more:

| Field | Why |
|---|---|
| `what` | one sentence, plain |
| `source` | a URL or a precise citation. **A finding with no resolvable source is not a finding** |
| `dated` | when the thing happened, not when we found it |
| `kind` | from the table above |
| `might affect` | which lifecycle stage(s), as a guess, explicitly labelled a guess |
| `consequence guess` | high / medium / low / unclear — **an opening bid for the human, not a verdict** |

And per cycle:

- **`nothing found`** as a first-class, valid outcome. A scan that always finds something is not detecting change.
- **`looked at`** — the ground actually covered, so a reader can tell a quiet month from a shallow scan. Without this, the two are indistinguishable, and that ambiguity is where a scan rots.

## What it must not do

- **Must not assess impact.** "What does this mean for us" is stage 2, behind a human gate. A finding that arrives pre-assessed has skipped the gate.
- **Must not rank or filter to a top N.** Suppression is a judgment; at monthly cadence there is no need for it, and when a classifier does arrive its decisions must be recorded, not implied by absence.
- **Must not present a vendor's claim as an outcome.** A vendor saying their tool improves something is a *finding about what a vendor claims*, graded accordingly. `STANDARDS.md` has the grading scheme.
- **Must not report a finding it cannot source.** No source, no finding.
- **Must not advance anything.** It writes a file and stops.

## Where it stops

A human reads the findings file and, per finding, decides: **interesting** → stage 2 · **not interesting** → dismissed, recorded with a reason · **later** → parked.

A dismissal is recorded rather than deleted, for two reasons: next cycle needs to know we already looked, and a classifier's mistakes are only discoverable if its decisions leave a trace.

## How we'd know this stage is working

- It surfaced something we would have missed, and we acted on it.
- It correctly reported a quiet period instead of manufacturing a finding.
- Its dismissals, read back three months later, still look right.
- A finding's source resolved when someone checked it.

## Settled in building it

1. **"Since we last looked" anchors to the most recent file in `findings/`**, skipping any marked `example: yes`. No state outside git. An empty directory is a first run, which records `since: first run` and covers the thirty days before the cycle date.
2. **A finding is a row** in a per-cycle file. Revisit on volume.
3. **One agent per source**, merged into one cycle file. Different sources fail differently, and one agent averaging three failure modes reports the average.

## Open

1. How a superseded finding is recorded — amended in place, or a new finding that points at the old one. This matters, because supersession is the kind we most want to catch and the kind most likely to be quietly overwritten. Nothing in the contract settles it yet.
2. The specific source list — one tool named in discussion did not transcribe cleanly and is deliberately not guessed at — and whether paid search or fetch is in scope, and at what cost per cycle.
3. Where a dismissal is recorded. This stage writes findings and stops; the assess stage does not exist.
