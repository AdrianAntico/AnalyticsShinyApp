# Workspace, Project, and Runtime Storage Architecture

Analytics Workstation separates application source from user-owned runtime data. The application may open without a workspace or project, but persistent writes are blocked until the storage owner is explicit.

The architecture is deployment-agnostic. Local Shiny, hosted Shiny, Electron/native desktop shells, and managed enterprise deployments should all flow through the same storage-provider contract rather than writing directly to paths assembled by page code.

## Storage Invariants

- Application source is not runtime storage.
- Persistent runtime output must not default to `getwd()`.
- Persistent runtime output must not default to the repository.
- Project-owned outputs require a ready active project.
- No-project work may create temporary/session results only.
- GenAI actions cannot provide output directories or override workspace/project roots.
- Timestamped artifact naming remains supported.

## Storage Classes

### Application Source

The repository contains code, documentation, fixtures, and development-only assets. Normal user flows must not write artifacts, reports, layouts, results, or collector files beneath this root.

### User Settings

The selected workspace path is stored outside source control using `tools::R_user_dir("AnalyticsWorkstation", "config")` through `storage_settings_file()`. The settings record stores:

- `workspace_provider_id`
- `workspace_root`
- `workspace_configured_at`
- `workspace_schema_version`

No secrets are stored here. Managed deployments may supply the provider/root through trusted server configuration instead of user-local settings.

## Storage Providers

The app uses a provider-independent storage contract. A provider records:

- `provider_id`
- `provider_type`
- `display_name`
- `available`
- `selection_supported`
- `managed`
- `root_path`
- `writable`
- `capabilities`
- `validation_status`

Initial provider types:

| Provider | Purpose | Notes |
| --- | --- | --- |
| `managed_workspace` | Administrator or deployment-assigned root | Baseline for hosted/enterprise deployments. |
| `configured_workspace` | User-confirmed persisted workspace | Local or server process path stored in user settings. |
| `local_server_directory` | Typed local/server directory | Does not assume the browser can browse client files. |
| `native_host_directory` | Optional desktop/native picker | Optional capability only; Electron is not required. |

Capabilities include `can_choose_directory`, `can_browse_server_directories`, `can_open_directory`, `workspace_is_managed`, `supports_external_projects`, and `native_directory_picker`.

## Deployment Modes

### Hosted Or Enterprise Shiny

The browser cannot choose a client-local directory for the remote R process. Hosted deployments should use a managed workspace root, authenticated-user allocation, or approved server directory choices. The app must still open when no provider is ready, but persistent writes remain blocked.

### Local Shiny

The R process usually runs on the same machine as the user. The app can support typed paths or restricted server-side browsing through the `configured_workspace` or `local_server_directory` providers.

### Electron Or Desktop Host

A native shell may expose a directory picker through `native_host_directory`. The core storage system does not depend on this provider and works when it is unavailable.

### No Available Provider

The shell, Guide, Knowledge Library, provider settings, and temporary analyses may remain available. Persistent writes are rejected with structured storage errors.

### Workspace Runtime Storage

A configured workspace is a user-selected writable directory outside the repository. The current structure is:

```text
AnalyticsWorkstation/
  projects/
  temp/
  cache/
  logs/
  settings/
```

The app starts when the workspace is missing or invalid, but persistent writes remain blocked and the Project page explains the setup requirement. A ready workspace is represented as `workspace_ready`; an absent project is represented separately as `no_project`.

### Project Persistent Storage

A project is the persistent owner for analytical outputs. Projects created through the app live below:

```text
<workspace>/projects/<project_id>/
  project.json
  project.rds
  data/
  artifacts/
  reports/
  layouts/
  results/
  governance/
    improvement_ledger/
    remediation_plans/
  logs/
    genai_actions/
      events.ndjson
      checkpoints/
  temp/
  collector/
```

The project metadata includes `project_id`, `project_name`, `project_root`, schema version, and timestamps. Existing `.rds` project files can still load, but their root is validated and treated as the active project root.

### Session Temporary Storage

Temporary work uses `session_temp_path()`. If a valid workspace exists, session temp lives under `<workspace>/temp`; otherwise it falls back to `tempdir()/AnalyticsWorkstation`. Temporary results are not project artifacts.

## Trusted Path Resolver

All new persistent path construction should use:

- `workspace_path()`
- `project_path()`
- `project_artifact_path()`
- `project_report_path()`
- `project_layout_path()`
- `project_result_path()`
- `session_temp_path()`

These helpers normalize paths, reject traversal, and ensure project paths remain inside the intended project root and outside the repository.

## Persistent Write Gate

`persistent_write_gate()` centralizes write eligibility. A persistent write requires:

- available active storage provider
- ready workspace
- provider permits durable writes
- active `project_ready` project
- project/provider compatibility
- target inside the active project root
- target outside the repository root

Blocked writes return structured `service_result()` errors such as `workspace_not_configured`, `workspace_unavailable`, `provider_disallows_write`, `project_required`, `target_outside_project`, and `target_inside_repository`.

Provider selection capabilities are not write requirements. A managed workspace may disallow user directory picking, server browsing, native pickers, or open-directory affordances and still be a valid persistence provider when the provider is available, writable, workspace-ready, and bound to a valid project root.

### Provider-Bound Persistence Approval

Persistent actions such as `result.persist` bind approval to trusted provider state, not to model-supplied paths. The persistence fingerprint includes:

- `workspace_provider_id`
- `workspace_provider_type`
- `workspace_state`
- `workspace_root_identity`
- `provider_capability_version`
- `provider_write_policy`
- `active_project_id`
- `project_root_identity`

Before writing, the application must re-resolve the active provider and reject the operation if the provider changed, is unavailable, is not writable, changed write policy, changed capabilities, has an invalid project-root relationship, or no longer matches the active project. A provider change invalidates approval even when the visible path is unchanged.

Project/provider compatibility is explicit. A project created under one provider cannot be persisted through a different provider without a new trusted project binding. External project roots are rejected unless the active provider declares `supports_external_projects`.

Approval UI should display safe labels: provider name, provider type, managed status, active project, workspace readiness, and a project-relative destination label. Managed deployments should not expose sensitive absolute roots.

The write gate records audit metadata for provider id, provider type, managed status, provider capability version, provider write policy, provider validation result, project/provider match, safe destination, and persistence fingerprint.

`result.persist` is the first implementation using this contract. It writes completed supported temporary results into `project/results/<persisted_result_id>/` through staged same-project storage and atomic directory commit. Current supported result types are `dataset_profile` and `model_assessment_regression`. It does not require `can_choose_directory`, server browsing, native pickers, or Electron APIs. Cross-process persistence locking remains open technical debt; see TD-STORAGE-002.

### Persisted Result Discovery And Inspection

Persisted results are discovered only through the active project `results/` root. The browser and GenAI action layer do not recursively browse arbitrary filesystem locations and do not accept paths from model output.

Completed result bundles are healthy only when:

- the result directory exists
- `manifest.json` exists and is readable
- required manifest fields exist
- manifest status is `complete`
- persistence schema is supported
- result type is supported
- manifest project id matches the active project
- all required resource files exist
- content hashes match

The supported persisted result types are currently `dataset_profile`, `model_assessment_regression`, and `model_assessment_binary`. Binary Model Assessment bundles include bounded `threshold_metrics.json` in addition to summary, metrics, diagnostics, warnings, resource usage, bounded table previews, and bounded plot specifications. Further persisted result types should continue through the result-type registry and review TD-GENAI-004.

## Project Runtime Job Storage

Phase 12 adds project-scoped runtime storage for isolated GenAI registered-analysis jobs:

```text
<project>/runtime/genai_jobs/<job_id>/
```

This directory contains durable job records, bounded progress, worker logs, temporary dataset snapshots, and validated handoff files. It is runtime state, not persisted analytical output. Completed handoffs may reconstruct session temporary results, but project persistence still requires a separate `result.persist` proposal and approval.

Durable job records expose only bounded metadata and safe relative handoff locations. Trusted internal request files may contain application-created absolute paths needed by the worker, but those paths are not model-supplied and are not surfaced as GenAI context. Dataset snapshots are hash-verified before worker execution and may be cleaned after successful handoff collection.

Invalid or unsupported bundles are classified with safe statuses such as `invalid_manifest`, `incomplete`, `hash_mismatch`, `missing_content`, `unsupported_schema`, `unsupported_result_type`, `project_mismatch`, and `unavailable`. Staging and hidden directories are ignored. Invalid bundles are never repaired or rendered automatically. See TD-RESULT-003 and TD-SCHEMA-001.

The Project page includes the first Persisted Results browser. It shows healthy results separately from invalid bundles, opens healthy results read-only, and renders only bounded summaries, metrics, diagnostics, warnings, resource usage, table previews, and bounded plot specifications. It uses project-relative labels such as `results/<persisted_result_id>` rather than raw absolute paths.

The GenAI action `result.inspect` uses the same discovery and validation path. It can select one healthy persisted result in the browser after explicit approval. It does not mutate the project, write files, update manifests, rewrite hashes, export content, generate reports, or rerun analysis. See DEFERRED-RESULT-001 through DEFERRED-RESULT-004.

### Durable GenAI Action Audit Ledger

Project-scoped approved GenAI actions write append-only audit events under `project/logs/genai_actions/events.ndjson`. The ledger is resolved with `project_log_path()` and guarded by `persistent_write_gate()` just like other durable project resources.

The ledger stores governance metadata only: action ids, proposal/execution ids, policy decisions, approval source, result status, safe resource references, bounded warnings/errors, and hash-chain integrity fields. It does not store raw prompts, raw rows, full result payloads, secrets, or sensitive absolute paths.

Session-scoped GenAI delegation grants are active-session state, not persistent project state. Grant creation, use, denial, revocation, expiration, and exhaustion are recorded as durable audit events when an active project is ready, but the executable authority itself is intentionally not restored after restart or project reload. See BOUNDARY-GENAI-004 and BOUNDARY-GENAI-005.

See `docs/architecture/genai_action_audit_ledger.md` for the event schema, sanitization policy, restart discovery, and reconciliation behavior.

### Improvement Ledger

The Improvement Ledger stores durable project-scoped governance records under:

```text
<project>/governance/improvement_ledger/
```

Governed Remediation Plans store bounded plan records, append-only plan events, and checkpoint metadata under:

```text
<project>/governance/remediation_plans/
  plans/
  events.ndjson
  checkpoint.json
```

Both systems use project path helpers and persistent write gates. They do not accept model-supplied paths and do not write beneath the source repository.

The project-scoped Improvement Ledger writes under `project/governance/improvement_ledger/`. Current item records live in `items/<item_id>.json`, event history lives in `events.ndjson`, and checkpoint metadata lives under `checkpoints/`. Writes use the same project path helpers and `persistent_write_gate()` policy as other durable project resources. The ledger stores bounded governance records only: no raw rows, secrets, full prompt payloads, or sensitive absolute paths.

## Current Integration

- Project page exposes workspace configuration, project creation, project close, project save, and project bundle controls.
- Project save writes through `save_project_state()` with workspace/project context and atomic RDS writes.
- Uploaded data is copied or written into `project/data/` before project save so project files do not point at stale Shiny upload paths.
- Project Artifact Collector writes under `project/collector/`.
- Report exports write under `project/reports/`.
- Table/code export helpers reject repository destinations.
- Collector defaults now fall back to session temp, not `docs/`.

## Storage Inventory

| Resource Type | Previous Risk | Trusted Destination | Project Required | Provider Required |
| --- | --- | --- | --- | --- |
| Workspace preference | Could be implied by repo/CWD behavior | `tools::R_user_dir("AnalyticsWorkstation", "config")` | No | Local/user settings or managed config |
| Session temporary results | Could drift into CWD if helpers chose relative paths | `session_temp_path()` under workspace temp or `tempdir()` | No | No, temp fallback allowed |
| Project manifest | Not previously a first-class root record | `<project>/project.json` | Yes | Yes |
| Project state RDS | Could be typed/repo-relative | `<project>/project.rds` or validated project path | Yes | Yes |
| Uploaded/project data | Could point to Shiny upload temp path | `<project>/data/` | Yes for save | Yes |
| Artifacts | Collector default previously pointed into `docs/` | `<project>/artifacts/` and `<project>/collector/artifacts/` | Yes | Yes |
| Collector DOCX/manifest | Repository-relative default risk | `<project>/collector/` | Yes | Yes |
| Human report exports | Export page defaulted to `getwd()` | `<project>/reports/` | Yes | Yes |
| Layout/report plans | App state persisted through project state | `<project>/project.rds`; future sidecars should use `<project>/layouts/` | Yes | Yes |
| Persisted results | Future persistence target | `<project>/results/` | Yes | Yes |
| Logs/audit records | Durable governance target | `<project>/logs/genai_actions/events.ndjson` for project-scoped GenAI action audit; workspace logs for future app-global events | Depends on scope | Yes for persistent logs |
| Improvement ledger | Durable project improvement governance | `<project>/governance/improvement_ledger/items/*.json` and `<project>/governance/improvement_ledger/events.ndjson` | Yes | Yes |
| Remediation plans | Durable project stepwise remediation governance | `<project>/governance/remediation_plans/plans/*.json` and `<project>/governance/remediation_plans/events.ndjson` | Yes | Yes |
| GenAI preflight/results | Temporary/session-local by design | memory/session temp only | No | No persistent provider required |

## Registered Debt References

- Cross-process project locking: TD-STORAGE-001.
- Cross-process persistence locking: TD-STORAGE-002.
- Distributed locking and multi-user conflict handling: TD-LOCKING-001.
- Schema migration strategy: TD-SCHEMA-001.
- Legacy project path compatibility: COMPAT-PROJECT-001.
- Provider/host capability differences: TD-PROJECT-002.

## Legacy Behavior

The app does not move or delete existing generated files. Legacy repository-relative paths are not trusted when rehydrating current project output settings; project reports are redirected to the active project `reports/` directory.

Existing `.rds` projects without `project_metadata` can be loaded from a valid external path. The containing directory becomes the project root after validation.

## Manual QA

1. Start the app with no stored workspace.
2. Confirm the app opens without crashing.
3. Confirm persistent saves are blocked.
4. Choose a workspace outside the repository.
5. Restart the app and confirm the workspace is restored.
6. Create a project.
7. Confirm project folders and `project.json` are created.
8. Upload data and save the project.
9. Confirm `project.rds` and `data/` live under the project root.
10. Run a module and confirm collector files live under `project/collector/`.
11. Export a report and confirm it lives under `project/reports/`.
12. Confirm no generated artifact appears in the source repository.
13. Close the project and attempt another save.
14. Confirm the write is blocked.
15. Try selecting the repository as a workspace.
16. Confirm it is rejected.
17. Delete or rename the workspace and restart.
18. Confirm invalid workspace detection and blocked writes.

## Known Limitations

- Existing standalone research/QA helpers may still write to explicit `tempdir()` or ignored research `exports/` paths.
- The app does not automatically migrate old repository-relative outputs. See COMPAT-PROJECT-001 and TD-SCHEMA-001.
- Project manifests are lightweight JSON records; the canonical app state remains `project.rds` for compatibility. See COMPAT-PROJECT-001.
- External project roots are allowed after validation, but the app does not yet maintain a full recent-project index. See TD-PROJECT-002.
