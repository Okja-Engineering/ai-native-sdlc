# Fixture observation — structurally valid, inspected repo absent

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
statement: PRs require review before merge
plane: workflow
basis: declared
source: CONTRIBUTING.md:14-20
status: observed
```

```contract
id: claim-02
kind: claim
statement: CI defines a test job on pull requests
plane: workflow
basis: configured
source: .github/workflows/ci.yml:10-30
status: observed
```

```contract
id: claim-03
kind: claim
statement: the test job ran and passed on the inspected revision
plane: workflow
basis: executed
source: changes/x/05-evidence-receipt.md:30-41
execution_ref: receipt-run-77@rev:none
status: observed
```

```contract
id: conflict-01
kind: conflict
subject: required reviewer count
positions: two-reviewers@CONTRIBUTING.md:14 | one-reviewer@interview:E3
status: unresolved
```
