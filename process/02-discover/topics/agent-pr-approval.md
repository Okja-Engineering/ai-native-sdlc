# Discovery — agent approval of pull requests

dated: 2026-10-01
status: discovery complete, not assessed. Two items open and consequential — see *What could not be established*.

## The question, in the asker's own words

> "do the agent approval one, **it has a clock**"

The clock is the reason this topic was selected ahead of others, and it is the part the discovery contradicted. The premise is preserved verbatim because a tidied restatement would hide that the selection criterion turned out not to hold.

The question underneath it comes from a collision the Define cycle recorded. `STANDARDS.md` §3 **[S]** states the practice as separation of duties: *"A second, independent evaluator — human or a separate agent with no memory of building it."* It does not forbid an agent approving a pull request. It forbids the same party authoring and approving. So the question is not "are agents approving pull requests" but:

**Can the agent that wrote a pull request be the thing that approves it?**

## Two passes, briefed to fail differently

A mechanics pass and a counter-case pass, separately briefed, no shared context. One pass to establish what the feature does; one whose only job was to find the limits, on the contract's stated grounds that *nothing markets a limitation.*

Scaled down from the three passes the classifier topic used. That question was "is this substance or marketing" and needed an advocate for the counter-case. This one is product mechanics with a partly documented answer, so the third pass had nothing distinct to do.

**Both passes corrected their own briefs, and the corrections are the most consequential findings in this artifact.** Both appear below rather than being quietly folded in.

---

## Claims

**Grades** are the `STANDARDS.md` scheme: `[E]` empirical · `[S]` standard · `[V]` vendor, never outcome evidence · `[P]` practitioner, unmeasured · `[O]` open, could not establish.

> *Added 2026-10-03.* This artifact never declared the scheme, and the gate did not say so: its grade-key check matched any prose line pairing the word "vendor" with a `[V]` marker, which this artifact has several of. A reader meeting `[V]` here for the first time had no way to know it is never outcome evidence. The check is tightened and the key is where it should have been — a reader aid added, not a claim changed.

### The capability

**GitHub states the feature is in public preview:** *"This feature is available in public preview to GitHub Copilot Pro, Pro+, Max, Business, and Enterprise plans."* **[V]** — [changelog, 2026-09-01](https://github.blog/changelog/2026-09-01-copilot-code-review-can-now-approve-pull-requests/)

**GitHub states it is off by default:** *"By default, Copilot will not approve pull requests."* Configurable at enterprise, organization and repository level. **[V]** — same source

**GitHub states an approval satisfies a required-approval rule** *"the same way a teammate's approval would."* **[V]** — same source

**The repository level carries two independent toggles**, not one: *allow Copilot to approve*, and separately *allow Copilot approvals to count toward merge requirements*, plus up to 15 file globs where every changed file must match for the approval to count. The changelog does not mention the second toggle. **[V]** — relayed from the mechanics pass, read in GitHub's configuration documentation

**Configuration delegates downward, not upward.** Enterprise options are *Let organizations decide* / *Enable for selected orgs* / *Disabled everywhere* (documented default). Organization and repository each narrow further. **[V]** — relayed

### Whether an agent can approve its own pull request

**GitHub documents nothing either way. [O]**

Not addressed in the 2026-09-01 changelog, nor in GitHub's code-review configuration or concept pages. A repository-wide search of `github/docs` for `"approve its own"`, `"self-approve"`, `"self-approval"`, `"cannot approve"` and `"approve pull requests it"` returned no statement about the code-review reviewer's identity. **[O]** — relayed from the mechanics pass; the changelog's silence verified by hand.

**Observed behaviour: it happens, measured. [E]**

Measured independently on 2026-10-01 against the GitHub search and REST APIs, not relayed:

| Measure | Value |
|---|---|
| Copilot-authored PRs since 2026-09-01, reviewed by the Copilot reviewer, carrying an approval | **875** |
| Copilot-authored PRs since 2026-09-01 carrying any approval (control) | 1,494 |
| Sample inspected review-by-review | **300** |
| Copilot was the **sole** approving reviewer | **31 (10%)** |
| Copilot approved alongside a human | 12 (4%) |
| The approval came from **someone other than Copilot** | **257 (85%)** |

**The headline count overstates the phenomenon by roughly seven times if read directly.** `reviewed-by:app/copilot-pull-request-reviewer review:approved` selects pull requests Copilot *reviewed* which *someone* approved. In 85% of the sample that someone was human. The quantity of interest is the 10% where no human approved at all — about 90 pull requests of the 875 when extrapolated.

**A correction to the pass that produced this finding.** The mechanics pass reported 15% as the sole-approver rate. The independent 300-item measurement puts the sole-approver rate at 10% and the "Copilot approved a pull request it authored" rate at 14%. The pass's 15% corresponds to the second measure, not the first. The distinction is load-bearing for the question this artifact asks, so the recomputed figures are the ones carried.

**The mechanical reason the author rule does not engage. [E]** The authoring actor (`copilot-swe-agent[bot]`, presenting as `Copilot`, type `Bot`) and the reviewing actor (`copilot-pull-request-reviewer[bot]`) are **different accounts**. GitHub's rule that authors cannot approve their own pull requests is evaluated per account. Both identities are documented by GitHub; the consequence of their being distinct is not.

**A correction to a widely repeated reading. [V]** GitHub's statement that Copilot *"cannot approve or merge a pull request"* appears in its coding-agent risks documentation and is scoped to the **coding agent as actor**. Secondary write-ups quote it as answering the question in this section. It does not, and the measurement above contradicts that reading.

### Whether such an approval can clear a merge gate

**One case verified end to end by hand. [E]**

[`Andrew199617/js-syntax-extension#65`](https://github.com/Andrew199617/js-syntax-extension/pull/65), read directly from the REST API:

| Field | Value |
|---|---|
| Author | `Copilot`, type `Bot` |
| Only `APPROVED` review | `copilot-pull-request-reviewer[bot]` |
| Ruleset | `Restrict Push To Master`, enforcement **active** |
| `required_approving_review_count` | **1** |
| `bypass_actors` | **0 — empty** |
| `require_extra_approval_for_unattributed_changes` | `false` |
| Ruleset `updated_at` | 2026-09-26 21:27, predating the merge |
| Merged | 2026-09-27 14:02, into `master` |

An agent's approval of a pull request that agent authored satisfied an active required-approval rule with an empty bypass list, and the pull request merged.

The mechanics pass recorded a caveat that the merge was performed by the repository owner, who might hold a bypass. The empty `bypass_actors` list was read by hand afterwards and narrows that caveat, without closing the general question of implicit administrator capability.

**n = 1.** One case establishes that the path exists. It does not establish a rate.

### A guardrail exists, and its scope is narrower than its name

**GitHub states rulesets carry `require_extra_approval_for_unattributed_changes`, enabled by default on new and existing rulesets. [V]** Verified `true` by hand on `dotnet/runtime`, `primer/react` and `microsoft/vscode`; not readable on `github/docs`. **[E]** for those three.

Two limits on what it does:

- GitHub scopes it to pull requests Copilot opens *"under its own app identity instead of on behalf of a person"* — the ordinary issue-assignment flow is stated not to be covered. **[V]** — relayed
- It raises a **count**, not a **kind**. An N+1 threshold can be met by a second machine approval where one is available. **[E]** by construction from the field's semantics
- It was `false` on the one repository where a Copilot-only approval was observed to merge. **[E]**

### The stale-approval reassurance conflicts with GitHub's own documentation

**GitHub states:** *"If new commits are pushed after Copilot approves, its approval is dismissed just like a human reviewer's."* **[V]** — [changelog, 2026-09-01](https://github.blog/changelog/2026-09-01-copilot-code-review-can-now-approve-pull-requests/), verified by hand

**GitHub also states**, of human approvals: *"**Optionally**, you can choose to dismiss stale pull request approvals when commits are pushed that affect the diff in the pull request."* **[V]** — [about protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), verified by hand

`dismiss_stale_reviews_on_push` is a per-ruleset opt-in boolean. The two statements are in tension: on a repository that has not enabled it, behaving *just like a human reviewer's* means the approval is **not** dismissed. No GitHub document reconciles them. **[O]** as to actual behaviour.

The one repository where a merge was observed had `dismiss_stale_reviews_on_push: true`, so this tension did not arise there. **[E]**

### The clock — the brief's premise, corrected

**Both passes independently reported that the 2026-10-22 policy does not reach this feature.** Verified by hand against both primary sources:

- *"The policy does not apply to features in preview."* **[V]** — [default availability](https://docs.github.com/en/copilot/concepts/enterprise/default-availability)
- *"This feature is available in public preview."* **[V]** — the 2026-09-01 changelog

**What 2026-10-22 does do. [V]** An enterprise owner selects *Enabled* / *Disabled* / *Let organizations decide*; from that date, eligible **GA** features left *Unconfigured* follow it, and explicit decisions are preserved. The unconfigured default is **Enabled** — a sentence that appears in the documentation and not in the changelog. — [changelog, 2026-09-24](https://github.blog/changelog/2026-09-24-default-enablement-of-copilot-features-for-copilot-business-and-enterprise); date and effect verified by hand

**The linkage is deferred, not absent. [V]** The same documentation puts *"Features that move from preview to GA"* in the policy's scope. A GA transition would therefore inherit a default already set, with no separate decision point at that moment.

**No GA announcement exists.** The mechanics pass reported zero changelog entries dated 2026-10, with the latest site-wide entry 2026-09-30. **[O]** as to date.

### Other platforms

**Microsoft states, of Azure DevOps — the same vendor:** *"Copilot always leaves a **Comment** review. It never approves the pull request or requests changes, so its review doesn't satisfy required-reviewer policies and doesn't block merging."* **[V]** — [Microsoft Learn, dated 2026-09-29](https://learn.microsoft.com/en-us/azure/devops/repos/git/copilot-code-reviews?view=azure-devops), verified by hand. That page also marks the feature *"in limited preview."*

**GitLab Duo:** approval is a proposal, not shipped — [issue #507336](https://gitlab.com/gitlab-org/gitlab/-/issues/507336), which itself states *"For regulated environments, configure Duo as an advisory reviewer only."* **[V]** — relayed. Search summaries claiming Duo ships approvals could not be confirmed against a GitLab primary source and are not carried.

**Greptile** is the one shipped peer found, and is scoped more tightly than GitHub: gated on a clean review plus a configurable risk ceiling, with auth, secrets, billing, migrations, infrastructure, CI and public APIs excluded. GitHub publishes no confidence threshold or risk-category exclusion. **[V]** — relayed

**CodeRabbit, Qodo, Graphite, Bitbucket, Gerrit: [O].** Only commercially interested sources were found.

### Governance

**NIST SP 800-53 AC-5** is written in terms of *"different individuals or roles"*, and its stated enforcement runs through IA-2 (*Organizational Users*), IA-4 and IA-12 — not IA-9 (*Service Identification and Authentication*). It contains no statement for or against a non-person entity holding a separated duty. **[S]** as to text; **[O]** as to application. — relayed, read from NIST's OSCAL JSON rather than a restatement

**PCI DSS 6.2.3.1** is reported to name author-independence explicitly, but the official text could not be obtained (403 and 404 from PCI SSC). Whether the author-independence clause attaches only to *manual* review, while 6.2.3 separately permits automated review, is unresolved. **[P]**, not **[S]**.

**SOC 2:** no authoritative AICPA guidance found; the available vendor commentary conflicts and is commercially interested. **[O]**

**ISO 27001 A.5.3:** text paywalled. **[P]**

**Audit trail. [V]** `pull_request_review.submit` is reported to carry `actor_is_agent` and `actor_is_bot`, so a machine approval is distinguishable in the audit log — but to carry no review-state field, so the log alone does not separate an approval from a comment-only review. Symmetric, and not specific to Copilot. — relayed

### Measured attention

The 2026-09-01 changelog scored **1 point and 0 comments** on Hacker News (item 49529323), as did the preceding Copilot review changelog — computed from the Algolia API. This measures Hacker News attention and nothing else. **[E]** — relayed

The counter-case pass also recorded that the "rubber stamp" discussion surfaced by search concerns **humans** rubber-stamping Copilot-written code — the inverse concern — and predates this feature. **[E]** — relayed

### A live documentation contradiction

`data/reusables/repositories/request-changes-tips.md` in `github/docs` states that approvals by GitHub Copilot *"do not count toward those requirements."* Its presence was confirmed by hand via the code search API (1 result). The mechanics pass reports it last modified 2025-12-02, predating the feature, and still rendering on the general pull-request review pages. A reader arriving from the pull-request documentation rather than the Copilot documentation is told the opposite of the feature documentation. **[E]** for existence; **[V]** for which surface is current.

### Operational notes

**Copilot code review runs on GitHub Actions.** Where GitHub-hosted runners are disabled, GitHub states the review falls back to *"a more limited review."* **[V]** — relayed

**Roughly 50 named files and 17 glob patterns are excluded from review** — `package-lock.json`, `go.sum`, `Cargo.lock`, `requirements.txt`, `build.gradle`, `**/vendor/**`, `**/generated/**` among them. A dependency-bump pull request can consist entirely of excluded files. Whether Copilot withholds approval when every changed file is excluded is undocumented. **[V]** for the register; **[O]** for the interaction. — relayed

**No API representation found.** The counter-case pass reports `copilot_approv`, `auto_approval`, `unattributed` and `extra_approval` at zero occurrences in the 13 MB published OpenAPI description, with sibling fields counted to demonstrate the negative is not a mis-grep. On that reading the approvals policy is UI-only: not readable, settable, or drift-detectable through a documented API. **[V]** — relayed, not re-verified. Note this sits in tension with `require_extra_approval_for_unattributed_changes` being readable via the rulesets API, which was verified by hand; the two may be describing different fields.

**An asymmetry in GitHub's own language. [V]** GitHub's API description labels `can_approve_pull_request_reviews` — the GitHub Actions equivalent — *"Whether GitHub Actions can approve pull requests. **Enabling this can be a security risk.**"*, and OpenSSF is reported to rate that misconfiguration HIGH. No equivalent language is attached to Copilot approvals. — relayed

---

## Coverage

### Reached

Both passes: 30 sources (counter-case) and the `github/docs` repository plus GitHub's changelog, concept and configuration pages (mechanics). Directly, for this artifact: the 2026-09-01 changelog, the 2026-09-24 changelog, GitHub's default-availability concept page, GitHub's protected-branches page, Microsoft Learn's Azure DevOps code-review page, the GitHub search / REST / rulesets / code-search APIs, and `Andrew199617/js-syntax-extension` at PR and ruleset level.

### Not reached

- **PCI DSS v4.0.1 official text** — 403 and 404 from PCI SSC. The single most consequential gap in this artifact.
- **ISO 27001 A.5.3** — paywalled.
- **NIST SSDF PW.7** — PDF undecodable on the machine used; consequently not cited anywhere above.
- **Organization and enterprise rulesets** — not readable from outside an organization, so the one verified merge case cannot be generalized.
- **A GitHub Issues API negative test** attempted by the counter-case pass failed as a method (keyword-OR semantics returned tens of thousands of irrelevant hits) and is recorded as not-reached rather than nothing-found.
- `require_extra_approval_for_unattributed_changes` on `github/docs` — ruleset not readable.

### Verified by hand

Separated from the passes' own hand-verification, because this section exists to distinguish *an agent reported this* from *someone checked it*. Checked directly for this artifact:

1. **"The policy does not apply to features in preview"** — fetched from GitHub's default-availability page.
2. **"This feature is available in public preview"** — fetched from the 2026-09-01 changelog. Together these two are what overturn the brief's premise, which is why both were checked rather than relayed.
3. **The changelog does not address self-approval** — read directly.
4. **The stale-approval tension** — both sides fetched: the changelog's *"just like a human reviewer's"* and the protected-branches page's *"Optionally."*
5. **The 875 count reproduced** from the search API, with two controls (1,494 without the reviewer constraint; the reviewer app returning 598,577 PRs, confirming the identifier is real).
6. **The 300-PR sample classified review-by-review** against the REST API. This is what produced the 10% / 4% / 85% split and the correction to the pass's 15%.
7. **`Andrew199617/js-syntax-extension#65` end to end** — author type, every review state, both active rulesets, `required_approving_review_count`, the empty `bypass_actors`, and `updated_at` against `merged_at`.
8. **`require_extra_approval_for_unattributed_changes`** read from live rulesets on three of four repositories.
9. **Azure DevOps's contrary statement** — fetched and quoted verbatim, with its date.
10. **The `request-changes-tips.md` contradiction exists** — confirmed via the code search API.

Relayed and **not** re-verified, marked as such above: the OpenAPI zero-occurrence counts, the NIST OSCAL reading, the Hacker News arithmetic, the exclusion-file register, the audit-log field names, the GitLab issue, the Greptile scoping, and the coding-agent risks-documentation scope.

A method note worth recording: the first three attempts at the 300-item classification returned zero inspected rows and reported success. Two causes — a null `number` field in the search response, and `gh` being absent from the PATH in some shell invocations. Both failed silently and would have produced a confident 0%.

---

## What could not be established

- **1. Whether GitHub intends an agent to be able to approve its own pull request. [O]** The behaviour is measured. The intent is undocumented, and the only statement that looks like an answer is scoped to a different actor.

- **2. Whether a machine approval can satisfy a separation-of-duties or four-eyes control in a regulated setting. [O]** This is the item that matters most for the asking context and it is open in both directions. NIST AC-5's text neither permits nor forbids it. The PCI DSS clause that would decide it could not be obtained. No authoritative SOC 2 guidance was found.

- **3. When this feature goes GA, and what happens to the default at that moment. [O]** The changelog says a preview opt-in is preserved at GA and is silent on enterprises that never opted in. The documentation says the policy governs features moving from preview to GA. These read differently and GitHub does not say which governs.

- **4. Whether a Copilot approval satisfies `require_code_owner_review`. [O]** CODEOWNERS documentation admits only users and teams with explicit write access; apps and bots are not listed. Undocumented and untested.

- **5. Whether a repository can disable approvals when its organization has selected "Enabled everywhere". [O]** Undocumented. GitHub's policy-conflicts reference table has no row for the approvals policy, so multi-organization resolution is also undocumented.

- **6. Whether an approval is withheld when every changed file is excluded from review. [O]**

- **7. Whether any wrongful approval has occurred in practice. [O]** Searched: Hacker News via the Algolia API (four queries, 2025-09 onward), GitHub Community Discussions, and general web. **Nothing found.** The most substantive practitioner piece located (2026-09-13) contains no first-hand testing and independently catalogues the same documentation gaps found here. At roughly 30 days into an opt-in preview this is weak evidence in either direction, and is recorded as an absence with the searches that produced it rather than as reassurance.

---

## Where this stops

Discovery establishes that the path exists, is measurable, and is undocumented at the point that matters. It does not say what follows from that, and the phase that decides is two phases away.

What a later phase will need and this one could not supply:

- **The PCI DSS text.** Obtaining it converts the governance question from `[O]` to `[S]` or settles it the other way. It requires either paid access or someone with PCI SSC access, and is a spending decision rather than a research step.
- **An answer from GitHub on the GA transition.** Item 3 is not resolvable from public sources; it is a question for a support or account channel.
- **A rate, not an existence proof**, for approvals clearing a merge gate. The one verified case establishes the path; organization and enterprise rulesets are unreadable from outside, so a rate would need either an inside view or a much larger public sample.
- **Whether our own repositories are exposed**, which is a configuration question about us and was deliberately not asked here.

Two facts recorded for whichever phase picks this up, because they cut in opposite directions and both are measured: an agent approving its own pull request with no human approver occurred in **10%** of a 300-item sample; and the same vendor's other platform states its reviewer *"never approves the pull request."*
