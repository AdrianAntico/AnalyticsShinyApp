# GenAI Context Strategy Research

Analytics Workstation treats GenAI context selection as an empirical research problem. No context strategy is assumed to be globally best.

This research sits under the Context Optimization Policy. Experiments compare representations after deterministic facts and Evidence Routing have made the search space smaller.

## Hypothesis

Different artifact families communicate best through different representations:

- Visual shape may be efficient for histograms, SHAP dependence plots, heatmaps, and trend plots.
- Exact values may require table previews, full tables, or structured JSON.
- Captions and metadata may be enough for simple artifacts.
- Hybrid strategies may outperform pure image or pure text for dense analytical evidence.

Information Encoding is now a separate experimental dimension. The same artifact family may perform differently when encoded for humans versus LLMs, even if the render target is unchanged.

## Artifact Family

Studies record `artifact_family` with `artifact_family_policy_source`:

- `explicit`
- `inferred`
- `unknown`

Current families include histogram, heatmap, correlation matrix, SHAP importance, SHAP dependence, SHAP interaction, trend, table ranking, table metrics, table diagnostics, table correlation, narrative, recommendation, and diagnostic artifacts.

## Context Provenance

Every experiment row records where context came from:

- `caption_source`
- `metadata_source`
- `diagnostics_source`
- `recommendations_source`
- `narrative_source`
- `table_preview_source`
- `json_summary_source`
- `screenshot_source`

Rows also record upstream AI provenance:

- `upstream_ai_used`
- `upstream_ai_provider`
- `upstream_ai_model`
- `upstream_ai_tokens`
- `upstream_ai_prompt_type`

This prevents comparing deterministic screenshots against AI-generated metadata without knowing it.

## Scoring Schema

Manual review fields are included but not automated:

- `correctness_score`
- `completeness_score`
- `usefulness_score`
- `hallucination_score`
- `missed_key_points`
- `overclaiming_score`
- `exact_value_accuracy`
- `reviewer_notes`

Derived metrics remain `NA` until scoring exists.

## Baseline Rules

Baseline rules are hypotheses:

- Text-only models cannot inspect screenshot pixels.
- Vision strategies require `image_payload_used = TRUE`.
- Exact-value questions prefer structured table or JSON context when available.
- Table artifacts should prefer preview or balanced context before `full_table`.
- `full_table` is guarded by safety thresholds.
- Dense plots may require screenshot plus caption or metadata.
- Heatmaps and correlation matrices may need screenshot plus table preview.
- SHAP dependence plots may prefer screenshot plus caption.
- Boxplots may require screenshot plus quantile backing data.
- LLM encodings may outperform human encodings when information density matters more than presentation aesthetics.
- Thumbnail encodings should not be used as substitutes for analytical evidence.

These rules are not production optimization. They seed research and conservative recommendations.

## Encoding Research

Future studies should compare:

- human encoding
- LLM encoding
- thumbnail encoding
- executive encoding
- developer encoding

Comparisons should record artifact family, question type, token usage, latency, manual quality scores, hallucination flags, and missed analytical points.

The research question is not whether one encoding is globally best. The question is which encoding communicates the most useful information for a specific consumer, artifact family, and question type.

## Recommendation Stub

`recommend_context_strategy()` combines:

- deterministic baseline rules
- available experiment evidence count
- user constraint
- provider capabilities

It returns a conservative recommendation, fallback, reason, confidence, evidence count, and rule source. Confidence remains low until enough manually scored evidence exists.

## Evidence Routing

Context strategy research feeds the conservative Evidence Routing Policy documented in `docs/evidence_routing_policy.md`.

The routing policy builds an evidence plan before a GenAI call. It decides which artifacts to exclude, mention, summarize, include as evidence, deep dive, or request as missing evidence. It records utility estimates, strategy choices, costs, and observability data for future learning.

The routing policy does not automatically optimize production behavior. It is explainable research infrastructure.

## Context Optimization

Context strategy recommendations should optimize analytical information transfer, not only token cost. They should account for expected utility, cost, novelty, trust, insight gain, redundancy, provider capability, and user profile.

Deterministic rules remain the default. Probabilistic routing is reserved for uncertainty, such as semantic overlap or usefulness estimates that deterministic metadata cannot confidently resolve.

## Outputs

`run_genai_context_strategy_study()` writes:

- `results.csv`
- `responses.json`
- `summary.md`
- `family_comparison.md`
- `strategy_recommendations.csv`
- `open_questions.md`

## Caveats

This framework is research infrastructure. It does not implement Agentic Lab, autonomous actions, render-target changes, or production automatic strategy optimization.
