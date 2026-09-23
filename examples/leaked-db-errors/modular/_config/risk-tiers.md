# Risk tiers — example

Risk scales process, not file count. The host repository's own policy defines
the tiers; this example shows the shape.

| Tier | Trigger example | Effect |
|---|---|---|
| low | docs, test-only, reversible config | stages 01–03 may collapse into one reviewed artifact |
| medium | single-service behavior change | all stages; standard review depth |
| high | crosses >1 topology edge, security-sensitive, irreversible | independent reviewer at 05; mandatory plan approval at 04 |

Scaling may reduce required evidence volume and review depth. It may never
remove authority, provenance, or review fields.
