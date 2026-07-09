# Evidence Routing Policy

Analytics Workstation should not blindly send every artifact to a language model. It should build an evidence plan that explains what evidence is included, excluded, summarized, deep-dived, or kept as sidecar reference.

This first policy is conservative, rule-based, explainable, configurable, telemetry-rich, and learning-ready. It is not autonomous and does not mutate production behavior.

Evidence Routing is layer 2 of the broader Context Optimization Policy. Deterministic artifact facts, provider capabilities, quality metadata, and safety limits should be evaluated first. Evidence Routing then uses those deterministic inputs to build an explainable evidence plan before any optional probabilistic routing or final GenAI reasoning occurs.

## Evidence Plan

An evidence plan records:

- question
- task type
- routing profile
- provider and model
- user constraints
- selected artifacts
- excluded artifacts
- mention-only or sidecar-only artifacts
- deep-dive artifacts
- request-more-evidence rows
- context strategy per artifact
- routing reason
- expected utility
- estimated context cost
- confidence
- fallback strategy

## Utility Model

The first-pass utility score is:

```text
artifact_utility =
task_relevance
* trustworthiness
* novelty
* expected_insight_gain
* user_preference_weight
/ estimated_context_cost
```

The score is intentionally approximate. It exists to produce inspectable routing decisions, not to pretend the system has learned optimal behavior.

## Routing Levels

0. Exclude
1. Mention Only
2. Summary
3. Evidence
4. Deep Dive
5. Request More Evidence

Every candidate receives one level and a reason.

## Profiles

Supported routing profiles:

- `conservative`
- `balanced`
- `thorough`
- `accuracy_first`
- `token_saver`
- `vision_first`
- `local_private`

Profiles configure artifact count, image/table limits, token budget, deep-dive threshold, redundancy tolerance, and preference for vision or exact values.

## Evidence Strategy Layer

User-facing Evidence Strategies map business intent to routing configuration:

- Efficient
- Balanced
- Thorough
- Critical Decision
- Cost Is Irrelevant

The strategy layer chooses or overrides routing profile settings, token budgets, artifact limits, provider constraints, and evidence explosion behavior. Evidence Routing remains the execution engine; Evidence Strategy is the UX/config layer above it.

## Upstream Priors

Routing uses available artifact metadata as priors:

- artifact family
- analytical intent
- module
- artifact importance
- artifact quality/completeness
- warnings and diagnostics
- screenshot availability
- table sidecar availability
- SHAP/model/EDA families inferred from producer metadata and artifact naming

Future modules can improve routing by emitting richer producer metadata.

## Context Strategy Integration

Selected artifacts are routed into existing GenAI context strategies:

- `caption_metadata`
- `screenshot_caption`
- `screenshot_caption_preview`
- `table_preview_only`
- `full_table`
- `structured_json_summary`
- `balanced`

Full tables remain guarded. Vision strategies require a provider/model configuration that can actually use images.

## Information Encoding

Evidence Routing selects evidence after an artifact has an appropriate information encoding for the consumer.

Render target and encoding are separate. For example, an LLM DOCX may use LLM encoding with denser labels, annotations, and composite analytical views, while a human report may use human encoding with more spacing, larger type, and interactive affordances.

Routing should eventually account for encoding because denser, consumer-appropriate encodings can improve analytical information transfer and reduce downstream context cost.

## Context Optimization Alignment

Evidence Routing should optimize for analytical information transfer rather than token minimization alone. Profiles such as `token_saver`, `balanced`, `accuracy_first`, `vision_first`, `local_private`, and high-stakes/critical-decision usage change routing thresholds and limits, not the governing architecture.

Probabilistic routing may be introduced later only for uncertain routing decisions such as semantic overlap or redundancy. It should reduce the evidence search space, not answer the user's question. Paid GenAI is never required for deterministic routing.

## Observability

Every plan can write:

- `evidence_plan.json`
- `evidence_plan.csv`
- `routing_summary.md`
- `observability_log.csv`

The observability log includes routing decisions, estimated costs, response placeholders, feedback placeholders, manual scores, and future learning signals.

## Learning-Ready Feedback

The log includes placeholders for:

- user rating
- answer accepted/rejected
- follow-up required
- excluded artifact opened afterward
- more detail requested
- hallucination flagged
- artifact later proved useful
- manual quality score
- feedback notes

## Policy Refinement

`update_evidence_routing_priors()` summarizes observed outcomes. It does not automatically mutate the routing policy.

Future refinement can learn from repeated evidence plans, manual scores, and user behavior, but all policy changes should remain inspectable.

## Calibration Sprint

`run_evidence_routing_calibration()` creates evidence plans across realistic analytical questions and routing profiles. It writes:

- per-plan `evidence_plan.json`
- per-plan `evidence_plan.csv`
- per-plan `routing_summary.md`
- per-plan `observability_log.csv`
- aggregate `calibration_plan_summary.csv`
- aggregate `calibration_decisions.csv`
- aggregate `calibration_report.md`

Calibration is used to inspect whether routing behaves like a professional analyst:

- token saver should include fewer, higher-value artifacts
- balanced should include key evidence with limited deep dives
- accuracy first should include more diagnostics and support
- thorough should broaden evidence inclusion

Current calibration adjustments remain simple and explainable:

- creative-attribute questions prioritize SHAP/effect/diagnostic evidence and request creative-specific evidence when absent
- model-risk questions weight diagnostics, metrics, calibration/residual gaps, and readiness evidence more strongly
- trustworthiness questions request validation/calibration evidence when unavailable
- nonlinear or unstable effect questions prioritize SHAP dependence/effect artifacts
- missing-evidence questions request interactions and validation/calibration evidence

Calibration reports are research artifacts. They do not automatically mutate policy.

## Limitations

- Utility scoring is heuristic.
- Redundancy detection is simple.
- Quality and trust depend on available artifact metadata.
- Manual scoring is not automated.
- No Agentic Lab behavior is implemented.
- No GenAI action execution is allowed.
- No full raw datasets are sent by default.
