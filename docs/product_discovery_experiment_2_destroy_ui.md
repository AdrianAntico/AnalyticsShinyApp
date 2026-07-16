# Product Discovery Experiment 2

Destroy the current UI and rediscover the product.

This is not a polish pass. It is not a layout pass. It is not another attempt to make the current pages feel better.

The working assumption is intentionally severe:

```text
The architecture is valuable.
The current interface is disposable.
```

The protected layer is the analytical architecture: projects, artifacts, evidence, decisions, governance, runtime, ontology, quality, replay, and QA. The unprotected layer is the human experience: pages, cards, panels, tabs, navigation, grouping, labels, and layout.

The purpose of this experiment is to ask whether Analytics Workstation has accidentally inherited too much enterprise-software syntax from dashboards, Shiny apps, module launchers, and admin consoles.

## Starting Question

If Analytics Workstation had never existed, but the underlying architecture already did, what should the product actually be?

Not:

```text
How do we improve the existing UI?
```

But:

```text
What human experience does this architecture want?
```

## Hard Rejections

Reject any concept whose first impression is:

- dashboard;
- module launcher;
- admin panel;
- grid of cards;
- tabs with prettier styling;
- enterprise cockpit;
- page full of boxes;
- Shiny app with better CSS.

Those may be useful implementation details later, but they are not product breakthroughs.

## Concept 1: Current Position OS

### Governing Philosophy

The product is not a set of pages. It is the evolving answer to the current business question.

Everything revolves around one durable object:

```text
Current Position
```

Current Position is the live analytical stance of the project:

- question;
- current answer;
- confidence;
- evidence basis;
- contradictions;
- unknowns;
- alternatives;
- recommendation;
- governance;
- next thought.

The user does not navigate to Evidence Review or Decision Management. The user watches the Current Position mature.

### Organizing Principle

The main screen is a position dossier.

It has a strong editorial hierarchy:

```text
Question
Current Position
Why we believe this
What weakens it
What decision follows
What must happen next
Evidence drawer
Governance drawer
Learning drawer
```

The product behaves less like a workstation and more like an active analytical brief that can expand into tools only when needed.

### Strengths

- Directly addresses the previous experiment's discovery.
- Reduces page cognition dramatically.
- Makes reasoning continuity the product center.
- Compresses evidence, decision, and governance into one object.
- Creates a natural place for AI guidance without becoming chat-first.
- Makes the app feel less like software and more like analytical thought made visible.

### Weaknesses

- Could become too document-like if not carefully interactive.
- May underexpose powerful capabilities for expert users.
- Requires excellent state summaries or the whole product feels vague.
- Harder to design than a page layout because the object must evolve across states.

### Why It Might Beat The Current Design

The current design still asks:

```text
Which room should I use?
```

Current Position OS asks:

```text
What do we currently believe, and what changes that belief?
```

That is a more fundamental analytical question.

### Why It Might Fail

If users need to perform many parallel analyses, one Current Position may feel too narrow. It may require a position switcher, which risks recreating navigation under a new name.

## Concept 2: Evidence Map

### Governing Philosophy

The product is a map of evidence relationships.

Artifacts are not cards. They are evidence nodes. Decisions, claims, contradictions, assumptions, and recommendations are also nodes.

The user moves through a reasoning graph, not pages.

### Organizing Principle

The main surface is a semantic map:

```text
Business Question
  -> Claims
    -> Supporting Evidence
    -> Contradicting Evidence
    -> Assumptions
  -> Alternatives
  -> Recommendation
  -> Review
  -> Outcome
```

Clicking a node opens a compact inspector. Edges explain relationships:

- supports;
- contradicts;
- depends on;
- supersedes;
- requires;
- tests;
- implements;
- validates.

### Strengths

- Makes the evidence architecture visible.
- Naturally represents contradiction and uncertainty.
- Could feel genuinely different from dashboards.
- Strong fit for causal reasoning, semantic intelligence, and knowledge state.
- Good for complex projects with many interacting claims.

### Weaknesses

- Graph UIs often become visually impressive but cognitively exhausting.
- Dense evidence projects can become hairballs.
- It may be slower for simple workflows.
- Requires strong graph layout and filtering decisions.

### Why It Might Beat The Current Design

The current UI spatially separates evidence, decisions, and governance. The Evidence Map reveals their relationships directly.

### Why It Might Fail

If users have to interpret graph topology before doing work, the graph becomes another kind of syntactic burden.

## Concept 3: Analytical Field Journal

### Governing Philosophy

Analysis is a chronological investigation.

The product should feel like a living research journal where every question, artifact, contradiction, decision, and outcome is recorded in order.

The user does not navigate pages. The user advances the investigation log.

### Organizing Principle

The central surface is a timeline/document hybrid:

```text
Question asked
Evidence generated
Finding recorded
Contradiction discovered
Position revised
Recommendation drafted
Review requested
Decision approved
Action implemented
Outcome observed
Knowledge updated
```

Each event is compact, expandable, and evidence-backed.

### Strengths

- Excellent for auditability and storytelling.
- Makes replay natural.
- Strong fit for governance, provenance, and book-like output.
- Easy for executives to understand.
- Avoids dashboard feeling by becoming narrative-first.

### Weaknesses

- Timelines are weak for comparing many simultaneous artifacts.
- Users may need faster analytical manipulation than a journal allows.
- Could become a report rather than a workspace.

### Why It Might Beat The Current Design

The current design shows state. The journal shows how state changed and why.

### Why It Might Fail

If the user wants to actively interrogate evidence rather than read the investigation, the journal may feel passive.

## Concept 4: Decision Theatre

### Governing Philosophy

The product is built around the moment of choice.

Everything exists to prepare, challenge, authorize, implement, and learn from decisions.

Evidence and artifacts are supporting actors. The decision is the stage.

### Organizing Principle

The interface resembles a decision hearing:

```text
Question before the room
Case for action
Case against action
Alternatives
Evidence exhibits
Risk and uncertainty
Recommendation
Objections
Approval conditions
Implementation record
Outcome review
```

The experience feels closer to a boardroom evidence hearing than a dashboard.

### Strengths

- Very strong for business value and investor demos.
- Makes governance and uncertainty visible without sounding academic.
- Naturally separates support, contradiction, risk, and action.
- Could produce a "holy shit" moment because the software feels like it is preparing a serious decision.

### Weaknesses

- May be too decision-centric for exploratory analytics.
- Could feel theatrical if overdone.
- Might underrepresent data exploration, feature engineering, and modeling workflows.

### Why It Might Beat The Current Design

The current design often asks users to inspect artifacts. Decision Theatre asks users to judge evidence.

That is closer to the commercial promise.

### Why It Might Fail

If users are not yet ready to decide, it may push them into judgment too early.

## Concept 5: Conversational Investigation

### Governing Philosophy

The product begins with a question and proceeds as a guided investigation.

The interface is not "chat beside app." The conversation is the spine, and deterministic tools become invoked evidence procedures.

The system asks:

```text
What decision are you trying to make?
What evidence would reduce uncertainty?
What do we know now?
What should we test next?
```

### Organizing Principle

The main surface is a structured dialogue with embedded evidence objects:

```text
User: Should we launch the offer?
System: Here is what we need to know.
Evidence block: model importance
Evidence block: holdout contradiction
System: The current position is bounded pilot, not rollout.
User: Why not rollout?
System: Because downside and stale holdout evidence weaken the broad claim.
Action: draft review package
```

The conversation is not free-form. It is governed by the ontology, evidence routing, context optimization, and action layer.

### Strengths

- Lowest navigation burden.
- Strong fit for business users.
- Naturally teaches the system.
- Makes AI feel central without hiding deterministic governance.
- Could feel radically different from the current app.

### Weaknesses

- High risk of feeling like "chat pasted into a dashboard" if execution is not crisp.
- Power users may feel constrained.
- Requires excellent deterministic grounding to avoid vague answers.
- Harder to visually communicate artifact richness.

### Why It Might Beat The Current Design

The current UI expects users to know which surface contains the next capability. Conversational Investigation lets the question pull capabilities forward.

### Why It Might Fail

If the conversation cannot reliably invoke, show, and preserve evidence, it becomes a chatbot wrapper rather than a product.

## Concept 6: Evidence Studio As Lightroom

### Governing Philosophy

Artifacts are the primary objects.

The user lives inside an evidence library where every artifact can be inspected, compared, routed, promoted, challenged, and composed.

Decisions emerge from curated evidence collections.

### Organizing Principle

The product is a professional evidence studio:

```text
Filmstrip of evidence
Focused artifact
Inspector
Claim stack
Contradiction stack
Decision tray
Collector memory
Story/export lane
```

The experience is more like Lightroom or Figma than a dashboard.

### Strengths

- Builds on Artifact Studio's strongest current product surface.
- Makes artifacts tangible and first-class.
- Excellent for visual analytics and evidence review.
- Strong fit for LLM artifact generation and collector workflows.

### Weaknesses

- Can underemphasize the business question.
- Artifact browsing can become another form of wandering.
- Decisions may feel downstream rather than central.

### Why It Might Beat The Current Design

The current app still has many pages. Evidence Studio could become the one place where the project feels alive.

### Why It Might Fail

If artifact inspection becomes the center, the product may optimize evidence browsing instead of decision quality.

## Concept 7: Mission Thread

### Governing Philosophy

The product is organized around active reasoning threads.

A thread is not a chat. It is a live analytical mission:

```text
Question -> evidence -> position -> decision -> action -> outcome
```

The user can have multiple threads, each with its own state, evidence, blockers, and next thought.

### Organizing Principle

The primary UI is a compact list of active mission threads. Selecting one opens its current state.

Each thread shows:

- question;
- current position;
- blocker;
- next thought;
- confidence;
- age;
- owner;
- evidence count;
- decision state.

The product becomes less like pages and more like managing serious analytical commitments.

### Strengths

- Generalizes Current Position across multiple investigations.
- Strong fit for Mission Control evolution.
- Naturally handles parallel work.
- Makes "what should I work on next?" central.

### Weaknesses

- Could drift back into task-management software.
- Needs careful design to avoid becoming a queue dashboard.
- Less immersive than Decision Theatre or Evidence Studio.

### Why It Might Beat The Current Design

The current app has destinations. Mission Thread has obligations.

### Why It Might Fail

If thread summaries are too shallow, users still have to open pages and reacquire context.

## Comparative Assessment

| Concept | Most Radical Shift | Best For | Main Risk |
| --- | --- | --- | --- |
| Current Position OS | Product revolves around belief state, not pages. | Reasoning continuity | Can become document-like |
| Evidence Map | Product becomes a semantic graph. | Complex evidence relationships | Graph overload |
| Analytical Field Journal | Product becomes investigation history. | Audit, replay, storytelling | Too passive |
| Decision Theatre | Product becomes decision hearing. | Commercial clarity | Too decision-centric |
| Conversational Investigation | Product becomes guided inquiry. | Low navigation burden | Chat wrapper risk |
| Evidence Studio As Lightroom | Product becomes evidence browser. | Artifact-centered work | Browsing without decision |
| Mission Thread | Product becomes active reasoning-thread manager. | Parallel investigations | Queue-dashboard risk |

## Recommendation

Prototype:

```text
Current Position OS
```

Not because it is the flashiest, but because it is the most fundamental.

The last experiment already discovered that Semantic Continuation is useful but incomplete. The real break was not the absence of a better button. The break was the absence of a durable object that carries reasoning across surfaces.

Current Position OS directly tests that discovery.

The prototype should not redesign the entire app. It should answer one question:

```text
Can the user remain oriented if the Current Position becomes the primary surface?
```

Minimum prototype:

```text
Business Question
Current Position
Evidence Basis
Contradiction
Alternatives
Recommendation
Governance Conditions
Next Thought
```

No cards unless unavoidable.

No module launcher.

No page grid.

No dashboard.

The first version can exist as a single experimental surface fed by the existing deterministic populated story. It should use the current architecture and services underneath, but ignore the current page layout.

## Concepts To Keep In Reserve

If Current Position OS succeeds, the next useful hybrids are:

1. Current Position + Decision Theatre
2. Current Position + Mission Thread
3. Current Position + Evidence Studio

These combinations are promising because they preserve one center of gravity:

```text
What do we currently believe, why, and what follows?
```

## Concepts To Avoid For Now

Avoid starting with:

- Evidence Map
- Conversational Investigation

Both are powerful, but both risk becoming technically impressive before the product knows its center of gravity.

Evidence Map could become a graph demo.

Conversational Investigation could become a chat demo.

Neither should come before Current Position is proven or rejected.

## Final Assessment

The current UI is not irredeemable, but it is still too page-shaped.

Working Contexts improved the problem. Semantic Continuation exposed the deeper issue. Current Position may be the real product object.

The most dangerous, useful conclusion is:

```text
Evidence Review and Decision Management might not be rooms.
They might be temporary views of Current Position.
```

That is the product experiment worth running next.

If it works, the current page model starts to dissolve.

If it fails, we learn that Working Contexts are still the better organizing layer.

Either result is useful.
