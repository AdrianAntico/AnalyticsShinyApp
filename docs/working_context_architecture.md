# Working Context Architecture

Product Experience Runtime Phase 5 introduces Working Contexts.

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

## Progressive Depth

Working Context depth follows:

1. Current Question
2. Current Evidence
3. Reasoning
4. Diagnostics
5. Architecture

Each level expands naturally. Architecture remains available, but it should not interrupt normal work.

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

- explain evidence sufficiency;
- summarize contradictions;
- explain why a next action is recommended;
- draft a review request;
- explain valuation caveats.

AI should not represent the whole application or become a general-purpose chat surface in this context.

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

These are context campaigns, not module campaigns.

## Open Questions

The largest remaining question is whether Evidence Review can become the dominant work surface for decisions, or whether Decision Management should become its own next context.

The current recommendation is:

```text
Next Working Context: Decision Management
```

Reason: Evidence Review naturally hands off to proposal, review, approval, implementation, outcome, and learning. Decision Management is the best next test of whether Working Contexts can span longer-lived work without becoming a module directory.

## Completion Criterion

This phase succeeds when a user can remain inside one coherent Working Context for an extended period, performing multiple related tasks without repeatedly navigating the application or being overwhelmed by unrelated capabilities.
