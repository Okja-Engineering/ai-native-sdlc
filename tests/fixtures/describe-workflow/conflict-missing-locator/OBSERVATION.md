# Fixture: conflict position without its own locator

```contract
id: obs-fixture
kind: observation
schema_version: workflow-observation/0.1.0
inspected_repo: /nonexistent/fixture-repo
inspected_revision: none
tree_state: no-git
snapshot_id: sha256:0000000000000000000000000000000000000000000000000000000000000000
inspection_scope: .
observed_at: 2026-09-14
observer: describe-workflow
```

```contract
id: conflict-01
kind: conflict
subject: required reviewer count
positions: two-reviewers@CONTRIBUTING.md:14 | one-reviewer
status: unresolved
```
