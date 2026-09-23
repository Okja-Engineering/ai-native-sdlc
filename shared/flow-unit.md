# Working flow unit: reviewable value slice

## Hypothesis

The primary unit of an augmented SDLC is the smallest independently valuable change that a human can understand, verify, approve, and safely promote without depending on unmerged work.

## Required properties

A candidate slice is valid when it is:

- **Valuable:** changes an observable user, operator, risk, or learning outcome.
- **Bounded:** has explicit intent, non-goals, affected boundaries, and a named owner.
- **Reviewable:** fits within one coherent human review and exposes its reasoning and evidence.
- **Verifiable:** has falsifiable acceptance criteria and executable checks where possible.
- **Shippable:** leaves the system working and can be promoted independently.
- **Reversible:** has a proportionate rollback, disablement, or containment path.
- **Traceable:** connects intent, implementation, evidence, approval, deployment, and runtime outcome.

## What it is not

A prompt, agent session, commit, PR, story, or ticket is only a container. It becomes a reviewable value slice only when it meets the properties above.

## Research questions

- What maximum cognitive size allows reliable human review?
- Must value always be customer-visible, or can risk reduction and validated learning qualify?
- When should one intent decompose into multiple slices?
- Which evidence is mandatory at each risk tier?
- How should semantic dependencies between independently shippable slices be represented?
