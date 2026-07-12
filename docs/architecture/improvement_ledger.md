# Unified Findings, Issues, and Improvement Ledger

Phase 13 introduces a durable, project-scoped Improvement Ledger. The ledger is the shared governance record for actionable concerns discovered by deterministic checks, workers, GenAI assessment, QA, Mission Control, audit reconciliation, technical debt review, and the user.

It does not replace the technical debt register. It does not execute fixes. It does not grant GenAI new authority. It records what is wrong, what is insufficient, what could be better, what evidence supports that conclusion, what remediation is recommended, what was attempted, and whether the attempted remediation actually worked.

## Contract

An `improvement_item` is a durable project record. It may represent a defect, validation failure, worker failure, stale resource, data quality issue, analysis quality issue, model quality issue, configuration gap, provider issue, audit issue, result integrity issue, UX problem, documentation gap, architecture debt reference, compatibility issue, enhancement opportunity, low-confidence GenAI concern, user-requested change, accepted limitation, or policy block.

Current schemas:

- `improvement_item_v1`
- `improvement_event_v1`
- `improvement_finding_v1`
- `improvement_remediation_v1`
- `improvement_attempt_v1`
- `improvement_re_evaluation_v1`
- `improvement_ledger_checkpoint_v1`

Required item fields include identity, project binding, item type, title, description, status, severity, priority, confidence, confidence basis, source type, source id, timestamps, affected component/resource, evidence references, recommended remediations, resolution criteria, user feedback, attempt history, re-evaluation history, decision history, issue signature, occurrence count, and intentional-for-now flag.

Optional fields remain optional. The ledger should not require every concern to have a remediation, every user request to have evidence, or every accepted limitation to have a deterministic verifier.

## Lifecycle

The authoritative status model is:

```text
detected
triage_required
accepted
planned
in_progress
awaiting_user_input
awaiting_approval
remediation_proposed
remediation_running
re_evaluation_required
resolved
partially_resolved
unresolved
deferred
accepted_limitation
rejected
duplicate
superseded
```

Detected does not mean accepted. This is especially important for GenAI concerns. The normal flow is:

```text
detect -> record -> triage -> accept/defer/reject
-> propose remediation -> approve or delegate under existing policy
-> execute registered action or manual step
-> re-evaluate -> resolve, partially resolve, defer, accept limitation, or reopen
```

Resolved requires evidence that resolution criteria were met. Partially resolved requires improvement evidence plus remaining gaps. Accepted limitation requires rationale. User disagreement is recorded but does not delete the original concern.

## Severity, Priority, And Confidence

Severity answers how harmful the issue is:

```text
informational, low, medium, high, critical
```

Priority answers when it should be addressed:

```text
backlog, normal, high, urgent
```

Confidence answers how strongly the system believes the concern:

```text
high, medium, low, unknown
```

Confidence basis is explicit:

```text
deterministic_failure
threshold_breach
multiple_evidence_sources
single_evidence_source
genai_inference
user_assertion
heuristic
```

Deterministic failures should not be represented as low-confidence speculation. GenAI-only concerns enter triage and retain the inference basis. GenAI critical severity is capped unless deterministic evidence supports it.

## Evidence

Evidence references point to trusted IDs, not arbitrary paths. Supported evidence types include Mission Control alerts, preflight results, temporary results, persisted results, audit events, worker jobs, QA checks, technical debt items, project resources, artifacts, report plans, module configuration, user feedback, storage validation, and result validation.

Relationships include:

```text
supports
contradicts
triggered_by
resolved_by
introduced_by
re_evaluated_by
```

The ledger stores bounded summaries and references. It does not store raw rows, secrets, full prompts, full result payloads, or sensitive absolute paths.

## Findings Versus Improvement Items

A finding is analytical evidence. An improvement item is a durable work/governance record.

One finding may create or update one improvement item. Multiple findings may consolidate into one item. Repeated detection of the same issue updates `last_detected_at`, increments `occurrence_count`, appends evidence, records re-evaluation history, and avoids duplicate item creation.

## Deduplication

Deduplication uses:

```text
project_id
item_type
affected_resource_type
affected_resource_id
normalized_issue_signature
```

The same issue on the same resource updates the existing item. The same issue on a different resource creates a different item. A materially different issue on the same resource creates a different item.

If a resolved item is detected again, the item moves to `re_evaluation_required`.

## Storage

The ledger is stored under trusted project storage:

```text
<ProjectRoot>/governance/improvement_ledger/
  items/<item_id>.json
  events.ndjson
  checkpoints/checkpoint.json
```

Project path helpers resolve all locations. The implementation does not use `getwd()`, repository-relative storage, user-supplied paths, or GenAI-supplied paths for durable writes.

Item records are atomically replaced. Event history is append-only NDJSON with hash chaining. Restart discovery classifies health as healthy, missing, malformed, unsupported schema, event history mismatch, partial, or unavailable. The system reports corruption; it does not silently repair it.

## Ingestion

Deterministic ingestion currently supports trusted signals such as failed preflight, worker failure, worker timeout, audit mismatch, provider mismatch, schema incompatibility, persistence partial success, result validation failure, and QA failure.

GenAI concern ingestion accepts only allowlisted fields. The application validates evidence IDs, affected references, categories, length, unsafe paths, executable-looking text, and remediation action mappings. GenAI concerns enter `triage_required`.

User-created items are application-owned. The user supplies title, description, item type, priority, affected component, and optional desired outcome. The app generates IDs, timestamps, project binding, event history, and default status.

## Remediation

Recommended remediations are proposals, not execution. They may point only to:

- existing registered actions
- user configuration changes
- manual review steps
- future registered remediation types

Initial remediation types include rerun preflight, rerun analysis, inspect result, inspect artifact, open module, update configuration manually, change project setting, repair result manually, review data quality, create technical debt item, defer, accept limitation, and request user input.

Where a remediation maps to a registered action, action proposal validation, approval, delegation, execution, and audit remain authoritative. The ledger does not bypass the GenAI Action Layer.

Phase 14 adds Governed Remediation Plans as the stepwise execution layer for accepted improvement items. Plans are stored separately under `governance/remediation_plans`, execute one step at a time, pause for manual input or explicit approval, and write attempt/re-evaluation results back to the source improvement item. See `docs/architecture/remediation_plans.md`.

## Attempts And Re-Evaluation

Attempt history records remediation id, action id, proposal id, execution id, start/completion timestamps, status, outcome summary, evidence references, introduced items, and user feedback.

Re-evaluation records before state, after state, comparison, whether criteria were met, remaining gaps, and whether user confirmation is required.

An attempt succeeding technically does not resolve the item. Resolution requires re-evaluation evidence.

## UI

The Project page exposes the Improvement Ledger browser:

- list and filters
- summary counts
- item detail
- evidence
- recommendations
- user feedback
- user-created items

Mission Control surfaces only operationally meaningful ledger states:

- critical open items
- high-priority open items
- items awaiting user input, approval, or triage
- unhealthy ledger state

Low-priority enhancements remain discoverable in the ledger without becoming Mission Control alerts.

## GenAI Context

`genai_improvement_context_summary()` returns a bounded context package with open item IDs, titles, types, statuses, severity, priority, confidence, affected components, evidence counts, remediation counts, and summary counts.

The full ledger is not injected into every prompt. GenAI may explain items, propose triage, suggest priority, propose remediation, compare outcomes, ask the user for missing context, recommend reopening, and identify likely duplicates. GenAI may not delete items, rewrite history, fabricate evidence, mark high-severity items resolved without policy, execute arbitrary remediation, or alter the technical debt register.

## Technical Debt Linkage

The technical debt register remains the source of truth for architectural and compatibility debt. Improvement items may reference debt IDs. Resolving a project item does not resolve a technical debt entry. Debt resolution still requires the register acceptance criteria and register update.

## Maturity Mode

Phase 13 establishes:

```text
Mode 3.5: Governed improvement loop
```

This mode adds durable findings and improvement items, remediation recommendations, human triage and feedback, registered action binding, and re-evaluation. It does not implement Mode 4 bounded autonomy.

## Manual QA

1. Open a project.
2. Trigger a known preflight failure.
3. Confirm an improvement item is created.
4. Run the same preflight again.
5. Confirm the same item updates instead of duplicating.
6. Open the Improvement Ledger on the Project page.
7. Review evidence.
8. Agree with the item.
9. Change its priority.
10. Add user context.
11. Ask Guide or GenAI assistance for a remediation.
12. Confirm the recommendation references registered functionality or manual steps.
13. Approve any actual action through the existing action policy.
14. Confirm the outcome is attached to attempt history.
15. Re-run the relevant check.
16. Confirm resolution criteria are evaluated.
17. Confirm the item resolves only when criteria are met.
18. Create a low-confidence GenAI concern.
19. Confirm it enters triage.
20. Reject the concern and confirm history remains.
21. Create a user-requested enhancement.
22. Defer it.
23. Restart the app.
24. Confirm items and history remain.
25. Trigger a worker timeout.
26. Confirm an execution-failure item is created.
27. Trigger a persisted-result hash mismatch in a test fixture.
28. Confirm an integrity item appears.
29. Confirm Mission Control surfaces critical integrity issues.
30. Confirm low-priority enhancements do not become critical alerts.
31. Review technical debt references.
32. Confirm resolving a project item does not automatically resolve architectural debt.
33. Confirm no raw data or sensitive paths appear.

## Boundaries

Phase 13 intentionally does not add unrestricted autonomous remediation, action chaining, data mutation, model mutation, threshold optimization, arbitrary Code Runner execution, external ticketing, multi-user assignment, full report generation, or broader persistence beyond the project ledger.
