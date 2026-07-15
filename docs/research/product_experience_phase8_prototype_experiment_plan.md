# Product Experience Intelligence Phase 8

# Intent-First Prototype, Business Question Prototype, Comparative Experience Experiment, and Product Identity Validation

## Status

This is the Phase 8 prototype plan.

It is intentionally not an implementation plan for a broad UI redesign. The first deliverable for this phase is the research protocol that will let the team compare two competing product philosophies over the same underlying application.

The purpose is not to make the app prettier. The purpose is to learn which mental model makes Analytics Workstation emotionally obvious.

## Executive Summary

Analytics Workstation has reached the point where the architecture is more mature than the visible product experience.

The app now contains:

- deterministic Product Experience Lab
- canonical synthetic worlds
- Golden Workflow
- browser replay infrastructure
- replay manifests
- review packages
- founder review schema
- UX campaign generation
- Product Experience Constitution
- Phase 7 product philosophy research
- artifact-centered evidence architecture
- knowledge compilation runtime
- GenAI action governance
- decision, semantic, causal, and evidence systems

The remaining uncertainty is not whether the system has enough capability. It does. The uncertainty is which product philosophy allows a human to understand the system fastest and trust it most naturally.

Phase 8 therefore compares two prototypes:

```text
Prototype A: Intent-first
Prototype B: Business Question first
```

The prototypes must use the same underlying product:

- same Golden Workflow
- same synthetic world
- same evidence
- same artifacts
- same AI capabilities
- same decision
- same Mission Control state
- same reports and collector state

Only the following may differ:

```text
Entry
Navigation
Information hierarchy
```

The experiment succeeds when the team can say:

```text
We have evidence that one product philosophy produces a better human experience than another.
```

The experiment does not need to pick a winner. It may conclude:

- Prototype A is stronger for cold-start orientation.
- Prototype B is stronger for investor storytelling.
- Both fail in the same way.
- Both reveal a third philosophy.
- The canonical experience should combine A and B.

The goal is discovery.

## Why This Phase Matters

The system is no longer only a technical build. It is becoming a product with a worldview.

Until now, much of the product work has asked:

```text
How do we expose this capability?
How do we validate this subsystem?
How do we preserve this artifact?
How do we govern this action?
```

Those were necessary questions. They made the architecture durable.

The current phase asks a different question:

```text
How should Analytics Workstation think about the human?
```

That question is deeper than visual polish. It determines:

- what the product asks first
- what the user believes the product is
- what feels powerful versus overwhelming
- what becomes intuitive
- what remains hidden
- when AI should appear
- how evidence becomes understandable
- how decisions become natural
- whether the product feels inevitable

Phase 7 established the candidate philosophy:

```text
Intent before capability.
Evidence before recommendation.
Progressive mastery before full exposure.
```

Phase 8 must now test the philosophy as experience, not only prose.

## Prior State Reviewed

This plan is grounded in the current product-experience system and repository evidence.

### Phase 7 Research

Phase 7 concluded that Analytics Workstation is an evidence-centered decision operating environment, not a dashboard, notebook, report generator, Shiny app, AutoML interface, or chat interface.

The core product philosophy proposed by Phase 7:

```text
Intent unfolds into evidence.
```

The main diagnosis:

```text
The architecture is coherent, but the shell exposes construction order too early.
```

The recommended next prototypes:

- intent-first Guide variant
- business-question-first Guide variant

### Current Golden Workflow

The current Golden Workflow is:

```text
Golden Workflow: Business Question to Persisted Draft
```

Current guiding question:

```text
What should we do next?
```

Current story:

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

Current replay metrics from the latest review package:

| Metric | Value |
| --- | ---: |
| completion_time_sec | 216 |
| clicks | 12 |
| backtracking | 0 |
| navigation_depth | 4 |
| context_expansions | 3 |
| ai_interactions | 1 |
| help_usage | 1 |
| scroll_events | 4 |
| confusion_markers | 0 |
| review_duration_sec | 72 |
| confirmation_count | 1 |
| draft_acceptance | 1 |

The metrics are promising, but they do not prove product inevitability. The current replay still risks presenting the machinery before the human story.

### Current Founder Findings

The current founder review template identifies these frictions:

| Step | Friction | Severity |
| --- | --- | --- |
| Business Context | The opening question is still generic and should be tied to the flagship synthetic world. | medium |
| Evidence Review | The first important insight is not always visually dominant. | high |
| Cross-Artifact Synthesis | Synthesis can read like a technical panel instead of a decision story. | medium |
| Evidence Sufficiency | Sufficiency language needs stronger hierarchy between conclusion, uncertainty, and next action. | medium |
| Governed Next Action | Mission Control needs stronger priority ordering for one next action. | medium |
| Navigation | Current replay still visits developer/product-experience surfaces. | critical |
| Review Draft | Draft/review state is structured but not emotionally satisfying. | medium |
| Persistence | Final screen does not yet feel like a clean close. | medium |

These findings point to philosophy, not merely layout.

### Current Research Campaigns

The current Product Experience Lab already identifies two next campaigns:

| Campaign | Prototype | Learning Goal |
| --- | --- | --- |
| research_campaign_1 | Business Question first | User understands the business story without narration. |
| research_campaign_2 | Intent-first | User can choose a path without asking what the app does. |

Phase 8 formalizes those campaigns into a controlled comparative experiment.

## Research Thesis

The central Phase 8 research thesis:

```text
The same architecture can produce different human understanding depending on whether the entry experience starts from intent or from a concrete business question.
```

The experiment compares two product philosophies:

### Prototype A Philosophy

```text
The user first knows what kind of work they want to do.
```

Prototype A asks:

```text
What are you trying to accomplish?
```

It treats the user as someone with a broad intent:

- analyze data
- make a decision
- review evidence
- continue work
- explore
- learn

### Prototype B Philosophy

```text
The user first knows the question they need answered.
```

Prototype B asks:

```text
What business question are you trying to answer?
```

It treats the user as someone with a decision or uncertainty that should unfold into evidence.

## Experimental Control

The two prototypes must differ only where the product philosophy differs.

### Must Remain Identical

- Golden Workflow
- synthetic world
- Bounded Growth Pilot evidence
- hidden truth policy
- generated artifacts
- collector state
- AI provider behavior
- AI action governance
- Mission Control data
- report/draft content
- final decision
- replay engine
- founder review schema
- metrics schema
- promotion gates

### May Differ

- first screen content
- opening prompt
- visible primary choices
- initial explanatory language
- ordering of evidence/action panels
- hiding or revealing of navigation
- where the user is routed after entry
- which context is shown in the first 60 seconds
- which cards are visible before the first meaningful action
- which surfaces are treated as backstage

### Must Not Differ

- analytic result quality
- evidence content
- AI answer quality
- synthetic data
- artifact availability
- collector behavior
- governance behavior
- backend capability

This is not a capability comparison. It is a product philosophy comparison.

## Prototype A: Intent-First

### Opening Prompt

```text
What are you trying to accomplish?
```

### Initial Choices

Only these choices should be visible:

- Analyze data
- Make a decision
- Review evidence
- Continue work
- Explore
- Learn

Nothing else should compete with the question.

### First Screen Goal

The user should understand:

```text
The workstation adapts to what I am trying to do.
```

### First 60 Seconds

The first minute should answer:

1. What kind of work can I start?
2. What does each path mean?
3. What is the recommended path for the current demo/project?
4. What will happen after I choose?
5. Where is the expert escape hatch?

It should not answer:

- what every module does
- how AI runtime works
- how evidence routing works
- what the Product Experience Lab is
- how reports are composed
- which QA systems exist

### Intended Flow

```text
Guide opens
-> Intent choices appear
-> User chooses Make a decision
-> System reveals Bounded Growth Pilot business question
-> System shows current project/evidence status
-> System recommends reviewing evidence path
-> Workflow continues into same Golden Workflow
```

### Information Hierarchy

Level 0:

- intent prompt
- six intent choices
- one recommended choice for the current demo
- concise product identity line

Level 1:

- selected path explanation
- required inputs
- next meaningful action

Level 2:

- evidence state
- artifacts available or missing
- decision readiness

Level 3:

- diagnostics
- guardrails
- uncertainty

Level 4:

- architecture
- runtime
- developer QA

### What A Hides Initially

- business-question authoring details
- module registry
- developer surfaces
- Product Experience Lab
- AI Runtime internals
- raw artifact policies
- generated code
- provider configuration
- report layout controls

### Expected Strengths

- Best for cold-start users.
- Best for users who do not yet know whether they have a question, data, model, or evidence.
- Broadest onboarding fit.
- Reduces fear of choosing the wrong module.
- Makes the app feel adaptive.

### Expected Weaknesses

- May feel generic if the choices are too broad.
- May weaken the investor story if the business decision appears too late.
- May feel wizard-like if expert exits are not visible.
- May underplay the evidence-centered identity in the first few seconds.

### Key Failure Modes

Reject or revise Prototype A if:

- users still ask "what is this app for?"
- the six choices feel like a menu disguised as a question
- users cannot tell why "Make a decision" is recommended
- the business story appears too late
- expert users feel trapped
- the workflow feels like onboarding rather than real work

### Success Signal

Prototype A succeeds if:

```text
A first-time user can choose a path without understanding the module system.
```

## Prototype B: Business Question First

### Opening Prompt

```text
What business question are you trying to answer?
```

For the Bounded Growth Pilot world:

```text
Which acquisition tactic should we scale next quarter without violating quality and capacity guardrails?
```

### First Screen Goal

The user should understand:

```text
This product exists to turn business questions into evidence-backed decisions.
```

### First 60 Seconds

The first minute should answer:

1. What question are we trying to resolve?
2. What decision depends on the answer?
3. What evidence already exists?
4. What evidence is missing?
5. What is the next evidence action?

It should not answer:

- every possible task the app can perform
- every module available
- all architecture concepts
- full evidence-routing detail
- full causal/semantic capabilities
- product-experience machinery

### Intended Flow

```text
Guide opens
-> Business question appears
-> Decision context appears
-> Known evidence and missing evidence appear
-> System recommends evidence review
-> Workflow continues into same Golden Workflow
```

### Information Hierarchy

Level 0:

- business question
- decision at stake
- one-sentence product identity
- current evidence state

Level 1:

- evidence needed
- current recommendation
- expected benefit
- expected cost

Level 2:

- artifacts and evidence inspector
- support, contradiction, uncertainty

Level 3:

- guardrails
- decision readiness
- governance

Level 4:

- architecture
- developer systems
- runtime diagnostics

### What B Hides Initially

- broad onboarding choices
- module registry
- architecture map
- Product Experience Lab
- AI Runtime internals
- generated code
- detailed provider status
- generic "learn the workstation" content unless requested

### Expected Strengths

- Strongest business story.
- Strongest investor demo candidate.
- Makes the product category obvious quickly.
- Aligns tightly with evidence and decision architecture.
- Makes AI synthesis more naturally bounded.
- Better at answering "why does this product exist?"

### Expected Weaknesses

- Less flexible for users who only have data and no question.
- May feel too formal for exploratory analysis.
- May require question authoring before users know enough.
- May underplay the breadth of the workstation.

### Key Failure Modes

Reject or revise Prototype B if:

- users do not have a question yet and feel blocked
- the first question feels like a form, not a thinking prompt
- users need to browse data before they can phrase the question
- evidence appears before enough orientation
- the product feels only executive-facing and not analyst-friendly

### Success Signal

Prototype B succeeds if:

```text
A viewer understands the business story without narration.
```

## Required Baseline

The current Analyst Workspace / Golden Workflow baseline should remain the control.

The baseline represents:

```text
Capability/module-aware workstation.
```

It is not wrong. It is the current expression of the architecture.

Baseline comparison should answer:

- Do A or B reduce cognitive load relative to the current shell?
- Do A or B tell the product story earlier?
- Do A or B hide developer surfaces better?
- Do A or B preserve enough expert power?
- Does either prototype make the existing architecture feel more inevitable?

## Metrics

The metrics must be comparable across baseline, Prototype A, and Prototype B.

### Quantitative Metrics

| Metric | Definition | Desired Direction |
| --- | --- | --- |
| time_to_first_meaningful_action_sec | Time from app entry to first action that advances the evidence/decision path. | lower |
| clicks | Total clicks to complete Golden Workflow. | lower, unless clarity improves |
| navigation_depth | Number of distinct pages/modes traversed. | lower |
| context_switches | Number of conceptual surface changes. | lower |
| backtracking | User returns to prior pages because path was unclear. | lower |
| reading_burden_estimate | Approximate visible text load before first meaningful action. | lower, unless confidence improves |
| help_usage | Guide/help/assistant usage caused by confusion. | lower |
| ai_interactions | AI interactions needed to complete flow. | lower unless AI adds clear reasoning value |
| scroll_events | Scrolls before first meaningful insight. | lower |
| replay_duration_sec | Total replay duration. | balanced, not necessarily minimized |
| completion | Whether the workflow completes. | true |
| draft_acceptance | Whether review draft is accepted/persisted. | true |

### Qualitative Metrics

| Metric | Question |
| --- | --- |
| first_minute_clarity | Does the user know what the product is for? |
| business_story_clarity | Is the decision/question obvious? |
| evidence_visibility | Is evidence visible as evidence, not output? |
| architecture_hidden | Are implementation details hidden until needed? |
| confidence | Does the user trust what is happening? |
| emotional_obviousness | Does the product feel inevitable? |
| delight | Is there a moment the user wants to click or continue? |
| confusion | Where does the product make the user think about the software rather than the work? |
| founder_preference | Which prototype would the founder choose to show first? |

### First-Minute Evaluation

For each prototype, review:

- What did the user see?
- What did the user have to infer?
- What was hidden?
- What was too early?
- What was missing?
- Did the product identity appear without narration?
- Did the user know the next action?

### Five-Minute Evaluation

For each prototype, review:

- Does the user understand project, evidence, artifact, collector, and recommendation at a usable level?
- Does the user feel confident enough to continue?
- Does the user know what is known and unknown?
- Does the user understand why the next step matters?
- Does the user see that AI is bounded by evidence?

### One-Week Evaluation

For each prototype, infer:

- What would users naturally discover?
- Would they find advanced capability when ready?
- Would they learn the product ontology through use?
- Would power users outgrow the entry model?
- Would executives understand decisions without becoming analysts?

## Founder Review Schema Additions

The existing founder review schema should be extended for Phase 8 with comparison-specific fields.

Recommended fields:

| Field | Purpose |
| --- | --- |
| prototype_id | `prototype_a_intent`, `prototype_b_business_question`, or `baseline_current` |
| first_minute_summary | What the reviewer understood in the first minute. |
| first_meaningful_action | First action that felt real. |
| moment_of_delight | The best emotional or understanding moment. |
| moment_of_confusion | Where the product made the reviewer work unnecessarily. |
| architecture_leak | Whether implementation details appeared too early. |
| ai_necessity | Whether AI was genuinely useful or acting as UI glue. |
| evidence_clarity | Whether artifacts felt like evidence. |
| product_identity_clarity | Whether the app answered "what is this?" without narration. |
| confidence_change | Whether trust increased during the flow. |
| preference_rank | Reviewer ranking across prototypes. |
| recommendation | Keep, revise, reject, combine, or create third prototype. |

Do not rely only on free-form notes. The comparison must be structured enough to become product evidence.

## Product Experience Lab Requirements

Phase 8 should eventually add Product Experience Lab support for:

- replay Prototype A
- replay Prototype B
- replay baseline
- compare A vs B vs baseline
- display metrics side by side
- display first-minute findings
- display founder preference
- display prototype-specific campaigns
- display open questions
- link to replay artifacts
- link to review packages

This should not be built until the prototype plan is accepted.

### Minimum Future Lab Outputs

The future Product Experience Lab output should include:

```text
Prototype A card
Prototype B card
Baseline card
Replay status
Metrics comparison
Founder comparison
Campaigns
Recommendation
Open questions
```

## Replay Plan

### Baseline Replay

Run the current Golden Workflow unchanged.

Purpose:

- preserve current benchmark
- establish current measured friction
- avoid comparing prototypes to memory

### Prototype A Replay

Run the same Golden Workflow through the intent-first entry.

Required opening:

```text
What are you trying to accomplish?
```

Required choices:

- Analyze data
- Make a decision
- Review evidence
- Continue work
- Explore
- Learn

Expected selected path:

```text
Make a decision
```

Then route into the same Bounded Growth Pilot story.

### Prototype B Replay

Run the same Golden Workflow through the business-question-first entry.

Required opening:

```text
What business question are you trying to answer?
```

Required flagship question:

```text
Which acquisition tactic should we scale next quarter without violating quality and capacity guardrails?
```

Then route into the same evidence path and decision story.

## Experience Controls

To keep the comparison fair:

- Same viewport size.
- Same theme.
- Same synthetic world.
- Same seeded project state.
- Same AI provider mode.
- Same evidence package.
- Same final review draft.
- Same pacing profile.
- Same replay recorder.
- Same founder review form.
- Same promotion gates.
- Same hidden truth policy.

If any control differs, the replay package must record the difference.

## Campaign Generation

Phase 8 should generate prototype-specific campaigns only.

Do not broadly polish unrelated modules.

Campaign examples:

### Prototype A Campaigns

- Reduce generic intent-choice ambiguity.
- Make recommended intent visually obvious.
- Add expert escape without polluting first screen.
- Move business story earlier if comprehension lags.

### Prototype B Campaigns

- Make question authoring feel conversational rather than form-like.
- Support users who have data but no question.
- Show evidence state without overwhelming first screen.
- Add "I do not know the question yet" escape.

### Shared Campaigns

- Hide developer surfaces from canonical replay.
- Make first meaningful insight visually dominant.
- Make Mission Control's next action unmistakable.
- Make AI synthesis shorter and decision-structured.
- Create cleaner final persisted-memory close.

## Mission Control Research Question

Phase 8 should explicitly investigate whether Mission Control is:

```text
A module
```

or:

```text
The operating system state layer.
```

The current answer is likely:

```text
Mission Control should not be cold-start entry, but it should become the returning-project operating layer.
```

However, this should remain a hypothesis.

Evaluate Mission Control in each prototype:

- Does it help the user understand what needs attention?
- Does it feel like monitoring or thinking?
- Does it make one next action clear?
- Does it reduce or increase navigation?
- Does it appear too early or at the right time?

## AI Research Question

Phase 8 should test whether AI interactions are present because:

1. AI is genuinely improving understanding, reasoning, or decision confidence; or
2. the architecture has exposed complexity that deterministic UX should have hidden.

For every AI interaction in replay, record:

- why AI appeared
- whether deterministic UI could replace it
- whether the response shortened or lengthened the user's path
- whether it improved confidence
- whether it introduced reading burden
- whether it made uncertainty clearer

The ideal AI moment is not a long answer. It is a short, evidence-grounded explanation that changes understanding.

## Product Identity Validation

Every prototype should answer:

```text
What is Analytics Workstation?
```

without narration.

### Prototype A Identity Statement

Expected identity:

```text
Analytics Workstation adapts to what I am trying to accomplish and guides me toward the right evidence path.
```

### Prototype B Identity Statement

Expected identity:

```text
Analytics Workstation turns business questions into evidence-backed decisions.
```

### Baseline Identity Statement

Likely identity:

```text
Analytics Workstation is a powerful analytical platform with many modules.
```

The baseline identity may be true, but less emotionally obvious.

## Decision Criteria

No winner is required, but if the team must choose, use these criteria.

### Prototype A Wins If

- first-time orientation is materially better
- users choose a path confidently
- broad user types feel included
- business story is still clear by minute five
- advanced capability remains discoverable
- cognitive load decreases without making the product feel shallow

### Prototype B Wins If

- product identity is obvious faster
- business story is stronger
- first meaningful action happens sooner
- evidence appears more naturally
- AI synthesis feels more bounded
- investor review preference is clearly higher

### Combine A And B If

- A is better for cold start
- B is better for the Golden Workflow/investor story
- users need a path for "I know my task" and "I know my question"

Possible combined entry:

```text
What are you trying to accomplish?

[Answer a business question]
[Analyze data]
[Review evidence]
[Continue work]
[Learn]

If Answer a business question:
  What business question are you trying to answer?
```

### Reject Both If

- both still expose architecture too early
- both require too much reading
- both feel like onboarding wrappers over the old app
- neither makes evidence visible fast enough
- neither produces a moment of product inevitability

### Preserve Third Hypothesis If It Emerges

A likely third hypothesis:

```text
Decision-first
```

Opening:

```text
What decision needs to be made?
```

This may prove stronger than both A and B for executives and investor demos, especially once alternatives, valuation, causal evidence, and review workflows are more mature.

## QA Plan

Phase 8 implementation should eventually add deterministic QA for:

- prototype registry includes A, B, and baseline
- A and B declare identical controls
- A and B use same Golden Workflow
- A and B use same synthetic world
- A and B use same metric schema
- A and B use same founder review schema
- comparison output includes all required metrics
- campaign generation is prototype-specific
- documentation exists
- replay package can distinguish prototype_id
- missing replay data degrades gracefully
- no prototype is declared winner without review evidence
- no investor candidate status is assigned without promotion gate pass

This plan does not implement those QA functions yet.

## Documentation Plan

Phase 8 implementation should update:

- `docs/product_experience_intelligence_architecture.md`
- Product Experience Lab documentation
- Product Experience Constitution references if needed
- UX roadmap
- Golden Workflow notes

The present document should remain the research protocol.

## Open Questions

1. Is intent-first too generic to produce an emotionally obvious opening?
2. Is business-question-first too narrow for users arriving with data but no question?
3. Should the app support both as two branches of the same Guide?
4. Should Mission Control become the returning-project home rather than a tab?
5. Should Artifact Studio become the center of gravity after evidence exists?
6. Should AI Runtime disappear from normal navigation entirely?
7. How much expert capability must remain visible to prevent the product from feeling like a wizard?
8. What is the first moment where the product feels inevitable?
9. Is the strongest product story decision-first rather than intent-first or question-first?
10. Can the Golden Workflow be replayed without showing any developer/product-experience surfaces?
11. Can the first minute communicate evidence, uncertainty, and next action without overloading users?
12. What should the final persisted-memory moment look like?

## Recommended Next Implementation Step

Do not start by redesigning the full shell.

Start with the smallest controlled vertical slice:

1. Add a prototype registry for baseline, intent-first, and business-question-first.
2. Add deterministic metadata for controls, visible elements, hidden elements, and metrics.
3. Add fixture-level comparison outputs without browser replay.
4. Add Product Experience Lab display for prototype comparison.
5. Add replay support for prototype_id only after metadata comparison is stable.
6. Add founder review comparison schema.
7. Run baseline, A, and B.
8. Generate comparison and campaigns.

Only after that should any broader app navigation changes be considered.

## Final Assessment For This Plan

### Which Prototype Better Matches The Product Constitution?

Before implementation, the hypothesis is:

- Intent-first best matches "Intent before capability."
- Business-question-first best matches "Evidence before recommendation."
- Both match "Progressive mastery before full exposure" if developer surfaces remain hidden.

No final winner should be declared yet.

### Which Reduces Cognitive Load?

Hypothesis:

- Intent-first reduces entry anxiety for broad users.
- Business-question-first reduces story ambiguity for decision contexts.

This must be measured.

### Which Tells The Product Story Earlier?

Hypothesis:

- Business-question-first tells the commercial/product story earlier.

### Which Better Hides Architecture?

Hypothesis:

- Both can hide architecture if implemented properly.
- Intent-first has slightly higher risk of exposing path logic.
- Business-question-first has slightly higher risk of exposing evidence/planning logic too early.

### Which Better Exposes Evidence?

Hypothesis:

- Business-question-first exposes evidence more naturally because evidence is immediately tied to a question.

### Which Feels More Inevitable?

Hypothesis:

- Business-question-first may feel more inevitable in investor replay.
- Intent-first may feel more inevitable in real user onboarding.

### What Still Feels Wrong?

The largest unresolved issue is that current canonical replay is tied to AI Runtime and developer/product-experience surfaces. The product story is right, but the staging is not yet emotionally obvious.

### What Should Become The Next Prototype?

Prototype A and Prototype B should both be built as lightweight Guide variants. If neither wins clearly, the next prototype should be a combined intent-question flow:

```text
What are you trying to accomplish?
-> Answer a business question
-> What business question are you trying to answer?
```

If the team wants a sharper executive/investor challenger after A/B, the next hypothesis should be Decision-first:

```text
What decision needs to be made?
```

## Completion Criterion

Phase 8 is complete only when:

```text
The team has comparable evidence for at least two competing product philosophies, generated from the same product, same world, same workflow, same evidence, and same review process.
```

The evidence should include:

- replay or fixture outputs for A and B
- metric comparison
- founder review findings
- cognitive-load assessment
- prototype-specific campaigns
- recommendation or preserved uncertainty
- open questions

The phase fails if it simply implements a preferred design without learning whether it improves human understanding.

