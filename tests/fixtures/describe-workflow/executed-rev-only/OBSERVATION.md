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
id: claim-01
kind: claim
statement: rev-only execution ref lacks a record name
plane: workflow
basis: executed
source: ci.yml:10-30
execution_ref: rev:abc123
status: observed
```
