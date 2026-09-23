# Scaffold research contract

## Candidate payload

```text
AGENTS.md or existing router amendment
CONTEXT.md or existing task-route amendment
changes/_templates/value-slice/
changes/{slice-id}/
```

Do not prescribe these paths when the target already has an authoritative equivalent.

## Deterministic checks

- Inspect before proposing.
- Compare before writing.
- Never overwrite owner text.
- Do not duplicate routes.
- Resolve every referenced path.
- Require explicit review markers between sequential artifacts.
- Run twice and confirm the second run is unchanged.
- Report unsupported capabilities rather than faking them.

## Stop conditions

Stop when the owner has not accepted the workflow specification, the target repository is unknown, the current router has not been inspected, or the smallest useful form has not been chosen.
