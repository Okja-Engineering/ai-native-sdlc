# Spec — V0

**Status:** this described V0 before V0 was built, and said so — "draft, unaccepted. Nothing downstream of this is authorized." That stopped being true. Five phases, two decisions, five gates and a standards amendment are downstream of it. The forward-looking framing is replaced below; what V0 turned out to be is in `README.md`, and where any cycle has got to is `bin/cycle.sh`.

Derived from [`intent.md`](intent.md). Scoped deliberately small at the time: state the intent, capture the research, specify **stage 1 only** — so the stage could be argued with before it was written. All five phases have since been built.

## What V0 is

Originally scoped as four documents and one stage specification, with no code. It did not stay that way: there are five phases, five gates, two tools and a CI workflow. The table below says what each piece is for, which is stable; it no longer claims what exists, which was not.

| Deliverable | What it is for |
|---|---|
| `intent.md` | Why this exists, what we believe, how sure we are |
| `STANDARDS.md` | How mature AI-native teams work, as of a date, with a grade on every claim |
| `spec.md` | This document |
| `README.md` | The loop, and what each piece is for |
| `process/01-scan/` | Record what changed since we last looked. Rank nothing, drop nothing |
| `process/02-discover/` | Establish what is true about one question, graded and sourced. Recommend nothing |
| `process/03-define/` | Converge a cycle into themes, and a theme into a stated problem |
| `process/04-develop/` | Diverge a problem into options, with each one's failure mode |
| `process/05-deliver/` | Converge on one choice, made by a named person, with the accepted cost written down |
| `bin/cycle.sh` | Where every cycle is and what is missing. Reads the tree, writes nothing |
| `bin/next.sh` | Start the next artifact, with its shape read from the contract that declares it |

**Where each phase has actually got to is not written here.** Run `bin/cycle.sh`. It reads the tree rather than a hand-maintained register — which removes one class of staleness, not all of them. See the note in `README.md`: the phrase "correct by construction" was an overclaim and is retired.

That is a deliberate repair, not an omission. This section previously carried hand-typed counts — findings, themes, options, how many times a phase had run — duplicating what `cycle.sh` already computes. It went stale three times in days, was caught by a reader every time and by a check never, and the response each time was to correct the copy and add a note observing that it keeps happening. Documenting a symptom three times is not fixing it. The duplicate is gone, so there is nothing left to go stale.

## What V0 is not

There is still no classifier, no CLI, no MCP server, and no scheduled job. Nothing runs on its own; a person starts every cycle.

**Nothing here produces a judgement.** `next.sh` writes a skeleton and the gates refuse that skeleton until a person fills it in. That is the line being held, not a gap waiting to be closed.

**Most phase contracts were written after the artifact they describe**, from what that artifact turned out to need, and each is asserted rather than enforced until a second, differently shaped artifact shows which parts were real. Where a gate exists, it checks only what does not depend on shape.

> **"Each" was too strong, and git says so.** Define, Develop and Discover hold the claimed order. Scan does not — `67a85aa` declared the contract before `d6da793` added the worked example. Deliver's contract landed one second before its first record, so the two were one batch and `deliver-contract.md`'s specific claim that "the record was drafted first" is unverifiable from the repository, with git's only testimony against it. Three of five, stated for five. Found by an external audit.

## The loop

**Drawn once, in [`README.md`](README.md#the-loop).** It used to be drawn twice — here and there — and the two copies disagreed with each other and with `process/` for five phases of real work. One drawing is the declaration; this section says what the drawing does not.

**A stage produces one artifact and stops.** No phase advances anything.

**A dismissal is an outcome, not an absence.** "Not interesting" gets recorded with its reason, because next cycle we need to know we already looked — and because a classifier that suppresses something important is only discoverable if its decisions are written down. The same reasoning covers a parked item and a rejected proposal: both are recorded, neither is silently dropped.

**Deliver is itself the last human gate.** A decision requires a named natural person; `validate-decision.sh` refuses a role, a team or a model name. That is the one place in the loop where the thing actually turns.

## Stage 1 — the scan

Specified in [`process/01-scan/README.md`](process/01-scan/README.md). In summary:

**Asks:** since we last looked, what has come out about how AI-native teams build software? Releases, milestones, notable events, and — the part that matters most — *how people are actually changing their way of working in response.*

**Sources:** the web, X, YouTube. A release note tells you a capability shipped; a thread or a talk tells you whether anyone changed how they work because of it. The second is the signal.

**Produces:** a findings file per cycle. Each finding carries what it is, where it came from, when, what it might affect, and an initial consequence guess — nothing more. **Stage 1 does not assess impact.** That is Discover (`process/02-discover/`), behind a human gate.

**Stops at:** a human reading the findings. Stage 1 has no authority to advance anything.

## Cadence

Start **monthly**, on the first. Monthly output is readable without a classifier, which means the first few cycles tell us the real signal rate before we build one.

Move to weekly or daily only when a classifier exists and has been wrong in front of us at least once, so we know how it fails. Cadence is cheap; attention is not.

## What has to be true for V0 to be accepted

1. A person reads `STANDARDS.md` and can tell which claims are established and which are ours.
2. A person reads the stage 1 spec and can say "that would find something useful" — or say precisely why not.
3. Nothing in this repository claims a capability it does not have.
4. No claim about speed, throughput or velocity appears anywhere.

## Open, carried from before stage 1 was built

- **Whether three sources are the right three**, and whether paid search or fetch is in scope. Cycle 2026-09-29 reached X only through unauthenticated surfaces.
- **What "since we last looked" is anchored to** — a stored date, or the last findings file in the repo. The second is self-describing and needs no state outside git.
- **Whether a finding is one file or one row.** Per-finding files diff well and are addressable; a single table per cycle reads faster. Leaning per-cycle file containing rows, and revisiting when volume says otherwise.
- **Whether stage 1 may use paid search or fetch at all**, and what that costs per cycle.
