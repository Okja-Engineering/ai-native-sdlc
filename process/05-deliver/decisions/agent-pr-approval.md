# Decision — agent-pr-approval

problem: [`process/03-define/problems/agent-pr-approval.md`](../../03-define/problems/agent-pr-approval.md)
options: [`process/04-develop/options/agent-pr-approval.md`](../../04-develop/options/agent-pr-approval.md)
chosen: D
decided_by: Matthew Van Dusen
dated: 2026-10-03
amends: [`STANDARDS.md` §3](../../../STANDARDS.md#3-an-agent-runs-checks-it-does-not-set-them-and-it-cannot-pass-itself)

**Decided.** D — an agent may review, comment and flag. The act that unblocks a merge is a human's.

---

## What was chosen, and why

**`STANDARDS.md` §3's "separate agent" permits agent *evaluation*, not agent *approval*.**

The reasoning is that §3 exists because of theme 2 of cycle `2026-09-29` — twelve findings that agents cannot reliably self-report, which the cycle calls the single principle §3 rests on. Those findings are about a model's capacity to grade its own output. Two GitHub bot accounts belonging to one vendor's one product is a separation of identity, and identity was not what §3 was protecting. Reading it that way would sever the standard from the evidence that produced it.

Two platforms already hold this position for exactly our situation. Azure DevOps: *"Copilot always leaves a Comment review. It never approves the pull request or requests changes, so its review doesn't satisfy required-reviewer policies and doesn't block merging."* GitLab's own Duo proposal: *"For regulated environments, configure Duo as an advisory reviewer only."* Both are vendor statements, graded `[V]`, and both are about practice rather than proof.

**The cost that would normally argue against this does not apply to us.** D puts a human in the path of every merge, which gives up the throughput case for agent approval entirely. `intent.md` already states that no claim about speed, throughput or velocity appears in this repository. We are declining a benefit we had already declined.

**What this means mechanically.** The two repository-level toggles that let a Copilot approval count toward merge requirements stay off, at all three levels. §3 gets amended to say so explicitly rather than leaving it inferable — which is work this repository cannot currently do, and is the subject of [#18](https://github.com/Okja-Engineering/ai-native-sdlc/issues/18).

## What we are accepting

**D's stated failure: the human approval becomes a rubber stamp.** That is the cost, and it is worse than it first reads.

A machine approval is *visible*. GitHub's audit log carries `actor_is_agent` and `actor_is_bot` on `pull_request_review.submit`, so an agent approving a pull request is distinguishable after the fact. A human clicking approve on a change they did not read is not distinguishable from one who read it carefully. **This decision moves a detectable failure into an undetectable one.** That is a real loss and nothing here mitigates it.

We are also accepting a standing configuration burden. The approvals policy has **no representation in GitHub's published API** — searched and reported as zero occurrences of the candidate field names in the 13 MB OpenAPI description. So the setting is UI-only: it cannot be read, set, or drift-checked programmatically. We are committing to a control we cannot verify mechanically, at three levels, indefinitely.

And we are accepting that **this is our practice, not a compliance position.** Whether a machine approval satisfies a regulated separation-of-duties control remains undecided — NIST SP 800-53 AC-5 speaks of "different individuals or roles" and routes enforcement through IA-2 *Organizational Users* rather than IA-9 *Service Identification*, saying nothing either way. We are asserting what we will do, not what we are required to do.

## Why not the others

- **A — a separate identity is enough.** Contradicted by §3's own basis, as set out above. It is the reading that requires no action, which is its only argument.
- **B — a separate model family or vendor.** The evidence that failure modes are model-characteristic comes from Greptile, which sells AI code review and lists adverse selection among its own limitations. Two vendors is real money and two third-party risk assessments, bought against a `[V]` claim. Revisit if the cross-cutting test supports it.
- **C — no shared context, read literally.** The most defensible reading of the actual words, and it may be right. It rests on the failure being context-driven rather than model-intrinsic, which is untested, and §3's own basis cuts both ways. Not chosen because it would have us rely on an untested assumption in the one place this repository says not to.
- **E — rewrite §3 to state the property.** Attractive, and the Define artifact already pointed at it. Rejected for now because it requires defining a risk class that does not exist, and because a §3 specifying context-sharing and risk classes is tuned to one platform's mechanics and dates faster than maker-checker does. D is a smaller change that buys time for E to be done properly.
- **F — record it as open and change nothing.** The honest option, and nearly chosen. Rejected because `producing-themes` is already carrying a wait with a tripwire, and choosing to wait twice consecutively in the same repository is a pattern rather than a judgement. Its substance survives anyway — see below.

## What would reverse this

- **The PCI DSS 6.2.3.1 text arrives and says something different.** Specifically whether its author-independence clause attaches only to *manual* review while 6.2.3 separately permits automated. That text is obtainable with paid or privileged access and is the single thing that would settle the governance question.
- **The cross-cutting test comes back strongly.** Does a stateless second pass by the same model find defects its own authoring pass introduced? A clear yes moves C to the front and makes D look like unnecessary cost.
- **A rubber-stamp rate becomes measurable and bad.** If human approvals on agent-authored changes turn out to be indistinguishable from no review, D is costing us a human's time for nothing and C or B becomes the better trade.
- **A GA announcement for the feature.** It would reattach a date and bring the 2026-10-22 default-enablement policy into scope, which currently it is not.

A reversal is a **new record pointing at this one**, per the contract. This file is not edited to change its answer.

## What this does not settle

**F's substance is adopted even though F was not chosen.** The regulated question stays open and should be recorded as `[O]` in `STANDARDS.md` alongside the §3 amendment. Choosing D is a statement about our practice; it is not an answer to whether a machine approval can satisfy a four-eyes control, and §3 must not imply otherwise.

**The stale-approval conflict.** GitHub states an approval is *"dismissed just like a human reviewer's"* on a new push, and separately states that dismissing stale human approvals is **optional** per ruleset. On a repository that never enabled it, the analogy means the approval survives the diff changing. No reading of §3 affects this and no GitHub document reconciles the two statements.

**Whether our own repositories are exposed.** Discovery deliberately did not look. D makes this urgent rather than academic: the decision is only real once the toggles are actually off, and nobody has checked what they are currently set to.

**Nothing was proposed that nobody had thought of.** The option set itself noted it has no entry for an answer outside the six. Given that the first cycle's most valuable finding was an outlier, that gap is worth restating here rather than treating six options as the whole space.
