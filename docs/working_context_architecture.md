# Working Context Architecture

Product Experience Runtime Phase 5 introduces Working Contexts.

Working Context Architecture Phase 2 deepened the first context by adding inline evidence operations. Evidence Review is no longer only a composed surface over existing modules; it can now complete a bounded evidence-review workflow inside the context.

Working Context Architecture Phase 3 extracts the reusable primitive. Evidence Review is now the reference implementation of a broader Working Context Framework.

The core product decision is:

```text
The architecture remains capability-first.
The product becomes task-first.
```

Analytics Workstation should no longer ask users to assemble meaningful work by jumping among powerful modules. The user should work inside a context that contains the tools, evidence, status, and next actions needed for the current job.

## Problem

Two extremes have both failed in different ways:

- Simple navigation can make functionality easy to find while breaking task continuity.
- Capability proximity can keep powerful modules nearby while breaking cognitive continuity.

The synthesis is Working Contexts.

## Product Hierarchy

```text
Relationship Shell
-> Current Working Context
-> Progressive Depth
-> Related Tasks
-> Advanced Capability
-> Architecture
```

The Relationship Shell determines how the product begins. The Working Context determines how meaningful work occurs once the user begins.

## Runtime Flow

```text
Intent
-> Working Context
-> Relevant Capability
-> Evidence
-> Decision
```

The runtime should compile intent into a focused working set, not into a list of application pages.

## Framework Runtime Stack

The canonical framework stack is:

```text
Relationship Runtime
-> Working Context Runtime
-> Context Composition
-> Progressive Depth
-> Context Services
-> Context Transitions
-> Canonical Workflow
```

The Relationship Runtime determines how the user is oriented to the project. The Working Context Runtime selects the coherent work environment. Context Composition binds references, services, controls, depth, transitions, replay, review, and campaigns into a compiled context.

This is the architectural pivot: future contexts should be composed, not invented from scratch.

## First Production Context

Phase 5 implements one context:

```text
Evidence Review / Decision Evaluation
```

This context is the template for future contexts.

It contains:

- Business Question
- Decision Context
- Relevant Artifacts
- Cross-Artifact Synthesis
- Contradictions
- Evidence Sufficiency
- Valuation Summary
- Supported Next Action
- Workflow Status
- Current Draft
- Mission Summary

The user should be able to remain inside this context long enough to review evidence, understand sufficiency, see contradictions, inspect valuation and workflow status, and choose a next action.

Phase 2 extends the lifecycle to:

```text
Business Question
-> Evidence Binder
-> Artifact Inspection
-> Cross-Artifact Synthesis
-> Contradiction Review
-> Sufficiency Assessment
-> Valuation Interpretation
-> Supported Next Action
-> Governed Draft
-> Human Confirmation
-> Persisted Result
```

The context should prove real state transition, not tab choreography.

## Inline Operation Inventory

Each Evidence Review element is classified before it is made interactive:

- informative only: context header, business question, Mission Summary, architecture metadata;
- navigational: adjacent task links to Artifact Studio, Semantic Intelligence, Mission Control, Knowledge Library;
- executable through existing handler: binder operations, artifact inspection, synthesis replay, contradiction review, sufficiency assessment, valuation interpretation, ranked next actions, governed draft persistence;
- executable but not yet exposed here: omitted-artifact relationship editing and full evidence retrieval;
- inappropriate for inline execution: autonomous approval, autonomous execution, silent evidence deletion, and unsupported artifact mutation.

This inventory prevents the context from becoming either a passive dashboard or an unsafe shortcut layer.

## Canonical Context State

Evidence Review persists a small reference-only context state:

- project id;
- business-question id;
- decision-context id;
- selected artifact ids;
- evidence-binder id;
- synthesis id;
- sufficiency state;
- selected next-action id;
- draft id;
- workflow stage;
- stale-state indicators;
- current depth level;
- open contradiction id;
- last meaningful action.

The state references authoritative objects. It does not duplicate artifacts, tables, plots, claims, valuation objects, or workflow records.

## Inline Evidence Operations

The Evidence Binder is a bounded working set over artifact references. It exposes included, omitted, stale, superseded, and contradictory artifacts. Artifact inspection returns progressive detail:

1. title, evidence type, key finding, readiness, applicability, limitations, contradiction state, freshness;
2. claims and diagnostics;
3. lineage and metadata;
4. full artifact reference.

Cross-artifact synthesis compiles cited claims, unresolved gaps, excluded evidence, and prohibited claims. Prohibited claims protect against overreach, especially causal certainty or decision-ready language when the supporting evidence is only exploratory.

Contradictions remain first-class. They show involved artifacts, nature of disagreement, scope differences, estimand differences, timing differences, supersession, consequence, unresolved question, and review status.

## Sufficiency and Valuation

Sufficiency is always specific to a proposed action. A context can have enough evidence to inspect, draft, request review, recommend, or make a decision-use claim. These are different states.

Valuation interpretation is contextual. Evidence Review does not recreate the full valuation workbench. It surfaces alternatives versus baseline, expected impact, materiality, risk, optionality, guardrails, missing inputs, and recommendation status where the valuation service already provides them.

## Governed Draft Flow

The bounded mutation path is:

```text
proposal
-> preview
-> validation
-> explicit human confirmation
-> persistence
-> artifact registration
-> audit record
```

Evidence Review may persist only an authorized draft artifact after confirmation. It must not silently alter source evidence, suppress contradictions, approve decisions, execute actions, or bypass existing governance.

## Progressive Depth

Working Context depth now follows the canonical six-level model:

1. Orientation
2. Working Set
3. Evidence
4. Decision
5. Diagnostics
6. Architecture

Each level expands naturally. Architecture remains available, but it should not interrupt normal work.

The framework owns the depth model. Individual contexts map their objects and controls into these levels.

## Capability Exposure Rules

Each capability is mapped as:

- Primary
- Adjacent
- Contextual
- Advanced
- Architectural
- Developer

Only Primary and Adjacent capabilities appear initially.

For Evidence Review:

- Primary: question, decision context, artifacts, synthesis, contradictions, sufficiency, valuation summary, next action, workflow status, current draft, mission summary.
- Adjacent: Artifact Studio, Decision Valuation, Decision Workflow.
- Contextual: Mission Control, Knowledge Library.
- Advanced: Code Runner, AI Runtime.
- Architectural: architecture docs.
- Developer: QA and Product Experience Lab.

## Working Set Philosophy

The working set is the subset of capability needed for the current job.

It is not:

- the whole app;
- a shortcut dashboard;
- a module directory;
- a hidden automation system.

It is a workbench. The tools for the job are within reach, while the rest of the building remains available but quiet.

## Semantic Interaction Principle

Working Contexts now inherit the governing UX rule:

```text
Maximize semantic cognition.
Minimize syntactic cognition.
```

A Working Context should spend the user's attention on the meaning of the work:

- What question is being answered?
- What evidence exists?
- What is missing?
- What contradicts?
- What can be safely concluded?
- What tradeoff matters?
- What decision is justified?
- What should happen next?

It should spend as little attention as possible on syntax:

- where a feature lives;
- which tab to open;
- which internal state name is current;
- which implementation component owns the action;
- which refresh, compile, or persistence step is mechanically required.

This does not mean controls disappear prematurely. It means controls earn their visibility by improving analytical understanding or preserving explicit human agency.

For future contexts, every visible element should be classified as:

- Semantic;
- Syntactic;
- Mixed.

Syntactic and mixed elements should be challenged:

- Can this disappear?
- Can this become automatic?
- Can this become contextual?
- Can this become inferred?
- Can this become progressive?
- Can this become a consequence rather than an action?

The current deterministic audit lives in:

```r
working_context_semantic_syntax_audit()
```

The current QA entry point is:

```r
qa_semantic_interaction_design()
```

## Semantic Continuation

Semantic interaction reduces the amount of product syntax the user must think about. Semantic Continuation protects the user's train of thought as work moves between contexts.

The rule is:

```text
Navigation becomes a consequence, not a prerequisite.
```

A Working Context should not first ask:

```text
Where would you like to go?
```

It should first ask:

```text
What is the next meaningful thought?
```

The current reasoning graph is:

```text
Business Question
-> Current Evidence
-> Current Answer
-> Current Decision
-> Current Recommendation
-> Governed Review
-> Implementation
-> Outcome Learning
```

The framework now treats transitions as thought-preservation seams. This is the thought preservation rule for context movement: a handoff should carry the current question, answer, decision, recommendation, evidence references, contradictions, uncertainty, and next meaningful thought where applicable. It should not carry raw artifacts, unsupported recommendations, stale decisions, hidden mutations, or approval as proof of outcome quality.

The current deterministic contracts are:

```r
working_context_reasoning_graph()
working_context_semantic_continuation_audit()
working_context_thought_preservation_contract()
working_context_handoff_principles()
qa_semantic_continuation_design()
```

## Canonical Context Contract

Every Working Context must define:

- purpose;
- current task;
- primary objects;
- primary evidence;
- primary controls;
- adjacent tasks;
- progressive depth;
- Mission signals;
- AI actions;
- supported mutations;
- return paths;
- replay;
- founder review;
- campaigns.

No duplicated fields should be introduced. Context-specific composition supplies values for the shared contract.

## Context Lifecycle

The framework recognizes these lifecycle states:

- available;
- selected;
- composed;
- active;
- suspended;
- resumed;
- completed;
- archived;
- blocked.

Suspended and resumed states are important because adjacent work should not abandon the original task context.

## Context State

All contexts use reference-only state. The state contract is organized around:

- selection;
- workflow;
- evidence;
- drafts;
- Mission;
- persistence;
- return;
- replay.

Context state may store ids, selected references, workflow stage, stale indicators, draft id, return target, and replay step. It may not copy canonical artifacts, duplicate business objects, hide mutations, or store unmanaged payloads.

## Context Services

The framework defines reusable service categories:

- Evidence;
- Valuation;
- Workflow;
- Mission;
- AI;
- Mutation;
- Artifacts;
- Knowledge;
- Replay;
- Campaigns.

Each context consumes canonical services through thin adapters. The context should not own analytical logic that belongs to the artifact model, valuation service, workflow service, mutation governance, Knowledge Compilation Runtime, GenAI service, Product Experience Runtime, or Mission Control.

## Navigation Philosophy

The goal is not to eliminate navigation.

The goal is to minimize context switching.

Navigation should lead to related work, not to the entire application. Evidence Review naturally leads to:

- Artifact inspection;
- valuation;
- decision review;
- workflow status;
- knowledge/learning when requested.

It should not initially lead to Code Runner, QA, AI Runtime, or developer surfaces.

## Context Transitions

Transitions are framework-owned contracts, not arbitrary tab jumps.

Each transition should define:

- source context;
- adjacent task;
- target surface;
- transition type;
- reason;
- preserved state;
- return path.

The current implementation records the source, target, type, and reason. Preserved-state and breadcrumb rendering are the next refinement area.

## Mission Control

Mission Control becomes context-aware.

Inside Evidence Review, the user sees a Mission Summary:

- artifacts;
- collector;
- decision;
- valuation;
- workflow.

Full Mission Control remains available when operational detail is needed.

## AI

AI should support the current context.

Inside Evidence Review, appropriate AI actions are:

- explain an artifact;
- explain a contradiction;
- summarize the binder;
- identify missing evidence;
- compare scoped alternatives;
- explain evidence sufficiency;
- draft a review request;
- propose a bounded next action.

AI should not represent the whole application or become a general-purpose chat surface in this context.

AI must use runtime bundles, citations, claim governance, and provider qualification checks. It should not be required for ordinary navigation, expanding deterministic details, or opening existing objects.

## Product Experience Lab

The Product Experience Lab now exposes:

- Working Context preview;
- Progressive depth preview;
- Capability exposure map;
- Founder review template;
- Replay contract;
- Working Context campaigns;
- Final assessment.

This makes Working Contexts measurable and reviewable instead of merely visual.

Phase 3 adds framework-level QA so Product Experience can evaluate contexts by registry, contract, state, composition, transitions, replay, persistence, review, campaigns, and documentation rather than by page-specific checks alone.

## Founder Review

Founder review should ask:

- Did I remain focused?
- Did I know where I was?
- Did I know what mattered?
- Did I know what came next?
- What unnecessary capability appeared?
- What capability was missing?
- Did transitions feel natural?
- Did evidence hierarchy feel clear?

## Campaigns

Working Context campaigns target:

- too many adjacent tasks;
- wrong information priority;
- too much architecture;
- too much navigation;
- poor transitions;
- weak evidence hierarchy.
- weak artifact inspection;
- unclear contradiction;
- insufficient inline action;
- valuation disconnected from evidence;
- AI too visible;
- confirmation boundary unclear;
- state transition not visible.

These are context campaigns, not module campaigns.

The framework version of campaigns adds:

- priority;
- severity;
- dependencies;
- replay comparison metric.

This allows future contexts to produce comparable improvement work instead of one-off UX notes.

## Template Rules for Future Contexts

Future Working Contexts should inherit these rules:

- context state stores references and workflow state only;
- authoritative services remain authoritative;
- context adapters are thin;
- inline operations use existing contracts where available;
- unsupported actions remain visible as unavailable or adjacent, not fabricated;
- AI assists reasoning and drafting, not silent mutation;
- every confirmed mutation creates a visible state change and an audit trail;
- progressive depth starts at orientation and working evidence, not implementation details.
- replay proves meaningful state transition, not only navigation;
- founder review and campaign generation are required contract pieces.

## Future Context Creation Sequence

To add a future Working Context:

1. Register the context with purpose and current task.
2. Fill the canonical context contract.
3. Define reference-only state.
4. Map capabilities by exposure level.
5. Map objects and controls to progressive depth.
6. Bind canonical services through adapters.
7. Define adjacent transitions and return paths.
8. Define contextual AI actions.
9. Define supported mutations and confirmation boundaries.
10. Add deterministic replay.
11. Add founder review prompts and campaigns.
12. Pass framework QA.

The architecture goal is that future contexts require context-specific composition, not architectural invention.

## Open Questions

The largest remaining question is how much of Decision Management should be brought into Evidence Review before creating a second context.

The current recommendation is:

```text
Next improvement: polish Evidence Review transitions and valuation refresh before creating Decision Management.
```

Reason: Evidence Review is now the template, but recordings should validate whether users can complete the full evidence-review path without confusion before the pattern is copied.

Phase 3 adds a second question:

```text
Which future context should be implemented first once the framework has stabilized?
```

The likely answer remains Decision Management, because it naturally follows Evidence Review into proposal, review, approval, implementation, outcome, and learning. The caution is that it should be implemented as a composition of the framework, not as another bespoke page.

## Completion Criterion

This phase succeeds when a user can remain inside one coherent Working Context for an extended period, performing multiple related tasks without repeatedly navigating the application or being overwhelmed by unrelated capabilities.
