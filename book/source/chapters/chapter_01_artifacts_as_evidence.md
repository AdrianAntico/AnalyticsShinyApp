# Chapter 1: Artifacts As Evidence

This is a canonical source chapter. It is intentionally too long, too complete, and too explanatory. It preserves history, reasoning, architecture, tradeoffs, implementation detail, empirical findings, counterarguments, and future work. Later drafts should prune, reorganize, and sharpen it. This version is designed to prevent loss of ideas.

## 1. The Historical Problem

Analytical software has spent decades treating dashboards, notebooks, and reports as the natural outputs of analysis. This was not foolish. It was an intelligent adaptation to the constraints of its time.

Before large language models were practical consumers of analytical context, the primary audience for analysis was human. A human analyst needed to prepare something another human could read, inspect, present, or argue with. A dashboard made sense because it turned changing data into a navigable visual surface. A report made sense because it turned analysis into a communicable document. A notebook made sense because it preserved code, output, and commentary in one place. Each form solved a real bottleneck.

The dashboard solved recurrence. If the same questions had to be asked every day, a dashboard made those questions visible without rerunning an analysis manually. The report solved communication. If a decision-maker needed a conclusion, a report arranged evidence into a linear story. The notebook solved reproducibility and exploration. If a data scientist wanted to combine code, intermediate outputs, and evolving reasoning, the notebook gave them a flexible mixed medium.

These forms became dominant because analytical work was largely organized around human consumption. Even automated systems ultimately produced human-facing outputs. A model monitoring dashboard existed so that a human could see drift. A quarterly business report existed so that executives could make decisions. A notebook existed so that a technical reader could retrace analysis. The unit of delivery was shaped by the human reader.

This history also shaped software architecture. BI tools optimized dashboards. Notebook platforms optimized code cells and output cells. Reporting systems optimized templated documents. Visualization packages optimized charts. Modeling packages optimized fitted objects, metrics, and diagnostics. Each layer assumed that the important thing was either computation or presentation. The middle layer, the durable analytical evidence object, was often implicit.

That implicitness did not matter as much when humans were the only serious consumers. Humans can infer context from layout, file names, surrounding prose, meeting memory, and organizational habit. A human can look at a plot in a PDF and remember that it came from the final model run. A human can see a table in a notebook and infer that it is a ranking. A human can understand that a section titled "Target Analysis" belongs before model training. Human interpretation fills in missing metadata.

The weakness appears when another kind of consumer arrives.

Large language models do not simply add chat to an existing analytical product. They change the optimal structure of analytical knowledge. An LLM can read, summarize, compare, and reason over evidence, but only if that evidence is represented in a way it can consume. It cannot rely on the analyst's memory. It cannot safely infer provenance from a screenshot filename. It should not be asked to compute deterministic facts that the system already knows. It should not receive a raw dataset when a curated set of analytical artifacts would communicate the landscape with less cost and less ambiguity.

The arrival of LLMs exposes a gap that dashboards, notebooks, and reports previously hid. Analytical software has often lacked a durable, structured, inspectable unit between raw data and final presentation. That missing unit is the analytical artifact.

The central claim of this chapter is simple:

Artifacts are not outputs. Artifacts are evidence.

This idea changes the architecture of analytical software. It changes how modules should produce results. It changes how projects should preserve memory. It changes how reports should be rendered. It changes how AI should receive context. It changes what quality means. It changes how future systems should learn.

To see why, we need to examine the failure modes of the older output forms.

## 2. The Failure Mode

Dashboards, notebooks, and reports are valuable, but they are poor foundations for AI-native analytical systems when treated as the primary knowledge units.

A dashboard is a live surface. Its strength is interaction. Its weakness is memory. A dashboard can show current state, but it often does not preserve why a particular view mattered, what run produced it, which diagnostics were present at the time, or which artifacts were skipped. A dashboard can disappear when the server stops, the filters change, the data refreshes, or the user navigates away. Its state may be reconstructable, but the evidence itself is not always durable.

A dashboard also has an ambiguous relationship to provenance. A chart may be visible, but what exactly is it? What module produced it? What run? What transformations? What warnings? What assumptions? What did it replace? Is it critical evidence or a supplementary visual? Was it generated for humans, for an LLM, for a thumbnail, or for a presentation? Traditional dashboards usually answer these questions only indirectly, if at all.

A report is durable, but it is usually a poor computational object. It is optimized for reading, not for structured reuse. A report's sections may contain plots, tables, and narrative, but the report itself often flattens those components into presentation. A plot inside a Word document may be visually available but not semantically addressable. A table in a PDF may be visible but not easily sortable, previewable, or reusable. A paragraph may summarize a finding but not connect back to the artifact, diagnostic, or run that produced it.

Reports also encourage premature linearization. They force analysis into a story before the system has preserved the underlying evidence as independent objects. That is acceptable when the report is the final destination. It is dangerous when the report becomes the only durable source. Once evidence is embedded inside a report, later systems must extract it back out. This is a lossy inversion. It is like trying to reconstruct a database from screenshots of a dashboard.

A notebook is flexible, but it mixes reasoning with implementation. This is both its genius and its danger. Code, outputs, comments, exploratory dead ends, and final results coexist in a temporal sequence. A notebook can preserve the analyst's path, but it often does not cleanly distinguish between a durable artifact and a transient intermediate. A notebook output cell may be important, or it may be a scratch check. A markdown paragraph may be a conclusion, or it may be a note to self. A plot may be final, or it may be one of fifteen exploratory variants.

Notebooks also rely heavily on execution state. Cells can be run out of order. Variables can persist from previous runs. Outputs can remain after code changes. A notebook is often more a trace of a human analytical session than a canonical evidence repository. For human data scientists, this can be acceptable because the notebook is a working medium. For an AI system that needs reliable context, the ambiguity is costly.

LLMs expose these weaknesses because they are powerful but context-bound. They can reason over what they are given, but the quality of that reasoning depends on the quality, structure, and relevance of the context. If we give an LLM a dashboard screenshot without provenance, it may describe what it sees but miss why it matters. If we give it a report without backing tables or metadata, it may summarize the prose but lose the analytical substrate. If we give it an entire notebook, it may waste attention on scratch work, outdated outputs, or implementation details irrelevant to the question.

The simplest response is to send raw data. But raw data is often the wrong unit of AI context. Raw data is large, low-level, and under-interpreted. It forces the model to perform tasks the analytical system should already have performed deterministically: compute summaries, detect missingness, rank features, compare metrics, inspect diagnostics, validate assumptions, and identify warnings. A language model can sometimes perform these tasks, but asking it to do so by default is an inefficient and risky use of probabilistic reasoning.

The better unit is the artifact: a compact, structured, provenance-bearing analytical object.

An artifact can be a plot, a table, a diagnostic, a recommendation, a narrative, a JSON payload, or a bundle of related components. It is not merely something rendered on screen. It is an object with identity, origin, purpose, quality, and relationships. It can be rendered differently for humans and LLMs. It can be collected into project memory. It can be routed as evidence. It can participate in experiments about information transfer. It can be inspected, compared, summarized, and learned from.

This is the architectural shift.

Traditional analytical software often moves:

Raw Data -> Computation -> Output

AI-native analytical software should move:

Raw Data -> Analytical Artifact -> Evidence -> Encoded Context -> Reasoning -> Observability -> Learning

The artifact is the hinge.

## 3. The Emergence Of The Artifact

The artifact concept in Analytics Workstation did not appear fully formed. It emerged from pressure.

The earliest product impulse was modest: build a local-first Shiny/Electron visualization builder powered by AutoPlots. The goal was not initially to invent an evidence-centered analytical operating environment. The goal was to create a safe product shell around AutoPlots without damaging AutoPlots itself.

That early doctrine mattered. AutoPlots owned chart rendering. AnalyticsShinyApp would own the application shell. The app should not modify AutoPlots public APIs. It should not call echarts4r directly for production plots. Generated code should call high-level AutoPlots functions. The application should remain local-first. This separation created a boundary between rendering primitives and product workflow.

The first application concerns were familiar: upload data, choose variables, preview plots, generate AutoPlots code, save plots, arrange them into grids or sections, export HTML or PNG, save and load project state. At this stage, artifacts were mostly "things the app made." A plot could be saved. A text block could be added. A table could be rendered. These were outputs in the ordinary sense.

Then the need for management appeared. Users needed one central place to view, preview, organize, edit metadata, hide or show, export, and remove all report artifacts: plots, text blocks, and tables. This became the Artifact Library. The requirements were practical but conceptually important. The library should show all artifacts with fields like artifact_id, artifact_type, label, source_module, section, order, visible, and status. It should have a combined artifact summary. It should allow artifact selection by ID. It should preview selected artifacts through existing rendering behavior. It should allow metadata editing. It should allow visibility to affect layouts without deleting the artifact.

These requirements quietly transformed the object. A plot was no longer merely a plot. It had identity. It had type. It had label. It had source. It had section and order. It had visibility. It had status. It could be selected, edited, hidden, exported, removed, and persisted.

That is the first step toward evidence.

The second step came from tables. A table artifact should not be merely the current page of a reactable widget. If a user exports a table, the export should contain the full underlying table data, not just the displayed page. This distinction is easy to miss, but it is fundamental. The visible rendering is one representation. The underlying table is the evidence. A table artifact must preserve the backing data.

The third step came from project state. Artifact metadata changes needed to persist through project save/load. If artifact identity and metadata disappear between sessions, then artifacts are UI outputs, not durable evidence. Persistence turns artifacts into project memory.

The fourth step came from module integration. As AutoQuant modules entered the application, EDA, Model Readiness, Model Insights, SHAP Analysis, and other workflows generated their own outputs. If each module generated its own report or DOCX, artifact ownership would fragment. The same patterns would be reimplemented. Project-level understanding would be difficult. This led to the Project Artifact Collector.

The fifth step came from LLMs. Once artifacts could be collected, the question became: what should an LLM receive? A whole dataset? A whole report? A screenshot dump? A table preview? A JSON summary? A caption plus metadata? The answer could not be guessed. It had to be treated as an information transfer problem. At that point artifacts were no longer just report components. They were candidate evidence units.

The emergence of artifacts therefore followed a practical path:

1. Create outputs.
2. Save outputs.
3. Manage outputs.
4. Give outputs identity and metadata.
5. Preserve them in project state.
6. Collect them across modules and runs.
7. Render them for different consumers.
8. Route them as evidence.
9. Study how well they transfer information to humans and LLMs.

This history matters because it prevents a common misunderstanding. The artifact model was not invented as abstract architecture for its own sake. It was extracted from repeated failures of output-centric design.

One alternative would have been to keep reports as the primary object. Modules could generate report sections, and the app could stitch them together. This would have been familiar. It would also have made reports too powerful. The report would become storage, presentation, memory, and context all at once. That would recreate the old problem: evidence buried inside delivery.

Another alternative would have been to keep module results as the primary object. Each module could return its own rich result structure, and downstream systems could learn each module's shape. This would preserve module-specific detail but make the collector and renderer module-aware. It would not scale. Every new module would require custom logic.

A third alternative would have been to rely on raw data and regenerate analyses when needed. This sounds clean but fails under practical constraints. Regeneration requires the same code, same versions, same parameters, same data, same random seeds, same external dependencies, and same execution environment. It also wastes computation and loses the historical fact that a specific artifact was seen, considered, and perhaps acted upon at a specific time.

The artifact approach sits between raw data and final reports. It preserves analytical interpretation without collapsing it into presentation. It is structured enough for software and meaningful enough for humans.

## 4. Artifacts As Evidence

To treat artifacts as evidence, an artifact needs more than a rendered payload. It needs identity, provenance, quality, intent, importance, relationships, render-target awareness, captions, diagnostics, recommendations, sidecars, and metadata. Each of these may sound like implementation detail. Together, they define the evidential nature of the artifact.

Identity is the first requirement. Evidence must be referable. If an analyst says "the SHAP dependence plot for age showed a nonlinear effect," the system should know which artifact that means. An artifact ID allows selection, persistence, routing, citation, inspection, and comparison. Without identity, an artifact is just a transient display.

Provenance is the second requirement. Evidence must have an origin. A plot should know which module produced it, which run it belongs to, which project it belongs to, what data or model it reflects, and when it was created. Provenance does not guarantee truth, but it makes truth assessable. It tells the reader where the evidence came from and what chain of computation produced it.

Quality is the third requirement. Evidence can be complete or incomplete, successful or degraded, richly supported or thin. The Artifact Quality Policy arose because different modules emitted different combinations of screenshots, tables, captions, diagnostics, recommendations, JSON, and metadata. If missing components are invisible, downstream systems overtrust artifacts. If missing optional components cause hard failures, the entire collector becomes brittle. The better rule is graceful degradation: record missing pieces, compute an informational completeness score, and continue when possible.

Quality should not be confused with trustworthiness. This distinction is important enough to preserve. A complete artifact can be analytically untrustworthy. A plot can have a screenshot, caption, metadata, backing JSON, and table sidecar while still being based on insufficient rows, leakage, poor model fit, or invalid assumptions. Artifact Quality asks whether the artifact has the expected components for its role. Trustworthiness asks whether the artifact should be believed. The first is a structural and render-target question. The second is an analytical and statistical question.

Analytical intent is the fourth requirement. An artifact should declare what kind of analytical work it is doing. Is it a ranking? A comparison? A distribution? A relationship? A diagnostic? An interaction? A time series? A prediction? This cannot always be inferred reliably from artifact type. A table might be a ranking, a confusion matrix, a threshold curve, a missingness summary, or a diagnostic. A plot might show distribution, relationship, importance, calibration, or residual structure. Producer Semantics emerged because producers often know the artifact's intent at creation time. It is wasteful to force downstream systems to infer it later.

Importance is the fifth requirement. Not all artifacts are equally valuable. Some are critical to a decision. Some are recommended context. Some are supplementary. This matters for rendering, routing, and token budgets. In a future token-aware LLM document, critical artifacts should survive pruning before supplementary ones. In an evidence plan for a high-stakes question, critical diagnostics may be routed even if they are costly.

Relationships are the sixth requirement. Evidence is rarely isolated. A SHAP importance plot relates to a SHAP importance table. A dependence plot relates to a feature. A model metric table relates to a model run. A readiness warning relates to a target analysis. A collector entry relates to a module and run. These relationships allow navigation and reasoning. They are the basis for future artifact lineage, run diffing, and evidence bundles.

Render-target awareness is the seventh requirement. An artifact can be delivered in a human report, an LLM DOCX, Artifact Studio, a collector document, a presentation, a developer trace, or a future API. The artifact remains the same analytical object, but its representation changes. This leads to the later distinction between Artifact, Information Encoding, and Render Target.

Captions are the eighth requirement. Every artifact should include a concise caption. The caption is not long narrative. It is an immediate semantic handle: "Variable Importance (Top 25)", "Target Distribution", "SHAP Dependence: Age", "Correlation Matrix", "Calibration Curve". Captions help humans scan and help LLMs understand what the artifact represents before interpreting its payload.

Diagnostics are the ninth requirement. Evidence should carry warnings, assumptions, validation status, and failure reasons where available. The SHAP interaction guard illustrates this well. Missing interaction inputs should not fail a SHAP run. They should produce structured diagnostics explaining what was skipped and why. Diagnostics preserve negative information. They tell the system not only what exists, but what could not be generated.

Recommendations are the tenth requirement. Some artifacts imply actions: investigate leakage, consider transformations, remove highly correlated features, review sparse groups, inspect calibration, gather more data. Recommendations connect evidence to next steps. They are not always available, and absence should not be fatal. But when they exist, they should be first-class artifact components.

Sidecars are the eleventh requirement. A screenshot may show a plot, but a table sidecar can preserve exact values. A JSON sidecar can preserve structured metadata. A CSV sidecar can preserve backing data. Sidecars prevent the visual representation from becoming the only source. They are especially important for LLMs because different models and tasks may benefit from different representations.

Metadata is the twelfth requirement. Metadata includes artifact ID, module, run, type, creation time, render targets, quality status, policy source, producer, collector location, file paths, and sidecar availability. Metadata makes artifacts operational. It allows sorting, filtering, routing, validation, and reconstruction.

Together these properties make an artifact evidential. A screenshot alone is not enough. A table alone is not enough. A paragraph alone is not enough. Evidence is not merely content. Evidence is content plus context plus provenance plus quality plus purpose plus relationship.

This is why artifacts are not outputs.

An output is something a system emits. Evidence is something a system can reason with.

## 5. The Collector

The Project Artifact Collector is easy to misunderstand as a DOCX generator. It is not. It may write a DOCX, but the DOCX is only one render target. The collector's deeper role is project memory.

The collector appeared because module-specific output generation was becoming architecturally wrong. EDA, Model Readiness, Model Assessment, Model Insights, SHAP Analysis, and future modules could each generate their own document. That would work superficially. Each module would be responsible for its own exports. But the project would not have one memory. A user would have a folder of module outputs, not an integrated evidence repository.

The collector changes ownership. Modules become producers. The project becomes the owner of artifact collection.

This distinction matters. A module should know how to produce artifacts from its domain. The EDA module knows how to produce distributions, missingness summaries, correlation artifacts, and descriptive diagnostics. The SHAP module knows how to produce importance, dependence, interaction diagnostics, and effect curves. Model Readiness knows how to produce leakage warnings, target analysis, class balance checks, and readiness recommendations. But no module should own the final project memory. That belongs to the project.

The artifact bundle is the submission contract. A module submits standardized artifacts with project ID, run ID, module ID, section title, artifact type, ordering, and payloads. The collector validates, appends, records, and renders. The collector does not need to know SHAP-specific logic or EDA-specific logic. It operates on bundles.

This is a major architectural simplification. Without it, every module becomes a mini reporting system. With it, modules produce evidence and the collector manages memory.

The manifest is as important as the DOCX. A collector document is useful to read or upload. A manifest is useful to reconstruct what happened. It records project ID, project name, run ID, timestamp, module, status, artifacts added, warnings, errors, collector document path, and artifact directory. It distinguishes expected non-failures from unexpected failures.

Expected non-failures include:

- module not requested
- module intentionally skipped
- no artifacts generated
- empty section

Unexpected failures include:

- artifact generation failure
- screenshot failure
- DOCX write failure
- corrupted artifact bundle
- collector append failure

This failure policy is part of the evidence architecture. A skipped module is not the same thing as a failed module. A missing optional interaction plot is not the same thing as a failed SHAP run. A screenshot failure is not the same thing as a missing caption or table sidecar. The collector must preserve these distinctions.

The collector also enables multiple project runs. A project may have Run 001 with EDA, Run 002 with SHAP, Run 003 with Model Insights, and so on. The collector should append new runs while preserving prior results. This makes the project historical. It allows the system to ask what changed, what evidence existed at the time, and which artifacts were available for later reasoning.

For future AI, this is crucial. An AI assistant that reasons over a project should not only see the latest chart. It should know the sequence of evidence. It should know that EDA was run before model readiness. It should know that model assessment is planned but not yet implemented. It should know that SHAP interactions were skipped because required columns were unavailable. It should know that an artifact has a screenshot but no JSON sidecar. It should know which run produced which table.

The collector is therefore not merely an exporter. It is a retrieval substrate. It is the durable evidence repository from which reports, LLM context, project briefings, Mission Control status, Artifact Studio browsing, and future Agentic Lab reasoning can draw.

The collector also changes the meaning of reports. A report no longer has to be the only durable record. A report becomes one render target over collected evidence. That means reports can be optimized for humans without losing machine-readable evidence. LLM DOCX can be optimized for LLMs without corrupting human report design. Future APIs can expose structured artifacts without scraping Word documents.

This is the project-memory shift:

Modules do not produce final knowledge. Modules produce artifacts.

The collector does not merely write documents. The collector preserves evidence.

The project is not a folder. The project is the world in which evidence accumulates.

## 6. Truth Vs Representation

Once artifacts become evidence, a second distinction becomes unavoidable:

Artifact -> Information Encoding -> Render Target

These concepts must remain separate.

The artifact is the analytical object. It is the thing that was produced: a SHAP importance result, a target distribution, a model metric table, a correlation matrix, a readiness diagnostic, an effect curve. It has identity, provenance, quality, intent, and metadata.

Information Encoding is how that artifact is represented for a consumer. The same artifact may be encoded differently for a human analyst, an LLM, a thumbnail, an executive, a developer, or a presentation. Human encoding prioritizes readability, spacing, visual hierarchy, interaction, and progressive disclosure. LLM encoding prioritizes information density, annotation density, compact legends, reference lines, labels, backing tables, JSON summaries, and reduced decorative whitespace. Thumbnail encoding prioritizes recognition. Executive encoding prioritizes decision support. Developer encoding prioritizes traceability and diagnostics.

Render Target is where the encoded representation is delivered. Human report, LLM DOCX, Artifact Studio preview, collector document, presentation, API, Markdown, website, and future GPT knowledge base are render targets.

The distinction matters because a render target is not a consumer by itself. A DOCX can be for humans or for LLMs. A plot image can be a thumbnail or a dense evidence graphic. An HTML report can be a polished human narrative or a developer diagnostic bundle. If render target and encoding are conflated, the system cannot adapt representation intelligently.

This distinction emerged from plot sizing work. HTML reports allowed dynamic resizing, but Word exports were static. The initial plot sizing gallery was meant to test static output. But the user correctly rejected gallery plots generated through alternate plotting libraries or custom screenshot logic. The gallery had to use production AutoPlots functions and the same screenshot helper used by artifact generators. Otherwise the QA would not evaluate what users actually receive.

Then visual failures appeared. Some plots were empty. Some lacked labels. Some used an invalid `Theme = "light"` option when AutoPlots defaulted to dark. Bar charts with many labels showed x-axis collision. Rotating labels 45 degrees helped sometimes, but not always. With large label counts, 90-degree rotation or coordinate flipping with larger height became more appropriate. Label length mattered as much as label count. Font-size reduction could help. These were not just cosmetic issues. They affected whether a human or LLM could read the evidence.

At that moment, plot sizing became information encoding. For a human report, a chart might prioritize beauty and spaciousness. For an LLM DOCX, the same chart might prioritize maximum readable information per page. It might accept smaller fonts, denser labels, combined views, more reference lines, and less decorative whitespace. The artifact is the same. The encoding differs.

This leads to composite analytical views. A composite view combines multiple analytical signals to increase information transfer: importance bars plus cumulative contribution line, histogram plus density, scatter plus smoother, boxplot plus mean, SHAP dependence plus binned mean, trend plus anomaly bands. These are not decorative overlays. They are compression devices. They increase the amount of analytical information conveyed in one representation.

The AutoPlots composite view audit was a response to this need. It asked whether composite views should be implemented as optional overlays on existing functions, new public functions, internal helpers, or a small grammar. The recommended approach was conservative: named public composite functions, shared internal helpers where useful, reuse existing theme defaults, raw echarts4r only where necessary, and avoid parameter explosion. The first prototype was `ImportancePareto()`, combining ranked importance bars with cumulative contribution line and optional cutoff.

The key lesson is that representation choices are architectural choices. They determine what evidence can be perceived, routed, and reasoned over.

Truth is not representation. But representation controls access to truth.

## 7. Relationship To AI

The artifact-as-evidence model is not an AI feature. It is the architecture that makes AI useful.

A common mistake is to add a chat box to analytical software and call it AI-native. The user asks a question, the model receives some context, and the answer appears. This can be useful, but it is not enough. The hard problem is not text generation. The hard problem is evidence selection, representation, grounding, cost, trust, and learning.

An LLM should reason over evidence rather than raw data by default because evidence is compressed analytical knowledge. A SHAP importance artifact tells the model which features mattered according to a trained model. A calibration table tells it whether predicted probabilities align with observed outcomes. A missingness artifact tells it where data quality may affect interpretation. A readiness diagnostic tells it whether modeling is appropriate. A collector manifest tells it which modules ran, which were skipped, and which artifacts exist. These are higher-level than raw rows.

This does not mean raw data is never needed. It means raw data should not be the default unit of context. Raw data is useful when the question requires recomputation, row-level inspection, anomaly investigation, or validation not already captured by artifacts. But sending raw data for every reasoning task wastes context and invites probabilistic computation of deterministic facts.

The governing principle is:

Deterministic knowledge should be computed deterministically. Probabilistic reasoning should be reserved for ambiguity, synthesis, judgment, and uncertain prioritization.

Artifacts are the bridge. They are computed deterministically or produced by analytical modules. They carry structured metadata. They can be inspected. They can be routed. The LLM receives them not as an undifferentiated dump, but as an evidence plan.

Evidence Routing decides what evidence is relevant before GenAI reasoning occurs. It uses deterministic project facts, artifact metadata, quality, producer semantics, table policies, and render target expectations. It should know that a question about model limitations may require diagnostics, calibration, residuals, missingness, and warnings. It should know that an executive briefing may prioritize recommendations, critical artifacts, and major risk signals. It should know that a SHAP interaction artifact may be unavailable and route diagnostics instead.

Context Optimization decides how to represent selected evidence under constraints. Should the model receive screenshot only, caption plus metadata, screenshot plus caption, table preview only, full table, structured JSON summary, or a balanced mixture? The answer depends on artifact type, question type, provider capability, privacy, latency, token budget, and decision criticality.

Marginal Information Gain provides the governing objective. The system should not minimize tokens blindly, nor should it maximize evidence volume blindly. It should ask: what additional value does this evidence provide relative to its cost, redundancy, uncertainty reduction, and decision impact? If an artifact adds little new information, it may not be worth sending. If a decision is critical, more evidence may be justified. If a provider lacks vision capability, screenshot strategies may downgrade. If a table is too large, full_table may downgrade to table_preview_only.

This is why the GenAI service was designed provider-agnostically. The app should call `genai_chat()`, `genai_generate()`, `genai_summarize_artifact()`, or `genai_brief_project()`, not provider-specific functions. Ollama can be a local adapter. LM Studio, llama.cpp server, and OpenAI-compatible endpoints can be adapters. Provider capabilities should be explicit: chat, generate, structured JSON, embeddings, vision, streaming, tool calling, local, remote, free, paid, offline, privacy-preserving.

The GenAI service was also intentionally read-only at first. It could summarize selected artifacts, brief the current project from metadata, explain Mission Control alerts, or suggest next analytical action. It should not execute app actions. Agentic Lab can come later, after evidence routing, context optimization, observability, and preview-before-commit exist.

This sequencing matters. AI-native analytical software should not begin with autonomy. It should begin with evidence.

## 8. Counterarguments

The artifact-as-evidence architecture is not the only possible approach. Several counterarguments deserve serious treatment.

### Why not just send raw data?

Raw data is the most complete source in one sense. It contains information that summaries may omit. If an LLM could perfectly inspect raw data at low cost, perhaps artifacts would be unnecessary.

But real systems face constraints. Raw data can be large. It may contain private or sensitive fields. It may require cleaning, transformation, aggregation, modeling, and validation before it becomes meaningful. Many user questions do not require row-level data. If the question is "What are the main model risks?", the relevant evidence may be missingness summaries, leakage diagnostics, calibration curves, residual plots, and model metrics. Sending raw data forces the LLM to reconstruct the analytical landscape from the bottom up.

Raw data also lacks interpretation. A row does not say whether a feature is important. A column does not say whether a model is calibrated. A table does not say whether a target is imbalanced. The analytical system can compute those things deterministically. The LLM should reason over the resulting evidence.

The honest answer is that raw data remains necessary for some tasks. But it should be routed deliberately, not dumped by default. Full data should be explicit, justified, and observable.

### Why not regenerate analyses when needed?

Regeneration sounds elegant. Instead of preserving artifacts, preserve data and code. When a question arises, recompute the necessary analysis.

This is sometimes appropriate. But regeneration has costs. It depends on code versions, package versions, seeds, data snapshots, parameters, optional dependencies, and compute availability. It also erases the historical status of evidence. If a user made a decision after Run 002, the artifact from Run 002 matters even if Run 005 would produce a slightly different result.

Artifacts are historical evidence. They record what existed at the time. Regeneration can supplement artifacts, but it cannot replace project memory.

### Why not use RAG over reports?

Retrieval over reports is useful but insufficient. Reports are delivery artifacts. They are optimized for a reader and often flatten underlying evidence. A RAG system over reports may retrieve prose but miss backing tables, diagnostics, skipped artifacts, quality metadata, and sidecars. It may retrieve a section without knowing which run produced it or whether an artifact was complete.

RAG over artifacts is more promising. Reports can be one indexed source, but the richer substrate is artifact metadata, captions, diagnostics, tables, screenshots, JSON, and manifests. Retrieval should operate over evidence objects, not only final prose.

### Why not ask the LLM to compute everything?

Because deterministic computation is cheaper, safer, and auditable. LLMs are powerful synthesizers, but they are not reliable replacements for statistical functions, model evaluation routines, missingness checks, or schema validation. Asking an LLM to compute deterministic facts increases cost and error risk.

The better role for GenAI is ambiguity and synthesis: explain what evidence means, compare signals, identify caveats, generate executive summaries, suggest next actions, and reason under uncertainty. It should consume deterministic artifacts, not replace deterministic analysis.

### Does artifact architecture add too much complexity?

It adds structure, but the complexity already exists. Without artifact architecture, the complexity hides in reports, module-specific exports, UI state, notebooks, filenames, and analyst memory. The artifact model makes that complexity explicit and reusable.

The risk is over-engineering. Not every small output needs maximal metadata. The system should support graceful adoption. Inference can remain a fallback. Optional components should not fail the collector. Completeness can be informational. But the architecture should point toward richer evidence over time.

### Are artifacts too static?

Artifacts can be static snapshots, but they do not have to be dead. They can have backing data, sidecars, provenance, relationships, render-target variants, and future regeneration hooks. They can be inspected, compared, routed, summarized, and linked. A static screenshot alone is limited. A structured artifact with screenshot, table, JSON, diagnostics, and metadata is not.

### Will LLMs actually benefit from screenshots?

This is uncertain. The project explicitly does not assume screenshots are always better. It also does not assume structured data is always better. That is why information transfer experiments exist. Different artifact families may favor different representations. A plot may communicate shape visually; a table may communicate exact values; a JSON summary may communicate structure; a caption may orient the model cheaply. The answer must be measured.

This uncertainty strengthens the artifact model rather than weakening it. Because artifacts preserve multiple components, the system can test representations without regenerating the analysis.

## 9. Implementation

The implementation in Analytics Workstation reflects the conceptual evolution.

The Artifact Model standardizes artifact identity, payloads, metadata, render-target state, quality state, and producer semantics. It exists because separate plot, text, and table paths would create inconsistent behavior. It allows artifacts to be selected, previewed, summarized, filtered, and collected.

The Project Artifact Collector receives standardized artifact bundles from modules. It appends artifacts to project memory, writes manifests, and renders collector documents. It exists because module-specific DOCX generation would duplicate logic and fragment evidence. The collector is intentionally module-agnostic. It should not contain SHAP-specific or EDA-specific logic. Modules produce bundles. The collector aggregates.

The Artifact Quality Policy evaluates required and optional components. It records screenshot status, table status, JSON status, captions, diagnostics, recommendations, and completeness. It exists because artifacts should degrade gracefully. A screenshot failure should not erase a caption, table, or diagnostic. Missing JSON should be recorded, not hidden. Missing required metadata should be reported by QA.

The Table Artifact Architecture makes tables canonical. It preserves backing data, preview views, sorting policy, CSV sidecars, JSON sidecars, and quality metadata. It exists because analytical tables often contain multiple meaningful views. A SHAP importance table can be sorted by mean absolute SHAP, positive mean SHAP, negative mean SHAP, or interaction strength. A model assessment table can show metrics, thresholds, lift, gain, calibration, or confusion matrix. A single displayed sort is not enough.

Producer Semantics allow modules to declare analytical intent and importance. This exists because producers know more than downstream inference. A SHAP module knows it is producing an importance ranking. A readiness module knows it is producing a diagnostic. A model assessment module knows a calibration table is a calibration artifact. The system should not rediscover this from labels.

Render Targets separate delivery contexts. Human Report and LLM DOCX are not the same. Artifact Studio preview is not the same. Collector DOCX is not the same. This exists because a single output format cannot serve all consumers equally.

Information Encoding separates representation from delivery. This exists because even within the same render target, the representation should vary by consumer. A human report may use a spacious plot. An LLM DOCX may use a denser annotated plot. A thumbnail may use a simplified visual identity. An executive rendering may emphasize recommendation and risk.

Artifact Studio makes artifacts visible as first-class objects. It includes filters, gallery cards, real thumbnails, quality metadata, an Evidence Inspector, and a filmstrip. It exists because artifacts should be explored, not buried in reports. The inspector hierarchy reflects the evidence model: preview first, summary second, quality third, recommendations and diagnostics next, metadata and backing assets later. This is progressive disclosure applied to evidence.

Mission Control uses project and collector state to surface status, progress, alerts, and next actions. It exists because users need an operational view of the project world. It should eventually become the place users open first.

The Command Palette provides keyboard-first navigation and action discovery. It exists because professional analytical software should not require hunting through pages.

The GenAI Service abstracts providers. It exists because local-first AI should support Ollama, LM Studio, llama.cpp, and OpenAI-compatible endpoints without hard-coding one provider. It also exists because provider availability should not determine app startup success.

The GenAI experiment harness records context strategies, included components, token estimates, latency, provider, model, response excerpts, and scoring placeholders. It exists because representation choices should be empirical. The system should learn whether screenshots, captions, table previews, full tables, JSON summaries, or balanced mixtures work best by artifact type and question type.

The QA system protects these contracts. There is QA for module terminology consistency, artifact quality policy, table artifact policy, project artifact collector, plot sizing gallery, GenAI service contract, experiment harness, Artifact Studio, SHAP interaction guards, and more. This matters because architecture-heavy systems regress in conceptual ways. A table can still render while bypassing the table artifact architecture. A plot can still appear while bypassing production rendering. A module can still work while using the wrong canonical ID. QA must protect the concepts, not only the functions.

The implementation story is therefore not a list of features. It is a chain of abstractions extracted from repeated friction:

- outputs needed management, so artifacts got identity
- artifacts needed persistence, so project state mattered
- modules needed aggregation, so the collector appeared
- collector documents needed quality, so artifact policy appeared
- tables needed backing data, so table artifacts appeared
- producers knew intent, so producer semantics appeared
- humans and LLMs differed, so render targets split
- representation differed from delivery, so information encoding appeared
- LLM context needed selection, so evidence routing appeared
- context choices needed optimization, so MIG appeared
- future improvement needed records, so observability appeared

This is the architecture of artifacts as evidence.

## 10. Case Studies In Artifact Thinking

The argument becomes clearer when grounded in concrete analytical cases. The following examples are not polished product demos. They are source-level cases that preserve why the artifact model matters.

### Case Study 1: SHAP Importance

A SHAP importance plot is easy to treat as an output. A model has been trained. SHAP values have been computed. The system renders a bar chart of top features. The analyst looks at it and says, "These are the important drivers."

As an artifact, the same SHAP importance result is richer.

It has identity: this exact importance artifact belongs to a project, run, module, model, and SHAP computation. It is not interchangeable with another importance plot from a later run.

It has provenance: which model produced it, which data sample was used, which features were included, which backend generated the values, whether the problem was regression or binary classification, and whether any optional components failed.

It has analytical intent: ranking. More specifically, model explanation through feature importance. This matters because the best table preview may be sorted by mean absolute SHAP, while another useful preview may show positive or negative directional summaries. A generic table preview would miss that the artifact is a ranking with alternate meaningful orderings.

It has multiple payloads: a screenshot for visual scanning, a table for exact values, a caption for orientation, metadata for routing, possibly JSON for structured consumption, and diagnostics for caveats. If interaction analysis was requested but skipped, interaction diagnostics should exist rather than a broken section.

It has render-target variants. In a human report, the SHAP importance plot may use generous spacing and a clear title. In an LLM DOCX, the plot may prioritize dense labels, top feature values, cumulative contribution, and backing table references. In Artifact Studio, the card may show a thumbnail and quality badge. In a future executive briefing, only the top drivers and implications may be shown.

The artifact model prevents the SHAP importance result from being flattened into a chart. It becomes evidence that can be inspected, routed, compared, summarized, and cited.

This is why the AutoQuant SHAP integration mattered. The effect-curve backend controls, optional AutoNLS behavior, SHAP Rmd template sections, interaction guards, table policies, and collector artifacts were not isolated improvements. They were all steps toward making model explanation evidence durable.

### Case Study 2: SHAP Interaction Failure

The SHAP interaction guard is one of the cleanest examples of evidence thinking.

The original failure mode was straightforward: a broad or default SHAP run with interaction analysis enabled could fail when required interaction columns were unavailable. The error was direct: `feature_a_col and feature_b_col must exist in data.`

In output-centric software, this kind of failure often becomes an exception. The module stops. The report fails. The user sees an error. A missing optional artifact destroys an otherwise useful run.

In evidence-centric software, the correct behavior is different. Interaction analysis is optional. If feature columns are missing, if rows are insufficient, if unique values are insufficient, if the backend is unavailable, or if no candidate pairs exist, the system should not pretend interaction evidence exists. It should emit structured diagnostics and continue.

That diagnostic artifact is itself evidence. It tells the analyst and future AI system something real: interaction analysis was requested or considered, but not generated for a specific reason. The absence is meaningful. A future LLM answering "Were interactions analyzed?" should not hallucinate an answer from missing charts. It should see an interaction diagnostics artifact with status, reason code, severity, required columns, available columns, feature names, and recommendation.

This example also clarifies graceful degradation. The system should not fabricate interaction columns. It should not silently skip and pretend nothing happened. It should not fail the full SHAP pipeline. It should preserve the limitation as evidence.

This principle generalizes. A failed screenshot is evidence. A missing JSON sidecar is evidence. An insufficient row count is evidence. A skipped module is evidence. A module not requested is evidence. Expected absence and unexpected failure must be distinct.

### Case Study 3: Model Readiness

The terminology migration from `autoquant_model_assessment` to `autoquant_model_readiness` may sound like naming cleanup. It was more than that.

The old name suggested that pre-model target analysis and suitability checks were "model assessment." But model assessment should mean post-model evaluation: RMSE, MAE, ROC, PR, lift, gains, calibration, residual diagnostics, and holdout performance. Pre-model work answers a different question: is the data suitable for modeling?

Model Readiness includes target analysis, leakage detection, collider diagnostics, drift, class balance, missingness, and recommendations. These are evidence artifacts before a model exists. Their job is not to assess model performance. Their job is to assess modeling readiness.

This distinction matters for artifacts because evidence belongs to a workflow stage. A leakage warning artifact should not be confused with a post-model diagnostic. A class balance artifact should inform model-building decisions. A readiness recommendation should feed Mission Control and future Agentic Lab suggestions before training.

The compatibility alias remained for legacy references, but the canonical module ID became `autoquant_model_readiness`. QA was added to ensure the old name did not become preferred again. That QA is ontology protection. It prevents conceptual drift from entering code.

In the book's larger argument, Model Readiness illustrates that evidence is not only final evidence. Pre-model evidence matters. It shapes whether later artifacts should be trusted. A beautiful SHAP plot from a model built on leaky data is not trustworthy. Evidence accumulates across the workflow.

### Case Study 4: Plot Sizing And LLM Readability

The plot sizing gallery began as a QA harness for static Word export. It became a lesson in representation.

At first, it would have been tempting to generate visually similar plots using a convenient plotting library. That would have been invalid. The gallery had to use production AutoPlots functions because the purpose was to evaluate the actual plots users receive. It also had to reuse the production screenshot helper because a custom screenshot path would test a different system.

Then practical failures appeared. Some plots were blank or wrong. Some used `Theme = "light"`, which was not valid for AutoPlots. Some showed axis label collisions. The user observed that rotating labels 45 degrees did not always fix the problem. For many labels, 90-degree rotation may be the best possible x-axis approach; beyond that, flipping coordinates and increasing height may be better. Label length matters. Font size matters. Plot height matters.

These observations are empirical findings about evidence representation. They are not merely UI polish. If a chart is unreadable in an LLM DOCX, it fails as evidence even if it is technically rendered. If a human can infer missing labels from interaction but the LLM sees only a static image, the encoding is wrong for that consumer.

The deeper insight was that human reports and LLM evidence documents optimize for different things. A human report should be readable and aesthetically balanced. An LLM DOCX should communicate dense analytical information without overwhelming the model. Sometimes that means different sizing, different labels, different composite views, or additional backing tables.

The plot sizing gallery therefore sits at the boundary between QA and research. It is a regression harness, but it is also an instrument for discovering how analytical visuals should be encoded.

### Case Study 5: Table Artifacts

A table is deceptively simple. It looks like rows and columns. But a table's meaning depends on ordering, truncation, context, and purpose.

Consider a variable importance table. The top rows by mean absolute importance tell one story. The top positive effects may tell another. The top negative effects may tell another. A table sorted alphabetically may be useful for lookup but poor for LLM reasoning. A human interactive table may allow sorting, filtering, and paging. An LLM DOCX receives a static preview.

This is why explicit table policy matters. If there are multiple meaningful orderings, if the table is SHAP, importance, risk, or diagnostic, if top and bottom slices tell different stories, or if the default human sort is not the best LLM sort, the producer should supply a policy.

The table artifact preserves the canonical data. The preview is a representation. The CSV sidecar preserves exact backing data. The JSON sidecar preserves structured machine-readable form. The caption explains the table. The summary or narrative identifies important patterns. The quality metadata records row count and truncation.

Without this architecture, tables become either UI widgets or screenshots. With it, tables become structured evidence.

### Case Study 6: Artifact Studio

Artifact Studio is the UX expression of the artifact thesis.

If artifacts are outputs, a page listing them is enough. If artifacts are evidence, the user should be able to browse them like a serious analytical library. Artifact Studio therefore uses a gallery, cards, thumbnails, filters, inspector, quality indicators, and a filmstrip. It was explicitly inspired by Lightroom's library model: artifacts should feel like objects worth opening.

The Evidence Inspector changed the hierarchy. A typical metadata panel might begin with artifact ID, type, file path, producer, run ID, and timestamps. That is useful information, but it is not how evidence should be encountered. The inspector should first answer: what am I looking at, why does it matter, how good is it, what should I do next, and where did it come from?

That led to the hero preview, executive summary, quality panel, recommendations, diagnostics, metadata, and backing assets. Low-level metadata moved down. Recommendations became prominent. Missing diagnostics or missing recommendations received meaningful empty states. Backing CSV, JSON, screenshots, collector paths, and manifests became a dedicated section.

The Artifact Studio demo seed then became important. A beautiful artifact browser without real artifacts is not evidence. The seeded project generated real artifacts from synthetic data, collector append behavior, screenshots, tables, narratives, diagnostics, recommendations, and metadata. This allowed visual QA against actual populated states.

The lesson is that product experience can reinforce architecture. Artifact Studio teaches the user that artifacts are first-class objects. It makes the ontology visible.

### Case Study 7: GenAI Context Strategy

Once artifacts exist, an LLM can receive them. But the form matters.

For a plot artifact, possible context strategies include caption plus metadata, screenshot only, screenshot plus caption, screenshot plus caption plus preview table, or structured JSON summary. For a table artifact, possible strategies include caption plus metadata, table preview only, full table if safe, structured JSON summary, or balanced. Each strategy has different cost, latency, and likely usefulness.

The system records telemetry: context strategy requested, context strategy used, included components, estimated input tokens, reported input tokens where available, latency, provider, model, success, error, response excerpt, and scoring placeholders. Vision strategies record whether an actual image payload was used or whether the system only passed a reference.

This instrumentation exists because the team refused to assume that screenshots are always better or that structured data is always better. That refusal is important. It makes the architecture empirical. The artifact model supplies the components. The experiment harness tests representations. Evidence routing and context optimization will eventually use the results.

In other words, artifacts make information transfer research possible.

## 11. Mathematical Intuition

The artifact thesis can also be understood through a simple decision-theory lens.

An analytical system exists because decisions are costly under uncertainty. The system gathers data, computes summaries, trains models, generates diagnostics, and communicates findings in order to reduce uncertainty enough for action. Every representation has a cost. Raw data costs storage, privacy exposure, compute, and attention. A plot costs rendering space and interpretive effort. A table costs tokens or pages. A narrative costs trust if it is not grounded. An LLM call costs latency, tokens, money, and sometimes privacy.

The question is not "How do we include everything?" The question is "What additional evidence is worth its cost for this decision?"

Artifacts are the units that make this question tractable. A raw dataset is too low-level. A final report is too aggregated. A notebook is too entangled. An artifact sits at a useful scale. It has enough analytical compression to be meaningful, but enough structure to be selected, compared, and routed.

Imagine a model risk question. The system could send the LLM the entire training dataset, the full notebook, all reports, and all screenshots. That might maximize available material, but it does not maximize usefulness. Much of the context would be redundant or irrelevant. The model would spend attention discovering facts the system already knows. Latency would increase. Token cost would increase. The chance of distraction would increase.

Now imagine sending only one metric: accuracy. That minimizes cost but may omit essential uncertainty. A high accuracy score could hide class imbalance, calibration failure, drift, leakage, or poor performance on important subgroups. The context is cheap but insufficient.

The useful point lies between these extremes. The system should include the artifacts whose marginal value exceeds their marginal cost. For the model risk question, this might include model metrics, calibration, confusion matrix, lift or gain, residual diagnostics, missingness, leakage warnings, target balance, and relevant SHAP summaries. It might exclude decorative plots, unrelated EDA, raw rows, and redundant tables. If the decision is critical, the threshold for inclusion lowers. If the user asks for a quick local/private summary, the threshold rises.

This is the intuition behind Marginal Information Gain, though the full framework belongs in a later chapter. Each candidate evidence component has expected benefit and cost. Benefit includes relevance to the question, trustworthiness, novelty, uncertainty reduction, and decision impact. Cost includes tokens, latency, page space, cognitive load, privacy exposure, and provider limitations. Redundancy reduces marginal value. Decision criticality increases acceptable cost.

Artifacts make these quantities observable enough to reason about. Because artifacts have metadata, the system can know module, run, type, intent, importance, quality, diagnostics, and sidecar availability. Because artifacts have components, the system can choose screenshot, caption, metadata, table preview, full table, JSON summary, or sidecar reference. Because artifacts are collected, the system can know what evidence already exists. Because GenAI calls are instrumented, the system can observe which strategies succeed.

This does not mean the system can compute perfect utility today. It cannot. But it can begin conservatively. It can route deterministic evidence before probabilistic reasoning. It can record context strategies. It can compare latency and token estimates. It can collect manual quality and accuracy scores. It can learn which representations tend to work for which artifact families.

The artifact model is therefore not only an engineering abstraction. It is the unit of marginal evidence economics.

Without artifacts, the system chooses between raw data, reports, and ad hoc prompt context. With artifacts, it can reason in smaller, meaningful increments. This is what makes future evidence sufficiency possible. The system can ask: given what is already known, what artifact or artifact component would most reduce uncertainty for this question? And at what cost does additional evidence stop being worth it?

This is the bridge from analytical software to AI-native analytical systems.

## 12. Open Research

Several questions remain unsettled. They should remain unsettled until experiments or usage clarify them.

The first open question is which artifact families matter most. It is likely that SHAP importance, model metrics, calibration, missingness, target distribution, residual diagnostics, and readiness warnings are high-value evidence. But the relative value depends on task. An executive question may need different artifacts than a data scientist question. A model risk question may need different artifacts than a marketing optimization question.

The second open question is optimal information encoding by consumer. Human encoding and LLM encoding are conceptually distinct, but exact policies are not yet proven. Should LLM plots use smaller fonts? More labels? More reference lines? More combined views? When does density become unreadable noise? Which visual details can vision models reliably extract? These questions require image-vs-data and plot-type-aware studies.

The third open question is whether screenshots, tables, JSON, or hybrids transfer the most useful information to LLMs. The project has instrumentation for context strategies, but quality and accuracy scoring remain manual or future work. It is plausible that screenshots are best for shape, tables for exact values, JSON for structure, and captions for cheap orientation. The frontier must be learned by artifact family and question type.

The fourth open question is how to measure information density. Possible metrics include label count, annotation count, reference lines, analytical dimensions, legend complexity, data-to-pixel ratio, and compression ratio. But a high-density artifact is not automatically useful. Density must be tied to successful information transfer.

The fifth open question is trustworthiness. Artifact completeness is easier to measure than analytical reliability. Future systems need ways to represent validation, assumptions, sample size, model quality, data quality, leakage risk, uncertainty, and diagnostic severity.

The sixth open question is evidence sufficiency. When does the system have enough evidence to answer? The answer depends on question type, decision criticality, uncertainty, redundancy, and cost. Marginal Information Gain provides the framework, but practical stopping criteria need experiments.

The seventh open question is retrieval. Should the system retrieve artifacts by metadata, embeddings, graph relationships, workflow stage, run, module, question type, or learned evidence value? The artifact model supports many possibilities, but the best retrieval architecture remains future work.

The eighth open question is multi-document strategy for LLM knowledge bases. A single DOCX may preserve project unity but become too large. Multiple DOCX files may improve organization but face upload-count limits. The best strategy depends on downstream platform constraints and information transfer behavior.

The ninth open question is learning. Observability can record context strategies, latency, token estimates, responses, errors, manual scores, and user ratings. But how should the system learn from that? Conservative deterministic rules should come first. Learned routing should arrive only after enough telemetry exists.

The tenth open question is autonomy. Agentic Lab is intentionally future work. Before AI can act, it must be grounded in evidence, explain its plan, preview changes, and respect deterministic project state. The artifact model is a prerequisite for safe autonomy.

These open questions do not weaken the artifact thesis. They define the research program that follows from it.

## Closing Argument

The claim that artifacts are evidence may sound like a naming preference. It is not.

If artifacts are outputs, then the system's job is to display them, export them, and perhaps arrange them nicely. If artifacts are evidence, then the system's job is to preserve their identity, provenance, quality, intent, relationships, renderings, diagnostics, recommendations, and role in reasoning.

If artifacts are outputs, then reports are final products. If artifacts are evidence, then reports are render targets over evidence.

If artifacts are outputs, then dashboards are surfaces. If artifacts are evidence, then dashboards are temporary views into a project memory.

If artifacts are outputs, then LLMs receive whatever can be pasted into context. If artifacts are evidence, then LLMs receive selected, encoded, observable evidence plans.

If artifacts are outputs, then missing screenshots or skipped interaction plots are annoyances. If artifacts are evidence, then missing components are diagnostic facts.

If artifacts are outputs, then table previews are UI details. If artifacts are evidence, then table policies preserve analytical meaning.

If artifacts are outputs, then producer metadata is optional decoration. If artifacts are evidence, then producer semantics are the highest-fidelity statement of analytical intent.

This is why the artifact is the fundamental analytical unit of AI-native analytical systems.

Raw data remains essential. Models remain essential. Visualizations remain essential. Reports remain essential. But none of them alone provides the right unit for project memory and AI reasoning. The artifact sits at the necessary middle layer: derived from computation, richer than raw output, more structured than a report, more durable than a dashboard, more semantically stable than a notebook cell, and more useful to AI than an undifferentiated dataset.

Artifacts are how analysis becomes evidence.

Evidence is how software becomes reason-able.
