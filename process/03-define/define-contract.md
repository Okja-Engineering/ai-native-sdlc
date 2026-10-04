# Define contract

**Status:** derived from one artifact. `cycles/2026-09-29.md` was written first; this describes the shape it turned out to need.

**Three checks are enforced; two remain deferred.** See *The gate* at the end.

## What Define is for

Taking a wide, unfiltered, unranked record and **naming what it is about**, so a person decides once per theme instead of once per item.

It is the convergent half of the first diamond.

**Define reads the Scan, not Discover — and this contract said otherwise until 2026-10-03.** The artifacts say so plainly: `cycles/2026-09-29.md` carries `from: process/01-scan/findings/2026-09-29.md`, and the Discover topic on the same question is dated two days *later*. Define runs twice in a cycle, and the two runs take different inputs:

| Run | Reads | Produces |
|---|---|---|
| Themes | the **Scan's** findings file | a cycle file grouping every finding |
| A problem | a theme, plus any **Discover** topic that was run on it | one stated problem |

So the real order is Scan → Define(themes) → *human picks a theme* → Discover(topic), where the theme needs one → Define(problem) → Develop → Deliver. Discover is conditional in the contract and has run for **both** shipped problems. This said `producing-themes` did not run it, read off that problem's missing `rests on:` field; the discovery it rests on was [the classifier topic](../02-discover/topics/classifier-models.md) all along. See *`rests on`, and what a problem with no Discover step means*.

`bin/cycle.sh` prints the per-cycle steps in that order. It lists Discover topics in a separate block after them rather than inside the cycle, because a topic hangs off a problem and not off a cycle — this contract said the script "already prints it that way" until 2026-10-03, which overstated what the output shows. The order the script agrees with is the one above; where it differs is that Discover has no in-cycle position to print.

## The rule everything else follows from

**A theme is a summary, not a filter. Nothing is dropped.**

Every item from the source artifact appears under a theme or in the outlier list. This is what makes Define compatible with rules the repository already holds — `intent.md`: *"a classifier that wrongly suppresses something is worse than no classifier"*; the scan spec: *"must not rank or filter to a top N."* Those forbid **dropping**. They do not forbid **naming**, and naming is what solves the problem they were worried about.

### The accounting is a set, declared by id

**A total cannot establish that nothing was dropped.** The first version of this check added theme counts to outlier counts and compared the result to a row count. An external audit broke it two ways: lowercasing a finding's first letter removed it from the denominator (the counter was `grep -cE '^\| [A-Z]'`), and two theme counts could be adjusted in opposite directions with the total still reconciling.

So a cycle declares the ids it accounted for, in a fenced block, and `validate-define.sh` compares it to the source as a **set**:

```markdown
<!-- accounting:ids -->
F01 F02 F03 ...
<!-- /accounting:ids -->
```

| Refusal | Condition |
|---|---|
| `no-accounting` | no block at all |
| `unaccounted` | a finding in the source the block does not list |
| `invented-accounting` | an id in the block that is not in the source |
| `duplicate-accounting` | an id listed twice |
| `counts-disagree` | theme counts plus outliers do not sum to the ids accounted for |

**From the next cycle, each theme lists its own ids.** The set check closes dropping. It cannot detect a finding *moved* between themes, because moving one leaves the set unchanged — that is a count-accuracy defect rather than a dropping defect. Cycle `2026-09-29` predates ids and recorded counts only, so its membership is not recoverable; its artifact says so rather than reconstructing a mapping nobody made.

The problem Define exists for is that **reading** is the wall. Sixty-four rows is more than anyone gets through, and a process people stop opening catches nothing regardless of how complete its record is. Trust in an automated feed is spent, not easily earned back, and every low-value item is a withdrawal. Themes reduce what must be read without reducing what is kept.

## Required fields

Define produces two artifacts and they do not have the same shape. These are **a cycle's** fields; a problem declares its own, in the section below.

| Field | |
|---|---|
| `dated` | when Define was run |
| `from` | the source artifact, linked, with its item count |
| `method` | how the themes were produced — by hand, by model, by classifier. **Not optional**: a reader must know what produced the grouping before trusting it |
| `status` | `defined, not decided` |

## Required fields — a problem

Declared after the second problem, and after finding that the first two disagreed about whether the Discover edge existed at all. One table served both artifacts until 2026-10-04, so `bin/next.sh` scaffolded a problem from the **cycle's** list: a problem got `method:`, which says nothing about a problem, and never got `rests on:`, which is the only thing that carries the Discover-to-Define edge.

| Field | |
|---|---|
| `dated` | when the problem was stated |
| `from` | the cycle and the theme within it, linked |
| `rests on` | the Discover topic the problem was stated from, **linked** — or `none` with the reason no discovery was needed |
| `status` | `defined, not solved` |

### `rests on`, and what a problem with no Discover step means

**A problem that skips Discover is legitimate, and it has to say so.** Discover establishes what is true about a theme when a theme needs that; it is not a toll gate on every item. But an omitted `rests on:` and a deliberate skip look identical, which is the same reasoning the Deliver contract uses for `amends: none` and this contract uses for an empty outlier section. So `rests on: none` plus the reason is the declared form, and a bare `none` says nothing a reader can check.

**Neither shipped problem took that route, and the repository said one of them had.** `agent-pr-approval` carried `rests on:` from the start. `producing-themes` carried only `from:`, and this contract, `README.md` and `bin/cycle.sh` all read that absence as a problem stated without discovery. It was not. The problem's third load-bearing argument is *"The cheap option carries measured problems"*, and every figure in it — 27.8% of decisions flipped on option reordering, 25.0% on rewording, ~90% claimed confidence against ~64% accuracy out of domain, calibration that does not transfer — comes from [the classifier topic](../02-discover/topics/classifier-models.md), which is dated the day before the problem. The discovery had run; the record did not say so, and `cycle.sh` reported the topic as referenced by no problem. The field is now present and names it.

So the conditional route is declared and has **no worked example**. That is worth stating plainly rather than letting a missing field stand in for one.

## Required sections

These are a cycle's sections. A problem's are **not yet declared**, and `bin/next.sh` emits a cycle's into a problem skeleton for want of anything else to read — so a scaffolded problem arrives with a Themes heading it does not want. Two problems is enough to declare a problem's fields and is not obviously enough to declare its sections; the two shipped ones share a shape but neither was written against a declaration. Named here rather than invented, and carried in *Open* below.

### Themes

Each carries:

- **A name that is a claim, not a category.** "The software factory became a named practice" — not "Factories." A reader should be able to disagree with it.
- **Its item count, and the consequence spread** of the items under it.
- **Why we think it is a theme.** The evidence for the grouping itself, stated so it can be argued with. In the worked artifact: *"five independent companies, one week, converging vocabulary."* Without this a theme is an assertion, and a reader has nothing to check but the label.

**A folded theme is still a theme.** Low-value items get grouped and explicitly marked folded, with the reason. Folded is not dropped — the rows remain in the source, and a later cycle may make one matter.

### Outliers — surfaced because they fit nothing

**Mandatory, and this is the load-bearing section.**

The most valuable finding in a period is often the one that clusters with nothing — a retraction, a supersession, a correction. Nothing markets those. A theming step will file them under "other" and bury them, which inverts the value: the harder something is to group, the more likely it is the thing nobody else noticed.

So an item that fits no theme is surfaced **because** it fits no theme, not despite it. On the first run this section immediately carried the finding most directly useful to how work gets shaped.

An empty outlier list is permitted but must say so explicitly, because an empty one and an omitted one look identical.

### Where this stops

What the human now decides, and what cannot yet be recorded. Define names the gap rather than inventing a home for a decision the next phase should own.

## What Define must never do

- **No decision.** Not which theme to pursue, not what to do about one. Define names what is there; choosing is the human gate, and acting is two phases away.
- **No dropping.** Every source item is accounted for.
- **No ranking that implies priority.** Ordering by size or date is mechanical. Ordering by importance is a judgment Define does not make.
- **No new claims.** Define groups what Discover found. A theme asserting something no underlying item says is a fabrication with a summary's authority.

## The gate

`validate-define.sh` enforces the three checks that do not depend on a cycle's shape:

- **every item in the source artifact is accounted for** — under a theme or in the outliers. This one caught a real defect by hand before it was mechanised: the first draft of cycle `2026-09-29` themed 54 of 64 and reported three wrong counts, and the ten strays included a pattern nobody had named
- **the outlier section exists, and says so explicitly when empty** — an empty list and an omitted one look identical otherwise
- **`method` is declared**

Each refusal carries its own message, and each is asserted by that message in `tests/test_validate_define.sh`.

Two checks remain deferred, because they do depend on shape and one cycle cannot tell shape from accident:

- every theme carries a name, a count, and a *why* — theme formatting may legitimately differ between cycles
- no decision language — a second cycle is needed to know the vocabulary

**Those two remain asserted, not enforced**, and should be described that way.

## Open

1. **Whether a small model produces the same themes.** The first cycle was themed by reading. That is the interesting test and it is now cheap, because the source artifact and the hand-made themes both exist to compare against.
2. **Whether themes should be stable across cycles** — "the software factory" recurring next month as the same theme, or re-derived each time. Re-deriving is honest and loses continuity; carrying them forward gains continuity and risks seeing last month's pattern in this month's data.
3. **Where the human's per-theme decision is recorded.** Not invented here.
4. **A problem's required sections.** Its fields are declared above; its sections are not. `bin/next.sh` therefore emits a cycle's sections into a problem skeleton. Declaring them from the two problems that exist would encode whatever those two happen to share.
