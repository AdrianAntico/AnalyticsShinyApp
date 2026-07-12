aw_contract_health_statuses <- function() {
  c(
    "healthy", "missing", "unavailable", "malformed", "partial", "partial_tail",
    "unsupported_schema", "event_history_mismatch", "hash_chain_mismatch"
  )
}

aw_contract_lifecycle_summary <- function() {
  list(
    workspace = list(
      statuses = workspace_states,
      terminal = c("workspace_invalid", "workspace_unavailable", "workspace_error"),
      awaiting = "workspace_configuring",
      running = character(),
      success = "workspace_ready"
    ),
    project = list(
      statuses = project_states,
      terminal = c("project_error", "project_closing"),
      awaiting = "project_loading",
      running = "project_loading",
      success = "project_ready"
    ),
    genai_action = list(
      statuses = genai_action_statuses(),
      terminal = c("succeeded", "failed", "rejected", "cancelled", "expired", "timed_out"),
      awaiting = c("proposed", "validated", "approved"),
      running = "executing",
      success = "succeeded"
    ),
    genai_job = list(
      statuses = genai_job_statuses(),
      terminal = genai_job_terminal_statuses(),
      awaiting = c("created", "queued", "starting", "cancel_requested", "cancelling"),
      running = "running",
      success = c("succeeded", "recovered")
    ),
    improvement = list(
      statuses = improvement_statuses(),
      terminal = improvement_terminal_statuses(),
      awaiting = c("detected", "triage_required", "awaiting_user_input", "awaiting_approval"),
      running = c("in_progress", "remediation_running", "re_evaluation_required"),
      success = c("resolved", "partially_resolved", "accepted_limitation")
    ),
    remediation = list(
      statuses = remediation_plan_statuses(),
      terminal = remediation_plan_terminal_statuses(),
      awaiting = c("draft", "awaiting_user_review", "approved", "queued", "awaiting_user_input", "awaiting_step_approval", "re_evaluation_required"),
      running = "running",
      success = c("succeeded", "partially_succeeded")
    ),
    delegation = list(
      statuses = genai_delegation_statuses(),
      terminal = c("expired", "revoked", "exhausted"),
      awaiting = character(),
      running = "active",
      success = "active"
    )
  )
}

aw_contract_schema_versions <- function() {
  data.table::data.table(
    contract = c(
      "workspace", "project", "persistence", "modeling_context",
      "feature_proposal", "feature_execution", "feature_experiment", "feature_comparison", "feature_adoption",
      "analytical_campaign", "analytical_campaign_plan", "analytical_campaign_synthesis",
      "genai_audit", "genai_delegation",
      "genai_job_record", "genai_worker_request", "genai_worker_result",
      "genai_progress_event", "genai_dataset_snapshot", "genai_recovery_state",
      "improvement_item", "improvement_event", "improvement_checkpoint",
      "remediation_plan", "remediation_plan_step", "remediation_plan_event",
      "remediation_checkpoint"
    ),
    version = c(
      storage_schema_version, project_schema_version, persistence_schema_version,
      modeling_context_schema_version(),
      feature_proposal_schema_version(), feature_execution_schema_version(),
      feature_experiment_schema_version(), feature_comparison_schema_version(),
      feature_adoption_schema_version(),
      analytical_campaign_schema_version(), analytical_campaign_plan_schema_version(),
      analytical_campaign_synthesis_schema_version(),
      genai_audit_schema_version(), genai_delegation_schema_version(),
      genai_job_record_schema_version(), genai_worker_request_schema_version(),
      genai_worker_result_schema_version(), genai_progress_event_schema_version(),
      genai_dataset_snapshot_schema_version(), genai_recovery_state_schema_version(),
      improvement_item_schema_version(), improvement_event_schema_version(),
      improvement_checkpoint_schema_version(), remediation_plan_schema_version(),
      remediation_plan_step_schema_version(), remediation_plan_event_schema_version(),
      remediation_plan_checkpoint_schema_version()
    )
  )
}

aw_contract_identity_samples <- function() {
  now <- Sys.time()
  data.table::data.table(
    identity_type = c(
      "project", "proposal", "execution", "audit_event", "genai_job",
      "improvement_item", "remediation_plan", "remediation_event"
    ),
    sample_id = c(
      safe_path_component("Cross System Project", "project"),
      genai_action_proposal("module.open", list(module_id = "autoquant_eda"), "Open module.", proposal_id = paste0("proposal_", format(now, "%Y%m%d%H%M%S"), "_000001"))$proposal_id,
      paste0("execution_", format(now, "%Y%m%d%H%M%S"), "_000001"),
      genai_audit_new_event_id(now),
      genai_job_id(),
      paste0("item_", substr(storage_hash_value(list("item", now)), 1L, 16L)),
      remediation_plan_id("project", "item", "Plan", revision = 1L),
      paste0("event_", substr(storage_hash_value(list("event", now)), 1L, 16L))
    )
  )
}

aw_contract_required_docs <- function() {
  c(
    "docs/architecture/workspace_project_storage.md",
    "docs/architecture/analytical_improvement_campaign.md",
    "docs/architecture/genai_action_layer.md",
    "docs/architecture/genai_action_audit_ledger.md",
    "docs/architecture/genai_delegation_policy.md",
    "docs/architecture/genai_job_execution.md",
    "docs/architecture/improvement_ledger.md",
    "docs/architecture/remediation_plans.md",
    "docs/architecture/schema_version_inventory.md",
    "docs/architecture/cross_system_invariants.md",
    "docs/architecture/qa_reliability_and_screenshot_cleanup.md"
  )
}

qa_cross_system_invariants <- function() {
  rows <- list()
  add <- function(check, status, message, file = "R/cross_system_contracts.R", severity = "error") {
    rows[[length(rows) + 1L]] <<- data.table::data.table(check = check, status = status, severity = severity, file = file, message = message)
  }

  lifecycle <- aw_contract_lifecycle_summary()
  add("lifecycle_contracts_present", if (length(lifecycle) >= 7L) "success" else "error", "Core systems expose lifecycle summaries.")
  for (name in names(lifecycle)) {
    item <- lifecycle[[name]]
    unknown <- setdiff(unique(c(item$terminal, item$awaiting, item$running, item$success)), item$statuses)
    add(paste0("lifecycle_known_statuses_", name), if (!length(unknown)) "success" else "error", paste("Unknown statuses:", paste(unknown, collapse = ", ")))
    add(paste0("lifecycle_terminal_nonempty_", name), if (length(item$terminal)) "success" else "error", paste(name, "has terminal or historical states."))
  }

  add("remediation_terminal_states_have_no_outgoing_transitions", if (!length(remediation_plan_lifecycle_diagnostics()$terminal_with_outgoing_transitions)) "success" else "error", "Remediation terminal states are closed.")
  job_terminal_open <- names(genai_job_transition_map())[names(genai_job_transition_map()) %in% genai_job_terminal_statuses() & vapply(genai_job_transition_map(), length, integer(1)) > 0L]
  expected_job_open <- "succeeded"
  add("genai_job_terminal_transitions_are_intentional", if (setequal(job_terminal_open, expected_job_open)) "success" else "error", paste("Unexpected terminal job transitions:", paste(job_terminal_open, collapse = ", ")))

  identities <- aw_contract_identity_samples()
  add("identity_samples_are_storage_safe", if (all(vapply(identities$sample_id, storage_resource_id_is_valid, logical(1)))) "success" else "error", "Generated cross-system ids are storage-safe.")
  add("identity_samples_have_type_prefixes", if (all(grepl("^[A-Za-z]+_", identities$sample_id) | identities$identity_type == "project")) "success" else "error", "Non-project ids carry readable type prefixes.")

  schemas <- aw_contract_schema_versions()
  add("schema_versions_are_declared", if (nrow(schemas) >= 18L && all(nzchar(schemas$version))) "success" else "error", "Cross-system schema versions are declared.")
  inventory <- if (file.exists("docs/architecture/schema_version_inventory.md")) paste(readLines("docs/architecture/schema_version_inventory.md", warn = FALSE), collapse = "\n") else ""
  missing_schema_docs <- schemas$contract[!vapply(schemas$version, function(version) grepl(version, inventory, fixed = TRUE), logical(1))]
  add("schema_versions_documented", if (!length(missing_schema_docs)) "success" else "error", paste("Schema versions missing from inventory:", paste(missing_schema_docs, collapse = ", ")), file = "docs/architecture/schema_version_inventory.md")

  health_states <- aw_contract_health_statuses()
  add("health_vocabulary_includes_unhealthy_replay_states", if (all(c("healthy", "missing", "malformed", "unsupported_schema", "event_history_mismatch", "hash_chain_mismatch") %in% health_states)) "success" else "error", "Shared health vocabulary covers replay and hash failures.")
  reader_functions <- c("genai_audit_read_events", "improvement_read_events", "remediation_plan_read_events")
  reader_exists <- vapply(reader_functions, function(name) exists(name, envir = environment(qa_cross_system_invariants), mode = "function"), logical(1))
  add("ledger_readers_expose_health", if (all(reader_exists)) "success" else "error", paste("Missing health-aware ledger readers:", paste(reader_functions[!reader_exists], collapse = ", ")))

  audit_events <- genai_audit_event_types()
  add("genai_audit_includes_job_events", if (all(genai_job_event_types() %in% audit_events)) "success" else "error", "GenAI job events are represented in the action audit ledger.")
  remediation_events <- remediation_plan_event_types()
  add("remediation_events_cover_terminal_outcomes", if (all(c("plan_succeeded", "plan_failed", "plan_cancelled", "plan_expired", "plan_superseded") %in% remediation_events)) "success" else "error", "Remediation events cover terminal outcomes.")
  improvement_events <- improvement_event_types()
  add("improvement_events_distinguish_attempt_and_resolution", if (all(c("remediation_succeeded", "remediation_failed", "re_evaluation_completed", "item_resolved", "item_partially_resolved") %in% improvement_events)) "success" else "error", "Improvement events distinguish attempts from verified resolution.")

  docs <- aw_contract_required_docs()
  add("contract_docs_exist", if (all(file.exists(docs))) "success" else "error", paste("Missing docs:", paste(docs[!file.exists(docs)], collapse = ", ")))
  invariant_doc <- if (file.exists("docs/architecture/cross_system_invariants.md")) paste(readLines("docs/architecture/cross_system_invariants.md", warn = FALSE), collapse = "\n") else ""
  required_terms <- c("append-only", "deterministic", "state transitions", "registered actions", "trusted project storage", "schema versions", "modeling context")
  missing_terms <- required_terms[!vapply(required_terms, function(term) grepl(term, invariant_doc, ignore.case = TRUE), logical(1))]
  add("architectural_invariants_documented", if (!length(missing_terms)) "success" else "error", paste("Missing invariant terms:", paste(missing_terms, collapse = ", ")), file = "docs/architecture/cross_system_invariants.md")

  schema_doc <- if (file.exists("docs/architecture/schema_version_inventory.md")) paste(readLines("docs/architecture/schema_version_inventory.md", warn = FALSE), collapse = "\n") else ""
  add("modeling_context_schema_documented", if (grepl(modeling_context_schema_version(), schema_doc, fixed = TRUE)) "success" else "error", "Active modeling context schema is documented.", file = "docs/architecture/schema_version_inventory.md")

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

qa_production_workflow_exercise <- function(output_dir = file.path(tempdir(), "production_workflow_exercise_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  rows <- list()
  add <- function(check, status, message, file = "R/cross_system_contracts.R", severity = NULL) {
    severity <- severity %||% if (identical(status, "success")) "info" else "error"
    rows[[length(rows) + 1L]] <<- data.table::data.table(check = check, status = status, severity = severity, file = file, message = message)
  }

  provider <- storage_provider(
    provider_id = "production_workflow_qa_provider",
    provider_type = "local_server_directory",
    display_name = "Production Workflow QA Provider",
    root_path = output_dir,
    available = TRUE,
    selection_supported = TRUE,
    managed = FALSE,
    writable = TRUE,
    capabilities = list(supports_external_projects = TRUE, can_choose_directory = TRUE)
  )
  workspace <- validate_workspace_root(output_dir, create = TRUE, provider = provider, repo_root = storage_repo_root())
  add("workspace_created", if (identical(workspace$status, "success")) "success" else "error", paste(workspace$errors %||% "Workspace ready.", collapse = "; "))
  if (!identical(workspace$status, "success")) return(data.table::rbindlist(rows, use.names = TRUE, fill = TRUE))

  project_result <- create_project_in_workspace(workspace$value, "Production Workflow QA", project_id = "production_workflow_qa")
  add("project_created", if (identical(project_result$status, "success")) "success" else "error", paste(project_result$errors %||% "Project ready.", collapse = "; "))
  if (!identical(project_result$status, "success")) return(data.table::rbindlist(rows, use.names = TRUE, fill = TRUE))
  project <- project_result$value

  data <- data.table::data.table(
    customer_id = seq_len(12L),
    segment = rep(c("Enterprise", "SMB", "Consumer"), each = 4L),
    spend = c(100, 120, 110, 140, 55, 65, 62, 75, 20, 22, 19, 28),
    revenue = c(240, 280, 260, 310, 120, 130, 128, 150, 38, 40, 34, 55)
  )
  data_path <- project_path(project, "data", "workflow_sample.csv", create_dir = FALSE)
  data.table::fwrite(data, data_path)
  imported <- file.exists(data_path) && nrow(data.table::fread(data_path)) == nrow(data)
  add("data_imported_to_project_storage", if (imported) "success" else "error", paste("Data path:", data_path))

  table_artifact <- create_artifact(
    artifact_id = "workflow_summary_table",
    artifact_type = "table",
    label = "Workflow Summary Table",
    source_module = "production_workflow_qa",
    object = data[, .(rows = .N, avg_spend = mean(spend), avg_revenue = mean(revenue)), by = segment],
    section = "Workflow Evidence",
    metadata = list(created_by_module = TRUE, module_id = "production_workflow_qa"),
    order = 1L
  )
  narrative_artifact <- create_artifact(
    artifact_id = "workflow_readiness_note",
    artifact_type = "narrative",
    label = "Workflow Readiness Note",
    source_module = "production_workflow_qa",
    content = "Synthetic workflow evidence confirms project storage, collector append, and governance handoff.",
    section = "Workflow Evidence",
    metadata = list(created_by_module = TRUE, module_id = "production_workflow_qa"),
    order = 2L
  )
  bundle <- project_artifact_bundle(
    project_id = project$project_id,
    project_name = project$project_name,
    run_id = "run_001",
    module_id = "production_workflow_qa",
    module_label = "Production Workflow QA",
    artifacts = list(summary = table_artifact, note = narrative_artifact),
    status = "success"
  )
  collector <- create_project_artifact_collector(
    project_id = project$project_id,
    project_name = project$project_name,
    output_dir = project_path(project, "collector", create_dir = TRUE)
  )
  appended <- project_collector_append_bundle(collector, bundle, write = TRUE)
  collector <- appended$value %||% collector
  manifest <- if (file.exists(collector$manifest_file)) data.table::fread(collector$manifest_file) else data.table::data.table()
  table_sidecars <- list.files(collector$table_directory, pattern = "\\.(csv|json)$", full.names = TRUE)
  add("artifacts_collected", if (identical(appended$status, "success") && nrow(manifest) == 1L) "success" else "error", paste("Collector append:", appended$status))
  add("collector_outputs_written", if (file.exists(collector$collector_docx) && file.exists(collector$manifest_file)) "success" else "error", "Collector DOCX and manifest exist.")
  add("collector_sidecars_written", if (length(table_sidecars) >= 2L && all(file.exists(table_sidecars)) && all(file.info(table_sidecars)$size > 0)) "success" else "error", paste("Sidecars:", length(table_sidecars)))

  proposal <- genai_action_proposal(
    action_id = "module.open",
    action_version = "1.0",
    arguments = list(module_id = "production_workflow_qa"),
    rationale = "Record workflow audit visibility.",
    risk_tier = "low"
  )
  audit_event <- list(
    audit_event_id = genai_audit_new_event_id(),
    audit_schema_version = genai_audit_schema_version(),
    event_type = "execution_succeeded",
    event_timestamp = storage_now(),
    project_id = project$project_id,
    action_id = proposal$action_id,
    action_version = proposal$action_version,
    risk_tier = proposal$risk_tier,
    proposal_id = proposal$proposal_id,
    proposal_hash = proposal$proposal_hash,
    execution_id = paste0("execution_", substr(storage_hash_value(list(project$project_id, Sys.time())), 1L, 12L)),
    approval_source = "qa",
    policy_decision = "approved",
    result_status = "succeeded"
  )
  audit_append <- genai_audit_append_event(project, workspace$value, audit_event)
  audit_summary <- genai_project_audit_summary(project)
  add("audit_history_written", if (identical(audit_append$status, "success") && nrow(audit_summary) == 1L && audit_summary$event_count[[1]] >= 1L) "success" else "error", paste("Audit append:", audit_append$status))

  item_result <- improvement_create_user_item(
    project,
    workspace$value,
    "Verify production workflow",
    "Workflow exercise should resolve after deterministic re-evaluation.",
    item_type = "user_requested_change",
    priority = "high",
    affected_component = "Workflow",
    desired_outcome = "workflow verified",
    evidence_refs = list(list(evidence_type = "artifact", evidence_id = "workflow_summary_table", relationship = "supports"))
  )
  item <- item_result$value
  accepted <- improvement_item_safe_transition(item, "accepted", "Accepted for production workflow QA.")
  if (identical(accepted$status, "success")) {
    improvement_save_item(project, workspace$value, accepted$value, event_type = "item_accepted", event_summary = "Accepted for QA.", actor = "qa")
    item <- improvement_load_item(project, item$item_id)$value
  }
  add("improvement_item_created_and_accepted", if (identical(item_result$status, "success") && identical(item$status, "accepted")) "success" else "error", paste("Item status:", item$status %||% NA_character_))

  steps <- list(
    remediation_plan_step(1, "informational", "Review workflow evidence", expected_effect = "Evidence reviewed.", failure_policy = "continue_with_warning", stop_on_failure = FALSE),
    remediation_plan_step(
      2,
      "deterministic_re_evaluation",
      "Verify workflow outcome",
      depends_on = "step_001_Review_workflow_evidence",
      re_evaluation_spec = list(evaluation_id = "workflow_verified", source_item_id = item$item_id, pass_condition = "always_pass"),
      expected_effect = "Workflow verified.",
      failure_policy = "stop_plan"
    )
  )
  plan <- remediation_plan_new(
    project = project,
    source_item = item,
    title = "Production workflow remediation",
    objective = "Resolve the workflow exercise item.",
    steps = steps,
    success_criteria = c("workflow verified"),
    stop_conditions = remediation_plan_default_stop_conditions(),
    risk_tier = "low",
    approval_policy = "plan_and_low_risk_steps",
    maximum_steps = 5L,
    maximum_persistent_actions = 0L
  )
  plan <- remediation_plan_safe_transition(plan, "awaiting_user_review", "Ready for review.")$value
  saved_plan <- remediation_plan_save(project, workspace$value, plan, "plan_created", "Workflow remediation plan.", source_item = item)
  approved_plan <- remediation_plan_approve(project, workspace$value, plan$plan_id, approved_by = "qa", approval_policy = "plan_and_low_risk_steps")
  first_step <- remediation_plan_execute_next_step(project, workspace$value, plan$plan_id)
  second_step <- remediation_plan_execute_next_step(project, workspace$value, plan$plan_id)
  loaded_plan <- remediation_plan_load(project, plan$plan_id)
  loaded_item <- improvement_load_item(project, item$item_id)
  add("remediation_plan_completed", if (identical(saved_plan$status, "success") && identical(approved_plan$status, "success") && identical(first_step$status, "success") && identical(second_step$status, "success") && identical(loaded_plan$value$status, "succeeded")) "success" else "error", paste("Plan status:", loaded_plan$value$status %||% loaded_plan$status))
  add("improvement_ledger_resolved", if (identical(loaded_item$status, "success") && identical(loaded_item$value$status, "resolved") && length(loaded_item$value$re_evaluation_history %||% list()) == 1L) "success" else "error", paste("Item status:", loaded_item$value$status %||% loaded_item$status))

  expired_fx <- improvement_create_user_item(project, workspace$value, "Expired plan failure path", "Expired plans should fail closed.", priority = "normal", affected_component = "Workflow")
  expired_item <- expired_fx$value
  expired_accepted <- improvement_item_safe_transition(expired_item, "accepted", "Accepted for expired-plan QA.")
  if (identical(expired_accepted$status, "success")) {
    improvement_save_item(project, workspace$value, expired_accepted$value, event_type = "item_accepted", event_summary = "Accepted expired-plan QA.", actor = "qa")
    expired_item <- improvement_load_item(project, expired_item$item_id)$value
  }
  expired_plan <- remediation_plan_new(
    project = project,
    source_item = expired_item,
    title = "Expired workflow plan",
    objective = "Exercise failure path.",
    steps = list(remediation_plan_step(1, "informational", "Expired step")),
    success_criteria = c("not executed"),
    stop_conditions = remediation_plan_default_stop_conditions(),
    risk_tier = "low",
    approval_policy = "plan_structure_only",
    maximum_steps = 3L,
    maximum_persistent_actions = 0L
  )
  expired_plan <- remediation_plan_safe_transition(expired_plan, "awaiting_user_review", "Ready for review.")$value
  expired_plan$expires_at <- format(Sys.time() - 60, "%Y-%m-%dT%H:%M:%S%z")
  remediation_plan_save(project, workspace$value, expired_plan, "plan_created", "Expired workflow plan.", source_item = expired_item)
  remediation_plan_approve(project, workspace$value, expired_plan$plan_id)
  expired_result <- remediation_plan_execute_next_step(project, workspace$value, expired_plan$plan_id)
  add("failure_path_expired_plan_fails_closed", if (identical(expired_result$status, "error") && identical(remediation_plan_load(project, expired_plan$plan_id)$value$status, "expired")) "success" else "error", paste("Expired result:", expired_result$status))

  improvement_summary <- improvement_ledger_summary(project)
  remediation_summary <- remediation_plan_summary(project)
  remediation_events <- remediation_plan_read_events(project)
  improvement_events <- improvement_read_events(project)
  audit_events <- genai_audit_read_events(project)
  remediation_all <- remediation_plan_load_all(project)
  remediation_table <- if (identical(remediation_all$status, "success")) remediation_plan_table(remediation_all$value$plans) else data.table::data.table()
  add("ledger_summaries_visible", if (nrow(improvement_summary) == 1L && nrow(remediation_summary) == 1L && improvement_summary$total_items[[1]] >= 2L && remediation_summary$total_plans[[1]] >= 2L) "success" else "error", "Improvement and remediation summaries expose workflow state.")
  add("improvement_outcome_count_exact", if (improvement_summary$total_items[[1]] == 2L && improvement_summary$resolved_items[[1]] == 1L) "success" else "error", paste("Items:", improvement_summary$total_items[[1]], "resolved:", improvement_summary$resolved_items[[1]]))
  add("remediation_outcome_count_exact", if (nrow(remediation_table) == 2L && sum(remediation_table$status == "succeeded") == 1L && sum(remediation_table$status == "expired") == 1L) "success" else "error", paste("Plans:", nrow(remediation_table), "succeeded:", sum(remediation_table$status == "succeeded"), "expired:", sum(remediation_table$status == "expired")))
  add("event_histories_have_expected_minimums", if (nrow(improvement_events$value$events) >= 6L && nrow(remediation_events$value$events) >= 8L && nrow(audit_events$value$events) >= 1L) "success" else "error", paste("Events:", nrow(improvement_events$value$events), nrow(remediation_events$value$events), nrow(audit_events$value$events)))
  add("event_replay_healthy", if (identical(improvement_events$value$ledger_health, "healthy") && identical(remediation_events$value$ledger_health, "healthy") && identical(audit_events$value$ledger_health, "healthy")) "success" else "error", paste("Health:", improvement_events$value$ledger_health, remediation_events$value$ledger_health, audit_events$value$ledger_health))
  add("mission_control_visibility", if (improvement_summary$resolved_items[[1]] >= 1L && remediation_summary$failed_plans[[1]] >= 0L && audit_summary$event_count[[1]] >= 1L) "success" else "error", "Mission Control source summaries can see workflow outputs.")

  project_closed <- project
  project_closed$project_state <- "project_closing"
  closed_write <- tryCatch(project_path(project_closed, "reports"), error = function(e) e)
  add("closed_project_blocks_project_paths", if (inherits(closed_write, "error")) "success" else "error", "Closing a project blocks new project path writes.")

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
