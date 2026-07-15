# Product Experience Intelligence Phase 7

# Product Philosophy Research, Intent-First Experience Architecture, and Canonical Workflow Design

## Executive Finding

Analytics Workstation is not suffering from a lack of capability. It is suffering from an experience-ordering problem.

The platform now contains enough architecture to support an evidence-centered analytical operating environment: projects, artifacts, collectors, render targets, information encoding, evidence routing, context optimization, knowledge state, GenAI action governance, semantic intelligence, causal intelligence, decision workflows, and product-experience replay. The technical system is unusually coherent. The user-facing surface, however, still exposes too much of the implementation sequence too early.

The product currently says, in effect:

```text
Here are the systems we built.
Choose one.
```

The product should say:

```text
Tell me what decision, question, or uncertainty brought you here.
I will help you turn that intent into evidence, judgment, action, and memory.
```

The recommended product philosophy is:

```text
Intent before capability.
Evidence before recommendation.
Progressive mastery before full exposure.
```

This does not mean hiding the power of the system. It means arranging the power so that it becomes available when it is cognitively useful. The right experience is not a dashboard, a module catalog, a notebook, a chat window, or a report generator. It is a guided analytical operating environment where the project is the world, artifacts are evidence, the collector is memory, and AI helps reason over bounded evidence rather than replacing the deterministic system.

The canonical entry experience should be intent-first, with a business-question-first variant tested immediately after it. The first screen should not be Mission Control, Artifact Studio, Product Experience Lab, Analysis Modules, AI Runtime, or Knowledge Library. The first screen should be the Guide asking:

```text
What decision or question are we trying to resolve?
```

The second question should be:

```text
What do you already have?
```

The answer determines the initial path:

- I have data.
- I have a model.
- I have a business question.
- I have existing evidence.
- I have a decision to review.
- I am continuing a project.

From there, the system should unfold only the next useful layer: project context, data readiness, evidence path, artifacts, decision readiness, governance, and advanced controls. The top-level navigation should eventually become a mode switcher and command surface, not a full disclosure of every internal subsystem.

The most important product move is to stop treating the app as a set of pages and start treating it as a thinking environment.

## Sources Reviewed

This synthesis is based on the current repository structure and product artifacts, including:

- `docs/vision/product_vision.md`
- `docs/architecture_synthesis.md`
- `docs/ui_ux_architecture.md`
- `docs/roadmap/ux_roadmap.md`
- `docs/guide_architecture.md`
- `docs/evidence_strategy_ux.md`
- `docs/product_experience_intelligence_architecture.md`
- `R/app_ui.R`
- `R/page_guide.R`
- `R/page_mission_control.R`
- `R/page_artifact_library.R`
- `R/page_product_experience.R`
- `R/page_project.R`
- `R/page_data.R`
- `R/page_workflow.R`
- `R/page_analysis_modules.R`
- `R/page_ai_runtime.R`
- `R/page_semantic_intelligence.R`
- `R/page_causal_intelligence.R`
- `exports/product_experience/golden_workflow/run_20260714_235655/review_package.json`

External UX references reviewed:

- Nielsen Norman Group, "Progressive Disclosure": https://www.nngroup.com/articles/progressive-disclosure/
- Nielsen Norman Group, "Minimize Cognitive Load to Maximize Usability": https://www.nngroup.com/articles/minimize-cognitive-load/
- Visual Studio Code command architecture documentation: https://code.visualstudio.com/api/extension-guides/command
- Interaction Design Foundation, "Progressive Disclosure": https://ixdf.org/literature/topics/progressive-disclosure
- Apple Human Interface Guidelines layout reference: https://developer.apple.com/design/human-interface-guidelines/layout

The external references are not treated as authority for the product strategy. They are used as grounding for established principles: progressive disclosure, cognitive load reduction, command-oriented power access, and context-sensitive navigation.

## Product Identity

### What It Is

Analytics Workstation is an evidence-centered decision operating environment.

That phrase is more precise than dashboard, BI tool, notebook, Shiny app, report generator, AutoML interface, or AI assistant.

It is evidence-centered because the central object is neither the model nor the chart nor the prompt. The central object is the artifact-as-evidence: a durable analytical object with provenance, quality, intent, diagnostics, recommendations, sidecars, render targets, and relationships to questions and decisions.

It is decision-oriented because evidence has purpose. The system is not only collecting outputs. It is helping determine what is known, what remains uncertain, what evidence is sufficient, what intervention is justified, what should be reviewed, and what should become organizational memory.

It is an operating environment because it is not a single workflow. It coordinates projects, data, analyses, artifacts, AI, governance, reports, decisions, review, replay, and learning. It provides modes and workspaces, not isolated pages.

The shortest product definition:

```text
Analytics Workstation helps teams turn business intent into governed analytical evidence, decisions, and reusable knowledge.
```

The stronger internal definition:

```text
Analytics Workstation is a project-centered analytical operating environment where business questions become investigation plans, analyses produce standardized artifacts, artifacts become evidence, evidence supports decisions, and every important step becomes durable memory.
```

The investor-facing definition:

```text
Analytics Workstation gives organizations an AI-native way to reason over analytical evidence without losing control of provenance, uncertainty, governance, or human judgment.
```

The analyst-facing definition:

```text
Analytics Workstation is the place where your data, models, evidence, conclusions, caveats, and next actions stay connected.
```

The executive-facing definition:

```text
Analytics Workstation helps answer what we should do next, why, how confident we are, and what evidence would change the answer.
```

### What It Is Not

It is not a dashboard.

A dashboard monitors. Analytics Workstation investigates, preserves, routes, and reasons.

It is not a Shiny app.

Shiny is the reactive engine. The product is the workstation architecture, artifact model, evidence system, and decision loop.

It is not a notebook.

Notebooks mix reasoning, implementation, state, and output. Analytics Workstation separates analytical artifacts from their renderings, provenance, policies, and decision use.

It is not AutoML.

AutoML optimizes model production. Analytics Workstation optimizes evidence production, reasoning, and governed action.

It is not a chat interface.

Chat is one interaction layer. The system must function without GenAI and must not make AI responsible for deterministic knowledge, state, navigation, or governance.

It is not a report generator.

Reports are render targets. The collector and artifacts are the durable analytical memory.

### Product Category

The nearest category is not yet common. Possible category labels:

| Candidate Category | Strength | Weakness |
| --- | --- | --- |
| Evidence-centered analytical operating environment | Most accurate | Long phrase |
| Decision evidence workstation | Concise and product-like | Slightly less architectural |
| AI-native analytical system | Strong book/category frame | Too broad for the app surface |
| Analytical intelligence workspace | Memorable | Can sound vague |
| Governed evidence platform | Enterprise-friendly | Understates analyst workflow |
| AI decision workbench | Clear business value | May overemphasize AI |

Recommended product category for internal use:

```text
Evidence-centered analytical operating environment
```

Recommended product shorthand:

```text
Decision Evidence Workstation
```

Recommended external positioning:

```text
An AI-native workstation for turning business questions into governed analytical evidence and decisions.
```

## The Core Experience Problem

The architecture is organized around durable concepts:

```text
Project
-> Artifact
-> Evidence
-> Collector
-> Knowledge State
-> Investigation
-> Evidence Routing
-> Context Optimization
-> GenAI
-> Decision
-> Learning
```

The current shell exposes many of these as peers:

```text
Guide
Knowledge Library
Mission Control
AI Runtime
Product Experience
Project
Data
Plots
Workflow
Analysis Modules
Semantic Intelligence
Causal Intelligence
Code Runner
Artifact Studio
Layout
Export
```

This creates a mismatch. The system's internal ontology is hierarchical and causal. The navigation is mostly flat.

Flat navigation creates several cognitive costs:

1. It asks users to understand the architecture before the product has taught them the task.
2. It exposes developer, research, runtime, and governance surfaces next to everyday user surfaces.
3. It makes "where should I start?" harder than it needs to be.
4. It makes the app feel like many powerful modules rather than one inevitable workflow.
5. It makes AI appear as one more module instead of an ambient reasoning layer.
6. It makes knowledge surfaces feel like documentation rather than living institutional memory.
7. It makes the Golden Workflow fight the shell instead of being carried by it.

This is not a failure of the architecture. It is a product sequencing problem.

The system knows how to think. The interface must now teach users how to think with it.

## Governing Product Philosophy

The single product philosophy should be:

```text
Intent unfolds into evidence.
```

Expanded:

```text
The user begins with intent: a question, decision, uncertainty, objective, or investigation.
The workstation turns intent into an evidence path.
The evidence path produces artifacts.
Artifacts become evidence when connected to the intent.
Evidence supports or blocks recommendations.
Recommendations remain governed by confidence, uncertainty, and human review.
Every consequential step becomes project memory.
```

This philosophy has direct UX consequences:

- Do not open with modules.
- Do not open with architecture.
- Do not open with a blank project workspace.
- Do not open with AI chat.
- Do not open with a report/export surface.
- Do not make the user infer the next step from page availability.
- Do not ask users to choose between internal subsystems before they know what problem they are solving.

Instead:

- Ask what the user is trying to accomplish.
- Show what the system already knows.
- Show what is missing.
- Show one recommended next action.
- Show why that action matters.
- Show the evidence that supports or blocks action.
- Reveal advanced controls only when they become useful.

The closest existing surface is the Guide. The Guide already has the right personality: mentor, not help page; deterministic when possible; GenAI-enhanced but not GenAI-defined. It should become the canonical entry.

## First-Minute Product Contract

Within the first minute, a new user should think:

```text
This is not asking me to pick a tool.
It is asking me what decision or question I need to resolve.
```

The first minute should establish:

1. This product is project-centered.
2. The project exists to answer questions and support decisions.
3. Evidence, not dashboard decoration, is the central object.
4. The system can recommend a next step.
5. The recommendation will explain why.
6. The system preserves memory.
7. AI is optional assistance, not the foundation of correctness.

The first minute should not require understanding:

- module registries
- artifact policies
- render targets
- context strategies
- runtime bundles
- product-experience replay
- QA surfaces
- provider diagnostics
- epistemic runtime internals
- report layout composition
- generated code
- causal estimator details

The user should be able to say:

```text
I came here with a business question. The software understands that as the starting point.
```

## Five-Minute Product Contract

Within five minutes, a user should understand:

1. A project is the container for data, evidence, decisions, and memory.
2. Work begins with intent, data, existing evidence, or a model.
3. The system turns that starting point into a recommended evidence path.
4. Analyses produce artifacts.
5. Artifacts can be inspected as evidence.
6. Evidence has quality, limitations, and recommendations.
7. The collector preserves project memory.
8. Mission Control shows operational health.
9. Artifact Studio is where evidence becomes explorable.
10. The Guide explains what to do next and why.

Five-minute mastery does not require users to understand how evidence routing, context optimization, action governance, causal identification, semantic intelligence, or knowledge compilation work internally. They only need to understand that those systems make the workstation trustworthy and inspectable.

## One-Week Mastery Contract

Within one week, an engaged analyst or technical user should master:

1. Creating and loading projects.
2. Loading data and understanding dataset readiness.
3. Running the canonical workflow from EDA to readiness to feature preparation to model training to assessment to insights.
4. Inspecting artifacts as evidence.
5. Understanding collector memory.
6. Generating and reviewing reports.
7. Using the command palette for expert navigation.
8. Using the Guide for interpretation and next-step explanation.
9. Understanding evidence sufficiency, decision readiness, and uncertainty.
10. Knowing when to use semantic, causal, or decision workflow surfaces.
11. Knowing when to inspect the Knowledge Library.
12. Knowing when GenAI is helpful and when deterministic workflow is enough.

One-week mastery should make the user feel:

```text
I know how this environment thinks, and I can move through it without fighting the interface.
```

## What Should Remain Hidden Initially

The following should remain hidden from initial/default user experience unless the user asks, the current context requires it, or the user is in a developer/research mode:

- Product Experience Lab
- AI Runtime internals
- Code Runner
- raw generated code panels
- QA and replay surfaces
- browser recording controls
- runtime bundle diagnostics
- provider qualification tables
- detailed context strategy telemetry
- artifact sidecar internals
- full ontology and architecture docs
- action registry internals
- experimental campaign infrastructure
- storage provider internals
- remediation state machines
- hash-chain details
- developer-only IDs

These are not unimportant. They are too important to expose casually. They preserve trust and governance, but they are not the first object of user attention.

The right principle:

```text
Architecture should be discoverable, not dumped.
```

## Canonical Entry Experience

The canonical entry should be the Guide, redesigned as an intent-first launcher.

The initial visible sequence:

```text
Welcome to Analytics Workstation.

What decision or question are we trying to resolve?

[I have a business question]
[I have data]
[I have a model]
[I have existing evidence]
[I need to review a decision]
[I want to continue a project]
```

After the user chooses a path, the Guide asks only the next useful question.

### If The User Has A Business Question

The system should ask:

```text
What question are we trying to answer?
```

Then:

```text
What evidence do we already have?
```

Then it creates or loads a project context and proposes an investigation path.

Visible next action:

```text
Create project and define evidence path.
```

### If The User Has Data

The system should ask for the dataset, then show:

- dataset status
- likely targets or required target selection
- recommended first analysis
- why the first analysis matters

Visible next action:

```text
Run Explore Data.
```

### If The User Has A Model

The system should ask for model outputs or scoring data, then show:

- model assessment path
- evidence needed for trust
- limitations if only predictions are available

Visible next action:

```text
Assess model evidence.
```

### If The User Has Existing Evidence

The system should open Artifact Studio or the collector summary, then show:

- evidence inventory
- top warnings
- missing evidence
- decision readiness

Visible next action:

```text
Inspect evidence and summarize readiness.
```

### If The User Needs To Review A Decision

The system should enter a decision-oriented surface, not a generic module list:

- decision statement
- alternatives
- evidence support
- uncertainty
- guardrails
- required review

Visible next action:

```text
Create or review decision context.
```

### If The User Is Continuing A Project

The system should load the last project state and show:

- current project
- last meaningful action
- current evidence state
- open warnings
- one recommended next step

Visible next action:

```text
Resume from last meaningful state.
```

## Entry Surface Alternatives

The repository already identifies several possible entry hypotheses. They should be treated as product research candidates, not abstract preferences.

### Intent-First

Opening prompt:

```text
What are you trying to accomplish?
```

Flow:

```text
Intent -> workflow -> evidence -> decision -> action
```

Strength:

- Broad enough for users who do not yet have a formal business question.
- Excellent for cold start.
- Matches the product philosophy.

Risk:

- Can feel too wizard-like if it blocks expert access.
- Needs an escape hatch through command palette and mode switcher.

Recommendation:

Prototype next. This should be the primary candidate for canonical entry.

### Business-Question-First

Opening prompt:

```text
What question are we trying to answer?
```

Flow:

```text
Question -> evidence -> understanding -> action
```

Strength:

- Strongest commercial story.
- Fits Golden Workflow better than the current generic "What should we do next?"
- Makes the product's value visible quickly.

Risk:

- Some users arrive with data but no explicit question.
- Can over-constrain exploratory analysis.

Recommendation:

Prototype next as the main challenger to intent-first.

### Mission-Control-First

Opening prompt:

```text
What needs attention?
```

Flow:

```text
System state -> priority signal -> evidence -> decision
```

Strength:

- Excellent after a project exists.
- Good for operations and returning users.
- Can show health, alerts, jobs, and next action.

Risk:

- Feels like monitoring rather than thinking.
- Weak for cold start.
- Dense if no context exists.

Recommendation:

Mission Control should become the returning-project home, not the first-run entry.

### Decision-First

Opening prompt:

```text
What decision needs to be made?
```

Flow:

```text
Decision -> alternatives -> evidence -> workflow
```

Strength:

- Strongest for executives and business owners.
- Naturally connects to semantic intelligence and decision workflow.

Risk:

- Requires more authored context.
- Users may not be ready to express alternatives up front.

Recommendation:

Prototype later, after intent-first and business-question-first are tested.

### Evidence-Gallery-First

Opening prompt:

```text
What evidence already exists?
```

Flow:

```text
Evidence -> pattern -> question -> decision
```

Strength:

- Excellent for artifact-rich projects.
- Artifact Studio already feels closest to a distinctive product experience.

Risk:

- Weak for empty projects.
- Can feel like browsing rather than deciding.

Recommendation:

Use as the post-evidence home. Not the cold-start entry.

### Analyst-Workspace / Module-First

Opening prompt:

```text
Which module do you want to run?
```

Flow:

```text
Capability -> module -> artifact -> report
```

Strength:

- Preserves power-user familiarity.
- Fast for experts who know exactly what they need.

Risk:

- Exposes implementation.
- Creates cognitive load for first-time users.
- Weak commercial story.

Recommendation:

Keep as advanced access through Workflow, command palette, and expert mode. Do not make it canonical.

## Information Architecture Recommendation

The current top-level navigation should eventually be reorganized around work modes rather than implementation surfaces.

Recommended long-term mode model:

```text
Guide
Mission Control
Data
Workflow
Artifact Studio
Decision Workbench
Delivery
Knowledge Library
Developer
```

Where:

- Guide is the entry and mentor.
- Mission Control is operational status for an active project.
- Data is project input and dataset inspection.
- Workflow is the guided analytical path.
- Artifact Studio is evidence inspection.
- Decision Workbench combines semantic intelligence, decision lifecycle, valuation, causal evidence, and approval.
- Delivery combines Layout and Export.
- Knowledge Library is the explanatory institutional memory.
- Developer contains AI Runtime, Product Experience Lab, Code Runner, QA, replay, generated code, runtime diagnostics, and internal tools.

This is not a request to implement the reorganization immediately. It is the target information architecture.

### Current Surface Classification

| Surface | Current Role | Recommended Initial Visibility | Rationale |
| --- | --- | --- | --- |
| Guide | Orientation, recommendations, health, teaching | Show first | Closest to intent-first entry. |
| Knowledge Library | Architecture/book/research reader | Hide initially, link contextually | Authoritative memory, not first-run workflow. |
| Mission Control | Operational state center | Show after project exists | Useful when it can prioritize current state. |
| AI Runtime | AI diagnostics, action review, retrieval, governance | Developer/advanced only | Too much implementation and provider detail for default users. |
| Product Experience | Replay, QA, campaigns, media governance | Developer/research only | Important for product team, not end users or investors. |
| Project | Project/storage/results/control center | Contextual setup | Useful but should not be the emotional entry. |
| Data | Dataset load and preview | Show when user has data/no project | Essential path-specific surface. |
| Plots | Plot/artifact builder | Advanced artifact authoring | Valuable but not first-run canonical. |
| Workflow | Stage map and progression | Show after intent/data path starts | Should express path, not module catalog. |
| Analysis Modules | Direct module configuration | Advanced/power access | Current form leaks implementation and generated code. |
| Semantic Intelligence | Business intent and decision authoring | Decision Workbench/advanced | High value but high cognitive load. |
| Causal Intelligence | Causal study/experiment design and estimation | Decision Workbench/scientific path | Should appear when causal question exists. |
| Code Runner | Trusted local R execution | Developer only | Powerful but not part of normal cognitive model. |
| Artifact Studio | Evidence gallery and inspector | Show once evidence exists | Signature evidence experience. |
| Layout | Report composition | Delivery mode | Should appear when user is communicating evidence. |
| Export | Report export | Delivery mode | End-of-loop surface. |

## Progressive Experience Model

The system should disclose power by cognitive level.

### Level 0: Orientation

User question:

```text
What is this and where should I start?
```

Show:

- intent prompt
- project state
- recommended starting paths
- one next action
- simple explanation of why

Hide:

- module internals
- architecture docs
- developer tools
- long diagnostics
- generated code

Primary surface:

- Guide

### Level 1: Workflow

User question:

```text
What am I doing next?
```

Show:

- current stage
- next step
- required inputs
- completion state
- blocker status

Hide:

- raw registries
- full technical configuration
- detailed provenance unless needed

Primary surfaces:

- Workflow
- Data
- Mission Control after project exists

### Level 2: Evidence

User question:

```text
What do we know?
```

Show:

- artifact summary
- key findings
- limitations
- evidence quality
- recommendations
- collector state

Hide:

- low-level sidecars by default
- provider internals
- QA details

Primary surface:

- Artifact Studio

### Level 3: Diagnostics And Trust

User question:

```text
Can I trust this?
```

Show:

- warnings
- data quality
- assumptions
- validation details
- conflicting evidence
- decision readiness
- review state

Hide:

- source code and runtime internals unless requested

Primary surfaces:

- Evidence Inspector
- Mission Control
- Decision Workbench

### Level 4: Architecture And Governance

User question:

```text
How is this system built, governed, or validated?
```

Show:

- contracts
- policies
- runtime
- QA
- ontology
- action governance
- replay manifests

Primary surfaces:

- Knowledge Library
- Developer mode
- Product Experience Lab
- AI Runtime

This is not a hierarchy of importance. It is a hierarchy of timing.

## AI Philosophy

AI should not be the product's entry point. AI should be an ambient reasoning layer that becomes visible when it adds judgment, synthesis, critique, or explanation beyond deterministic state.

### AI Should Be Used For

- explaining why a next action is recommended when multiple factors matter
- summarizing cross-artifact evidence
- identifying contradictions and unresolved uncertainty
- translating evidence into executive language
- drafting bounded review text
- critiquing claim strength
- explaining epistemic risks
- helping users understand complex artifacts
- comparing evidence strategies
- proposing investigation paths with explicit uncertainty

### AI Should Not Be Used For

- basic navigation that deterministic UI already knows
- selecting the next obvious stage
- replacing structured status indicators
- generating long generic prose
- inventing missing evidence
- obscuring provenance
- acting without review
- making the user wait for explanations that could be static templates

### AI Should Feel Like

- a senior analyst whispering context
- a critic checking overreach
- a synthesis layer over evidence
- a guide that knows when to be quiet

### AI Should Not Feel Like

- a chatbot pasted onto a dashboard
- a substitute for navigation
- a theatrical actor
- a mysterious decision-maker
- a source of truth independent of artifacts

The product-experience research already states that deterministic UI should replace AI for basic interface operation. This is correct. The strongest AI moments are not when AI clicks buttons. They are when AI compresses complex evidence into a decision-relevant explanation while preserving uncertainty and traceability.

## Mental Model Analysis

### Current User Mental Model Implied By The Shell

The current shell implies:

```text
This is a large application with many modules.
I need to know which page to open.
Some pages are for analysis, some for AI, some for developer tooling, some for reports.
I must learn the product map before I can be effective.
```

This is acceptable for builders and power users. It is too expensive for first-time analysts, executives, and investors.

### Desired User Mental Model

The desired mental model:

```text
I bring a question, decision, data set, model, or existing project.
The workstation tells me what evidence exists, what is missing, and what I should do next.
When evidence is produced, I can inspect it.
When recommendations are made, I can see why.
When action is proposed, governance and memory preserve the trail.
```

### The Product Should Teach These Concepts In Order

1. Project
2. Intent
3. Evidence path
4. Artifact
5. Collector
6. Recommendation
7. Decision readiness
8. Governance
9. AI assistance
10. Architecture

The current app often exposes architecture before intent. That is the central inversion to fix.

## Great Software Pattern Synthesis

Analytics Workstation should borrow interaction principles from professional software without imitating any single product.

### VS Code / Cursor

Relevant patterns:

- command palette as expert shortcut
- workspace as project root
- panels that appear when context requires them
- extensions/capabilities accessible without dominating primary experience

Implication:

The command palette should be power access, not the default learning path. Developer and advanced systems can exist behind commands and mode switches.

### Figma

Relevant patterns:

- object-centered canvas
- inspector as contextual detail
- selection drives the right panel
- collaboration and state are visible but secondary to the object

Implication:

Artifact Studio is the closest existing surface to a signature workstation experience. Selecting an artifact should feel like selecting an analytical object, not opening a property list.

### Adobe Lightroom

Relevant patterns:

- library of visual evidence
- filmstrip for continuity
- focused inspection
- modes for different phases of work

Implication:

Artifact Studio should remain a major product pillar. Evidence browsing is more memorable than module configuration.

### Linear

Relevant patterns:

- focused next action
- low-friction status
- keyboard-driven flow
- opinionated prioritization

Implication:

Mission Control should emphasize one current priority, not equal-weight status everywhere.

### Notion / Obsidian

Relevant patterns:

- knowledge spaces
- backlinking
- readable documents
- concepts as durable objects

Implication:

Knowledge Library should become the authoritative explanation layer, but not the entry point.

### Jupyter / Observable

Relevant patterns:

- iterative analysis
- visible computation
- narrative plus results

Risks:

- notebooks blur code, state, reasoning, and evidence

Implication:

Analytics Workstation should preserve the exploratory value while maintaining standardized artifacts and collector memory.

### Bloomberg / Trading Terminals

Relevant patterns:

- high-density professional surfaces
- command-driven navigation
- real-time status
- specialized user mastery

Risk:

- steep learning curve

Implication:

Professional density is appropriate after orientation. It should not be the first experience.

### Control Rooms / Mission Control Systems

Relevant patterns:

- status, alerts, escalation, incident awareness
- operational confidence

Risk:

- users may feel they are monitoring a machine rather than conducting an investigation

Implication:

Mission Control is important, but it should answer "what needs attention now?" rather than "what is every subsystem doing?"

## Product Narrative

The canonical product story should be:

```text
A user arrives with a business intent.
The workstation converts that intent into an evidence path.
The user loads or selects data.
The system produces artifacts.
Artifacts become evidence.
The Evidence Inspector explains what each artifact means, how trustworthy it is, and what it implies.
Mission Control tracks health and next action.
The Guide explains why the next step matters.
AI synthesizes bounded evidence when useful.
The decision is drafted, reviewed, approved, or rejected.
The collector preserves memory.
The project becomes smarter for next time.
```

The current Golden Workflow already points in this direction:

```text
Business Context
-> Evidence Review
-> Cross-Artifact Synthesis
-> Evidence Sufficiency
-> Governed Next Action
-> Navigation
-> Review Draft
-> Human Confirmation and Persisted Draft
```

The problem is that the expected pages still lean heavily on AI Runtime, which is labeled as a developer surface. The story is right. The stagecraft is not yet right. AI Runtime should not be where the user experiences the canonical workflow. It should be the backstage machinery that enables Guide, Mission Control, Artifact Studio, and Decision Workbench experiences.

## Golden Workflow Reframe

Current Golden Workflow:

```text
Golden Workflow: Business Question to Persisted Draft
Guiding question: What should we do next?
```

Recommended guiding question:

```text
Which action should we take next, and what evidence supports it?
```

For the Bounded Growth Pilot flagship world, the guiding question should be concrete:

```text
Which acquisition tactic should we scale next quarter without violating quality and capacity guardrails?
```

The first externally meaningful video should not begin with page navigation. It should begin with the decision context.

Recommended recording narrative:

1. The user opens the Guide.
2. The Guide asks what decision is being made.
3. The Bounded Growth Pilot question appears.
4. The workstation shows current evidence state and missing evidence.
5. The user runs or reviews the evidence path.
6. Artifacts appear in Artifact Studio.
7. The Evidence Inspector shows one meaningful artifact.
8. AI or deterministic synthesis summarizes support, uncertainty, and guardrails.
9. Mission Control shows the recommended governed next action.
10. The user reviews a persisted draft.
11. The system confirms memory and next action.

This creates a commercial story:

```text
The app did not merely show analytics.
It helped prevent a premature decision and identified a bounded pilot supported by evidence.
```

## Cognitive Load Findings

### Main Cognitive Load Sources

The largest unnecessary cognitive loads are:

1. Flat navigation across too many surfaces.
2. Developer/research tools visible near user tools.
3. Architecture language appearing before user intent.
4. Generated code panels appearing in analysis contexts.
5. AI Runtime visible as a product page rather than backstage machinery.
6. Analysis Modules requiring module knowledge rather than workflow intent.
7. Semantic and causal intelligence appearing as large authored workbenches without gradual entry.
8. Mission Control density without enough dominance for the one next action.
9. Product Experience Lab exposing replay machinery inside the same shell as the product experience.
10. Knowledge Library competing with product workflow as a top-level page rather than contextual authority.

### Necessary Complexity

Some complexity is intrinsic:

- causal inference is complex
- epistemic governance is complex
- decision review is complex
- evidence routing is complex
- cross-artifact synthesis is complex
- model assessment is complex

The goal is not to remove this complexity. The goal is to remove extraneous complexity: the mental work of figuring out which subsystem to open, what internal labels mean, or why developer surfaces are visible during normal work.

External UX literature supports this distinction. Nielsen Norman Group distinguishes intrinsic load from extraneous load and recommends reducing mental work that does not help users understand the content. Progressive disclosure similarly defers advanced or rarely used features until needed.

## What Should Become Invisible

The following should become invisible during ordinary use:

- provider request payload construction
- action registry internals
- runtime bundle selection
- context component scoring
- internal artifact normalization
- replay/golden workflow machinery
- file path staging unless relevant
- QA contract execution
- generated R code by default
- raw storage provider paths
- raw project ledger internals
- model qualification diagnostics unless model choice matters

Invisible does not mean unavailable. It means the system should not charge the user attention for these details until they are relevant.

## What Should Become Unforgettable

The unforgettable moments should be:

1. The first prompt asks about the user's decision, not the app's modules.
2. The system shows what is known, unknown, and needed in one coherent view.
3. A generated artifact appears as evidence with quality, limitations, and recommendations.
4. The Evidence Inspector feels like opening an analytical dossier.
5. The system recommends one next action and explains why.
6. AI synthesis connects evidence without pretending uncertainty is gone.
7. A governed draft becomes durable project memory.
8. Returning to the project feels like reopening an investigation, not reloading a dashboard.

If these moments work, the product feels inevitable.

## Product Experience Constitution

These principles should guide all future UX work.

### 1. Intent Before Capability

Users should not need to understand the module map before they can begin. The product should start from intent: question, decision, data, model, evidence, or project continuation.

### 2. Evidence Before Recommendation

Recommendations should be grounded in visible or inspectable evidence. The user should be able to ask, "Why?" and receive artifacts, diagnostics, and uncertainty.

### 3. One Next Action Before Many Possibilities

The system can contain many capabilities, but the main experience should surface one recommended next step when context permits.

### 4. Architecture Is Earned

Architecture should be available through the Knowledge Library, developer mode, and contextual links. It should not be dumped onto first-time users.

### 5. AI Is A Reasoning Layer, Not UI Glue

AI should synthesize, critique, explain, and draft. Deterministic UI should handle known state, navigation, and obvious next actions.

### 6. Artifacts Are First-Class Objects

Plots, tables, narratives, diagnostics, and recommendations are not transient outputs. They are evidence objects with identity, provenance, quality, and relationships.

### 7. The Collector Is Memory, But Memory Should Feel Human

Collector state should not feel like a file path. It should feel like the project remembers what happened and why.

### 8. Progressive Mastery Beats Progressive Settings

Progressive disclosure should reveal concepts and decisions, not merely hide advanced parameters.

### 9. Trust Must Be Visible

Uncertainty, warnings, limitations, source, review state, and governance should be visible at the right altitude.

### 10. Developer Surfaces Are Not Product Surfaces

Product Experience Lab, AI Runtime internals, Code Runner, QA, replay, generated code, and runtime diagnostics belong behind developer/research access.

### 11. Reports Are Delivery, Not Memory

Reports matter, but the project memory lives in artifacts, collector, ledgers, and knowledge state.

### 12. The Product Should Teach Its Own Ontology Slowly

Users should eventually learn artifacts, evidence, collector, decision readiness, evidence routing, and context optimization. They should learn them through use, not through a lecture.

### 13. The Command Palette Is For Power, Not Orientation

The command palette should help users who know what they want. It should not compensate for unclear primary navigation.

### 14. Empty States Are Teaching Moments

An empty project, empty artifact gallery, or missing provider should teach the next useful action.

### 15. Every Important Step Should Create Memory

If a step matters to a decision, it should leave a durable trace: artifact, finding, draft, review, ledger entry, or collector update.

## Canonical User Journey

### Cold Start

```text
Guide
-> Intent prompt
-> Project creation or load
-> Data/model/evidence intake
-> Recommended evidence path
-> First analysis
-> Artifact Studio
-> Evidence summary
-> Mission Control next action
-> Delivery or decision review
```

### Returning User

```text
Mission Control
-> Current project state
-> Open alerts
-> Last meaningful event
-> One next action
-> Artifact Studio or Decision Workbench
```

### Analyst Power User

```text
Command Palette
-> Workflow stage or module
-> Advanced settings
-> Artifact output
-> Inspector and collector
```

### Executive Reviewer

```text
Guide or Decision Workbench
-> Decision summary
-> Evidence sufficiency
-> Key artifacts
-> Risks and guardrails
-> Recommendation
-> Approval/review state
```

### Developer / Research User

```text
Developer mode
-> Product Experience Lab
-> AI Runtime
-> QA
-> Replay artifacts
-> Runtime bundle diagnostics
-> Code Runner
```

## Roadmap Recommendations

### Immediate UX Research Campaign

Do not redesign everything. Test the entry thesis with low-risk prototypes.

Recommended candidates:

1. Intent-first Guide variant.
2. Business-question-first Guide variant.
3. Current Golden Workflow baseline.

Evaluation questions:

- Which variant lets a first-time user start without understanding modules?
- Which variant makes the business story obvious fastest?
- Which variant preserves expert escape hatches?
- Which variant reduces developer-surface leakage?
- Which variant produces the strongest investor recording?

### Near-Term Product Hardening

1. Move Product Experience Lab to Developer/Research mode by default.
2. Move AI Runtime internals to Developer/Advanced mode by default.
3. Keep Guide as the default entry.
4. Make the Guide's primary prompt intent-first.
5. Make the Golden Workflow question specific to the flagship world.
6. Replace generic "What should we do next?" with decision-specific language.
7. Convert Analysis Modules into a backstage or workflow-invoked surface for first-run users.
8. Make Mission Control emphasize the single current priority.
9. Make Artifact Studio the default after evidence exists.
10. Merge Layout and Export conceptually into Delivery.

### Medium-Term Product Direction

1. Create a Decision Workbench mode that absorbs semantic intelligence, causal intelligence, valuation, decision workflow, and review.
2. Build an Evidence Storyline view: known, unknown, evidence, confidence, next action.
3. Make Knowledge Library contextual rather than competing with core workflow.
4. Add role-aware surfaces: executive, analyst, scientist, developer.
5. Make collector memory feel like a project timeline.
6. Use command palette as expert access to hidden or advanced systems.
7. Create a persistent Guide that can explain the current surface in context.

### Long-Term Direction

1. Adaptive entry based on project state and user role.
2. Cross-project knowledge transfer surfaced as recommendations.
3. Evidence routing visible as an editable but comprehensible evidence plan.
4. Decision histories that show how knowledge changed over time.
5. AI-assisted investigation planning grounded in Knowledge State and Evidence Strategy.
6. Product-experience replay as continuous UX QA, not only demo production.
7. Knowledge Library as source for docs, book, GPT knowledge packs, and in-app education.

## Product Research Questions

The next research questions should be:

1. Do new users naturally start with intent, question, data, model, or project state?
2. Does Mission Control feel like a home base or an operations dashboard?
3. When does Artifact Studio become the user's center of gravity?
4. What is the shortest AI response that feels useful?
5. How much architecture should be visible before it becomes cognitive load?
6. Which surfaces should be modes and which should be backstage systems?
7. Can the Guide explain the system without becoming a documentation page?
8. Does the Golden Workflow demonstrate business value without narration?
9. Which moment produces the strongest "this is different" reaction?
10. What should an executive see that an analyst should not see first?
11. What should an analyst see that an executive should not see first?
12. How can the app reveal power without looking complicated?
13. What user language should replace internal terms like runtime, artifact policy, context strategy, and provider qualification?
14. Should decisions or investigations become first-class project objects in the UI?
15. Should the first screen ask a freeform question, present structured choices, or combine both?

## Terminology Recommendations

Use user-facing language:

| Internal / Advanced Term | User-Facing Term |
| --- | --- |
| Artifact | Evidence item |
| Artifact Studio | Evidence Library or Artifact Studio, depending on audience |
| Collector | Project Memory |
| Render Target | Output Format or Delivery Target |
| Context Optimization | Evidence Budgeting or AI Context Planning |
| Evidence Routing | Evidence Selection |
| GenAI Provider | AI Assistant Provider |
| AI Runtime | AI Operations / Developer AI Runtime |
| Product Experience Lab | Product QA Lab |
| Semantic Intelligence | Business Intent / Decision Context |
| Causal Intelligence | Causal Evidence |
| Analysis Modules | Analysis Tools or Analytical Steps |
| Remediation Plan | Improvement Plan |
| Epistemic Integrity | Evidence Integrity |
| Runtime Bundle | AI Knowledge Bundle |

Do not remove precise terms from architecture docs. Use them at the right altitude.

## Final Assessment

### What Is Analytics Workstation?

Analytics Workstation is an evidence-centered decision operating environment. It turns business intent into analytical evidence, governed recommendations, durable project memory, and reusable knowledge.

### What Should The User Think Within The First Minute?

The user should think:

```text
This system starts with what I am trying to decide, not with a tool list.
```

They should also understand that the workstation will guide them from intent to evidence to action.

### What Should They Understand Within Five Minutes?

They should understand:

- projects preserve work
- analyses create artifacts
- artifacts become evidence
- evidence has quality and limitations
- the collector is project memory
- the Guide recommends next steps
- Artifact Studio is where evidence is inspected
- Mission Control shows health and priority
- AI helps explain and synthesize, but does not replace governance

### What Should They Master Within One Week?

They should master:

- creating/loading projects
- loading data
- running the guided analytical workflow
- inspecting evidence
- using collector memory
- interpreting recommendations and warnings
- generating reports
- using the command palette
- using the Guide for next steps
- understanding when to use decision, semantic, causal, and developer surfaces

### What Should Remain Hidden Initially?

Developer and architecture-heavy surfaces should remain hidden initially:

- Product Experience Lab
- AI Runtime internals
- Code Runner
- QA/replay controls
- generated code
- provider diagnostics
- runtime bundle details
- raw context strategy telemetry
- architecture docs unless requested

### What Should Become The Canonical Entry Experience?

The Guide should become the canonical entry experience, with an intent-first prompt and a business-question-first prototype tested as the immediate challenger.

### What Should Become Invisible?

Deterministic plumbing should become invisible:

- routing mechanics
- provider payloads
- artifact normalization
- sidecar staging
- action registry internals
- replay machinery
- generated code
- storage details
- runtime diagnostics

They remain inspectable for advanced users, but should not occupy normal attention.

### What Should Become Unforgettable?

The unforgettable moment should be:

```text
The user asks a business question, the workstation produces evidence, identifies uncertainty, recommends a governed next action, and preserves the reasoning as project memory.
```

The Evidence Inspector should be the most tactile proof that artifacts are evidence. The final persisted draft should prove that the project remembers.

### What Currently Creates The Most Unnecessary Cognitive Load?

The largest load is flat exposure of implementation surfaces before user intent:

- too many top-level tabs
- developer/research pages visible beside product pages
- AI Runtime as a visible destination
- Analysis Modules as raw module selection
- architecture language before task language
- generated code and QA surfaces appearing too early

### What Single Product Philosophy Should Guide All Future UX?

```text
Intent unfolds into evidence.
```

All future UX decisions should be judged against this principle. If a screen, label, button, or workflow does not help the user move from intent to evidence to decision to memory, it should be hidden, renamed, postponed, or redesigned.

