# SDLC package — task routing

Route each task to the smallest stage contract needed. `output/` under each
stage is the only cross-stage handoff surface; run artifacts live under
`changes/{slice-id}/` in the host repository.

## Task routing

| Task | Stage contract | Terminal decision |
|---|---|---|
| Frame a raw request | `stages/01-intent/CONTEXT.md` | accept / correct / reject — request owner |
| Select the value slice | `stages/02-slice/CONTEXT.md` | select / revise / split / reject — accountable engineer |
| Define proof before implementation | `stages/03-evidence-plan/CONTEXT.md` | accept / revise / reject — accountable engineer |
| Implement the slice | `stages/04-implement/CONTEXT.md` | external actor; returns evidence |
| Verify the implemented slice | `stages/05-verify/CONTEXT.md` | accept / revise / reject — independent reviewer |
| Record merge readiness | `stages/06-merge-decision/CONTEXT.md` | merge-ready / revise / split / reject — merge authority |

## Shared resources

| Resource | Location | Contents |
|---|---|---|
| Flow unit | `shared/value-slice.md` | What makes a change a reviewable value slice |
| Risk tiers | `_config/risk-tiers.md` | When stages may collapse and when review deepens |
| Contract schema | `_config/stage-contract-schema.md` | Schema version this package conforms to |

## Coverage map — what this package executes vs describes

| Lifecycle stage | Status |
|---|---|
| Plan, Design | Covered (01–03) |
| Build | External boundary only (04) |
| Test | Evidence plan + receipt; not CI-integrated evals |
| Deploy | Stops at merge-ready; gates described, not installed |
| Maintain | Out of scope — outcome evaluation is a separate capability |
