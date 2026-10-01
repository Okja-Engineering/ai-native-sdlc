# Define contract

**Status:** derived from one artifact. `cycles/2026-09-29.md` was written first; this describes the shape it turned out to need.

**Three checks are enforced; two remain deferred.** See *The gate* at the end.

## What Define is for

Taking what Discover produced — wide, unfiltered, unranked — and **naming what it is about**, so a person decides once per theme instead of once per item.

It is the convergent half of the first diamond. Discover goes wide. Define says what the wide thing was.

## The rule everything else follows from

**A theme is a summary, not a filter. Nothing is dropped.**

Every item from the source artifact appears under a theme or in the outlier list. This is what makes Define compatible with rules the repository already holds — `intent.md`: *"a classifier that wrongly suppresses something is worse than no classifier"*; the scan spec: *"must not rank or filter to a top N."* Those forbid **dropping**. They do not forbid **naming**, and naming is what solves the problem they were worried about.

The problem Define exists for is that **reading** is the wall. Sixty-four rows is more than anyone gets through, and a process people stop opening catches nothing regardless of how complete its record is. Trust in an automated feed is spent, not easily earned back, and every low-value item is a withdrawal. Themes reduce what must be read without reducing what is kept.

## Required fields

| Field | |
|---|---|
| `dated` | when Define was run |
| `from` | the source artifact, linked, with its item count |
| `method` | how the themes were produced — by hand, by model, by classifier. **Not optional**: a reader must know what produced the grouping before trusting it |
| `status` | `defined, not decided` |

## Required sections

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
