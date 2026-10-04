# Problem — producing themes at the cadence we want

dated: 2026-09-30
from: [`../cycles/2026-09-29.md`](../cycles/2026-09-29.md) — its own stated open question
rests on: [`../../02-discover/topics/classifier-models.md`](../../02-discover/topics/classifier-models.md)
status: defined, not solved

**What this is.** The convergence of one theme into a stated problem, which is what Develop needs as input. The cycle file names *what the month was about*; this names *what that leaves us needing to decide*.

**What this is not.** Not a solution and not a preference between solutions. Develop diverges from here.

---

## The problem

Themes work. Cycle `2026-09-29` turned 64 findings into seven themes and three outliers, readable in about a minute, with nothing dropped. The convergence is the thing that makes the scan usable at all — 64 rows is more than anyone gets through, and a process people stop opening catches nothing regardless of how complete its record is.

**But that cycle was themed by reading, by one person, once.** It cost real attention and it does not obviously survive contact with the cadence we actually want. The intent document says monthly is readable and daily is affordable, and the whole argument for a higher cadence was that checking becomes cheap. Theming by hand reintroduces exactly the cost that cadence was supposed to remove.

So: **the convergence step is load-bearing and currently manual.**

## Why it is not simply "automate it"

Three things make this harder than it looks, all established rather than assumed.

**The outlier surface is where the value concentrated, and it is the hardest part to automate.** The single most useful item in the cycle — requirements arriving after implementation begins roughly doubling the code-invalidation rate — clustered with nothing. Anything that groups well will file it under "other." A themer optimised for coherent groups is optimised against the finding kind we most want.

**A hand pass already failed the accounting rule once.** The first draft of the cycle file themed 54 of 64 and reported three wrong counts. That is an argument *for* mechanisation, not against it — but it also shows the failure is silent, and a machine making the same error at speed is worse, not better.

**The cheap option carries measured problems.** The classifier discovery established that a small frozen model of the kind proposed for this flips 27.8% of decisions on option reordering and 25.0% on meaning-preserving rewording, claims ~90% confidence while being right ~64% out of domain, and requires per-workload calibration that does not transfer. Those are not disqualifying. They are facts an option has to answer for.

## The question this forces

> **What produces the themes, and what does the reader have to be able to check about them?**

The second half is the real constraint. A theme is only useful because its evidence travels with it — the cycle file states *why we think it is a theme* so a reader can disagree with the grouping, not just the label. Any producer has to preserve that, or it is a summary nobody can audit.

## What would change the answer

- **If a cheap model reproduces the seven themes from the same 64 rows**, the automation question is largely settled and the remaining work is the outlier surface. This is testable now, cheaply, because both the source and a hand-made answer exist.
- **If it produces coherent-but-different themes**, that is more interesting than failure: it means theming is underdetermined, and "correct" is the wrong frame.
- **If the real volume at a daily cadence turns out to be two or three findings**, the problem mostly dissolves and hand-theming is fine. We have one cycle of data and do not know the daily rate.

## What we do not know

- The actual finding rate at daily cadence. One month is one data point.
- Whether themes should persist across cycles or be re-derived each time. Carrying them forward gains continuity and risks seeing last month's pattern in this month's data.
- Whether a reader trusts a machine-made theme the same way. Untested, and trust is the resource this whole design is managing.
