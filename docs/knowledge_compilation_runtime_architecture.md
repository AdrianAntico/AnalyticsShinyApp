# Knowledge Compilation and AI Runtime Architecture

Status: Phases 1-7 implemented incrementally; this document remains the architectural source, with phase-specific implementation notes in `docs/knowledge_compilation_runtime_phase*.md`
Scope: ontology, runtime, compilation, ownership, and long-term placement review
Date: 2026-07-14

## Executive Summary

Analytics Workstation has reached a boundary where documentation alone is no longer enough.

The project now contains long-form philosophy, architectural contracts, ontologies, policies, source chapters, examples, QA, historical decisions, and implementation rules. Those documents are essential as source knowledge, but they are not a practical runtime substrate for an AI that will eventually operate inside the application. An AI runtime cannot be expected to consume hundreds of pages of philosophy on every interaction. It needs small, task-specific, versioned, validated, and explainable bundles.

The recommended architecture is:

```text
Source Philosophy and Architecture
  -> Knowledge Compiler
  -> Compiled Runtime Bundles
  -> Context Compiler
  -> AI Runtime
  -> Local / Free / Paid / Frontier / Fine-Tuned Models
```

Epistemic Integrity should therefore be implemented as a combination of:

- portable contracts and taxonomies;
- deterministic quality gates;
- claim and reasoning metadata;
- workflow and intervention events;
- decision-review integration;
- compiled runtime policy;
- task-specific AI guidance;
- knowledge compilation output.

It should not be implemented as only a set of R contracts, only report metadata, only UI warnings, or only prompt instructions. It is a cross-cutting integrity layer whose philosophy must compile into operational rules.

Knowledge Compilation should become a first-class architectural subsystem, but not necessarily a new repository in Phase 0. The initial recommendation is:

- AutoQuant owns portable analytical contracts, epistemic taxonomies, deterministic checks, and package-level runtime source fragments.
- AnalyticsShinyApp owns project runtime assembly, context compilation, AI runtime policy selection, UI integration, Mission Control surfacing, and action governance.
- Documentation remains the canonical source of long-form philosophy.
- Compiled bundles become derived artifacts that are versioned, validated, and regenerated from source.

No implementation should begin until the bundle taxonomy and ownership boundaries are accepted.

## Core Architectural Decision

### Decision

Adopt the distinction:

```text
Source Philosophy
  -> Compiled Runtime
  -> Current Project Context
  -> Task Context
  -> LLM
```

instead of:

```text
Documentation
  -> LLM
```

### Rationale

The direct documentation-to-LLM approach is attractive early because it is simple. It fails at scale:

- token cost grows with every new architecture document;
- model attention becomes diluted;
- instructions conflict unless normalized;
- task-specific guidance is buried in general philosophy;
- local/free models cannot afford large contexts;
- fine-tuned or Custom GPT deployments need stable source packs;
- governance rules must be explainable and testable;
- runtime behavior must be reproducible.

Compilation solves this by converting long-form knowledge into smaller operational assets.

## Where Epistemic Integrity Belongs

Epistemic Integrity should not live in one place. It has multiple representations across the system.

| Capability | Primary form | Owner | Consumer | Updated by | Validated by | Runtime nature |
|---|---|---|---|---|---|---|
| Reasoning taxonomy | Contract/taxonomy | AutoQuant | App, reports, GenAI runtime | Package releases | AutoQuant QA | Deterministic |
| Human assertion provenance | Contract + workflow event | AutoQuant contract, app capture | Decision Workflow, Causal, Reports | Users/workflows | App + AutoQuant QA | Deterministic + human reviewed |
| Human intervention provenance | Workflow event + audit event | AnalyticsShinyApp | Mission Control, Evidence Inbox, reports | App runtime | App QA/audit | Deterministic |
| Claim governance | Contract + quality gate | AutoQuant | Reports, Decision Valuation, Causal, GenAI | Modules/workflows | AutoQuant QA | Deterministic |
| Prohibited/permitted language | Compiled runtime policy + report gate | AutoQuant source, app compiler | Reports, GenAI | Compiler/versioned policy | Bundle QA | Compiled deterministic |
| Abductive assessment | Contract + review artifact | AutoQuant | Investigation, Guide, GenAI | Analyst/AI-assisted drafts | Human review + QA | Human reviewed + AI assisted |
| Contradictory evidence | Artifact metadata + claim map | Both | Evidence Routing, reports, Guide | Modules/users | QA + review | Deterministic |
| Cognitive-bias exposure | Finding/risk signal | AutoQuant taxonomy, app findings | Mission Control, Evidence Inbox | Assessments/review | QA + human review | Signal-only or gated |
| Organizational pressure exposure | Workflow event + review risk | AnalyticsShinyApp | Decision Workflow, Mission Control | Users/reviewers | Human review | Human reviewed |
| Judgment calibration | Learning artifact | AutoQuant contract, app outcomes | Runtime compiler, Guide | Outcome reviews | QA + governance | Learned, explainable |
| Epistemic runtime guidance | Compiled bundle | AnalyticsShinyApp compiler | AI Runtime | Compiler | Bundle QA | Compiled |
| Epistemic UI status | Mission Control/status cards | AnalyticsShinyApp | Human users | App runtime | UI QA | Deterministic |

## Runtime Architecture

The runtime should be layered.

```text
Source Layer
  docs, README, examples, QA, contracts, source chapters, historical notes

Compilation Layer
  parse, classify, normalize, resolve, extract, test, bundle

Runtime Bundle Layer
  decision, workflow, causal, epistemic, forecast, valuation, operator, authority, claim

Context Compiler Layer
  project state, artifact state, task, user constraints, provider capability, budget

AI Runtime Layer
  task router, instruction loader, tool/action policy, evidence package, model adapter

Model Layer
  deterministic code, local model, paid model, frontier model, fine-tuned model, Custom GPT
```

### Source Layer

The source layer remains human-readable and expansive. It contains:

- product vision;
- manifesto;
- canonical ontology;
- concept dependency graph;
- architecture synthesis;
- Epistemic Integrity review;
- policies;
- contracts;
- examples;
- QA results;
- source chapters;
- historical design notes;
- implementation decisions.

Source documents preserve why the system exists and how ideas evolved. They are not optimized for runtime.

### Compilation Layer

The compiler transforms source knowledge into operational knowledge.

The compiler should be deterministic first. AI assistance may help propose summaries or detect conflicts later, but compiled runtime output must remain inspectable.

### Runtime Bundle Layer

Runtime bundles are small, versioned, task-oriented knowledge packs. They are not prompts alone. They contain:

- concepts;
- invariants;
- rules;
- prohibited actions;
- permitted actions;
- examples;
- counterexamples;
- task routing hints;
- required checks;
- fallback behavior;
- confidence/uncertainty rules;
- provenance requirements;
- QA expectations.

### Context Compiler Layer

The context compiler selects and assembles the minimum useful runtime context for the current task. It combines:

- active task;
- current page/mode;
- project metadata;
- artifact summaries;
- evidence plan;
- available tools/actions;
- provider capabilities;
- user execution mode;
- evidence strategy;
- risk tier;
- relevant runtime bundles.

### AI Runtime Layer

The AI Runtime is the controlled execution environment for model interaction. It decides:

- which model/provider is eligible;
- which bundles to load;
- which project context is included;
- which actions are available;
- which claims are permitted;
- whether approval is needed;
- whether the request is blocked;
- what telemetry must be recorded.

It must not be an unstructured chat wrapper.

## Knowledge Compilation Pipeline

The long-term compilation pipeline should look like this:

```text
1. Source discovery
2. Parsing
3. Document classification
4. Concept extraction
5. Contract extraction
6. Policy extraction
7. Example extraction
8. Counterexample extraction
9. Operator extraction
10. Dependency graph construction
11. Conflict detection
12. Conflict resolution
13. Runtime rule generation
14. Bundle generation
15. Bundle validation
16. Runtime manifest generation
17. Context compiler registration
18. Runtime output
```

### 1. Source Discovery

Find source material:

- `docs/`;
- `book/source/`;
- package READMEs;
- exported contract docs;
- examples;
- QA files;
- historical source packs;
- architecture reviews.

### 2. Parsing

Convert Markdown, Roxygen, README, examples, and QA source into structured sections.

Expected parsed units:

- title;
- section heading;
- body;
- code block;
- table;
- concept mention;
- policy phrase;
- imperative instruction;
- example;
- warning;
- open question.

### 3. Document Classification

Classify each source document:

- product vision;
- architecture;
- policy;
- contract;
- QA;
- research;
- roadmap;
- source chapter;
- user guide;
- implementation note;
- historical note.

### 4. Concept Extraction

Extract and normalize concepts:

- Artifact;
- Evidence;
- Claim;
- Decision;
- Authority;
- Knowledge State;
- Evidence Routing;
- Context Optimization;
- Epistemic Integrity;
- Human Intervention;
- Reasoning Risk;
- Marginal Information Gain;
- Runtime Bundle.

### 5. Contract Extraction

Identify formal contracts:

- R function names;
- schema versions;
- lifecycle states;
- allowed transitions;
- required fields;
- status vocabularies;
- validation functions;
- QA functions.

### 6. Policy Extraction

Extract normative rules:

- must;
- must not;
- should;
- should not;
- allowed;
- prohibited;
- requires review;
- blocks execution;
- advisory only.

### 7. Example Extraction

Extract positive examples that teach desired behavior:

- valid decision workflow;
- valid causal planning;
- valid evidence package;
- valid GenAI action proposal;
- valid claim language.

### 8. Counterexample Extraction

Extract anti-patterns:

- treating authority as truth;
- treating artifact completeness as claim validity;
- using GenAI to approve decisions;
- estimating observational causal effects before readiness;
- suppressing contradictory evidence;
- using human judgment as unreviewed fact.

### 9. Operator Extraction

Identify app and analytical operators:

- modules;
- actions;
- analysis functions;
- report renderers;
- review workflows;
- causal planners;
- valuation translators;
- GenAI actions.

### 10. Dependency Graph Construction

Build relationships:

- concept depends on concept;
- policy governs operator;
- QA validates contract;
- runtime bundle includes rule;
- source document supports bundle;
- bundle required for task.

### 11. Conflict Detection

Detect:

- duplicate terms;
- conflicting instructions;
- obsolete names;
- deprecated workflows;
- policy contradictions;
- drift between docs and code;
- examples that no longer compile.

### 12. Conflict Resolution

Resolve using hierarchy:

1. explicit current architecture decisions;
2. active contract definitions;
3. current QA;
4. current README;
5. source chapters;
6. historical notes.

Historical notes should be preserved but marked non-authoritative when superseded.

### 13. Runtime Rule Generation

Convert policies into operational rules:

- preconditions;
- required checks;
- blocked actions;
- allowed actions;
- review requirements;
- permitted claim language;
- prohibited claim language;
- fallback behavior;
- telemetry requirements.

### 14. Bundle Generation

Generate bundle artifacts:

- `bundle_id`;
- `bundle_version`;
- `source_refs`;
- `concepts`;
- `rules`;
- `examples`;
- `counterexamples`;
- `dependencies`;
- `token_budget`;
- `provider_suitability`;
- `validation_hash`.

### 15. Bundle Validation

Validate:

- required sections exist;
- source refs exist;
- no prohibited runtime contradictions;
- bundle size within budget;
- dependencies available;
- examples are current;
- rules map to known actions/contracts where applicable.

### 16. Runtime Manifest Generation

Produce a manifest:

- bundle inventory;
- versions;
- source hashes;
- dependency graph;
- model routing compatibility;
- last compilation time;
- validation status;
- known warnings.

### 17. Context Compiler Registration

Register bundles for task routing:

- task type;
- page/mode;
- action id;
- risk tier;
- evidence strategy;
- provider capability.

### 18. Runtime Output

The final output is not prose documentation. It is a compact runtime package:

- manifest;
- bundles;
- dependency graph;
- task routing map;
- validation report.

## Bundle Taxonomy

Runtime bundles should be domain-specific and composable.

| Bundle | Purpose | Dependencies | Expected size | Loaded when |
|---|---|---|---:|---|
| Core Runtime | Identity, safety, project model, evidence-centered philosophy | None | Small | Every AI call |
| Artifact Runtime | Artifact model, quality, collector, render targets | Core | Small/medium | Artifact tasks |
| Evidence Runtime | Evidence routing, MIG, context strategy, trustworthiness | Core, Artifact | Medium | Evidence selection/summarization |
| Epistemic Runtime | Claims, reasoning risk, intervention provenance, permitted language | Core, Evidence | Medium | Claims, recommendations, causal, reports |
| Claim Runtime | Claim classes, support/contradiction, language gates | Core, Evidence, Epistemic | Small | Report/recommendation wording |
| Decision Runtime | Decisions, alternatives, uncertainty, optionality | Core, Evidence, Claim | Medium | Decision tasks |
| Workflow Runtime | Review, approval, implementation, outcome lifecycle | Core, Decision | Medium | Decision workflow tasks |
| Causal Runtime | Causal questions, estimands, design readiness, prohibited claims | Core, Evidence, Epistemic | Medium/large | Causal tasks |
| Forecast Runtime | Forecast specs, evidence, assessment, strategy selection | Core, Evidence | Medium | Forecast tasks |
| Valuation Runtime | Evidence-to-impact, economics, source types, guardrails | Core, Decision, Claim | Medium | Valuation tasks |
| Authority Runtime | Authority, coverage, approval, access boundaries | Core, Workflow | Small | Approval/review tasks |
| Operator Runtime | Available actions, module registry, tool/action boundaries | Core | Medium | Action/task execution |
| Guide Runtime | Teaching language, onboarding, explanations | Core, selected domain bundles | Small/medium | Guide responses |
| Report Runtime | Render targets, claim fidelity, caveats, narrative rules | Core, Artifact, Claim | Medium | Report generation |
| Developer Runtime | QA, contracts, extension points, repository boundaries | Core | Medium/large | Developer tasks |

## Bundle Granularity

Bundle granularity should be coarse enough to avoid brittle micro-prompts and fine enough to avoid loading a book for every task.

Recommended granularity:

- one core bundle always loaded;
- one task-family bundle loaded for the domain;
- one policy bundle loaded for the risk type;
- one operator bundle loaded when an action may be proposed;
- one project-context bundle generated dynamically;
- one evidence bundle generated dynamically.

Avoid:

- one huge universal runtime prompt;
- hundreds of tiny fragments with unclear precedence;
- runtime dependence on source docs for ordinary operations.

## Ownership Matrix

| Layer | Owner | Repository placement | Notes |
|---|---|---|---|
| Long-form philosophy | AnalyticsShinyApp docs/book | AnalyticsShinyApp | Source of product philosophy and book |
| Portable analytical contracts | AutoQuant | AutoQuant | Exported R contracts and QA |
| Plot/render primitives | AutoPlots | AutoPlots | Visualization behavior, not reasoning policy |
| Feature transformation contracts | Rodeo | Rodeo | Transformation fit/apply semantics |
| App workflow/runtime | AnalyticsShinyApp | AnalyticsShinyApp | Project state, UI, orchestration |
| GenAI provider abstraction | AnalyticsShinyApp | AnalyticsShinyApp | Provider/model interaction |
| GenAI action policy/audit | AnalyticsShinyApp | AnalyticsShinyApp | Registered actions, approvals, audit |
| Knowledge compiler | Initially AnalyticsShinyApp | AnalyticsShinyApp, later maybe separate | Compiles source into runtime bundles |
| Runtime bundles | Generated artifacts | AnalyticsShinyApp project or package inst data | Versioned derived output |
| Context compiler | AnalyticsShinyApp | AnalyticsShinyApp | Assembles task-specific runtime context |
| AI Runtime | AnalyticsShinyApp | AnalyticsShinyApp | Runtime policy and model routing |
| Cross-repo validation | AnalyticsShinyApp + package QA | Multiple | Ensures source and runtime do not drift |

## Repository Ownership Recommendation

Do not create a new repository yet.

Phase 0 should remain architecture-only. Phase 1 should likely implement minimal compilation inside AnalyticsShinyApp because:

- the app owns runtime context;
- the app owns provider/model selection;
- the app owns action governance;
- the app owns project state;
- the app already contains the book/source docs.

AutoQuant should not own the whole AI runtime. It should own portable domain truth:

- analytical contracts;
- epistemic contracts;
- causal contracts;
- decision contracts;
- validation functions;
- QA;
- source fragments suitable for compilation.

A future repository may become justified if the compiler becomes useful across multiple apps or products. Candidate future name:

```text
AnalyticsKnowledgeCompiler
```

But this should wait until there is a stable compiler contract and more than one consumer.

## AI Runtime Architecture

The AI Runtime should be composed of the following components:

### Runtime Manifest

Records:

- bundle versions;
- source hashes;
- dependency graph;
- validation status;
- compatible model classes;
- last compile time;
- known warnings.

### Task Router

Maps user intent and app state to task type:

- explain page;
- summarize artifact;
- inspect artifact;
- recommend next step;
- propose action;
- preflight analysis;
- draft report language;
- evaluate claim;
- review causal readiness;
- explain decision workflow;
- persist result.

### Bundle Loader

Selects bundles required by the task:

- core;
- relevant domain;
- relevant policy;
- relevant operator/action rules;
- relevant claim/epistemic rules.

### Context Compiler

Assembles runtime prompt/context from:

- selected bundles;
- project state;
- current page;
- selected artifact;
- evidence package;
- user question;
- action policy;
- provider capability;
- token budget.

### Action Policy Gate

Determines:

- read-only;
- proposal allowed;
- approval required;
- execution allowed;
- execution blocked;
- persistence allowed;
- audit required.

### Model Adapter

Calls provider:

- local model;
- OpenAI-compatible endpoint;
- paid model;
- frontier model;
- fine-tuned model;
- Custom GPT export path.

### Runtime Observability

Records:

- task type;
- bundles loaded;
- bundle versions;
- provider/model;
- token estimate;
- latency;
- action policy decision;
- evidence included;
- response status;
- user rating;
- manual review outcome.

## Model Routing Architecture

Different models should receive different compiled contexts.

| Model class | Runtime strategy | Advantages | Disadvantages |
|---|---|---|---|
| Deterministic runtime | No LLM; rules/code only | Cheapest, reproducible, auditable | Cannot synthesize ambiguous narratives |
| Local/free model | Small bundles, concise project context, no sensitive data by default | Private, low marginal cost | Lower reasoning capacity, context limits |
| Paid API model | Medium bundles, richer evidence, more structured outputs | Better reliability and reasoning | Cost/privacy constraints |
| Frontier model | Full task bundle, richer evidence, high-risk review support | Best synthesis and ambiguity handling | Highest cost; must guard overreach |
| Fine-tuned model | Minimal runtime bundle, learned product idiom | Low prompt cost, consistent style | Update burden; risk of stale knowledge |
| Custom GPT | Compiled knowledge pack plus stable instructions | Useful author/product demo, portable | Upload/file limits; less runtime control |

### Routing Principles

1. Deterministic rules run before LLM calls.
2. Local/free models should receive compact, explicit instructions.
3. Paid/frontier models should receive richer evidence only when marginal value justifies cost.
4. Fine-tuning should not replace contracts or deterministic validation.
5. Custom GPT knowledge packs should be compiled from source, not hand-curated ad hoc.

## Fine-Tuning Strategy

Knowledge should be placed according to volatility and required explainability.

| Knowledge type | Best location | Reason |
|---|---|---|
| Current contracts | Deterministic code + compiled bundles | Must be inspectable and versioned |
| Safety/prohibited actions | Deterministic code + runtime policy | Must not depend on model memory |
| Product philosophy | Source docs + distilled bundles | Long-form source, compact runtime |
| Stable writing style | Fine-tune or system instructions | Useful but not authoritative |
| Domain examples | RAG or compiled examples | May grow and change |
| Project state | Runtime context | Always dynamic |
| Artifact evidence | Evidence routing/context compiler | Dynamic and task-specific |
| Epistemic gates | Deterministic policy + bundle explanation | Must be enforceable |
| Historical rationale | Knowledge Library/RAG | Valuable but not always needed |
| QA/invariant rules | Deterministic tests + developer bundle | Must be testable |

### Fine-Tuning Recommendation

Do not fine-tune early for correctness.

Use fine-tuning later for:

- product voice;
- response structure;
- repeated explanation patterns;
- classification assistance after labels exist;
- lower token overhead for stable behavior.

Do not put volatile contracts, action permissions, current policy, project state, or sensitive rules only in weights.

## Token Optimization Strategy

Token optimization should happen at multiple levels:

### Source Compression

Compile long-form docs into:

- definitions;
- invariants;
- rules;
- examples;
- counterexamples;
- task maps.

### Bundle Selection

Load only:

- core runtime;
- active task bundle;
- relevant policy bundle;
- relevant operator bundle;
- project context summary.

### Evidence Routing

Use existing Evidence Routing and Context Optimization:

- include only relevant artifacts;
- prefer summaries unless full evidence has high marginal information gain;
- downgrade expensive encodings when provider capability or task does not justify them.

### Model-Aware Context

Use provider capability:

- local model gets stricter, shorter, more explicit guidance;
- frontier model can receive more nuance;
- vision model receives image payload only when image evidence is useful;
- text-only model receives structured summaries instead.

### Runtime Caching

Cache:

- compiled bundles;
- source hashes;
- project summaries;
- artifact summaries;
- evidence plans;
- previous task context fingerprints.

### Explanation Without Repetition

The AI should cite bundle ids and rule ids rather than restating full philosophy every time.

## Knowledge Compilation and Existing Architecture

Knowledge Compilation sits above the current architecture. It does not replace it.

```text
Artifact Model
  -> Evidence Routing
  -> Context Optimization
  -> GenAI
```

becomes:

```text
Source Philosophy
  -> Knowledge Compiler
  -> Compiled Runtime Bundles
  -> Artifact Model
  -> Evidence Routing
  -> Context Optimization
  -> AI Runtime
  -> GenAI
```

The current architecture remains valid. The compiler makes it operational for AI.

## Epistemic Runtime Placement

Epistemic Runtime should be a compiled policy bundle plus underlying contracts.

It should contain:

- epistemic source classes;
- human assertion rules;
- intervention event rules;
- claim strength vocabulary;
- permitted/prohibited claim language;
- reasoning-risk taxonomy;
- abductive assessment guidance;
- cognitive-bias exposure language;
- organizational epistemic threat language;
- review/gate thresholds;
- GenAI boundaries;
- reporting requirements.

It should depend on:

- Core Runtime;
- Artifact Runtime;
- Evidence Runtime;
- Claim Runtime;
- Workflow Runtime for review/approval;
- Causal Runtime when causal claims are involved;
- Decision Runtime when recommendations are involved.

## Compiled Runtime Output Format

A future compiled bundle should be machine-readable and human-reviewable.

Suggested conceptual shape:

```yaml
bundle_id: epistemic_runtime
bundle_version: 0.1.0
source_refs:
  - docs/epistemic_integrity_architecture_review.md
  - docs/knowledge_compilation_runtime_architecture.md
dependencies:
  - core_runtime
  - evidence_runtime
  - claim_runtime
concepts:
  - Human Assertion
  - Human Intervention
  - Claim Governance
rules:
  - rule_id: epistemic.authority_is_not_truth
    severity: gate_when_material
    text: Authority may approve decisions but does not convert an unsupported claim into evidence.
prohibited:
  - infer dishonesty
  - assign hidden trust scores
  - suppress contradictory evidence
examples:
  - weak causal evidence should use cautious language
counterexamples:
  - "This proves the tactic worked" when only observational descriptive evidence exists
validation:
  required_sections: true
  source_hash: ...
```

## Runtime Bundle Loading Rules

Recommended loading rules:

1. Always load Core Runtime.
2. Load Operator Runtime only when app actions may be proposed.
3. Load Epistemic Runtime when a response may make or evaluate a claim.
4. Load Claim Runtime for reports, recommendations, summaries, causal interpretation, valuation, or executive language.
5. Load Causal Runtime for treatment/effect/causal language.
6. Load Decision Runtime for alternatives, recommendations, approvals, or implementation.
7. Load Workflow Runtime for review/approval/status tasks.
8. Load Developer Runtime only for implementation or QA tasks.
9. Load source citations only when the user asks for explanation, traceability, or audit.

## Conflict Handling

Compiled runtime must handle conflicts explicitly.

Conflict types:

- term conflict;
- policy conflict;
- version conflict;
- repository boundary conflict;
- stale document conflict;
- code-vs-doc conflict;
- example-vs-contract conflict.

Resolution hierarchy:

1. Current explicit architecture decision;
2. Current exported contract and validation code;
3. Current QA;
4. Current README and user guide;
5. Current architecture docs;
6. Source chapters and manifesto;
7. Historical notes.

If conflict cannot be resolved deterministically, the compiler should mark it:

- `requires_human_resolution`;
- `runtime_excluded`;
- `warning_only`.

## Validation Strategy

Compilation should produce QA.

Future `qa_knowledge_compilation_runtime()` should verify:

- source files discovered;
- source hashes recorded;
- concepts extracted;
- contract references valid;
- bundle dependencies acyclic;
- bundle size within budget;
- required core bundles exist;
- conflicting rules are marked;
- prohibited actions present;
- runtime manifest written;
- model routing map exists;
- generated bundles cite source refs;
- stale source causes recompile warning;
- runtime output can be loaded without app startup dependency on GenAI.

## Risks

### Risk: Over-Architecting Too Early

The architecture is powerful, but implementation should start small. The first compiler can be a deterministic markdown-to-bundle extractor. Avoid building a generic knowledge graph platform before there is runtime demand.

### Risk: Runtime Drift

Compiled bundles can become stale if source docs change. Use source hashes and validation.

### Risk: Hidden Prompt Governance

If rules live only in prompts, they are hard to test. Keep critical gates in deterministic code.

### Risk: Fine-Tune Staleness

Fine-tuned models can preserve obsolete behavior. Keep volatile policy in runtime bundles.

### Risk: Duplicate Governance

Knowledge Compilation must not duplicate Decision Workflow, GenAI Action Audit, Artifact Quality, or Causal Readiness. It should compile their rules into AI-operational form.

### Risk: Token-Optimized but Epistemically Weak

Small bundles may omit nuance. Use task risk tiers to decide when richer context is required.

### Risk: AI Treats Documentation as Authority Over Runtime State

Compiled philosophy must never override current project facts, evidence, or deterministic validation.

## Migration Strategy

### Step 1: Keep Source Docs Canonical

Do not remove or shorten source philosophy. The long-form source remains the truth archive.

### Step 2: Define Bundle Taxonomy

Accept the runtime bundle taxonomy and ownership matrix.

### Step 3: Create Static Manual Bundles

Before building a compiler, manually author one or two runtime bundles:

- Core Runtime;
- Epistemic Runtime.

Use them to learn the shape.

### Step 4: Add Deterministic Bundle Validation

Validate structure, dependencies, source refs, and size.

### Step 5: Add Context Compiler

Select bundles by task, page, provider, action policy, and risk.

### Step 6: Connect AI Runtime

Use bundles for Guide/GenAI explanations and registered action proposals.

### Step 7: Automate Compilation

Only after static bundles prove useful, build parser/extractor automation.

### Step 8: Add Observability

Record bundle ids, versions, token costs, output quality, user rating, and review outcomes.

### Step 9: Calibrate

Use observed outcomes to refine bundle loading and model routing.

## Long-Term Evolution

The long-term architecture likely evolves into:

```text
Knowledge Library
  -> Knowledge Compiler
  -> Runtime Bundle Registry
  -> Context Compiler
  -> AI Runtime
  -> Governed Actions
  -> Observability
  -> Learning
  -> Updated Source Knowledge
```

Eventually:

- bundle compilation can feed Custom GPT knowledge packs;
- fine-tuning datasets can be generated from approved runtime examples;
- source chapters can remain expansive while runtime bundles remain compact;
- app AI can behave consistently without loading the book every time;
- epistemic integrity can become an operational guardrail rather than a philosophy paragraph.

## Recommendation

Proceed with Knowledge Compilation as a first-class architectural concept.

Do not create a new repository yet.

Do not implement Epistemic Integrity contracts until the runtime placement is accepted.

Recommended immediate next step:

1. Accept the Source Philosophy -> Compiled Runtime -> Project Context -> Task Context -> LLM architecture.
2. Treat Epistemic Integrity as both portable contracts and compiled runtime policy.
3. Define the first two runtime bundles manually: Core Runtime and Epistemic Runtime.
4. Validate those bundles before automating compilation.
5. Keep all critical gates deterministic and use GenAI only for explanation, synthesis, and draft assistance.

The key architectural insight is that the future AI is not merely reading documentation. It is operating inside a governed analytical runtime. The documentation is source code for that runtime, but it must be compiled before it can scale.

## Phase 1 Implementation Status

The first bounded vertical slice is implemented in `R/knowledge_compilation_runtime.R` and documented in `docs/knowledge_compilation_runtime_phase1.md`.

Phase 1 covers:

- source registry
- curated canonical knowledge units
- conflict and dependency registries
- runtime bundle compilation
- initial task taxonomy
- task routing
- project-context digest
- compact AI context package
- model-tier profiles
- operator cards
- deterministic structured-output validation
- cold-start competency and compression QA

The implementation intentionally remains curated and deterministic. LLM-assisted source extraction, semantic search, vector stores, tier-specific bundle variants, and autonomous execution remain deferred.
