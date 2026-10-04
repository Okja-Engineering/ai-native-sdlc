# Controls

**What this is.** The controls this process enforces, the evidence each one produces, and what each one does **not** cover. Written for someone who has to assess whether the process is sound, not for someone using it.

**What this is not.** Not a compliance assertion. This repository has not been audited against SOC 2, ISO 27001, PCI DSS or anything else, and nothing here should be read as a claim that it would pass. It demonstrates a process shaped so that controls are statable and evidenced.

**Derived, not designed.** Every control below describes a gate that already exists. None was written as a requirement first.

**What keeps this document in step with the code.** `bin/validate-controls.sh` checks the wiring between the two in three directions, and `tests/test_controls.sh` drives it against this document and against documents built to break it.

- **Forward.** Every refusal code a control cites is emitted at an **emission site** — a `refuse` call carrying that code as an argument — in a script that control's own **Enforced by** line names. A code in a comment does not satisfy it, and neither does a code some other gate emits.
- **Backward.** Every refusal code any gate emits is cited by a control that names that gate, or is listed under *Refusals and gates no control covers* with a reason.
- **Sideways.** Every gate script, and both git hooks, is either named by a control or listed there. The surface comes from the tree, so a gate this document forgets is refused rather than absent.

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

**Evidence note.** The allowlist was read out of [`DECIDERS.md`](DECIDERS.md) as the first cell of every row in the file, header included, so `decided_by: Name` was an authorized decider until 2026-10-03. It is now the `Name` column of whichever tables declare one, data rows only, skipping fenced examples — so a second table, an example row and the heading itself all donate nothing. A file that declares no such column authorizes nobody, which is the same choice as a missing file.

**When the proof of a person starts.** This control establishes **who is authorized** to decide. Proof that a person rather than an agent recorded the decision starts with the **next** decision, by commit signature. A signature is evidence that a specific private key was present when the commit was made; an author field is a string anyone can set, which is why the author field cannot carry this. Nothing in the published history is signed — measured on `main` at `12ca5cd` on 2026-10-04:

```
$ git log 12ca5cd --format='%G?' | sort -u
N
```

`N` is git's code for no signature, and it is the only value every commit reachable from that one returns. The ref is a commit rather than a branch name so the measurement stays reproducible; `tests/test_doc_claims.sh` runs the command and refuses a transcript git disagrees with.

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
| `no-accounting` | no `accounting:ids` block, so there is nothing to compare |
| `unaccounted` | a finding in the source the block does not list |
| `invented-accounting` | an id accounted for that is not in the source |
| `duplicate-accounting` | an id listed twice |
| `counts-disagree` | theme counts plus outliers do not sum to the ids accounted for |
| `no-declared-count` | `from:` links a source and states no item count |
| `declared-count` | the count `from:` declares is not the number of findings the source records |
| `source-unreadable` | the ids of the declared source could not be read |
| `no-outlier-section` | no outlier section at all |
| `silent-empty-outliers` | the section lists nothing and does not say it is empty |
| `no-source` | the record links no source artifact |
| `source-unresolved` | the declared source does not resolve |
| `source-is-example` | the declared source is marked `example: yes`, so it is not a real scan |

**Evidence.** The counts reconcile against the source artifact, which is linked and resolvable. This control caught a real defect before it was mechanised: a draft that grouped 54 of 64 findings and reported three wrong counts, where the ten strays included a pattern nobody had named.

**Evidence note.** The accounting is a **set comparison by id**, not arithmetic. It was a total until 2026-10-03, when an external audit broke it two ways — lowercasing a finding's first letter removed it from the denominator, and two theme counts could move in opposite directions with the total reconciling.

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
| `silent-empty-open` | the section lists nothing and does not say so |
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

**What it does not cover.** Three things. The first is the limit of the repaired check, and is in *What is not controlled*, item 11. The other two of the checks the contract hoped for are **not mechanisable**, and the gate's own header says so rather than leaving the gap implicit:

- **"Every claim carries a grade"** and **"every claim carries a source"** need a claim to be a delimited thing. The two topics write claims as prose paragraphs in different markup with no boundary a script can find. Checking this would mean inventing a convention mid-gate. What is checked instead is that the grades *used* are from the enum and that the enum is declared.
- **"No recommendation language"** is covered under *What is not controlled*, item 3.

---

## CTRL-8 · Every graded claim in STANDARDS.md resolves to something a reader can open

**What it prevents.** The loop's output document asserting evidence it does not have. `STANDARDS.md:5` says *"Every claim carries a grade. The grade is the point of this document"* — and until 2026-10-03 it carried 31 graded claims, zero citations, and one route to evidence that was a branch which does not exist on origin.

**Enforced by** `bin/validate-standards.sh`.

| Refusal | Condition |
|---|---|
| `uncited-claim` | a line carrying an `[E]` or `[S]` marker anywhere on it, citing no source ID |
| `unknown-source` | a cited ID absent from the register |
| `source-no-link` | a register entry with no URL, DOI or path |
| `no-register` | no source register at all |
| `dangling-ref` | a document points at a path, commit, branch or tag this repository does not have |
| `empty-register` | the register declares no IDs |

**Evidence.** [`SOURCES.md`](SOURCES.md) — 22 sources, each with its population, finding and limitation. Vendor-affiliated empirical studies carry that in the class column so it cannot be read past.

**Evidence note on the evidence pointer.** The check matched backtick-quoted strings beginning `experiment/` or `branch/` — the two namespaces the one known defect happened to use. The pointer this repository actually depends on is a commit: the corpus is in history and not on any branch, and `DECIDERS.md` records that the planned identity cleanup is a force-push rewriting every SHA. Replacing that commit with a dead one left the gate reporting every document clean. It now checks any backticked token that contains a `/` or is a hexadecimal object name, against the working tree and against git.

**Evidence note.** Until 2026-10-03 the gate skipped any line starting with `|` or `> ` and matched only four marker forms — `**[E]`, `**[S]`, `[E]/[S]`, `[S]/[P]`. A bare `[E]`, a table row and a blockquote all passed uncited, and a bare marker is this repository's own house style for a graded claim. A marker is now read wherever it appears on a line. Repairing the detection found one real uncited `[S]` claim in the shipped document — §3's configuration requirement — which now cites `S-NIST-AC5`, the standard the practice two paragraphs above it already rests on.

**What it does not cover.**

- **Whether the cited source supports the claim.** The gate checks a citation resolves, not that it is apt. A reader is still the only check on that.
- **A one-level branch or tag name is not checked.** The gate treats a backticked token as a pointer when it contains a `/` or is a hexadecimal object name. `main` and `v0.1` in backticks cannot be told apart from an ordinary word or a version number in prose, and guessing would refuse `v4.0.1` in a sentence about PCI DSS. A dead branch named without a namespace would pass.
- **A reference to another repository has to be a link, not backticks.** The cost of the rule above, stated plainly: `owner/name` and `experiment/0.0.0` are the same shape, so a backticked repository slug in one of these four documents is refused. The refusal says to link it instead. That is a deliberate false positive, chosen over leaving a dead branch unchecked, and it is loud rather than silent.
- **The gate refuses to run in a shallow clone.** It resolves pointers into history, and a depth-1 checkout does not contain the commit the documents cite. It exits 2 — *the gate could not run* — rather than reporting the documents clean having resolved nothing. The `tests` job checks out with `fetch-depth: 0` for that reason.
- **A pointer declared dead is taken at its word.** A document may record that a pointer is dead, declared in band and naming the pointer: `<!-- dead-pointer: experiment/0.0.0 — reason -->`. The gate checks the declaration names that pointer and carries a reason, not that the reason is true. This was a match on four phrases anywhere on the line until 2026-10-03, which meant `SOURCES.md` line 5 — naming the dead branch and the live commit in one sentence — exempted both, and replacing the live commit with a dead one was accepted.
- **A line that declares itself not a claim is taken at its word.** Some lines carry a grade marker without grading anything: the table that defines what each grade means, and a sentence about the scheme rather than graded by it. Those are declared in band, `<!-- not-a-claim: reason -->`, and the gate prints how many it honoured — three, at the time of writing. It checks that the declaration is present and carries a reason, not that the reason is true, so an author can exempt a real claim. That is a weaker control than no exemption at all and a stronger one than what it replaced, which exempted every table row and every blockquote in the document, silently and without a reason.
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

## What is not controlled

The section an assessor should read first. Each of these is a real gap, not a formality.

**0. Whether a cited source actually supports the claim it is cited for.** CTRL-8 establishes that a citation resolves. Nothing establishes that the paper says what the sentence says it says. Four of the register's entries carry limitations that materially bound the claim — three are vendor-affiliated, and `S-METR-2026-01` carries its own authors' statement that the results are unreliable. A reader who does not open the register will not know.

**1. Whether an approver actually reviewed.** CTRL-1 makes a decision attributable. It cannot distinguish a person who read the change from one who clicked approve. `STANDARDS.md` §3 now requires a natural person to hold the approving position, and the decision that set that policy records the cost explicitly: a machine approval is visible in a platform audit log, a human rubber stamp is not, so the policy **moves a detectable failure into an undetectable one.**

**1b. Whether a finding was moved between themes.** CTRL-4 detects a dropped or invented finding and not a relabelled one. See CTRL-4.

**2. Whether a machine approval can satisfy a separation-of-duties control.** **Undecided, in both directions.** NIST SP 800-53 AC-5 is written in terms of *"different individuals or roles"* and routes enforcement through IA-2 *Organizational Users* rather than IA-9 *Service Identification*, saying nothing either way. The PCI DSS clause that would settle it could not be obtained. `STANDARDS.md` §3 carries this as `[O]`. **Our position is a practice we chose, not a requirement we met.**

**3. Judgement in a discovery artifact.** The discovery contract forbids recommendation language, and that check is deliberately **not** mechanised. A pattern match on *recommend* fires on the sentence "No option set, no recommendation, no decision" — flagging a correct disclaimer as the thing it disclaims. The real failure is a neutral-sounding paragraph that steers, which no pattern catches. This stays a reader's job.

**4. Whether every claim in a discovery artifact is graded and sourced.** CTRL-7 gates the phase now, but not this. It needs a claim to be a delimited thing, and the two topics write claims as prose paragraphs in different markup with no boundary a script can find. The gate checks that the grades *used* are from the enum, not that every assertion carries one. A reader counting graded claims against ungraded ones is still the only way to know.

**5. Develop has no gate.** One options artifact existed when its contract was written, so a gate would have encoded that artifact's accidents. The reasoning that justified waiting still holds.

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

**What replaces it is a start date, not an enforcement.** CTRL-1 now records that proof of a person begins with the next decision, by commit signature, and that the two existing decisions predate the obligation. It carries the command and the measurement that show no commit in the published history is signed. Signing for decision commits is not configured and configuring it is the decider's, so the honest position is that the proof obligation starts, not that it is met.

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
