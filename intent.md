# Intent

**Status:** draft, unaccepted.

## Why this exists

The accepted practice for building software with AI is changing faster than any team can track by reading. New capabilities land weekly, most published material about them is written by the vendor selling them, and the genuinely useful signal — *how are people actually changing the way they work?* — arrives as scattered releases, threads, talks, and posts.

Reading all of that is not a job anyone has. Not reading it means our way of working quietly drifts out of date, and we find out when something we should have adopted six months ago turns up in someone else's postmortem.

So: a repository that states how we work, and a process that keeps that statement true.

## What we want from it

**A shared vocabulary for a conversation.** The near-term reason this exists is so our team can argue productively about how we want to work. Naming the moves we already make — and the ones we've decided against — is most of the value.

**An honest statement of what's actually established.** Distinguishing an empirical result from a vendor's methodology from our own opinion. This matters more for us than most teams: we work in a high-risk regulated codebase, in a carved-out space where AI exploration is permitted on the condition it's done as controlled experiment rather than enthusiasm. "This is accepted practice" is a claim we have to be able to defend.

**Change detection with an opinion about consequence.** Not a news feed. A filter that says *this one matters to a software team, and here's the blast radius* — and stays quiet about the rest.

**The ability to change ourselves deliberately.** When something does matter, the output isn't a link. It's a proposed change to our standards and our skills, that a person accepts or rejects.

## What drives how we work here

If this repository documents AI-native practice, it has to be built the way we would defend. We take that from three existing sources rather than inventing one:

- **Agile** — working software over comprehensive documentation. Responding to change over following a plan.
- **Lean Startup** — build, measure, learn. Validated learning before more building.
- **XP** — communication, simplicity, feedback, courage, respect. Small releases. Test first. Refactor rather than accrete.

### Where we currently break them

A value with no tension named is decoration. These are real and they are ours:

| The value | How we break it | How we are resolving it |
|---|---|---|
| Working software over comprehensive documentation | Four documents existed before any working tool. Prose about the process has repeatedly outgrown the process | Tooling before more prose. A document that restates what a script computes gets deleted, not corrected |
| Simplicity | The scan keeps every finding in full, which is hard to defend as simple | Kept, but for a different reason — see the SOC 2 note below. Completeness of the record is a control, not a completeness habit |
| Small releases | One pull request has carried a research artifact, a problem statement, a contract change and two document rewrites | One capability per pull request. Split when it needs the word "and" |
| Communication | Pull request bodies were written in a voice no one speaks in, which made review slower | The structure and voice rules in [`AGENTS.md`](AGENTS.md) |
| Validated learning | We have built tooling on an n of 1 more than once | Decision F is the correction: measure two more cycles before building a themer |

### What SOC 2 changes

We work in a regulated environment, so one Agile value gets bounded rather than followed straight.

"Working software over comprehensive documentation" does not mean fewer records. An auditable change trail is not documentation about the work — it is part of the work. So the things that look like paperwork and are actually controls stay: a complete findings record, a decision naming a natural person, a date, a reason each rejected option was rejected.

The test we apply: **would an auditor ask for this?** If yes it stays and gets written as a control. If no, and it only describes what the code or a script already shows, it goes.

## What we think is true

Stated so they can be attacked. Graded, because not all of these are equally supported — the grades and sources are in [`STANDARDS.md`](STANDARDS.md).

| We assume | Support |
|---|---|
| The binding constraint is intent, verification and review — not generation | **Strongest thing we have.** Large-scale observational work shows the gain attenuating from commits toward shipped releases |
| Small, independently reviewable units are the right flow unit | **Practitioner consensus, unmeasured.** No source establishes a maximum reviewable size, including ours |
| A human checkpoint before risk expands beats one after | **Reasoned, not demonstrated.** Nothing we found tests the ordering |
| An agent cannot check its own work | **Our own repeated experience.** In one working session, four confident agent verdicts were wrong and only cross-checking caught them — including an agent that retracted a correct finding, and one that reported a file edit it never made |
| Naming what an agent must *not* do beats describing what it should | **From our own prototype.** Its safety story was prose claims about what skills would never do; an audit found most unenforced, including one that passed a merge receipt reading `findings: BLOCKING — auth bypass unpatched` |
| Tracking this by reading does not scale | **Assumption.** Untested. It is the premise of the whole repository and it could be wrong — we might find the signal rate is low enough to just read |

## What would mean it worked

- A finding reached us that we would otherwise have missed, and we changed something because of it.
- Someone on the team disagreed with a claim in `STANDARDS.md` and had something specific to point at.
- A month passed, the scan ran, and it correctly told us nothing important had happened.

That last one is the real test. A change-detector that always finds something is not detecting change.

## What this is not

- **Not autonomy.** The human gates are the product, not friction in front of it.
- **Not speed.** No claim about throughput, cycle time or velocity appears in this repository, and none should.
- **Not a standard for anyone else.** We're one team working out how we want to work. Portability is a nice property, not a goal.
- **Not a platform.** If it stops being a small number of readable files plus a scheduled job, something has gone wrong.

## Open questions

1. Does intent scope to a change, or does a monorepo also need standing intent per module — a promise the module makes that outlives any one change to it?
2. How much of this should be mechanically enforced versus written down and trusted? Our prototype drifted toward "enforce everything," and the enforcement outgrew the thing being enforced.
3. What cadence is right? Monthly is readable. Daily is affordable but needs a classifier good enough that it doesn't bury us — and a classifier that wrongly suppresses something is worse than no classifier.
