# AI-Native Analytical Systems

## Designing Software That Reasons Over Evidence

Overcomplete manuscript draft v0  
Purpose: maximize captured detail before pruning

This is not a polished book. It is the first deliberately expansive manuscript source. The purpose is to preserve the full shape of the work before later passes compress, reorder, cut, and sharpen it.

The material in this draft comes from the current known Analytics Workstation corpus: the AnalyticsShinyApp repository, the AutoQuant-origin Codex thread, the AnalyticsShinyApp continuation thread, the current Codex thread, architecture documents, research documents, implementation summaries, QA work, and manuscript planning documents.

Some raw web-interface ChatGPT material is not yet captured. Where that matters, this draft treats the absence as a source gap rather than pretending the source has been recovered.

---

# Part I: The Story

## Chapter 1: The Moment Analytical Software Changed

Analytical software has always been about compression.

A dataset is too large to understand directly, so we summarize it. A summary table is too narrow to reveal shape, so we visualize it. A plot is too isolated to communicate judgment, so we write a report. A report is too static to support exploration, so we build dashboards. A dashboard is too rigid for research, so we use notebooks. A notebook is too personal and chronological for repeated operations, so we build applications.

Each generation of analytical software has been a response to a particular bottleneck in understanding.

Spreadsheets made calculation visible. Statistical languages made analysis programmable. Business intelligence tools made metrics shareable. Notebooks made computation and narrative cohabitate. Dashboards made operational state observable. Machine learning platforms made modeling repeatable. Reporting tools made analytical conclusions portable.

But the introduction of large language models changed the bottleneck again.

At first, the obvious move was to add chat. Put a chat box beside the dashboard. Let the user ask questions. Let the model summarize a report. Let the model write SQL. Let the model explain a chart. These are useful capabilities, but they are not the deeper transformation.

The deeper transformation is that language models create a second class of analytical consumer.

Before LLMs, analytical outputs were primarily consumed by humans. A chart was designed for a human eye. A report was structured for human reading. A dashboard was arranged for human scanning. A notebook was written for a human analyst, sometimes the author, sometimes a collaborator, sometimes a future reviewer.

An LLM consumes analytical material differently.

It does not need beauty in the same way. It does not need the same whitespace. It may need more metadata than a human would tolerate. It may benefit from dense annotations. It may need exact row counts and provenance. It may perform poorly if a screenshot is only referenced by path rather than attached as an image payload. It may do better with a table preview than a full table for one question, and with a screenshot plus caption for another. It may hallucinate if a chart lacks context. It may miss an important caveat if the caveat is not explicitly represented. It may confidently summarize an artifact that was never actually included in context.

This means the problem is not merely prompt engineering.

The problem is evidence architecture.

If a system wants an LLM to reason over an analytical project, the system must first decide what counts as evidence, how evidence is preserved, how evidence is represented, how evidence is routed, how much evidence is enough, and how to record the reasoning path. A prompt can only operate on the context it receives. If the context is a random bundle of reports, screenshots, raw rows, and loosely named outputs, the model is reasoning over accidental structure.

The core thesis of this book is that analytical software must evolve from dashboard and report generation into evidence-centered analytical operating environments.

An evidence-centered analytical operating environment is not a dashboard with a chatbot. It is not a notebook with autocomplete. It is not a report generator that emits a DOCX for an LLM. It is a project environment in which analytical artifacts are durable evidence objects, the project owns memory, representations are chosen for consumers, evidence is routed before reasoning, deterministic facts are computed deterministically, probabilistic reasoning is reserved for synthesis and ambiguity, and every GenAI call becomes observable enough to learn from.

This architecture emerged gradually. It did not begin with a grand plan.

It began with a practical product idea: build a local-first Shiny/Electron app around AutoPlots.

The earliest doctrine was modest and strict. The app should load datasets, create AutoPlots charts, arrange plots, preview outputs, export HTML, export PNG, and export reproducible R code. It should not redesign AutoPlots. It should not call echarts4r directly. It should not replace AutoPlots with ggplot2, plotly, or custom JavaScript chart builders. Generated plot code should use high-level AutoPlots calls. Generated layouts should use AutoPlots display helpers.

That was a sensible beginning: keep the visualization engine stable, build a product shell around it, and avoid corrupting the lower-level package with application concerns.

But the work kept revealing a larger structure.

First, the app needed a service-result contract so exports and operations did not sprawl into edge-case handling. Then it needed project state. Then save/load. Then portable bundles. Then a workflow. Then analysis modules. Then AutoQuant integration. Then artifact normalization. Then SHAP controls. Then a collector. Then render targets. Then artifact quality. Then table artifacts. Then producer semantics. Then an Artifact Studio. Then Mission Control. Then a command palette. Then a GenAI provider contract. Then information-transfer experiments. Then evidence routing. Then context optimization. Then Marginal Information Gain. Then the realization that the system being built was not simply an app. It was an analytical operating environment.

The product changed because the architecture forced the product to change.

The first principle became:

```text
Artifacts are evidence.
```

That single sentence reorganized everything.

If artifacts are evidence, they need identity. They need metadata. They need captions. They need provenance. They need diagnostics. They need recommendations. They need render targets. They need quality assessment. They need sidecars. They need to be inspectable. They need to be collected. They need to be routed. They need to be preserved across runs. They need to be comparable. They need to be explainable to humans and machines.

A chart is no longer just a chart.

A table is no longer just a table.

A report is no longer the end of the pipeline.

The project becomes the world.

The collector becomes memory.

The LLM becomes a reasoner over evidence, not a magician over raw data.

## Chapter 2: Why The Old Units Are Not Enough

The old units of analytical work are familiar: dashboard, report, notebook, model, dataset, script, slide deck. Each is valuable. None is enough.

A dashboard is a visibility surface. It helps a human see current state. It can show whether revenue is up or down, which segments are weak, which campaigns are over budget, and which KPIs are out of range. It is excellent for repeated monitoring. But it usually does not preserve analytical judgment. It shows views, not necessarily evidence.

A report is a communication surface. It helps a human read a conclusion. It can organize claims, charts, tables, and recommendations. It is excellent for stakeholder delivery. But it is often final-form. It may omit intermediate evidence, diagnostics, sidecars, provenance, and alternative views that an LLM would need for follow-up reasoning.

A notebook is an exploratory surface. It preserves code and output in a chronological form. It is excellent for data scientists. But it can be messy, stateful, personal, and uneven as project memory. It mixes scratch work with final artifacts. It may not tell the system which outputs matter.

A raw dataset is a source of truth for values, but not a source of analytical meaning. Raw data contains the material from which evidence is made. It is not usually the best thing to hand to an LLM. Rows are expensive. Raw fields are ambiguous. Privacy risk is high. Relevance is uneven. The model may be forced to rediscover deterministic facts that software should compute exactly.

This is why the artifact becomes the better unit.

An artifact is a compressed analytical object. It is not merely output; it is evidence with structure.

A missingness summary compresses raw data into a data-quality signal. A box plot compresses a distribution into medians, quartiles, spread, and outliers. A SHAP importance plot compresses local contribution values into a global ranking. A SHAP dependence plot compresses local feature effects into a visual relationship. A calibration curve compresses prediction reliability into a diagnostic. A lift chart compresses model ranking usefulness into business targeting value. A marginal utility curve compresses response saturation into a decision frontier.

These artifacts discard information. That is the point.

The objective is not lossless compression. The objective is preserving decision-relevant information while reducing unnecessary cost.

This is the fundamental difference between raw data and analytical evidence.

Raw data is high fidelity but often low immediate utility. Evidence is lower fidelity but higher semantic density.

For AI-native analytical systems, the question becomes: which representation transfers the most useful analytical information for the least unnecessary cost?

That cost is not only tokens.

It includes latency, privacy, provider capability, paid API cost, local compute, model confusion, human review burden, and the opportunity cost of excluding other evidence from a finite context window.

This reframes the entire system as an optimization problem.

## Chapter 3: Deterministic Before Probabilistic

The foundational rule is simple:

```text
Deterministic knowledge should be computed deterministically.

Probabilistic reasoning should be reserved for ambiguity,
synthesis, judgment, and uncertain prioritization.

When probabilistic reasoning is used,
the system should record why and learn from outcomes over time.
```

This is the rule that protects AI-native analytics from becoming theatrical.

There is no reason to ask a language model whether a column exists. The software can check. There is no reason to ask a model to compute a missingness rate from raw rows. Code can compute it exactly. There is no reason to ask a model whether a screenshot file exists, whether a provider is available, whether a table has 500 rows, whether a JSON sidecar was written, or whether a module returned a warning. These are facts. They belong to deterministic software.

The LLM should be used where uncertainty and synthesis matter.

It can explain what a set of diagnostics implies. It can summarize tradeoffs. It can interpret a conflict between strong AUC and poor calibration. It can suggest next analytical actions. It can translate technical caveats for an executive. It can compare evidence bundles. It can reason over ambiguous priority when two evidence candidates have similar utility.

But it should not be used as a substitute for basic computation.

This is not a conservative stance against AI. It is the only way to make AI reliable inside analytical software. Probabilistic reasoning becomes more valuable when surrounded by deterministic scaffolding. If the system computes all computable facts first, the LLM can spend its uncertainty budget on genuinely uncertain questions.

This principle eventually led to context optimization.

Context optimization is not merely prompt construction. It is the discipline of deciding what should be computed, what should be routed, what should be represented, what should be sent, and what should be recorded before an LLM is asked to reason.

In the Analytics Workstation architecture, the hierarchy becomes:

```text
Deterministic facts
-> Evidence Routing
-> Optional probabilistic routing
-> GenAI reasoning
-> Observability
-> Future learning
```

The phrase "never spend probabilistic intelligence on deterministic knowledge" became one of the core architectural principles.

It applies everywhere.

It applies to artifact quality. The system can check if a caption exists. It can check if a screenshot was generated. It can check if table previews exist. It can check if JSON exists. It can calculate completeness.

It applies to provider status. The system can check whether Ollama is running. It can list models. It can record capabilities. It can detect whether a model appears vision-capable. It can record whether image payloads were actually used.

It applies to evidence routing. The system can inspect artifact type, module, run id, quality score, analytical intent, artifact importance, table row count, warnings, diagnostics, sidecar paths, and render targets.

Only after this deterministic layer is built should the system ask a probabilistic model to synthesize.

# Part II: From Visualization Builder To Workstation

## Chapter 4: The AutoPlots Doctrine

The earliest product shell was built around a strong constraint: do not contaminate AutoPlots.

AutoPlots already had a public philosophy. Users should be able to create rich echarts visualizations through high-level R functions. They should call functions like `AutoPlots::Bar()`, `AutoPlots::Line()`, `AutoPlots::Scatter()`, `AutoPlots::Histogram()`, and `AutoPlots::VariableImportance()`. They should not need to write raw echarts4r verbs for ordinary charts.

The first Shiny app doctrine protected that boundary:

- do not redesign AutoPlots from the app
- do not change AutoPlots public APIs from the app repo
- do not introduce nested plot configuration objects that fight the package philosophy
- do not replace AutoPlots calls with ggplot2, plotly, echarts4r, or custom chart builders
- generated plot code must use high-level AutoPlots functions
- generated layout code must use AutoPlots display helpers

This mattered because product shells have a habit of reaching downward. A UI needs one special option. A report needs one special chart tweak. A screenshot needs one special render path. Before long, the app is bypassing the plotting package and building its own graphics layer. That would have made AnalyticsShinyApp fragile and incoherent.

The constraint forced discipline.

If the app needed a plot, AutoPlots should produce it. If AutoPlots lacked a capability, the capability should be considered in AutoPlots as a package-level concern, not hacked into the app. If the app needed layouts, it should use AutoPlots display helpers. If display helpers were too plot-specific, that might become future AutoPlots work.

This doctrine later became crucial during the plot sizing gallery work.

The first version of the gallery was unacceptable because it generated plots using an alternate plotting library. That invalidated the sizing QA. The purpose of the gallery was not to make visually similar plots; it was to evaluate the actual plots users receive. The fix was to ensure every plot originated from production AutoPlots functions.

Then another issue emerged: screenshots had to use the production artifact screenshot helper, not a custom HTML-to-PNG path. Again, the principle was the same. QA must test the real production pipeline. Otherwise, it measures the wrong thing.

The plot sizing work revealed a broader truth: if artifacts are evidence, then rendering paths are part of evidence integrity.

A screenshot is not just an image. It is a representation of an artifact under a particular pipeline. If the pipeline differs between QA, human reports, LLM DOCX output, and the app, then evidence may drift. A language model might be given a screenshot that no user would ever see. A DOCX might contain browser error pages rather than plots. A sizing QA might conclude labels are fine when the production renderer clips them.

This is how a simple visualization-builder doctrine became an evidence-integrity principle.

## Chapter 5: The App Extraction

The early work happened in the orbit of AutoQuant and AutoPlots. But the app needed its own home.

The project was extracted into:

```text
C:\Users\Bizon\Documents\GitHub\AnalyticsShinyApp
```

It would depend on AutoPlots externally rather than living inside AutoPlots. That separation was important. AutoPlots is the visualization engine. AnalyticsShinyApp is the product shell. AutoQuant is the analytical producer layer. The app should integrate them without collapsing their boundaries.

The extraction also forced R package discipline.

At one point, service helpers lived under nested `R/services/`. That works for a plain app if files are sourced manually, but it is wrong for a package-like R project because ordinary R package source files should live directly under `R/`. The correction established the flat `R/` convention:

```text
R/
  app_server.R
  app_ui.R
  service_result.R
  service_export.R
  service_project.R
  service_plot.R
  registry_plots.R
  registry_options.R
  project_state.R
  project_bundle.R
  utils_paths.R
  utils_messages.R
```

No nested `R/services/`, `R/registries/`, `R/project/`, or `R/utils/`.

This may sound like a small implementation detail. It was more than that. It reflected a larger pattern: the system should be boring where boring is correct. Fancy architecture does not excuse violating package conventions. A project can be ambitious and still use ordinary, reliable structure.

The app also began to adopt a service-result pattern.

Service functions should return structured results rather than throwing arbitrary errors or returning inconsistent lists. This was a response to the risk of edge-case sprawl. Once a local-first app supports uploads, plot generation, exports, project save/load, bundles, collector writes, report generation, and AI status checks, every operation can fail in different ways. Without a common result contract, the UI becomes a patchwork of special cases.

The service-result contract was the first sign that AnalyticsShinyApp would become contract-driven.

That pattern later reappeared everywhere:

- module results
- artifact bundles
- collector append results
- GenAI provider responses
- QA outputs
- diagnostics artifacts
- skipped optional analyses
- evidence plans

The architectural instinct was already present: make operations explicit, structured, inspectable, and composable.

## Chapter 6: Workflow Becomes Product Spine

The app began with pages: Data, Plots, Layout, Export.

That was natural for a visualization builder. But as AutoQuant modules entered the picture, pages were no longer enough. Analytics work is not just a set of independent screens. It has a lifecycle.

The lifecycle looked like:

```text
EDA
-> Feature Engineering
-> Model Prep
-> Model Readiness
-> CatBoost Builder
-> Model Assessment
-> Model Insights
-> SHAP Insights
-> Report / Export
```

The terminology mattered.

One major cleanup separated pre-model Model Readiness from post-model Model Assessment. The existing adapter id `autoquant_model_assessment` actually represented pre-model target analysis and readiness checks. That was architecturally wrong. It needed to become `autoquant_model_readiness`.

The distinction:

Model Readiness is pre-model:

- target analysis
- leakage detection
- collider diagnostics
- drift
- class balance
- missingness
- readiness recommendations

Model Assessment is post-model:

- RMSE
- MAE
- ROC
- PR
- lift
- gains
- calibration
- residual diagnostics
- holdout performance

This terminology cleanup was not cosmetic. A true post-model Model Assessment module would eventually exist. If the pre-model module kept the assessment name, future architecture would be permanently ambiguous.

This led to terminology QA. The system needed to prevent future regressions where `autoquant_model_assessment` became preferred again. The canonical pre-model module became `autoquant_model_readiness`. The legacy id remained only as compatibility.

This was one of the first clear examples of a principle that would become important for the book:

```text
Terminology is architecture.
```

Names carry boundaries. If a module name is wrong, future features attach to the wrong concept. If a render target is confused with an encoding, future output systems become tangled. If a context strategy is confused with an evidence strategy, users and developers reason at the wrong level.

The workflow layer became more than navigation. It became the product spine.

# Part III: Artifacts And Memory

## Chapter 7: The Artifact Model Emerges

The word "artifact" started as a convenient way to describe outputs. It became the center of the architecture.

An artifact is not simply a file. It is not just a plot or table. It is a durable analytical object that can carry:

- identity
- source module
- project id
- run id
- section
- ordering
- artifact type
- caption
- metadata
- diagnostics
- recommendations
- screenshot
- canonical table
- JSON payload
- sidecar paths
- render targets
- quality status
- analytical intent
- importance
- producer semantics

Once the system treats artifacts this way, every downstream capability becomes more coherent.

Artifact Studio can browse them. The collector can aggregate them. The quality policy can evaluate them. Table policy can preserve their canonical data. Render targets can deliver them. Information encoding can represent them differently. Evidence routing can select them. GenAI can reason over them. Observability can record their use.

The artifact model also changed how modules should behave.

Modules should not think "generate my DOCX." They should think "produce standardized artifacts." The project should decide how those artifacts are collected, rendered, routed, and delivered.

That led directly to the Project Artifact Collector.

## Chapter 8: The Project Artifact Collector

The collector was the architectural point where the product stopped being a collection of modules and became a project environment.

Before the collector, each module could produce outputs. EDA could produce a report. Model Readiness could produce diagnostics. SHAP could produce explanations. Model Insights could produce charts. But each module was still a local producer.

The collector made the project the owner of memory.

The conceptual diagram was:

```text
EDA
          \
Readiness \
            \
Assessment ---> Artifact Bundle ---> Project Artifact Collector ---> Project DOCX
            /
Insights   /
          /
SHAP
```

The collector accepts standardized artifact bundles. A bundle records:

- project id
- project name
- run id
- module id
- module label
- status
- artifacts
- warnings
- errors
- diagnostics
- metadata

The artifacts inside the bundle are standard objects. The collector does not know how EDA, SHAP, forecasting, optimization, or causal analysis compute results. That is deliberate. The collector is not a module-specific report generator. It is an aggregation layer.

The collector lifecycle:

1. A user starts or loads a project.
2. The app creates or loads the collector.
3. A module runs and returns a service result.
4. The app converts that result into an artifact bundle.
5. The collector appends the bundle with a run id.
6. The collector writes the DOCX, manifest, screenshots, and table sidecars.
7. The UI exposes collector status.

Optional modules are allowed. Skipped modules should not fail the collector. No artifacts generated is not the same as a failure. Empty sections can be expected. The failure policy distinguishes expected absence from unexpected corruption.

This distinction is important because real analytical workflows are partial. A user may run EDA and SHAP but not Model Assessment. A user may intentionally skip a module. A module may produce diagnostics but no plots. The collector must preserve truth, not force a complete checklist.

The collector also introduced duplicate append protection, manifest generation, DOCX integrity checks, screenshot validation, table sidecar persistence, and backward compatibility with existing artifact objects.

The collector's DOCX purpose is also specific. It is not the same as a human report. It is optimized as a compact project corpus for review and LLM interpretation. It favors information-dense screenshots, grounding metadata, table previews, diagnostics, recommendations, and sidecar references.

This was a key step toward the later book thesis:

```text
The collector is memory.
```

Without memory, an LLM can only reason over whatever the current prompt includes. With memory, the system can reconstruct what evidence exists, where it came from, what quality it has, and what remains missing.

## Chapter 9: Artifact Quality

Once artifacts became central, quality had to become explicit.

Different modules naturally produce different combinations of screenshots, tables, captions, narratives, diagnostics, recommendations, JSON, and metadata. If each module decides quality for itself, the system becomes inconsistent. One module treats missing screenshots as fatal. Another ignores missing captions. Another omits JSON silently. Another creates table previews without recording truncation.

The Artifact Quality Policy centralizes expectations.

Every artifact should ideally include:

- screenshot when graphical and needed for LLM DOCX
- caption
- narrative when meaningful
- diagnostics where available
- recommendations where available
- backing tables where practical
- JSON where available
- metadata

The policy is informational and graceful. Missing optional components should be recorded, not treated as collector failures. A screenshot failure should not destroy the entire collector run. It should lower completeness and create a warning. JSON unavailable should be recorded. Recommendations not supplied should be recorded.

This is the pattern:

```text
Screenshot fails
-> record failure
-> keep caption/table/metadata/narrative/diagnostics
-> collector continues
```

Artifact completeness became a 0-100 informational score. It is not a truth score. It does not mean the artifact's analytical conclusion is correct. It means the artifact has more or fewer of the components expected for robust downstream use.

This distinction later created a tension: Artifact Quality vs Trustworthiness.

Quality is about completeness and component status. Trustworthiness is broader. It may include sample size, diagnostics, warning severity, model validation, staleness, producer reliability, and whether the artifact is appropriate for the question. A complete artifact can still be untrustworthy. A sparse diagnostic warning can be highly trustworthy.

This is why the book needs both terms.

Artifact Quality belongs to artifact policy.

Trustworthiness belongs to evidence routing and Marginal Information Gain.

## Chapter 10: Table Artifacts

Tables required special treatment.

The easy path would have been to screenshot tables for LLM DOCX output. That would have been wrong.

Tables are analytical objects, not screenshots.

A table artifact preserves canonical backing data first. The screenshot of an interactive table is only one temporary visual state. It may reflect pagination, sorting, filtering, or viewport constraints. It is not the source of truth.

The Table Artifact Architecture defined the canonical table as the in-memory data frame or data.table stored in the artifact object. Human reports can continue to render interactive tables with pagination, searching, sorting, filtering, and HTML fallbacks. LLM DOCX output should include structured table interpretation:

- caption
- table summary
- row and column counts
- default sort
- alternate sorts
- preview strategy
- preview row count
- truncation status
- policy-driven preview tables
- backing CSV path
- backing JSON path
- render target metadata

The sorting policy was especially important.

The first page of an interactive table is not necessarily the best LLM representation. A SHAP importance table may need top mean absolute SHAP, top positive mean SHAP, and top negative mean SHAP. A correlation table may need highest absolute, highest positive, and highest negative correlations. A threshold table may need utility-ordered and threshold-ordered views.

The rule emerged:

When creating a table artifact, supply explicit table policy if:

- there are multiple meaningful orderings
- the table is SHAP, importance, risk, or diagnostic output
- top and bottom slices tell different stories
- the default human sort is not the best LLM sort

This is an example of a broader principle: producers should declare analytical intent when they know it. Inference remains useful for compatibility, but explicit producer semantics are higher fidelity.

Tables also reveal why raw data is not the right default AI context. A full table may sometimes be appropriate, especially if it is small or exact values matter. But large tables should usually be represented through previews, summaries, sort policies, and sidecars. The system should record when it downgrades full-table context to a preview.

Again, this is not merely token saving. It is information architecture.

# Part IV: Render Targets, Encoding, And Representation

## Chapter 11: Render Target Is Delivery

The render target architecture began with a practical problem: human-facing reports and LLM-facing collector DOCX files have different presentation needs.

Human reports should preserve interactive widgets. They should use existing R Markdown and HTML behavior. They should optimize for reviewer experience.

LLM collectors should optimize for dense evidence transfer. They may use static screenshots, captions, metadata, table previews, sidecars, diagnostics, recommendations, and JSON payloads.

The render targets include:

- `human_report`
- `html_report`
- `rmarkdown`
- `llm_docx`
- `markdown`
- `pdf`
- `json_archive`

The important clarification was:

```text
Render target is not information encoding.
```

Render target answers where the artifact goes.

Information encoding answers how the artifact is represented for a consumer.

This distinction solved a conceptual knot. Early LLM DOCX work could have led to "LLM-specific artifacts" as separate objects. Instead, the architecture says the analytical artifact remains stable. The representation may change for the consumer. Then the render target delivers it.

For plots, `ExportPNG = TRUE` means produce an additional LLM-ready static representation alongside the human artifact. It does not mean replace the human widget with a PNG.

The intended lifecycle:

```text
Production AutoPlots object
-> information encoding: human, LLM, thumbnail, executive, developer
-> render target: human_report, llm_docx, Artifact Studio, collector, archive
```

All renderings originate from the same production analytical artifact. Encoding may change. Identity and provenance remain stable.

## Chapter 12: Information Encoding

The Information Encoding Policy was one of the major conceptual breakthroughs.

The purpose of an analytical artifact is not beauty. Beauty is useful when it improves comprehension, but it is not the primary objective. The purpose is efficient transfer of analytical information.

Different consumers need different encodings.

Human encoding optimizes for:

- readability
- visual hierarchy
- spacing
- larger fonts
- interaction
- presentation quality
- progressive disclosure
- exploration

LLM encoding optimizes for:

- information density
- annotation density
- compact legends
- smaller fonts when still readable
- more labels
- more reference lines
- combined analytical views
- higher data-to-pixel ratio
- less decorative whitespace
- maximum information transfer

Thumbnail encoding optimizes for recognition.

Executive encoding optimizes for decision support.

Developer encoding optimizes for debugging and traceability.

The same artifact may therefore have multiple encodings:

```text
Human       -> interactive understanding
LLM         -> information density
Thumbnail   -> recognition
Executive   -> decision support
Developer   -> traceability
```

This policy also reframed AutoPlots V2.

Future plot APIs should support consumer-aware encoding and composite analytical views without parameter explosion. Rather than adding endless flags like `AddLine`, `AddMean`, `AddDensity`, `AddReference`, `LLMMode`, `ThumbnailMode`, and so on to every function, AutoPlots should prefer clear named composites and compact encoding policies.

Composite analytical views exist to increase information transfer:

- bar plus line
- importance plus cumulative contribution
- histogram plus density
- scatter plus smoother
- SHAP dependence plus binned mean
- box plot plus mean
- trend plus confidence bands
- trend plus anomalies

These are not decorative. They intentionally compress multiple related analytical signals into one evidence object.

This eventually led to the AutoPlots Composite View Audit and `ImportancePareto()`.

## Chapter 13: Plot Sizing And LLM DOCX Evidence

The plot sizing gallery began as infrastructure for Word artifact export. HTML reports support dynamic resizing. Word exports are static. If plots are unreadable in static form, the LLM evidence document fails.

The initial goal was not to perfect sizing heuristics. It was to generate a representative gallery of plots for manual review:

- vertical bars
- flipped bars
- 5/15/30/60 categories
- short labels
- long labels
- rotated labels
- variable importance top 10/25/50
- heatmaps
- correlation matrices
- sparse and dense scatter plots
- box plots
- line and area charts
- SHAP-style plots

The first implementation problem was that the gallery used a different plotting library. That invalidated the QA. The user correctly objected: the gallery must evaluate the actual plots users receive, not visually similar substitutes.

The next correction required using the production AutoPlots rendering path.

Then another issue appeared: the gallery used its own screenshot logic. That was also wrong. The gallery needed to reuse the existing artifact screenshot helper used by production artifact generators.

Then the production screenshot path failed with:

```text
Saving a widget with selfcontained = TRUE requires pandoc
```

But EDA artifact generation worked with `ExportPNG = TRUE`. The fix was to mirror the EDA artifact generator's screenshot path exactly, including selfcontained behavior, dependency/libdir handling, temp dirs, widget save path, webshot/chromote options, viewport size, and working directory.

This sequence matters because it illustrates evidence discipline. A QA harness that uses the wrong plot library is not evidence. A screenshot generated through a different path is not evidence. A browser error page embedded in DOCX is not evidence.

The gallery also led to practical encoding insights. Large x-axis label counts need rotation. Sometimes 45 degrees is not enough. At 30 or more labels, 90 degrees may be the best vertical-axis option, but with too many labels, coordinate flipping and increased height may be better. Label length matters. Font size matters. Human aesthetics and LLM readability are not identical.

The user made a crucial point: for the Word DOCX, as long as an LLM can read the plots, that is what matters. The R Markdown reports are for humans. The LLM DOCX is evidence compression for machine interpretation.

This was a direct precursor to Information Encoding.

# Part V: Evidence Routing And Context Optimization

## Chapter 14: Context Optimization Is Not Token Saving

The early framing could have been "reduce token usage."

That was too small.

The real objective is:

```text
Maximize analytical information transfer
while minimizing unnecessary cost.
```

Cost includes:

- input tokens
- output tokens
- latency
- provider cost
- local compute
- privacy risk
- model confusion
- user attention
- opportunity cost inside a fixed context window

The objective is not to minimize cost. A system that minimizes tokens can be under-informed. The objective is not to maximize context. A system that includes everything can be redundant, expensive, slow, and confusing. The objective is efficient analytical understanding.

Context Optimization became the parent policy:

```text
Deterministic reasoning
-> Evidence Routing
-> Optional Local GenAI
-> Optional Paid GenAI
-> Final Reasoning
-> Observability
-> Future Learning
```

Layer 1 is deterministic knowledge:

- constant variables
- near-zero variance
- missingness
- sparse groups
- correlation
- artifact quality
- screenshot availability
- render target
- producer metadata
- collector metadata
- routing profile
- provider capabilities
- context size estimation
- token estimation
- image capability
- safety limits

Layer 2 is Evidence Routing.

Layer 3 is optional probabilistic routing.

Layer 4 is probabilistic reasoning.

Layer 5 is learning and observability.

This hierarchy is the antidote to prompt-first AI architecture.

The prompt is not the system. The prompt is the final packaging of a long evidence pipeline.

## Chapter 15: Evidence Routing

Evidence Routing decides which artifacts matter for a question.

It produces an Evidence Plan. The plan records:

- question
- task type
- routing profile
- provider and model
- user constraints
- selected artifacts
- excluded artifacts
- mention-only artifacts
- sidecar-only artifacts
- deep-dive artifacts
- request-more-evidence rows
- context strategy per artifact
- routing reason
- expected utility
- estimated context cost
- confidence
- fallback strategy

Routing levels:

0. Exclude
1. Mention Only
2. Summary
3. Evidence
4. Deep Dive
5. Request More Evidence

This creates inspectability. If a GenAI answer is weak, the system can ask whether the wrong artifacts were selected, whether the right artifacts were represented poorly, whether the provider lacked capability, whether a table was downgraded, whether a screenshot was missing, whether the model failed, or whether the prompt was unclear.

Without an evidence plan, all of this disappears into a black box.

Evidence Routing uses deterministic signals:

- artifact type
- analytical intent
- source module
- artifact importance
- quality score
- diagnostics
- recommendations
- screenshot status
- table policy
- sidecars
- provider capability
- token estimate
- privacy constraints

It then estimates utility. The early utility framing:

```text
artifact_utility =
task_relevance
* trustworthiness
* novelty
* expected_insight_gain
* user_preference_weight
/ estimated_context_cost
```

This is intentionally approximate. It is not a claim that the perfect equation has been found. It is a way to produce inspectable routing decisions.

The next step is calibration, not overclaiming.

## Chapter 16: Evidence Strategy UX

Most users should not think in token budgets.

They should think in decision posture.

Evidence Strategy UX bridges business intent and technical routing configuration. The user-facing strategies are:

- Efficient
- Balanced
- Thorough
- Critical Decision
- Cost Is Irrelevant

Efficient means fastest and lowest cost. It is appropriate for quick reads, exploratory questions, low-stakes decisions, and local/private usage.

Balanced is the default. It is appropriate for normal business decisions, routine model interpretation, and project briefings.

Thorough includes broader evidence, more diagnostics, more caveats, and more supporting views.

Critical Decision allows evidence explosion because the cost of being wrong is high.

Cost Is Irrelevant uses everything reasonable, often for local/offline runs, final review, research, or deep audit.

These strategies map to technical configuration:

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
- caveat bias
- novelty weight
- trust weight
- relevance weight
- cost weight

This is not a parallel router. It is a user-friendly layer over the centralized routing system.

This matters because serious analytical software must support both executives and technical users. The executive wants a decision posture. The technical user wants inspectable configuration. The architecture must support both without splitting into two systems.

## Chapter 17: Marginal Information Gain

Marginal Information Gain became the governing theory.

Every artifact is an investment. The question is not:

```text
Should this artifact be included?
```

The better question is:

```text
What is the marginal analytical information gained by including this artifact,
given the evidence already selected?
```

An artifact contributes high marginal gain when it changes expected understanding. It contributes low marginal gain when it repeats what is already known.

A SHAP importance plot may have high gain early in a model interpretation task. A second table with the same ranking may have low gain. A SHAP dependence plot for the top feature may have high gain because it reveals nonlinear behavior. A calibration curve may have high gain for deployment readiness. A full table may have low gain if a preview answers the question.

MIG depends on:

- the question
- selected evidence
- artifact type
- artifact quality
- producer semantics
- model capabilities
- user objective
- decision criticality
- context cost
- redundancy
- uncertainty

The framework borrows from familiar ideas:

- marginal ROI
- marginal lift
- marginal utility
- diminishing returns
- efficient frontiers
- decision theory
- experimental design
- information gain

It does not yet finalize equations. That would be premature. The concept is clearer than the measurement.

The system should continue adding evidence while expected marginal gain exceeds the context-adjusted threshold. It should stop when evidence is sufficient, budget is exhausted, provider capability is reached, privacy constraints prevent safe inclusion, or remaining artifacts are too redundant.

Decision criticality changes the threshold.

Exploration stops earlier. Critical decisions justify more evidence. Cost-is-irrelevant mode can include more, but even unlimited budget does not make useless redundancy valuable.

This framework reframes LLM context selection as a real optimization problem rather than a prompt-size problem.

# Part VI: GenAI And Information Transfer

## Chapter 18: Provider-Agnostic GenAI

The GenAI service architecture began with a boundary: do not implement Agentic Lab yet.

First, build the provider contract.

The app should call:

- `genai_chat()`
- `genai_generate()`
- `genai_summarize_artifact()`
- `genai_brief_project()`

It should not call Ollama-specific functions directly.

Provider adapters handle:

- provider id
- display name
- base URL
- model
- capabilities
- availability checks
- model listing
- chat
- generate
- structured output
- timeouts
- errors
- response normalization

Capabilities are explicit:

- chat
- generate
- structured JSON
- embeddings
- vision
- streaming
- tool calling
- local
- remote
- free
- paid
- offline
- privacy preserving

The initial target providers:

- Ollama
- LM Studio
- llama.cpp server
- OpenAI-compatible local endpoints

The service must not require paid API keys. The app must start with no provider configured. If a local provider is unavailable, GenAI status should show unavailable and provide setup guidance without crashing.

The initial use cases are read-only:

- summarize selected artifact
- brief current project from metadata
- explain Mission Control alerts
- suggest next analytical action

No autonomous actions.

This is important. Agentic behavior is a later layer requiring permissions, preview-before-commit, traces, and action safety. The GenAI service is not the agent. It is the reasoning provider abstraction.

## Chapter 19: Information Transfer Experiments

Once GenAI existed, the next question was not simply "does the model answer?"

The question was: which representation communicates the most useful information for the lowest cost?

Every GenAI call should record:

- context strategy
- included components
- estimated input tokens
- reported input tokens
- estimated output tokens
- reported output tokens
- latency
- provider
- model
- output quality placeholder
- accuracy placeholder
- user rating placeholder

Included components:

- screenshot
- caption
- metadata
- diagnostics
- recommendations
- table preview
- full table
- JSON summary
- sidecar reference

Strategies:

- screenshot only
- caption plus metadata
- screenshot plus caption
- table preview only
- full table
- screenshot plus caption plus preview table
- structured JSON summary
- balanced

The core humility:

Do not assume screenshots are always better.

Do not assume structured data is always better.

Different artifact families may have different frontiers. A SHAP dependence plot may benefit from a screenshot. A metrics table may benefit from structured table context. A heatmap may need both screenshot and table preview. A box plot may need screenshot plus quantile backing data. Exact-value questions may prefer tables or JSON. Shape questions may prefer images.

The system began with Ollama smoke tests, then a reusable experiment harness, then local vision support, then image-vs-data studies, then plot-type-aware strategy research.

Vision support required special care. A screenshot path is not the same as an image payload. If a strategy is called `screenshot_only`, but the provider receives only a path string, the model has not inspected pixels. The telemetry must record:

- image payload used
- image reference only
- vision downgrade reason
- vision capability declared
- vision capability verified
- image payload bytes
- image count
- model/provider

This is how the system avoids lying to itself.

## Chapter 20: Observability Before Learning

Learning cannot happen without traces.

The system needs to record the whole path:

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

Manual scoring fields should exist before automatic scoring:

- correctness
- completeness
- usefulness
- hallucination
- missed key points
- overclaiming
- exact value accuracy
- reviewer notes

The system should not pretend it can optimize automatically before it has enough reviewed outcomes. It should prepare the structure for learning while remaining conservative.

This is one of the key differences between AI-native software and AI theater.

AI theater hides the messy part. It produces a response and hopes the user trusts it.

AI-native analytical software records what it did, why it did it, what evidence it used, what it omitted, what it downgraded, how much it cost, and how the output was later judged.

# Part VII: Workstation UX

## Chapter 21: Not A Shiny App

The product philosophy changed sharply when the goal was reframed:

The objective is not to build a nice Shiny application.

The objective is to build a premium analytics workstation that happens to use Shiny as its reactive engine.

Shiny provides:

- reactivity
- state management
- module orchestration
- server communication
- routing

Shiny does not define the UX.

The design inspiration shifted toward professional software:

- VS Code
- Cursor
- JetBrains IDEs
- Figma
- Linear
- Notion
- Power BI Desktop
- Tableau
- JupyterLab
- Observable
- Databricks
- Adobe Lightroom
- Bloomberg Terminal
- control-room dashboards
- modern AI agent workspaces

The app should feel like an analytical workspace:

```text
Project
-> Workspace
-> Analysis
-> Artifacts
-> Collector
-> Reports
-> AI
```

Not:

```text
Page
-> Run
-> Output
```

The UI should be dense but organized. It should avoid stock Shiny visual defaults where they break the workstation feel. It should use reusable primitives:

- cards
- metric tiles
- status badges
- progress indicators
- artifact preview cards
- collector status panels
- timeline components
- workflow progress components
- section headers
- callouts
- warning panels
- success panels
- empty states
- loading states
- action bars
- split panels
- resizable panels
- tabbed workspaces
- command palette
- artifact gallery
- project dashboard

This design philosophy produced the Workstation Design System.

## Chapter 22: Artifact Studio

Artifact Studio became the first unforgettable mode.

Its purpose: make artifacts the center of the experience.

The layout:

- left: filters, collections, artifact types, runs, modules, quality
- center: artifact gallery
- right: Artifact Inspector
- bottom: persistent filmstrip

Artifact cards show:

- title
- module
- run
- quality
- importance
- analytical intent
- render targets
- thumbnails
- hover actions

Plot cards use real screenshots from existing artifact/collector screenshot paths. Table cards may show compact previews. Narrative, diagnostic, and recommendation cards can use semantic icons.

The inspector evolved from metadata panel to Evidence Inspector.

The hierarchy:

1. hero preview
2. executive summary
3. quality panel
4. diagnostics
5. recommendations
6. metadata
7. backing assets

The inspector should answer:

- what am I looking at?
- why does it matter?
- how good is it?
- what should I do next?
- where did it come from?

This is not a CRUD detail panel. It is an analytical dossier.

The filmstrip gives quick navigation through recently generated artifacts, like Lightroom's filmstrip. Interaction polish made selection, hover, active state, and inspector updates feel alive rather than static.

Artifact Studio matters because it makes the abstract artifact architecture tangible. A user can click evidence. Inspect it. See its quality. See its recommendations. See its sidecars. See its collector location.

This is how architecture becomes product.

## Chapter 23: Mission Control

Mission Control is the operational awareness mode.

It answers:

- what is happening?
- what is healthy?
- what needs attention?
- what should I do next?

It is not a dashboard in the generic sense. It is a control room for the analytical project.

Its layers:

- project health
- system/workflow status
- alerts/open decisions
- run timeline
- collector readiness
- AI readiness
- QA status

Mission Control makes the project visible. It should be the first place a user can open and understand whether the project has data, artifacts, collector memory, reports, warnings, missing evidence, and AI readiness.

Mission Control depends on permanent run history more than the first implementation could fully provide. Early timeline signals may be reconstructed from current state, artifact timestamps, and collector availability. Future work should create durable run-history events.

The concept is still clear: if Artifact Studio is where users inspect evidence, Mission Control is where they understand project state.

## Chapter 24: Command Palette

The command palette brings professional software navigation into the workstation.

It supports:

- keyboard-first navigation
- searchable commands
- mode switching
- future action execution
- discoverability

The command palette matters because an analytical operating environment should not force users to remember where every capability lives. Beginners can search. Experts can move quickly.

In future Agentic Lab work, the command palette may become part of an action registry. But for now, it remains navigation and controlled commands, not autonomous execution.

# Part VIII: AutoPlots Composite Views

## Chapter 25: The Composite View Audit

The Information Encoding Policy raised a question: should AutoPlots support composite analytical views?

Examples:

- bar plus line
- box plot plus mean/reference line
- histogram plus density
- importance bar plus cumulative contribution line
- scatter plus smoother
- SHAP dependence plus binned mean
- trend plus anomaly/reference bands

An audit of AutoPlots examined:

- `R/PlotFunctions_NEW.R`
- `R/revised_echarts4r_functions.R`
- existing `e_*_full()` helpers
- raw echarts4r usage
- shared theme/style logic
- public plot APIs
- existing overlays
- dual-axis and multi-series logic
- centralized versus manual chart options

The recommendation was hybrid:

- add named public composite functions for clear analytical idioms
- build them on unexported internal composition helpers
- reuse existing prep logic and `e_*_full()` helpers
- use raw echarts4r only where necessary
- avoid broad overlay flags on existing plot APIs
- defer any general grammar layer until multiple composites prove the pattern

This recommendation preserved AutoPlots' simple API philosophy.

The first prototype was `ImportancePareto()`.

It shows:

- ranked importance bars
- cumulative contribution line
- optional cutoff/reference line
- theme support
- simple API defaults
- future-ready encoding argument

This prototype is important because it operationalizes Information Encoding. It combines ranking and concentration in one artifact. It compresses more analytical information than a plain importance bar chart, especially for LLM evidence where cumulative contribution can help determine whether the top few features explain most importance or whether importance is diffuse.

It also demonstrates the API discipline: named analytical helper, not parameter explosion.

# Part IX: The Book Itself As A System

## Chapter 26: Why The Book Needs A Compiler

By the time the architecture synthesis and MIG framework existed, the documentation itself had become a system.

There were product vision docs, research sprint docs, UX roadmap docs, artifact quality docs, collector docs, render target docs, information encoding docs, evidence routing docs, context optimization docs, GenAI service docs, context strategy research docs, AutoPlots audit docs, and manuscript drafts.

This is too much for ordinary documentation.

The knowledge needed its own architecture.

The Book Compiler Plan treats the book like another render target:

```text
Truth
-> Knowledge Base
-> Representation
-> Delivery
```

The book is not the source of truth. The canonical knowledge base is.

Other render targets:

- white papers
- conference talks
- GPT knowledge bases
- websites
- developer docs
- executive summaries
- research notebooks

The workflow:

```text
Expand
-> Cluster
-> Synthesize
-> Condense
```

This mirrors software evolution. Raw conversations are like raw implementation. Clusters are modules. Chapters are services. Terminology is the API. Source Packs are dependency manifests. Synthesis is refactoring. Pruning is optimization. Render targets are delivery artifacts.

## Chapter 27: Source Packs

Every chapter should eventually have a Source Pack.

A Source Pack includes:

- conversation references
- git commits
- architecture docs
- QA logs
- experiments
- screenshots
- example code
- terminology
- future work
- known conflicts
- open questions

This makes chapter generation mechanical. The chapter is not invented from memory; it is compiled from source.

The first priority Source Packs:

1. Product Vision
2. Glossary / Terminology
3. Artifacts
4. Project Artifact Collector
5. Render Targets + Information Encoding
6. Evidence Routing + Context Optimization
7. Marginal Information Gain
8. GenAI Service + Experiments
9. Artifact Studio + Mission Control
10. AutoPlots + Composite Views

The recent thread corpus capture plan and inventory begin this process. They record the sources:

- current Codex thread
- AutoQuant-origin Codex thread
- AnalyticsShinyApp continuation thread
- regular ChatGPT web threads still needing export
- repository docs
- code
- QA
- experiments

The goal is overcomplete preservation.

Only later do we prune.

# Part X: What Is Known, What Is Unknown

## Chapter 28: Known Principles

Some principles are now stable enough to state strongly.

Analytical software should become evidence-centered.

Artifacts are better units of AI context than raw outputs.

Project-level memory belongs outside individual modules.

Render target and information encoding are different concepts.

Tables should preserve canonical data, not just screenshots.

Deterministic facts should be computed deterministically.

Evidence should be routed before GenAI reasoning.

GenAI provider calls should be abstracted behind a service contract.

Local-first behavior should not require paid APIs.

Optional analyses should degrade into diagnostics, not fatal failures.

Producer semantics are preferable to inference when the producer knows analytical meaning.

Context optimization should maximize useful information transfer, not minimize tokens alone.

Marginal Information Gain is the right governing frame for evidence selection.

Observability is required before learning.

## Chapter 29: Active Research Hypotheses

Many important claims remain probabilistic.

We do not yet know the best LLM encoding for each plot family.

We do not yet know when screenshots outperform structured data.

We do not yet know when full tables are worth their cost.

We do not yet know how to estimate Marginal Information Gain reliably.

We do not yet know the best thresholds for Evidence Strategies.

We do not yet know how much redundancy improves confidence versus wastes context.

We do not yet know when probabilistic routing improves deterministic routing.

We do not yet know the best UI for exposing evidence plans to nontechnical users.

We do not yet know how Agentic Lab should safely move from explanation to action.

These uncertainties are not weaknesses. They are research directions.

The system has already created the infrastructure needed to study them:

- artifact metadata
- collector manifests
- table policies
- quality scores
- GenAI telemetry
- context strategy experiments
- image-vs-data studies
- plot-type-aware strategy research
- manual scoring placeholders
- evidence strategy configuration

The next stage is calibration.

## Chapter 30: The Next Logical Experiments

The next experiments should reduce architectural uncertainty.

Experiment 1: plot family encoding study.

Compare human versus LLM encodings for:

- SHAP dependence
- SHAP importance
- box plots
- heatmaps
- correlation matrices
- variable importance
- calibration curves

Question types:

- key findings
- limitations
- risks
- executive explanation
- technical explanation
- next action

Measure:

- correctness
- completeness
- usefulness
- hallucination
- missed key points
- latency
- token estimates
- image payload use

Experiment 2: table representation study.

Compare:

- caption metadata
- preview only
- multiple policy views
- full table when safe
- JSON summary
- balanced

Artifact types:

- metrics
- threshold tables
- SHAP summaries
- correlation pairs
- missingness
- diagnostics

Experiment 3: evidence routing ablation.

Compare:

- all artifacts
- top quality artifacts
- deterministic evidence plan
- random evidence with same token budget
- human-curated evidence
- optional probabilistic routing

Measure:

- answer quality
- missed evidence
- token cost
- latency
- user preference

Experiment 4: MIG calibration.

For each additional artifact included in an evidence plan, ask reviewers:

- did this artifact change understanding?
- did it add nuance?
- did it repeat known evidence?
- did it reveal a caveat?
- did it change the recommendation?
- was it worth its cost?

Experiment 5: Agentic Lab safety design.

Before allowing actions:

- require evidence grounding
- require proposed plan
- require preview-before-commit
- require action permissions
- require trace
- require rollback or artifact acceptance flow

This experiment should be design-first, not autonomy-first.

# Part XI: Closing The Overcomplete Draft

This draft is intentionally too broad.

It contains the story, principles, architecture, implementation history, product evolution, research frontier, and book compiler strategy in one place. It repeats ideas that later drafts should compress. It includes unresolved questions that later chapters may move to research appendices. It gives more detail than a published book may need.

That is the point.

The immediate goal is not elegance.

The immediate goal is not page economy.

The immediate goal is not final order.

The immediate goal is capture.

The architecture emerged through work:

- AutoPlots-powered app doctrine
- AnalyticsShinyApp extraction
- service-result contracts
- workflow spine
- Model Readiness terminology
- AutoNLS and AutoQuant integration
- SHAP guardrails
- plot sizing QA
- project artifact collector
- render targets
- artifact quality
- table artifacts
- producer semantics
- premium workstation UX
- Artifact Studio
- Mission Control
- Command Palette
- GenAI provider contract
- information-transfer experiments
- evidence routing
- context optimization
- information encoding
- AutoPlots composites
- Marginal Information Gain
- architecture synthesis
- Book Compiler Plan
- first manuscript draft

This is the raw shape of the work.

Later, it can become many things:

- a serious technical book
- a short manifesto
- a white paper on Marginal Information Gain
- a conference talk on evidence-centered analytics
- a developer guide for artifact-producing modules
- a GPT knowledge base
- a website
- a research notebook

But all of those should come from the same canonical knowledge base.

The final principle is the same as the first:

```text
Truth
-> Knowledge Base
-> Representation
-> Delivery
```

The book is a representation.

The knowledge is the source.

