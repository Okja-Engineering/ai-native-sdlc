# Shared helpers for workflow-contract tests — compatibility shim.
# The implementation moved to the sdlc-scaffold product library so the
# exporter and the S6 suites consume one contract surface (proposal §12.6).
# Sourced by tests/test_workflow_contract.sh, test_export_equivalence.sh,
# test_loading_rules.sh.

. "$(dirname "${BASH_SOURCE[0]}")/../../skills/sdlc-scaffold/scripts/lib-contract.sh"
