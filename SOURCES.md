# Source register

Every `[E]` and `[S]` claim in [`STANDARDS.md`](STANDARDS.md) cites an ID from this file. `bin/validate-standards.sh` refuses a graded claim whose ID is not here, and refuses an ID here that nothing cites.

**Why this file exists.** `STANDARDS.md` carried 31 graded claims and zero citations. Its only route to evidence was a reference to a branch, `experiment/0.0.0`, which does not exist on origin and never did. From inside the repository every `[E]` claim was an assertion. Found by the external audit in #22; the register was recovered from history at `fa7538a:research/sources/source-register.md`. <!-- dead-pointer: experiment/0.0.0 — named here to record that it never existed on origin, not as a route to anything -->

**Three defects in the recovered corpus are corrected here**, not inherited. `STANDARDS.md` named them and nothing had acted on it:

| Defect | Correction |
|---|---|
| One source's population understated fivefold | `S-NBER-2026-01` read "more than 100,000"; the paper says more than 500,000 |
| The METR supersession unrecorded | Added as `S-METR-2026-01`, with METR's own reliability caveat |
| Three vendor-affiliated sources filed under non-vendor labels | `S-FIELD-2025-01`, `S-DORA-2024-01`, `S-DORA-2025-01` now carry **vendor-affiliated** in the class column |

---

## Empirical

| ID | Source | Date | Class | Population or scope | Finding | Limitation |
|---|---|---|---|---|---|---|
| `S-NBER-2026-01` | Demirer, Musolff, Yang — [nber.org/papers/w35275](https://www.nber.org/papers/w35275) | 2026-05 | Observational event study | **More than 500,000** GitHub developers with usage telemetry | Coding gains attenuate at project and release levels; output did not establish proportional usage value | Observational; activity and marketplace proxies |
| `S-FIELD-2025-01` | Demirer et al. — [doi.org/10.1287/mnsc.2025.00535](https://doi.org/10.1287/mnsc.2025.00535) | 2025 | Controlled field experiment — **vendor-affiliated** | 4,867 developers across three companies | AI-assistant access increased completed tasks ~26%; larger gains for less-experienced developers | Run by Microsoft and Accenture on GitHub Copilot, with vendor co-authors. Company tasks and assistant generation limit transfer to autonomous agents |
| `S-METR-2025-01` | METR — [arxiv.org/abs/2507.09089](https://arxiv.org/abs/2507.09089) | 2025-07 | Randomized controlled trial | 16 experienced maintainers, 246 real mature-repository tasks | AI-allowed work took **19% longer** despite perceived acceleration | Small sample, early-2025 tools. **Superseded for its period — see `S-METR-2026-01`** |
| `S-METR-2026-01` | METR — [x.com/METR_Evals/status/2026355544668385373](https://x.com/METR_Evals/status/2026355544668385373) | 2026-02-24 | Follow-up study, **author's own supersession** | 57 developers (10 from the original, 47 new), 143 repositories, 800+ tasks | METR states the 19–20% slowdown finding "is now outdated" and that "speedups now seem likely" | **METR's own caveat, quoted:** *"changes in developer behavior make our new results unreliable. We're working to address this."* The per-cohort figures (−18% for returning developers, −4% for new) are **relayed from secondary coverage and not verified against a METR publication** — the post is not on METR's blog index as of 2026-10-03 |
| `S-SEC-2022-01` | Pearce et al. — [doi.org/10.1145/3610721](https://doi.org/10.1145/3610721) | 2022/2025 | Security evaluation | 1,689 generated programs across CWE scenarios | A material share contained security weaknesses | Earlier model generation, synthetic scenarios |
| `S-SEC-2023-01` | Perry et al. — [doi.org/10.1145/3576915.3623157](https://doi.org/10.1145/3576915.3623157) | 2023 | Controlled user study | Security-sensitive programming tasks | AI-assisted participants produced less-secure code and were more confident in it | Bounded tasks, older models |
| `S-METR-2025-02` | METR task horizons — [arxiv.org/abs/2503.14499](https://arxiv.org/abs/2503.14499) | 2025-03 | Benchmark research | Software, ML and cybersecurity tasks | Agent success declined as task horizon increased | Well-specified benchmarks differ from production delivery |
| `S-DORA-2024-01` | DORA 2024 — [dora.dev](https://dora.dev/research/2024/dora-report/2024-dora-accelerate-state-of-devops-report.pdf) | 2024 | Global survey — **vendor-affiliated** | ~3,000 technology professionals | AI correlated with individual flow improvements but lower delivery throughput and stability | Self-report, correlational, Google Cloud affiliation |
| `S-DORA-2025-01` | DORA 2025 — [research.google](https://research.google/pubs/dora-2025-state-of-ai-assisted-software-development-report/) | 2025 | Global survey — **vendor-affiliated** | ~5,000 professionals | AI acted as an amplifier; throughput association improved, stability remained pressured | Self-report, correlational, Google Cloud affiliation |

## Our own measurements

Recorded here because `STANDARDS.md` cites them and a reader needs to know they are ours, not the field's.

| ID | Source | Date | Class | Scope | Finding | Limitation |
|---|---|---|---|---|---|---|
| `S-OURS-APPROVAL-2026-01` | [`process/02-discover/topics/agent-pr-approval.md`](process/02-discover/topics/agent-pr-approval.md) | 2026-10-03 | Our own measurement, GitHub search and REST APIs | 300 Copilot-authored pull requests since 2026-09-01 | An agent was the **sole** approving reviewer on 10%, approved alongside a human on 4%, a human approved 85% | One vendor, one month, public repositories only. The raw search count of 875 overstates the phenomenon ~7× if read as self-approvals |

## Standards and frameworks

| ID | Source | Date | Class | Scope | Contribution | Limitation |
|---|---|---|---|---|---|---|
| `S-NIST-AC5` | NIST SP 800-53 AC-5 — [csrc.nist.gov](https://csrc.nist.gov/projects/risk-management/sp800-53-controls/release-search#!/control?version=5.1&number=AC-5) | 2020 | Standard | Separation of duties | The maker-checker control `STANDARDS.md` §3 maps onto | Written in terms of *"different individuals or roles"*; routes enforcement through IA-2 *Organizational Users*, not IA-9 *Service Identification*. **Says nothing for or against a non-person holding a separated duty** |
| `S-NIST-SSDF-2022-01` | NIST SSDF — [csrc.nist.gov/projects/ssdf](https://csrc.nist.gov/projects/ssdf) | 2022 onward | Standard | Secure software development | Structural secure-development baseline | Does not prescribe any of this |
| `S-NIST-AIRMF-2023-01` | NIST AI RMF — [nist.gov](https://www.nist.gov/itl/ai-risk-management-framework) | 2023 | Standard | AI risk management | Govern, map, measure, manage | Establishes expected practice, not implementation effectiveness |
| `S-OWASP-GENAI-2026-01` | OWASP GenAI — [genai.owasp.org](https://genai.owasp.org/) | 2026 | Community security guidance | LLM and agentic systems | Prompt injection, sensitive data, excessive agency, supply chain, output risks | Guidance evolves; does not prove control effectiveness |
| `S-SLSA-2023-01` | SLSA — [slsa.dev](https://slsa.dev/) | 2023 onward | Supply-chain standard | Build provenance | Hardened, traceable artifact promotion | Does not establish code quality or human approval |
| `S-CISA-SBD-2023-01` | CISA Secure by Design — [cisa.gov](https://www.cisa.gov/securebydesign) | 2023 onward | Government guidance | Software products | Security outcomes as structural defaults, not end-user burden | Broad product guidance, not an AI-SDLC effectiveness study |
| `S-SPACE-2021-01` | SPACE — [queue.acm.org](https://queue.acm.org/detail.cfm?id=3454124) | 2021 | Research framework | Developer productivity | Productivity is multidimensional and cannot be reduced to activity | Not an AI intervention study |
| `S-DEVEX-2023-01` | DevEx — [queue.acm.org](https://queue.acm.org/detail.cfm?id=3595878) | 2023 | Research framework | Developer experience | Feedback loops, cognitive load and flow shape effectiveness | Not an AI intervention study |
| `S-DORA-CAP-2025-01` | DORA AI Capabilities Model — [research.google](https://research.google/pubs/introducing-the-dora-ai-capabilities-model-7-keys-to-succeeding-in-ai-assisted-software-development/) | 2025 | Research-derived framework — **vendor-affiliated** | Organizational capabilities | Small batches, VCS, platforms, data, policy and user focus condition AI value | Not universal causal guarantees; Google Cloud affiliation |

## Practitioner frameworks

| ID | Source | Date | Class | Contribution | Limitation |
|---|---|---|---|---|---|
| `S-AGILE-2001-01` | Agile Manifesto — [agilemanifesto.org](https://agilemanifesto.org/) | 2001 | Practitioner framework | Working software over comprehensive documentation; responding to change over following a plan | Not controlled evidence |
| `S-XP-1999-01` | Extreme Programming — [extremeprogramming.org](https://www.extremeprogramming.org/values.html) | 1999 onward | Practitioner framework | Communication, simplicity, feedback, courage, respect | Requires local fit |
| `S-LEAN-2011-01` | Lean Startup — [theleanstartup.com](https://theleanstartup.com/principles) | 2011 | Practitioner framework | Small experiments support validated learning | Not controlled AI-SDLC evidence |

---

## Interpretation rules

Carried forward from the recovered register, because they are what stop this file being a list of links.

- **Our own measurements establish facts about our situation; they do not establish the field's.** `S-OURS-*` entries are one team, one month.
- **Standards support control expectations, not proof that a control works locally.**
- **Vendor documentation proves capability, not outcome effectiveness.** A vendor-affiliated empirical study is still empirical; the affiliation is a limitation, recorded in the class column so it cannot be read past.
- **Working papers, preprints and framework claims retain their stated limitations.**
- **A superseded finding keeps its entry.** `S-METR-2025-01` is not deleted — it stands for its period, and `S-METR-2026-01` records what replaced it and that the replacement's own authors call it unreliable.

## What is not in here

**The research corpus this derives from is at `fa7538a`**, not on a branch. `experiment/0.0.0` was referenced in three places and does not exist on origin; those references are corrected to the commit. <!-- dead-pointer: experiment/0.0.0 — named here to record that it never existed on origin, not as a route to anything -->

Nothing in this file sources the repository's own `[P]` and `[O]` claims, by design — a practitioner observation is ours, and an open question has no source by definition.
