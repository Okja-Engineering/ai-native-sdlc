# Research-to-artifact map

| Research artifact | Provenance class | Canonical sources | Decision | Intended consumer | Verification |
|---|---|---|---|---|---|
| `claims/verification-capacity.md` | R | S-NBER-2026-01, S-DORA-2024-01, S-DORA-2025-01, S-METR-2025-01, S-FIELD-2025-01 | Treat downstream constraint as conditional, not universal | Workflow Package Builder recommendations; future `research-audit` | Card audit and owner applicability check |
| `patterns/reviewable-value-slice.md` | R+A | S-DORA-CAP-2025-01, S-SPACE-2021-01, S-LEAN-2011-01, S-XP-1999-01, S-WPB-2026-01 | Use as a pilot hypothesis, not mandatory workflow form | Future `slice-review`; pilot framing | Seven-property check and completed-case test |
| `patterns/sequential-human-checks.md` | R+A | S-NIST-AIRMF-2023-01, S-OWASP-GENAI-2026-01, S-WPB-2026-01, S-SCUBA-2026-01 | Keep human gates only where consequence expands | Workflow package contracts; pilot readiness | Review-marker and authority audit |
| `controls/deterministic-before-model-judgment.md` | R+A | S-NIST-SSDF-2022-01, S-CISA-SBD-2023-01, S-SEC-2022-01, S-SEC-2023-01, S-SKILL-ARCH-2026-01, S-RLP-2026-01 | Machine-provable invariants precede probabilistic review | Future `research-audit`; pilot checks | Valid, deterministic-failure, and semantic-failure fixtures |
| `measures/production-qualified-value-slice.md` | R+A | S-NBER-2026-01, S-DORA-2025-01, S-SPACE-2021-01, S-DEVEX-2023-01, S-WPB-2026-01 | Separate activity, qualified completion, guardrails, and total cost | Workflow package value model; case study | Unit/provenance check and matched-case review |
| `sources/source-register.md` | R | All S-prefixed sources | One canonical source record per cited work or precedent | All cards and auditors | ID uniqueness and URL/source resolution |
| `../PACKAGE-BUILDER-INTEGRATION.md` | A | S-WPB-2026-01 | Research supports recommendations but never owner facts | Workflow Package Builder integration | Package-field boundary audit |
| `../PLUGIN-DESIGN.md` | A+P-design | S-RLP-2026-01, S-SKILL-ARCH-2026-01, S-SCUBA-2026-01, S-IMPL-IMS-2026-01, S-IMPL-BASH-2026-01 | Build a thin research-to-pilot plugin, not a lifecycle orchestrator | Future plugin implementation | Decision record and scope tests |

## Provenance classes

- `R` — evaluated research content.
- `A` — adaptation from research, owner method, or external precedent.
- `P` — plugin/runtime implementation or its design.
- `T` — deterministic test or fixture.
- `I` — installation and manifest layer.

## Rules

- A map row documents why an artifact exists; it does not prove the artifact is correct.
- Exact quotations remain with their source and license requirements.
- Adapted practices retain applicability conditions and rejected alternatives.
- The broader research repository is canonical; a future plugin contains a versioned reviewed snapshot.
