# Controls

**What this is.** The controls this process enforces, the evidence each one produces, and what each one does **not** cover. Written for someone who has to assess whether the process is sound, not for someone using it.

**What this is not.** Not a compliance assertion. This repository has not been audited against SOC 2, ISO 27001, PCI DSS or anything else, and nothing here should be read as a claim that it would pass. It demonstrates a process shaped so that controls are statable and evidenced.

**Derived, not designed.** Every control below describes a gate that already exists. None was written as a requirement first. Each cites the refusal its gate actually emits, and `tests/test_controls.sh` fails if a cited refusal is not in the named script — so a control cannot drift from its enforcement.

**The evidence trail for every control below is git.** Every artifact, its author, its date, and the merge that accepted it. There is no separate audit store to keep in step.

**What that does not include.** The issue and pull request bodies by which this repository was *built* live in GitHub's database. A merge commit carries the pull request number and its title and nothing else — no validation method, no evidence section. So a clone can follow the chain the loop **produces** end to end, and cannot see what any individual engineering change was intended to do. `AGENTS.md` claimed *"all of it in git"* until 2026-10-03, when an external audit caught it. See *what is not controlled*, item 9.

---

## CTRL-1 · A decision is made by a named natural person

**What it prevents.** An unattributed decision, and a machine closing the loop on its own work. If nobody is named, nobody chose, and the record is describing an outcome rather than a decision.

**Enforced by** `process/05-deliver/validate-decision.sh`.

| Refusal | Condition |
|---|---|
| `undecided-by` | `chosen:` is set and `decided_by:` is empty |
| `not-a-person` | `decided_by:` names someone not listed in [`DECIDERS.md`](DECIDERS.md) |
| `undated-decision` | a decided record carries no date |
| `pending-but-decided` | the record claims both states at once |

**Evidence.** The decision record, the git commit author, the commit date, and the merge. `chosen: pending` is a valid recorded state, so a decision that has not been made is distinguishable from one that was never asked for.

**Evidence note.** The allowlist was read out of [`DECIDERS.md`](DECIDERS.md) as the first cell of every row in the file, header included, so `decided_by: Name` was an authorized decider until 2026-10-03. It is now the `Name` column of whichever tables declare one, data rows only, skipping fenced examples — so a second table, an example row and the heading itself all donate nothing. A file that declares no such column authorizes nobody, which is the same choice as a missing file.

**What it does not cover.** Whether the named person actually read the change. A name is attributable, not a guarantee of attention — see *What is not controlled*, item 1.

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
| `amends-not-reciprocated` | the amended document does not cite the decision back |

**Evidence.** The `amends:` field on the record and the `decided:` link on the amended claim. `STANDARDS.md` §3 and `process/05-deliver/decisions/agent-pr-approval.md` are the worked pair.

**What it does not cover.** Two things, both stated in the contract rather than implied:

- **Skills.** The stated output is "standards *and our skills*". Skills are not in this repository, so this reaches one of the two.
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
| `no-outlier-section` | no outlier section at all |
| `silent-empty-outliers` | the section lists nothing and does not say it is empty |
| `no-source` | the record links no source artifact |
| `source-unresolved` | the declared source does not resolve |

**Evidence.** The counts reconcile against the source artifact, which is linked and resolvable. This control caught a real defect before it was mechanised: a draft that grouped 54 of 64 findings and reported three wrong counts, where the ten strays included a pattern nobody had named.

**Evidence note.** The accounting is a **set comparison by id**, not arithmetic. It was a total until 2026-10-03, when an external audit broke it two ways — lowercasing a finding's first letter removed it from the denominator, and two theme counts could move in opposite directions with the total reconciling.

**What it does not cover.**

- **A finding moved between themes.** Moving a count from one theme to another leaves the set unchanged and still reconciles. That is a count-accuracy defect rather than a dropping defect, and closing it needs per-theme ids — required by `define-contract.md` from the next cycle. Cycle `2026-09-29` predates ids and recorded counts only, so its membership is not recoverable and its artifact says so rather than reconstructing a mapping nobody made.
- **Whether the grouping is useful.** Accounting for every item says nothing about whether the themes are the right themes.

---

## CTRL-5 · How a grouping was produced is declared

**What it prevents.** A reader trusting a grouping without knowing whether a person, a model or a classifier made it.

**Enforced by** `process/03-define/validate-define.sh`, refusal `no-method`.

**Evidence.** The `method:` field on every cycle record.

**What it does not cover.** Whether the declared method was the method used. This is a declaration, not an attestation.

---

## CTRL-6 · A findings record matches its declared contract

**What it prevents.** A cycle record that cannot be compared with the next one, and a finding with no source. The scan runs repeatedly, so drift in shape is the risk worth mechanising against.

**Enforced by** `process/01-scan/validate-findings.sh`, with fifteen refusals including `no-source`, `nothing-found`, `empty-cycle`, `since`, `consequence`, `kind`, `contradiction` and `filename`.

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

**10. Who committed a decision.** CTRL-1 establishes that `decided_by` names an authorized person. It does not establish that the person, rather than an agent, wrote the field. Every commit on `main` is authored under one address, `imagineux@gmail.com`, under two display names, so `git log` cannot separate the parties — the same shape `STANDARDS.md` 3 convicts a vendor of, one account with two display names. The identity `DECIDERS.md` declares a decision commit must carry authors no commits at all.

Run `bin/validate-authorship.sh` for the live tally, or `git log main --format='%an <%ae>' | sort | uniq -c` in a clone. The numbers are not repeated here on purpose: this section carried a transcribed tally until 2026-10-03 and it was wrong, because it had been measured in a working tree holding unpushed branches. `DECIDERS.md` holds the one transcribed copy, labelled with the ref and the date.

`bin/validate-authorship.sh` checks it and **refuses today**: a commit setting `chosen:` must be authored by the identity declared in `DECIDERS.md`, and that identity must not be shared. Neither holds. It is deliberately **not wired into CI**, because a gate that cannot pass blocks every branch, and what turns it on is a configuration change plus a workflow change that both belong to the decider. `DECIDERS.md` states exactly what they are, and they are **deferred to a git history cleanup on `main`** — a force-push that rewrites every SHA and therefore every commit citation in the tracked documents. Tracked as issue #51 and not scheduled into a sprint.

**11. Whether a person checked what a coverage part says they checked.** CTRL-7 requires the verified-by-hand part, and the reached and not-reached parts, to name something the artifact carries somewhere else — a file, an id, a measurement, a product, an address. That establishes two things and no more: the part names something checkable, and the artifact itself carries that thing. It does not establish that anybody looked at it.

The sentence below was run against the repaired gate on 2026-10-03 and **passes**:

```
### Verified by hand

1. Nothing in the GitHub REST API or the SemIf source was verified by hand.
```

Both names resolve, so the part names things, and the sentence denies checking them. Nothing mechanical closes that, which is why the repaired gate is written as *names a referent* rather than as *was verified*. A reader is still the only check on whether a coverage part is true. What has changed is narrower and worth stating exactly: a part naming nothing at all is now refused however it is punctuated, where before two commas were enough.

**12. A gate refuses on the authority of a document nobody accepted.** [`bin/validate-claims.sh`](bin/validate-claims.sh) enforces the rule against speed and velocity claims and names [`intent.md`](intent.md) as the authority when it refuses. `intent.md` is marked *draft, unaccepted*, and six other tracked files cite it as binding; its status line now lists all seven. So a reviewer asking what authorized a refusal is told the root document is a draft nobody accepted.

Stated rather than closed, for one reason: accepting `intent.md` is a decision by a named decider under [`DECIDERS.md`](DECIDERS.md), and an agent writing "accepted" into a status line would be item 10's defect wearing different clothes — a document asserting a state nothing produced. The check that would close it is *no gate names a document that declares itself unaccepted*. It cannot pass until the decider acts, which is the same position `bin/validate-authorship.sh` is in, so it is written down here and not added.
