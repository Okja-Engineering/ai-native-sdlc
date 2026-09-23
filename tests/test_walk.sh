#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

router=AGENTS.md
context=CONTEXT.md
skill=skills/evidence-to-intent/SKILL.md

grep -q 'skills/evidence-to-intent/SKILL.md' "$router"
grep -q 'tests/test_evidence_to_intent.sh' "$router"
grep -q 'skills/evidence-to-intent/references/evidence-contract.md' "$context"
grep -q 'skills/evidence-to-intent/references/specification-contract.md' "$context"
grep -q 'implementation_authorized: false' "$skill"
grep -q 'accept | revise | reject' "$skill"
grep -qi 'do not invoke' "$skill"
grep -q 'reviewable-delivery' "$skill"
test ! -d skills/reviewable-delivery

echo "PASS: walk"
