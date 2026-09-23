# Fixture: configured-but-unrun — basis 'executed' with only a CI config
# source and no execution record. A CI definition proves configured, not ran.

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
statement: the CI test job ran on the inspected revision
plane: workflow
basis: executed
source: .github/workflows/ci.yml:10-30
status: observed
```
