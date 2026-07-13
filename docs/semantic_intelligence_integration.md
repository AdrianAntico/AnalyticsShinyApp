# Semantic Intelligence Integration

Analytics Workstation exposes AutoQuant Semantic Intelligence through a
project-authored Semantic Intelligence workbench.

Phase 3 integration was intentionally narrow:

- surfaces the installed AutoQuant decision-management contract
- displays a deterministic decision context
- shows alternative assessment evidence
- shows optionality evidence
- shows canonical decision artifact metadata
- adds a command palette route
- does not create a new persistence model
- does not execute decisions
- does not optimize budgets or trigger actions

Phase 4 adds a durable decision lifecycle slice:

- project-state persistence for decision contexts, outcome reviews, and memory artifacts
- deterministic outcome review through `aq_review_decision()`
- lifecycle replay through `aq_decision_timeline()`
- learning summaries through `aq_decision_learning_summary()`
- canonical decision-memory artifact registration through `aq_decision_memory_artifact()`
- Project Artifact Collector append through the existing module-result path
- Mission Control signals for awaiting reviews, validated learning, and negative evidence
- bounded GenAI-ready context metadata without autonomous action execution

Phase 5 adds project-authored organizational knowledge:

- authored mission, objective, strategy, tactic, lever, KPI, guardrail, constraint, risk, assumption, authority, coverage, decision-context, alternative, recommendation, decision, review, and learning-summary objects
- create, edit, approve, archive, and restore-oriented lifecycle events through the project state
- deterministic version history for created, modified, approved, archived, retired, restored, superseded, and relationship-change events
- relationship editing for objective-strategy, strategy-tactic, tactic-lever, objective-KPI, strategy-assumption, decision-alternative, and related mappings
- integrity diagnostics for orphaned objects, broken references, missing KPI/authority/coverage/alternatives, duplicate mappings, and invalid lifecycle state
- deterministic search over authored objects
- lightweight relationship inspection without introducing a graph database
- Mission Control health signals for semantic workspace warnings, errors, review objects, and authored-object counts
- bounded GenAI project context containing semantic workspace summary counts only

Phase 6 replaces the production demo decision fallback with a fully authored
decision lifecycle:

- project-authored decision contexts, alternatives, lever settings, criteria,
  financial impacts, uncertainty, optionality, recommendations, human decisions,
  outcome reviews, and learning records
- deterministic validation before assessment, including stale-assessment,
  authority, coverage, workspace-reference, lever-actionability, permitted-range,
  validated-range, financial-evidence, uncertainty, and optionality diagnostics
- AutoQuant assessment through `aq_decision_context()`,
  `aq_assess_decision_alternatives()`, `aq_assess_decision_optionality()`, and
  `aq_review_decision()`
- canonical table artifacts for decision context, alternatives, assessment,
  recommendation, decision, outcome review, learning summary, and decision
  memory
- Project Artifact Collector append through the existing service-result path
- Mission Control signals for authored decision blockers, stale assessment,
  missing outcome review, and registered decision artifacts
- bounded GenAI context containing only decision lifecycle summary counts and
  campaign seed types
- deterministic campaign seed candidates for unresolved decision-lifecycle work

## Purpose

The page is the first app-facing bridge from business intent and variable
semantics into governed decisions. It helps users see that a recommendation is
not a single model output. A decision contains a question, baseline, alternatives,
criteria, financial evidence, uncertainty, optionality, authority, and follow-up.

## Current Contract

The workbench requires AutoQuant exports:

- `aq_decision_context()`
- `aq_assess_decision_alternatives()`
- `aq_assess_decision_optionality()`
- `aq_decision_context_artifact()`
- `aq_review_decision()`
- `aq_decision_timeline()`
- `aq_decision_learning_summary()`
- `aq_decision_memory_artifact()`

If these are unavailable, the page degrades to a warning rather than failing app
startup.

The authored business workspace also converts project-authored objects into the
AutoQuant business-intent contract when `aq_business_intent()` is available. The
app remains the authoring surface and project-state owner. AutoQuant remains the
canonical analytical contract provider.

## Project Persistence

The page stores legacy durable decision memory in the project state under
`decision_memory_state`:

- `decisions`
- `reviews`
- `artifacts`
- `last_result`
- `message`

This preserves decision memory with the same project save/load lifecycle used by
plots, module artifacts, report plans, feature experiments, and analytical
campaigns.

The fully authored lifecycle is stored separately under `semantic_decision_state`:

- `contexts`
- `alternatives`
- `lever_settings`
- `criteria`
- `financial_impacts`
- `uncertainties`
- `optionality`
- `recommendations`
- `decisions`
- `reviews`
- `assessments`
- `artifact_registry`
- `history`

The app owns the authoring surface and project persistence. AutoQuant owns the
canonical decision contracts and deterministic assessments.

The page stores authored organizational knowledge under `semantic_workspace`:

- `objects`
- `relationships`
- `history`
- `schema_version`
- `project_id`

Objects are archived or retired instead of being silently deleted. This keeps the
project reproducible and allows future decision/recommendation lineage to explain
which business context existed at the time evidence was created.

## Collector Integration

Decision memory artifacts are converted into standard app table artifacts and
submitted to the Project Artifact Collector through
`append_module_result_to_collector()`. The page does not write DOCX files or
collector manifests directly.

## Mission Control

Mission Control reads the decision-memory summary and can surface:

- decision contexts awaiting outcome review
- validated decision learning
- negative decision evidence or failed assumptions
- decision-memory artifact counts

Mission Control also reads the semantic workspace summary and can surface:

- authored business object counts
- objects awaiting review
- semantic integrity warnings and errors
- relationship counts
- the latest lifecycle event

These signals are operational cues. They do not execute actions, approve
decisions, or modify authored objects.

Mission Control also reads the authored decision lifecycle summary and can
surface:

- decision lifecycle validation errors
- decision lifecycle validation warnings
- stale assessments
- authored contexts that have not been assessed
- human decisions without outcome reviews
- decision lifecycle artifact counts

## GenAI Context

GenAI project context includes a bounded semantic workspace summary:

- total objects
- draft, review, and approved counts
- relationship count
- validation warning and error counts
- latest lifecycle event

Full authored object content is intentionally omitted by default. The context is
for read-only explanation and next-action guidance, not autonomous decision
execution.

GenAI project context also includes a bounded authored-decision summary:

- context, alternative, criteria, financial, uncertainty, optionality,
  recommendation, decision, and review counts
- validation error and warning counts
- assessment status
- registered decision artifact count
- deterministic campaign seed count and seed types

Full alternatives, financial impacts, uncertainty records, and human decisions
are intentionally omitted by default.

## Remaining Future Integration

Future phases may add:

- persisted variable semantics editing
- richer GenAI context routing over decision artifacts
- knowledge promotion workflows over validated decision memory
- richer object-level bounded context strategies for authored organizational knowledge
- relationship graph visualization
- richer review calendars and decision follow-up workflows

The current workbench still avoids autonomous execution, optimization, approval
automation, and enterprise workflow integration. Deterministic fixtures remain
available only for QA and cookbook examples; they are not used as the production
decision-lifecycle path.

## Cookbook

1. Create or load a project.
2. Open **Semantic Intelligence**.
3. Author a mission, objective, strategy, tactic, lever, KPI, authority, coverage,
   and decision context.
4. Link the objects in the Relationship Editor.
5. Review Integrity Validation. Repair missing KPI, authority, coverage, or
   decision-alternative diagnostics before relying on the workspace downstream.
6. Approve stable objects. Leave uncertain objects in draft or review.
7. Use **Authored Decision Lifecycle** to enter the decision context, baseline,
   alternatives, lever settings, criteria, financial evidence, uncertainty, and
   optionality.
8. Run **Assess Authored Decision** to create a deterministic AutoQuant
   assessment.
9. Record the recommendation and human decision when the package is ready.
10. Add the outcome review after the decision has produced real evidence.
11. Register decision lifecycle artifacts so the Project Artifact Collector
    preserves the evidence.
12. Check Mission Control for semantic workspace health, decision lifecycle
    status, stale assessments, and decision-memory status.
