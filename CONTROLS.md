# Controls

**What this is.** The controls this process enforces, the evidence each one produces, and what each one does **not** cover. Written for someone who has to assess whether the process is sound, not for someone using it.

**What this is not.** Not a compliance assertion. This repository has not been audited against SOC 2, ISO 27001, PCI DSS or anything else, and nothing here should be read as a claim that it would pass. It demonstrates a process shaped so that controls are statable and evidenced.

**Derived, not designed.** Every control below describes a gate that already exists. None was written as a requirement first. Each cites the refusal its gate actually emits, and `tests/test_controls.sh` fails if a cited refusal is not in the named script — so a control cannot drift from its enforcement.

**The evidence trail is git.** Every artifact, its author, its date, and the merge that accepted it. There is no separate audit store to keep in step.

---

## CTRL-1 · A decision is made by a named natural person

**What it prevents.** An unattributed decision, and a machine closing the loop on its own work. If nobody is named, nobody chose, and the record is describing an outcome rather than a decision.

**Enforced by** `process/05-deliver/validate-decision.sh`.

| Refusal | Condition |
|---|---|
| `undecided-by` | `chosen:` is set and `decided_by:` is empty |
| `not-a-person` | `decided_by:` names a role, a team, or a model |
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
- **The reciprocal check is a substring match**, not anchor-aware. A document that mentions the decision's filename anywhere satisfies it.

---

## CTRL-4 · The change record is complete — nothing is dropped

**What it prevents.** Silent suppression. A summary that quietly discards items is indistinguishable from one that covers them, and the repository holds that *"a classifier that wrongly suppresses something is worse than no classifier."*

**Enforced by** `process/03-define/validate-define.sh`.

| Refusal | Condition |
|---|---|
| `unaccounted` | themes plus outliers do not equal the source item count |
| `no-outlier-section` | no outlier section at all |
| `silent-empty-outliers` | the section lists nothing and does not say it is empty |
| `no-source` | the record links no source artifact |
| `source-unresolved` | the declared source does not resolve |

**Evidence.** The counts reconcile against the source artifact, which is linked and resolvable. This control caught a real defect before it was mechanised: a draft that grouped 54 of 64 findings and reported three wrong counts, where the ten strays included a pattern nobody had named.

**What it does not cover.** Whether the grouping is *useful*. Accounting for every item says nothing about whether the themes are the right themes.

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

## What is not controlled

The section an assessor should read first. Each of these is a real gap, not a formality.

**1. Whether an approver actually reviewed.** CTRL-1 makes a decision attributable. It cannot distinguish a person who read the change from one who clicked approve. `STANDARDS.md` §3 now requires a natural person to hold the approving position, and the decision that set that policy records the cost explicitly: a machine approval is visible in a platform audit log, a human rubber stamp is not, so the policy **moves a detectable failure into an undetectable one.**

**2. Whether a machine approval can satisfy a separation-of-duties control.** **Undecided, in both directions.** NIST SP 800-53 AC-5 is written in terms of *"different individuals or roles"* and routes enforcement through IA-2 *Organizational Users* rather than IA-9 *Service Identification*, saying nothing either way. The PCI DSS clause that would settle it could not be obtained. `STANDARDS.md` §3 carries this as `[O]`. **Our position is a practice we chose, not a requirement we met.**

**3. Judgement in a discovery artifact.** The discovery contract forbids recommendation language, and that check is deliberately **not** mechanised. A pattern match on *recommend* fires on the sentence "No option set, no recommendation, no decision" — flagging a correct disclaimer as the thing it disclaims. The real failure is a neutral-sounding paragraph that steers, which no pattern catches. This stays a reader's job.

**4. Whether every claim in a discovery artifact is graded and sourced.** CTRL-7 gates the phase now, but not this. It needs a claim to be a delimited thing, and the two topics write claims as prose paragraphs in different markup with no boundary a script can find. The gate checks that the grades *used* are from the enum, not that every assertion carries one. A reader counting graded claims against ungraded ones is still the only way to know.

**5. Develop has no gate.** One options artifact existed when its contract was written, so a gate would have encoded that artifact's accidents. The reasoning that justified waiting still holds.

**6. Configuration drift.** §3 requires two repository toggles to stay off. GitHub publishes **no API representation** for that approvals policy, so the setting cannot be read, set or drift-checked programmatically. It is a UI setting and a promise. Nobody has verified the current state of our own repositories.

**7. Cadence.** Nothing is scheduled. A missed cycle is invisible, which also means the first early-reversal condition of decision `producing-themes` cannot currently fire.

**8. This is not an audit.** No external party has assessed any of the above. Issue #22 is the first attempt to have someone outside the team try to break the chain, and an agent with no prior context is a cheap proxy for a colleague who has never seen the repository, not an equivalent.
