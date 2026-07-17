# Current Position OS White Paper

Before we build it, decide whether it should exist.

This document is intentionally non-implementation.

It does not propose UI.

It does not modify Working Contexts.

It does not modify architecture.

It treats **Current Position OS** as a hypothesis, not a decision.

## Executive Summary

Creative Exploration Sprint 3 selected **Current Position OS with Oracle-style footnotes** as the strongest surviving product philosophy. That result is not enough to justify implementation.

The concept deserves investigation because it may identify a deeper product object than pages, rooms, dashboards, modules, reports, or even artifacts.

The working hypothesis:

```text
Analytics Workstation should revolve around the project's current analytical position:
what can responsibly be believed, why, what weakens it, what remains unknown,
what decision is justified, and what would change the conclusion.
```

The paper's conclusion:

```text
Current Position OS should become the next prototype,
but only as a bounded scientific product experiment.
```

It should not replace the existing architecture. It should sit above it as a reasoning object that composes existing services, evidence, artifacts, decisions, governance, and knowledge state.

The core reason it deserves to exist:

```text
Current Position is not a metaphor.
It is the missing durable reasoning object that Semantic Continuation exposed.
```

The core risk:

```text
If implemented as a summary page, dashboard, memo, or chat answer,
Current Position OS fails.
```

## Source Trail

The concept did not appear randomly. It emerged through a sequence of product discoveries.

### Working Contexts

Working Contexts were introduced to make the product task-first instead of page-first.

They answered:

```text
Where should meaningful work happen?
```

Evidence Review became the first production context. Decision Management became the second. Together they proved that the app can present a focused working environment without exposing the whole architecture at once.

But Working Contexts still preserve a room model.

They reduce navigation burden, but they do not fully solve reasoning continuity.

### Evidence Review

Evidence Review asks:

```text
What do we know?
```

Its focal object is Current Answer.

It composes evidence binder, artifacts, synthesis, contradictions, sufficiency, valuation, next action, mentor support, and draft persistence.

The important discovery:

```text
Evidence Review works best when Current Answer is the first-class object.
```

### Decision Management

Decision Management asks:

```text
What should we do?
```

Its focal object is Current Decision.

It composes alternatives, tradeoffs, economics, governance, workflow, provenance, and recommendations.

The important discovery:

```text
Decision Management works best when Current Decision is the first-class object.
```

### Semantic Continuation

Semantic Continuation tried to preserve reasoning across room transitions.

It improved language:

```text
Continue the reasoning.
```

But the populated replay showed a deeper failure:

```text
A label cannot preserve thought unless the thought itself is carried.
```

The user still had to reacquire:

- question;
- current answer;
- evidence basis;
- contradiction;
- limits;
- intent;
- next thought.

The better candidate abstraction was named:

```text
Current Position
```

### Creative Exploration Tournament

The design tournament tested many product worlds. Current Position OS survived criticism because it was less theatrical than the other metaphors.

Oracle With Footnotes described how the product might speak.

Current Position OS described what the product would know.

That distinction matters.

## Central Question

If Analytics Workstation revolved around Current Position instead of pages, rooms, workflows, or dashboards, what would fundamentally change?

The answer:

```text
The product center would shift from places where work happens
to the evolving reasoning state that work changes.
```

Pages ask:

```text
Where do you want to go?
```

Rooms ask:

```text
What kind of work are you doing?
```

Current Position asks:

```text
What can we responsibly believe right now,
what follows from that belief,
and what would change it?
```

This is not a cosmetic difference. It changes the ontology.

## Ontology

### What Current Position Is Not

Current Position is not:

- a page;
- a dashboard;
- a report;
- a chat answer;
- a static summary;
- a single recommendation;
- a project status card;
- an artifact;
- a decision record;
- a workflow step;
- a knowledge graph node alone.

Each of those may express part of it, but none is the object.

### Definition

Current Position is a **durable, versioned, evidence-grounded reasoning state** for a project, investigation, decision, or question.

It contains the strongest responsible analytical stance available at a given time.

It answers:

- What question are we answering?
- What can we currently say?
- How strong is that statement?
- What evidence supports it?
- What evidence weakens it?
- What remains unknown?
- Which assumptions are active?
- Which alternatives remain plausible?
- What decision is justified?
- What action should happen next?
- What would change our mind?
- What governance or review is required?
- What changed since the last position?

### Object Class

Current Position is best understood as:

```text
a reasoning bundle
```

It is adjacent to, but distinct from:

- a knowledge bundle;
- an evidence bundle;
- a decision bundle;
- a recommendation;
- a working context;
- a semantic object.

It is a bundle because it references many objects.

It is a reasoning bundle because its purpose is not storage, display, or workflow. Its purpose is to preserve and evolve judgment.

### Canonical Fields

A minimal Current Position would include:

| Field | Purpose |
| --- | --- |
| Position ID | Stable identity. |
| Project ID | Parent project. |
| Investigation or decision context | Scope of reasoning. |
| Business question | Governing question. |
| Current answer | Strongest responsible answer. |
| Claim set | Atomic claims that compose the answer. |
| Evidence basis | References to supporting artifacts and findings. |
| Contradictions | Evidence or findings that weaken the answer. |
| Unknowns | Missing evidence and unresolved uncertainty. |
| Assumptions | Explicit premises carried forward. |
| Alternatives | Plausible competing positions or actions. |
| Recommendation | Current advised action, if justified. |
| Decision readiness | Evidence confidence for action. |
| Next best action | Highest-value analytical or decision move. |
| Governance state | Review, approval, and authority requirements. |
| Footnotes | Claim-to-evidence links. |
| Version | Historical state. |
| Change reason | Why the position changed. |

### Claim-Level Structure

A Current Position should not be one paragraph.

It should be decomposable into claims.

Example:

```text
Position:
The evidence supports a bounded premium Midwest retention pilot,
not a national rollout.
```

Claims:

1. Premium Midwest subscribers show promising modeled response.
2. Response variance remains high.
3. Prior holdout evidence is positive but stale.
4. Full rollout is not justified.
5. A bounded pilot preserves option value while reducing uncertainty.

Each claim should have:

- support;
- weakness;
- confidence;
- evidence references;
- allowed language;
- overclaim risk;
- review state.

This is where Oracle-style footnotes belong.

They are not the operating system. They are the presentation and interaction grammar for claim-level accountability.

## Lifecycle

### Creation

A Current Position is created when the project has a question or investigation scope.

It may begin empty:

```text
No responsible position yet.
Question defined.
Evidence not yet assembled.
```

It may also be generated from imported state:

- existing project;
- existing decision context;
- evidence review;
- model assessment;
- causal study;
- report;
- prior position.

Creation should not require GenAI. It can begin deterministically.

### Evolution

Current Position evolves when meaningful reasoning state changes:

- new evidence is added;
- evidence is invalidated;
- a contradiction is reviewed;
- a claim is strengthened or weakened;
- an assumption is added or removed;
- alternatives change;
- decision readiness changes;
- governance changes;
- outcome learning arrives;
- a user revises the business question;
- a model or estimator result changes;
- evidence sufficiency is reassessed.

The important rule:

```text
Not every UI interaction changes Current Position.
Only reasoning-relevant events do.
```

### Versioning

Current Positions should be versioned.

A version records:

- what changed;
- why it changed;
- evidence added or removed;
- claims affected;
- confidence/readiness movement;
- actor or service responsible;
- timestamp;
- provenance.

Versioning prevents the concept from becoming ephemeral prose.

### Splitting

A Current Position splits when one reasoning state can no longer honestly represent the project.

Split triggers:

- multiple business questions;
- competing hypotheses remain live;
- alternatives require separate evidence paths;
- different audiences require distinct decision frames;
- segment-specific conclusions diverge;
- causal and predictive answers diverge;
- governance requires separate approval paths.

Example:

```text
Position A: Premium Midwest retention pilot.
Position B: National rollout.
Position C: No offer, invest in service intervention.
```

Splitting protects against false consensus.

### Merging

Positions merge when competing threads resolve into a common stance.

Merge triggers:

- evidence eliminates an alternative;
- a decision combines actions;
- a broader recommendation absorbs narrower findings;
- a project moves from exploration to decision.

Merging should preserve the lineage of the merged positions.

### Death

A Current Position dies when it is no longer active as a reasoning state.

It may become:

- historical;
- superseded;
- rejected;
- implemented;
- archived;
- contradicted by later evidence;
- converted into organizational knowledge;
- converted into a decision record;
- converted into outcome-learning state.

Death is not deletion.

It is a lifecycle transition.

### Multiple Positions Per Project

Projects can contain multiple Current Positions.

This is not a contradiction. A project may contain multiple questions, alternatives, claims, or decisions.

The dangerous design mistake would be assuming a project has exactly one position.

Better:

```text
Project
-> Active Position(s)
-> Historical Position(s)
-> Superseded Position(s)
-> Draft Position(s)
```

## Relationship To Existing Concepts

### Project

Project remains the container.

Current Position becomes the active reasoning state inside the project.

Relationship:

```text
Project owns context.
Current Position owns stance.
```

Project does not become obsolete.

### Evidence

Evidence remains the material that supports, weakens, or changes positions.

Current Position does not replace evidence. It routes evidence into meaning.

Relationship:

```text
Evidence answers: what supports or weakens this?
Current Position answers: what follows from the evidence?
```

### Artifact

Artifacts remain durable analytical objects.

Current Position references artifacts; it does not absorb them.

Relationship:

```text
Artifacts are evidence objects.
Current Position is the reasoning state built from selected evidence objects.
```

### Recommendation

Recommendation becomes one possible output of Current Position.

It should not be the same object.

A position may conclude:

```text
No recommendation is justified yet.
```

Therefore recommendation is secondary.

### Decision

Decision is a governed commitment or choice.

Current Position may support a decision, but it does not equal a decision.

Relationship:

```text
Current Position: what should be believed or considered now.
Decision: what the organization commits to do.
```

### Workflow

Workflow becomes secondary.

Workflow describes procedural progress. Current Position describes reasoning progress.

Workflow remains useful for governance and operation, but it should not be the user's primary mental model.

### Knowledge Bundle

Knowledge Bundle captures validated or promoted knowledge.

Current Position may contain tentative, contested, or unresolved reasoning.

Relationship:

```text
Current Position can graduate into knowledge.
Knowledge can inform future Current Positions.
```

### Working Context

Working Context is a place where a kind of work happens.

Current Position is the object the work changes.

Relationship:

```text
Working Context is workspace.
Current Position is work state.
```

This is the key distinction.

Working Contexts should not be discarded yet. They may become perspectives, editors, or transformation surfaces for Current Position.

### Mission Control

Mission Control provides orientation and operational awareness.

If Current Position becomes primary, Mission Control may shift from destination hub to project-status layer around active positions.

It remains useful for:

- jobs;
- health;
- alerts;
- project state;
- stale evidence;
- action queues.

It should not compete with Current Position as the reasoning center.

### Semantic Continuation

Semantic Continuation becomes a behavior of Current Position.

It is no longer the top-level abstraction.

Semantic Continuation means:

```text
When the user moves between surfaces,
the Current Position carries the reasoning forward.
```

### Oracle With Footnotes

Oracle With Footnotes is not the OS.

It is:

- presentation layer;
- explanation layer;
- interaction philosophy;
- claim accountability grammar.

It lets Current Position speak in direct language without becoming ungrounded.

## Do Evidence Review And Decision Management Become Rooms?

The white paper's answer:

```text
They remain valid, but their ontological status changes.
```

They are no longer primary product destinations.

They become **position editors** or **position perspectives**.

### Evidence Review

Evidence Review becomes the perspective that asks:

```text
What evidence supports, weakens, or changes the Current Position?
```

It edits:

- evidence basis;
- contradictions;
- sufficiency;
- claim support;
- claim weakness;
- unknowns;
- next evidence requirement.

### Decision Management

Decision Management becomes the perspective that asks:

```text
What action follows from the Current Position?
```

It edits:

- alternatives;
- tradeoffs;
- recommendation;
- approval;
- implementation readiness;
- decision state;
- outcome obligations.

### Consequence

The current room model does not need to be destroyed immediately.

But if Current Position OS is correct, rooms become subordinate.

The user no longer thinks:

```text
I am in Evidence Review.
Now I go to Decision Management.
```

The user thinks:

```text
I am working on this position.
Now I need to inspect evidence.
Now I need to compare actions.
Now I need to request review.
```

## Thought Experiment: No Pages, No Tabs, No Navigation

Suppose the product had no pages.

Only Current Position.

Could it still exist?

Conceptually, yes.

The product would begin with:

```text
What decision, question, or claim are we working on?
```

Then it would maintain:

```text
Current Position
```

Capabilities would emerge as transformations of that position:

- add evidence;
- challenge claim;
- compare alternatives;
- inspect contradiction;
- request more evidence;
- revise assumption;
- estimate value;
- request review;
- approve decision;
- implement;
- record outcome;
- promote learning.

The deeper discovery:

```text
Pages are one way to expose transformations.
They are not the ontology.
```

## User Journey Without UI

Conceptual first interaction:

```text
Tell me the decision or question.
```

The product creates a draft position:

```text
No responsible answer yet.
Evidence required.
Suggested first action: assemble evidence binder.
```

After evidence exists:

```text
Current Position:
Evidence supports a bounded pilot, not broad rollout.
```

The user asks:

```text
Why?
```

The position reveals footnoted claims.

The user asks:

```text
What weakens this?
```

The position reveals contradictions.

The user asks:

```text
What should we do?
```

The position reveals alternatives and readiness.

The user asks:

```text
What would change your mind?
```

The position reveals missing evidence and next best action.

The user acts.

The position versions.

The decision is recorded.

Outcome learning later updates or supersedes the position.

## Failure Analysis

### Failure Mode 1: Summary Page Disguised As Philosophy

The largest risk is that Current Position becomes a page showing:

- current answer;
- evidence count;
- recommendation;
- readiness;
- next action.

That would be a dashboard.

The concept survives only if the position is:

- interactive;
- versioned;
- challengeable;
- claim-structured;
- evidence-grounded;
- transformable.

### Failure Mode 2: Confirmation Bias

A single current position can anchor the user.

If the product leads with one answer, users may stop exploring alternatives.

Mitigation:

Current Position must include:

- competing positions;
- rejected positions;
- unresolved hypotheses;
- contradiction pressure;
- evidence that would change the answer.

### Failure Mode 3: Hidden Exploration

Exploration can feel awkward if everything must resolve into a position.

Mitigation:

Allow early positions such as:

```text
No responsible answer yet.
Three hypotheses remain live.
The product is in discovery state.
```

Exploration is still a position.

### Failure Mode 4: Expert Frustration

Experts may reject Current Position if it hides controls.

Mitigation:

Expose expert depth through claim, evidence, and transformation affordances.

Do not remove power. Remove unnecessary syntax.

### Failure Mode 5: Multiple Simultaneous Questions

A project can contain many questions.

Mitigation:

Allow multiple Current Positions with explicit scope.

Avoid pretending the project has one universal stance.

### Failure Mode 6: Over-Textual Product

Current Position could become prose-heavy.

Mitigation:

Claims, evidence, contradictions, uncertainty, alternatives, and history need visual structure.

The product should not become a memo editor.

### Failure Mode 7: Stale Position

If new evidence arrives but the Current Position does not change, users may trust stale reasoning.

Mitigation:

Current Position needs freshness state:

- current;
- stale;
- partially stale;
- invalidated;
- awaiting review.

### Failure Mode 8: False Objecthood

The team might invent a new object that duplicates existing services.

Mitigation:

Current Position should reference existing canonical services, not own their data.

It should compose, not replace.

## Success Analysis

If Current Position OS is correct, several things become simpler.

### Navigation Becomes Consequential

The user no longer chooses destinations abstractly.

They choose transformations:

```text
inspect support;
challenge claim;
compare alternatives;
request review;
record outcome.
```

### AI Becomes Safer

AI does not free-roam across the app.

It explains, challenges, summarizes, and proposes changes to Current Position.

The AI's scope becomes naturally bounded.

### Artifacts Gain Purpose

Artifacts are not browsed for their own sake.

They matter because they support, weaken, or change claims.

### Governance Becomes Natural

Governance is not a separate bureaucracy.

It determines whether the Current Position is allowed to become a decision, recommendation, draft, or organizational knowledge.

### Reports Become Render Targets

Reports are no longer the product center.

They are encodings of Current Position for an audience.

### Knowledge State Becomes Operational

Knowledge State can update when Current Positions are confirmed, superseded, contradicted, or promoted.

### Outcome Learning Becomes Inevitable

After implementation, the product asks:

```text
Did the outcome validate, weaken, or revise the position?
```

That connects decision to learning.

## Comparisons

### Current Position vs Working Context House

Working Context House explains where focused work happens.

Current Position explains what the focused work is changing.

Working Context is still useful, but subordinate.

### Current Position vs Museum of Evidence

Museum explains artifact curation.

Current Position explains why artifacts matter.

Museum is passive unless connected to claims.

### Current Position vs Living Brief

Living Brief explains how reasoning becomes readable.

Current Position explains the reasoning state before it is rendered.

Living Brief is a render target or executive expression.

### Current Position vs Oracle With Footnotes

Oracle explains how a position speaks.

Current Position explains what is speaking.

Oracle should not become the ontology.

### Current Position vs Evidence Studio

Evidence Studio explains artifact work.

Current Position explains evidence relevance.

Evidence Studio can become a position evidence editor.

### Current Position vs Current Architecture

Current architecture is capability-rich and contract-driven.

Current Position would not replace it.

It would create a new product-facing composition layer over it.

## Mental Model

The closest physical object is not one thing.

Current Position is part:

- patient chart;
- case file;
- scientific hypothesis;
- legal brief;
- flight plan;
- research notebook;
- decision memo;
- mission status.

The best single analogy:

```text
Current Position is a live case file for analytical judgment.
```

Why case file?

- It has a question.
- It has evidence.
- It has claims.
- It has contradictions.
- It evolves.
- It can be reviewed.
- It can support action.
- It can be reopened.
- It can become historical.

But it should not inherit detective theater. The case file is an ontology analogy, not a visual mandate.

## Product Identity

If Current Position became the primary object, the sentence becomes:

```text
Analytics Workstation is an evidence-centered analytical operating environment
that maintains the current responsible position of a project and shows what
supports it, what weakens it, what follows from it, and what would change it.
```

Shorter:

```text
Analytics Workstation helps teams know what they can responsibly believe and do next.
```

Even shorter:

```text
Analytics Workstation is a system for maintaining responsible analytical positions.
```

## Consequences

### What Would Need To Change

Eventually, if the prototype succeeds:

- top-level navigation would become less central;
- Evidence Review and Decision Management would become position perspectives;
- artifacts would be shown primarily through claim relevance;
- reports would render positions;
- AI actions would target position explanation and revision;
- semantic continuation would become position continuity;
- project opening would prioritize current question and position;
- outcome learning would update or supersede positions.

### What Would Stay

The following should remain:

- artifact model;
- evidence routing;
- knowledge state;
- governance;
- decision workflow;
- valuation;
- GenAI contracts;
- action layer;
- runtime bundles;
- QA;
- project storage;
- Working Context implementation as existing product surface;
- canonical service ownership.

### What Becomes Unnecessary

Potentially reduced:

- page-first orientation;
- destination-first navigation;
- repeated "where do I go next?" logic;
- generic module launch thinking;
- static summaries disconnected from claims;
- chat as primary AI surface.

### What Becomes More Important

More important:

- claim decomposition;
- position versioning;
- stale-state detection;
- evidence-to-claim footnotes;
- competing positions;
- contradiction state;
- position history;
- outcome learning;
- decision readiness;
- deterministic synthesis before GenAI prose.

## Recommendation

Current Position OS should become the next prototype.

But with strict boundaries.

### Why Prototype

It answers a real product failure discovered through populated replay:

```text
The user loses reasoning momentum because the thought itself is not carried.
```

It is also compatible with the existing architecture. It does not require throwing away evidence, artifacts, governance, decisions, Working Contexts, or AI contracts.

It gives the product a stronger primary object than page, room, dashboard, module, or report.

### Why Not Commit Yet

The concept can still fail.

It may:

- become a summary page;
- hide exploration;
- over-anchor users;
- frustrate experts;
- duplicate services;
- collapse into AI answer UI;
- make multiple investigations awkward.

Therefore the next step should be a prototype designed to falsify it.

### Prototype Hypothesis

```text
A user can remain better oriented across Evidence Review and Decision Management
when a durable Current Position carries question, answer, evidence, contradiction,
alternatives, recommendation, governance, and next thought.
```

### Falsification Criteria

Reject or demote Current Position OS if:

- users still need to reconstruct reasoning after transitions;
- the surface feels like a dashboard or memo;
- alternatives become less visible;
- experts feel trapped;
- claims cannot be challenged naturally;
- evidence feels hidden;
- the concept requires duplicating existing services;
- the user asks "where are the real tools?"

## Open Questions

1. Is Current Position one object per project, or many scoped objects?
2. What is the smallest viable claim model?
3. How should competing positions appear without becoming a list of pages?
4. When should Current Position update automatically versus require review?
5. What does a stale Current Position look like?
6. How much can be deterministic before GenAI enters?
7. Should AI propose position revisions or only explain them?
8. How does Current Position relate to Knowledge State promotion?
9. Can outcome learning update Current Position without creating revision chaos?
10. What does position history look like for humans?
11. What does position history look like for audit?
12. Can Current Position handle exploratory EDA before a decision exists?
13. Can it handle multiple simultaneous business questions?
14. Does it reduce cognitive load in real replay, or merely rename it?
15. What is the correct visual grammar for footnoted claims?

## Final Assessment

Current Position OS deserves to exist as a prototype candidate.

It should not yet become the product mandate.

The strongest finding is:

```text
Current Position is deeper than Semantic Continuation
and more fundamental than Working Contexts.
```

But the strongest warning is:

```text
Current Position OS will fail if it becomes a new page instead of a durable reasoning state.
```

The next design task should not be:

```text
Design the Current Position page.
```

It should be:

```text
Define the smallest Current Position object that can carry reasoning
across Evidence Review and Decision Management,
then prototype one surface that proves or falsifies the object.
```

If that succeeds, rebuilding the UI around Current Position becomes rational.

If it fails, the Working Context House remains the stronger organizing layer.

Either outcome improves the product.
