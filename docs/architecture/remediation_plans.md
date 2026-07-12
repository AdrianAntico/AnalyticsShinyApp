# Governed Remediation Plans

Phase 14 adds governed remediation plans as the stepwise execution layer above the Improvement Ledger.

The Improvement Ledger records findings, issues, UX friction, user requests, attempts, and re-evaluations. A remediation plan turns an accepted improvement item into a bounded, reviewable sequence of steps. It does not make GenAI autonomous. It does not introduce arbitrary actions. It does not bypass registered action validation, approval, delegation policy, isolated execution, storage gates, or durable audit.

The governing rule is:

```text
Improvement items identify what needs work.
Remediation plans describe the bounded path.
Registered actions and manual checkpoints perform only approved steps.
Re-evaluation determines whether the item improved.
```

## Schemas

Current schemas:

- `remediation_plan_v1`
- `remediation_plan_step_v1`
- `remediation_manual_input_v1`
- `remediation_decision_gate_v1`
- `remediation_plan_event_v1`
- `remediation_plan_template_v1`
- `remediation_plan_recovery_v1`
- `remediation_plan_checkpoint_v1`

Plan records are stored under trusted project storage:

```text
<ProjectRoot>/governance/remediation_plans/
  plans/<plan_id>.json
  events.ndjson
  checkpoints/checkpoint.json
```

Plan files are atomically replaced. Plan events are append-only NDJSON with hash chaining. The checkpoint records the latest event id and event hash for restart discovery.

## Lifecycle

Plan statuses:

```text
draft
validation_failed
awaiting_user_review
approved
queued
running
paused
awaiting_user_input
awaiting_step_approval
re_evaluation_required
succeeded
partially_succeeded
failed
cancelled
expired
superseded
```

Terminal statuses are `succeeded`, `partially_succeeded`, `failed`, `cancelled`, `expired`, and `superseded`. Terminal plans cannot resume.

The lifecycle map is centralized in code as the single source of truth for:

- allowed transitions
- terminal states
- resumable states
- approval-required states
- retryable states

Execution, pause, cancellation, expiration, re-evaluation, and QA all use this map rather than scattered conditional transition logic.

The normal path is:

```text
accepted improvement item
-> remediation template
-> plan validation
-> user review
-> approval
-> one-step execution
-> manual input or step approval when required
-> deterministic re-evaluation
-> succeeded / partially succeeded / re_evaluation_required / failed
```

## Step Types

Supported step types:

- `registered_action`
- `manual_user_input`
- `deterministic_re_evaluation`
- `decision_gate`
- `informational`

Registered-action steps may reference only existing GenAI action ids:

- `module.open`
- `artifact.inspect`
- `report.open`
- `analysis.preflight`
- `analysis.run_registered`
- `result.persist`
- `result.inspect`

The plan validator performs deterministic structure checks, action allowlist checks, risk checks, dependency checks, argument-shape checks, budget checks, runtime checks, retry checks, and unsafe-content checks. Live resource validation happens at step execution, not plan creation, because a plan may be prepared before a dataset, artifact, or temporary result is available.

## Approval Policy

Approval policies:

- `plan_structure_only`
- `plan_and_low_risk_steps`

`plan_structure_only` approves only the existence and structure of the plan. Every registered action still uses the normal GenAI action approval and delegation path.

`plan_and_low_risk_steps` can execute low-risk delegated steps when the step is explicitly delegation eligible and the action is low risk. It does not authorize computation, persistence, mutation, arbitrary code, or action chaining.

Medium-risk actions such as `analysis.preflight` and `analysis.run_registered`, and persistent actions such as `result.persist`, remain explicit approval actions.

## Manual Inputs

Manual input checkpoints pause the plan and require application-owned structured input. Supported input types:

- `choice`
- `boolean`
- `short_text`
- `number`
- `resource_reference`

Manual input values are validated for required fields, allowed values, type shape, and unsafe content. They are idempotent by submission id. Unsafe paths, executable-looking strings, and complex objects are rejected.

## Dependencies And Decision Gates

Steps may depend on prior step ids. Plan validation rejects duplicate ids, missing dependencies, and dependency cycles.

Decision gates are represented by `remediation_decision_gate_v1`. Phase 14 documents the schema and validates gate shape. Full branching execution is intentionally minimal; future phases can expand alternative-branch selection without changing the plan contract.

## Execution

Plans execute one step at a time. Step execution may:

- run a delegated low-risk registered action
- pause for explicit step approval
- pause for manual input
- run deterministic re-evaluation
- fail closed on unsupported actions, invalid proposals, exhausted retries, expired plans, unsafe content, or failed stop-on-failure steps

Successful technical execution does not resolve the improvement item. Re-evaluation decides whether resolution criteria were met.

Terminal historical plans remain readable even after the source improvement item becomes `resolved`, `rejected`, `duplicate`, or `superseded`. Active plans still require a remediable source item. This distinction keeps replay and audit history inspectable without allowing obsolete plans to keep executing.

## Integration With The Improvement Ledger

Plan approval moves the source item to `planned`. Running steps record `improvement_attempt_v1` entries. Manual input can move the item to `awaiting_user_input`. Deterministic re-evaluation records `improvement_re_evaluation_v1` and may move the item to `resolved`, `partially_resolved`, or `re_evaluation_required`.

This keeps the distinction clear:

```text
Attempt succeeded != issue resolved.
Issue resolved == criteria re-evaluated and satisfied.
```

## UI

The Project page exposes a Remediation Plans browser. It shows:

- plan counts
- active plans
- awaiting input
- awaiting approval
- available accepted improvement items
- approval policy
- create plan
- approve plan
- approve step
- execute next step
- pause
- revise
- cancel
- selected plan detail
- step table
- success criteria
- stop conditions

Mission Control summarizes remediation plans and raises alerts for failed plans, manual input needs, approval needs, and unhealthy plan event ledgers.

## GenAI Context

`genai_remediation_plan_context_summary()` provides bounded plan context:

- plan id
- source item id
- status
- current step
- next required action
- completed steps
- total steps
- aggregate counts

It does not expose raw project files, arbitrary paths, full ledgers, raw data, handlers, callbacks, or unrestricted action authority.

## Recovery

`remediation_plan_recovery_summary()` classifies restart state as:

- `none`
- `recoverable_paused`
- `recoverable_waiting_approval`
- `recoverable_waiting_input`
- `step_execution_uncertain`
- `terminal`
- `unavailable`

Plans that were running or queued during restart are classified conservatively as uncertain. The system does not silently mark them successful.

Event history is authoritative when checkpoints are missing or invalid. Malformed or hash-inconsistent event histories are reported as unhealthy. Once an event history is unhealthy, new remediation events are rejected rather than appended onto a corrupted chain.

## Hardening QA

`qa_remediation_plan_hardening()` exercises production-like edge cases:

- legal and illegal lifecycle transitions
- successful, partial, failed, paused, cancelled, expired, and terminal replay paths
- deterministic replay from persisted state
- duplicate event idempotency
- corrupted plan classification
- corrupted event history detection
- unhealthy ledger append blocking
- invalid checkpoint tolerance
- bounded GenAI remediation context generation
- exactly-one re-evaluation outcome for completed remediation plans

This QA is integrated into aggregate analysis-module QA so remediation regressions are visible during normal smoke runs.

## Boundaries

Remediation plans do not:

- execute arbitrary R, Python, SQL, shell, or JavaScript
- call unregistered functions
- create new action ids
- bypass approval
- bypass delegation limits
- write outside trusted project storage
- silently repair corrupted ledgers
- resolve an item without re-evaluation evidence
- perform autonomous multi-step chains without checkpoints

## QA

`qa_remediation_plans()` validates:

- schema fields
- invalid/missing source item rejection
- status transitions
- dependency validation
- unsafe content rejection
- excessive step/retry/runtime/persistence rejection
- plan approval
- low-risk one-step execution
- manual input pause
- manual input validation and idempotence
- approval-gated analytical steps
- pause/cancel/revise behavior
- terminal non-resume
- event ledger health
- recovery summary
- bounded GenAI context
- Project UI integration
- Mission Control integration
- schema inventory
- architecture documentation

## Future Work

Likely next refinements:

- richer decision-gate branching
- explicit retry scheduling
- stronger reconciliation between plan events and GenAI action audit events
- visual step timelines
- remediation templates for more item families
- technical debt item creation from accepted remediation limitations
- multi-run recovery guidance for uncertain worker-backed steps
