# Governed Agent Operation and Observability

Analytics Workstation now supports a bounded agent-operation framework for demonstrating analytical investigation without granting unbounded autonomy.

The operating chain is:

```text
Agent intent
-> Governed app action
-> Deterministic service execution
-> AgentSession event
-> Observable UI representation
-> Replayable report evidence
```

## AgentSession

`AgentSession` is the durable record of an agent-operated investigation. It is versioned, serializable, and replayable without rerunning analysis.

It records:

- objective
- dataset manifest
- campaign type
- lifecycle status
- plan
- actions
- observations
- decision traces
- evidence references
- approvals
- service runs
- inquiry record
- warnings and errors
- report id
- presentation settings
- provenance

Lifecycle states are:

```text
created
planning
awaiting_approval
running
paused
completed
failed
cancelled
replaying
```

Transitions are centrally validated by the AgentSession lifecycle table. Illegal transitions throw deterministic errors.

## Actions

Agent actions are semantic operations, not browser coordinates.

Supported action types include:

- inspect_project
- inspect_dataset
- navigate
- configure_service
- run_service
- review_result
- record_observation
- record_decision
- request_approval
- receive_approval
- create_artifact
- build_report
- validate_report
- open_report
- pause
- resume
- complete
- fail

Each action records type, target, status, timestamps, label, rationale, evidence inputs, outputs, UI hints, and errors.

## DecisionTrace

`DecisionTrace` is the human-readable reasoning trace. It intentionally avoids hidden chain-of-thought capture.

Each trace records:

- goal
- observation
- decision
- basis
- evidence ids
- confidence
- alternatives considered
- next action

## Inquiry Record

The inquiry record is the exposed investigation state inside `AgentSession`. It is not a second workflow system and it is not hidden chain-of-thought. It records the governed reasoning artifacts that a human reviewer should be able to inspect:

- observation
- important uncertainty
- competing explanations
- candidate investigations
- selected investigation
- evidence collected
- belief update
- decision impact
- remaining uncertainty
- stopping rule

The first Build Week campaign uses this record to show how the campaign moves from initial uncertainty to evidence-backed belief revision. Explanations are statused as proposed, supported, weakened, rejected, or unresolved. Belief revisions keep the initial belief, evidence discovered, updated belief, decision impact, confidence, and evidence ids.

## Presentation Settings

Agent operation can be shown at different speeds without changing the underlying deterministic state.

Presets:

- Instant
- Follow Along
- Presentation
- Step-by-step

Settings control cursor display, dwell times, observation visibility, decision visibility, evidence visibility, raw events, auto-scroll, and approval gates.

## Mock Cursor

The mock cursor is an observability aid only. It moves between registered semantic targets and never controls the app by fragile screen coordinates.

If a target is missing, the cursor falls back to a safe generic page target and records a warning.

## Funnel Driver Campaign

`run_funnel_driver_investigation()` implements the first bounded campaign:

1. Validate dataset contract.
2. Run EDA report step.
3. Run Regression Model Insights report step.
4. Request approval before SHAP.
5. Run SHAP if approved.
6. Assemble campaign ReportContract.
7. Validate report.
8. Open Report Browser.
9. Complete session.

The campaign does not fabricate business conclusions. It records process observations derived from service output validation, evidence references, approval state, and report assembly.

The campaign also records competing explanations and candidate investigations before the optional SHAP step. This is intentionally bounded: the system exposes why the selected investigation was useful, how evidence changed the recommendation, and what uncertainty remains. It does not create autonomous plans beyond the registered campaign path.

## Replay

Replay consumes the recorded `AgentSession`. It does not rerun analytics services, rebuild artifacts, or mutate project state.

## Verification

The deterministic QA suite is `qa_agent_operation_runtime()`. It covers:

- session construction
- lifecycle validation
- action registry
- decision traces
- presentation settings
- pause/resume/step
- approval and rejection paths
- cancellation/failure
- serialization round-trip
- replay without rerun
- cursor fallback
- report validation
- claim traceability
- inquiry validation
- belief revision capture
- recommendation evolution
