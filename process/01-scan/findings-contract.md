# The findings file contract

**Status:** built. This document is the only place the shape of a findings file is declared, and [`validate-findings.sh`](validate-findings.sh) reads its declarations from here rather than carrying a second copy. Change a list in this file and the gate changes with it.

**Authority:** none. This describes a record. It does not authorize anything. See [`README.md`](README.md) for what stage 1 may and may not do.

## One file per cycle

`process/01-scan/findings/<YYYY-MM-DD>.md`, where the filename is the **cycle date** — the day the scan ran, not the date of anything it found.

The filename is load-bearing: *"since we last looked"* anchors to the most recent file in `findings/`, so a filename that is not a date breaks the anchor for every later cycle. The gate refuses one.

## The file

```markdown
# Scan cycle — 2026-10-01

since: 2026-09-01
nothing found: no

## Looked at

- web: <the ground actually covered, and the window>
- X: <the ground actually covered, and the window>
- YouTube: <the ground actually covered, and the window>

## Findings

| id | what | source | dated | kind | might affect (guess) | consequence guess |
|---|---|---|---|---|---|---|
| F01 | <one plain sentence> | <URL or precise citation> | 2026-09-14 | practice-change | verify (guess) | medium |
```

**This example had six columns where the declaration below has seven**, from the day the `id` column landed until 2026-10-04. A findings file written from it drew `refuse[columns]` twice, so the one document that calls itself the only place the shape is declared described a file its own gate refuses. `tests/test_validate_findings.sh` now extracts this block, writes it as a findings file and runs the gate over it — the example is the fixture, read from here rather than copied, because a copy would be a third declaration of the shape and would go stale the same way.

Prose lines are allowed anywhere — a note about a gap, a caveat about a source. Fields and headings are not: the field keys, the table columns, and these headings are exactly what is declared, and each field appears once.

<!-- contract:sections -->
- Looked at
- Findings
<!-- /contract:sections -->

There is no third section. A `## What this means` heading would be stage 2 arriving in a stage 1 file, so the set is closed and the gate refuses anything outside it.

**Each of the six machine-read blocks in this file is read from EXACTLY ONE place, in a rendering context.** Until 2026-10-05 neither half was true, and the two together were a hole: a second block was unioned with the first, and a block inside a fenced example was read as a real one. So appending a fenced illustration of the `sections` block naming a third section widened the closed set, and `## What this means` — the heading the sentence above says the gate refuses — then passed with exit 0. A rule declared twice is a rule that can drift, so two blocks is now a refusal to run rather than a merge: the union of two declarations is nobody's declaration. A block shown to a reader goes inside a fenced block, an inline code span, an HTML comment or an indented block, any of which `bin/lib-rendering.sh` reads as an illustration.

## Per-cycle fields

| Field | Required | Value |
|---|---|---|
| `since` | yes | the cycle date of the previous findings file, as `YYYY-MM-DD` — or the literal `first run` when `findings/` held no earlier file |
| `nothing found` | yes | `yes` or `no` |
| `example` | no | `yes` on a worked example that is not a real scan |

`since` records the anchor the cycle actually used, so a skipped month is visible in the file rather than only inferable from the directory listing.

**`nothing found: yes` is a first-class, valid outcome.** A scan that always finds something is not detecting change. It means the ground in `## Looked at` was covered and produced nothing sourceable — not that the scan was skipped. A file with no findings and no `nothing found: yes` is refused, because silence and absence are not the same record.

## `## Looked at`

Required. One line per source in the declared source list, each naming the ground actually covered and the window. Without this a quiet month and a shallow scan are indistinguishable, and that ambiguity is where a scan rots.

<!-- contract:sources -->
- web
- X
- YouTube
<!-- /contract:sources -->

A source that returned nothing still gets a line saying what was covered. A source that could not be reached gets a line saying so — an unreachable source is a gap in the cycle, and a missing line hides it.

**A source that could not be reached is recorded, not omitted.** An unreachable, rate-limited or walled source gets a line in `## Looked at` saying so. A reader cannot otherwise tell a quiet month from a shallow look, and that ambiguity is where a scan rots.

## `## Findings`

Required unless `nothing found: yes`. Exactly these columns, in this order:

<!-- contract:columns -->
- `id`
- `what`
- `source`
- `dated`
- `kind`
- `might affect (guess)`
- `consequence guess`
<!-- /contract:columns -->

A finding carries these and **nothing more**. An extra column is refused, because every field stage 1 does not have is a field where a verdict can arrive pre-made.

**Why an id.** Define accounts for every finding, and a total cannot establish that nothing was dropped — an item can leave one theme and be absorbed by another with the sum unchanged. An id makes the accounting a set comparison rather than arithmetic. It also makes a row countable by its id rather than by the case of its first letter: the previous counter was `grep -cE '^\| [A-Z]'`, so lowercasing a finding's first word removed it from the denominator and both gates passed a dropped finding. Found by the external audit in #22.

The guess label lives in the **column header**, not in each cell, so it cannot be dropped one row at a time.

Cells must not contain `|`.

| Column | What goes in it |
|---|---|
| `id` | `F` plus a number, unique within the cycle. Assigned once and never reused |
| `what` | one plain sentence, neutral. What happened, not what it means |
| `source` | a URL or a precise citation, in one of the forms below |
| `dated` | `YYYY-MM-DD` — when the thing happened, not when we found it |
| `kind` | one value from the `kind` list |
| `might affect (guess)` | the lifecycle stage(s) it might touch. A guess, and labelled one |
| `consequence guess` | one value from the `consequence guess` list. An opening bid for the human, not a verdict |

### `kind`

<!-- contract:kind -->
- `release-or-capability`
- `practice-change`
- `milestone-or-event`
- `counter-evidence`
- `sentiment-shift`
<!-- /contract:kind -->

`counter-evidence` — a study, retraction, or supersession that undercuts something we currently believe — is the highest-value kind and the easiest to miss, because nothing markets it.

### `consequence guess`

<!-- contract:consequence -->
- `high`
- `medium`
- `low`
- `unclear`
<!-- /contract:consequence -->

`unclear` is the honest default. Reaching for `high` or `low` to look decisive is the failure this column invites.

### Accepted `source` forms

One of:

| Form | Example |
|---|---|
| a URL | `https://example.com/blog/post` — scheme, and a host containing a dot |
| a DOI | `doi:10.1145/3597503` |
| an arXiv identifier | `arXiv:2402.01234` |
| a precise citation | `cite: Org, Title of the talk, 2026` — at least twelve characters and a four-digit year |

Trailing detail after the locator is fine and often useful: a video needs a timestamp, a paper needs a section.

**No source, no finding.** This is the hardest rule in the stage. A thing that cannot be pointed at is a memory, and a corpus of memories cannot be checked by the person reading it three months later.

The gate checks the *form* of a source, not that it resolves. It cannot: it makes no network calls, and a gate that did would fail for reasons that have nothing to do with the file. **Resolution is a human check** — "a finding's source resolved when someone checked it" is one of the ways we would know this stage is working.

### A vendor claim is a finding about a claim

A vendor saying their tool improves something is recorded as *what the vendor claims*, in the `what` sentence, and graded by `STANDARDS.md`'s scheme when it reaches a document. Recording it as an outcome is how vendor material gets laundered into evidence. Nothing in the gate can detect this; it is asserted, not enforced.

## The boundary stage 1 must not cross

Stage 1 has no authority to judge what a finding means. *"What does this mean for us"* belongs to Discover (`process/02-discover/`), behind a human gate — and a finding that arrives pre-judged has skipped that gate. This is the boundary the whole stage rests on, and it is enforced two ways.

**Structurally**, which is the reliable half: the columns, the field keys and the section headings are fixed. There is no field for a verdict, and an added one is refused.

**Lexically**, which is a tripwire rather than a proof: the phrases below are refused anywhere in the file.

<!-- contract:assessment-vocabulary -->
- `impact`
- `blast radius`
- `assess`
- `we should`
- `we must`
- `we need to`
- `recommend`
- `implication`
- `therefore`
- `means for us`
- `action required`
- `next step`
<!-- /contract:assessment-vocabulary -->

The list is deliberately blunt and will sometimes fire on a neutral sentence — a paper with one of these words in its title, for instance. **Reword the sentence.** There is no override, because an override on this rule would replace the rule. Matching is case-insensitive and substring-based, so the stems catch their longer forms.

It catches named vocabulary, not paraphrase. A determined verdict written in fresh words will pass, and the structural half plus the human reading the file are what stand behind it.

## What the gate refuses

Each refusal prints its own message, so a file that breaks two rules says which two.

| Code | Refuses |
|---|---|
| `contract-unreadable` | this file's declared lists could not be read — the gate refuses to run rather than pass everything |
| `filename` | a findings filename that is not `<YYYY-MM-DD>.md` |
| `since` | a missing `since`, or one that is neither a date nor `first run` |
| `nothing-found` | a missing `nothing found`, or a value other than `yes`/`no` |
| `empty-cycle` | a cycle with neither findings nor an explicit `nothing found: yes` |
| `contradiction` | `nothing found: yes` alongside findings |
| `looked-at` | a missing or empty `## Looked at`, or a declared source with no line |
| `sections` | a heading outside the declared set |
| `columns` | a findings table whose columns are not the declared ones |
| `assessment` | a finding that carries a judgment of what it means |
| `no-source` | a finding with no resolvable-looking source |
| `dated` | a missing `dated`, or one that is not a real calendar date |
| `kind` | a `kind` outside its list |
| `consequence` | a `consequence guess` outside its list |
| `field` | an empty required cell, a duplicated field, or a bad `example` value |

## Asserted, not enforced

Boundaries that matter here but that nothing refuses. Written down as claims about our behaviour rather than dressed up as controls.

- **A source resolves.** The gate checks form only. A human checks resolution.
- **A vendor claim is recorded as a claim, not an outcome.** No refusal can tell the difference.
- **`what` is neutral and one sentence.** Length and tone are not checked.
- **`dated` is the date of the thing, not of the scan.** Nothing can tell these apart.
- **A worked example is marked `example: yes`.** Nothing refuses a real cycle that reuses an example's placeholder sources, or an example that forgets the marker.

  **The opposite direction is now refused, and it was disclosed nowhere until 2026-10-04.** An external audit inserted `example: yes` into the only real findings file. `bin/cycle.sh` collapsed to a skipped line, both gates reported the files within the contract, and the Define cycle's `from:` went on resolving to the file — so a month's record rested on a file declaring itself not a real scan. `process/03-define/validate-define.sh` refuses `source-is-example` when a cycle's source carries the marker, and `bin/cycle.sh` names the cycles reading a skipped file. The marker itself is not refused: an example read by nothing is a legitimate file, and `findings/2026-09-01.md` is one.
- **A judgment written in unlisted words.** The tripwire catches the listed phrases only.
- **The anchor skips examples.** `since` resolves to the most recent file in `findings/` that is *not* marked `example: yes`, so a worked example cannot become the window a real cycle measures from. The gate checks the form of `since`, never that the right file was chosen.

  **Marking a real file as an example therefore moves the next cycle's window, and nothing mechanical catches that.** Nothing runs the anchor — it is an instruction in [`scan.md`](scan.md) that a person follows — so there is no gate to put a refusal in. What exists is the Define refusal above, which fires as soon as a cycle depends on the file; a file marked before any cycle reads it leaves nothing to contradict.
