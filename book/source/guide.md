# The Analytics Workstation Guide

Analytics Workstation has reached the point where its architecture is too rich to assume users will infer it from the interface.

This is a healthy problem. Simple tools can expose features and let users discover meaning. Analytical operating environments cannot. They contain modes, workflows, evidence, collectors, reports, routing policies, quality signals, execution postures, GenAI providers, and unfinished knowledge. Even experienced users can become disoriented if the system presents all of that as a collection of pages.

The answer is not merely better tooltips. It is also not a chat bot.

The system needs a Guide.

The Guide is the human-facing mentor layer of Analytics Workstation. It explains where the user is, what has been accomplished, what is known, what remains unknown, why the system recommends a next step, and how the user should think about the workstation itself.

The Guide is not the Agentic Lab. It does not execute actions. It does not become a free-floating assistant. It is the embodiment of the product philosophy for humans.

## Why A Guide Is Necessary

Most analytical software assumes that the user already understands the product's ontology. A dashboard assumes the user knows which metric matters. A notebook assumes the user knows which cell should run next. A BI tool assumes the user knows which chart to build. A modeling platform assumes the user knows what stage the project is in.

Analytics Workstation cannot make that assumption.

The workstation is not organized around a single output. It is organized around evidence-centered analytical work. It contains Mission Control, Artifact Studio, Project Workspace, Data Workspace, Analysis Modules, Command Palette, Delivery surfaces, Context Optimization, Evidence Routing, Knowledge State, Evidence Strategies, Execution Modes, GenAI providers, and async jobs. Each of these concepts is useful. Together, they can overwhelm.

The Guide exists to translate architecture into situated guidance.

It should help a first-time MBA user and an experienced data scientist in different ways. The MBA user may need to know why Model Readiness comes before modeling. The data scientist may need to know why an artifact is not being routed into a GenAI context package. Both users need the system to help them think, not merely expose controls.

## The Guide Is Not Chat

The distinction matters.

A generic chat box starts from the user's question and tries to answer it. A Guide starts from the user's question, the current project, the architecture, the evidence base, and the workflow state. It answers inside the system.

If the user asks, "What should I do next?", a generic chat box may produce a plausible list. The Guide should inspect project state. Has data been loaded? Has EDA run? Are there artifacts? Is the collector populated? Is Model Readiness missing? Are there warnings? Is there a current Evidence Strategy? Is the user in Manual or Guided mode? Is GenAI available? Are there running async jobs?

The answer should be grounded:

```text
You have loaded data and generated EDA artifacts, but no Model Readiness
artifacts exist yet. The next recommended step is Model Readiness because
it checks target suitability, leakage, missingness, and readiness blockers
before model building. Expected cost is low. Confidence is high. Alternative:
inspect EDA artifacts in Artifact Studio first.
```

This is not merely conversational. It is contextual analytical guidance.

## A Senior Analytical Mentor

The intended personality is a senior analytical mentor.

The Guide teaches without condescending. It recommends without pretending to be certain. It explains tradeoffs. It makes missing evidence visible. It helps users understand why a recommendation is not ready. It connects artifacts to decisions.

The Guide should be capable of saying:

```text
You cannot make a high-confidence recommendation yet because the evidence
base only contains EDA. EDA tells us what the data look like. It does not
yet tell us whether the target is safe to model, whether the model performs
well, or why predictions behave the way they do.
```

That kind of answer changes the user's relationship to the software. The user is no longer clicking through modules. The user is moving through an investigation.

## The Guide And The Ontology

The Guide should embody the ontology rather than describe it all at once.

It does not need to tell users, "Analytics Workstation has an Artifact Model, Render Targets, Information Encoding, Evidence Routing, Context Optimization, Knowledge State, Investigation Planning, Execution Modes, and Observability." That is too much.

Instead, it should introduce concepts when they become useful.

When the user creates a plot:

```text
This plot is now an artifact. Artifacts are evidence objects that can be inspected,
collected, routed into reports, or used later for AI-assisted reasoning.
```

When the collector is written:

```text
The Collector is project memory. It preserves artifacts and metadata so future
reports and explanations can reason over the same evidence.
```

When evidence is missing:

```text
The project has a knowledge gap. We do not yet have model explanation evidence,
so SHAP is recommended if a model or SHAP-ready data are available.
```

When the user changes Evidence Strategy:

```text
Balanced gathers enough evidence for routine decisions. Critical Decision gathers
more redundant and diagnostic evidence because the cost of missing nuance is higher.
```

The architecture is taught through use.

## First-Run Orientation

The first-run Guide should not begin with a tour of features.

It should begin with intent:

```text
What decision are you trying to make?
```

This question reframes the product. The workstation is not asking which page the user wants. It is asking what analytical situation the user is in.

Useful initial paths include:

- I have data.
- I have a model.
- I have a business question.
- I have an existing project.
- I want to explore.

Each path should map to a different orientation.

If the user has data, the Guide should recommend loading data, running EDA, and then running Model Readiness. If the user has a model, the Guide should orient toward Model Assessment, Model Insights, and SHAP. If the user has a business question, the Guide should introduce Investigation Planning. If the user has an existing project, the Guide should open Mission Control. If the user wants to explore, the Guide should route toward Data Workspace, EDA, and Artifact Studio.

The point is not to hide complexity. The point is to choose the first useful door.

## The Guide And Mission Control

Mission Control shows project state. The Guide explains it.

Mission Control may show that there are no artifacts, collector evidence is missing, and AI readiness is incomplete. The Guide should translate that:

```text
This project is not evidence-ready yet. No artifacts have been generated,
so there is nothing for the Collector, reports, or GenAI context routing to use.
Start with EDA if you have data, or load an existing project if evidence already exists.
```

When Mission Control shows warnings, the Guide should explain why the warnings matter and what to inspect next.

When Mission Control shows a healthy state, the Guide should not simply say "Everything is good." It should say what is now possible:

```text
The project has evidence, the collector is ready, and artifact quality is acceptable.
You can now inspect artifacts, generate a report, or ask for a project brief.
```

## The Guide And Artifact Studio

Artifact Studio is where evidence becomes tangible.

The Guide should help users interpret evidence without taking over the Evidence Inspector. The inspector is the dossier. The Guide is the mentor.

If the selected artifact is a SHAP importance plot, the Guide might explain:

```text
This artifact ranks features by average contribution magnitude. It is useful
for identifying which features deserve deeper inspection, but it does not tell
you whether the effect is positive, negative, linear, nonlinear, stable, or causal.
The next useful evidence is SHAP dependence for the top features.
```

If the selected artifact is a table:

```text
This table is backing evidence. The preview is optimized for quick interpretation,
but the full CSV/JSON sidecars preserve the analytical detail for reports and
future machine use.
```

The Guide should help users move from artifact to implication.

## The Guide And Knowledge State

Knowledge State is one of the most important concepts in the system, but most users should not encounter it as jargon first.

The Guide should translate it as:

```text
What we know, what we believe, what we are assuming, and what remains unknown.
```

A project with only EDA has a different Knowledge State than a project with EDA, readiness diagnostics, model assessment, SHAP importance, dependence plots, and recommendations.

The Guide should summarize that state:

```text
We know the target distribution, missingness profile, and basic feature structure.
We do not yet know whether the model is reliable or what drives predictions.
Decision readiness is preliminary.
```

This is how the user learns that analysis is not a pile of outputs. It is uncertainty reduction.

## The Guide And Investigation Planning

Business users ask questions. Analysts conduct investigations.

The Guide is the natural bridge.

If a user asks, "Which creative attributes should we test?", the Guide should not jump immediately to SHAP or charts. It should form an investigation:

Known:

- existing artifacts
- available data
- prior findings
- current model state

Unknown:

- which attributes matter
- whether importance is stable
- whether effects are nonlinear
- whether segments behave differently
- whether interactions matter

Required evidence:

- variable importance
- dependence or effect curves
- interaction diagnostics
- segment summaries
- time stability if temporal data exist

The Guide does not need to implement the full investigation engine immediately. But its architecture should point in that direction.

## The Guide And Evidence Routing

Evidence Routing is difficult for users to see because it is an internal selection process.

The Guide should make it explainable.

If an artifact is routed:

```text
This artifact is included because it is relevant to model explanation, has high
artifact quality, and directly supports the question about feature importance.
```

If an artifact is not routed:

```text
This artifact was not included because it is redundant with a higher-quality
summary artifact and does not add enough marginal information for the current
context budget.
```

This is where the Guide protects trust. Users do not need every internal score, but they do need to know the system is not behaving magically.

## The Guide And Execution Modes

The Guide should change posture based on Execution Mode.

In Manual mode, it teaches:

```text
Here are the reasonable next steps. You choose which one to run.
```

In Guided mode, it recommends:

```text
The next recommended step is Model Readiness. Run it now?
```

In Assisted mode, it summarizes and gates:

```text
I completed routine checks and generated the evidence plan. Approval is needed
before using a paid provider or promoting the synthesis to Knowledge State.
```

In Autonomous mode, it audits:

```text
The investigation completed under the approved policy. Here is the evidence used,
the evidence excluded, the caveats, and the decision-readiness level.
```

In Research / Step-by-Step mode, it explains everything:

```text
The recommendation came from workflow registry state, missing readiness artifacts,
collector manifest gaps, and the current Balanced evidence strategy.
```

This is how the same Guide can serve different users without becoming inconsistent.

## GenAI Is Optional

The Guide must work without GenAI.

This is not a philosophical nicety. It is an architectural requirement. If no provider exists, if Ollama is not running, if a paid provider is unavailable, or if privacy constraints prohibit a call, the Guide should still orient the user using deterministic state.

Without GenAI, the Guide can still explain:

- what a page does
- what a module is for
- what artifacts exist
- what evidence is missing
- which workflow stages are incomplete
- what Evidence Strategy means
- what Execution Mode means
- why a deterministic next step is recommended

With GenAI, the Guide becomes more fluid. It can synthesize artifact captions, diagnostics, recommendations, and collector state into natural language. But the Guide's personality and purpose do not change.

GenAI enhances the Guide. It does not define the Guide.

## UI Shape

The Guide should probably not live in a single place.

A first-run orientation belongs in Project Workspace. A next-step widget belongs in Mission Control. A contextual explanation belongs in Artifact Studio. A compact persistent hint belongs in the shell or status strip. A deeper teaching surface may be a collapsible docked panel.

The best design is layered:

1. First-run orientation.
2. Persistent compact Guide cue.
3. Collapsible Guide panel.
4. Mission Control recommendation widget.
5. Contextual Guide hooks in Artifact Studio and Analysis Modules.

This avoids turning the Guide into a single chat window that must do everything.

## The Guide And The Knowledge Library

The Guide should not carry the full burden of explaining Analytics Workstation.

That is the role of the Knowledge Library.

The Guide teaches in the moment. The Library preserves and explains the canonical knowledge body. If the Guide says, "The collector is project memory," it should not need to reproduce the entire collector architecture. It should be able to offer a path:

Read the Collector concept.

Open the Project Artifact Collector architecture.

Read the chapter on artifacts as evidence.

Inspect related QA.

Open the relevant implementation references.

This relationship keeps the Guide humane. It can remain concise, contextual, and helpful because the deeper material lives somewhere stable. It also keeps the Library useful. The Library is not a passive archive; it is the place the Guide points when a user wants the full explanation.

In this sense, the Guide and Library form a teaching pair. The Guide says what matters now. The Library explains why it matters in the system.

## What The Guide Must Not Do

The Guide must not become a shortcut around the architecture.

It should not execute modules. It should not mutate project state. It should not silently promote GenAI output into Knowledge State. It should not bypass Evidence Routing. It should not ignore Execution Mode gates. It should not hide uncertainty. It should not tell users they are ready to decide when evidence is missing.

The Guide is allowed to recommend action.

It is not allowed to pretend recommendation is execution.

## The Product Meaning

The Guide is important because Analytics Workstation is not trying to be a dashboard.

It is trying to become an evidence-centered analytical operating environment.

That environment needs a human-facing voice. Not a mascot. Not a chatbot. Not a wizard that hides the system. A guide.

The Guide should make the software feel approachable without making it shallow. It should let users grow into the system. It should help them understand why artifacts matter, why the collector matters, why evidence can be insufficient, why decision readiness is not model confidence, why context should be optimized, and why GenAI should reason over evidence rather than raw data.

If the Guide works, users will not merely learn where buttons are.

They will learn how to think inside the workstation.
