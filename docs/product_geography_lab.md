# Product Geography Laboratory

Product Geography Laboratory Phase 1 is an exploratory product-design layer for Analytics Workstation.

The purpose is not to prove that one information architecture is correct. The purpose is to create several plausible spatial organizations, experience them side by side, preserve what resonates, reject what feels wrong, and let founder review shape the next iteration.

This phase changes organization, visibility, hierarchy, grouping, and navigation language only. It does not change analytical services, artifact contracts, Working Contexts, GenAI governance, evidence routing, storage, runtime behavior, or workflow execution.

## Operating Philosophy

Analytics Workstation should be understood as a working environment, not a stack of tabs.

The current architecture is powerful, but architecture is not the user's map. A user should not need to know that the system contains an Artifact Model, Project Artifact Collector, Evidence Routing, Context Optimization, Knowledge Compilation Runtime, and Action Registry in order to do useful work. Those systems remain real, but they should appear through product geography only when they help the user understand the work.

Product Geography treats the application as a place:

- entry halls;
- workbenches;
- galleries;
- decision tables;
- preparation benches;
- delivery rooms;
- libraries;
- control rooms;
- utility rooms;
- developer backstage.

The question is not "where does this implementation component belong?" The question is:

```text
Where would a competent analyst expect to find this kind of work?
```

## Principles

The lab uses these principles:

| Principle | Product Rule |
| --- | --- |
| Intent before capability | Ask what the user is trying to accomplish before showing every module. |
| Task before tool | Organize by analytical work, not implementation surface. |
| Orientation before exploration | Users should know where they are and why they are there before browsing. |
| Working set before catalog | The active work deserves more prominence than the full feature list. |
| Evidence as center | Artifacts, findings, contradictions, sufficiency, and recommendations should be spatially adjacent. |
| Utility rooms stay quiet | Settings, runtime, QA, provider diagnostics, and replay should not define normal use. |
| Developer space is backstage | Developer power remains available without becoming first-hour geography. |
| AI is a mentor, not a room | AI follows work and explains it; it should not become a destination users must manage. |
| Progressive mastery | Power appears as work deepens. |
| Rejection is evidence | A prototype that feels wrong is useful if it narrows the geography. |

## Candidate Prototypes

### Common Geography

Common Geography uses familiar product labels:

```text
Guide
-> Data
-> Prepare
-> Analyze
-> Evidence
-> Decide
-> Deliver
-> Learn
-> Developer
```

This is the safest and most legible map. It reduces immediate confusion but risks feeling like a normal analytical application. It may be useful as a fallback or as a bridge for first-time users.

### Working Context House

Working Context House treats the product as rooms around the active work:

```text
Guide Hall
-> Current Workbench
-> Evidence Gallery
-> Decision Table
-> Delivery Room
-> Knowledge Library
-> Utility Room
-> Developer Backstage
```

This is currently the strongest hypothesis. It preserves the architecture while giving the user a natural place to stay. The Working Context becomes the room where meaningful work happens, and adjacent rooms remain available without crowding the workbench.

### Evidence-Centered Studio

Evidence-Centered Studio makes artifacts the central object:

```text
Evidence Wall
-> Evidence Inspector
-> Evidence Filmstrip
-> Decision Table
-> Delivery
```

This is likely the most memorable artifact-centered geography. It makes the philosophy visible immediately once evidence exists. Its risk is that data loading, preparation, and execution can become secondary unless the transition into the studio is designed carefully.

### Mission Control Hallway

Mission Control Hallway treats status as the route into work:

```text
Mission Control
-> Alert
-> Room opened by status
-> Return to Mission Control
```

This may be strongest for returning users. It frames Mission Control as a hallway, not the house. The user enters the room that needs attention. The risk is that the product can feel operationally heavy if the user has not yet experienced analytical value.

### Decision Theater

Decision Theater centers the business question or decision:

```text
Decision Board
-> Evidence Docket
-> Risk and Review
-> Analysis Room
```

This is compelling for high-stakes use and executive framing. It may be premature for exploratory users who have data but no explicit decision yet.

## Spatial Rooms

The lab defines reusable room concepts:

| Room | Purpose |
| --- | --- |
| Guide Hall | Orient the user and ask what decision, question, or work state matters. |
| Current Workbench | Keep the active Working Context in one focused place. |
| Evidence Gallery | Browse, inspect, compare, and reason over artifacts as evidence. |
| Decision Table | Evaluate readiness, alternatives, claims, valuations, and next actions. |
| Preparation Bench | Prepare data and features without mutating original data. |
| Delivery Room | Create reports, exports, collector documents, and presentation-ready outputs. |
| Knowledge Library | Read product knowledge, ontology, architecture, and source chapters. |
| Mission Control | Inspect health, jobs, alerts, approvals, and operational risk. |
| Utility Room | Configure providers, storage, execution, themes, and environment checks. |
| Developer Backstage | Run QA, replay, code, package validation, and product experiments. |

The room names are not necessarily final UI labels. They are a design vocabulary for comparing placement and adjacency.

## Preliminary Assessment

These answers are product hypotheses before founder review:

| Question | Preliminary Answer |
| --- | --- |
| Which prototype felt most natural? | Working Context House. It maps to how people actually work: enter, focus, inspect evidence, decide, deliver. |
| Which best reduced overwhelm? | Working Context House, with Common Geography as the safer first-time fallback. |
| Which best preserved power? | Working Context House. It keeps adjacent rooms available while making current work primary. |
| Which had the strongest orientation? | Mission Control Hallway for returning users; Guide Hall or Common Geography for new users. |
| Which best supported Working Contexts? | Working Context House. It treats contexts as rooms rather than tabs or modules. |
| Which best hid architecture? | Evidence-Centered Studio and Working Context House both hide architecture well; Studio hides it most aggressively. |
| What should not survive? | Top-level navigation based on implementation sequence, developer tools in normal navigation, AI as a standalone destination, and module catalogs as the primary mental model. |
| What unexpectedly resonated? | Mission Control as a hallway, Developer as backstage, Artifact Studio as gallery/studio. |
| What should be explored next? | A clickable low-fidelity geography selector comparing Working Context House, Evidence-Centered Studio, and Mission Control Hallway against the same Golden Workflow. |

## Founder Review

Founder review should ask:

- Where did orientation happen fastest?
- Where did the product feel least like a normal Shiny app?
- Where did the user want to click next?
- Where did the architecture disappear?
- Where did power remain discoverable?
- What definitely should not survive?

Scores should be recorded with notes. A low score is useful when it explains what to reject.

## Campaigns

Initial campaigns:

| Campaign | Purpose |
| --- | --- |
| Working Context House comparison | Test whether a room-based working context geography reduces navigation while preserving depth. |
| Artifact Studio as center | Test whether making artifacts central communicates value faster than workflow-stage navigation. |
| Mission Control Hallway | Test whether returning users benefit from status-based routing. |
| Decision Theater fit | Test whether a decision-first room helps or constrains users before evidence exists. |
| Developer Backstage | Determine which developer and architecture surfaces should move backstage without harming developer workflows. |

## Open Questions

- Should the primary geography be organized by rooms, workflow stages, or selected evidence?
- Should Mission Control be a hallway, a room, or a compact status layer?
- Should Artifact Studio be the center of everyday work or appear only after evidence exists?
- Does Decision Theater resonate for exploratory users or only decision-ready projects?
- How much spatial metaphor helps before it becomes cute or distracting?
- What should the top navigation become if Product Geography wins over tab geography?

## QA

`qa_product_geography_lab()` verifies:

- exploratory status;
- prototype count;
- architecture preservation;
- Working Context placement;
- developer backstage placement;
- product geography principles;
- layout zones;
- navigation maps and return paths;
- comparison metrics;
- founder review prompts;
- prototype campaigns;
- direct final assessment questions;
- documentation;
- Working Context Framework regression.

The QA is intentionally structural. It does not declare a winning prototype.

## Phase 2 Extension

Spatial Information Architecture Phase 2 makes the leading alternatives clickable and experientially comparable.

Phase 2 focuses on:

- Working Context House;
- Evidence-Centered Studio;
- Mission Control Hallway.

The lab now includes prototype route buttons, representative page selection, primary-action placement experiments, Guide/help placement experiments, layout-zone previews, a screenshot-based layout audit, founder resonance framework, synthesis candidate, rejected-layout log, and Phase 2 campaigns.

Details live in:

```text
docs/product_geography_phase2.md
```
