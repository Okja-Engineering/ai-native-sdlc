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

| what | source | dated | kind | might affect (guess) | consequence guess |
|---|---|---|---|---|---|
| <one plain sentence> | <URL or precise citation> | 2026-09-14 | practice-change | verify (guess) | medium |
```

Prose lines are allowed anywhere — a note about a gap, a caveat about a source. Fields and headings are not: the field keys, the table columns, and these headings are exactly what is declared, and each field appears once.

<!-- contract:sections -->
- Looked at
- Findings
<!-- /contract:sections -->

There is no third section. A `## What this means` heading would be stage 2 arriving in a stage 1 file, so the set is closed and the gate refuses anything outside it.

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

**The source list has a known gap.** One tool named in discussion did not transcribe cleanly and is deliberately not guessed at. A wrong tool name in a standards document is worse than a missing one, so the gap is stated and stays stated until someone names the tool.

## `## Findings`

Required unless `nothing found: yes`. Exactly these columns, in this order:

<!-- contract:columns -->
- `what`
- `source`
- `dated`
- `kind`
- `might affect (guess)`
- `consequence guess`
<!-- /contract:columns -->

A finding carries these and **nothing more**. An extra column is refused, because every field stage 1 does not have is a field where a verdict can arrive pre-made.

The guess label lives in the **column header**, not in each cell, so it cannot be dropped one row at a time.

Cells must not contain `|`.

| Column | What goes in it |
|---|---|
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

Stage 1 has no authority to judge what a finding means. *"What does this mean for us"* belongs to the assess stage, behind a human gate — a stage that is named and not built — and a finding that arrives pre-judged has skipped that gate. This is the boundary the whole stage rests on, and it is enforced two ways.

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
- **A judgment written in unlisted words.** The tripwire catches the listed phrases only.
- **The anchor skips examples.** `since` resolves to the most recent file in `findings/` that is *not* marked `example: yes`, so a worked example cannot become the window a real cycle measures from. The gate checks the form of `since`, never that the right file was chosen.
