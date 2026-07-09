# Marginal Information Gain Framework

Analytics Workstation treats analytical evidence as an optimization problem.

The original intuition was simple: reduce token usage. That is no longer the right objective. A token-minimizing system can become under-informed, brittle, and misleading. A maximum-context system can become expensive, slow, redundant, and harder for a language model to reason over.

The deeper objective is:

```text
Maximize analytical information transfer
while minimizing unnecessary cost.
```

This is the same pattern that appears throughout data science and decision science:

- marginal ROI
- marginal lift
- marginal utility
- marginal media contribution
- efficient frontiers
- diminishing returns
- budget-constrained optimization

Analytics Workstation applies the same reasoning to analytical evidence.

Every artifact is an investment. The question is not simply:

```text
Should this artifact be included?
```

The better question is:

```text
What is the marginal analytical information gained by including this artifact,
given the evidence already selected and the decision being supported?
```

That question defines the Marginal Information Gain framework.

## Core Principle

Every artifact can contribute:

- positive information
- negative information
- redundancy
- cost
- uncertainty

Positive information helps the consumer understand the analytical landscape more accurately. Negative information can also be valuable: a caveat, warning, failed validation, model weakness, missingness pattern, suspicious leakage signal, or fragile assumption may reduce confidence in a conclusion, but it improves the truthfulness of the evidence package.

Redundancy is not automatically bad. Repeated evidence can increase confidence when it comes from independent perspectives. But redundancy becomes wasteful when it repeats the same analytical fact without improving trust, nuance, or decision quality.

Cost is broader than tokens. Cost includes:

- input tokens
- output tokens
- latency
- provider cost
- local compute
- privacy risk
- cognitive load
- model confusion
- opportunity cost within a fixed context budget

Uncertainty matters because evidence is rarely perfect. Screenshots may be visually dense but imprecise. Tables may be exact but narrow. Narratives may be concise but lossy. JSON may be structured but incomplete. The value of an artifact depends on what it clarifies and what uncertainty it leaves behind.

The optimization problem becomes:

```text
Maximize expected Marginal Information Gain

Subject to:
  token budget
  latency budget
  privacy constraints
  provider capabilities
  user preference
  decision criticality
  evidence availability
```

## Defining Marginal Information Gain

Marginal Information Gain, or MIG, is the expected improvement in analytical understanding caused by adding one more evidence item to the current context.

An artifact has high marginal gain when it changes expected understanding.

Examples:

- A correlation heatmap reveals a cluster of highly collinear predictors that was not visible in the model metrics.
- A SHAP dependence plot reveals a nonlinear effect that a variable-importance table could not show.
- A calibration plot shows that a high-AUC classifier is poorly calibrated.
- A missingness table reveals that the strongest predictor is missing for most of the deployment population.
- A diagnostic warning shows that an apparently strong effect may be caused by leakage.

An artifact has low marginal gain when it repeats what is already known.

Examples:

- A second importance table ranks features almost identically to the first.
- A narrative restates the caption without adding interpretation.
- A screenshot and table preview communicate the same simple count distribution.
- A full table is sent even though the top and bottom preview slices answer the question.

Marginal gain is contextual. It depends on:

- the question being asked
- the artifacts already selected
- the artifact family
- the information encoding
- the model or provider capabilities
- the user's objective
- the decision being supported
- the cost and risk of being wrong

There is no universal artifact value. A plot can be essential for one question and nearly useless for another. A full table can be wasteful during exploration and justified during audit. A screenshot can be highly informative to a vision-capable model and only a sidecar reference to a text-only model.

MIG is not a fixed score on an artifact. It is the expected value of adding that artifact at a particular moment in a particular evidence plan.

## Proposed Utility Components

This framework does not finalize equations. The following components are research concepts that can guide deterministic routing, future learning, and manual evaluation.

### Task Relevance

How directly does this artifact answer the question?

A SHAP dependence plot is highly relevant to feature-effect questions. A project manifest may be more relevant to workflow status questions. A confusion matrix is relevant to classification assessment, but less relevant to feature engineering recommendations.

### Trustworthiness

How much should the system trust this artifact?

Trustworthiness may depend on:

- artifact quality score
- producer reliability
- sample size
- validation status
- diagnostics
- warning severity
- missing components
- screenshot success
- table sidecar availability
- whether the artifact is stale

Trustworthy artifacts are not always positive. A severe diagnostic warning can be very trustworthy and highly valuable.

### Novelty

How much new information does the artifact add relative to what is already selected?

Novelty is the heart of marginal reasoning. An artifact can be high quality and highly relevant but still low marginal value if it duplicates existing evidence.

### Expected Insight Gain

How likely is this artifact to reveal a useful analytical conclusion?

This is a pragmatic estimate of whether the artifact helps the consumer discover patterns, anomalies, risks, relationships, or decisions that were not obvious before.

### Expected Decision Impact

How much could this artifact change the recommendation, confidence level, or next action?

Some artifacts are interesting but unlikely to affect decisions. Others can alter the entire project trajectory.

Examples of high decision impact:

- leakage detection
- severe class imbalance
- drift between training and scoring populations
- unstable model performance
- high-value feature effect
- model calibration failure
- recommendation conflict

### Context Cost

What does inclusion cost?

Cost includes:

- estimated input tokens
- image payload size
- table preview size
- full table size
- latency
- paid provider cost
- privacy exposure
- risk of distracting the model

The cheapest representation is not always best. The best representation is the one with the highest expected information gain per relevant unit of cost.

### Uncertainty

How uncertain is the estimated value of the artifact?

Uncertainty may come from:

- incomplete metadata
- missing screenshots
- missing table sidecars
- unknown model vision capability
- ambiguous artifact type
- insufficient QA history
- conflicting evidence

High uncertainty does not always imply exclusion. It may imply a conservative strategy, a preview-only strategy, or a request for more evidence.

### Redundancy

How much does the artifact overlap with selected evidence?

Redundancy can be measured conceptually across:

- artifact type
- producer
- analytical intent
- feature set
- metric family
- plot family
- caption similarity
- table columns
- diagnostic category
- decision implication

Some redundancy is useful for corroboration. Excessive redundancy wastes context and can dilute the signal.

### Provider Capability

The same artifact representation can have different value depending on the provider.

Examples:

- A screenshot has low direct value for a text-only model unless transformed into a caption or sidecar reference.
- A vision-capable model may extract pattern-level information from a plot more efficiently than a text-only summary.
- A small local model may perform better with structured JSON than with dense visual evidence.
- A larger remote model may tolerate richer mixed context but carry higher privacy and cost tradeoffs.

Provider capability changes the expected marginal gain of each representation.

## Information Compression

Analytics Workstation does not treat raw data as the default best representation. Raw data is often the least efficient way to transfer analytical understanding.

Analytical work naturally compresses information through layers:

```text
Raw Data
  -> Statistical Summary
  -> Visual Summary
  -> Narrative Summary
  -> Executive Summary
```

Each layer intentionally throws away some detail.

That is not a bug. It is the point.

The objective is not lossless compression. The objective is preserving decision-relevant information while reducing unnecessary burden.

### Raw Data

Raw data is highest fidelity but often lowest efficiency. It preserves everything, including noise, irrelevant rows, redundant columns, and privacy-sensitive values.

Raw data should not be sent by default. It may become appropriate for narrow, high-criticality questions where exact row-level evidence is required and safety constraints allow it.

### Statistical Summary

Statistical summaries compress raw data into distributions, counts, correlations, metrics, missingness, drift, and diagnostics.

They are compact, exact enough for many questions, and highly useful for models that reason well over structured text.

### Visual Summary

Visual summaries compress many values into pattern recognition.

Plots can communicate:

- shape
- outliers
- clusters
- nonlinear effects
- rank concentration
- correlation structure
- calibration behavior
- distribution overlap
- trend breaks

Visual summaries are not automatically better than tables. Their value depends on the artifact family, question type, image encoding, and model capability.

### Narrative Summary

Narratives compress analytical evidence into interpretation.

They are useful when a producer already knows what the artifact means. They can also be dangerous if they overstate, omit caveats, or hide uncertainty.

Narratives should be treated as evidence components, not replacements for evidence.

### Executive Summary

Executive summaries compress evidence into decisions, risks, and recommended actions.

They are high-level, low-detail, and decision-oriented. They are not sufficient for audit, debugging, or scientific investigation, but they may be ideal for business communication.

## Evidence Sufficiency

MIG introduces the concept of Evidence Sufficiency.

Evidence Sufficiency asks:

```text
Given the current question and decision context,
is the selected evidence enough to support a useful answer?
```

The routing engine should reason about:

- current knowledge
- knowledge gaps
- marginal gain of remaining candidates
- cost of adding more evidence
- decision criticality
- stopping criteria

### Current Knowledge

Current Knowledge is the set of analytical facts already represented in the evidence plan.

Examples:

- target is imbalanced
- top features are stable
- missingness is concentrated in specific predictors
- calibration is weak
- SHAP effects are nonlinear
- drift is present
- diagnostics are clean

### Knowledge Gaps

Knowledge Gaps are important unknowns that remain.

Examples:

- feature effects are known, but robustness is unknown
- model metrics are available, but calibration is missing
- EDA exists, but target leakage has not been assessed
- importance ranking exists, but dependence behavior is unknown
- screenshot exists, but backing table is missing

### Marginal Gain

Marginal Gain estimates whether another artifact would close a meaningful gap, refine uncertainty, or change the decision.

### Stopping Criterion

Evidence selection should continue only while the expected marginal gain remains worthwhile.

Conceptually:

```text
Continue adding evidence while:
  expected marginal gain > context-adjusted cost threshold

Stop when:
  evidence is sufficient
  budget is exhausted
  provider capability is reached
  privacy constraints prevent safe inclusion
  remaining artifacts are too redundant
```

The stopping threshold is not universal. It depends on the decision context.

## Relationship to Context Optimization

Marginal Information Gain is the theoretical basis for Context Optimization.

```text
Context Optimization
  -> Evidence Routing
  -> Marginal Information Gain
  -> Context Strategy
  -> GenAI
```

Context Optimization asks how to spend limited context wisely.

Evidence Routing builds a plan for which artifacts should be included, excluded, summarized, deep-dived, mentioned, or kept as sidecar references.

Marginal Information Gain explains why a candidate artifact deserves context budget.

Context Strategy chooses how to represent the selected artifact:

- caption only
- caption plus metadata
- screenshot only
- screenshot plus caption
- table preview
- full table
- structured JSON summary
- balanced mixed representation
- sidecar reference

GenAI receives the final routed and encoded evidence package.

MIG is not a separate feature. It is the reasoning principle that ties these layers together.

## Relationship to Existing Architecture

MIG complements the current architecture. It does not replace it.

### Artifact Model

The Artifact Model defines what evidence exists.

MIG estimates which evidence is worth adding in a given context.

### Producer Semantics

Producer Semantics describes analytical intent, importance, policy source, and meaning at the time an artifact is created.

MIG uses producer knowledge to estimate relevance, novelty, and decision impact.

### Artifact Quality Policy

Artifact Quality evaluates completeness, captions, metadata, screenshots, diagnostics, recommendations, backing tables, and JSON.

MIG uses quality as part of trustworthiness and expected utility.

### Table Artifact Architecture

The Table Artifact Architecture provides previews, sort policies, CSV sidecars, JSON sidecars, and render-target metadata.

MIG helps decide whether the best representation is a table preview, full table, structured summary, or sidecar reference.

### Information Encoding

Information Encoding controls how the same analytical artifact is encoded for different consumers.

MIG depends on encoding. A thumbnail may have high marginal value for recognition in Artifact Studio and low marginal value for detailed model reasoning. An LLM-dense encoding may be valuable for GenAI and too dense for a human report.

### Render Targets

Render Targets define where evidence is delivered:

- Human Report
- LLM DOCX
- Artifact Studio
- Collector

MIG is upstream of render target. It helps decide what evidence is worth routing, while render targets decide how selected evidence is delivered.

### Evidence Routing

Evidence Routing operationalizes MIG through explainable selection decisions.

MIG gives routing its optimization objective.

### Context Optimization

Context Optimization governs the broader budget and provider-aware strategy.

MIG provides the marginal utility concept that makes optimization meaningful.

### GenAI Context Strategy Research

GenAI Context Strategy Research measures how different artifact representations perform.

MIG supplies the research target: discover which representation produces the best marginal information gain for each artifact family, question type, and provider capability.

## Decision Criticality

Different decisions justify different stopping thresholds.

The philosophy does not change. The threshold changes.

### Exploration

Goal: understand the landscape quickly.

Routing should prefer breadth, summaries, previews, and fast feedback. Low marginal gains may be skipped quickly.

### Business Decision

Goal: support a practical recommendation.

Routing should include evidence that affects action, risk, confidence, or tradeoffs. Redundant artifacts should be avoided unless they materially increase confidence.

### Executive Briefing

Goal: communicate major findings and risks.

Routing should emphasize decision impact, recommendations, caveats, and concise evidence. Detailed diagnostics may be sidecar references unless they change the executive decision.

### Production Deployment

Goal: evaluate whether a model or analysis is safe to operationalize.

Routing should lower the threshold for diagnostics, drift, leakage, calibration, robustness, and failure modes. Negative information has high value.

### Critical Decision

Goal: avoid costly or high-risk mistakes.

Routing should prioritize thoroughness, trustworthiness, uncertainty reduction, and independent corroboration. Higher context cost is justified.

### Unlimited Budget

Goal: maximize understanding without normal token or latency constraints.

Even here, MIG still matters. Unlimited budget does not imply infinite useful context. Redundant or confusing evidence can still reduce reasoning quality.

## Learning and Observability

This document does not implement learning.

Future observations could refine estimated marginal gain.

Possible learning signals:

- manual output quality scores
- factual accuracy reviews
- user ratings
- reviewer notes
- repeated evidence selection patterns
- provider comparisons
- latency and token telemetry
- context strategy experiments
- artifact family performance
- question type performance
- user behavior in Artifact Studio
- whether recommendations changed after adding evidence

Over time, Analytics Workstation could learn:

- which artifact families usually have high gain for each question type
- which encodings work best for each provider
- when screenshots outperform tables
- when structured JSON outperforms narratives
- when full tables are worth their cost
- when evidence plans have become sufficient

The first implementation should remain explainable and conservative. Learning should refine the estimates, not turn routing into an opaque oracle.

## Open Research Questions

The MIG framework intentionally leaves important questions open.

- Can marginal information gain be estimated deterministically?
- Which components are stable enough to score before any LLM call?
- Can MIG be learned from manual ratings and repeated experiments?
- Does plot family change the gain curve?
- Do question types change the gain curve?
- Do vision models extract more useful information from screenshots than text-only models extract from structured summaries?
- When are images more efficient than tables?
- When are tables more efficient than images?
- When is a full table ever worthwhile?
- How much redundancy is useful corroboration rather than waste?
- Can negative evidence be routed aggressively without overwhelming the final answer?
- How should privacy risk be priced against expected insight gain?
- How should local model limitations change evidence strategy?
- Can evidence sufficiency be detected before generation?
- When should routing stop?
- What is the right human interface for showing why evidence was included or excluded?
- Can user preference be respected without degrading analytical quality?

These are research questions, not implementation commitments.

## Practical Implications

The MIG framework implies several product principles.

### Artifacts Exist Because They Compress Evidence

Artifacts are not decorative outputs. They are compressed analytical evidence.

Plots, tables, diagnostics, recommendations, narratives, and JSON sidecars all exist because they can transfer understanding more efficiently than raw data alone.

### Evidence Routing Exists Because Context Is Scarce

Even large context windows are scarce. Attention, latency, privacy, and reasoning quality remain scarce.

Routing exists to spend context on evidence with the highest expected marginal value.

### Context Strategies Exist Because Representation Changes Value

The same artifact may have different marginal value depending on whether it is represented as:

- screenshot
- caption
- metadata
- table preview
- full table
- structured JSON
- narrative
- sidecar reference

The artifact is the same. The information transfer efficiency changes.

### Information Encoding Exists Because Consumers Differ

Humans, LLMs, thumbnails, executives, developers, and future agents need different encodings.

MIG should eventually account for consumer type when estimating value.

### Collector Memory Exists Because Marginal Gain Depends on What Is Already Known

Marginal gain cannot be estimated without knowing prior evidence.

The Project Artifact Collector is therefore not just an export mechanism. It is project memory. It records what evidence exists, what has already been generated, and what may still be missing.

## Conceptual Summary

Analytics Workstation is an evidence-centered analytical operating environment.

Its core optimization problem is not:

```text
How do we fit more stuff into context?
```

It is:

```text
How do we transfer the most decision-relevant analytical understanding
with the least unnecessary cost?
```

Marginal Information Gain gives the system a language for answering that question.

It explains:

- why artifacts exist
- why evidence is routed
- why context is optimized
- why screenshots, tables, narratives, and JSON should be compared empirically
- why decision criticality changes evidence thresholds
- why the collector matters as memory
- why future learning should focus on utility, not just token counts

This framework should guide future Context Optimization, Evidence Routing, Information Encoding, and GenAI research. It should remain theoretical until enough telemetry, QA, and manual review exist to justify production behavior.

