# Schema Version Inventory

This inventory lists the versioned contracts that currently shape Analytics Workstation runtime state, GenAI actions, storage, audit, and project outputs.

Related debt: TD-SCHEMA-001.

| Schema name | Current version | Reader location | Writer location | Compatibility policy | Unsupported-version behavior | Related debt IDs |
| --- | --- | --- | --- | --- | --- | --- |
| proposal schema | `proposal_version = "1.0"` | `R/genai_actions.R` | `R/genai_actions.R` | Strict registered action proposal shape. Model output is normalized into the proposal constructor. | Proposal validation fails. | TD-SCHEMA-001 |
| GenAI action definition schema | implicit `aq_genai_action_definition` list | `R/genai_actions.R` | `R/genai_actions.R` | Registry metadata is internal and handlers are hidden from model context. | Unknown/unsupported action ids fail validation. | TD-GENAI-003 |
| delegation schema | `genai_delegation_v1` | `R/genai_delegation.R` | `R/genai_delegation.R` | Session-local only; durable audit records lifecycle metadata. | Invalid grants are rejected or treated as unavailable. | BOUNDARY-GENAI-004, BOUNDARY-GENAI-005 |
| audit schema | `genai_action_audit_v1` | `R/genai_audit_ledger.R` | `R/genai_audit_ledger.R` | Append-only NDJSON with hash chaining. | Ledger health becomes `unsupported_schema` or unhealthy. | TD-AUDIT-001, TD-AUDIT-002, TD-AUDIT-003 |
| result type registry | `genai_result_type_registry` | `R/genai_result_contracts.R` | `R/genai_result_contracts.R` | Result descriptors define supported temporary/persisted types and output contract versions. | Unknown result types fail validation or persistence. | TD-GENAI-004 |
| model assessment mode registry | `genai_model_assessment_mode_registry` | `R/genai_result_contracts.R` | `R/genai_result_contracts.R` | One registered module routes through trusted app-state mode descriptors for regression and binary classification. | Unsupported modes fail configuration validation. | BOUNDARY-GENAI-008, TD-GENAI-004 |
| temporary result contracts | `dataset_profile_output_v1`, `model_assessment_regression_output_v1`, `model_assessment_binary_output_v1` | `R/genai_actions.R`, `R/genai_result_contracts.R` | `R/genai_actions.R` | Supported temporary result types are allowlisted. | Result cannot be persisted if contract validation fails. | TD-GENAI-004, TD-RESULT-001 |
| GenAI job record schema | `genai_job_record_v1` | `R/genai_job_manager.R` | `R/genai_job_manager.R` | Durable project-scoped job metadata only; raw rows, process handles, secrets, callbacks, functions, and internal absolute path bundles are excluded. | Unsupported or malformed job records are classified as invalid/recoverable failure states. | TD-GENAI-006, TD-STORAGE-001 |
| GenAI worker request schema | `genai_worker_request_v1` | `R/genai_worker_runtime.R`, `R/genai_worker_contracts.R` | `R/genai_job_manager.R` | Strict internal trusted request. It may contain application-created paths required by the worker but rejects model-supplied callbacks, code, prompts, secrets, and unregistered handlers. | Request validation fails before handler execution. | TD-GENAI-003, BOUNDARY-GENAI-003 |
| GenAI worker result schema | `genai_worker_result_v1` | `R/genai_job_manager.R` | `R/genai_worker_runtime.R` | Worker handoff must match job id, execution fingerprint, result type, and registered output contract before temporary result registration. | Handoff is rejected and no temporary result is created. | TD-RESULT-001 |
| GenAI progress event schema | `genai_progress_event_v1` | `R/genai_job_manager.R` | `R/genai_worker_runtime.R` | Bounded NDJSON progress events with monotonic sequence, stage, message, optional fraction, and heartbeat. | Malformed progress is ignored or classified stale; job record remains authoritative. | TD-AUDIT-001 |
| GenAI dataset snapshot schema | `genai_dataset_snapshot_v1` | `R/genai_worker_runtime.R` | `R/genai_job_manager.R` | Bounded project-runtime RDS snapshot with row/column counts, sampling mode, content hash, safe relative location, creation time, and expiry. | Missing or hash-mismatched snapshot blocks worker execution. | TD-STORAGE-001 |
| GenAI recovery state schema | `genai_recovery_state_v1` | `R/genai_job_manager.R` | `R/genai_job_manager.R` | Recovery classifies durable job records and can reconstruct validated completed handoffs as temporary session results. | Unsupported records remain invalid/orphaned and require a new proposal. | TD-RESULT-001 |
| improvement item schema | `improvement_item_v1` | `R/improvement_ledger.R` | `R/improvement_ledger.R` | Project-scoped durable item record for defects, findings, issues, UX friction, accepted limitations, and user-requested improvements. | Item validation fails; malformed records are classified by ledger health and not silently repaired. | TD-SCHEMA-001 |
| improvement event schema | `improvement_event_v1` | `R/improvement_ledger.R` | `R/improvement_ledger.R` | Append-only project governance event history with hash chaining and bounded summaries. | Ledger health becomes `unsupported_schema`, `malformed`, `partial`, or `event_history_mismatch`. | TD-SCHEMA-001, TD-AUDIT-001 |
| improvement finding schema | `improvement_finding_v1` | `R/improvement_ledger.R` | deterministic diagnostics and GenAI concern ingestion | Provider-independent analytical finding contract. Findings are evidence; improvement items are durable governance records. | Finding cannot be promoted to an item until normalized. | TD-SCHEMA-001 |
| improvement remediation schema | `improvement_remediation_v1` | `R/improvement_ledger.R` | `R/improvement_ledger.R` | Recommended remediation points only to registered actions, manual configuration, user input, or future registered remediation types. | Unsupported remediation/action mappings are rejected. | BOUNDARY-GENAI-003, TD-GENAI-003 |
| improvement attempt schema | `improvement_attempt_v1` | `R/improvement_ledger.R` | `R/improvement_ledger.R` | Attempt history binds remediation, proposal, execution, outcome, and evidence without marking success as resolution automatically. | Malformed attempts are rejected with the containing item. | TD-SCHEMA-001 |
| improvement re-evaluation schema | `improvement_re_evaluation_v1` | `R/improvement_ledger.R` | `R/improvement_ledger.R` | Re-evaluation records before/after state, criteria status, remaining gaps, and user-confirmation requirement. | Malformed re-evaluations are rejected with the containing item. | TD-SCHEMA-001 |
| improvement ledger checkpoint schema | `improvement_ledger_checkpoint_v1` | `R/improvement_ledger.R` | `R/improvement_ledger.R` | Checkpoint summarizes append-only event history for restart discovery and health checks. | Missing checkpoints do not block reads; event history remains authoritative. | TD-SCHEMA-001 |
| remediation plan schema | `remediation_plan_v1` | `R/remediation_plans.R` | `R/remediation_plans.R` | Bounded project-scoped plan created from accepted improvement items. Plans define step order, budgets, approval policy, stop conditions, and success criteria. | Unsupported or malformed plans fail validation and are not executed. | TD-SCHEMA-001 |
| remediation plan step schema | `remediation_plan_step_v1` | `R/remediation_plans.R` | `R/remediation_plans.R` | Steps may be registered actions, manual input, deterministic re-evaluation, decision gates, or informational checkpoints. | Invalid step shape, dependencies, risk understatement, unsafe content, or unsupported actions fail plan validation. | TD-SCHEMA-001, BOUNDARY-GENAI-003 |
| remediation manual input schema | `remediation_manual_input_v1` | `R/remediation_plans.R` | `R/remediation_plans.R` | Manual checkpoints define bounded application-owned fields. | Missing required values, invalid choices/types, unsafe paths, or executable-looking input are rejected. | BOUNDARY-GENAI-003 |
| remediation decision gate schema | `remediation_decision_gate_v1` | `R/remediation_plans.R` | `R/remediation_plans.R` | Decision gates identify allowed next-step ids for future branching. | Unsupported gate schemas or missing allowed next steps fail validation. | TD-SCHEMA-001 |
| remediation plan event schema | `remediation_plan_event_v1` | `R/remediation_plans.R` | `R/remediation_plans.R` | Append-only remediation plan event history with normalized hash chaining. | Ledger health becomes `unsupported_schema`, `malformed`, `partial`, or `event_history_mismatch`. | TD-SCHEMA-001, TD-AUDIT-001 |
| remediation plan template schema | `remediation_plan_template_v1` | `R/remediation_plans.R` | `R/remediation_plans.R` | Internal templates map item families to bounded step sequences. | Unsupported item types return `remediation_not_currently_executable`. | TD-SCHEMA-001 |
| remediation recovery schema | `remediation_plan_recovery_v1` | `R/remediation_plans.R` | `R/remediation_plans.R` | Recovery classifies paused, waiting, uncertain, and terminal plans after restart. | Unknown or malformed plan state is reported as unavailable or unhealthy rather than repaired. | TD-SCHEMA-001 |
| remediation checkpoint schema | `remediation_plan_checkpoint_v1` | `R/remediation_plans.R` | `R/remediation_plans.R` | Checkpoint stores latest remediation event metadata for restart discovery. | Missing checkpoint does not block reads; event history remains authoritative. | TD-SCHEMA-001 |
| persisted result manifests | `result_persistence_v1` | `R/storage_architecture.R` | `R/genai_actions.R` | Manifest plus content hashes; supported result types only. | Bundle classified as `unsupported_schema`, `unsupported_result_type`, or invalid and is not opened. | TD-SCHEMA-001, DEFERRED-RESULT-004 |
| configuration snapshot schemas | `dataset_profile_config_v1`, `model_assessment_config_union_v1`, `model_assessment_regression_config_v1`, `model_assessment_binary_config_v1` | `R/genai_actions.R`, `R/genai_result_contracts.R` | `R/genai_actions.R` | Trusted app state only; model-supplied module config is rejected. Binary configuration requires explicit positive class, probability scale, and threshold from trusted state. | Validation/preflight blocks execution. | TD-GENAI-005, TD-PROJECT-001 |
| workspace schema | `storage_schema_version = "1"` | `R/storage_architecture.R` | `R/storage_architecture.R` | User settings are read through storage helpers. | Workspace validation fails or reports unavailable/invalid state. | TD-SCHEMA-001, COMPAT-PROJECT-001 |
| project schema | `project_schema_version = "1"` | `R/storage_architecture.R`, `R/project_state.R` | `R/storage_architecture.R`, `R/service_project.R` | Existing project RDS compatibility remains during transition. | Project validation/loading reports structured errors or repair warnings. | TD-SCHEMA-001, COMPAT-PROJECT-001 |
| storage policy version | `storage_policy_v1` | `R/storage_architecture.R` | `R/storage_architecture.R` | Persistent write fingerprints include storage policy version. | Approval/persistence fingerprints become stale or invalid. | TD-STORAGE-001, TD-STORAGE-002 |
| persistence schema | `result_persistence_v1` | `R/storage_architecture.R` | `R/genai_actions.R` | Same as persisted result manifest schema; listed separately because write gates bind to this contract. | Unsupported bundles are diagnosed and withheld from inspection. | TD-SCHEMA-001, DEFERRED-RESULT-004 |
| technical debt register | `technical_debt_v1` | `R/technical_debt_register.R` | `config/technical_debt.yml` | YAML is source of truth; Markdown summary must contain all IDs and synchronized counts. | `qa_technical_debt_register()` fails. | TD-SCHEMA-001 |
| artifact bundle contract | `artifact_bundle_v1` | `R/project_artifact_collector.R` | module producers and collector helpers | Collector accepts standardized bundles; module-specific logic remains outside collector. | Invalid bundles are rejected or reported by collector QA. | TD-SCHEMA-001 |
| artifact quality policy | `artifact_quality_policy_v1` | `R/artifact_quality_policy.R` | `R/artifact_quality_policy.R` | Completeness scoring is informational; missing optional components degrade gracefully. | QA reports missing required metadata. | TD-SCHEMA-001 |
| table artifact policy | `table_artifact_policy_v1` | `R/table_artifact_policy.R` | `R/table_artifact_policy.R` | Explicit producer policies preferred; inference remains fallback. | QA reports invalid/missing policy metadata. | TD-SCHEMA-001 |
| render target contract | `render_target_v1` | `R/render_targets.R` | `R/render_targets.R` | Human, LLM, artifact-studio, and collector render targets remain separate from information encoding. | Unknown target is rejected or treated as unsupported. | TD-SCHEMA-001 |
| active modeling context | `modeling_context_v1` | `R/modeling_context.R`, `R/project_state.R` | `R/modeling_context.R`, `R/app_server.R` | The action layer still exposes only trusted `active_dataset`, while context metadata records source/prepared dataset lineage, active artifact id, feature manifest, and activation time. | Missing prepared artifacts or project mismatches fail validation; source revert may require reloading source data after restart. | TD-PROJECT-001 |
| feature proposal | `feature_proposal_v1` | `R/feature_experiment_loop.R` | `R/feature_experiment_loop.R` | Bounded evidence-backed feature hypotheses store metadata and parameters only, never executable code. | Unsupported, blocked, or malformed proposals cannot execute. | TD-SCHEMA-001, BOUNDARY-GENAI-003 |
| feature execution | `feature_execution_v1` | `R/feature_experiment_loop.R` | `R/feature_experiment_loop.R`, Rodeo vNext contract | Approved supported proposals translate to Rodeo specs, fit/apply deterministically, serialize learned state, and produce challenger prepared dataset artifacts. | Failed execution returns structured errors and does not present partial success. | TD-SCHEMA-001 |
| feature challenger experiment | `feature_experiment_v1` | `R/feature_experiment_loop.R` | `R/feature_experiment_loop.R`, `R/module_autoquant_catboost_builder.R` | One frozen baseline is compared with one challenger dataset/model while preserving target, split, seed, parameters, and feature manifests. | Missing baseline lineage blocks the experiment. | TD-SCHEMA-001 |
| feature comparison | `feature_comparison_v1` | `R/feature_experiment_loop.R` | `R/feature_experiment_loop.R` | Deterministic baseline/challenger metric deltas classify accept, reject, or inconclusive before GenAI interpretation. | Missing comparable metrics produce inconclusive diagnostics. | TD-SCHEMA-001 |
| feature adoption | `feature_adoption_v1` | `R/feature_experiment_loop.R` | `R/feature_experiment_loop.R`, `R/app_server.R` | Accepted challengers require explicit approval before adoption; negative and inconclusive outcomes remain evidence. | Adoption without approval or without accepted evidence is rejected. | TD-SCHEMA-001 |
| analytical campaign | `analytical_campaign_v1` | `R/analytical_improvement_campaign.R`, `R/app_server.R` | `R/analytical_improvement_campaign.R`, `R/app_server.R` | Campaigns coordinate bounded evidence review, opportunity ranking, feature proposal sequencing, execution memory, and status. State is stored in project state. | Malformed campaigns fail reconciliation and should be paused for review. | TD-SCHEMA-001 |
| analytical campaign plan | `analytical_campaign_plan_v1` | `R/analytical_improvement_campaign.R` | `R/analytical_improvement_campaign.R` | Plans summarize ranked opportunities, required approvals, stopping criteria, and expected deliverables. | Invalid or empty plans produce campaign warnings rather than execution. | TD-SCHEMA-001 |
| analytical campaign synthesis | `analytical_campaign_synthesis_v1` | `R/analytical_improvement_campaign.R` | `R/analytical_improvement_campaign.R` | Synthesis records evidence reviewed, opportunities considered, executed experiments, accepted/rejected/inconclusive outcomes, remaining opportunities, and next recommendation. | Missing synthesis does not mutate campaign state; rerun synthesis from campaign memory. | TD-SCHEMA-001 |

## Migration Support

Migration support is currently limited. Most durable readers prefer strict validation and clear unsupported-version diagnostics over automatic repair. This is intentional until schema contracts stabilize. See TD-SCHEMA-001 and DEFERRED-RESULT-004.

## Unsupported-Version Policy

Unsupported versions should:

- fail closed for persistent writes
- avoid opening unsafe bundles
- report structured diagnostics
- never silently repair durable project state
- reference a debt or migration item when the gap is known

## Phase 11 Update

Phase 11 added `model_assessment_binary` as a supported temporary and persisted result type under the existing `model_assessment` registered module. The binary mode uses trusted app-state configuration only, supports probability predictions in `[0,1]`, persists `threshold_metrics.json`, and records mode/result identifiers in audit projections. Multiclass, model mutation, threshold optimization, report generation, and artifact generation remain unsupported; see BOUNDARY-GENAI-008.

## Phase 12 Update

Phase 12 added isolated worker execution contracts for `analysis.run_registered`. `dataset_profile`, `model_assessment_regression`, and `model_assessment_binary` now execute through a project-scoped `callr` worker when a ready workspace and project are active. Worker requests and results are versioned, dataset transfer uses bounded hash-verified snapshots, progress uses bounded NDJSON, and completed handoffs can reconstruct temporary session results without automatic persistence.

## Phase 13 Update

Phase 13 added the project-scoped Improvement Ledger. The ledger stores current item JSON records under `governance/improvement_ledger/items`, append-only event history under `governance/improvement_ledger/events.ndjson`, and checkpoint metadata under `governance/improvement_ledger/checkpoints`. It distinguishes findings from durable improvement items, severity from priority, and remediation attempts from verified resolution. GenAI concern ingestion is allowlisted and enters triage; deterministic failures may create high-confidence items. The ledger does not replace the technical debt register and does not bypass registered action approval or delegation.

## Phase 14 Update

Phase 14 added governed remediation plans under `governance/remediation_plans`. Plans are created from accepted improvement items, validated against bounded schemas, reviewed by the user, and executed one step at a time. Plan steps may reference only registered GenAI actions, manual checkpoints, deterministic re-evaluations, decision gates, or informational checkpoints. Plan approval does not bypass action approval; medium-risk analytical steps and persistence still require explicit approval. Plan events are append-only and hash chained. Project UI and Mission Control expose active plans, approvals, manual inputs, failures, and recovery state.

## Phase 16 Update

Phase 16 added cross-system invariant QA and documentation without introducing a new persisted schema. `qa_cross_system_invariants()` checks identity safety, lifecycle vocabulary consistency, declared schema versions, ledger health readers, event coverage, and architecture documentation across storage, module results, artifact collection, GenAI actions, delegation, audit, improvement, remediation, and Mission Control contracts.

## Phase 17 Update

Phase 17 added a production workflow exercise without introducing a new persisted schema. `qa_production_workflow_exercise()` validates project creation, project data import, artifact collection, audit writing, improvement creation, remediation execution, ledger summaries, expired-plan recovery, Mission Control source visibility, and closed-project write protection over the existing contracts.

## Phase 18 Update

Phase 18 hardened QA reliability without introducing a new persisted schema. Screenshot validation now verifies readable non-empty PNG files with plausible dimensions, collector browser cleanup is classified separately from primary write status, and `qa_screenshot_pipeline_reliability()` covers missing, empty, corrupt, successful, and gracefully failed screenshot cases.

## Phase 25 Update

Phase 25 introduced `modeling_context_v1` as project-state metadata for the trusted active dataset. It does not create a broad dataset registry. The current GenAI action layer still accepts only `active_dataset`, but the resolver now carries bounded context fields such as active dataset source, prepared artifact id, feature manifest, and lineage summary. CatBoost Builder records this context in result metadata and downstream handoff metadata so historical model evidence remains interpretable after the active context changes.

## Phase 26 Update

Phase 26 introduced the governed feature experiment loop contracts: `feature_proposal_v1`, `feature_execution_v1`, `feature_experiment_v1`, `feature_comparison_v1`, and `feature_adoption_v1`. The initial loop supports bounded evidence-backed proposals for Rodeo-supported transformations only, explicit approval before execution, deterministic Rodeo fit/apply, prepared challenger dataset artifacts, frozen-baseline CatBoost challenger runs, deterministic comparison, outcome interpretation, explicit adoption, and reconciliation. Unsupported ideas are retained as recommendations and are not converted into arbitrary code.

## Phase 28 Update

Phase 28 introduced analytical improvement campaign contracts: `analytical_campaign_v1`, `analytical_campaign_plan_v1`, and `analytical_campaign_synthesis_v1`. Campaigns coordinate existing evidence, feature proposal, Rodeo execution, CatBoost challenger, comparison, interpretation, and memory functions. They pause at approval, missing-baseline, blocked-execution, and adoption-decision gates. They do not introduce a new ledger, workflow engine, AutoML loop, or autonomous adoption policy.

## Phase 29 Update

Phase 29 extended the existing analytical campaign contracts without adding new schema names. `analytical_campaign_v1` now records compact multi-opportunity memory: completed opportunity ids, failed executions, superseded proposals, supporting evidence references, proposal lineage, experiment lineage, adoption lineage, and ordered event history. Remaining opportunities are reprioritized after each completed execution, dependency-blocked opportunities are marked explicitly, and repeated execution through governance gates returns structured `needs_input` rather than silently continuing.

`analytical_campaign_synthesis_v1` now includes the adaptive campaign view: remaining opportunities, superseded items, supporting evidence references, lineage, and timeline. The compatibility policy remains project-state scoped and deterministic.

## Phase 30 Update

Phase 30 added deterministic campaign evidence assessment inside the existing `analytical_campaign_v1` and `analytical_campaign_synthesis_v1` contracts. No new persistence system or workflow engine was introduced. Campaigns now record `analytical_campaign_evidence_assessment_v1` as embedded assessment metadata with readiness, confidence score, evidence gaps, uncertainty signals, counts, baseline availability, and recommendation.

Campaign creation blocks before opportunity discovery when evidence is insufficient, while preliminary evidence remains runnable with conservative ranking and explicit baseline/artifact caveats. Mission Control reads the existing campaign summary to surface evidence readiness and remaining/completed opportunity counts.

## Phase 31 Update

Phase 31 added deterministic campaign learning assessment inside the existing analytical campaign contracts. Campaigns now embed `analytical_campaign_learning_assessment_v1` rows in campaign memory and synthesis. The assessment distinguishes model outcome from learning outcome, records uncertainty before/after, expected evidence, observed evidence, confidence change, unresolved questions, newly created questions, hypothesis disposition, and repeat-value guidance.

No new persistence or governance layer was introduced. Campaign memory now tracks facts learned, evidence collected, supported/rejected/uncertain hypotheses, unresolved questions, new questions, low-learning opportunities, and learning summaries. Remaining opportunity ranking can use this memory to avoid repeating low-value investigations.

## Phase 32 Update

Phase 32 added deterministic campaign closure assessment and knowledge promotion within the existing campaign contracts. Campaigns now embed `analytical_campaign_closure_assessment_v1` in synthesis with closure recommendation, campaign confidence, confidence factors, completeness, expected next-opportunity value, governance status, remaining uncertainty, evidence gaps, promoted knowledge, intentionally non-promoted knowledge, reopening guidance, and summary.

Promoted knowledge remains campaign evidence, not a global knowledge graph. `analytical_campaign_apply_promoted_knowledge()` can apply promoted guidance to a future campaign by deprioritizing repeat-avoidance records or lightly prioritizing supported bounded hypotheses. Weak evidence and unsupported learning are retained as historical evidence but not promoted.

## Phase 33 Update

Phase 33 added governed cross-campaign knowledge validation within the existing campaign contracts. Promoted knowledge now carries `analytical_campaign_knowledge_lifecycle_v1` fields for deterministic identity, origin campaign, supporting campaigns, experiments, artifacts, promotion reason, validation history, current status, supersession, retirement, and reopening conditions.

The lifecycle registry is embedded in campaign synthesis and summaries. It is not a global knowledge graph, probabilistic memory system, or new persistence layer. Future campaigns validate promoted knowledge through deterministic relationships such as supports, contradicts, extends, narrows, supersedes, and unrelated. Duplicate promoted knowledge is merged by deterministic fingerprint. Superseded and retired knowledge remains historically inspectable.

## Phase 34 Update

Phase 34 added deterministic knowledge applicability inside the existing campaign knowledge lifecycle. Promoted knowledge now embeds `analytical_campaign_applicability_v1` fields describing bounded applicability context: dataset characteristics, target, model family, feature scale, data scale, operator support, required evidence, known exclusions, known limitations, evidence references, and transfer guidance.

Applicability matching is deterministic and returns fully applicable, partially applicable, weakly applicable, not applicable, or insufficient information. Matching is advisory and affects campaign prioritization only when active knowledge is applicable. No global knowledge graph, ontology engine, probabilistic confidence layer, or new persistence system was introduced.
