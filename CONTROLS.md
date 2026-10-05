# Controls

**What this is.** The controls this process enforces, the evidence each one produces, and what each one does **not** cover. Written for someone who has to assess whether the process is sound, not for someone using it.

**What this is not.** Not a compliance assertion. This repository has not been audited against SOC 2, ISO 27001, PCI DSS or anything else, and nothing here should be read as a claim that it would pass. It demonstrates a process shaped so that controls are statable and evidenced.

**Derived, not designed.** Every control below describes a gate that already exists. None was written as a requirement first.

**What keeps this document in step with the code.** `bin/validate-controls.sh` checks the wiring between the two in four directions, and `tests/test_controls.sh` drives it against this document and against documents built to break it.

- **Forward.** Every refusal code a control cites is emitted at an **emission site** — a `refuse` call carrying that code as an argument — in a script that control's own **Enforced by** line names. A code in a comment does not satisfy it, and neither does a code some other gate emits.
- **Backward.** Every refusal code any gate **in that surface** emits is cited by a control that names that gate, or is listed under *Refusals and gates no control covers* with a reason. The surface is the one *Sideways* describes below, so this direction inherits its limit.
- **Sideways.** Every script whose **filename matches** `process/*/validate-*.sh` or `bin/validate-*.sh`, plus the two git hooks named literally, is either named by a control or listed there. **The surface is that pattern over the tree, not the tree**, so a gate this document forgets is refused *if it is named like one* — and a script that refuses things under any other name is read by nothing in any of the three directions. This said *"the surface comes from the tree"* until 2026-10-04, which is the sentence an adopter adding a script of their own would rely on. The gap is *what is not controlled*, item 16; widening the enumeration is tracked as an open issue and is not done here.
- **Declared but unenforced.** Every `<!-- declared-not-enforced: name — reason -->` in `process/*/*-contract.md` is disclosed by a row under *Declarations no gate enforces*, and every row there corresponds to a declaration that still exists. **This direction was missing until 2026-10-04 and its absence was structural, not an oversight:** the three above all run through refusal codes, and a field declared and deliberately unenforced emits no code, so it could not appear in this document at all. Four had landed that way and none was here. The limit is *what is not controlled*, item 17.

**It checks the wiring, not the claim.** That a control cites `not-a-person` and that `process/05-deliver/validate-decision.sh` emits `not-a-person` says nothing about whether the condition behind that code is the condition the Condition column describes. That is a reader's job, and it is where an assessor's time is now worth spending, because everything mechanical about this document is checked and this is not. *What is not controlled*, item 12, states that and four narrower limits.

**This paragraph was wrong until 2026-10-03, and it was the sentence inviting you to trust the document.** It said a control "cannot drift from its enforcement", and the check behind it was a substring search. Three ways it was false were each run against the shipped suite: a control pointed at a gate emitting none of its four codes passed 18 assertions out of 18; a fabricated refusal code passed once one comment line was added to any gate; and CTRL-9's five hook and CI controls were outside the check altogether, because its table has no code column and the gate pattern recognised only `validate-*.sh`. A fourth was found while repairing it: nothing checked the other direction, and eight refusals the gates emit were claimed by no control at all.

**The evidence trail for every control below is git.** Every artifact, its author, its date, and the merge that accepted it. There is no separate audit store to keep in step.

**What that does not include.** The issue and pull request bodies by which this repository was *built* live in GitHub's database. A merge commit carries the pull request number and its title and nothing else — no validation method, no evidence section. So a clone can follow the chain the loop **produces** end to end, and cannot see what any individual engineering change was intended to do. `AGENTS.md` claimed *"all of it in git"* until 2026-10-03, when an external audit caught it. See *what is not controlled*, item 9. <!-- corrected-overclaim: all of it in git — this sentence records the claim in order to withdraw it -->

---

## CTRL-1 · A decision is made by a named natural person

**What it prevents.** An unattributed decision, and a machine closing the loop on its own work. If nobody is named, nobody chose, and the record is describing an outcome rather than a decision.

**Enforced by** `process/05-deliver/validate-decision.sh`.

| Refusal | Condition |
|---|---|
| `no-chosen-field` | the record declares no `chosen:` field at all, so it does not say whether a decision was made |
| `undecided-by` | `chosen:` is set and `decided_by:` is empty |
| `not-a-person` | `decided_by:` names someone not listed in [`DECIDERS.md`](DECIDERS.md) |
| `undated-decision` | a decided record carries no date |
| `pending-but-decided` | the record claims both states at once |

**Evidence.** The decision record, the git commit author, the commit date, and the merge. `chosen: pending` is a valid recorded state, so a decision that has not been made is distinguishable from one that was never asked for.

**Evidence note.** The allowlist is the `Name` column of the **one table [`DECIDERS.md`](DECIDERS.md) designates** as the list, data rows only. The designation is an in-band HTML comment immediately above that table, carrying a reason — the same form as `declared-empty`, `not-a-claim` and `dead-pointer`. A table the file does not designate donates nobody whatever its columns are called, and so does an example row in a fenced block, a table inside an HTML comment, and the heading row itself. Three states authorize nobody rather than everybody: a file that designates no table, a file that designates more than one, and a designated table with no `Name` column. A missing file is the same choice.

**This sentence was false twice, and the second time it contradicted itself.** Until 2026-10-03 the allowlist was the first cell of every row in the file, header included, so `decided_by: Name` was an authorized decider. From then until 2026-10-04 it was *"the `Name` column of whichever tables declare one"* followed by *"so a second table … donates nothing"* — the first clause says every such table contributes and the second says one of them does not, and the gate did what the first clause said. A second table listing people who had asked to be added authorized all of them. Three documents stated the refusal — this one, `DECIDERS.md`, and the gate's own comment naming a second table as the defect it had fixed — and no test exercised a second table, so all three could be wrong at once for a cycle. `tests/test_validate_decision.sh` now holds that case, the designation being absent, the designation being ambiguous, a table inside a comment, a fence between the declaration and the table, and a declaration smuggled into a heading row.

**When the proof of a person starts.** This control establishes **who is authorized** to decide. Proof that a person rather than an agent recorded the decision starts with the **next** decision, by commit signature. A signature is evidence that a specific private key was present when the commit was made; an author field is a string anyone can set, which is why the author field cannot carry this. Neither decision that already exists has one:

```
$ git log --no-walk --format='%h %G?' 59b7cd2 f808ff5
59b7cd2 N
f808ff5 N
```

`N` is git's code for no signature. Both are local commits with no signature header at all, so they read `N` on any machine, and nothing can add one afterwards. `tests/test_doc_claims.sh` runs this and refuses a transcript git disagrees with.

**The history does hold signatures, and they are not a person's.** 74 of the 206 commits reachable from `12ca5cd` carry a PGP signature, every one of them committed by `GitHub <noreply@github.com>` — the platform signing a merge it performed through the web interface. That is evidence GitHub did the merge. It is not evidence about who wrote the change or who recorded a decision, which is why this control rests on the decision commit rather than on the merge.

It also shows why a signature count is not the measurement to transcribe. `%G?` over the whole history reads differently depending on whether the reader has `gpg` installed and GitHub's key available: on a machine without `gpg`, git reports `N` for all 206, which is how a claim that **nothing in the repository is signed** came to be written down on 2026-10-04 and was wrong. A signature *header* is a fact about the object; a signature *status* is a fact about the reader's keyring, and only the first is worth transcribing.

Signing for decision commits is **not configured**, and configuring it belongs to the decider, so this is an obligation that **starts at the next decision rather than one already met**. A control with a start date is an ordinary thing for an assessor to read; a history that cannot be verified is not.

**The two decisions that predate it.** `59b7cd2` set `chosen: D` and `f808ff5` set `chosen: F`. Both are unsigned, both carry an identity an agent also uses, and both are the `chosen:`-setting commits `bin/validate-authorship.sh` refuses today. They are recorded as predating the obligation rather than relabelled to satisfy it. Rewriting history to assign them an identity was weighed and refused, because the history holds no signal that could decide it and the rewrite would have put an invented separation in the one file that exists to say who is authorized — *What is not controlled*, item 10, carries the measurement and the reasoning.

**What it does not cover.** Whether the named person actually read the change. A name is attributable, not a guarantee of attention — see *What is not controlled*, item 1. And, for those two decisions, whether a person rather than an agent typed `decided_by:` at all. A clone can establish who is authorized; for the records that already exist it cannot establish who sat at the keyboard, and nothing added later can make it.

---

## CTRL-2 · A chosen option existed before it was chosen

**What it prevents.** Inventing the answer at decision time. If the right answer was not developed, the alternatives were never weighed.

**Enforced by** `process/05-deliver/validate-decision.sh`.

| Refusal | Condition |
|---|---|
| `no-options-link` | a decided record declares no option set |
| `options-unresolved` | the declared option set does not resolve |
| `chosen-not-an-option` | `chosen:` names something absent from that set |
| `no-problem-link` | no `problem:` field — a decision with no question |
| `problem-not-linked` | names a problem without linking it |
| `problem-unresolved` | links a problem that does not exist |

**Evidence.** The options artifact, dated before the decision, with each option's cost, assumption, failure mode and the condition that would make it right.

**Evidence note.** `problem:` was a required field in the contract that nothing read until 2026-10-03 — deleting it left the gate reporting the record within the contract, so the decision-to-problem edge had no check. Found by the external audit, and it was not disclosed here either.

**What it does not cover.** Whether the option set covered the real space. Both option sets written so far state explicitly that they have no entry for an answer nobody proposed.

---

## CTRL-3 · A decision that changes how we work lands in the document it changes

**What it prevents.** A decision that never reaches the standard it was about, and a standard that drifts from the decisions behind it. Checked in **both** directions, because a one-way pointer lets the two disagree silently.

**Enforced by** `process/05-deliver/validate-decision.sh`.

| Refusal | Condition |
|---|---|
| `no-amends` | a decided record declares no `amends:` |
| `bare-none-amends` | `amends: none` with no reason — indistinguishable from an oversight |
| `amends-not-linked` | names a document without linking it |
| `amends-unresolved` | links a document that does not exist |
| `amends-not-reciprocated` | the amended claim does not cite the decision back |
| `amends-no-claim` | the link names a document and no claim within it |
| `amends-claim-unresolved` | the link names a claim the amended document does not carry |

**Evidence.** The `amends:` field on the record and the `decided:` link on the amended claim. `STANDARDS.md` §3 and `process/05-deliver/decisions/agent-pr-approval.md` are the worked pair.

**Evidence note.** Reciprocity was compared at **file** level until 2026-10-04. `amends:` carries the anchor of the claim it changes and the anchor was stripped before the comparison, so deleting §3's back-link and re-inserting the identical `decided:` line in §7 — while `amends:` still named §3 — reported the pair within the contract. The control established that two documents pointed at each other, not that they pointed at the same claim. The back-link now has to sit inside the claim the anchor names, subsections included, and the anchor itself is required. A **fenced block** is not part of the claim: attacking the repaired check found that a document showing what a back-link looks like, in a fenced example, reciprocated the real thing — the same class as the example row in `DECIDERS.md` that would have authorized everyone it named.

**Evidence note.** The back-link was read with `head -1` until 2026-10-04 — the first `decided:` line in the amended document and no others. `STANDARDS.md` is the document decisions amend and already carried one amendment, so a second decision pointing at a different claim in it was refused for naming a different record, and the control allowed exactly one amendment per document. Every `decided:` line is now read, and the refusal fires only when none of them names the record under test.

**What it does not cover.** Two things, both stated in the contract rather than implied:

- **Skills.** The stated output is "standards *and our skills*". Skills are not in this repository, so this reaches one of the two.
- **Whether the claim says what the decision decided.** The repaired check establishes that the record names a claim the document carries and that the claim links back to that record. It reads neither side's prose, so a claim rewritten under an unchanged heading still reciprocates with a decision that no longer matches it. The links agree; the content is a reader's job.
- **The reciprocal check verifies a link, not a mention.** It was a bare filename match until 2026-10-03, when an external audit replaced the `decided:` link with the sentence *"A note: the file agent-pr-approval.md exists somewhere in this repository"* and the gate reported the pair reciprocated. It now requires a `decided:` line carrying a link that resolves back to that record, and refuses a back-link pointing at a different one.

---

## CTRL-4 · The change record is complete — nothing is dropped

**What it prevents.** Silent suppression. A summary that quietly discards items is indistinguishable from one that covers them, and the repository holds that *"a classifier that wrongly suppresses something is worse than no classifier."*

**Enforced by** `process/03-define/validate-define.sh`.

| Refusal | Condition |
|---|---|
| `no-accounting` | no `accounting:ids` block at all, or a block that declares no ids and does not declare itself empty |
| `unaccounted` | a finding in the source the block does not list |
| `invented-accounting` | an id accounted for that is not in the source |
| `duplicate-accounting` | an id listed twice |
| `counts-disagree` | theme counts plus outliers do not sum to the ids accounted for |
| `no-declared-count` | `from:` links a source and states no item count |
| `declared-count` | the count `from:` declares is not the number of findings the source records |
| `source-unreadable` | the ids of the declared source could not be read |
| `no-outlier-section` | no outlier section at all |
| `silent-empty-outliers` | the section lists nothing and does not declare itself empty |
| `no-source` | the record links no source artifact |
| `source-unresolved` | the declared source does not resolve |
| `source-is-example` | the declared source is marked `example: yes`, so it is not a real scan |

**Evidence.** The counts reconcile against the source artifact, which is linked and resolvable. This control caught a real defect before it was mechanised: a draft that grouped 54 of 64 findings and reported three wrong counts, where the ten strays included a pattern nobody had named.

**Evidence note.** The accounting is a **set comparison by id**, not arithmetic. It was a total until 2026-10-03, when an external audit broke it two ways — lowercasing a finding's first letter removed it from the denominator, and two theme counts could move in opposite directions with the total reconciling.

**Evidence note, a quiet cycle.** A cycle over a scan marked `nothing found: yes` accounts for **zero** findings, and until 2026-10-05 that record had no passing state at all: this gate read an empty declared id set and an absent block as the same thing, so every body for the block drew `no-accounting`, and the only route to a non-empty set was to invent an id. `.github/workflows/ci.yml` runs this gate over the directory, so **recording one quiet month would have made every branch red permanently** — the control would have forbidden a state the scan contract protects deliberately. A set of zero now declares itself in band inside the block, `<!-- declared-empty: reason -->`, the same form CTRL-7 and the outlier section use; an absent block is still refused and the message says which of the two it is. The declaration does not excuse a cycle that has findings: a zero set against a source of sixty-four leaves all sixty-four named by `unaccounted`, so nothing about this control is weaker. It was found by building the second cycle, not by reading the gate.

**Evidence note, the outlier section.** `define-contract.md` calls Outliers the load-bearing section, and the refusal that makes it load-bearing was a search of the section's prose for one of three short words until 2026-10-04. The section's own explanation of why outliers matter uses one of those words twice, so for cycle `2026-09-29` that refusal could never fire: deleting all three outliers left the section satisfying its own emptiness check. An empty section now declares itself empty in band and with a reason, `<!-- declared-empty: reason -->`, the same form CTRL-7 requires of an empty open section. The limit of it is *What is not controlled*, item 15.

**Evidence note, the denominator.** The set comparison establishes that the ids accounted for are the ids the source **currently** carries, and says nothing about what the source was supposed to carry. Until 2026-10-04 a finding could be deleted from the findings table, its id dropped from the accounting block and one theme count decremented, and both gates reported the files within the contract — while the record's `from:` line declared 64 findings over a 63-row table and nothing read it. The declared count is now compared to the source's rows, so the three numbers — declared, recorded, accounted — have to agree.

**What it does not cover.**

- **What the scan was supposed to contain.** This is the honest limit of the whole control, and it is worth stating plainly rather than leaving in the shape of the refusal list. **The denominator is anchored to what the scan recorded. Nothing anchors it to the world.** A scan that never saw a thing cannot be shown to have missed it, and `findings-contract.md` already carries that limit for stage 1. What the declared count adds is narrower and real: dropping a finding now takes a coordinated edit to two dated records instead of one, because the count the Define cycle declares is in a different file from the table it counts. A tamperer who edits both still reconciles, and the gate passes. Nothing mechanical closes that.
- **A findings file marked as an example before anything reads it.** `source-is-example` fires on the contradiction between the marker and a cycle that depends on the file, which is the case an external audit used to erase a month's record. A file marked before any cycle reads it leaves nothing to contradict, and the scan's anchor — which skips examples — is an instruction a person follows rather than code, so there is no gate to put a refusal in.
- **A finding moved between themes.** Moving a count from one theme to another leaves the set unchanged and still reconciles. That is a count-accuracy defect rather than a dropping defect, and closing it needs per-theme ids — required by `define-contract.md` from the next cycle. Cycle `2026-09-29` predates ids and recorded counts only, so its membership is not recoverable and its artifact says so rather than reconstructing a mapping nobody made.
- **Whether the grouping is useful.** Accounting for every item says nothing about whether the themes are the right themes.

---

## CTRL-5 · How a grouping was produced is declared

**What it prevents.** A reader trusting a grouping without knowing whether a person, a model or a classifier made it.

**Enforced by** `process/03-define/validate-define.sh`.

| Refusal | Condition |
|---|---|
| `no-method` | the cycle record declares no `method:` field |

**Evidence.** The `method:` field on every cycle record.

**What it does not cover.** Whether the declared method was the method used. This is a declaration, not an attestation.

---

## CTRL-6 · A findings record matches its declared contract

**What it prevents.** A cycle record that cannot be compared with the next one, and a finding with no source. The scan runs repeatedly, so drift in shape is the risk worth mechanising against.

**Enforced by** `process/01-scan/validate-findings.sh`.

All fifteen are listed. This said "fifteen refusals including" and named eight, and the seven it left out — `field`, `sections`, `looked-at`, `assessment`, `columns`, `id` and `dated` — were outside the check that was supposed to bind this document to the gate. A prose list is not reachable by the check either way: the eight it did name were read from a sentence, and the check only harvested table rows.

| Refusal | Condition |
|---|---|
| `filename` | the file name is not a cycle date, `<YYYY-MM-DD>.md` |
| `since` | no `since` field, or a value that is neither a date nor the words first run |
| `nothing-found` | no "nothing found" field, or a value other than yes or no |
| `field` | a declared field appears more than once, carries a value outside the declared set, or a required cell is empty |
| `sections` | a heading that is not one of the sections the contract declares |
| `looked-at` | no "Looked at" section, an empty one, or a declared source with no line in it |
| `assessment` | stage 1 prose judging what a finding means, which belongs to Discover |
| `columns` | the findings table's column count, column names, or a row's cell count disagree with the contract |
| `id` | the id cell is not `F` followed by a number, so Define cannot account for the row |
| `no-source` | a finding with no source, or a source that is not a resolvable-looking locator |
| `dated` | no dated cell, or a value that is not a calendar date in `YYYY-MM-DD` |
| `kind` | kind is outside the declared list |
| `consequence` | the consequence guess is outside the declared list |
| `empty-cycle` | the cycle carries neither a finding nor an explicit "nothing found: yes" |
| `contradiction` | "nothing found: yes" and the file carries findings |

**Evidence.** Every finding carries what it is, a resolving locator, a date, what it may affect, and a consequence grade. `nothing-found` is a recorded result rather than an empty file, so "the scan found nothing" is distinguishable from "the scan did not run".

**What it does not cover.** Whether the sources were the right sources. Three were used; the spec records that as an open question.

---

## CTRL-7 · A discovery artifact says what it could not establish

**What it prevents.** An artifact claiming completeness it has not earned, and agent output presented as verified fact. Discover carries more claims than any other phase — 55 graded ones in a single artifact — and had no mechanical check at all.

**Enforced by** `process/02-discover/validate-discovery.sh`.

| Refusal | Condition |
|---|---|
| `no-open-section` | no "what could not be established" section |
| `silent-empty-open` | the section lists no `[O]` item and does not declare itself empty |
| `no-verified-by-hand` | coverage has no verified-by-hand part |
| `empty-verified-by-hand` | the verified-by-hand part names nothing the artifact carries anywhere else |
| `empty-coverage-part` | the reached or not-reached part names nothing the artifact carries anywhere else |
| `no-not-reached` | coverage lists only what was reached |
| `no-question` | the question is not in the asker's own words |
| `question-not-quoted` | the question section carries no quotation |
| `grade-not-in-enum` | a grade outside `E`, `S`, `V`, `P`, `O` |
| `no-grades` | no graded claims at all |
| `no-where-this-stops` | does not record what a later phase will need |
| `link-unresolved` | a local link that does not resolve |
| `undated` | no `dated:` field |
| `no-status` | no `status:` field |
| `no-coverage` | no coverage section at all |
| `no-reached` | coverage has no reached part |
| `no-grade-key` | the grade scheme is not declared in the document |

**Evidence.** Coverage in three parts — reached, not reached, and **verified by hand** — which is what separates *an agent reported this* from *someone checked it*. Both shipped topics pass despite differing in markup, so the gate checks the contract rather than one artifact's formatting.

**Evidence note.** Each part's check was two numbers until 2026-10-03 — a minimum separator count and a minimum character count — and the comment above them asserted that a fabricated part "tops out around 43 characters and 2 separators". It does not. A sentence denying that anything was checked passed with two commas added to it, and the same sentence without the commas was refused. The gate now requires each part to name something the artifact carries somewhere else, which is the thing the two numbers were a proxy for.

**Evidence note, the open section.** This is the control behind the question *where did the process say it could not verify something*, and until 2026-10-04 it was a search of the section's prose for one of three short words. A review deleted all seven items from the open section of `process/02-discover/topics/agent-pr-approval.md`, replaced them with *"the discovery was exhaustive and nothing of consequence remains outstanding"*, and the gate reported the artifact within the contract — an artifact deleting every disclosure it owed, asserting the opposite, and passing on one incidental word. Two more routes were found while repairing it and neither needed a word at all: the section's own trailing `---` separator was inside the body the check read and begins with a list marker, so it counted as an item; and an `[O]` anywhere in the body counted as an item.

What the check reads now is a **declaration**, `<!-- declared-empty: reason -->`, inside the section and in a rendering context — the shape `not-a-claim` and `dead-pointer` already use, checked for presence and for a reason. **This said "outside a fenced block" until 2026-10-05, and the gate implemented exactly that, which left four ways in.** Writing the form in backticks emptied this section with every suite green, and a fenced example containing one bulleted `[O]` line counted toward the item total. Five display forms are now answered by one reading, `bin/lib-rendering.sh`, and the whole cross-product is in `tests/test_rendering.sh`. An open item is a list item carrying its `[O]` grade — a line starting flush left with `-`, `*`, `+`, `1.` or `1)` and a space. Two of the five cases below were found by attacking the repaired check rather than by reproducing the review: a declaration shown inside a fenced block satisfied it, which is the class a fenced `rests on: none` and a fenced `DECIDERS.md` row already cost this repository twice; and an indented line carrying `[O]` counted as an item, where Markdown renders four spaces as a code block and a reader sees no item at all. The same declaration is what CTRL-4 now requires of an empty outlier section; one form, two sections, and the limit of it is *What is not controlled*, item 15.

**What an item is, said once, after the two gates disagreed about it.** *"One form, two sections"* was true of the `declared-empty` declaration and false of what counts as an item until 2026-10-04. This gate accepted a bullet, a number **or any line beginning `**`** with the `[O]` anywhere after it, so a bold-led sentence counted as an open item — including `**Nothing remains open.** … the grade [O] is not used in this artifact.`, a line denying the grade satisfying a check for an item carrying it. CTRL-4's gate accepted `^- \*\*` and nothing got past it, so the two sections that share a shape disagreed about it and the looser one was behind the audit question this control answers.

The rule is now stated once, in [`discovery-contract.md`](process/02-discover/discovery-contract.md) under *What could not be established*, and `define-contract.md` cites it. The bold-label form is gone: the distinction it needs — a label carrying the grade, versus a sentence mentioning it — can be drawn where items are graded and cannot be drawn in an outlier section at all. CTRL-4's gate no longer requires a bold lead either, which is a **loosening** of that one, stated as such in its own contract: nothing had ever declared that requirement and keeping it would have made one cycle's markup the rule for two gates. `tests/test_item_rule.sh` drives one candidate line through both gates and asserts the verdicts are equal, which is what stops them drifting again while they hold separate copies of the check.

**What it does not cover.** Three things. The first is the limit of the repaired check, and is in *What is not controlled*, item 11. The other two of the checks the contract hoped for are **not mechanisable**, and the gate's own header says so rather than leaving the gap implicit:

- **"Every claim carries a grade"** and **"every claim carries a source"** need a claim to be a delimited thing. The two topics write claims as prose paragraphs in different markup with no boundary a script can find. Checking this would mean inventing a convention mid-gate. What is checked instead is that the grades *used* are from the enum and that the enum is declared.
- **"No recommendation language"** is covered under *What is not controlled*, item 3.

---

## CTRL-8 · Every graded claim resolves to something a reader can open

**What it prevents.** The loop's output document asserting evidence it does not have. `STANDARDS.md:5` says *"Every claim carries a grade. The grade is the point of this document"* — and until 2026-10-03 it carried 31 graded claims, zero citations, and one route to evidence that was a branch which does not exist on origin.

**Enforced by** `bin/validate-standards.sh`.

| Refusal | Condition |
|---|---|
| `uncited-claim` | a line carrying an `[E]` or `[S]` marker anywhere on it, citing no source ID | <!-- not-a-claim: this row names the markers the refusal looks for, it does not grade anything -->
| `unknown-source` | a cited ID absent from the register |
| `source-no-link` | a register entry with no URL, DOI or path |
| `no-register` | no source register at all |
| `dangling-ref` | a document points at a path, commit, branch or tag this repository does not have |
| `empty-register` | the register declares no IDs |

**Evidence.** [`SOURCES.md`](SOURCES.md) — 22 sources, each with its population, finding and limitation. Vendor-affiliated empirical studies carry that in the class column so it cannot be read past.

**Evidence note on the evidence pointer.** The check matched backtick-quoted strings beginning `experiment/` or `branch/` — the two namespaces the one known defect happened to use. The pointer this repository actually depends on is a commit: the corpus is in history and not on any branch, and `DECIDERS.md` records that the planned identity cleanup is a force-push rewriting every SHA. Replacing that commit with a dead one left the gate reporting every document clean. It now checks any backticked token that contains a `/` or is a hexadecimal object name, against the working tree and against git. <!-- dead-pointer: experiment/0.0.0 — named here to record the defect that left STANDARDS.md unevidenced; it never existed on origin and is not a route to anything -->

**Evidence note.** Until 2026-10-03 the gate skipped any line starting with `|` or `> ` and matched only four marker forms — `**[E]`, `**[S]`, `[E]/[S]`, `[S]/[P]`. A bare `[E]`, a table row and a blockquote all passed uncited, and a bare marker is this repository's own house style for a graded claim. A marker is now read wherever it appears on a line. Repairing the detection found one real uncited `[S]` claim in the shipped document — §3's configuration requirement — which now cites `S-NIST-AC5`, the standard the practice two paragraphs above it already rests on.

**The scope, and the fact that it was a filename until 2026-10-04.** This control was titled *"Every graded claim in STANDARDS.md"* and the gate was pinned to that filename, so `AGENTS.md` — which says *"grade every claim"* at line 156 — carried four `[E]` claims nothing read, with none of their sources in the register. That is the failure this control exists for, *"31 graded claims, zero citations"*, reproduced in a second document because the check was keyed to a file rather than to the marker. <!-- not-a-claim: this names the marker those four claims carry in order to say they were unread, it grades nothing -->

Two surfaces now, each enumerated rather than listed:

- **Graded claims** are read in every document matching `*.md`, `.github/*.md`, `.github/*/*.md` or `process/*/*.md` — seventeen today, and the gate prints the count. Positively enumerated, so a new document at one of those depths is in scope by existing. The **dated records are out**: their own contracts require a resolving source in the row for every claim, which is stricter than a register id, and asking them for `S-` ids would refuse all 26 graded claims they carry correctly. `tests/` is out because a fixture exists to be refused by a gate.
- **Evidence pointers** are read in every document that cites an **object name** — a 7-to-40 character hexadecimal token. That is the shape of an evidence route here, because the research corpus is in history at a commit rather than on a branch. Six documents qualify today. The list this replaces was four, hand-written, and left out this document and `spec.md`.

**One document declares that its graded claims cite inline**, with a reason, and it is named here rather than only in the gate: [`AGENTS.md`](AGENTS.md).

**What it does not cover.**
 Its four `[E]` claims name their sources in prose — a Kubernetes release audit, two repositories, an ICSE 2013 paper and an arXiv preprint — and none is a register entry. A register entry carries a publication date and the limitations that bound the claim and a prose citation carries neither, so **this is a weaker state than the control asks for**, declared rather than hidden. The gate prints which documents carry the declaration and refuses one that carries it without a reason. Promoting those four needs the sources opened and their limitations recorded, which is the owner's. <!-- not-a-claim: this counts the graded claims in another document, it does not make one -->

- **An UNGRADED claim.** This control reads the grade marker, so a statistic written with no grade is invisible to it. The live instance is `.github/pull_request_template.md`, which cites a figure from the same arXiv preprint `AGENTS.md` uses and carries neither a grade nor a source. `discovery-contract.md` sets out why *"every claim carries a grade and a source"* is not mechanisable: it needs a claim to be a delimited thing, and prose is not. **Grading every claim is a rule a person keeps**; this gate only catches a grade that resolves to nothing.
- **Whether the cited source supports the claim.** The gate checks a citation resolves, not that it is apt. A reader is still the only check on that.
- **A one-level branch or tag name is not checked.** The gate treats a backticked token as a pointer when it contains a `/` or is a hexadecimal object name. `main` and `v0.1` in backticks cannot be told apart from an ordinary word or a version number in prose, and guessing would refuse `v4.0.1` in a sentence about PCI DSS. A dead branch named without a namespace would pass.
- **A reference to another repository has to be a link, not backticks.** The cost of the rule above, stated plainly: a repository slug written *owner/name* and `experiment/0.0.0` are the same shape, so a backticked repository slug in one of these documents is refused. The refusal says to link it instead. That is a deliberate false positive, chosen over leaving a dead branch unchecked, and it is loud rather than silent. **The slug in that sentence is in italics rather than backticks for that reason** — this document came into the surface on 2026-10-04 and was refused by the rule it describes, which is the same self-reference that forced `AGENTS.md` to spell out a speed claim rather than quote one. <!-- dead-pointer: experiment/0.0.0 — named here as the example of a dead ref the rule exists to catch, not as a route to anything -->
- **The gate refuses to run in a shallow clone.** It resolves pointers into history, and a depth-1 checkout does not contain the commit the documents cite. It exits 2 — *the gate could not run* — rather than reporting the documents clean having resolved nothing. The `tests` job checks out with `fetch-depth: 0` for that reason.
- **A pointer declared dead is taken at its word.** A document may record that a pointer is dead, declared in band and naming the pointer: `<!-- dead-pointer: experiment/0.0.0 — reason -->`. The gate checks the declaration names that pointer and carries a reason, not that the reason is true. This was a match on four phrases anywhere on the line until 2026-10-03, which meant `SOURCES.md` line 5 — naming the dead branch and the live commit in one sentence — exempted both, and replacing the live commit with a dead one was accepted.
- **A line that declares itself not a claim is taken at its word.** Some lines carry a grade marker without grading anything: the rows that define what each grade means, and a sentence about the scheme rather than graded by it. Those are declared in band, `<!-- not-a-claim: reason -->`, and the gate prints how many it honoured. It checks that the declaration is present and carries a reason, not that the reason is true, so an author can exempt a real claim. That is a weaker control than no exemption at all and a stronger one than what it replaced, which exempted every table row and every blockquote in the document, silently and without a reason.

  **A SPAN form of that exemption existed, was disclosed nowhere, and switched this control off.** `<!-- not-a-claim-block: reason -->` exempted every line until `<!-- end-not-a-claim-block -->`, the terminator was not required, and the opener was honoured inside a fenced block. Deleting that one line from `STANDARDS.md` and stripping its citations left the gate reporting *20 not currently cited* and **exiting 0** — the state this control was built for, *"31 graded claims, zero citations"*, restored by deleting one line. `grep -c not-a-claim-block CONTROLS.md` returned **0** while the sentence above praised the per-line form against *"what it replaced, which exempted every table row and every blockquote"*; an unterminated span exemption is that, with a reason attached. It was **retired on 2026-10-05**, not repaired: the per-line form does the same job and each exempted line then carries its own reason and is counted, where the span counted once for eleven lines, which is why the reproduction was invisible in the summary. The grade table now carries two per-line declarations instead.
- **A graded claim inside a fenced block is still read, and a `not-a-claim` inside the same fence does not exempt it.** The exemptions are read in a rendering context and the CLAIMS are not, and that asymmetry is deliberate: a grade marker is written in backticks here as house style — `AGENTS.md`'s four `[E]` claims are written that way — so sixteen lines carrying a real grade vanish from a reading that blanks code spans. Reading claims that way would hide four real claims in the document this gate was widened to cover. The cost is this bullet: a document wanting to show a reader an example graded claim cites it, or declares it on a line outside the fence. <!-- not-a-claim: this sentence counts graded claims in another document in order to say which reading is safe, it does not make one -->
- **A dead pointer named only inside a fenced transcript is still refused.** Same asymmetry, same reason — a pointer IS a backticked token. No document does that today.
- **The pointer set is extracted by pairing backticks left to right across the whole file, and the pairing is sensitive to fenced content.** Reading it in a rendering context instead extracts the dead branch named in the evidence note above out of this document where the raw read does not, and that note's own line then draws `dangling-ref` for naming it — even though the note carries a declaration. That is a real gap in the extraction, it is **not** closed here because nothing on issue #116 is evidence for it and closing it refuses a shipped document, and it is recorded for the owner rather than left unsaid. **The branch is named in prose here rather than in backticks for the same reason the slug three bullets up is in italics** — this document is inside the surface the rule polices.
- **`[P]` and `[O]` claims have no source by design** — a practitioner observation is ours, an open question has none.
- **Register entries nothing cites are reported, not refused.** The first version refused them, which would have forced deleting real sources or attaching them to claims they do not support.

---

## CTRL-9 · The conventions are enforced where they cannot be skipped

**What it prevents.** A convention from applying only to whoever remembered to enable it. The hooks in `.githooks/` are bypassable — `--no-verify` defeats them and they run only for someone who has set `core.hooksPath` — so the ones that can have a server-side counterpart.

**An external audit found this document omitted all of these.** An assessor told to start here got five of the repository's refusals and missed five more, including a hard refusal protecting the local-to-remote boundary.

**Enforced by** `.githooks/commit-msg`, `.githooks/pre-push` and `bin/validate-claims.sh`, and the `commit-messages`, `claims` and `tests` jobs in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

This control enforces by exit status rather than by refusal codes, so it has no refusal table. That put it outside the document check twice over: codes were harvested only from table rows, and the gate pattern recognised only `validate-*.sh`, so neither hook could be checked even if they had been harvested. `bin/validate-controls.sh` now resolves all six — each path has to exist, and each job name has to be declared in the workflow.

| Control | Local | Server-side | What it refuses |
|---|---|---|---|
| Conventional commits | `.githooks/commit-msg` | the `commit-messages` job | a non-conventional subject, one over 72 characters, or an attribution trailer |
| No speed claims | — | the `claims` job, via [`bin/validate-claims.sh`](bin/validate-claims.sh) | the obvious forms of a speed or velocity claim. A **tripwire**, not enforcement |
| Secret scan | `.githooks/pre-push` | — | a built-in pattern scan over the commits being pushed, plus `gitleaks` where installed. The built-in always runs, so the guard is never simply absent |
| Publish disclosure | `.githooks/pre-push` | — | **a hard refusal** if a push would newly publish a never-publish path, having first printed which commits and how many files would become public |
| Suite integrity | — | the `tests` job | a runner that reports success on a deliberately failing suite — asserted, not trusted |

**Evidence.** The hook scripts, the workflow, and CI's run history. `tests/test_hooks.sh` drives both hooks end to end against a throwaway repository and a bare remote, so the local half is asserted rather than assumed.

**Evidence note.** This control is about a convention applying only to whoever enabled it. It drifted the other way instead. The conventional-subject rule is enforced in three places — `.githooks/commit-msg`, `.githooks/pre-push`, the `commit-messages` job — and until 2026-10-03 the merge exemption was in the job alone, so both hooks were **stricter** than the thing they mirror. A local `git merge main` was refused for the subject git had just written, and a force-push of a rebased branch was refused for a merge on `main` that the forge wrote. The only way past either was `--no-verify`, which also turns off the secret scan, so the practical effect of the stricter hook was less enforcement. Neither case appears in ordinary use, which is why it sat there: one needs a local merge and the other needs a rebase.

**What it does not cover.**

- **The hooks are local and bypassable.** That is what the server-side half is for, and the table above shows how little of it there is. Three of the five controls exist as a local hook — conventional commits, the secret scan, the publish disclosure — and of those three, **only conventional commits has a server-side counterpart**. The secret scan and the publish disclosure exist **only** as hooks, so a push from a machine that never ran `git config core.hooksPath .githooks` is unguarded by either. (This read *"only two of the five have one"* until 2026-10-03. No reading of the table gives two: three rows carry a server-side entry and three carry a local one.)
- **The publish disclosure cannot run in CI.** It is about a push that has not happened yet.
- The `commit-messages` job skipped a direct push to main until 2026-10-03. Two commits on main still predate the convention and have never been checked.

---

## CTRL-10 · A problem names the discovery it was stated from

**What it prevents.** A problem that asserts what is true about a theme with no discovery behind it, and a discovery that no problem ever used. Define is the convergent step, so a problem is where an outside fact enters the chain; if the link is missing, a reader cannot tell a question that was researched from one that was assumed.

**Enforced by** `process/03-define/validate-define.sh`.

| Refusal | Condition |
|---|---|
| `no-rests-on` | a problem declares no `rests on:` field |
| `bare-none-rests-on` | `rests on: none` with no reason — indistinguishable from the field being forgotten |
| `rests-on-not-linked` | names a discovery without linking it |
| `rests-on-unresolved` | links a topic this repository does not have |
| `rests-on-not-a-topic` | links something that resolves but is not in `process/02-discover/topics` |

**Evidence.** The `rests on:` field on each problem, and the Discover topic it resolves to. Both shipped problems carry one. `bin/cycle.sh` prints the resulting linkage per topic, so a topic no problem names is visible in the status report as well as refused at the gate.

**Evidence note.** A field shown as an **example** is not the field. Attacking the new check found that a fenced `rests on: none — ...` ahead of the real field was read as the field's value, so the real link was never looked at. The field reader in this gate now skips fenced blocks, which also closes the same hole for a cycle's `method:` and `from:`. The same class is in `process/05-deliver/validate-decision.sh` and `process/02-discover/validate-discovery.sh`, which share the field-reader shape and have not been changed here.

**Evidence note.** No gate read a problem or an option at all until 2026-10-04, and `rests on:` was declared nowhere — `define-contract.md` listed the **cycle's** fields only. `bin/next.sh` scaffolded a problem from that list, so a scaffolded problem got `method:` and never got `rests on:`. The only thing that noticed the missing edge was `bin/cycle.sh` printing *"classifier-models referenced by no problem"* in a status report nothing fails on. And the repository had read that absence the wrong way round: `producing-themes` drew every figure in its cost argument from that topic, so the discovery had run and the record did not say so.

**What it does not cover.**

- **Whether it is the right topic.** The check establishes that `rests on:` names a Discover topic that exists. It does not read either document, so a problem linking an unrelated topic passes. The same limit as CTRL-3's: the links agree, the content is a reader's job.
- **Whether the reason for `none` is true.** `rests on: none` plus a reason is accepted on its word. A problem can declare no discovery was needed when one was.
- **A problem's `from:`.** Declared by the contract and read by nothing — see *What is not controlled*, item 14.
- **Options.** `process/04-develop/options/` is still in no gate. That is item 5, unchanged and still disclosed.

---

## Refusals and gates no control covers

Every refusal any gate in this repository emits is either cited by a control above or listed here with a reason, and so is every gate no control names. `bin/validate-controls.sh` refuses if something is in neither place, so this table cannot be quietly short.

Two shapes of entry. `the gate itself` means the gate needs no control and none of its refusals needs a citation; a backticked code would exempt that one refusal. Both entries below are the first shape, which is the broader of the two — see *what is not controlled*, item 12.

| Gate | Refusal | Why no control covers it |
|---|---|---|
| `bin/validate-authorship.sh` | the gate itself | It refuses today and is deliberately not wired into CI, so it gates nothing yet. What CTRL-1 now carries instead is a start date: proof that a person recorded a decision begins with the next decision, by commit signature, and the two existing decisions are recorded as predating that. Turning this gate on needs the decider to commit under the declared address — not a history rewrite, which was weighed and refused; *what is not controlled*, item 10, holds the measurement. A control claiming enforcement by a gate nothing runs would be the overclaim this document exists to avoid. |
| `bin/validate-controls.sh` | the gate itself | It checks this document against the gates rather than checking a process artifact. A control over the control document would be this document asserting a control over itself. Its own refusals are covered by `tests/test_controls.sh`. |

`bin/validate-claims.sh` needs no entry. CTRL-9 names it, and it emits no refusal code at all — it exits non-zero and prints the matching lines — so the backward check has nothing to find and the control naming it is not asked for a refusal table it could only invent.

---

## Declarations no gate enforces

**A field a contract declares and nothing checks.** Different from a refusal no control covers, and different again from a check that is deferred: the field exists, the scaffold writes it, a report may print it, and no gate reads it. Each row is a real gap and is here so that an assessor starting at this document learns the field exists and is unguarded.

**Why this table exists rather than the prose it replaces.** The three directions at the top of this document all run through **refusal codes**. A field that is declared and deliberately unenforced emits no code, so it was invisible to every one of them by construction — not overlooked, unrepresentable. Four landed that way across three changes, every one of them honestly marked in its own contract, and not one reached this document. **So this document got less complete as the repository got more honest**, and that is what made question 5 of the self-audit move backwards after it had been answered.

**It is derived, not maintained here.** A contract marks a declaration in band, `<!-- declared-not-enforced: name — why nothing enforces it -->`, and `bin/validate-controls.sh` enumerates them from `process/*/*-contract.md` and refuses in both directions: a declaration this table omits, and a row naming a declaration a contract no longer carries. A hand-kept list is what this repository keeps deleting, and this one was short before anyone kept it — the issue that asked for the table named three of the four.

| Declaration | Declared in | What is not checked |
|---|---|---|
| `expires` | `process/05-deliver/deliver-contract.md` | Nothing refuses a decision record that omits the field, and nothing refuses one whose expiry has passed. `bin/cycle.sh` reports days to the nearest expiry, which puts the date in front of a person and refuses nothing. CTRL-1 and CTRL-2 are unaffected: both read a decided record regardless. |
| `pass took` | `process/03-define/define-contract.md` | Nothing refuses a cycle that omits it and nothing reads the value, so a cycle can claim any duration or none. Deliberate: no artifact carries the field yet, and gating an invented shape is designing the contract up front. |
| `a theme's own ids` | `process/03-define/define-contract.md` | The scaffold writes the block and nothing reads it. This is the mechanism CTRL-4's item 1b gap would need: a finding moved between themes leaves the accounting set unchanged, so CTRL-4 cannot see it. |
| `compares` | `process/03-define/define-contract.md` | Nothing refuses a comparison record that omits the field, and nothing checks that it resolves to a cycle over the same source — so two records could claim to compare and read different findings files. |
| `criterion` | `process/03-define/define-contract.md` | The field is declared and has no value, here or in any record, and nothing checks either. What *"closely"* means is the owner's to set; the two readings the decision names point at opposite answers. |

**What this table does not establish.** That the list of gaps is complete — only that the gaps the contracts *declare* are all here. A field nobody declared anywhere is outside this the same way a script nobody named like a gate is outside *Sideways*; see *what is not controlled*, items 16 and 17.

---

## What is not controlled

The section an assessor should read first. Each of these is a real gap, not a formality.

**0. Whether a cited source actually supports the claim it is cited for.** CTRL-8 establishes that a citation resolves. Nothing establishes that the paper says what the sentence says it says. Four of the register's entries carry limitations that materially bound the claim — three are vendor-affiliated, and `S-METR-2026-01` carries its own authors' statement that the results are unreliable. A reader who does not open the register will not know.

**1. Whether an approver actually reviewed.** CTRL-1 makes a decision attributable. It cannot distinguish a person who read the change from one who clicked approve. `STANDARDS.md` §3 now requires a natural person to hold the approving position, and the decision that set that policy records the cost explicitly: a machine approval is visible in a platform audit log, a human rubber stamp is not, so the policy **moves a detectable failure into an undetectable one.**

**1b. Whether a finding was moved between themes.** CTRL-4 detects a dropped or invented finding and not a relabelled one. See CTRL-4.

**2. Whether a machine approval can satisfy a separation-of-duties control.** **Undecided, in both directions.** NIST SP 800-53 AC-5 is written in terms of *"different individuals or roles"* and routes enforcement through IA-2 *Organizational Users* rather than IA-9 *Service Identification*, saying nothing either way. The PCI DSS clause that would settle it could not be obtained. `STANDARDS.md` §3 carries this as `[O]`. **Our position is a practice we chose, not a requirement we met.**

**3. Judgement in a discovery artifact.** The discovery contract forbids recommendation language, and that check is deliberately **not** mechanised. A pattern match on *recommend* fires on the sentence "No option set, no recommendation, no decision" — flagging a correct disclaimer as the thing it disclaims. The real failure is a neutral-sounding paragraph that steers, which no pattern catches. This stays a reader's job.

**4. Whether every claim in a discovery artifact is graded and sourced.** CTRL-7 gates the phase now, but not this. It needs a claim to be a delimited thing, and the two topics write claims as prose paragraphs in different markup with no boundary a script can find. The gate checks that the grades *used* are from the enum, not that every assertion carries one. A reader counting graded claims against ungraded ones is still the only way to know.

**5. Develop has no gate.** One options artifact existed when its contract was written, so a gate would have encoded that artifact's accidents. **That reason expired on 2026-10-03 and this item claimed it still held until 2026-10-04.**

```
$ ls process/04-develop/options/
agent-pr-approval.md  producing-themes.md
```

The second artifact did what the deferral was for. `develop-contract.md` now records what it showed: the three required fields, six options, the do-nothing option, the cross-cutting test and the *what none of these solves* section all held in both, four of the five things required of an option are a labelled field in both, and the fifth — *what it is* — is a label in one artifact and an unlabelled lead paragraph in the other, so a gate keyed to it would have encoded the newer markup as the rule.

So the honest reason Develop has no gate is **that nobody has decided to build one**, not that it cannot be derived. What that leaves uncontrolled is what the contract names as the thing most likely to decay: an author who has already decided writes several options and one answer wearing an option's clothes, and nothing refuses. Building the gate is the owner's decision and is surfaced in the contract rather than taken here.

**And nothing watches a deferral's condition, which is why two of them expired unnoticed.** Four contracts deferred enforcement until a second artifact. Discover's was spent and the contract was updated and gated. Define's is live — one cycle exists. Develop's and Deliver's both fired and neither sentence was re-read; Deliver's contradicted itself thirty lines apart, saying `amends` was added *after the second decision* and that Deliver's shape still waited for one.

A check for this was considered and **not built**, for a stated reason rather than by omission. Finding the deferrals lexically — a scan for *second artifact*, *run once*, *waits for* — is the word search this repository has now shipped and repaired three times, and it fails open on the fourth phrasing nobody thought of. The sound version is the shape used elsewhere: an in-band declaration beside the sentence it governs, naming the directory and the count that spends it, with the count read off disk rather than from a list anybody maintains. That is a convention spanning five contracts and a new refusal needing a control to claim it, which is a design decision rather than a correction, and it belongs to the owner alongside the Develop gate. A line in `bin/cycle.sh`'s status report was the cheap alternative and was rejected: this repository has already paid for a status report nothing fails on, which is the only thing that noticed a problem referencing no topic.

**6. Configuration drift.** §3 now states the requirement explicitly — the toggles that let an agent approval satisfy a merge gate stay off at every level. GitHub publishes **no API representation** for that policy, so the setting cannot be read, set or drift-checked programmatically. It is a UI setting and a promise, and nobody has verified the current state of our own repositories. §3 also records that the approval can outlive the diff, because dismissing a stale approval on push is optional per ruleset.

**7. Cadence.** Nothing is scheduled. A missed cycle is invisible, which also means the first early-reversal condition of decision `producing-themes` cannot currently fire.

**8. This is not an audit.** No external party has assessed any of the above. The first attempt to have someone outside the team try to break the chain was run on 2026-10-03 against a clean clone, and an agent with no prior context is a cheap proxy for a colleague who has never seen the repository, not an equivalent.

**9. Why any individual engineering change was made.** The chain the loop produces is complete in a clone. The chain by which this repository was built is not: issue and pull request bodies live in GitHub's database, so a clone shows that a change was reviewed and merged but not what it was intended to do or how that was to be validated. An assessor holding only a clone can assess the process and not its own construction.

Three ways to close it were weighed and none chosen yet, because each has a real cost: stop claiming it — done, this is that; mirror merged pull request bodies into tracked files, which is more duplicated state of the kind this repository keeps being burned by; or move the intent itself into git and leave the GitHub issue as a pointer, which is the most honest and the largest change.

**And it went further than this section admitted until 2026-10-03.** The gap was stated as *why a change was made*. Part of the **process's own design rationale** was out there too: two structural decisions — that applying a decision is a field plus a link rather than a sixth phase, which is why the `STANDARDS.md` gate lives in `bin/`, and the test method that a guard has to be mutated as well as deleted — were cited nine times across the gates and their suites as a bare issue number and nowhere else. `AGENTS.md` carries the rule those citations broke: *"a document naming an issue states the gap in the same sentence rather than pointing at it."* Each of those nine now states the substance and names the tracked document that holds the full reasoning.

Nothing mechanical checks this, and it is not a candidate for one: a rule telling design rationale from plain attribution would be guessing at what a sentence is for, and *"found by the external audit in #22"* is a legitimate use of a number.

**10. Who committed a decision.** CTRL-1 establishes that `decided_by` names an authorized person. It does not establish that the person, rather than an agent, wrote the field. Both commits that set `chosen:` are authored by an identity an agent uses, and the identity `DECIDERS.md` declares a decision commit must carry authors no commits at all — so `git log` cannot separate the parties for the one act this control is about. A distinct agent address was configured on 2026-10-03, which separates agent-driven commits from the rest and leaves this item exactly where it was: the two display names sharing `imagineux@gmail.com` are the shape `STANDARDS.md` 3 convicts a vendor of, and the decider's declared address is still unused. This item said *"every commit on `main` is authored under one address"* until 2026-10-04, a day after that stopped being true, with the sentence below telling the reader to run the gate that was printing the contradiction. <!-- corrected-claim: under one address — the correction has to quote the sentence it corrects -->

Run `bin/validate-authorship.sh` for the live tally. The identity tally is not repeated here on purpose: this section carried a transcribed copy until 2026-10-03 and it was wrong, because it had been measured in a working tree holding unpushed branches. It also changes every time anybody commits, so a copy here would go stale on its own. `DECIDERS.md` holds the one transcribed copy, labelled with the commit it was measured at, and `tests/test_doc_claims.sh` checks both that it agrees with git and that no document contradicts the gate in the present tense.

**A history rewrite was weighed and refused, so this gap is permanent for the records that already exist.** The one measurement worth transcribing here is a fixed fact about commits that already exist rather than a live tally, so it does not go stale — author against committer on `main` at `12ca5cd`:

```
$ git log 12ca5cd --format='%an|%cn' | sort | uniq -c | sort -rn
  85 imagineux|imagineux                        <- made locally, either party
  74 Matthew Van Dusen|GitHub                   <- web merges, the owner
  43 ai-native-sdlc agent|ai-native-sdlc agent  <- the agent
   4 imagineux|ai-native-sdlc agent
```

Those 85 carry no signal at all: author and committer are both `imagineux`, the commit was made locally, and it was made by either the owner or an agent. Committer does not separate them and neither does timing or message style. A rewrite could only assign them an identity by fiat, producing a history that looks separated while the separation is invented — and nobody, including whoever ran it, could check it afterwards. That is the overclaim this document exists to avoid, in the file that answers who is authorized. It would also force a push past the `non_fast_forward` rule on `main` and break every commit citation the tracked documents carry, including the `fa7538a` pointer `bin/validate-standards.sh` now resolves.

**What replaces it is a start date, not an enforcement.** CTRL-1 now records that proof of a person begins with the next decision, by commit signature, and that the two existing decisions predate the obligation. It carries the command and the measurement showing neither of them is signed, and the reason the 74 signatures the history does hold are no help: they are GitHub's, on merges it performed itself. Signing for decision commits is not configured and configuring it is the decider's, so the honest position is that the proof obligation starts, not that it is met.

`bin/validate-authorship.sh` checks the author field and **refuses today**: a commit setting `chosen:` must be authored by the identity declared in `DECIDERS.md`, and that identity must not be shared. Neither holds. It is deliberately **not wired into CI**, because a gate that cannot pass blocks every branch. What would turn it on is the decider committing under the declared address and making the `chosen:` commit personally — `DECIDERS.md` states both. Neither is waiting on a history change: the issue that tracked rewriting `main` is closed as won't-fix for the reason above, and nothing is deferred to it.

**11. Whether a person checked what a coverage part says they checked.** CTRL-7 requires the verified-by-hand part, and the reached and not-reached parts, to name something the artifact carries somewhere else — a file, an id, a measurement, a product, an address. That establishes two things and no more: the part names something checkable, and the artifact itself carries that thing. It does not establish that anybody looked at it.

The sentence below was run against the repaired gate on 2026-10-03 and **passes**:

```
### Verified by hand

1. Nothing in the GitHub REST API or the SemIf source was verified by hand.
```

Both names resolve, so the part names things, and the sentence denies checking them. Nothing mechanical closes that, which is why the repaired gate is written as *names a referent* rather than as *was verified*. A reader is still the only check on whether a coverage part is true. What has changed is narrower and worth stating exactly: a part naming nothing at all is now refused however it is punctuated, where before two commas were enough.

**12. Whether the documents are true.** This is the limit of the two checks added on 2026-10-03, and it is worth stating exactly because the checks are easy to read as more than they are.

`tests/test_doc_claims.sh` and `tests/test_controls.sh` catch **four specific mechanical contradictions** between a document and the repository:

- a line asserting that a path or a **phase** this repository has does not exist, and a transcribed git measurement with no command above it to reproduce it
- a sentence in `CONTROLS.md` or `SOURCES.md` claiming a named gate refuses something, where the refusal it names is not one that gate emits
- a document a gate cites as authority whose own status line declares it unaccepted, which would leave a refusal resting on nothing
- a control citing a refusal the gate **that control names** does not emit at an emission site, a gate emitting a refusal no control claims, and a gate or hook no control names — the three directions at the top of this document

That is the whole of it. **The documents are not otherwise verified, and nothing mechanical does that.** Seven known gaps, each probed deliberately rather than assumed:

- **An absence claim with a long qualifier escapes.** The phase has to sit within about forty characters of the claim, because that window is what distinguishes the subject of a sentence from a mention elsewhere in it. *"Define, the convergent half of the first diamond that groups every finding, does not exist"* passes. Widening the window brings four true sentences back in as false positives, including this document's own note about the Update stage that was genuinely never built.
- **An absence claim that does not name the phase escapes.** *"the next stage ... does not exist yet"* and *"the phase that owns that decision does not exist yet"* were two of the three survivors, and neither names what it means. Both are corrected by hand. A check for an unnamed referent would fire on honest prose about something that really is not built.
- **A true-looking claim that cites a real refusal for the wrong condition escapes.** The check establishes that a named refusal is one the gate emits, not that the gate emits it for the reason the sentence gives. The same limit applies to every control's Condition column above: a control could cite `not-a-person` and describe it as checking a date, and all three directions would pass.
- **A document with no status line at all is not checked for acceptance.** The check reads a declaration and refuses one that says *unaccepted*; a document that never declares a state has nothing to contradict. So it establishes that a gate's authority does not call itself a draft, not that anybody accepted it.
- **A control naming several scripts is satisfied by any one of them.** The binding is to the set the control declares, not to a single script. CTRL-9 names two hooks, a script and three CI jobs. A control that named every gate would be back to the document-wide union that made the old check vacuous; that is visible in the document and nothing mechanical stops it.
- **An exception taken on `the gate itself` covers every refusal that gate emits, including ones added later.** Both entries in *Refusals and gates no control covers* are that shape.
- **A fabricated refusal code in prose is not detectable.** The check refuses a code a gate really emits appearing outside its control's table, because it can recognise those. A backticked word that was never a refusal code anywhere reads as ordinary prose, and nothing can tell the difference.

Everything else a document asserts — that a number is right, that a description matches what a script does, that a limitation bounds a claim the way it says — is a reader's job and is not covered.

**13. A gate that read nothing is still not refused, only disclosed.** Every gate and both hooks were read for one shape: *the input is absent, so there is nothing to refuse, so the check passes*. Two instances were fail-open and are fixed, four more claimed conformance over nothing and now say so instead, and this item states what is still not covered.

The rule the repository now holds everywhere is the one `process/01-scan/validate-findings.sh` already stated for its contract — a list that is empty or missing means the gate would pass everything, so it refuses to run. The same sentence had to be applied in six more places, and the fact that it had to be applied one site at a time is itself the gap: there is no shared library, so nothing stops a seventh gate being written without it.

What was found, and what each one does now:

| Where | It used to | It now |
|---|---|---|
| `.githooks/pre-push`, the never-publish guard | pass when the list was missing, unreadable, or had every pattern commented out | refuse, naming whether the problem is the list or its contents |
| `process/02-discover/validate-discovery.sh`, the link check | pass a broken link when its scratch path could not be written, and refuse a sound artifact when a directory sat at that path | hold the result in a variable, so no state outside the artifact can change the verdict |
| `bin/validate-claims.sh` | report no speed claims whether it read every tracked document or none, because `git grep` exits 1 for both | refuse to run when its pathspec matches no document, and print the count on the clean path |
| `bin/validate-authorship.sh` | read a `git log` failure as an empty range, so a misspelled ref printed every commit attributable and exited 0 | refuse to run when the history cannot be read |
| the four process gates | print *0 file(s) within the contract* over an empty phase directory | say nothing was checked |

**What this does not cover, stated plainly.**

- **The four process gates still exit 0 over an empty phase directory.** CI runs all four with no arguments, so emptying or moving a phase directory leaves the build green. What changed is that the log now says nothing was checked instead of claiming the files conform. A phase with no artifact is a real state — `validate-findings.sh` has always called it a first run — so turning it into a refusal is a decision about this repository's lifecycle rather than a bug fix, and it belongs to the decider.
- **Fixing a fail-open does not make a hook enforcement.** The never-publish guard and the secret scan still exist only as hooks, and a push from a machine that never ran `git config core.hooksPath .githooks` is unguarded by either. CTRL-9 says this already and it stays true: a guard that fails closed locally is still bypassable by not installing it at all.
- **There is no mechanical check for the shape.** The sweep was a person reading every gate and both hooks and running each one with its input taken away. Nothing refuses a new gate written with the same shape, and the only thing that would is a convention nobody can enforce from inside a shell script.
- **One mutant is known to be uncaught.** Replacing the discovery gate's variable with a `mktemp` whose write is not checked re-opens the fail-open, and no suite catches it, because it only fails when the temp area itself is broken. Recorded in `tests/test_validate_discovery.sh` at the site, with the reason the obvious test for it does not work.
**14. A problem's `from:`.** CTRL-10 reads a problem's `rests on:` and not its `from:`, which the Define contract also declares as required. So a problem can name a cycle that does not exist, or name one without linking it, and the gate reports it within the contract. This is the same shape as two defects this repository has already found — `problem:` on a decision record, and `rests on:` itself — and it is left open rather than closed in the same change for a stated reason: no artifact has shown it failing, and the two it would check are both correct today. It is written down here so the next reader does not have to rediscover it.

**15. Whether a section declared empty really is empty.** CTRL-4 and CTRL-7 both require a section with nothing in it to declare that in band and with a reason. That establishes two things and no more: the author made the claim deliberately, and recorded why. **A declaration that a section is empty is not evidence that nothing was found.** An author who found something and did not want to write it down can declare the section empty and the gate will accept it, exactly as an author can declare a real claim `not-a-claim` or a live pointer dead.

What the declared form does change is narrower and worth stating exactly. The emptiness claim can no longer be made **by accident**: before this, prose that happened to contain a short word satisfied the check, which is how an artifact that deleted all seven of its disclosures and asserted the opposite passed. A declaration has to be written, it names the author's reason, and `git log` shows who added it. So the control moved from *a word appeared* to *somebody asserted this on the record* — and the assertion itself is still a reader's job to disbelieve.

Two narrower limits of the same check:

- **What counts as an item is a markup rule.** An open item is a list item carrying its `[O]` grade. A real open item written as unmarked prose is not counted, so an artifact can be refused for a section that does carry content — an actionable refusal rather than a silent pass, but a refusal of honest work all the same. In the other direction, a fabricated item in the right markup — a bullet asserting that nothing was left open, graded `[O]` — is counted as an item and the section is not read any further.

  **This paragraph has now misstated the bar three times, and the third time was in the sentence that recorded the first two.** It said the surviving bypass needed *"a fabricated graded claim rather than an incidental word, which is a higher bar"*. It did not. Issue #116 reproduced two routes through this check and **neither was a fabrication** — both were honest illustrations of the repository's own syntax:

  - delete the seven `[O]` items from [`process/02-discover/topics/agent-pr-approval.md`](process/02-discover/topics/agent-pr-approval.md) and write one line mentioning `<!-- declared-empty: reason -->` **in backticks**: exit 0, eighteen suites green
  - delete them and add a **fenced** example containing one bulleted `[O]` line: the fenced line counted toward the item total

  So the bar was never a fabricated claim. It was *displaying the check's own syntax*, which a contract has to be able to do, which is why the bar read as higher than it was. **The bar now is: a list marker, flush left, on a line carrying the grade, in a rendering context** — and the remaining route really is a fabricated item in that markup, which is what this bullet claimed before it was true.

  The two earlier misstatements stay recorded. Until 2026-10-04 the gate also counted any line beginning `**` with an `[O]` anywhere after it, so an incidental mention in a bold-led sentence sufficed; before that it was a search of the section's prose for one of three short words. CTRL-7's evidence note carries both reproductions.
- **A displayed declaration no longer satisfies anything, and that IS now a mechanism.** This said *"nothing stops a third section being written with a fourth word search"*, and the reason given was that the two gates share no library because one would be a load-bearing script outside the enumeration *Sideways* builds — item 16 below.

  That reasoning held for two copies of one predicate and did not scale. The tree carries **fifteen in-band declaration forms** read by seven gates, one helper and three suites, and fence-awareness ran from all of them to none; four of the six sites on #116 existed *because* the rule was copied rather than shared, and the two gates that never received a copy held both criticals. So there is one reading now, `bin/lib-rendering.sh`, and it is a reading rather than a predicate: a gate obtains its artifact through it once and every check below reads that, so a **new** check written by someone who has never heard of this rule is still safe, because the displayed form is not in the text it is handed.

  **What that costs is item 18 below**, and it is the cost this bullet previously used as the reason not to pay it.

  The narrower guarantee from before also still holds: `tests/test_item_rule.sh` drives one candidate line through both gates and asserts the verdicts are equal, and the item rule is stated in one contract that the other cites. `tests/test_rendering.sh` is the wider one — five display forms against all fifteen declaration forms, every cell enumerated.

  **What is still not controlled:** nothing refuses a new gate that reads its artifact with `cat` instead. The library makes the safe path the default rather than making the unsafe path impossible, and only a convention keeps a new gate on it.

**16. Whether a script that refuses things is covered at all, if it is not named like a gate.** This is the limit of *Sideways* at the top of this document, and it is the one an adopter is most likely to walk into: they add a script of their own, it refuses something no control claims, and the build is green.

The surface is `ls process/*/validate-*.sh bin/validate-*.sh` plus two hooks named literally. **The filename is what decides whether a script is asked about**, in all three directions. A reviewer demonstrated it with a script in `bin/` called `check-smuggled.sh`, emitting a refusal no control claims: exit 0, every suite green. The same file renamed to begin `validate-` is refused.

**It is not hypothetical, and the proof is already in the tree.** `bin/next.sh` carries a `refuse` call that `bin/list-refusals.sh` cannot read a code from — a condition this gate refuses on. Nothing refuses, because of the name:

```
$ bash bin/list-refusals.sh bin/next.sh
bin/next.sh:163:?
$ n=validate-next.sh; cp bin/next.sh "bin/$n"
$ bash bin/validate-controls.sh 2>&1 | sed -n 's/.*\(refuse\[[a-z-]*\]\).*/\1/p'
refuse[site-unreadable]
refuse[uncontrolled-gate]
```

**That transcript said `bin/next.sh:149:?` until 2026-10-04, and the command prints `:163`.** Line 149 is `wrap_ids "$5"`; 163 is the `refuse` call the item is about. It is in the one section this document invites a reader to verify by running, and an auditor found it rather than a test. `tests/test_doc_claims.sh` now runs every transcribed `bin/list-refusals.sh` command in every tracked document and compares its output to what the document shows, so a drifted transcript is a test failure. Nothing is pinned in the suite — the expected value is produced by running the command.

Nothing about the file changed, and the copy is named through a variable above so this document does not claim a path it does not have. Four more tracked scripts sit outside the surface — `bin/cycle.sh`, `bin/list-refusals.sh`, `process/01-scan/findings-ids.sh` and `bin/lib-rendering.sh` — and the last three are load-bearing: `validate-define.sh` exits 2 without the harvester, this gate exits 2 without the lister, and **every gate that reads a declaration exits 2 without the rendering library**. None is named by a control or listed in the exception table. The third was added on 2026-10-05 and its cost is *what is not controlled*, item 18.

**The two denominators also disagree.** `bin/list-refusals.sh`'s own header says the document check and the mutation sweep have to agree about what a site is, because a guard invisible to both at once is how an untested refusal shipped. The sweep's surface carries `bin/list-refusals.sh` and this gate's does not, so they differ by one script today.

**Both directions are asserted in `tests/test_controls.sh`**, so this is recorded as a gap and cannot be read as coverage: a refusing script outside the pattern is not noticed, the same file inside it is refused, and the refusal lister reads both — which is what shows that the enumeration rather than the lister is what excludes it. Widening the enumeration is a deliberate change tracked as its own open issue and is not done here: a wider surface makes every tracked script something this document has to account for. **Fewer claims honestly enforced is the trade.**

**17. Whether a gap nobody declared is a gap at all.** *Declarations no gate enforces* is complete with respect to the declarations the contracts **make**. A field that exists, is unenforced, and that nobody marked in band is outside it — the same shape as item 16, one level up: there the enumeration is a filename pattern, here it is an author writing a marker.

**The enumeration is `process/*/*-contract.md` and nothing else**, which is the narrower half of the same limit and is checkable rather than inferred: a `declared-not-enforced` marker written into a topic, a findings file, a README or this document is read by nothing. That boundary is deliberate — a contract is where a field's shape is declared, so it is where the absence of a check belongs — and it means a declaration in the wrong file is silent rather than refused.

What this is not is the state it replaced. Before 2026-10-04 an honest prose disclosure in a contract could not reach this document at all, because the binding ran through refusal codes and an unenforced field emits none; four declarations sat in two contracts and none was here. So the gap moved from *structurally unrepresentable* to *dependent on an author marking it*, which is a weaker claim than enforcement and a stronger one than nothing. The closing move would be to require a declaration for every field a contract names and no gate reads — which means enumerating the fields a contract names, and that is a shape no gate here reads today. It is not done, and saying so is the point of this item.

The same limit as the other declarations in this repository applies, and *what is not controlled*, item 15, already states it for two of them: the gate checks that a declaration is present and carries a reason, never that the reason is true.

**18. The reading every declaration goes through is a load-bearing script no control covers.** `bin/lib-rendering.sh` answers one question — would a reader of the rendered document see this? — for every gate that reads a declaration, counts an item or harvests a list. It is the repair for the class issue #116 names, and it is the third script of its kind outside the surface *Sideways* builds, after `bin/list-refusals.sh` and `process/01-scan/findings-ids.sh`, which the *Sideways* section already names.

It emits no refusal code, so all four directions of `bin/validate-controls.sh` are blind to it **by construction** — the same blindness the fourth direction was built to fix for declared fields, one level further down. It does not widen the enforcement surface, so the decision item 16 holds is untouched.

**It is also a single point of failure: one wrong edit moves seven gates at once.** Three things bound that and none of them is a promise:

- every caller exits 2 when it cannot read the file, the pattern `validate-define.sh` already uses for the findings harvester
- both of its file readers return non-zero when the view does not have the same number of lines as the file, so a truncation cannot be read as a clean document — and that guard was itself wrong on its first draft, firing on a correct view of this document and handing the caller an empty one, which is recorded at the site
- `tests/test_rendering.sh` is the denominator: five display forms against fifteen declaration forms, every cell enumerated and a cell that does not apply recorded with the reason rather than left out

**What would close it** is widening the *Sideways* pattern so a load-bearing non-gate is named by a control or listed as an exception. That is item 16's decision and this is the third thing waiting on it.

---

## The in-band declaration forms, all fifteen

A declaration is an HTML comment carrying a name, a colon and a reason. Every one is checked for two things and no more: that it is present, and that it carries a reason. **Never that the reason is true** — items 15 and 17 above.

**A document that DISPLAYS a declaration does not thereby SATISFY it**, and that is five forms rather than the one the gates knew until 2026-10-05: a backtick fence, a tilde fence, an inline code span, an HTML comment other than the declaration's own, and a four-space indented block. One reading answers all five, `bin/lib-rendering.sh`, and item 18 above is its cost.

**This table is the enumeration this document did not have.** Two forms were disclosed nowhere before 2026-10-05 — `not-a-claim-block` and `not-an-enforcement-claim` — and `grep -c not-a-claim-block CONTROLS.md` returned 0 while that form could switch CTRL-8 off by having one line deleted.

| Declaration | Read by | What it does | Control |
|---|---|---|---|
| `<!-- declared-empty: reason -->` | `validate-discovery.sh`, `validate-define.sh` | a mandatory section, or an `accounting:ids` set, states that it is empty | CTRL-4, CTRL-7 |
| `<!-- accounting:ids -->` … `<!-- /accounting:ids -->` | `validate-define.sh` | delimits the ids a cycle accounts for | CTRL-4 |
| `<!-- contract:NAME -->` … `<!-- /contract:NAME -->` | `validate-findings.sh`, `findings-ids.sh` | declares one of the scan contract's six machine-read lists. **Exactly one block per name, in a rendering context** — two is a refusal to run, because the union of two declarations is nobody's declaration | CTRL-6 |
| `<!-- deciders-table: reason -->` | `validate-decision.sh` | designates the one table that is the decider allowlist | CTRL-1 |
| `<!-- not-a-claim: reason -->` | `validate-standards.sh` | exempts the line it sits on from `uncited-claim` | CTRL-8 |
| `<!-- graded-claims-cite-inline: reason -->` | `validate-standards.sh` | one document declares that its graded claims cite in prose rather than through the register | CTRL-8 |
| `<!-- dead-pointer: pointer — reason -->` | `validate-standards.sh` | records that a named pointer is dead rather than offering it as a route | CTRL-8 |
| `<!-- declared-not-enforced: name — reason -->` | `validate-controls.sh` | a contract declares a field nothing enforces; a row in *Declarations no gate enforces* has to match | the fourth direction, item 17 |
| `<!-- corrected-claim: phrase — reason -->` | `tests/lib/retired-claim.sh`, via `test_cycle.sh` and `test_doc_claims.sh` | retires a sentence that stopped being true, quoting it | CTRL-9 |
| `<!-- corrected-overclaim: phrase — reason -->` | `tests/lib/retired-claim.sh`, via `test_doc_claims.sh` | the same, for a claim that was always too strong | CTRL-9 |
| `<!-- not-an-enforcement-claim: reason -->` | `tests/lib/enforcement-claim.sh`, via `test_controls.sh` | a sentence mentions a refusal without claiming one. **Disclosed here for the first time on 2026-10-05** | CTRL-9 |
| `<!-- not-a-claim-block: reason -->` … `<!-- end-not-a-claim-block -->` | **retired 2026-10-05, read by nothing** | exempted every line until its terminator. The terminator was not required and the opener was honoured inside a fence, so deleting one line from `STANDARDS.md` left 20 uncited graded claims and exit 0. Dropped rather than repaired: the per-line form does the same job, and each exempted line then carries its own reason and is counted | CTRL-8 |
| `<!-- scaffold:source-ids -->` | `bin/next.sh` | substituted when a skeleton is copied out of a contract. **Read from inside a fence on purpose** — it is a template, not a check, and nothing is satisfied or permitted by it | none; nothing refuses |
| `<!-- review:signoff -->` | nothing | the same shape, inside a fenced skeleton | none |
| `<!-- theme:ids -->` | nothing | declared by `define-contract.md` and read by no gate | disclosed under *Declarations no gate enforces* |

**The last three are why the display question does not arise for them:** a form nothing reads cannot be satisfied by displaying it. `tests/test_rendering.sh` records those cells as not applicable, with that reason, and asserts that no gate reads them — so a gate that starts reading one is a failure there rather than a cell nobody wrote.

