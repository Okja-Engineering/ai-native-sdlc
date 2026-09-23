# Stage 01: Discover

Inventory material AI-native SDLC claims and their originating evidence without prematurely choosing a solution.

## Inputs

| Source | File/Location | Scope | Why |
|---|---|---|---|
| Register | `../../SOURCES.md` | Full file | Existing sources and gaps. |
| Schema | `../../_config/evidence-schema.md` | Claim and source fields | Keeps collection consistent. |
| Local references | `references/` | Selected source extracts | Stage-specific material only. |

## Process

1. State the research question and inclusion boundary.
2. Decompose source material into one claim per row.
3. Trace each claim to its earliest accessible source.
4. Search for supporting, contradictory, and null evidence.
5. Record source class, population, outcome, date, and limitations.
6. Deduplicate circular citations.
7. Save the inventory to `output/claim-inventory.md`.

## Checkpoints

| After step | Agent presents | Human decides |
|---|---|---|
| 2 | Claim domains and exclusions | Whether the research boundary matches the problem. |
| 6 | Coverage gaps and circular claims | Whether discovery is sufficient for evaluation. |

## Audit

| Check | Pass condition |
|---|---|
| Atomic claims | Every row contains one assessable claim. |
| Source quality | Material outcome claims include a primary or strongest available source. |
| Balance | Contradictory evidence was sought explicitly. |
| Independence | Repeated vendor claims are traced to one origin. |

## Outputs

| Artifact | Location | Format |
|---|---|---|
| Claim inventory | `output/claim-inventory.md` | Table conforming to the evidence schema. |
