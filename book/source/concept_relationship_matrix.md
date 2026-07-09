# Concept Relationship Matrix

This matrix records purpose, inputs, outputs, dependencies, and downstream consumers for major Ontology v1 concepts.

| Concept | Purpose | Inputs | Outputs | Dependencies | Downstream Consumers | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Manifesto | State governing values | project history, architecture lessons | principles | ontology, corpus | contributors, book, architecture | clear |
| Project | Own analytical world | data, runs, modules, artifacts | project state | app state, storage | collector, mission control, artifact studio | clear |
| Project Run | Preserve execution episode | module execution | run artifacts, run metadata | project | collector, manifest, timeline | clear |
| Artifact | Durable evidence object | module output | structured artifact | artifact model | collector, studio, routing | clear |
| Artifact Model | Standardize artifacts | payloads, metadata | artifact contract | producers | collector, QA, UI | clear |
| Artifact Bundle | Submit artifacts to collector | artifacts, module/run metadata | bundle | artifact model | collector | clear |
| Collector | Preserve project evidence memory | bundles | manifest, DOCX, artifact directory | artifacts | knowledge state, delivery, studio | clear |
| Manifest | Record collector state | module statuses, artifacts | reconstructable run record | collector | knowledge state, mission control | clear |
| Artifact Quality | Evaluate completeness | artifact components | completeness/status | artifact model | routing, studio, collector | clear |
| Trustworthiness | Evaluate reliability | diagnostics, validation, assumptions | trust signal | quality, evidence | knowledge state, routing | needs refinement |
| Table Artifact | Preserve tabular evidence | canonical table | previews, sidecars | table policy | LLM DOCX, routing, collector | clear |
| Table Policy | Define table views | table type, producer intent | sort/preview policy | producer semantics | table artifact, context strategy | clear |
| Producer Semantics | Declare meaning | producer knowledge | intent, importance, purpose | module producers | routing, encoding, quality | clear |
| Analytical Intent | Classify artifact purpose | producer semantics | intent label | artifact model | routing, context strategy | clear |
| Artifact Importance | Prioritize artifact | producer judgment | critical/recommended/supplementary | producer semantics | MIG, routing, rendering | clear |
| Evidence | Use artifact for reasoning | artifact + purpose | support/contradiction | artifact | knowledge state, routing | clear |
| Knowledge State | Represent what is known/unknown | evidence, findings, assumptions | gaps, readiness, future evidence | evidence, collector | context optimization, mission control | clear/emerging |
| Knowledge | Represent supported understanding | evidence, reasoning | finding/belief | knowledge state | decisions, reports, GenAI | clear/emerging |
| Unknown | Represent unresolved truth | gaps, missing evidence | open questions | knowledge state | future evidence, MIG | clear/emerging |
| Assumption | Represent carried premise | user/domain/model context | assumption record | knowledge state | readiness, trustworthiness | clear/emerging |
| Hypothesis | Represent testable claim | question, pattern, suggestion | test need | knowledge state | future evidence | clear/emerging |
| Validated Finding | Represent supported claim | evidence, sufficiency | finding | knowledge state | reports, decisions | clear/emerging |
| Open Question | Operationalize unknown | unknown, decision need | question | knowledge state | future evidence, routing | clear/emerging |
| Decision Readiness | Judge action support | findings, evidence, confidence | readiness level | knowledge state | mission control, reports | clear/emerging |
| Knowledge Gap | Identify missing understanding | desired readiness, current knowledge | gap | knowledge state | MIG, future evidence | clear/emerging |
| Contradiction | Preserve conflict | conflicting findings/evidence | contradiction record | knowledge state | readiness, routing | clear/emerging |
| Future Evidence | Identify evidence to generate | gaps, unknowns | evidence request | knowledge state, MIG | routing, mission control | clear/emerging |
| Evidence Sufficiency | Judge enough evidence | evidence, readiness target | sufficient/insufficient | MIG, knowledge state | context optimization | needs calibration |
| Marginal Information Gain | Optimize evidence value | gap, cost, uncertainty | utility estimate | knowledge state, evidence | context optimization | research |
| Context Optimization | Govern constraints/objective | strategy, budget, provider | optimization profile | MIG, provider caps | evidence routing, context strategy | clear |
| Evidence Strategy | User-facing posture | user constraints | strategy profile | UX, context policy | context optimization | needs naming guard |
| Evidence Routing | Select evidence | artifacts, profile, gap | evidence plan | context optimization | context strategy, GenAI | clear |
| Evidence Plan | Record selected evidence | routing result | included/excluded/missing evidence | evidence routing | context strategy, observability | clear |
| Context Strategy | Represent selected evidence | evidence plan, provider | context package | encoding, provider caps | GenAI, telemetry | clear |
| Information Encoding | Adapt representation | artifact, consumer | encoded artifact | artifact model | render target, context strategy | clear |
| Render Target | Deliver representation | encoded artifact | report/doc/UI/API | encoding | users, LLM, delivery | clear |
| Human Report | Human delivery | report plan, artifacts | readable report | render target | humans | clear |
| LLM DOCX | LLM delivery | artifacts, dense encoding | evidence doc | render target, collector | LLM/custom GPT | research/emerging |
| GenAI Service | Provider abstraction | context package | response | provider adapter | reasoning, telemetry | clear |
| Provider Adapter | Translate provider calls | service request | normalized response | provider endpoint | GenAI service | clear |
| Provider Capability | Describe model abilities | provider/model | capability flags | adapter | context optimization | clear |
| GenAI Telemetry | Record calls | request/response | telemetry | GenAI service | observability, learning | clear |
| Observability | Record behavior | telemetry, manifests, QA | audit data | structured outputs | learning, review | clear |
| Learning | Refine future behavior | observations, scores | calibrated policies | observability | optimization, routing, knowledge state | future |
| Mission Control | Show project state | project, manifest, knowledge state | status/alerts/next actions | workstation UI | users | emerging |
| Artifact Studio | Browse evidence | artifact inventory | inspection/selection | artifact model | users, GenAI actions | clear |
| Delivery | Send output to consumer | encoded artifacts | report/export/brief | render target | humans/LLMs | emerging |
| Command Palette | Command navigation | command registry | actions/routes | UI shell | users | clear |
| Book Compiler | Produce knowledge products | corpus, ontology, docs | manuscripts/source packs | source material | book/GPT/docs | emerging |

## Matrix Findings

Concepts with strongest clarity:

- Artifact
- Collector
- Artifact Quality
- Table Artifact
- Producer Semantics
- Render Target
- Information Encoding
- Evidence Routing
- Context Strategy
- GenAI Service
- Observability

Concepts needing refinement:

- Trustworthiness
- Evidence Sufficiency
- Decision Readiness calibration
- Delivery ownership
- Learning update rules

Concepts intentionally future/speculative:

- Agentic Lab
- Model Landscape
- Delivery Studio
- automatic Learning
- Knowledge Graph implementation

