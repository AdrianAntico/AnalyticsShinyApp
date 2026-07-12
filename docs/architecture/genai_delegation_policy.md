# GenAI Delegation Policy

Analytics Workstation supports narrowly scoped session delegation for selected low-risk UI actions. Session-only delegation is intentional; see BOUNDARY-GENAI-004.

Delegation begins Mode 3:

```text
Delegated safe actions
```

It does not create autonomy. It removes repeated approval only for a specific user-granted action scope during the current session. No action chaining is allowed; see BOUNDARY-GENAI-002.

## Principle

Delegation changes approval source, not safety checks.

The proposal is still required. The action registry is still authoritative. The application still validates:

- proposal schema
- action id and action version
- risk tier
- resource identity
- resource fingerprint
- project binding
- provider binding
- grant hash
- expiration
- use count
- revocation status

GenAI cannot grant, expand, renew, revoke, or edit delegation.

## Eligible Actions

Only low-risk UI actions are eligible:

- `module.open`
- `artifact.inspect`
- `report.open`
- `result.inspect`

These actions may change temporary UI state only. They may not mutate project data, write files, run analysis, persist results, generate reports, or chain actions.

## Ineligible Actions

The following remain approval-required:

- `analysis.preflight`
- `analysis.run_registered`
- `result.persist`

Future actions are ineligible by default unless explicitly added to the delegation policy.

`result.persist` remains explicitly approval-required because persistent project mutation cannot be delegated. See BOUNDARY-GENAI-001.

Improvement Ledger recommendations and Governed Remediation Plans do not expand delegation. A remediation plan may reference an eligible delegated action such as `module.open`, `artifact.inspect`, `report.open`, or `result.inspect`, but the action must still match an active session grant and pass proposal validation. Plan approval may approve plan structure and, when explicitly selected, low-risk delegated steps only. Analytical execution, persistence, project repair, data mutation, model mutation, and arbitrary remediation remain outside delegation.

Phase 11 keeps binary Model Assessment inside this boundary. `analysis.preflight` and `analysis.run_registered` may execute `model_assessment_binary` only after explicit approval and trusted app-state configuration. GenAI may not delegate, infer, or supply binary target, prediction, positive class, threshold, prediction scale, or weights. `result.inspect` may be delegated only for a specific healthy persisted result, whether that result is `dataset_profile`, `model_assessment_regression`, or `model_assessment_binary`.

## Grant Schema

A delegation grant contains:

- `delegation_id`
- `delegation_schema_version`
- `action_id`
- `action_version`
- `scope_type`
- `scope_value`
- `resource_type`
- `resource_id`
- `resource_fingerprint_at_grant`
- `project_id`
- `project_root_identity`
- `workspace_provider_id`
- `workspace_provider_type`
- `provider_capability_version`
- `provider_policy_version`
- `granted_by`
- `granted_at`
- `expires_at`
- `session_id`
- `status`
- `max_uses`
- `uses_remaining`
- `policy_version`
- `created_from_ui`
- `delegation_hash`

The application generates authoritative fields. Model output is never trusted as a grant.

## Scope Model

Phase 9 supports specific scopes only.

For `module.open`:

- `specific_module`

For `artifact.inspect`, `report.open`, and `result.inspect`:

- `specific_resource`

Broad wildcard scopes are not implemented in Phase 9.

## Expiration And Use Limits

Delegations are session-local and expire by:

- session end
- timestamp
- use exhaustion
- explicit revocation
- project change
- provider change
- policy/hash invalidation

Defaults:

- 30 minute maximum duration
- 5 uses maximum
- one-use grant option

Permanent delegation is not supported.

## Project And Provider Binding

Delegation binds to the active project and storage provider.

Project binding includes:

- `project_id`
- `project_root_identity`
- `project_state`

Provider binding includes:

- `workspace_provider_id`
- `workspace_provider_type`
- `provider_capability_version`
- `provider_policy_version`
- `workspace_state`

Changing project or provider revokes session grants. A grant is never silently transferred to another project. See BOUNDARY-GENAI-005.

## Resource Binding

Resource-specific delegation stores the resource fingerprint at grant time. Before delegated execution, the proposal is validated again and the resource fingerprint must still match. Stale resources fall back to explicit approval.

## Execution Flow

```text
GenAI proposal
-> normal proposal validation
-> delegation lookup
-> grant validation
-> approval_source = active_delegation
-> deterministic registered handler
-> use count consumed
-> session audit
-> durable audit when project-scoped
```

A use is consumed once deterministic execution begins. Handler failure after execution start still consumes the use.

## Revocation

Users may revoke one grant or all session grants from the Guide / AI Assistance panel. Revocation is immediate and blocks pending proposals before execution.

## Audit

Delegation lifecycle events are written durably when the active project is ready:

- `delegation_granted`
- `delegation_used`
- `delegation_denied`
- `delegation_revoked`
- `delegation_expired`
- `delegation_exhausted`

Audit events include safe scope, action, project, provider, use count, and denial metadata. They exclude raw prompts, raw rows, secrets, full payloads, and sensitive absolute paths.

## GenAI Context

GenAI may see only safe delegation summaries:

- delegated action ids
- scope summaries
- expiration summaries
- uses remaining
- active project binding

It may not see delegation hashes or hidden policy internals.

## Current UI

The floating Guide / AI Assistance panel includes:

- a session delegation manager
- active grant list
- revoke and revoke-all controls
- `Grant Once`
- `Grant 5 Uses`
- delegated authorization notice
- explicit-approval fallback notice

## Known Limitations

- Delegation is session-local only. See BOUNDARY-GENAI-004.
- Broad project/resource-type scopes are not enabled.
- No delegated computation or persistence exists. See BOUNDARY-GENAI-001.
- No action chaining exists. See BOUNDARY-GENAI-002.
- Cross-process delegation sharing is not implemented.
- Proposal-created/rejected durable events are emitted for proposals entering trusted app state; malformed advisory text that never becomes a proposal remains advisory chat.

## Registered Debt References

- No delegated persistence: BOUNDARY-GENAI-001.
- No action chaining: BOUNDARY-GENAI-002.
- Session-only delegation: BOUNDARY-GENAI-004.
- Delegation invalidated on project reload: BOUNDARY-GENAI-005.

## Manual QA

1. Open a project.
2. Generate a valid `module.open` proposal.
3. Grant one-use delegation.
4. Ask Guide to open the same module.
5. Confirm it executes without another approval prompt.
6. Confirm the grant is exhausted.
7. Ask again and confirm explicit approval is required.
8. Grant delegation for a specific artifact/report/result.
9. Confirm only that same resource is covered.
10. Revoke the grant and confirm it no longer authorizes.
11. Change project/provider and confirm grants are invalidated.
12. Confirm `analysis.preflight`, `analysis.run_registered`, and `result.persist` still require explicit approval.
