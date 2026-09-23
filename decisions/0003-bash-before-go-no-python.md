---
id: ADR-0003
status: accepted
date: 2026-09-07
owner: Matthew Van Dusen
scope: repository implementation language
---

# Use Bash before Go; do not use Python scripts

## Decision

Repository scripts use Bash. Go is introduced only when the logic cannot remain safe, portable, and readable in Bash. Python scripts are prohibited.

## Consequences

- `evidence-to-intent` validators are executable Bash scripts.
- Tests are Bash and use available POSIX userland tools plus `jq` for JSON manifests.
- `tests/test_structure.sh` rejects `.py` files.
- Script compatibility is Bash 3.2+ with POSIX userland utilities.
- Go requires a documented complexity justification and a separate reviewed slice.
- Research and package recommendations must not include runnable Python script examples.
