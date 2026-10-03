# Develop — agent approval of pull requests

dated: 2026-10-03
problem: [`../../03-define/problems/agent-pr-approval.md`](../../03-define/problems/agent-pr-approval.md)
status: options developed, none chosen

**What this is.** The divergent half of the second diamond. Genuinely different readings of one sentence in our own standard, each with what it costs, what it assumes, and how it fails. Written so a reader can pick, not so they can agree with a preference.

**What this is not.** No recommendation, no ranking, no preferred option. Choosing is Deliver's. If this document reveals which way the author leans, it has failed.

**The sentence everything turns on.** `STANDARDS.md` §3, graded `[S]`:

> A second, independent evaluator — human or a **separate** agent with no memory of building it — with criteria written down beforehand.

**The fact it has to survive.** Measured 2026-10-03 over 300 Copilot-authored pull requests: Copilot was the sole approving reviewer on **10%**, approved alongside a human on 4%, and a human approved the other 85%. The authoring and reviewing actors are different GitHub accounts, so the platform's "an author cannot approve their own pull request" rule does not engage. One case was verified merging under an active ruleset requiring one approval with an empty bypass list.

**These are different readings, not thresholds.** Options differing only by how strict a threshold is would belong in one entry.

---

## A · "Separate" means a separate identity

**What it is.** We read §3 as satisfied when the approving actor is a different account from the authoring actor. On this reading, Copilot code review approving a Copilot-authored pull request already complies, and no change is needed to the standard or to any configuration.

**Costs.** Nothing to build and nothing to write. The cost is entirely in what we give up: any claim that §3 provides independence beyond identity. If challenged by an auditor or a colleague, the defence is that two accounts were involved.

**Assumes.** That identity separation is what §3 was protecting. **Contradicted by the standard's own basis.** §3 rests on theme 2 of cycle `2026-09-29` — 12 findings that agents cannot reliably self-report, which the cycle calls "the single principle `STANDARDS.md` §3 rests on." Those findings are about a model's capacity to evaluate its own output, not about which account the output was posted from. Reading §3 as an identity rule severs it from the evidence that produced it.

**Fails when.** The authoring and reviewing instances share a failure mode. Greptile reports that failure distribution shifts by agent — Cursor BG at 3.45× on N+1 queries, Claude at 1.75× on IDOR and tenancy, Codex at 1.35× on config — which if correct means defects are model-characteristic. A reviewer sharing the author's characteristic blind spot cannot see it, regardless of account.

**Would be right if.** The evidence turns out to be that review quality is independent of whether the reviewer shares the author's model — which nobody has measured.

---

## B · "Separate" means a separate model family or vendor

**What it is.** The approving evaluator must come from a different model family, or a different vendor, than the authoring one. One vendor's product reviewing its own output does not satisfy §3 regardless of account.

**Costs.** Real money and real operational weight: two vendors under contract, two sets of credentials, two review surfaces to configure and keep in step, two vendors to assess. In a regulated environment, two third-party risk assessments rather than one.

**Assumes.** That model-characteristic failure modes are the thing to defend against, and that different vendors fail differently enough to matter. **Partly supported, from a vendor.** Greptile's per-agent failure distribution is the evidence, and Greptile sells AI code review — graded `[V]`, with adverse selection among its own stated limitations. The independent finding on agentic pull request descriptions is consistent with failure modes being agent-specific but does not establish it.

**Fails when.** Two vendors share a base model, a training corpus, or a scaffold. The separation is then nominal and more expensive than option A for the same actual independence. Also fails when the second vendor's false-positive rate is high enough that its findings get ignored, which is unmeasurable today — no non-vendor precision or recall figure for any AI reviewer could be established.

**Would be right if.** Cross-vendor review is shown to catch defects a same-vendor second pass misses, and the cost of two vendors is acceptable.

---

## C · "Separate" means no shared context, read literally

**What it is.** We take §3's own clause at face value — *"no memory of building it"* — and treat a stateless evaluation with no access to the authoring session as satisfying it. The same model family may review its own output provided the reviewing call carries none of the authoring context.

**Costs.** Low to implement and precise to state. The cost is that it makes §3 a statement about context rather than about capability, which narrows what the standard promises. Anyone reading §3 as a competence guarantee would be reading more into it than this permits.

**Assumes.** That the failure §3 guards against is context-driven rather than model-intrinsic — that an agent cannot grade work it remembers building, but can grade the same work arriving cold. **Untested, and the standard's basis cuts both ways.** The theme 2 findings include agents reaching high benchmark scores partly by reading git history or recalling memorised solutions, which is a context argument and supports this reading. They also include models being unreliable at self-reporting their own progress, which is closer to a capability argument and does not.

**Fails when.** The defect is one the model cannot see at all rather than one it is motivated not to see. A stateless second pass removes the motive and keeps the blind spot.

**Would be right if.** A same-model stateless pass is shown to find defects its own authoring pass introduced — the test named below.

---

## D · The approving position is held by a human; machine review is advisory

**What it is.** §3's "separate agent" is read as permitting agent *evaluation* but not agent *approval*. An agent may review, comment and flag; the act that unblocks a merge is a human's. Mechanically this means the two repository-level toggles that let a Copilot approval count toward merge requirements stay off, and `STANDARDS.md` says so explicitly.

**Costs.** Gives up the throughput argument for agent review entirely — a human is in the path of every merge, which is the cost the capability existed to remove. Also a standing configuration burden: three levels to keep set, with no API representation found for the approvals policy, so drift is not detectable programmatically.

**Assumes.** That a human in the approving position is materially different from a machine in it. **Supported as practice, unestablished as a control.** Two platforms take this position: Azure DevOps states *"Copilot always leaves a Comment review. It never approves the pull request or requests changes, so its review doesn't satisfy required-reviewer policies"*, and GitLab's own Duo proposal states *"For regulated environments, configure Duo as an advisory reviewer only."* Both are `[V]`. Whether a regulated separation-of-duties control actually requires it is **undecided** — NIST SP 800-53 AC-5 speaks of "different individuals or roles" and routes enforcement through IA-2 *Organizational Users* rather than IA-9 *Service Identification*, saying nothing either way.

**Fails when.** The human approval is a rubber stamp. This is the failure the repository's own discovery already found evidence for in a different form, and it converts a visible machine approval into an invisible human one. A control that moves a failure out of the audit log is worse than one that records it — the GitHub audit log carries `actor_is_agent` and `actor_is_bot`, so a machine approval is at least distinguishable.

**Would be right if.** The governing standard turns out to require a natural person, or the cost of being wrong on a change is high enough that throughput is not the consideration.

---

## E · Rewrite §3 to state the property instead of the actor

**What it is.** Stop asking what "separate" means and change the sentence. §3 currently names an actor type; it could instead name the property required — for example that the evaluator must not share the authoring context, must apply criteria written down beforehand, and for changes above a stated risk class must be a natural person. The actor question dissolves because the standard no longer turns on it.

**Costs.** Changing a standard, which is the heaviest thing in this repository and has never been done. It also requires defining a risk class, which does not exist yet and is a larger piece of work than any other option here. And it makes §3 longer, against a value this repository just committed to.

**Assumes.** That "separate" is doing load-bearing work it was not written to do. **Established, by this exercise.** The word is carrying an entire question, and the fact that five other readings of one adjective are each defensible is the evidence. Also assumes we are willing to amend a standard on roughly a month of evidence about one vendor's feature.

**Fails when.** The rewrite encodes this month's situation into a durable document. §3 travels well now because maker-checker is an old idea stated plainly; a version specifying context-sharing and risk classes is tuned to one platform's mechanics and dates faster.

**Would be right if.** We expect the actor question to keep recurring across platforms, which the option set's own existence is some evidence for.

---

## F · Record §3 as open, and change nothing yet

**What it is.** `STANDARDS.md` grades every claim, and `[O]` means open. §3 keeps its wording and acquires an explicit open note: that whether a second instance of one vendor's product satisfies "separate" is unresolved, with the reason — the governing text could not be obtained. No configuration changes, no standard rewritten.

**Costs.** Leaves a known ambiguity in the one document this repository exists to keep true, and leaves it in a section an auditor would read first. It also defers a question that has a live platform behaviour behind it: 10% of a 300-item sample already shows the pattern §3 is ambiguous about.

**Assumes.** That the cost of deciding wrong exceeds the cost of waiting, and that waiting is cheap here. **Partly established.** The specific blocker is identified and concrete — PCI DSS 6.2.3.1, and whether its author-independence clause attaches only to manual review while 6.2.3 separately permits automated. That text is obtainable with paid or privileged access, so this is a bounded wait rather than an open one. Against it: no GA date for the feature is published, so the platform side has no date to wait for.

**Fails when.** Waiting becomes the decision. This is the same failure the `producing-themes` decision is already carrying with a tripwire, and choosing it twice in a row in the same repository would be a pattern rather than a judgement. Also fails if someone reads an `[O]` on §3 as permission — an open question in a standards document is routinely read as "not prohibited."

**Would be right if.** The PCI text arrives soon enough that the ambiguity is short-lived, and nothing in our own repositories is configured to allow the pattern meanwhile — which is unchecked.

---

## The test that cuts across A, B and C

**Does a stateless second pass by the same model find defects its own authoring pass introduced?**

Three of these options turn on it. A assumes the answer does not matter, B assumes it is no, C assumes it is yes. It is answerable cheaply on work we already have — this repository's own history includes four confident agent verdicts that were wrong and were caught only by cross-checking, including an agent that retracted a correct finding and one that reported a file edit it never made.

Running it would sharpen A, B and C considerably. **It does not decide between them**, because it speaks to capability and not to what a regulated control requires, which is where D and F sit. It is recorded here rather than treated as the answer.

---

## What none of these options solves

**The stale-approval conflict.** GitHub states an approval is *"dismissed just like a human reviewer's"* when new commits are pushed, and separately states that dismissing stale human approvals on push is **optional** per ruleset. On a repository that never enabled it, the analogy means the approval survives the diff changing. No reading of §3 affects this, and no GitHub document reconciles the two statements. Whichever option is chosen, this remains open.

**Whether our own repositories are exposed.** Deliberately left out of discovery as a configuration question about us. Options A, C, E and F all leave current configuration untouched, which means they leave it unknown.

**The regulated question itself.** A, B, C, D and E each assert something the governing standards do not settle. Only F declines to, and it pays for that by leaving the ambiguity in place. Given the first cycle's most valuable finding was an outlier, it is worth noting that this option set has no entry for "the answer is something nobody has proposed yet."
