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

**Evidence.** The options artifact, dated before the decision, with each option's cost, assumption, failure mode and the condition that would make it right.

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
| `empty-verified-by-hand` | the part exists and names nothing |
| `empty-coverage-part` | a reached or not-reached part asserts a state instead of naming things |
| `no-not-reached` | coverage lists only what was reached |
| `no-question` | the question is not in the asker's own words |
| `question-not-quoted` | the question section carries no quotation |
| `grade-not-in-enum` | a grade outside `E`, `S`, `V`, `P`, `O` |
| `no-grades` | no graded claims at all |
| `no-where-this-stops` | does not record what a later phase will need |
| `link-unresolved` | a local link that does not resolve |
| `undated` | no `dated:` field |
| `no-status` | no `status:` field |

**Evidence.** Coverage in three parts — reached, not reached, and **verified by hand** — which is what separates *an agent reported this* from *someone checked it*. Both shipped topics pass despite differing in markup, so the gate checks the contract rather than one artifact's formatting.

**What it does not cover.** Two of the checks the contract hoped for are **not mechanisable**, and the gate's own header says so rather than leaving the gap implicit:

- **"Every claim carries a grade"** and **"every claim carries a source"** need a claim to be a delimited thing. The two topics write claims as prose paragraphs in different markup with no boundary a script can find. Checking this would mean inventing a convention mid-gate. What is checked instead is that the grades *used* are from the enum and that the enum is declared.
- **"No recommendation language"** is covered under *What is not controlled*, item 3.

---

## CTRL-8 · Every graded claim in STANDARDS.md resolves to something a reader can open

**What it prevents.** The loop's output document asserting evidence it does not have. `STANDARDS.md:5` says *"Every claim carries a grade. The grade is the point of this document"* — and until 2026-10-03 it carried 31 graded claims, zero citations, and one route to evidence that was a branch which does not exist on origin.

**Enforced by** `bin/validate-standards.sh`.

| Refusal | Condition |
|---|---|
| `uncited-claim` | an `[E]` or `[S]` claim citing no source ID |
| `unknown-source` | a cited ID absent from the register |
| `source-no-link` | a register entry with no URL, DOI or path |
| `no-register` | no source register at all |
| `dangling-ref` | a document points at a git ref that does not exist |
| `empty-register` | the register declares no IDs |

**Evidence.** [`SOURCES.md`](SOURCES.md) — 22 sources, each with its population, finding and limitation. Vendor-affiliated empirical studies carry that in the class column so it cannot be read past.

**What it does not cover.**

- **Whether the cited source supports the claim.** The gate checks a citation resolves, not that it is apt. A reader is still the only check on that.
- **`[P]` and `[O]` claims have no source by design** — a practitioner observation is ours, an open question has none.
- **Register entries nothing cites are reported, not refused.** The first version refused them, which would have forced deleting real sources or attaching them to claims they do not support.

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

**10. Who committed a decision.** CTRL-1 establishes that `decided_by` names an authorized person. It does not establish that the person, rather than an agent, wrote the field. Three git identity variants exist in this history and two share an address, so `git log` cannot separate the parties — the same shape `STANDARDS.md` 3 convicts a vendor of, one account with two display names.

`bin/validate-authorship.sh` checks it and **refuses today**: a commit setting `chosen:` must be authored by the identity declared in `DECIDERS.md`, and that identity must not be shared. Neither holds. It is deliberately **not wired into CI**, because a gate that cannot pass blocks every branch, and what turns it on is a configuration change plus a workflow change that both belong to the decider. `DECIDERS.md` states exactly what they are.

**9. Why any individual engineering change was made.** The chain the loop produces is complete in a clone. The chain by which this repository was built is not: issue and pull request bodies live in GitHub's database, so a clone shows that a change was reviewed and merged but not what it was intended to do or how that was to be validated. An assessor holding only a clone can assess the process and not its own construction.

Three ways to close it were weighed and none chosen yet, because each has a real cost: stop claiming it — done, this is that; mirror merged pull request bodies into tracked files, which is more duplicated state of the kind this repository keeps being burned by; or move the intent itself into git and leave the GitHub issue as a pointer, which is the most honest and the largest change.
