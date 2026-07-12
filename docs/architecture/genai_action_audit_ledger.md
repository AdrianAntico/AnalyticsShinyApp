# GenAI Action Audit Ledger

Analytics Workstation maintains a durable, project-scoped GenAI action audit ledger for approved project actions. The ledger complements the existing session-local audit stream. Session audit is useful for immediate UI feedback; durable audit is project memory and survives restart.

## Purpose

The ledger records governance events for registered GenAI actions:

- proposal and approval lifecycle
- policy decisions
- execution start and terminal outcomes
- persistence commits and idempotency recovery
- project and storage-provider bindings
- bounded warnings and errors
- resource/result references

The ledger does not make GenAI autonomous. GenAI still proposes. Application code validates, requires explicit approval, executes registered handlers, and records the result.

The GenAI action audit ledger is separate from the Improvement Ledger and Governed Remediation Plans. Action audit records what the registered action layer did. The Improvement Ledger records durable concerns, user feedback, attempts, and re-evaluation. Remediation Plans record the bounded stepwise path from an accepted item to manual checkpoints, action proposals, and deterministic re-evaluation. When a remediation plan leads to a registered action proposal, the plan/item should reference proposal/execution IDs and the action audit should remain bounded to governance metadata rather than duplicating the full plan or improvement item payload. See `docs/architecture/improvement_ledger.md` and `docs/architecture/remediation_plans.md`.

## Storage

Ledger files live under trusted project storage:

```text
<ProjectRoot>/
  logs/
    genai_actions/
      events.ndjson
      checkpoints/
        checkpoint.json
      indexes/
```

The implementation resolves the destination with `project_log_path()` and passes writes through `persistent_write_gate()`. Audit writes never fall back to `getwd()`, the application repository, or a model-supplied path.

## Format

Events are append-only NDJSON. Each line is one complete JSON event. The ledger is not stored as one mutable JSON array and is not stored as R serialization.

The checkpoint is a small derived JSON file containing:

- schema version
- event count
- last event id
- last event timestamp
- last event hash

The checkpoint helps quick inspection but is not the source of truth.

## Event Schema

Current schema: `genai_action_audit_v1`.

Core fields:

- `audit_event_id`
- `audit_schema_version`
- `event_type`
- `event_timestamp`
- `project_id`
- `workspace_provider_id`
- `workspace_provider_type`
- `action_id`
- `action_version`
- `risk_tier`
- `proposal_id`
- `proposal_hash`
- `execution_id`
- `approval_source`
- `policy_decision`
- `result_status`

Common optional fields:

- `resource_type`
- `resource_id`
- `resource_fingerprint`
- `persistence_fingerprint`
- `temporary_result_id`
- `result_type`
- `output_contract_version`
- `persisted_result_id`
- `module_id`
- `module_version`
- `dataset_id`
- `dataset_version`
- `schema_version`
- `job_id`
- `idempotency_key`
- `already_committed`
- `warnings`
- `errors`
- `ui_state_changed`
- `project_state_changed`
- `persistent_changes`
- `computation_performed`
- `temporary_result_created`
- `persisted_result_created`
- `artifact_created`
- `report_created`
- `safe_relative_location`
- `configuration_snapshot_id`
- `configuration_fingerprint`
- `preflight_result_id`

## Event Types

Supported event types:

- `proposal_created`
- `proposal_validated`
- `proposal_rejected`
- `approval_granted`
- `approval_rejected`
- `execution_started`
- `execution_succeeded`
- `execution_failed`
- `execution_cancelled`
- `execution_timed_out`
- `persistence_committed`
- `persistence_recovered`
- `inspection_opened`
- `policy_blocked`
- `resource_stale`
- `delegation_granted`
- `delegation_used`
- `delegation_denied`
- `delegation_revoked`
- `delegation_expired`
- `delegation_exhausted`

Phase 8 emits durable approval, execution-start, terminal execution, and persistence events for eligible project-scoped actions. Phase 10 extends action events with result-type, output-contract, trusted configuration fingerprint, and preflight references so a persisted `model_assessment_regression` result can be reconciled back to the exact approved preflight/run/persist sequence without storing raw analytical payloads. Phase 11 applies the same reconciliation model to `model_assessment_binary` and records safe mode metadata such as `mode_id`, `positive_class`, `decision_threshold`, and `prediction_scale`. The ledger stores only identifiers, bounded status, trusted configuration fingerprints, and safe scalar metadata; it does not store raw binary metrics tables, prediction rows, or plot payloads. Additional proposal lifecycle events can use the same schema as the action layer grows.

Phase 9 adds durable delegation lifecycle events for project-scoped session grants. These events record safe delegation metadata such as action id, scope type, safe scope value, project/provider binding, use counts, denial reason, and revocation source. Active grants remain session-local and do not survive restart; audit history survives as project governance memory. See BOUNDARY-GENAI-004.

## Eligibility

Durable audit is written when:

- the active project is ready
- the action is registered and project-scoped
- the action is one of `module.open`, `artifact.inspect`, `report.open`, `analysis.preflight`, `analysis.run_registered`, `result.persist`, or `result.inspect`

`result.persist` receives the strictest handling because it creates durable project state.

## Sanitization

Before writing, events are validated and sanitized. Durable audit rejects prohibited fields such as:

- raw prompts
- full model responses
- raw dataset rows
- full temporary or persisted result payloads
- credentials, API keys, tokens, and secrets
- callbacks, handlers, functions, environments, connections, and external pointers
- unrestricted stack traces
- sensitive absolute paths

Warnings and errors are bounded. Result references use IDs and safe relative locations rather than user-machine absolute paths.

## Idempotency

Each event receives a trusted audit idempotency key derived from event type, project, action, proposal, execution, result status, and persisted result id. If the same event is retried, the append service returns the existing audit event and marks the write as `already_recorded`.

This prevents duplicate terminal events during retry or uncertain completion.

## Integrity

Each event contains:

- `previous_event_hash`
- `event_hash`

The hash is chained across the ledger. Restart discovery validates the chain and classifies mismatches without rewriting the ledger.

Current health states:

- `healthy`
- `missing`
- `malformed`
- `partial_tail`
- `hash_chain_mismatch`
- `unsupported_schema`
- `unavailable`

The system reports unhealthy history. It does not silently repair or rewrite audit records.

## Persistent Action Failure Policy

For `result.persist`, audit before the project mutation is mandatory. If the ledger cannot record approval/start before execution, the persistent write is blocked. Delegated persistence remains intentionally prohibited; see BOUNDARY-GENAI-001.

If the result bundle commits successfully but a later durable audit write fails, the result is not deleted. The execution result records `audit_write_failed` and a partial-success detail. The persisted result manifest remains the durable source of truth for the result. Reconciliation can later surface the missing audit event.

## Browser

The Project page contains the Phase 8 audit browser. It displays:

- event timestamp
- action
- event type
- risk tier
- proposal id
- execution id
- result status
- approval source
- persisted result reference
- persistent-change status
- bounded warnings/errors

The detail view shows safe structured fields only. It intentionally excludes prompts, raw rows, secrets, and sensitive paths.

## Phase 12 Job Events

Project-scoped isolated execution adds bounded job lifecycle events:

- `job_created`
- `job_queued`
- `worker_started`
- `job_progress_checkpoint`
- `cancel_requested`
- `worker_terminated`
- `job_cancelled`
- `job_timed_out`
- `job_failed`
- `job_succeeded`
- `job_orphaned`
- `job_recovered`
- `result_handoff_rejected`
- `temporary_result_reconstructed`

The ledger records safe worker metadata such as job id, backend id, worker pid hash/safe id, module id, mode id, result type, progress stage, heartbeat timestamp, termination/timeout/recovery flags, result fingerprint, bounded resource usage, and error code. It does not record raw rows, dataset snapshots, full worker requests, full stack traces, secrets, or absolute snapshot paths.

## Reconciliation

Persisted result manifests are reconciled against audit events. Statuses include:

- `matched`
- `missing_audit_event`
- `project_mismatch`
- `duplicate_terminal_event`

Future phases may add `missing_manifest_reference` and `idempotency_mismatch` once more persisted result families expose richer manifest bindings.

## Known Limitations

- Locking is in-process and append-oriented; this phase does not implement distributed cross-process locking. See TD-AUDIT-001 and TD-LOCKING-001.

## Registered Debt References

- Cross-process audit locking: TD-AUDIT-001.
- Persisted-result-focused reconciliation: TD-AUDIT-002.
- Incomplete durable proposal lifecycle coverage: TD-AUDIT-003.
- Durable audit is project-scoped only: BOUNDARY-GENAI-006.
- Schema migration strategy: TD-SCHEMA-001.
- The ledger is file based, not a database.
- Proposal-created/rejected events are schema-supported but not yet broadly emitted by every UI surface.
- Reconciliation currently targets persisted results and does not yet reconcile every future artifact/report mutation type.

## Manual QA

1. Configure a workspace provider.
2. Open or create a project.
3. Run an approved GenAI action such as `module.open`.
4. Persist a temporary result with `result.persist`.
5. Open the Project page.
6. Inspect the GenAI Action Audit Ledger.
7. Confirm approval, execution-start, terminal, and persistence events appear.
8. Restart the app.
9. Reload the project.
10. Confirm the ledger survives restart.
11. Inspect the persisted result reconciliation.
12. Confirm no raw prompt, raw rows, secrets, or absolute project paths appear in event details.
