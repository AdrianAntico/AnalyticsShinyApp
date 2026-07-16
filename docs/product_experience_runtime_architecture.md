# Product Experience Runtime Architecture

## Purpose

The Product Experience Runtime separates how humans encounter Analytics Workstation from how the analytical architecture is implemented.

The application has one architecture:

```text
Project
-> Data
-> Workflow
-> Artifacts
-> Collector
-> Evidence
-> Decision
-> Governance
-> Learning
```

The runtime compiles different experiences over that same architecture:

```text
User
-> Intent
-> Product Experience Runtime
-> Compiled Experience
-> Golden Workflow
-> Evidence
-> Decision
```

The runtime is the product-design analogue of the Knowledge Compilation Runtime. Knowledge Compilation makes AI guidance compact and deterministic. Product Experience Runtime makes human-facing UX experimentation deterministic, reversible, and evidence-driven.

## Non-Goals

The Product Experience Runtime does not:

- redesign the app shell
- fork business logic
- change analytics
- change evidence generation
- choose a winning prototype
- create a second workflow engine
- create a separate architecture
- hide governance from users who need it
- optimize for marketing beauty

It compiles presentation, routing, visibility, and emphasis.

## Core Contract

The runtime compiles:

```text
Intent
-> Workflow
-> Navigation
-> Information exposure
-> AI visibility
-> Visual emphasis
-> Progressive disclosure
```

The runtime never changes:

```text
Business logic
Analytical functions
Evidence content
Artifact contracts
Collector behavior
Decision governance
Storage contracts
GenAI action safety
```

## Prototype Registry

`experience_prototype_registry()` defines supported product philosophies.

Initial prototypes:

| Prototype | Philosophy | Entry Prompt |
| --- | --- | --- |
| Current Golden Workflow | Capability-aware benchmark | What should we do next? |
| Prototype A: Intent-first | User intent compiles the experience | What are you trying to accomplish? |
| Prototype B: Business Question first | Business question compiles the experience | What business question are you trying to answer? |

Every prototype declares:

- entry prompt
- entry surface
- default intent
- Mission Control behavior
- AI visibility behavior
- visual emphasis
- shared workflow id
- prototype status

All initial prototypes share the same Golden Workflow. This preserves experimental control.

## Intent Routing

`experience_intent_registry()` defines user intents:

- analyze
- decide
- review
- continue
- explore
- learn

`experience_route_intent()` deterministically maps intent plus prototype plus project state to a starting surface and next action.

Examples:

- `decide` starts in Guide.
- `review` starts in Artifact Studio when artifacts exist.
- `learn` starts in Knowledge Library.

Intent routing replaces static exposure with context-sensitive experience routing.

## Experience Compiler

`experience_compiler()` accepts:

- prototype
- intent
- workflow
- user state
- current project
- current decision
- current artifacts

It returns a `compiled_experience` object containing:

- prototype
- intent route
- workflow identity
- navigation plan
- information plan
- AI plan
- progressive experience plan
- capability map
- immediate capabilities
- hidden capabilities
- controls
- metrics seed

The compiled experience is not compiled UI. It is the deterministic experience contract that UI, replay, QA, and review can consume.

## Information Exposure Runtime

The runtime visibility levels are:

- immediate
- deferred
- contextual
- advanced
- architectural
- developer

Every visible or hidden component must include a justification.

The point is not to hide power. The point is to stop charging the user attention for details that do not advance the current intent.

## Progressive Experience

`experience_progressive_runtime()` defines the ladder:

```text
Orientation
-> Workflow
-> Evidence
-> Decision
-> Diagnostics
-> Architecture
```

The runtime decides which level is active. The app should avoid forcing architecture-level concepts into orientation-level moments.

## AI Visibility

AI visibility becomes runtime behavior.

The workflow should not decide that AI must appear. The runtime should decide whether AI is useful for the current experience.

Default policy:

- AI is hidden for deterministic entry choices.
- AI may appear for evidence synthesis.
- AI may appear for reasoning, uncertainty, and guardrails.
- AI diagnostics remain advanced or developer-facing.
- Deterministic UI owns obvious navigation.

This preserves the rule:

```text
If the application already knows the answer, do not spend AI on it.
```

## Mission Control Behavior

Mission Control behavior is prototype-dependent.

Initial classifications:

- Current Golden Workflow: workspace status
- Intent-first: contextual operating layer
- Business Question first: decision status layer

This leaves open the Phase 8 research question:

```text
Is Mission Control a module, or is it the operating system state layer?
```

The runtime does not answer permanently. It makes the behavior explicit and comparable.

## Comparison

`experience_compare_compiled_prototypes()` compiles baseline, intent-first, and business-question-first experiences through the same contract.

The comparison includes:

- entry prompt
- start surface
- time to first meaningful action estimate
- estimated clicks
- navigation depth
- AI interactions
- cognitive load estimate
- visible components
- hidden components
- comparison note

The comparison intentionally does not declare a winner. A prototype becomes preferred only after replay and founder review evidence supports that conclusion.

## Founder Review

Phase 2 adds an executable comparison package for founder review.

The comparison is deliberately controlled:

- same synthetic world
- same Golden Workflow
- same evidence content
- same decision
- same artifact and governance contracts
- different entry experience, routing emphasis, and information exposure

The supported Phase 2 entry experiences are:

| Prototype | First Interaction | Purpose |
| --- | --- | --- |
| Current | What should we do next? | Preserve the benchmark for regression and continuity. |
| Prototype A | What are you trying to accomplish? | Test whether intent-first orientation reduces cold-start friction. |
| Prototype B | What business question are you trying to answer? | Test whether business-question-first orientation improves story clarity and investor comprehension. |

Prototype A exposes these immediate choices:

- Analyze data
- Make a decision
- Review evidence
- Continue previous work
- Explore
- Learn

Prototype B starts with a business question and then compiles the same workflow into evidence, decision, diagnostics, and architecture layers.

## Phase 2 Replay Packages

`experience_prototype_replay_package()` creates a deterministic package for one prototype.

`experience_run_all_prototype_replays()` creates Current, A, and B packages together.

Each package records:

- prototype id
- entry experience
- compiled experience
- shared Golden Workflow
- replay events
- comparison metrics
- founder review prompts
- Mission Control role
- AI visibility policy
- convergence controls
- manifest path
- founder review package path

Fixture replay packages do not fabricate screenshots, video, or trace. Browser replay remains a separate validation layer.

## Phase 2 Metrics

`experience_compare_prototype_replays()` compares:

- time to first action
- time to first evidence
- time to first understanding
- clicks
- navigation depth
- context switches
- backtracking
- AI interactions
- visible concepts
- reading burden
- founder preference placeholder
- replay quality

These values are deterministic compiled estimates until browser replay or founder review supplies observed evidence.

## Phase 2 Founder Review

`experience_founder_review_package()` asks the reviewer to score each prototype on:

- strengths
- weaknesses
- delight
- confusion
- trust
- recommendation
- open questions

The review package is intentionally comparative. It should be completed after seeing the same workflow under Current, A, and B.

## Phase 2 Recommendation Policy

The runtime must not choose a final experience during Phase 2.

The conservative recommendation is:

```text
Run Current, A, and B against the same Golden Workflow.
Review the unedited replays.
Score the founder review package.
Only then select, combine, or reject an entry experience.
```

Current hypothesis:

- Intent-first is likely stronger for general onboarding.
- Business-question-first is likely stronger for decision narrative and investor demonstration.
- Mission Control should act as a supporting operating layer rather than the first screen.
- AI should be contextual, not forced at entry.
- A decision-first prototype remains a plausible future candidate, but should wait until A/B failure modes are visible.

## Product Experience Lab

Phase 2 extends the Product Experience Lab with:

- prototype selector
- intent selector
- prototype entry experience
- prototype replay package
- replay comparison
- founder review package
- prototype-specific campaigns
- conservative recommendation

This keeps product experience research inside the app without converting it into normal user-facing workflow.

## Phase 3 Browser-Recorded Prototype Trial

Phase 3 changes the objective from product improvement to product philosophy selection.

The prototypes are treated as competing scientific hypotheses:

| Replay | Prototype | Hypothesis |
| --- | --- | --- |
| Replay_Current | Current Experience | The current experience may preserve capability context but expose architecture too early. |
| Replay_Intent | Intent-First | Intent-first may reduce cold-start ambiguity by asking what the user wants to accomplish. |
| Replay_BusinessQuestion | Business Question First | Business-question-first may reveal product identity fastest by starting with the decision problem. |

The controlled constants are:

- synthetic world
- data
- AI mode
- evidence
- Golden Workflow
- final decision
- Mission Control availability
- viewport
- browser
- pacing profile
- narration profile
- recording quality

Allowed differences are limited to:

```text
Entry
-> Navigation
-> Information hierarchy
-> Progressive disclosure
```

The phase succeeds when a human can watch all three recordings and meaningfully compare the experiences.

## Phase 3 Browser Replay Contract

`experience_run_phase3_browser_trial()` runs the three replay hypotheses through the Playwright recorder.

Each replay should produce:

- WebM
- screenshots
- trace
- execution report
- review package
- metrics

Each replay is validated for:

- expected page
- expected state
- expected workflow
- expected artifacts
- expected transitions
- expected AI
- expected Mission Control
- expected final draft
- expected completion

Browser replay is intentionally distinct from fixture replay. Fixture replay validates contracts. Browser replay produces product-experience evidence.

## Phase 3 Metrics

Phase 3 records:

- time to first action
- time to first evidence
- time to first insight
- clicks
- navigation depth
- context switches
- backtracking
- reading burden
- visible concepts
- AI interactions
- workflow duration
- completion
- Mission Control usage

The cognitive-load layer estimates:

- initial overload
- progressive understanding
- information density
- decision confidence
- cognitive-load spike

## Phase 3 Product Story Assessment

For each replay the runtime records when the viewer should understand what Analytics Workstation is.

The key question is not:

```text
What module did the user open?
```

The key question is:

```text
When does the viewer understand the product?
```

## Phase 3 AI Assessment

AI is evaluated on:

- visibility
- naturalness
- necessity
- deterministic replacement possibility

If deterministic UX can replace an AI interaction, the replay should flag it.

## Phase 3 Founder Review

The founder review package asks for:

- understanding
- trust
- confusion
- delight
- evidence
- workflow
- AI
- visual hierarchy
- navigation
- recommendation
- approval

The review is intentionally structured but not automated. Product philosophy selection requires human experience judgment.

## Phase 3 Final Assessment

The final assessment must answer:

- Which prototype minimizes cognitive load?
- Which reveals the product identity fastest?
- Which best hides architectural complexity?
- Which best prepares the Golden Workflow?
- Which produces the strongest trust?
- Which best balances simplicity and capability?
- Should either challenger replace the current experience?
- Should a third prototype now be explored?

The runtime may provide preliminary metric-based answers, but it must not choose a winner without replay review and founder evidence.

`experience_founder_review_comparison_template()` creates prototype-specific review rows for:

- first minute summary
- first meaningful action
- moment of delight
- moment of confusion
- architecture leak
- AI necessity
- evidence clarity
- product identity clarity
- confidence change
- preference rank
- recommendation

This keeps founder review structured enough to become product evidence.

## Prototype Campaigns

`experience_prototype_campaigns()` scopes campaigns to prototypes:

- baseline reproducibility
- intent-first orientation risk
- business-question-first story risk

Campaigns must remain prototype-specific unless a shared component issue is proven by replay or review.

## Product Experience Lab Integration

The Product Experience Lab now exposes:

- Experience Runtime
- Compiled Experience
- Runtime Comparison
- Runtime Campaigns

This is a research and developer surface. It does not change normal user workflows.

## QA

`qa_product_experience_runtime()` verifies:

- prototype registry
- shared Golden Workflow
- intent registry
- capability map
- visibility levels
- runtime service result
- compiler contract
- intent routing
- architecture/workflow controls
- visibility justification
- AI runtime behavior
- progressive runtime
- comparison contract
- founder review template
- campaign scope
- no premature winner
- documentation

## Future Work

Next implementation phases may add:

- browser replay A/B runs
- side-by-side visual replay scorecards
- observed founder preference capture
- observed time/click/scroll metrics from browser replay
- prototype-specific campaign persistence
- a decision-first prototype if A/B replay exposes the need

Do not add these until the runtime contract remains green under deterministic QA.

## Completion Criterion

Product Experience Runtime Phase 2 is complete when Analytics Workstation has:

```text
One architecture
One product
Multiple compiled experiences
Comparable replay packages
```

The runtime should make future product philosophy experiments inexpensive, deterministic, evidence-driven, and reversible.

## Product Experience Runtime Phase 4

Phase 4 introduces the Relationship Runtime.

The goal is not to optimize the app. The goal is to optimize the human's first hour with the product.

The runtime now distinguishes how Analytics Workstation should begin for:

- New User
- Returning User
- Current Project
- Resume Workflow
- Explore
- Learn

This is not personalization, telemetry, machine learning, adaptive UI, or a production shell replacement. It is a deterministic preview contract for comparing first-hour product experiences.

## Relationship Runtime Architecture

The Relationship Runtime sits before workflow routing.

```text
Relationship State
-> Current Intent
-> Progressive Experience Shell
-> Workflow
-> Evidence
-> Decision
-> Diagnostics
-> Architecture
```

Its responsibility is to determine what the product should say first, what should remain hidden, and what should become visible only after intent, evidence, or risk makes it relevant.

## Progressive Experience Shell

The shell follows this progression:

```text
Orientation
-> Question
-> Evidence
-> Understanding
-> Decision
-> Diagnostics
-> Architecture
```

Only immediate information should be visible at the start.

The initial information hierarchy is:

- Immediate
- Helpful
- Contextual
- Deferred
- Advanced
- Architectural
- Developer

Immediate information answers:

- What is this?
- Why should I care?
- What can I accomplish?
- What should I do first?

Developer, architectural, advanced, and diagnostic surfaces should not be part of the first encounter unless the user explicitly chooses that path.

## New User Experience

The recommended first-time opening is:

> Tell me what decision or question brought you here. I will help turn it into evidence, uncertainty, and a next action.

The shell should explain the product in one sentence, ask for intent, and offer one first action. It should not begin with module catalogs, QA surfaces, generated code, or architecture terminology.

## Returning User Experience

The recommended returning-user opening is:

> Here is what changed, what needs attention, where you left off, and the best next step.

Returning users need continuity before exploration. The first screen should summarize changed artifacts, attention items, resumable workflows, and one deterministic next action.

## Mission Control Policy

Mission Control should be summarized inside the Relationship Shell and opened as a full workspace after orientation.

For a new user, Mission Control detail is too operational as the first full page. For a returning user, a compact Mission Control summary is valuable immediately because it answers what changed and what needs attention.

Full Mission Control should open when:

- failures exist;
- approvals are waiting;
- jobs are running;
- workflows are blocked;
- the user explicitly wants operational status.

## AI Policy

AI should not greet the user by default.

The deterministic shell should own the greeting, orientation, visibility hierarchy, and simple next-step logic. AI should appear after intent or evidence creates a real reasoning need.

AI becomes useful when the user asks:

- Why is this recommended?
- What does this evidence imply?
- What is missing?
- What should I do next and why?

AI should not replace deterministic orientation, navigation, status display, or basic product explanation.

## Logging Philosophy

Phase 4 documents a logging ontology but does not implement logging.

Future logging may observe:

- first impression;
- trust;
- momentum;
- curiosity;
- confidence;
- overwhelm;
- understanding;
- desired next action;
- confusion;
- exit.

These signals should exist only to improve the relationship between user and product. They should not become hidden credibility scores, opaque personalization, or adaptive behavior without deterministic review gates.

## Experience Memory

Phase 4 documents future distinctions:

- first use;
- returning user;
- mastery;
- current workflow;
- current project;
- current intent.

No experience memory is implemented in this phase. The distinction is preserved so future work can resume context without pretending to understand the user.

## Product Experience Lab Integration

The Product Experience Lab now exposes:

- Relationship Runtime preview
- New User shell preview
- Returning User shell behavior
- Current Project / Resume / Explore / Learn previews
- Relationship comparison
- Founder review template
- Relationship campaigns

This remains a developer and product-research surface.

## Relationship Campaigns

Phase 4 campaigns are relationship campaigns, not module campaigns.

They evaluate questions such as:

- Does the new-user shell reduce overwhelm?
- Does the returning-user shell improve continuity?
- Should Mission Control be compact status first or a full starting page?
- Does AI feel more natural when it appears after intent and evidence?

## Open Research Questions

The largest unanswered question is whether the first-hour shell should begin with intent, business question, or decision context.

The current recommendation is conservative:

- do not replace production yet;
- preview deterministic shells;
- compare relationship states;
- use founder review before selecting a canonical entry experience.

## Phase 4 QA

`qa_product_experience_relationship_runtime()` verifies:

- relationship states;
- new-user and returning-user questions;
- visibility hierarchy;
- initial shell visibility;
- progressive disclosure;
- experience layer order;
- preview-only runtime behavior;
- Mission Control policy;
- AI policy;
- design-only logging ontology;
- documented future experience memory;
- founder review dimensions;
- relationship campaign scope;
- direct final assessment answers;
- documentation.

## Product Experience Runtime Phase 5

Phase 5 introduces Working Contexts.

Relationship Runtime answers:

```text
How should the product begin?
```

Working Contexts answer:

```text
How should meaningful work occur once the user begins?
```

The first production Working Context is:

```text
Evidence Review / Decision Evaluation
```

It composes business question, decision context, artifacts, cross-artifact synthesis, contradictions, evidence sufficiency, valuation summary, supported next action, workflow status, current draft, and mission summary into one focused workspace.

This is the bridge between simple navigation and broad capability:

```text
Relationship Shell
-> Current Working Context
-> Progressive Depth
-> Related Tasks
-> Advanced Capability
-> Architecture
```

The architecture remains capability-first. The product becomes task-first.

Details live in:

```text
docs/working_context_architecture.md
```

## Product Geography Laboratory Phase 1

Product Geography Laboratory Phase 1 adds a spatial information architecture research layer.

Relationship Runtime asks:

```text
How should the product begin?
```

Working Context Runtime asks:

```text
How should meaningful work occur?
```

Product Geography asks:

```text
Where should product concepts live so the user can form a durable mental map?
```

The lab compares several candidate geographies without selecting a final winner:

- Common Geography;
- Working Context House;
- Evidence-Centered Studio;
- Mission Control Hallway;
- Decision Theater.

All candidates preserve the same underlying architecture, services, evidence contracts, runtime contracts, workflows, and AI governance. They change only organization, visibility, navigation hierarchy, grouping, and progressive disclosure.

The Product Experience Lab now exposes:

- geography selector;
- prototype summary;
- layout zones;
- navigation map;
- comparison metrics;
- founder review prompts;
- geography campaigns;
- direct preliminary assessment.

Details live in:

```text
docs/product_geography_lab.md
```

## Spatial Information Architecture Phase 2

Phase 2 makes the leading product geographies clickable inside the Product Experience Lab.

The phase compares:

- Working Context House;
- Evidence-Centered Studio;
- Mission Control Hallway.

Each prototype uses identical fixture state. The prototypes differ in spatial organization, focal object, action placement, Guide/help placement, navigation, progressive disclosure, and developer-surface treatment.

The lab now includes:

- clickable route buttons;
- representative page selector;
- primary-action placement selector;
- Guide/help placement selector;
- page layout previews;
- layout-zone system;
- screenshot-based layout audit;
- Product Geography Constitution;
- founder resonance framework;
- synthesis candidate;
- rejected-layout log;
- Phase 2 campaigns.

Phase 2 still does not replace the production shell or choose a final geography.

Details live in:

```text
docs/product_geography_phase2.md
```
