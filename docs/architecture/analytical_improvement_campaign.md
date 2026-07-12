# Agent-Led Analytical Improvement Campaign

Phase 28 added a bounded analytical improvement campaign layer.

Phase 29 extends that layer from a single opportunity into an adaptive sequence of bounded opportunities.

The campaign is not a workflow engine, AutoML loop, or autonomous adoption system. It coordinates existing deterministic operators:

```text
bounded evidence context
-> evidence sufficiency assessment
-> situation assessment
-> ranked opportunities
-> feature proposals
-> approval pause
-> Rodeo execution
-> challenger dataset
-> CatBoost challenger comparison
-> deterministic interpretation
-> learning assessment
-> campaign memory
-> reprioritized remaining opportunities
-> synthesis / next action
```

## Ownership

AnalyticsShinyApp owns campaign planning, opportunity ranking, memory, synthesis, Mission Control visibility, and project-state persistence.

Feature Experiment Loop owns proposal validation, Rodeo execution, challenger experiment creation, comparison, interpretation, adoption, and reconciliation.

Rodeo owns transformation fit/apply behavior.

AutoQuant owns CatBoost model fitting.

GenAI may assist with future opportunity narrative, but Phase 28 does not require a live provider and does not allow arbitrary code generation.

## Campaign Contracts

The campaign layer introduces three lightweight contracts:

- `analytical_campaign_v1`
- `analytical_campaign_plan_v1`
- `analytical_campaign_synthesis_v1`

These live inside project state through the existing project save/load path. They do not create a separate persistence framework.

## Evidence Model

Campaigns consume the existing bounded feature experiment evidence context:

- project id
- target
- feature manifest
- dataset schema summary
- artifact references
- prior feature experiment outcomes
- baseline metadata when available

Raw rows are not included in campaign context.

Before opportunity discovery, campaigns create a deterministic evidence assessment. The assessment records:

- readiness: `insufficient`, `preliminary`, `reasonable`, or `strong`
- confidence score
- missing evidence gaps
- uncertainty signals
- dataset schema, feature, artifact, prior-outcome, and raw-row counts
- baseline availability
- recommendation

Insufficient evidence blocks the campaign before opportunity discovery. Preliminary evidence may still produce bounded opportunities, but ranking is conservative and challenger comparison may pause until a frozen baseline exists.

## Opportunity Ranking

`analytical_campaign_discover_opportunities()` reuses `generate_feature_proposals()` and assigns a deterministic score based on:

- expected impact
- Rodeo feasibility
- approval/risk tier
- prior-outcome reuse

Previously evaluated opportunities are penalized or skipped rather than rediscovered as fresh ideas.

After each completed opportunity, `analytical_campaign_reprioritize()` updates the remaining opportunity list using campaign memory:

- accepted improvements
- rejected improvements
- failed executions
- superseded proposals
- completed opportunity ids
- dependency status
- minimum usefulness threshold
- current evidence readiness
- prior learning value

This avoids circular recommendation loops and makes each completed opportunity influence the next decision.

## Opportunity Dependencies

Opportunities may declare prerequisite opportunity ids. A dependent opportunity is marked `blocked_dependency` until its prerequisite appears in `completed_opportunity_ids`.

The campaign does not execute dependent work speculatively.

## Evidence Sufficiency

Campaigns distinguish weak evidence from blocked execution.

Evidence is insufficient when the campaign lacks a usable dataset schema, target, or feature manifest. In that case the campaign status is `blocked`, the event history records `evidence_insufficient`, and execution returns structured `needs_input` with the evidence recommendation.

Evidence is preliminary when the core schema/target/features exist but artifact evidence or a frozen baseline is missing. Preliminary campaigns can rank and execute bounded deterministic proposals, but they remain explicit about expected pauses and uncertainty.

Evidence is reasonable or strong when artifacts and, ideally, prior outcomes exist. Strong evidence allows prior campaign/feature outcomes to influence future ranking more naturally.

## Approval Model

Campaign execution pauses at the feature proposal approval gate unless explicit approval is supplied.

This preserves the existing governance rule:

> Evidence can recommend action. It cannot authorize transformation execution by itself.

## Execution

`analytical_campaign_execute_next()` executes one ranked opportunity at a time.

With approval it:

1. approves the supported feature proposal
2. executes the proposal through Rodeo
3. records execution memory
4. runs a CatBoost challenger when a frozen baseline is supplied
5. records accept/reject/inconclusive memory
6. records proposal and experiment lineage
7. marks the opportunity completed
8. reprioritizes remaining opportunities
9. returns the next campaign state

Without a baseline, the campaign records `awaiting_baseline` after the deterministic Rodeo execution.

Campaign execution refuses to continue through governance gates. If the status is `awaiting_approval`, `awaiting_adoption_decision`, `awaiting_baseline`, or `blocked`, a repeated execute call returns structured `needs_input` rather than continuing silently.

## Campaign Memory

Campaign memory records:

- evaluated opportunities
- completed opportunities
- proposals
- executions
- experiments
- accepted experiments
- rejected experiments
- inconclusive experiments
- failed executions
- blocked items
- skipped items
- superseded ideas
- facts learned
- evidence collected
- hypotheses supported
- hypotheses rejected
- hypotheses still uncertain
- unresolved questions
- newly created questions
- learning assessments
- supporting evidence references
- proposal lineage
- experiment lineage
- adoption lineage
- event history

This memory is intentionally compact and project-state compatible.

## Learning Assessment

Phase 31 adds deterministic learning assessment for each completed opportunity.

The campaign now separates two questions:

1. Did the challenger improve the model outcome?
2. Did the opportunity reduce analytical uncertainty?

The first question is answered by the existing deterministic baseline/challenger comparison. The second is answered by `analytical_campaign_learning_assessment()`, which records:

- uncertainty before and after
- expected evidence
- observed evidence
- model outcome
- learning outcome
- confidence change
- unresolved questions
- newly created questions
- whether the result was informative
- whether repeating the same test is likely to add value
- whether the hypothesis should be retired or revised
- recommendation

Learning outcomes are deterministic labels:

- `resolved`
- `reduced_uncertainty`
- `maintained_uncertainty`
- `shifted_uncertainty`
- `failed_to_generate_useful_evidence`

Rejected challenger experiments may still reduce uncertainty by retiring a weak hypothesis. Inconclusive experiments preserve or shift uncertainty and should not be repeated without new evidence.

## Closure Assessment

Phase 32 adds deterministic campaign closure assessment. Closure is not just the absence of remaining queued work. It evaluates:

- campaign objective
- opportunities completed
- remaining candidate opportunities
- blocked or deprioritized opportunities
- evidence sufficiency
- learning assessments
- uncertainty reduced
- unresolved questions
- failed executions
- expected value of the next opportunity
- governance status

`analytical_campaign_closure_assessment()` returns a deterministic recommendation:

- `ready_for_closure`
- `continue_campaign`
- `await_approval`
- `await_additional_evidence`
- `blocked`
- `requires_human_judgment`

Campaign confidence is deterministic. It is computed from evidence sufficiency, learning outcomes, unresolved questions, failed executions, and remaining opportunities. It is not probabilistic model confidence.

## Knowledge Promotion

Campaign learning can become reusable analytical knowledge only when supported by enough evidence.

Promoted knowledge remains inside the existing campaign evidence model. The app does not create a global knowledge graph or new memory system.

Promotion examples:

- accepted or resolved hypotheses become supported campaign knowledge
- rejected but informative hypotheses become repeat-avoidance guidance
- weak or inconclusive learning remains campaign-local historical evidence

Promoted knowledge records include campaign, opportunity, proposal, support level, evidence references, and future guidance. Future campaigns may consume these records through `analytical_campaign_apply_promoted_knowledge()` to deprioritize repeated low-learning ideas or lightly prioritize supported bounded hypotheses. They are guidance, not mandatory rules.

## Cross-Campaign Knowledge Validation

Phase 33 adds governed validation for promoted knowledge across campaigns. Promotion no longer implies permanence.

Promoted knowledge records carry deterministic lifecycle identity:

- `knowledge_id`
- `knowledge_fingerprint`
- `campaign_origin`
- `supporting_campaigns`
- `supporting_experiments`
- `supporting_artifacts`
- `promotion_date`
- `promotion_reason`
- `promotion_confidence`
- `validation_history`
- `current_status`
- `superseded_by`
- `retired_reason`
- `reopening_conditions`

The deterministic fingerprint prevents duplicate promoted knowledge for the same analytical conclusion and proposal context. If a later campaign promotes the same knowledge again, the lifecycle registry merges support rather than creating a duplicate item.

`analytical_campaign_validate_promoted_knowledge()` compares a campaign's learning evidence against existing promoted knowledge. Relationships are deterministic:

- `supports`
- `contradicts`
- `extends`
- `narrows`
- `supersedes`
- `unrelated`

The function returns an updated lifecycle registry, validation history, conflict records, and a status summary.

Knowledge statuses are governed:

- `candidate`
- `promoted`
- `validated`
- `strengthened`
- `weakened`
- `superseded`
- `retired`
- `blocked`

Historical records are preserved. Superseded or retired knowledge remains inspectable and traceable to the evidence that originally promoted it. Validation strength is deterministic and explainable. It uses supporting campaigns, supporting experiments, contradictory evidence, and current campaign evidence. It is not Bayesian confidence and does not claim probabilistic truth.

## Supersession and Retirement

Supersession is explicit. When new campaign evidence contradicts or replaces older promoted knowledge, the older record is marked as `superseded` rather than deleted.

Retirement is explicit through `analytical_campaign_retire_knowledge()`. Retirement records a reason and preserves the historical knowledge item for audit and learning.

Future campaigns consume only active knowledge statuses:

- `promoted`
- `validated`
- `strengthened`

Weakened, superseded, retired, and blocked knowledge remains visible but is not used for prioritization guidance.

## Knowledge Review

`analytical_campaign_knowledge_review()` summarizes lifecycle counts by status. Campaign synthesis exposes the lifecycle registry, validation history, conflicts, and review summary. Mission Control surfaces campaign knowledge health through existing campaign visibility, including validated knowledge and conflict counts. No new dashboard is introduced.

## Reopening Guidance

Campaigns record deterministic reopening conditions. A campaign should not reopen merely because time passed.

Supported reopening triggers include:

- new data
- new model
- new evidence
- new deterministic operator capability
- new transformation support
- new business objective
- significant performance regression
- additional evidence for campaigns previously blocked by weak evidence

## Campaign Timeline

`analytical_campaign_timeline()` returns an ordered timeline derived from campaign event history. Timeline entries include:

- approval pauses
- executions
- experiments
- learning assessments
- reprioritization
- completion or stopping decisions

Timeline entries reference existing ids instead of duplicating artifacts.

## Synthesis

`analytical_campaign_synthesis()` produces the campaign summary:

- objective
- evidence reviewed
- evidence assessment
- opportunities considered
- experiments executed
- accepted/rejected/inconclusive improvements
- facts learned
- supported/rejected/uncertain hypotheses
- unresolved and newly created questions
- learning summary
- closure assessment
- knowledge promoted
- knowledge intentionally not promoted
- knowledge lifecycle registry
- knowledge validation history
- knowledge conflicts
- knowledge review summary
- reopening guidance
- blocked/skipped items
- superseded items
- supporting evidence references
- proposal and experiment lineage
- remaining opportunities
- ordered event history
- recommendation

The synthesis is evidence-linked and deterministic.

## Mission Control

Mission Control now summarizes:

- total campaigns
- active campaigns
- approval waits
- adoption waits
- blocked campaigns
- completed campaigns
- latest status
- latest evidence readiness
- remaining opportunities
- completed opportunities
- learning assessments
- uncertainty reduced
- closure recommendation
- campaign confidence
- promoted knowledge count
- knowledge awaiting validation
- validated or strengthened knowledge
- weakened or superseded knowledge
- knowledge conflicts

Campaigns also contribute alerts when waiting for approval, blocked, or awaiting adoption.

## Stopping Rules

Campaigns stop or pause when:

- no candidate opportunities remain
- approval is required
- evidence is insufficient
- a baseline is missing
- an accepted challenger needs explicit adoption/defer decision
- a deterministic execution fails
- dependencies are unmet
- opportunity expected value falls below usefulness
- repeating an opportunity has low expected learning value
- closure assessment recommends no further value
- configured experiment limits are reached in future extensions

## QA

`qa_analytical_improvement_campaign()` verifies:

- campaign creation
- opportunity ranking
- plan generation
- approval pause
- approved execution
- campaign memory
- evidence assessment
- insufficient-evidence blocking
- learning assessment
- uncertainty reduction
- hypothesis memory
- repeat prevention
- learning synthesis
- closure recommendation
- campaign confidence
- knowledge promotion
- promotion thresholds
- cross-campaign knowledge validation
- knowledge strengthening
- knowledge weakening
- supersession
- retirement
- conflict detection
- duplicate prevention
- governed status transitions
- knowledge review summary
- reopening guidance
- future campaign reuse
- evidence traceability
- multiple sequential opportunities
- adaptive reprioritization
- dependency handling
- optional CatBoost baseline/challenger path
- stopping/continuation state
- restart/replay
- historical timeline
- remaining opportunity updates
- campaign synthesis
- reconciliation

## Non-Goals

- no AutoML
- no exhaustive feature search
- no arbitrary R generation
- no autonomous model adoption
- no new governance system
- no new persistence system
- no generic workflow engine
