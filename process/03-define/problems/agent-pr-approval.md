# Problem — whether an agent may approve what an agent wrote

dated: 2026-10-01
from: [`../cycles/2026-09-29.md`](../cycles/2026-09-29.md) — theme 3, *"Review authority is moving to agents, and it has a date"*
rests on: [`../../02-discover/topics/agent-pr-approval.md`](../../02-discover/topics/agent-pr-approval.md)
status: defined, not solved

**This states a question. It does not answer it.** The answer is Deliver's, two phases away, and nothing here should be read as a preference.

---

## The finding it came from

Theme 3 of cycle `2026-09-29`, 7 findings, the only theme in that cycle carrying a deadline. Its source row:

> GitHub shipped the ability for Copilot code review to formally approve pull requests, off by default and configurable at enterprise, org and repository level — [changelog, 2026-09-01](https://github.blog/changelog/2026-09-01-copilot-code-review-can-now-approve-pull-requests/), graded `high`

The theme was selected for Define ahead of others on the stated grounds that *"it has a clock."*

## The clock was wrong, and that is the first thing this problem has to absorb

Discovery established that the 2026-10-22 default-enablement policy **does not reach this feature**. GitHub's own two statements, both verified by hand: *"The policy does not apply to features in preview"*, and *"This feature is available in public preview."*

**The urgency that selected this topic does not exist in the form it was believed to.** What discovery found instead is narrower and differently shaped:

- The policy's scope includes *"features that move from preview to GA"*, so a GA transition inherits a default already set, with no separate decision point at that moment.
- No GA date is published.

A dated event that could be planned for became an undated one that cannot. Whether that is better or worse is not this phase's call.

## What we currently hold

`STANDARDS.md` §3, graded `[S]`, quoted rather than paraphrased:

> **The practice:** separation of duties. Whoever produced the change does not grade it. A second, independent evaluator — **human or a *separate* agent with no memory of building it** — with criteria written down beforehand. This maps onto maker-checker, which is why it travels well in regulated environments.

Two things follow from the exact wording, and both matter:

1. **An agent approving a pull request is not forbidden.** The standard admits a separate agent as the second evaluator. A headline reading "agents are approving pull requests now" does not collide with anything we hold.
2. **What is forbidden is the same party authoring and grading.** The standard's own basis is theme 2 of the same cycle — 12 findings, which the cycle calls *"the single principle `STANDARDS.md` §3 rests on"* — that agents cannot reliably self-report.

So the collision, if there is one, is narrow and specific.

## Where they actually collide

**At one point, and it is measured.**

The authoring actor (`copilot-swe-agent[bot]`) and the reviewing actor (`copilot-pull-request-reviewer[bot]`) are **different GitHub accounts**. GitHub evaluates "an author cannot approve their own pull request" per account, so the rule does not engage. Measured independently on 2026-10-01 over a 300-item sample of Copilot-authored pull requests:

| | |
|---|---|
| Copilot was the **sole** approving reviewer | **31 (10%)** |
| Copilot approved alongside a human | 12 (4%) |
| A human approved | 257 (85%) |

And one case verified end to end: a Copilot-authored pull request whose only approval came from the Copilot reviewer merged into `master` under an **active** ruleset requiring one approval with an **empty bypass list**.

**Two different accounts belonging to one vendor's one product is a separation of identity, not a separation of duties.** Whether it satisfies §3 turns on what "separate" was doing in that sentence — a question about our own standard's wording, not about GitHub.

## Where they do not collide

Stated explicitly, because the problem is substantially smaller than the theme's framing implied:

- **85% of the time a human approved.** The raw search count of 875 overstates the phenomenon roughly sevenfold if read as self-approvals.
- **It is off by default**, at three levels, with the enterprise default documented as *"Disabled everywhere."*
- **A guardrail ships enabled by default** — `require_extra_approval_for_unattributed_changes`, verified `true` on three large public repositories. Though it raises a *count*, not a *kind*, and was `false` on the one repository where a Copilot-only approval was observed to merge.
- **The same vendor's other platform took the opposite position.** Azure DevOps, dated 2026-09-29: *"Copilot always leaves a Comment review. It never approves the pull request or requests changes, so its review doesn't satisfy required-reviewer policies and doesn't block merging."* GitHub is closer to an outlier than to an industry direction.
- **Nobody is alarmed.** The changelog scored 1 point and 0 comments on Hacker News, and no practitioner report of a wrongful approval was found.

## The question this forces

**Does `STANDARDS.md` §3's "separate agent" mean a separate account, a separate model, a separate vendor, or a separate evaluation with no shared context — and is a second instance of one vendor's product reviewing the first instance's output any of those?**

Stated so it can be answered. It is a question about our own standard, which is the part that is ours to settle; everything about GitHub's behaviour is now established.

Two sub-questions it cannot be answered without:

1. **Is "no memory of building it" satisfied by a stateless second call to the same model family?** The standard's clause is about memory, and a fresh context window arguably satisfies it literally while arguably defeating its purpose. The cycle's theme 2 evidence is about self-report, not about memory, so it does not settle this either way.
2. **Does a machine approval satisfy a regulated separation-of-duties control at all?** Open in both directions. NIST SP 800-53 AC-5 is written in terms of *"different individuals or roles"* and routes enforcement through IA-2 *Organizational Users* rather than IA-9 *Service Identification* — it says nothing for or against. The PCI DSS clause that would decide it could not be obtained.

## What would change the answer

- **The PCI DSS 6.2.3.1 text.** Specifically whether its author-independence clause attaches only to *manual* review while 6.2.3 separately permits automated. This converts the governance question from open to settled, in one direction or the other. It is a purchase or an access request, not a research step.
- **A GA announcement**, which would reattach a date and bring the default-enablement policy into play.
- **A first wrongful-approval report.** None exists yet at roughly 30 days into an opt-in preview, which is weak evidence either way.
- **An answer from GitHub on whether a never-opted-in enterprise inherits the global default at GA.** The changelog and the documentation read differently and GitHub does not say which governs.
- **A decision that §3's wording is itself what needs changing**, which is a legitimate outcome and would make this a standards question rather than a tooling one.

## What we do not know

- Whether a Copilot approval satisfies `require_code_owner_review`. CODEOWNERS admits only users and teams with explicit write access; apps and bots are not listed. Undocumented and untested.
- Whether a repository can disable approvals when its organization has selected *Enabled everywhere*. GitHub's policy-conflicts table has no row for this policy.
- Whether the stale-approval reassurance holds. GitHub states an approval is *"dismissed just like a human reviewer's"*; GitHub also states human dismissal-on-push is **optional** per ruleset. On a repository that never enabled it, the analogy means the approval is not dismissed. No GitHub document reconciles the two.
- **Whether our own repositories are exposed.** Discovery deliberately did not ask. This is a configuration question about us, answerable cheaply, and nothing above depends on it.

## Where this stops

A question stated, with the facts it rests on established and graded, and the two items that would change the answer named. No option set, no recommendation, no decision.

The option set is Develop's. One thing is recorded here for whoever writes it, because discovery found it and an option set that ignored it would be incomplete: **the question may be answerable by changing our own wording rather than by changing any configuration.** §3's "separate" is currently doing load-bearing work it was probably not written to do.
