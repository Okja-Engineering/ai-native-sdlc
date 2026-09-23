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
statement: first claim
plane: workflow
basis: declared
source: a.md:1
status: observed
```

```contract
id: claim-01
kind: claim
statement: second claim sharing the id
plane: workflow
basis: declared
source: b.md:1
status: observed
```
