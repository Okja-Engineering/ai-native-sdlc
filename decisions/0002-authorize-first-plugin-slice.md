---
id: ADR-0002
status: accepted
date: 2026-09-07
owner: Matthew Van Dusen
scope: evidence-to-intent first plugin slice
---

# Authorize the first plugin slice

## Decision

The owner's instruction, “let's build out the playbook for the repo / plugin,” authorizes implementation of the first `evidence-to-intent` plugin slice described by the corrected Workflow Package Builder package.

## Authorized

- Cross-agent plugin manifests.
- Root plugin router integrated with the existing research repository.
- `evidence-to-intent` skill and references.
- Evidence and specification validators.
- Structure, behavior, and cold-session walk tests.
- Plugin README, license, changelog, release notes, and explicit non-goals.

## Not authorized

- The deferred `reviewable-delivery` skill.
- Target-repository mutation or scaffolding.
- Merge, deployment, production access, or publication.
- RLP promotion or Skill Architect rewrite.
- Git commit or push.

This decision supersedes the implementation-unauthorized marker only for the listed first-slice files. Generated research and package artifacts remain historical inputs and retain their original status.
