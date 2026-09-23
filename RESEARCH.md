# Research synthesis: from AI automation to sequential augmentation

## Problem

AI can create implementation output faster than many teams can establish intent, verify correctness, review risk, and observe production outcomes. Applying agents to an unchanged SDLC can therefore increase queues, rework, security exposure, cognitive load, and delivery instability while making individuals feel faster.

The design problem is not how to automate the entire lifecycle. It is how to use AI to prepare the next smallest human decision with enough deterministic evidence that the decision is fast, informed, and reversible.

## What the evidence supports

### 1. Coding acceleration is real but conditional

Controlled field experiments report meaningful task gains, while the METR maintainer study found a measured slowdown. The correct conclusion is conditional: clear, bounded work with fast feedback tends to benefit; mature, tacit, high-assurance work may incur a verification tax larger than the generation benefit.

### 2. Local output does not equal system throughput

The strongest field evidence shows gains shrinking from code activity to projects and releases. DORA similarly finds that AI amplifies platform quality, architecture, workflow, and organizational health. The system constraint—not available model capacity—governs throughput.

### 3. Verification and comprehension are emerging constraints

Generated code can be functionally plausible yet semantically wrong, insecure, over-complex, or misaligned with intent. Model review is useful but probabilistic. Deterministic checks, independent evidence, and accountable human judgment must absorb the increased volume.

### 4. Ambiguity gets more expensive as implementation gets cheaper

Agents do best when intent, non-goals, boundaries, and acceptance criteria are explicit. This does not justify mandatory document inflation. The appropriate artifact is the smallest durable representation needed for the risk and coordination cost of the change.

### 5. Autonomy must be earned per action class

Prompts and skills are advisory. Consequence-bearing authority needs identity, least privilege, least agency, sandboxing, policy enforcement, provenance, observable operations, and tested rollback. Autonomy should advance from read → recommend → prepare → propose change → execute pre-approved runbook.

### 6. Production is part of verification

Tests prove modeled expectations; production reveals actual behavior. Deployment identity, traces, service objectives, customer outcomes, agent actions, and approvals must connect back to the originating intent and change.

### 7. Learning must improve the generating system

Repeated corrections should become stronger checks, regression tests, scoped context, or focused skills. Capturing everything directly into always-on context recreates the same cognitive overload the system is meant to solve.

## Working architecture

The lifecycle should process a **reviewable value slice** through sequential gates:

1. **Intent:** establish outcome, constraints, non-goals, owner, and risk.
2. **Evidence plan:** define how the outcome could be falsified before implementation.
3. **Slice plan:** identify the smallest independent change and its rollback.
4. **Build:** let an agent implement inside a bounded workspace with continuous feedback.
5. **Verify:** run deterministic checks and independent semantic review.
6. **Human decision:** review intent, evidence, architecture, and risk.
7. **Promote:** enforce provenance, authorization, environment policy, and rollback readiness.
8. **Observe:** compare runtime and product behavior with the intended outcome.
9. **Learn:** route corrections through RLP and validated-learning decisions.

This sequence is intentionally HITL. The agent reduces the cost of preparing evidence at every step; it does not remove the accountable person.

## 60/30/10 application

### Deterministic actions

- artifact schemas and required fields;
- exact repository and test commands;
- types, linters, tests, scans, policy checks, and provenance;
- protected paths and branch rules;
- evidence receipts;
- risk thresholds and stop conditions;
- deployment and rollback mechanics;
- metric definitions.

### Orchestration

- routing work by risk and ambiguity;
- decomposing intent into value slices;
- stage order and handoffs;
- checkpoint ownership;
- bounded retry and escalation;
- pilot experiment design;
- correction routing through RLP.

### AI judgment

- identifying ambiguity and missing constraints;
- proposing alternative slices;
- semantic comparison of intent, plan, diff, and evidence;
- synthesizing conflicting research;
- drafting risk explanations for human review.

## Metrics

The primary outcome is not automation rate. The system should measure:

- intent-to-production lead time;
- active time and queue time by stage;
- size and cognitive coherence of review units;
- human review time and intervention rate;
- first-pass CI and verification success;
- rework after human approval;
- escaped defects, incidents, and rollback rate;
- change failure and recovery time;
- developer comprehension and confidence calibration;
- total model, CI, review, and rework cost;
- customer or operator outcome achieved.

The candidate north-star unit is **cost and lead time per production-qualified value slice**, constrained by stability, security, and human comprehension.

## Unresolved research questions

- How should cognitive reviewability be measured without turning lines changed into a target?
- What evidence minimum belongs to each risk tier?
- When does a product intent need decomposition before entering the workflow?
- How much model-review diversity produces real independence?
- Which agent actions can safely advance after repeated successful pilot evidence?
- How should comprehension and skill atrophy be measured over time?
- Which production outcomes qualify as validated learning when customer volume is low?

## Implication for the future plugin

The plugin should eventually scaffold and guide this staged evidence process. It should not become an autonomous software factory, a second project tracker, a generic multi-agent orchestrator, or an always-on memory system. Its initial value should be helping one pilot team turn one intent into one production-qualified value slice while preserving explicit human decisions and publishable evidence.
