# Part I: Foundations

# AI-Native Analytical Systems

Working title:

```text
AI-Native Analytical Systems:
Designing Software That Reasons Over Evidence
```

## The Governing Problem

Analytical software has spent decades helping people make outputs.

Dashboards show metrics. Reports preserve summaries. Notebooks mix code, charts, and prose. BI tools let users slice and filter. Modeling platforms train, score, and evaluate. Presentation tools turn analytical work into stories. Each of these forms solved a real problem. None should be dismissed. The modern data stack would not exist without them.

But they were designed for a world in which the primary consumer of analytical knowledge was a human looking at a screen or reading a document.

That world has changed.

Large language models do not merely add a chat box to existing analytical tools. They change the economics of representation. They change what it means for evidence to be useful. They change how analytical knowledge should be packaged, routed, compressed, inspected, and remembered. They make it possible for software to reason over a project, but only if the project has been structured as evidence rather than as a loose pile of charts, tables, reports, notebooks, logs, and exports.

The central claim of this book is that analytical software must evolve from dashboard and report generation into evidence-centered analytical operating environments.

This is not a cosmetic change. It is an architectural change.

An AI-native analytical system is not a dashboard with a chatbot. It is a software environment where analytical artifacts are durable evidence objects, where project memory is explicit, where representations are selected for the consumer, where evidence is routed before reasoning, where deterministic facts are computed deterministically, and where probabilistic reasoning is reserved for ambiguity, synthesis, judgment, and uncertain prioritization.

The governing principle is:

```text
Deterministic knowledge should be computed deterministically.

Probabilistic reasoning should be reserved for ambiguity,
synthesis, judgment, and uncertain prioritization.

When probabilistic reasoning is used,
the system should record why and learn from outcomes over time.
```

This principle sounds simple. It is not. It forces a redesign of nearly every layer of analytical software.

It asks whether a missingness rate should be calculated by a model or by code. The answer is code.

It asks whether a language model should decide whether a column exists. The answer is no.

It asks whether a language model should be given a full dataset when a compact artifact would communicate the relevant structure more efficiently. Usually no.

It asks whether an LLM should inspect every artifact in a project. Usually no.

It asks whether a project should preserve screenshots, tables, diagnostics, narratives, recommendations, and metadata as separate disposable outputs. No. They should become evidence.

It asks whether humans and LLMs should receive the same representation. Often no.

It asks whether context windows should be filled, minimized, or optimized. They should be optimized.

It asks whether prompt engineering is enough. It is not.

The rest of this section explains why.

## Why Dashboards Are Insufficient

Dashboards are excellent at operational visibility. They answer questions such as:

- what is the current value?
- is it up or down?
- which segment is largest?
- where is the anomaly?
- which KPI is red, yellow, or green?

They are less effective at preserving the reasoning that produced those answers.

A dashboard is typically a surface over data, not a memory of analytical judgment. It can show that conversion fell in a region. It usually does not preserve the sequence of evidence that led an analyst to conclude that the fall was caused by creative fatigue, distribution shift, pricing pressure, measurement error, or a seasonal effect. A dashboard may show many tiles at once, but tiles are not the same as evidence. They are views.

This distinction matters because LLMs do not need merely visible outputs. They need grounded context. A dashboard designed for human scanning may be inefficient or even misleading as AI context. It may omit diagnostics, caveats, calculation assumptions, table sidecars, model provenance, or warning states that a language model would need to produce a useful answer.

Suppose a marketing team is testing creative attributes: background color, offer framing, spokesperson type, duration, call-to-action, discount depth, and channel. A dashboard can show performance by attribute. It can show lift by segment. It can show spend, impressions, conversion, and estimated return. But if the task is to decide what creative strategy to scale next, the system must preserve more than KPI surfaces.

It needs evidence:

- which attributes were tested?
- which attributes had enough exposure?
- which effects are confounded with channel or audience?
- which comparisons are underpowered?
- which high-performing creatives are also high cost?
- which effects appear stable across time?
- which signals disappear after controlling for placement?
- which recommendations are robust, and which are speculative?

These are not merely dashboard tiles. They are analytical claims, caveats, diagnostics, and decision supports.

Dashboards are also usually optimized for current state. Analytical reasoning often depends on history: what was tried, what failed, what evidence was generated, what warnings were ignored, what model versions existed, what assumptions changed. A dashboard can be rebuilt from current data. A project memory must preserve the trail.

An AI-native analytical system needs the dashboard's visibility, but it cannot stop there. It needs an evidence layer below the dashboard and a reasoning layer above it.

What is known: dashboards are useful for human monitoring and repeated operational views.

What is unknown: how much dashboard-style interactivity should be exposed directly to LLMs, especially as multimodal models improve.

Why uncertainty exists: current models vary widely in their ability to interpret visual interfaces, screenshots, table layouts, and interactive state. A dashboard screenshot may communicate a pattern well to one model and poorly to another.

What would reduce uncertainty: controlled experiments comparing dashboard screenshots, individual artifact screenshots, structured tables, and narrative summaries across question types and model providers.

The next logical step: treat dashboard panels as potential artifacts, but route them through the same evidence, encoding, and context strategy policies as any other artifact.

## Why Notebooks Are Insufficient

Notebooks are powerful because they preserve computational process. They combine code, output, text, and iteration. They are often where real analysis happens.

But notebooks are not ideal project memory.

They are chronological rather than architectural. They preserve what happened in the order it happened, not necessarily what matters in the order a future consumer needs. They can mix temporary exploration with final evidence. They can depend on hidden state. They can be difficult to audit. They often contain outputs that are visually useful but not semantically standardized. They are excellent for an analyst in motion and uneven as long-term evidence stores.

A notebook cell that produces a SHAP importance plot may be clear to the author. To a system, it is often just an output. The system may not know:

- that the artifact is about feature importance
- that it is model-specific
- that higher mean absolute SHAP values indicate stronger average contribution
- that the top and bottom rows have different analytical meaning
- that this artifact is critical rather than supplementary
- that the plot should be rendered differently for a human report, thumbnail, or LLM evidence bundle
- that the backing table should be preserved as CSV or JSON
- that warnings should be attached

This is not a criticism of notebooks. It is a limitation of unstructured analytical state.

AI-native analytical systems need notebook-like exploratory power, but they must extract durable evidence from exploration. The long-term object cannot be merely a notebook cell. It must be an artifact with identity, metadata, provenance, quality, render targets, and possible encodings.

For data scientists, this may feel like an additional burden. It should not be. The system should turn useful outputs into artifacts automatically whenever possible. The analyst should not have to manually annotate every chart. But when the producer knows analytical intent, the system should preserve it.

What is known: notebooks are valuable for computation and exploration.

What is unknown: the best boundary between free-form exploration and structured artifact production.

Why uncertainty exists: too much structure slows exploration; too little structure loses evidence.

What would reduce uncertainty: workflows that automatically promote selected notebook outputs into standardized artifacts, then measure whether later users and LLMs can reason over them more reliably.

The next logical step: design artifact promotion paths that preserve notebook flexibility while capturing evidence when an output becomes decision-relevant.

## Why Reports Are Insufficient

Reports are good at communication. They assemble analysis into a readable sequence. They can persuade. They can explain. They can preserve a moment in time.

But reports are usually final-form documents. They are not always good source systems.

A human report may optimize for layout, pacing, and narrative clarity. It may omit intermediate diagnostics. It may summarize tables. It may choose a few key plots from many. It may be designed to prevent overload. These are virtues for a human reader. They can be liabilities for an LLM expected to answer detailed follow-up questions.

An LLM evidence bundle has different needs. It may benefit from dense screenshots, structured metadata, compact table previews, JSON sidecars, diagnostics, and explicit caveats. It may not need elegant spacing. It may need exact row counts. It may need the provenance of an artifact more than the prose around it.

This is why render target and information encoding must be separate.

A report is a render target. It is a delivery destination. It answers: where does this artifact go?

Information encoding answers: how should this artifact be represented for this consumer?

The same SHAP dependence artifact may have several encodings:

- a human report version with readable labels, a clear caption, and interpretive prose
- an LLM version with denser annotations, binned means, compact metadata, and backing table references
- a thumbnail version for fast recognition in an artifact gallery
- an executive version emphasizing direction, risk, and recommended action
- a developer version exposing provenance, feature names, model id, and diagnostics

The artifact is the same. The representation changes.

Traditional reporting tools usually blur these distinctions. AI-native analytical systems cannot.

What is known: human reports and LLM evidence bundles optimize for different consumers.

What is unknown: the exact encoding policies that maximize LLM comprehension for each artifact family.

Why uncertainty exists: model capabilities are changing quickly, and performance depends on artifact type, question type, provider, context strategy, and visual encoding.

What would reduce uncertainty: information-transfer experiments comparing encodings across plot families and table types, with manual scoring for correctness, completeness, usefulness, hallucination, and missed key points.

The next logical step: maintain separate render targets while instrumenting representation strategies.

## Artifacts As Evidence

The fundamental unit of an AI-native analytical system is not the dashboard tile, notebook cell, report section, or raw data frame. It is the artifact.

An artifact is a durable analytical object.

It may be a plot, table, metric, diagnostic, narrative, recommendation, JSON payload, model summary, screenshot, or backing data reference. What matters is not its media type. What matters is that it has identity, provenance, meaning, and a role in analysis.

Artifacts become evidence when used to support a question, claim, recommendation, or decision.

This distinction is important. Not every artifact is evidence for every question. A box plot of conversion by creative attribute is evidence for distributional differences across creative groups. It may be weak evidence for causal effect. A SHAP importance table is evidence for model contribution ranking, not necessarily for causal importance. A model assessment metric is evidence for predictive performance under a defined validation scheme, not proof of deployment reliability.

Evidence is contextual.

Treating artifacts as evidence forces the system to preserve:

- what the artifact is
- where it came from
- what it is meant to show
- what it does not show
- how complete it is
- which diagnostics or warnings attach to it
- what backing data exists
- which render targets it supports
- which information encodings are appropriate
- how it should be routed for a question

This is the difference between a chart and an evidence object.

Consider SHAP importance. In many systems it is simply a plot. In an evidence-centered system it is an artifact with at least the following implied meaning:

- artifact type: importance ranking
- analytical intent: feature contribution ranking
- model context: associated model, dataset, target, validation split
- importance definition: mean absolute contribution unless otherwise specified
- caveat: ranking is model-specific and not causal by itself
- table policy: top mean absolute SHAP is one meaningful ordering; top positive and top negative mean SHAP may be different meaningful views
- render target expectations: human report, LLM DOCX, Artifact Studio
- possible encodings: human plot, LLM-dense screenshot, table preview, JSON summary
- routing relevance: high for "what drives the model?", lower for "is calibration acceptable?"

Once this semantic layer exists, software can reason about the artifact before an LLM ever sees it.

That is the point.

The system should not ask a language model to infer everything from pixels or prose if the producer already knows the artifact's meaning. Producer knowledge should become metadata. Inference should remain a fallback, not the main architecture.

What is known: standardized artifact metadata improves routing, collector generation, quality evaluation, and future AI grounding.

What is unknown: how much producer metadata is enough before the burden outweighs the benefit.

Why uncertainty exists: different modules know different amounts. Some artifacts have obvious intent; others are exploratory or user-generated.

What would reduce uncertainty: audits comparing explicit producer semantics against inferred semantics, scored by downstream routing quality and user correction rates.

The next logical step: continue moving producers toward explicit semantic metadata where the analytical intent is obvious, while preserving inference for backward compatibility.

## Raw Data Is Usually The Wrong Unit Of AI Context

There is a tempting mistake in AI analytics: give the model the data.

Sometimes that is appropriate. Usually it is not.

Raw data is high fidelity, but it is often low information density for the task. It contains noise, redundancy, irrelevant rows, privacy-sensitive values, uncompressed distributions, and details that may not affect the decision. A language model reading raw rows is frequently being asked to rediscover what analytical software should have computed first.

If the question is, "Are there missingness risks in this dataset?", the correct first step is not to send rows to an LLM. The correct first step is to calculate missingness deterministically:

- missing count
- missing rate
- missingness by feature
- missingness by target
- missingness by segment
- missingness co-occurrence
- high-risk fields

The LLM may later synthesize the implications. But the facts should be computed by code.

If the question is, "Which creative attributes appear promising?", the system should not begin by sending every impression-level row. It should first construct evidence:

- attribute-level performance summaries
- exposure and sample size diagnostics
- box plots or distributions by attribute
- model estimates if appropriate
- marginal utility curves
- confounding warnings
- segment stability checks
- recommendations and caveats

The language model should reason over this evidence package, not over a raw dump.

This is not just about saving tokens. It is about preserving analytical meaning. Raw data is not self-explanatory. Artifacts are compressed interpretations of data produced by analytical procedures. They carry structure.

The hierarchy is:

```text
Raw Data
-> Statistical Summary
-> Visual Summary
-> Narrative Summary
-> Executive Summary
```

Each layer compresses information. The goal is not lossless compression. The goal is preserving decision-relevant information.

This is familiar to analysts. A histogram is a compression of raw values into shape. A box plot is a compression into median, spread, and outliers. A SHAP importance plot is a compression of local contribution values into global ranking. A calibration curve compresses predicted probabilities and outcomes into reliability structure. A marginal utility curve compresses response behavior into decision-relevant diminishing returns.

The question for AI-native systems is not whether compression loses information. It always does. The question is whether the lost information is irrelevant to the decision, and whether the retained information is enough.

That is a decision-theory problem, not a prompt-engineering problem.

What is known: deterministic summaries and artifacts often communicate analytical structure more efficiently than raw rows.

What is unknown: when full raw or near-raw data is worth the cost.

Why uncertainty exists: exact-value questions, audit tasks, anomaly investigations, and small-table cases may require more granular evidence.

What would reduce uncertainty: controlled comparisons of raw data, full tables, previews, visual summaries, and structured JSON across question types and artifact families.

The next logical step: default away from raw data, allow guarded full-table strategies when safe, and record when granular evidence changes answer quality.

## Collectors, Memory, And The Project As The World

If artifacts are evidence, then a project needs memory.

That memory cannot live inside individual modules. An EDA module can produce missingness summaries, distributions, and correlation artifacts. A model readiness module can produce leakage, collider, drift, class balance, and missingness diagnostics. A model assessment module can produce metrics, residuals, lift, gains, ROC, PR, and calibration evidence. A SHAP module can produce importance, dependence, interaction, and grouped contribution artifacts.

Each module sees its own outputs. The project must see across modules.

This is the role of the collector.

The Project Artifact Collector is the canonical aggregation layer. It receives artifact bundles from modules, groups them by project, run, and module, writes a reconstructable manifest, persists screenshots and table sidecars, and produces a primary project evidence document.

It is not a module report generator. It is memory.

This shift is subtle and important. Without a collector, each module thinks in terms of "generate my report." With a collector, each module thinks "produce standardized artifacts." The project owns aggregation, delivery, and memory.

That makes cross-run and cross-module reasoning possible.

For example, imagine a model project with:

- Run 001: EDA
- Run 002: Model Readiness
- Run 003: CatBoost model build
- Run 004: Model Insights
- Run 005: SHAP analysis

A human may ask, "What are the biggest deployment risks?"

The answer may require evidence from all runs:

- EDA: missingness and distribution shifts
- Readiness: leakage warnings and class imbalance
- Model build: validation scheme and feature set
- Model assessment: calibration and threshold behavior
- Model insights: residual patterns and segment errors
- SHAP: top features and nonlinear dependence

No single module owns that answer. The project does.

An AI-native analytical system therefore needs project-level memory that is structured enough for routing and reasoning. A folder of exported files is not enough. A report bundle is not enough. The collector must preserve artifact identity, provenance, quality, sidecars, diagnostics, and render target metadata.

What is known: project-level aggregation is necessary for cross-module reasoning.

What is unknown: how rich collector memory should become before it turns into a database, knowledge graph, or project operating system of its own.

Why uncertainty exists: the collector must remain simple enough to be reliable, but expressive enough to support future lineage, comparison, Story Builder, and Agentic Lab.

What would reduce uncertainty: incremental lineage use cases, run-history persistence, and retrieval experiments over collector manifests and artifact metadata.

The next logical step: keep the collector as canonical memory, add permanent run history, and avoid module-specific aggregation logic.

## Render Targets And Information Encoding

Analytical software historically treated rendering as the final step: make the chart, table, or report visible.

AI-native systems need a stronger distinction.

The analytical artifact is the identity. Information encoding is the representation. Render target is the destination.

```text
Analytical Artifact
-> Information Encoding
-> Render Target
```

This distinction prevents a common architectural mistake: assuming that because two consumers need the same artifact, they need the same representation.

Humans and LLMs consume information differently.

A human report needs readability, visual hierarchy, appropriate spacing, progressive disclosure, and narrative flow. An LLM evidence bundle may need dense screenshots, compact legends, more labels, structured table previews, JSON summaries, and explicit metadata. A thumbnail needs recognition, not full analytical detail. An executive summary needs decisions, risks, and recommendations. A developer view needs traceability, IDs, paths, diagnostics, and raw detail.

The artifact is stable. The encoding changes.

This applies directly to plot design. A box plot for human review may need readable group labels and enough whitespace to compare distributions comfortably. A box plot for LLM context might benefit from denser labels, visible sample sizes, mean markers, and compact quantile summaries if still legible. A SHAP dependence plot for a human may prioritize interactive exploration. A SHAP dependence plot for LLM context may benefit from a binned mean line, sparse-region indicators, and a concise caption explaining the feature and model.

Composite analytical views become important here. They are not decoration. They are information-density tools.

Examples:

- importance bar plus cumulative contribution line
- histogram plus density
- scatter plus smoother
- SHAP dependence plus binned mean
- box plot plus mean and sample size
- trend plus anomaly bands

The reason to combine views is not visual novelty. It is marginal information gain per unit of attention or context.

What is known: consumer-specific representation is necessary because human readability and LLM information density are different objectives.

What is unknown: the optimal encoding for each artifact family and consumer type.

Why uncertainty exists: model vision capabilities, prompt sensitivity, image interpretation, table reasoning, and context window behavior vary across providers and time.

What would reduce uncertainty: plot-family-specific information-transfer experiments comparing human, LLM, thumbnail, executive, and developer encodings.

The next logical step: implement named composite analytical views cautiously, instrument their use, and compare encoding strategies empirically.

## Context Optimization Is Not Token Minimization

It is easy to think the problem is tokens.

Tokens matter. They affect cost, latency, context limits, and sometimes output quality. But minimizing tokens is not the objective. A system that minimizes tokens can omit crucial evidence. A system that maximizes context can bury the model in redundancy. Both are wrong.

The objective is to maximize useful analytical information transfer under constraints.

Constraints include:

- token budget
- latency budget
- provider capability
- privacy
- local versus remote execution
- paid versus free providers
- decision criticality
- user preference
- evidence availability
- model uncertainty

This is an optimization problem.

Consider two modes:

Token-saving mode for a cheap or local user:

- use captions and metadata first
- avoid full tables
- include only high-relevance artifacts
- prefer local/private providers
- use screenshots only when they likely add visual information
- stop early when evidence is sufficient

Evidence explosion mode for a critical decision:

- allow more redundancy
- include more diagnostics
- include screenshots and table previews
- include negative evidence
- include warnings and caveats
- lower the threshold for deep dives
- spend more context to reduce risk

Neither mode is universally correct. The correct strategy depends on the decision.

This is familiar from marketing mix modeling and marginal utility analysis. A dollar spent on one channel has a marginal return that depends on saturation, constraints, and the alternatives. Early spend may have high marginal benefit. Later spend may show diminishing returns. At some point, the next dollar is better spent elsewhere or not spent at all.

Evidence behaves similarly.

The first SHAP importance plot may provide substantial insight into what the model uses. A second importance table with the same ranking may add little. A SHAP dependence plot for the top feature may add new information about nonlinearity. A calibration plot may change the decision about deployment. A full table of 10,000 rows may add cost without improving the answer.

The system should reason in terms of marginal benefit and marginal cost.

What is known: context selection affects cost, latency, and likely answer quality.

What is unknown: how to estimate context utility reliably before a model call.

Why uncertainty exists: usefulness depends on question type, artifact type, model capability, redundancy, and what evidence has already been selected.

What would reduce uncertainty: telemetry and manual scoring across context strategies, artifact families, question types, and providers.

The next logical step: record context strategy decisions and outcomes, but keep production routing conservative and explainable.

## Evidence Routing Before GenAI Reasoning

An AI-native analytical system should not blindly send every artifact to a language model.

It should build an evidence plan first.

The evidence plan should answer:

- what evidence is included?
- what evidence is excluded?
- what is mentioned only?
- what is summarized?
- what deserves a deep dive?
- what evidence is missing?
- what context strategy is used?
- why was each decision made?
- what cost is expected?
- what confidence or uncertainty exists?

This should happen before GenAI reasoning.

The reason is simple: selection is itself analytical work. If selection is hidden inside a prompt, the system cannot inspect it, debug it, or learn from it. If a model gives a weak answer, was the problem the model, the prompt, the missing evidence, the wrong representation, a poor routing decision, or a flawed artifact? Without an evidence plan, this is hard to know.

Evidence routing should begin with deterministic facts:

- artifact type
- module source
- analytical intent
- artifact importance
- quality score
- warnings
- diagnostics
- table row count
- screenshot availability
- sidecar availability
- render targets
- provider capabilities
- image support
- token estimates

Then it should estimate relevance, novelty, trustworthiness, expected insight gain, redundancy, cost, and decision impact.

Only after routing should GenAI synthesize.

This prevents a common anti-pattern: asking the LLM to do both evidence selection and reasoning in one opaque step. There may eventually be cases where probabilistic routing is useful, especially for semantic overlap, ambiguity, or prioritization. But that should be explicit. The system should record when probabilistic routing was used and why.

What is known: deterministic routing can eliminate many unnecessary or unsafe context decisions before GenAI.

What is unknown: when probabilistic routing improves evidence selection enough to justify its cost and opacity.

Why uncertainty exists: some relevance and novelty judgments are semantic, not purely metadata-driven.

What would reduce uncertainty: compare deterministic evidence plans against probabilistic or hybrid plans using manually scored answer quality and missed-evidence audits.

The next logical step: keep evidence routing deterministic and explainable by default, while instrumenting cases where uncertainty remains.

## Marginal Information Gain

The governing optimization principle is Marginal Information Gain.

Marginal Information Gain is the expected improvement in analytical understanding caused by adding one more evidence item to the current context.

An artifact has high marginal gain if it changes expected understanding.

It has low marginal gain if it repeats what is already known.

This depends on the question.

A SHAP dependence plot may be high value for "How does age affect the model's prediction?" and low value for "Is the model calibrated?" A calibration curve may be high value for deployment approval and low value for creative attribute exploration. A box plot may be high value for detecting segment-level distribution differences and low value for explaining exact feature contribution in a tree model.

MIG depends on:

- task relevance
- trustworthiness
- novelty
- expected insight gain
- expected decision impact
- context cost
- uncertainty
- redundancy
- provider capability
- decision criticality

No equation should be finalized too early. The concept is clearer than the measurement. We know the system should prefer high marginal gain evidence over low marginal gain evidence. We do not yet know the best general-purpose estimator.

This is normal. Many useful systems begin with an objective before they have a perfect measurement. Marketing teams optimize marginal ROI before knowing the true causal response curve. Recommender systems optimize expected utility under uncertainty. Experimental design chooses observations expected to reduce uncertainty. Model selection balances performance, complexity, interpretability, and risk.

Analytics evidence is no different.

The system should continue adding evidence while expected marginal gain exceeds a context-adjusted threshold. It should stop when evidence is sufficient, budget is exhausted, remaining artifacts are redundant, privacy constraints prevent inclusion, or provider capability is insufficient.

Decision criticality changes the threshold.

Exploration mode should stop earlier. Critical-decision mode should include more evidence, more diagnostics, more caveats, and more redundancy. "Cost is irrelevant" mode can spend more context, but even then the system should avoid confusing redundancy. Unlimited budget does not imply unlimited useful evidence.

What is known: marginal gain is the right conceptual framing for evidence selection.

What is unknown: whether MIG can be estimated deterministically, learned from outcomes, or requires hybrid methods.

Why uncertainty exists: true information gain depends on the user's task, model behavior, selected evidence, and downstream answer quality.

What would reduce uncertainty: observability logs, manual scoring, evidence ablation studies, and repeated experiments across artifact families.

The next logical step: make MIG observable as a planning concept before making it an automatic optimizer.

## Deterministic Before Probabilistic

The foundational principle deserves repetition because it is easy to violate.

Deterministic knowledge should be computed deterministically.

Probabilistic reasoning should be reserved for ambiguity, synthesis, judgment, and uncertain prioritization.

This principle is not anti-LLM. It is pro-system.

LLMs are extraordinary at synthesis, language, analogy, prioritization, and reasoning under ambiguity. They are not the best tool for counting rows, checking whether a column exists, computing a missingness rate, validating a schema, detecting whether a screenshot path exists, or calculating model metrics. Even when they can do these things, the system should not spend probabilistic intelligence on facts that software can compute exactly.

In an analytical system, deterministic layers include:

- schema inspection
- summary statistics
- missingness
- correlation
- model metrics
- artifact metadata
- table row counts
- screenshot existence
- provider availability
- token estimates
- render target policy
- quality assessment
- routing constraints

Probabilistic layers include:

- explaining tradeoffs
- synthesizing evidence
- judging ambiguous importance
- summarizing caveats
- suggesting next actions
- interpreting conflicting evidence
- estimating usefulness where deterministic metadata is insufficient

The boundary is not always perfect. For example, "which artifact is most useful for this question?" may be partly deterministic and partly judgment-based. The system can compute relevance signals, quality, type, and cost. It may still need probabilistic help when semantic meaning is ambiguous.

When probabilistic reasoning is used, the system should record:

- why deterministic rules were insufficient
- what evidence was available
- what prompt/context was used
- which provider and model were used
- what output was generated
- what latency and token cost occurred
- whether the answer was later rated useful or accurate

This is how future learning becomes possible.

What is known: deterministic facts should not be delegated to LLMs.

What is unknown: the best boundary for probabilistic routing and prioritization.

Why uncertainty exists: language models are improving, and some semantic decisions are hard to encode as rules.

What would reduce uncertainty: routing audits that compare deterministic, probabilistic, and hybrid selection quality.

The next logical step: enforce deterministic-first contracts and add observability for every probabilistic step.

## Observability And Learning

An AI-native analytical system that cannot observe itself cannot improve.

Prompt engineering often treats the model call as the unit of work: prompt in, answer out. That is too narrow. The real unit is the evidence pathway:

```text
Question
-> Evidence Strategy
-> Evidence Plan
-> Context Strategy
-> Provider Capability
-> GenAI Call
-> Response
-> Review
-> Learning Signal
```

Each step should be observable.

The system should record:

- context strategy requested
- context strategy used
- included components
- screenshot used or downgraded
- image payload count
- table preview used
- full table allowed or downgraded
- JSON summary used
- sidecar references included
- estimated tokens
- reported tokens when available
- latency
- provider
- model
- success or failure
- error reason
- response excerpt
- manual quality score placeholder
- accuracy score placeholder
- user rating placeholder
- reviewer notes

The placeholders matter. The system should not pretend it can automatically score answer quality before enough evidence exists. But it should prepare the structure for future review.

This is especially important for image-vs-data experiments. We should not assume screenshots are always better. We should not assume structured data is always better. A heatmap may communicate correlation structure efficiently as an image. A table may be better for exact values. A SHAP dependence plot may need both screenshot and caption. A metrics table may not benefit from a screenshot at all.

The frontier must be learned.

Observability also protects against silent failure. If a strategy says "screenshot_only" but the provider is text-only, the system must record that the image was not actually used. If a vision model is unavailable and the strategy downgrades to caption metadata, that should be visible. If a full table is too large and the system uses a preview instead, the downgrade should be recorded.

This turns context optimization from magic into engineering.

What is known: telemetry is required to compare strategies and debug failures.

What is unknown: which feedback signals best predict future usefulness.

Why uncertainty exists: user ratings, factual correctness, completeness, hallucination, and decision impact are related but not identical.

What would reduce uncertainty: manual scoring workflows and controlled ablation experiments that compare strategies against known analytical takeaways.

The next logical step: continue recording telemetry even before automatic learning exists.

## MBA-Friendly Controls And Technical Override

An analytical operating environment must serve multiple users.

A technical user may understand token budgets, context strategies, provider capabilities, full-table thresholds, image payloads, structured JSON, and routing levels. A business leader should not need to.

The user-facing control should be decision-oriented:

- Efficient
- Balanced
- Thorough
- Critical Decision
- Cost Is Irrelevant

These are MBA-friendly controls. They express posture, not mechanics.

Efficient mode means fast, low-cost, few artifacts, few images, no full tables, local/private-friendly defaults.

Balanced mode means enough evidence for normal business decisions without evidence explosion.

Thorough mode means broader evidence, more diagnostics, more caveats, and higher cost tolerance.

Critical Decision mode means evidence explosion is allowed because the cost of being wrong is high.

Cost Is Irrelevant mode means the system may use everything reasonable, especially in local or near-free environments, while still avoiding useless redundancy.

Under the hood, these choices map to technical configuration:

- routing profile
- marginal gain threshold
- max artifacts
- max images
- max tables
- max full tables
- max estimated tokens
- max latency
- redundancy tolerance
- deep-dive threshold
- full-table allowed
- image payload allowed
- paid provider allowed
- local only
- vision preference
- exact-value bias
- diagnostic bias
- novelty weight
- trust weight
- relevance weight
- cost weight

The business user should not be forced to manage this. The technical user should be able to inspect and override it.

This is not merely UX convenience. It is an architectural principle. High-level intent should map to centralized policy. It should not create a parallel router. Overrides should be recorded in the evidence plan and observability logs.

What is known: decision-oriented controls reduce cognitive burden while preserving technical control.

What is unknown: the best default mapping from business posture to technical configuration.

Why uncertainty exists: different organizations, model providers, privacy regimes, and decision contexts will value cost, speed, and thoroughness differently.

What would reduce uncertainty: dogfooding, user studies, and telemetry showing which strategies users choose and which produce useful answers.

The next logical step: keep strategy presets simple, expose technical detail progressively, and record overrides.

## Why This Is Not Prompt Engineering

Prompt engineering matters. Clear instructions, good structure, examples, and constraints can improve model behavior.

But the architecture described here is not merely prompt engineering.

Prompt engineering begins near the model. AI-native analytical systems begin much earlier:

- how artifacts are produced
- how tables preserve canonical data
- how screenshots are generated
- how metadata is recorded
- how quality is assessed
- how collector memory is built
- how render targets are separated
- how information encoding is selected
- how evidence is routed
- how context is optimized
- how provider capability is checked
- how GenAI calls are instrumented
- how outcomes are reviewed
- how learning might occur

A prompt cannot fix missing evidence. It cannot recover a table sidecar that was never saved. It cannot know producer intent that was never recorded. It cannot distinguish an unavailable image payload from a true screenshot strategy unless the system tells it. It cannot reliably infer whether an artifact is critical or supplementary if the system treats all outputs as equal.

Prompting is the last mile. Evidence architecture is the road.

This is why analytical software must change. The value is not in attaching a chat box to a dashboard. The value is in building a project environment where every analytical object can become evidence, where evidence can be encoded and routed, where reasoning is grounded, and where outcomes can be observed.

The future of AI in analytics is not "ask your data" in the abstract. It is "reason over the right evidence, represented in the right way, for the right consumer, under the right constraints, with the right trace."

That is a systems problem.

## Running Example: Creative Attribute Testing

Consider a company testing advertising creatives.

The raw data contains impressions, clicks, conversions, spend, channel, audience, creative id, background color, message type, call-to-action, discount, duration, placement, date, and market.

A dashboard might show conversion rate by creative. A notebook might model conversion using creative attributes. A report might recommend scaling top performers.

An AI-native analytical system would build an evidence environment.

First, deterministic artifacts:

- EDA summaries of spend, impressions, conversions, and missing attributes
- box plots of conversion rate by creative attribute
- sample size diagnostics by group
- model readiness checks for leakage or sparse groups
- model assessment metrics if a predictive model is trained
- SHAP importance for creative attributes
- SHAP dependence for high-impact attributes
- marginal utility or response curves if spend saturation matters
- recommendations and caveats

Second, collector memory:

- each artifact has id, module, run, caption, quality, diagnostics, and sidecars
- table artifacts preserve canonical data
- plot artifacts have production screenshots
- warnings are preserved

Third, evidence routing:

If the question is "What should we scale next?", the system selects evidence about performance, sample size, stability, marginal utility, and risks.

If the question is "Which creative attributes drive the model?", it selects SHAP importance and dependence, plus caveats about causality.

If the question is "Is this safe for executive recommendation?", it includes diagnostics, confounding warnings, and evidence sufficiency checks.

Fourth, context strategy:

For a local, cheap exploratory question, the system may use captions, metadata, and small table previews.

For a critical decision, it may include screenshots, diagnostics, recommendations, table previews, and redundant corroborating evidence.

This is not a dashboard. It is not a notebook. It is not a report.

It is an analytical operating environment.

## Running Example: Model Assessment

A model assessment workflow illustrates why evidence must be routed before reasoning.

Suppose a binary classifier has strong AUC. A naive AI assistant might summarize that the model performs well. But deployment risk may depend on evidence not captured by AUC:

- calibration curve
- threshold metrics
- confusion matrix
- lift and gain
- segment-level error
- drift
- class imbalance
- leakage diagnostics
- residual or error concentration
- SHAP dependence for sensitive or operationally important features

The question "Is this model ready?" is not answered by one metric.

An evidence plan should include:

- performance metrics for broad predictive quality
- calibration for probability reliability
- threshold tables for operational tradeoffs
- diagnostics for validity
- SHAP artifacts for interpretability
- readiness artifacts for data risks
- recommendations and warnings

The marginal gain of each artifact changes as evidence accumulates. If metrics and calibration already show a fatal issue, additional SHAP deep dives may be less urgent. If performance is good but calibration is unknown, calibration evidence has high marginal gain. If SHAP importance and variable importance agree, a second ranking may have low marginal gain, while SHAP dependence for the top feature may have high gain.

This is the kind of reasoning the system should support.

## Running Example: SHAP Importance And Dependence

SHAP artifacts make the representation problem concrete.

A SHAP importance plot answers a ranking question:

- which features contribute most to model output on average?

A SHAP dependence plot answers a relationship question:

- how does a feature's value relate to its contribution?

These are different analytical intents. They should not be routed interchangeably.

For an LLM, a SHAP importance table might be best represented as a policy-driven preview with top mean absolute SHAP, top positive mean SHAP, and top negative mean SHAP views. A SHAP importance plot might benefit from a screenshot if the visual ranking is easy to inspect. A SHAP dependence plot likely benefits more from a screenshot because shape, nonlinearity, sparse regions, and interaction coloring are visual patterns.

But these are hypotheses, not settled laws.

The system should test:

- caption plus metadata
- screenshot plus caption
- screenshot plus caption plus preview table
- structured JSON summary
- table preview only
- full table when safe

It should compare by question type:

- key findings
- limitations
- risks
- executive explanation
- data-scientist explanation
- next action

It should record latency, token estimates, provider, model, true image payload use, downgrade reasons, and manual quality scores.

Only then can the system learn which representation works best.

## The Efficient Frontier Of Evidence

In decision theory and optimization, an efficient frontier describes options where no alternative is better on one objective without being worse on another. Evidence selection has a similar frontier.

One evidence package may be cheap and fast but incomplete. Another may be thorough but expensive. Another may be locally private but less capable because the model is smaller. Another may use a remote vision model and perform better on screenshots but raise privacy or cost concerns.

The system should help users navigate this frontier.

The axes are not fixed, but they include:

- expected information gain
- estimated token cost
- latency
- privacy risk
- provider cost
- factual accuracy
- completeness
- hallucination risk
- decision usefulness
- user confidence

The frontier differs by decision criticality.

For exploration, the efficient point may be a small context package with high-level artifacts. For executive approval, it may include curated evidence and recommendations. For production deployment, it may include extensive diagnostics and negative evidence. For local research, token cost may matter less, while latency and model capability matter more.

This is why the system needs both MBA-friendly controls and technical override.

The business user chooses the posture. The system maps it to a policy. The technical user can inspect the policy. The observability layer records the result.

## The First Architecture Of AI-Native Analytics

The first architecture is not an agent.

It is not a chat interface.

It is not a mega-prompt.

It is an evidence system:

```text
Project
-> Modules
-> Artifacts
-> Collector
-> Quality
-> Information Encoding
-> Render Targets
-> Evidence Routing
-> Context Optimization
-> GenAI
-> Observability
-> Learning
```

This architecture begins with humility. It does not assume the model knows everything. It does not assume one representation is best. It does not assume more context is always better. It does not assume deterministic facts should be inferred probabilistically. It does not assume AI should act autonomously before the system can explain what evidence it used.

It assumes that analytical work is evidence work.

It assumes that software should preserve evidence, not just display outputs.

It assumes that AI reasoning should be grounded in structured project memory.

It assumes that uncertainty should be recorded, not hidden.

It assumes that future learning requires observability now.

These assumptions may look conservative. They are. But conservative architecture is not timid architecture. It is what allows powerful systems to become trustworthy.

The next frontier is not merely better prompts. It is better analytical memory, better evidence routing, better information encoding, better measurement of marginal gain, and better human control over probabilistic reasoning.

That is the work of AI-native analytical systems.

