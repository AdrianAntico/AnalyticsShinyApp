# Spatial Information Architecture Phase 2

Phase 2 turns the Product Geography Lab from conceptual comparison into a clickable research surface.

The goal remains exploration, not production replacement. The production shell is unchanged. The lab now lets the founder compare three materially different spatial organizations over the same fixture state:

- Working Context House;
- Evidence-Centered Studio;
- Mission Control Hallway.

Each prototype uses the same project, business question, selected artifact, evidence sufficiency state, alert state, and recommended next action. The prototypes differ only in spatial organization, focal object, action placement, help placement, progressive disclosure, and developer-surface treatment.

## Shared Fixture

The fixture state is:

```text
Project: Creative Attribute Testing Demo
Business question: Which creative attributes should we test next?
Current stage: Evidence Review
Selected artifact: SHAP Dependence: Creative A
Evidence sufficiency: Reasonable, not high confidence
Highest priority signal: Contradictory evidence between importance and segment stability
Recommended next action: Review contradiction and generate segment stability evidence
```

Every prototype must preserve this state. A prototype does not receive better content, richer evidence, or a more complete workflow than another.

## Screenshot-Based Layout Audit

The Phase 2 audit records concrete placement observations across current app surfaces. It intentionally avoids vague findings such as "too many cards." Each observation names:

- current primary object;
- actual primary task;
- visual focal point;
- first actionable control;
- placement observation;
- governing principle;
- recommended Phase 2 experiment.

Pages covered:

- Guide;
- Evidence Review;
- Knowledge Library;
- Mission Control;
- AI Runtime;
- Product Experience;
- Project;
- Data Workspace;
- Plots;
- Analysis Modules;
- Workflow;
- Semantic Intelligence;
- Causal Intelligence;
- Artifact Studio;
- Decision surfaces;
- developer-oriented pages.

The audit is available through:

```r
product_geography_screenshot_layout_audit()
```

## Product Geography Constitution

Phase 2 refines the placement rules:

| Rule | Meaning |
| --- | --- |
| Primary-object rule | Every task surface must have one visually dominant object. |
| Primary-action rule | Primary actions must be obvious, adjacent to readiness/configuration, and reachable for long tasks. |
| Help where uncertain | Help belongs where uncertainty occurs, not as an arbitrary floating destination. |
| Attention hierarchy | State, task, action, evidence, depth, diagnostics, and architecture should not render as peer cards. |
| Working-set rule | Show current tools and outputs first; keep adjacent tools discoverable and unrelated tools quiet. |
| Stable-landmark rule | Prototypes may vary, but users need consistent landmarks. |
| Context-preservation rule | Deep tools must preserve originating task, selected object, return path, and workflow stage. |
| Visual-awe rule | Progressive disclosure should still create curiosity, trust, and comprehension. |
| Developer-backstage rule | QA, replay, code, provider diagnostics, and architecture tools belong backstage. |

## Clickable Prototypes

The Product Experience Lab now contains:

- prototype selector;
- representative page selector;
- primary-action placement selector;
- Guide/help placement selector;
- route buttons for the selected geography;
- layout-zone preview;
- page preview over the shared fixture state;
- synthesis candidate display.

The route buttons are not production navigation. They are a low-to-medium-fidelity interaction model for feeling where each geography wants adjacent work to live.

## Prototype 1: Working Context House

Working Context House organizes the product as task rooms:

```text
Home
Analyze
Decide
Monitor
Learn
Create
Develop
```

Its primary object is the current Working Context. It is currently the strongest hypothesis for balancing orientation, task flow, discoverability, and expert depth.

Developer tools live in Develop / Backstage.

## Prototype 2: Evidence-Centered Studio

Evidence-Centered Studio makes the selected work product or evidence canvas central:

```text
Studio
Evidence
Inspector
Timeline
Deliver
Learn
Backstage
```

It is strongest once evidence exists. It makes artifacts feel tangible and inspectable. Its risk is that setup and execution tasks may not fit a literal studio pattern.

## Prototype 3: Mission Control Hallway

Mission Control Hallway treats entry as orientation through project status:

```text
Today
Attention
Current Work
Rooms
History
Learn
Backstage
```

It is promising for returning users, active projects, unresolved blockers, and resumable work. It should route into task rooms rather than monopolize execution.

## Layout-Zone System

Each prototype demonstrates the same zone vocabulary:

- global orientation;
- room/context navigation;
- task header;
- primary canvas;
- primary action;
- contextual actions;
- supporting evidence;
- inspector;
- progressive-depth region;
- status and audit;
- developer/debug region.

Each zone declares:

- purpose;
- content eligibility;
- visibility rule;
- priority;
- responsive behavior.

## Representative Pages

The lab applies each geography to a bounded representative set:

- Guide / Home;
- Evidence Review;
- Mission Control;
- Data or Analyze Entry;
- Developer Backstage.

This covers orientation, task execution, monitoring, analytical entry, and backstage isolation without redesigning every page.

## Action Placement Experiment

Phase 2 compares three primary-action patterns:

| Pattern | Best For |
| --- | --- |
| Sticky Task Action Bar | Long configuration workflows and expert iteration. |
| Context Header Action | Short tasks with compact readiness state. |
| Configuration Summary Action | Analysis modules, model runs, plot builds, and validation-sensitive execution. |

Preliminary rule:

Primary Run actions for long configuration workflows should live beside a compact configuration/readiness summary, with a sticky task action bar for long forms and a disabled explanation when unavailable.

## Guide and Help Placement

Phase 2 tests:

- global Guide destination;
- page-level "Explain this page";
- contextual explanation beside complex controls;
- guided mode;
- persistent help affordance.

Preliminary rule:

Guide should orient at the front door, explain pages near task headers, answer control-level uncertainty inline, and remain available as a compact contextual mentor.

## Progressive Disclosure

Disclosure patterns are semantic:

- summary -> expand;
- primary -> advanced;
- current -> history;
- conclusion -> supporting evidence;
- result -> diagnostics;
- task -> architecture;
- normal mode -> developer mode.

The product should not become a uniform sea of accordions.

## Synthesis Candidate

The leading synthesis is:

```text
Guide / Common front door
-> Mission Control hallway
-> Working Context rooms
-> Evidence-Centered Studio inside contexts
-> Developer Backstage
```

This synthesis should not become production navigation until founder review supports it.

## Rejected Layout Log

Rejected or suspect patterns:

- implementation-sequence navigation;
- AI as a primary room;
- developer tools in normal navigation;
- Run button only after long configuration;
- uniform card wall;
- generic accordion depth.

Each may return only under explicit conditions, usually developer mode or a narrowed task-specific use.

## Founder Resonance Review

The founder review captures:

- immediate emotional reaction;
- first focal point;
- perceived purpose;
- expected next action;
- expected adjacent-work location;
- overwhelm;
- obscurity;
- elegance;
- visual interest;
- friction;
- trust;
- inevitability;
- artificiality;
- what to steal;
- what to discard.

This is a taste-discovery phase. Free-form reactions are as important as scores.

## Current Phase 2 Assessment

Preliminary answers:

- Clearest common geography: Working Context House.
- Strongest task flow: Working Context House.
- Best balance of discoverability and calm: Working Context House plus Mission Control Hallway.
- Clearest action placement: Configuration Summary Action for analysis execution, Context Header Action for short tasks, Sticky Task Action Bar for long forms.
- Primary Run actions for long forms: beside compact readiness/configuration summary, with sticky access while scrolling.
- Guide/help role: orient at front door, explain page/task uncertainty, support controls inline, and remain context-aware.
- Patterns to retire: implementation-sequence top nav, AI as a destination, developer tools in normal navigation, bottom-only run buttons, uniform card walls, generic accordions.
- Strengths to preserve: dark-first theme, Artifact Studio preview, command palette, status badges, table styling, Guide/Working Context philosophy.
- Hybrid synthesis: currently more promising than any pure prototype, but requires founder review.

## QA

`qa_product_geography_phase2_lab()` verifies:

- Phase 2 does not replace production;
- prototype registry;
- fixture equivalence;
- representative pages;
- layout zones;
- primary-action patterns;
- help patterns;
- progressive disclosure;
- navigation alternatives;
- layout generation;
- clickable route metadata;
- developer-surface isolation;
- stable landmarks;
- context return paths;
- screenshot audit;
- founder resonance framework;
- campaigns;
- rejected layout log;
- final assessment;
- documentation.

The QA checks structure and contract completeness. It does not automate aesthetic judgment.
