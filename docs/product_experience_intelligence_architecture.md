# Product Experience Intelligence Architecture

## Purpose

Product Experience Intelligence turns the experience of using Analytics Workstation into evidence.

The goal is not to create a polished marketing demo. The goal is to create a deterministic product-experience laboratory that can repeatedly answer:

> What is it actually like to use the workstation for a specific analytical workflow?

The lifecycle is:

```text
Canonical World
-> Deterministic Project
-> Scenario
-> Automated Application Operation
-> Screenshots / Video / Trace
-> Human Review
-> Experience Findings
-> Remediation Campaign
-> Product Improvement
```

Recorded friction is not a failure of the system. It is the evidence the system exists to preserve.

## Architecture Decision

Phase 1 selects **Playwright** as the single browser automation and recording path for future recorded product-experience runs.

Rationale:

- Browser-level workflow evidence requires launch, navigation, validation, screenshots, video, traces, and clean shutdown.
- The app already has production artifact screenshot helpers, but those helpers are not a full guided product walkthrough system.
- No maintained in-app guided tour system was found that should be expanded instead.
- Playwright is a better fit for deterministic end-to-end product recording than a duplicate Shiny-specific tour framework.

Phase 1 also provides a deterministic fixture runner. The fixture runner validates contracts, metrics, review artifacts, and campaign seeds. It does **not** fabricate videos, screenshots, or traces.

If the Playwright runtime is unavailable, the recorder reports that status explicitly.

## Browser Runtime Provisioning

Phase 2 adds repository-local browser runtime provisioning for recorded Golden Workflow runs.

The runtime lifecycle is:

```text
Discover
-> Validate
-> Repair / Provision
-> Retry
-> Replay
```

Discovery checks:

- repo-local Node runtime under `runtime/product-experience/node`
- npm and npx from the same runtime
- Playwright package installation
- Chromium browser availability
- `package.json` and `package-lock.json`
- prior screenshots, videos, traces, and execution reports

Validation launches Chromium, performs a minimal DOM interaction, captures a screenshot, and shuts down the browser. Provisioning downloads a pinned Node runtime and installs the pinned Playwright dependency into `runtime/product-experience`.

Generated runtime files and recordings remain runtime/media artifacts. They are not source files:

- `runtime/product-experience/node`
- `runtime/product-experience/node_modules`
- external media root recordings under `product_experience/runs/*`

The repository source contract is limited to:

- `tools/product-experience/package.json`
- `scripts/product_experience/golden_workflow_replay.js`
- the R provisioning, validation, replay, and QA helpers

This keeps browser automation reproducible without turning Analytics Workstation into an Electron application or depending on globally installed Node/npm/Playwright state.

## Runtime Failure Classification

Recorded workflow failures are classified before they reach human review:

- Runtime unavailable
- Provisioning failed
- Browser failed
- Application failed
- Selector failed
- Scenario failed
- Validation failed
- Recording failed
- Golden Workflow completed

Partial recordings are still useful evidence. A failed replay should preserve its execution report, trace, video when available, and any screenshot chapters captured before failure.

## Phase 3 Recording Completion Gate

Phase 3 treats the Golden Workflow video as the deliverable.

The replay is complete only when:

- `GoldenWorkflow.webm` exists in the replay run directory
- Chromium can open the WebM and read playable media metadata
- the video has non-trivial duration and dimensions
- all eight screenshot chapters exist and are non-empty
- `trace.zip` exists and contains a valid Playwright trace archive
- `execution_report.json` exists and records verification
- `review_package.json` exists and includes validation, known issues, campaign seeds, and open questions

The canonical output path for a run is external to the source repository by default:

```text
<media_root>/product_experience/runs/<run_id>/GoldenWorkflow.webm
```

The media root resolves in this order:

1. explicit function argument
2. `ANALYTICS_WORKSTATION_MEDIA_ROOT`
3. `options(analytics_workstation.media_root = "...")`
4. `%USERPROFILE%/Documents/AnalyticsWorkstationMedia` on Windows, or `~/AnalyticsWorkstationMedia` fallback

The app validates that the media root is writable and outside the repository. This keeps large generated video, trace, and screenshot packages from becoming source-control noise.

The replay function must return failure if the browser process exits successfully but any required artifact is missing or unreadable. A successful process exit is not sufficient evidence that the product-experience deliverable is ready for review.

The review package is intentionally designed for founder review. It includes:

- video path
- trace path
- screenshot paths
- workflow metrics
- replay metrics
- validation results
- known issues
- campaign seeds
- open questions
- founder review readiness status
- media lifecycle state
- showcase candidate/evidence summary

## Phase 4 Showcase Quality Gate

Phase 4 changes the goal from "recording is possible" to "recording visibly demonstrates product capability."

The canonical showcase should show:

```text
Business question
-> meaningful synthetic evidence
-> AI-operated or deterministic fixture-guided investigation
-> nontrivial insight
-> uncertainty and guardrails
-> governed next action
-> visible project-state progression
```

The replay therefore uses pacing profiles:

- `fast`: QA-oriented smoke validation
- `short`: compact visual check
- `investor`: default human-review pacing
- `technical`: slower walkthrough for deeper review

The default browser replay uses `investor` pacing and must produce a video with non-trivial duration. A process that records a very short clip without visible execution is not considered a successful showcase even if the file is playable.

## External Media Lifecycle

Large generated media is governed separately from repository source.

Lifecycle states:

- `candidate`
- `awaiting_review`
- `approved`
- `rejected`
- `archived`

The source repository stores scripts, contracts, QA, and documentation. It does not store bulky generated recordings by default. Approved external media can be promoted for sharing, but that promotion is a separate decision from source code changes.

## Flagship Synthetic World

Phase 4 introduces a flagship synthetic showcase world: **Bounded Growth Pilot**.

The app-facing business question is:

> Which acquisition tactic should we scale next quarter without violating quality and capacity guardrails?

The world is designed to support an investor-grade demonstration because it contains:

- a clear business decision
- visible growth, cost, quality, and capacity tradeoffs
- evidence that supports a bounded pilot rather than an unguarded rollout
- uncertainty and guardrail language that makes governance visible
- enough structure for later analytical modules without using real customer data

Hidden truth remains QA-only. The app-facing evidence package intentionally excludes the generating mechanism and true best action. The demo should appear evidence-driven, not omniscient.

## Candidate Ranking

Phase 4 ranks showcase candidates using:

- story clarity
- data richness
- visual potential
- AI demonstrability
- governance visibility
- credibility risk

The first-ranked candidate is **Bounded Growth Pilot**. Existing worlds such as Contradictory Evidence, Epistemic Integrity, Guardrail Failure, and Decision Lifecycle remain valuable specialized demos.

## Golden Workflow UX Iteration Protocol

The first technically working recording should not be shown externally. The promotion path is:

```text
record canonical workflow
-> founder review
-> structured friction findings
-> UX campaign
-> implement
-> record the identical workflow again
-> compare
```

The app should receive the same evidence standard as the analytics engine. The goal is not to polish every tab. The goal is to make the canonical workflow feel inevitable.

### Pass 1: Coherence and Friction

Purpose: make the app feel like one product rather than many powerful modules.

Focus:

- obvious entry point
- clear current stage
- fewer clicks
- no dead ends
- no repeated authoring
- understandable terminology
- consistent button placement
- visible next action
- clean loading and transition states
- removing internal architecture language from normal user surfaces

Primary question:

> Can a new user complete the Golden Workflow without knowing how the system was built?

### Pass 2: Evidence Communication and AI Naturalness

Purpose: make the value understandable.

Focus:

- showing the key insight earlier
- improving chart and table hierarchy
- reducing evidence overload
- making contradictions visually legible
- separating conclusion, uncertainty, limitations, and next action
- shortening AI responses
- making AI actions visible but not theatrical
- explaining why AI navigated or proposed something
- reducing the feeling of chat pasted into a dashboard

Primary question:

> Does the app help the viewer understand something consequential faster than an analyst could explain it manually?

### Pass 3: Presentation and Investor Readiness

Purpose: make the already-good workflow pleasant to watch.

Focus:

- spacing
- typography
- responsive sizing
- stable viewport
- chart polish
- meaningful empty states
- presentation pacing
- chapter transitions
- synthetic-data disclosure
- final summary screen
- branded but restrained visual identity
- no ugly debug or developer surfaces
- investor, executive, and technical cut pacing

Primary question:

> Does the workflow inspire trust and make the product's commercial value obvious?

### Scope Rule

Any shared UX improvement discovered through the Golden Workflow should propagate broadly. Unrelated cosmetic work should wait. This prevents the product-experience loop from becoming a wandering polish exercise.

## Investor Promotion Gate

No recording may be marked `investor_candidate` until all criteria pass:

- no major confusion finding
- no broken or fake-looking transition
- no unresolved navigation friction
- clear business question within the opening segment
- meaningful app execution
- nontrivial insight
- AI contribution is visible and valuable
- uncertainty and guardrails remain credible
- final next action is obvious
- no developer-only content
- human founder review approves the complete unedited workflow

Intermediate recordings stay outside Git. Their manifests, scorecards, findings, traces, and review packages may be retained. Most bulky videos should be discarded or archived. Only isolated best recordings should be promoted.

## Phase 5 Founder Review and UX Campaign Loop

Phase 5 treats the Golden Workflow as the product benchmark.

The optimization target is:

```text
Understanding
-> Confidence
-> Flow
-> Decision
```

The anti-target is:

```text
Features
-> Complexity
-> Power
```

The software should explain itself. Every screen in the Golden Workflow should answer:

- Where am I?
- Why am I here?
- What just happened?
- What happens next?

### Founder Review Contract

Founder observations are structured evidence. Each observation records:

- timestamp
- workflow step
- finding
- category
- severity
- screenshot path
- video timestamp
- recommendation
- campaign id
- status

Allowed categories:

- Navigation
- Visual
- Terminology
- AI
- Evidence
- Decision
- Workflow
- Mission Control
- Performance
- Loading
- Hierarchy

### Campaign Prioritization

Every founder observation becomes a UX campaign candidate. Campaigns are ranked by:

- user impact
- commercial impact
- scientific impact
- implementation effort
- risk
- dependencies
- expected UX improvement

The ranking is intentionally transparent. It should be clear why a campaign is first, and it should be possible to disagree with the weights without losing the evidence trail.

### Current Bottleneck

The current canonical replay is useful for internal review, but it is not yet investor-ready.

Largest blocker:

> The Golden Workflow still contains product-experience/developer scaffolding in the recording path.

The next UX campaign should remove developer-only Product Experience Lab surfaces from investor-facing capture while preserving the deterministic replay and review machinery.

### Final Assessment Classes

Product-experience recordings may be classified as:

- `Internal`
- `Beta`
- `Investor Candidate`
- `Public Candidate`
- `Approved`

The current deterministic assessment should remain conservative. A recording with visible developer-only content or without founder approval must not be marked `Investor Candidate`.

### Completion Question

Continuously ask:

> If this were the only workflow a first-time user ever experienced, would they understand why Analytics Workstation exists?

Every UX decision should increase the probability that the answer becomes "yes."

## Canonical Worlds

The canonical world registry currently defines ten product-experience worlds:

1. Happy Path
2. Null Evidence
3. Contradictory Evidence
4. Explore vs Exploit
5. Guardrail Failure
6. Observational AIPW
7. Difference-in-Differences
8. Epistemic Integrity
9. Decision Lifecycle
10. Cold Start

Each world has app-facing fields such as title, public objective, product experience, and workflow variant.

Hidden truth is intentionally stored in a separate QA-only registry. The app-facing world registry must not expose hidden truth, known generating mechanisms, or true outcomes.

## Scenario Contract

Each scenario preserves:

- scenario id
- world id
- title
- audience
- purpose
- estimated duration
- entry point
- workflow variant
- steps
- expected pages
- expected screenshots
- expected narration
- expected validation
- expected completion

Scenarios are product-experience contracts. They are not general app automation scripts.

## Stable Selectors

Automation should use semantic selectors such as:

- `nav-guide`
- `nav-mission-control`
- `nav-artifact-studio`
- `product-experience-world`
- `product-experience-scenario`

Selectors should be stable `data-testid` contracts, not brittle CSS paths.

## AI Modes

Product-experience runs support three AI modes:

- `fixture`: deterministic scripted response for repeatable validation
- `live`: configured provider response
- `replay`: previously captured response with provenance

The active mode must always be disclosed. Fixture AI must never be presented as live AI.

## Review Artifact

Human review creates a `product_experience_review_artifact`.

It includes:

- scenario
- reviewer
- timestamp
- friction points
- confusing moments
- missing explanation
- navigation issues
- AI issues
- workflow issues
- visual issues
- unexpected delight
- recommended changes
- severity
- screenshots
- video timestamps
- campaign candidates

Review artifacts are standard analytical artifacts. Product experience is treated as evidence, not anecdote.

## Experience Metrics

Initial metrics include:

- completion time
- clicks
- navigation depth
- context expansions
- AI interactions
- help usage
- backtracking
- errors
- confusion markers
- abandoned workflow
- recovery

The system monitors workflows, not people.

## Product Experience Campaigns

Review findings can become campaign seeds.

The intended path is:

```text
Review Finding
-> Campaign Seed
-> Workflow Improvement
-> Product Backlog
-> Product Change
-> Replayed Scenario
```

## Developer Page

The Product Experience Lab page is a developer surface. It shows:

- architecture decision
- canonical worlds
- selected scenario contract
- fixture run status
- workflow metrics
- review artifact summary
- campaign seeds
- AI modes
- stable selectors
- recorder availability

It is not a user-facing guided demo.

## Phase 2 Golden Workflow

Phase 2 introduces one canonical product benchmark:

```text
Business Question
-> Evidence Review
-> Cross-Artifact Synthesis
-> Evidence Sufficiency
-> Governed Next Action
-> Navigation
-> Review Draft
-> Human Confirmation
-> Persisted Draft
```

The Golden Workflow answers the question:

> What should we do next?

It is intentionally narrower than the full product. The goal is to make one workflow coherent enough to become the UX benchmark, regression benchmark, educational benchmark, and commercial benchmark.

The workflow story is:

```text
Business Context
-> Evidence
-> Understanding
-> Decision
-> Governance
-> Learning
```

The success criterion is not that the app appears impressive. The success criterion is that a first-time user finishes believing:

> This system helped me make a better decision.

## Golden Workflow Benchmarks

The Golden Workflow records expected UX metrics:

- completion time
- clicks
- backtracking
- navigation depth
- context expansions
- AI interactions
- help usage
- scroll events
- confusion markers
- review duration
- confirmation count
- draft acceptance

Current replay compares observed metrics against expected values and tolerances. Deviations become UX evidence, not hidden failures.

## Replay Manifest

Every Golden Workflow replay writes:

- `execution_manifest.json`
- `review_package.json`

The manifest records:

- workflow id
- scenario id
- world id
- automation mode
- AI mode
- recorder diagnostics
- steps
- screenshot chapters
- video path and hash when captured
- trace path and hash when captured
- metrics
- hidden-truth exclusion

Fixture replay validates the contract and writes real manifests, but it does not capture screenshots, video, or trace.

## Screenshot Chapters

Golden Workflow screenshot chapters are:

1. Business Context
2. Evidence Review
3. Cross-Artifact Synthesis
4. Evidence Sufficiency
5. Governed Next Action
6. Navigation
7. Review Draft
8. Human Confirmation and Persisted Draft

Until the Playwright recorder is provisioned, screenshot status is explicit rather than fabricated.

## Human UX Adjudication

Phase 2 expands structured review fields:

- timestamp
- step
- confusion
- delay
- unexpected click
- backtracking
- AI quality
- workflow quality
- visual hierarchy
- terminology
- trust
- overall friction
- overall delight
- severity
- recommendation
- campaign seed

Reviewers should not write free-form notes only. Free-form comments may supplement structured fields, but structured fields are what make the review replayable and comparable.

## AI Invisibility Rule

The Golden Workflow treats AI as an aid to product understanding, not as the primary UX.

Every AI interaction should be evaluated:

```text
Can deterministic UX replace this?
```

If yes, prefer deterministic UX. The user should feel that the application understands the workflow, not that they are operating a generic chatbot.

## Regression Comparison

The Product Experience Lab compares the current Golden Workflow run against:

- expected metrics
- tolerance thresholds
- previous run metrics when supplied

This creates product-experience regression evidence.

## Current Limitations

- Playwright video and trace capture are now available through the repo-local runtime when provisioning succeeds.
- Fixture runs validate the product-experience contract but do not operate the browser.
- Screenshots are not fabricated in fixture mode.
- Hidden truth is available only to QA, not app workflows.
- Product-experience campaign seeds are local records, not external issue tracker items.
- Browser replay currently exercises one Golden Workflow rather than the full application surface.

## Maintenance Rule

Do not optimize for a beautiful demo. Optimize for a truthful, repeatable, measurable product experience. If the recorded workflow exposes friction, preserve that friction in the review artifact rather than hiding it. The objective is continuous product learning, not presentation.

## Phase 6: Exploratory UX Research

Phase 6 changes the product-experience stance from refinement to exploration. The current Golden Workflow remains the benchmark, but it is not treated as the final canonical user journey.

The research principle is:

```text
Do not optimize for consensus.
Optimize for learning.
```

The current product architecture is capability-rich and module-aware. That is useful for implementation and power users, but it may expose too much too early for first-time users, executives, and investor reviewers. Phase 6 therefore tests whether the visible product should open from user intent rather than from system modules.

## Competing Experience Hypotheses

The Product Experience Lab now records competing information architectures:

- Intent-first: What are you trying to accomplish?
- Mission Control first: What needs attention?
- Business Question first: What question are we trying to answer?
- Decision-first: What decision needs to be made?
- Analyst Workspace: What workspace do you want to use?
- Evidence Gallery first: What evidence already exists?

The Analyst Workspace pattern is the current baseline. Intent-first and Business Question first are the next lightweight prototype candidates.

## Prototype Modes

Prototype modes are not permanent navigation redesigns. They are experimental shells used to compare entry surface, default disclosure level, initially visible elements, hidden elements, and success metrics.

The next prototype pair should compare:

- an intent-first Guide variant that unfolds only relevant workflow paths;
- a business-question-first Guide variant that anchors on the flagship business question, then reveals evidence and action.

The Golden Workflow remains the replayable benchmark for comparison until an alternative clearly improves understanding, confidence, and flow.

## Information Exposure Taxonomy

Visible surfaces are classified as:

- Essential: required to understand or advance the current intent.
- Helpful: useful but not required for the next action.
- Contextual: useful only in the current project/module state.
- Advanced: power-user controls or deeper diagnostics.
- Architectural: explains how the system is built or governed.
- Developer: implementation, QA, replay, runtime, or debug details.

Developer and architectural surfaces should be hidden from normal investor workflows unless their appearance is the object of the demo.

## Progressive Disclosure

The proposed disclosure ladder is:

1. Level 0 Orientation: What is this and where should I start?
2. Level 1 Workflow: What am I doing next?
3. Level 2 Evidence: What do we know?
4. Level 3 Diagnostics: Can I trust this?
5. Level 4 Architecture: How is this system built?

The UI should not force Level 4 concepts into Level 0 or Level 1 moments. Architecture is important, but it should appear when the user asks for it or enters advanced/developer surfaces.

## AI Visibility

AI should disappear anywhere deterministic UX can provide a better answer.

Examples:

- Basic navigation should be deterministic.
- Obvious next actions should be visible UI.
- Short deterministic reasons should replace generic AI prose where the reason is known.
- AI should remain visible for cross-artifact synthesis, uncertainty explanation, guardrail interpretation, and evidence sufficiency reasoning.

The test is simple:

```text
If the application already knows the answer, do not spend AI on it.
```

## Current Research Answers

These are provisional answers, not final decisions:

- The current architecture probably exposes too much too early.
- First-time users probably think in intent, question, evidence, and decision language before they think in modules.
- Expert users still need module and developer access, but this should unfold progressively.
- The Golden Workflow should remain the current benchmark, not the final canonical journey.
- Developer replay controls, generated code, internal IDs, provider minutiae, and raw architecture labels should disappear from normal first-run and investor surfaces.
- Diagnostics, architecture, sidecars, full tables, QA, runtime status, and provider details should unfold progressively.
- AI should become invisible for basic navigation and obvious interface operation.
- The largest unanswered UX question is the entry model: intent, business question, mission control, decision, evidence, or workspace.

## Research Campaigns

The next research campaigns are:

- compare an Intent-first prototype against the current Golden Workflow;
- compare a Business Question first prototype against the current Golden Workflow;
- retain the current Analyst Workspace as the baseline.

Each campaign should generate replay evidence, structured founder review, friction findings, and a comparison against the existing benchmark. This phase does not declare an investor-ready navigation model.

## Phase 7 Product Philosophy Research

Phase 7 consolidates the product-experience findings into a product philosophy and canonical experience recommendation.

The research conclusion is:

```text
Intent before capability.
Evidence before recommendation.
Progressive mastery before full exposure.
```

The working philosophy is:

```text
Intent unfolds into evidence.
```

The detailed product philosophy, entry-model analysis, information-architecture recommendation, AI-visibility policy, progressive experience model, and final Phase 7 assessment live in:

```text
docs/research/product_experience_phase7_product_philosophy.md
```

## Phase 8 Prototype Experiment Plan

Phase 8 should compare two competing product philosophies over the same product, same Golden Workflow, same synthetic world, same evidence, same artifacts, same AI, and same decision.

The prototypes are:

- Prototype A: Intent-first
- Prototype B: Business Question first

Only entry, navigation, and information hierarchy may differ.

The Phase 8 experiment plan lives in:

```text
docs/research/product_experience_phase8_prototype_experiment_plan.md
```
