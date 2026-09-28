# Run the scan

**Status:** built, as an instruction. Nothing schedules it and nothing runs it on its own — a person starts a cycle, and the only executable part of this stage is the gate at the end.

**Authority:** none. This stage reads, records, and stops. See [`README.md`](README.md) for the specification and [`findings-contract.md`](findings-contract.md) for the shape of what it writes.

The question the cycle asks:

> Since we last looked, what has come out about how AI-native teams build software — and has anyone actually changed the way they work because of it?

The second half is the point. A release note tells you a capability shipped; it does not tell you whether anyone changed anything.

## 1 · Resolve the anchor

*Since we last looked* anchors to `findings/`, not to a stored date, so the anchor lives in git and nowhere else.

1. List the `<YYYY-MM-DD>.md` files in `findings/` and drop any marked `example: yes`.
2. **If one remains**, take the most recent. Its cycle date is this cycle's `since`, and the window is from that date up to the cycle date.
3. **If none remains** — an empty directory, or only worked examples — this is a **first run**: record `since: first run` and cover the thirty days before the cycle date. State that window per source in `## Looked at`, since `first run` names no dates by itself.
4. The cycle date is the day you run it. Cadence is monthly, on the first.

A gap between `since` and the previous cycle date means a month was skipped. Record it as it is. A cycle that quietly widens its window to cover a miss hides the miss.

## 2 · Brief one agent per source

One agent per source, three agents, run independently. The sources fail in different ways — the web is mostly written by whoever is selling the thing, X is unrepresentative and undurable, YouTube is slow to search and hard to cite precisely — and a single agent averaging three failure modes reports the average instead of the three.

Each agent returns rows and a coverage line. It does not write to `findings/`; you merge.

### Obligations on every source agent

State these as obligations, not as things the agent may do:

- **You must return every item with a locator another person can follow**, in one of the forms the contract accepts. An item you cannot locate is not returned at all.
- **You must return `nothing found` when you found nothing.** That is a valid and expected result. Returning a weak item to avoid an empty hand corrupts the record, because a cycle that always finds something cannot detect change.
- **You must return the ground you actually covered**, including ground you could not reach — a paywall, a rate limit, a search that returned nothing. One line, specific enough that a reader can tell a quiet month from a shallow look.
- **You must look for counter-evidence**: a retraction, a supersession, a correction, a study that undercuts something already believed. Nothing markets these, so they are the easiest kind to miss and the most valuable to catch. `STANDARDS.md` carries a supersession that a previous review missed entirely.
- **You must record a vendor's claim as a claim.** "A vendor states X about their own tool" is the finding. "X" is not.
- **You must not judge what an item means for us.** No consequence beyond the `consequence guess` value, no recommendation, no next step. That judgment is the next stage, behind a human gate, and it does not exist yet.
- **You must not rank, filter to a top N, or drop an item because it looks minor.** Suppression is a judgment too, and an item dropped silently leaves no trace that it was ever seen.
- **You must not return an item without a date.** When the thing happened is part of the record; when you found it is not.

Ask each agent for **artifacts with locators** — the row, the URL, the timestamp, the published date. Do not ask it to explain how it searched or to narrate its thinking: what you can check is what it returned and what it says it covered.

### Per source

| Agent | Obliged to return | Locator it owes |
|---|---|---|
| **web** | what shipped and when — release notes, engineering blogs, papers, preprints — and any retraction or supersession | the URL, plus the dated line on the page the date came from |
| **X** | practitioners describing a change they made to how they work, and sentiment turning against a practice already treated as normal | the post URL and the post's date; the account, so a reader can judge how much weight it carries |
| **YouTube** | the long-form "here is how we work now" that nobody writes down — conference sessions, walkthroughs | the video URL **with a timestamp**, the title, and the publish date. A talk cited without a timestamp is not precisely cited |

### What each agent returns

1. One `looked at` line: the ground covered, the window, and anything it could not reach.
2. Zero or more finding rows, cells in the contract's column order.
3. `nothing found: yes` when it returns no rows.

Nothing else. An agent returning a summary, a ranking, or a view on what matters has returned something this stage cannot record.

## 3 · Merge into one cycle file

One file, `findings/<cycle date>.md`, in the shape [`findings-contract.md`](findings-contract.md) declares.

1. Write the fields: `since`, and `nothing found` (`yes` only when **all three** agents returned nothing).
2. Write `## Looked at` with one line per source, from each agent's coverage line. A source that failed or was unreachable gets a line saying so — a missing line hides whether it ran at all.
3. Write `## Findings`, one row per finding, **ordered by `dated`, oldest first.** A mechanical order carries no opinion; any other order is a ranking.
4. **Collapse only identical locators.** Two sources describing the same event stay two rows. Deciding they are the same event is a judgment, and this stage does not make judgments — it also loses the fact that two independent sources carried it.
5. Carry the source-list gap forward as a note: one tool named in discussion did not transcribe cleanly and is deliberately not guessed at, so a cycle covers three sources rather than four. A wrong tool name in a standards document is worse than a missing one.

## 4 · Run the gate

```bash
process/01-scan/validate-findings.sh
```

It refuses a file that breaks the contract, each refusal naming its own rule.

**If it refuses, fix the file.** Do not edit the gate or the contract to admit the file — a gate edited to let something through is not a gate, and the refusal it dropped was the only thing standing behind the rule. If the contract is genuinely wrong, that is a change to the contract, argued on its own and on its own commit.

## 5 · Stop

The stage writes one file, runs the gate, and stops. It does not advance anything, and there is nothing built for it to advance into.

A person then reads the file and decides, per finding: **interesting** · **not interesting**, dismissed with a reason · **later**, parked. Where those decisions get recorded is not settled and is deliberately not invented here — the assess stage does not exist.

## Unsettled

Carried from [`README.md`](README.md), unchanged by building this:

1. **The source list has a gap** — the tool that did not transcribe cleanly. Stated, not guessed.
2. **Whether paid search or fetch is in scope**, and the cost of a cycle.
3. **Where a dismissal is recorded.** This stage writes findings only.
4. **How a superseded finding is recorded** — amended in place, or a new row pointing at the old one. This matters most of all, because supersession is the kind we most want to catch and the kind most easily overwritten in silence.
