# Source register

## Empirical research

| Source | Class | Main relevance |
|---|---|---|
| Demirer et al., “The Effects of Generative AI on High-Skilled Work” — https://doi.org/10.1287/mnsc.2025.00535 | Controlled field experiments | AI assistance increased completed tasks across 4,867 developers; effects varied by experience. |
| METR, “Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity” — https://arxiv.org/abs/2507.09089 | Randomized controlled trial | Experienced maintainers took 19% longer with AI despite perceiving a speedup. |
| Demirer, Musolff, Yang, “Writing Code vs. Shipping Code” — https://www.nber.org/papers/w35275 | Observational/event study | Coding activity gains attenuated substantially at project and release levels. |
| DORA 2024 — https://dora.dev/research/2024/dora-report/2024-dora-accelerate-state-of-devops-report.pdf | Global survey research | AI adoption improved individual flow but was associated with lower delivery throughput and stability in 2024. |
| DORA 2025 — https://research.google/pubs/dora-2025-state-of-ai-assisted-software-development-report/ | Global survey and qualitative research | AI acts as an amplifier; throughput relationship improved while stability remained pressured. |
| Pearce et al., “Asleep at the Keyboard?” — https://doi.org/10.1145/3610721 | Security evaluation | Generated programs frequently contained security weaknesses. |
| Perry et al., “Do Users Write More Insecure Code with AI Assistants?” — https://doi.org/10.1145/3576915.3623157 | Controlled user study | AI-assisted participants produced less secure code and were more confident in it. |
| METR, software-task time horizons — https://arxiv.org/abs/2503.14499 | Benchmark research | Agent reliability declines as task duration and ambiguity increase. |

## Delivery and human-system frameworks

| Source | Class | Main relevance |
|---|---|---|
| DORA AI Capabilities Model — https://research.google/pubs/introducing-the-dora-ai-capabilities-model-7-keys-to-succeeding-in-ai-assisted-software-development/ | Research-derived framework | AI value depends on platforms, small batches, data access, VCS, policy, and user focus. |
| SPACE framework — https://queue.acm.org/detail.cfm?id=3454124 | Research framework | Developer productivity is multidimensional and cannot be reduced to activity. |
| DevEx framework — https://queue.acm.org/detail.cfm?id=3595878 | Research framework | Feedback loops, cognitive load, and flow state shape engineering effectiveness. |
| Lean Startup — https://theleanstartup.com/principles | Practitioner framework | Small experiments should test assumptions through validated learning. |
| Extreme Programming — https://www.extremeprogramming.org/values.html | Practitioner framework | Feedback, simplicity, communication, courage, and respect support small, safe change. |
| Martin Fowler, TDD in the agent loop — https://martinfowler.com/articles/exploring-gen-ai/tdd-in-the-agent-loop.html | Practitioner experiment | Telling an agent to do TDD does not itself guarantee a real red-green loop or better outcomes. |
| Simon Willison, Agentic Engineering Patterns — https://simonwillison.net/2026/Feb/23/agentic-engineering-patterns/ | Practitioner synthesis | Professional agent use requires executable feedback, review, and bounded tools. |

## Security and governance standards

| Source | Class | Main relevance |
|---|---|---|
| NIST AI RMF — https://www.nist.gov/itl/ai-risk-management-framework | Standard/framework | Govern, map, measure, and manage AI risk. |
| NIST SSDF — https://csrc.nist.gov/projects/ssdf | Standard/framework | Secure software development practices remain the baseline. |
| NIST SP 800-218A — https://www.nist.gov/publications/secure-software-development-practices-generative-ai-and-dual-use-foundation-models-ssdf | Standard/profile | Extends secure development practices to generative AI. |
| OWASP GenAI Security Project — https://genai.owasp.org/ | Community standard | Prompt injection, excessive agency, sensitive data, supply chain, and output handling risks. |
| CISA Secure by Design — https://www.cisa.gov/securebydesign | Government guidance | Security outcomes should be structural defaults rather than user burden. |
| SLSA — https://slsa.dev/ | Supply-chain standard | Build provenance and hardened promotion paths for artifacts. |

## Architecture and practitioner perspectives

| Source | Class | Main relevance |
|---|---|---|
| Anthropic, AI-Native SDLC Playbook — https://claude.com/blog/the-ai-native-sdlc-playbook | Vendor methodology | Original six-stage artifact-loop thesis; procedural claims are documented but outcomes are not independently proven. |
| Thoughtworks, context engineering — https://www.thoughtworks.com/radar/techniques/context-engineering | Practitioner framework | Context becomes an architectural design surface for agent systems. |
| Charity Majors, “AI demands more engineering discipline, not less” — https://charity.wtf/p/ai-demands-more-engineering-discipline | Practitioner argument | Cheap code increases the value of architecture, constraints, and production evidence. |
| Microsoft Research, “To Copilot and Beyond” — https://www.microsoft.com/en-us/research/publication/to-copilot-and-beyond-22-ai-systems-developers-want-built/ | Qualitative research | Developers prefer bounded delegation, provenance, uncertainty, and least privilege. |
| Addy Osmani, agentic code review — https://addyosmani.com/blog/agentic-code-review/ | Practitioner synthesis | Verification and trust become central as generation volume grows. |
| Scuba Stack — https://github.com/danielchappell/scuba-stack | Open-source workflow | Shows explicit intake, delegation, adversarial review, monitoring, and durable control-plane artifacts. |
| ICM — https://github.com/RinDig/Interpretable-Context-Methodology | Research/methodology | Uses staged context contracts and inspectable output handoffs instead of hidden orchestration code. |
| Repository Learning Protocol — https://github.com/Okja-Engineering/repo-learning-protocol | Open-source protocol | Filters corrections into checks, tests, scoped context, skills, or discard. |
| Skill Architect — https://github.com/Okja-Engineering/skill-architect | Open-source plugin | Defines deterministic-first skills, progressive disclosure, HITL changes, and the 60/30/10 heuristic. |
| `imsungbin/ai-native-sdlc-playbook` — https://github.com/imsungbin/ai-native-sdlc-playbook | Open-source implementation precedent | Faithful article-to-file implementation with provenance map, locked verbatim content, hooks, tests, and explicit non-implemented product capabilities. |
| `bashebr/ai-native-sdlc` — https://github.com/bashebr/ai-native-sdlc | Open-source implementation precedent | Broad reusable lifecycle skill with staged adoption, workflow graph, assets, eval tooling, gate ledger, and autonomous-agent organization. |

## Source rules

- Vendor documentation proves product capability, not outcome effectiveness.
- Thought-leader agreement is a practice signal, not empirical proof.
- Preprints remain provisional until replicated or peer reviewed.
- Every downstream claim must retain population, measured outcome, and limitations.
