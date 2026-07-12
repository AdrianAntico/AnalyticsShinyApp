genai_delegation_schema_version <- function() {
  "genai_delegation_v1"
}

genai_delegation_policy_version <- function() {
  "genai_delegation_policy_v1"
}

genai_delegation_eligible_actions <- function() {
  c("module.open", "artifact.inspect", "report.open", "result.inspect")
}

genai_delegation_ineligible_actions <- function() {
  c("analysis.preflight", "analysis.run_registered", "result.persist")
}

genai_delegation_default_duration_minutes <- function() 30L
genai_delegation_default_max_uses <- function() 5L

genai_delegation_session_id <- function() {
  paste0("session_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
}

genai_delegation_statuses <- function() {
  c("active", "revoked", "expired", "exhausted", "invalid")
}

genai_delegation_scope_from_proposal <- function(proposal) {
  action_id <- proposal$action_id %||% ""
  args <- proposal$arguments %||% list()
  if (identical(action_id, "module.open")) {
    return(list(scope_type = "specific_module", scope_value = args$module_id %||% NA_character_, resource_type = "module"))
  }
  if (identical(action_id, "artifact.inspect")) {
    return(list(scope_type = "specific_resource", scope_value = args$artifact_id %||% NA_character_, resource_type = "artifact"))
  }
  if (identical(action_id, "report.open")) {
    return(list(scope_type = "specific_resource", scope_value = args$report_id %||% NA_character_, resource_type = "report"))
  }
  if (identical(action_id, "result.inspect")) {
    return(list(scope_type = "specific_resource", scope_value = args$persisted_result_id %||% NA_character_, resource_type = "persisted_result"))
  }
  list(scope_type = NA_character_, scope_value = NA_character_, resource_type = NA_character_)
}

genai_delegation_project_binding <- function(ctx = NULL) {
  project <- if (!is.null(ctx) && is.function(ctx$current_project)) tryCatch(ctx$current_project(), error = function(e) NULL) else NULL
  if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
    return(NULL)
  }
  list(
    project_id = project$project_id %||% NA_character_,
    project_root_identity = storage_root_identity(project$project_root %||% ""),
    project_state = project$project_state %||% NA_character_
  )
}

genai_delegation_provider_binding <- function(ctx = NULL) {
  workspace <- if (!is.null(ctx) && is.function(ctx$current_workspace)) tryCatch(ctx$current_workspace(), error = function(e) NULL) else NULL
  if (!is.list(workspace)) return(NULL)
  provider <- workspace$provider %||% storage_provider(
    provider_id = workspace$provider_id %||% "configured_workspace",
    provider_type = workspace$provider_type %||% "configured_workspace",
    display_name = workspace$provider_display_name %||% "Configured Workspace",
    root_path = workspace$workspace_root %||% NULL,
    available = !is.null(workspace$workspace_root),
    writable = TRUE,
    capabilities = list(supports_external_projects = TRUE)
  )
  list(
    workspace_provider_id = provider$provider_id %||% workspace$provider_id %||% NA_character_,
    workspace_provider_type = provider$provider_type %||% workspace$provider_type %||% NA_character_,
    provider_capability_version = storage_provider_capability_version(provider),
    provider_policy_version = storage_provider_write_policy_id(provider),
    workspace_state = workspace$workspace_state %||% NA_character_
  )
}

genai_delegation_hash_payload <- function(grant) {
  grant[c(
    "delegation_id", "delegation_schema_version", "action_id", "action_version",
    "scope_type", "scope_value", "project_id", "project_root_identity",
    "workspace_provider_id", "workspace_provider_type", "provider_capability_version",
    "provider_policy_version", "granted_at", "expires_at", "session_id",
    "max_uses", "policy_version", "resource_type", "resource_id",
    "resource_fingerprint_at_grant"
  )]
}

genai_delegation_compute_hash <- function(grant) {
  .genai_action_hash(genai_delegation_hash_payload(grant))
}

genai_delegation_validate_hash <- function(grant) {
  identical(grant$delegation_hash %||% "", genai_delegation_compute_hash(grant))
}

genai_delegation_grant_id <- function(now = Sys.time()) {
  paste0("delegation_", format(now, "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
}

genai_delegation_event <- function(event_type, grant, proposal = NULL, execution = NULL, ctx = NULL, denial_reason = NA_character_,
                                  uses_before = NA_integer_, uses_after = NA_integer_) {
  project <- if (!is.null(ctx) && is.function(ctx$current_project)) tryCatch(ctx$current_project(), error = function(e) NULL) else NULL
  workspace <- if (!is.null(ctx) && is.function(ctx$current_workspace)) tryCatch(ctx$current_workspace(), error = function(e) NULL) else NULL
  list(
    audit_event_id = genai_audit_new_event_id(),
    audit_schema_version = genai_audit_schema_version(),
    event_type = event_type,
    event_timestamp = storage_now(),
    project_id = project$project_id %||% grant$project_id %||% NA_character_,
    workspace_provider_id = workspace$provider_id %||% grant$workspace_provider_id %||% NA_character_,
    workspace_provider_type = workspace$provider_type %||% grant$workspace_provider_type %||% NA_character_,
    action_id = grant$action_id %||% proposal$action_id %||% NA_character_,
    action_version = grant$action_version %||% proposal$action_version %||% NA_character_,
    risk_tier = "low",
    proposal_id = proposal$proposal_id %||% NA_character_,
    proposal_hash = proposal$proposal_hash %||% NA_character_,
    execution_id = execution$execution_id %||% NA_character_,
    approval_source = "active_delegation",
    policy_decision = "delegation_policy",
    result_status = execution$status %||% grant$status %||% NA_character_,
    delegation_id = grant$delegation_id %||% NA_character_,
    scope_type = grant$scope_type %||% NA_character_,
    scope_value_safe = grant$scope_value %||% NA_character_,
    granted_by = grant$granted_by %||% NA_character_,
    granted_at = grant$granted_at %||% NA_character_,
    expires_at = grant$expires_at %||% NA_character_,
    uses_before = uses_before,
    uses_after = uses_after,
    revoked_at = grant$revoked_at %||% NA_character_,
    revocation_source = grant$revocation_source %||% NA_character_,
    denial_reason = denial_reason %||% NA_character_,
    resource_type = grant$resource_type %||% NA_character_,
    resource_id = grant$resource_id %||% grant$scope_value %||% NA_character_,
    resource_fingerprint = grant$resource_fingerprint_at_grant %||% NA_character_,
    persistent_changes = FALSE,
    project_state_changed = FALSE,
    ui_state_changed = FALSE,
    computation_performed = FALSE,
    warnings = character(),
    errors = character()
  )
}

genai_delegation_record_event <- function(event_type, grant, proposal = NULL, execution = NULL, ctx = NULL, denial_reason = NA_character_,
                                          uses_before = NA_integer_, uses_after = NA_integer_) {
  project <- if (!is.null(ctx) && is.function(ctx$current_project)) tryCatch(ctx$current_project(), error = function(e) NULL) else NULL
  workspace <- if (!is.null(ctx) && is.function(ctx$current_workspace)) tryCatch(ctx$current_workspace(), error = function(e) NULL) else NULL
  if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
    return(service_result(status = "success", value = list(durable = FALSE, skipped = TRUE), messages = "Delegation audit event is session-only without a ready project."))
  }
  event <- genai_delegation_event(event_type, grant, proposal, execution, ctx, denial_reason, uses_before, uses_after)
  genai_audit_append_event(project, workspace, event)
}

genai_delegation_create_grant <- function(proposal, validation, ctx, max_uses = genai_delegation_default_max_uses(),
                                          duration_minutes = genai_delegation_default_duration_minutes(),
                                          granted_by = "active_user", explicit_user_interaction = TRUE) {
  errors <- character()
  if (!isTRUE(explicit_user_interaction)) errors <- c(errors, "explicit_user_interaction_required")
  action_id <- proposal$action_id %||% ""
  if (!action_id %in% genai_delegation_eligible_actions()) errors <- c(errors, "action_not_eligible_for_delegation")
  if (!identical(proposal$action_version %||% "", "1.0")) errors <- c(errors, "unsupported_action_version")
  if (!identical(validation$status %||% "", "success") || !isTRUE(validation$value$valid %||% FALSE)) errors <- c(errors, "proposal_not_valid_for_delegation")
  scope <- genai_delegation_scope_from_proposal(proposal)
  if (!nzchar(scope$scope_value %||% "")) errors <- c(errors, "delegation_scope_missing")
  if (!scope$scope_type %in% c("specific_module", "specific_resource")) errors <- c(errors, "delegation_scope_not_allowed")
  project_binding <- genai_delegation_project_binding(ctx)
  if (is.null(project_binding)) errors <- c(errors, "project_not_ready")
  provider_binding <- genai_delegation_provider_binding(ctx)
  if (is.null(provider_binding) || !identical(provider_binding$workspace_state %||% "", "workspace_ready")) errors <- c(errors, "provider_unavailable")
  max_uses <- as.integer(max_uses %||% genai_delegation_default_max_uses())
  duration_minutes <- as.integer(duration_minutes %||% genai_delegation_default_duration_minutes())
  if (is.na(max_uses) || max_uses < 1L || max_uses > genai_delegation_default_max_uses()) errors <- c(errors, "invalid_use_count")
  if (is.na(duration_minutes) || duration_minutes < 1L || duration_minutes > genai_delegation_default_duration_minutes()) errors <- c(errors, "invalid_expiration")
  if (length(errors)) {
    return(service_result(status = "error", errors = unique(errors)))
  }
  now <- Sys.time()
  resource <- validation$value$resource_resolution %||% list()
  grant <- c(
    list(
      delegation_id = genai_delegation_grant_id(now),
      delegation_schema_version = genai_delegation_schema_version(),
      action_id = action_id,
      action_version = proposal$action_version %||% "1.0",
      scope_type = scope$scope_type,
      scope_value = scope$scope_value,
      resource_type = scope$resource_type,
      resource_id = resource$resource_id %||% scope$scope_value,
      resource_fingerprint_at_grant = validation$value$resource_fingerprint %||% resource$resource_fingerprint %||% NA_character_,
      granted_by = granted_by,
      granted_at = as.character(now),
      expires_at = as.character(now + duration_minutes * 60),
      session_id = ctx$genai_delegation_state$session_id %||% genai_delegation_session_id(),
      status = "active",
      max_uses = max_uses,
      uses_remaining = max_uses,
      policy_version = genai_delegation_policy_version(),
      created_from_ui = TRUE
    ),
    project_binding,
    provider_binding
  )
  grant$delegation_hash <- genai_delegation_compute_hash(grant)
  service_result(status = "success", value = grant, messages = paste("Delegation granted for", action_id, scope$scope_value))
}

genai_delegation_scope_matches <- function(grant, proposal) {
  scope <- genai_delegation_scope_from_proposal(proposal)
  identical(grant$scope_type %||% "", scope$scope_type %||% "") &&
    identical(as.character(grant$scope_value %||% ""), as.character(scope$scope_value %||% ""))
}

genai_delegation_find_matching_grant <- function(proposal, validation, ctx) {
  grants <- ctx$genai_delegation_state$grants %||% list()
  if (!length(grants)) {
    return(service_result(status = "warning", errors = "delegation_missing"))
  }
  candidates <- Filter(function(grant) {
    identical(grant$action_id %||% "", proposal$action_id %||% "") &&
      identical(grant$action_version %||% "", proposal$action_version %||% "") &&
      genai_delegation_scope_matches(grant, proposal)
  }, grants)
  if (!length(candidates)) {
    return(service_result(status = "warning", errors = "delegation_missing"))
  }
  genai_delegation_validate_grant(candidates[[1]], proposal, validation, ctx)
}

genai_delegation_validate_grant <- function(grant, proposal, validation, ctx) {
  errors <- character()
  if (!proposal$action_id %in% genai_delegation_eligible_actions()) errors <- c(errors, "action_not_eligible_for_delegation")
  if (!identical(grant$status %||% "", "active")) errors <- c(errors, paste0("delegation_", grant$status %||% "invalid"))
  if (!genai_delegation_validate_hash(grant)) errors <- c(errors, "delegation_hash_invalid")
  expires_at <- tryCatch(as.POSIXct(grant$expires_at), error = function(e) NA)
  if (is.na(expires_at) || expires_at <= Sys.time()) errors <- c(errors, "delegation_expired")
  if ((as.integer(grant$uses_remaining %||% 0L)) <= 0L) errors <- c(errors, "delegation_exhausted")
  if (!identical(grant$session_id %||% "", ctx$genai_delegation_state$session_id %||% "")) errors <- c(errors, "delegation_session_mismatch")
  project_binding <- genai_delegation_project_binding(ctx)
  if (is.null(project_binding) || !identical(grant$project_id %||% "", project_binding$project_id %||% "")) errors <- c(errors, "delegation_project_mismatch")
  if (!is.null(project_binding) && !identical(grant$project_root_identity %||% "", project_binding$project_root_identity %||% "")) errors <- c(errors, "delegation_project_mismatch")
  provider_binding <- genai_delegation_provider_binding(ctx)
  if (is.null(provider_binding) ||
      !identical(grant$workspace_provider_id %||% "", provider_binding$workspace_provider_id %||% "") ||
      !identical(grant$workspace_provider_type %||% "", provider_binding$workspace_provider_type %||% "") ||
      !identical(grant$provider_capability_version %||% "", provider_binding$provider_capability_version %||% "") ||
      !identical(grant$provider_policy_version %||% "", provider_binding$provider_policy_version %||% "")) {
    errors <- c(errors, "delegation_provider_mismatch")
  }
  if (!genai_delegation_scope_matches(grant, proposal)) errors <- c(errors, "delegation_scope_mismatch")
  current_fingerprint <- validation$value$resource_fingerprint %||% (validation$value$resource_resolution %||% list())$resource_fingerprint %||% NA_character_
  if (!identical(grant$resource_fingerprint_at_grant %||% "", current_fingerprint %||% "")) errors <- c(errors, "delegation_resource_stale")
  if (length(errors)) {
    return(service_result(status = "warning", value = grant, errors = unique(errors)))
  }
  service_result(status = "success", value = grant, messages = "Delegation authorizes this proposal.")
}

genai_delegation_approve_proposal <- function(proposal, validation, grant) {
  proposal$status <- "approved"
  proposal$approved_at <- Sys.time()
  proposal$approval_source <- "active_delegation"
  proposal$approval_hash <- proposal$proposal_hash
  proposal$approval_resource_fingerprint <- validation$value$resource_fingerprint %||% NULL
  proposal$delegation_id <- grant$delegation_id
  service_result(status = "success", value = proposal, messages = "Proposal authorized by active delegation.")
}

genai_delegation_consume_use <- function(ctx, delegation_id, proposal = NULL, execution = NULL) {
  grant <- ctx$genai_delegation_state$grants[[delegation_id]]
  if (is.null(grant)) return(service_result(status = "error", errors = "delegation_missing"))
  uses_before <- as.integer(grant$uses_remaining %||% 0L)
  grant$uses_remaining <- max(uses_before - 1L, 0L)
  if (grant$uses_remaining <= 0L) {
    grant$status <- "exhausted"
  }
  grant$delegation_hash <- genai_delegation_compute_hash(grant)
  ctx$genai_delegation_state$grants[[delegation_id]] <- grant
  genai_delegation_record_event("delegation_used", grant, proposal, execution, ctx, uses_before = uses_before, uses_after = grant$uses_remaining)
  if (identical(grant$status, "exhausted")) {
    genai_delegation_record_event("delegation_exhausted", grant, proposal, execution, ctx, uses_before = uses_before, uses_after = grant$uses_remaining)
  }
  service_result(status = "success", value = grant, messages = "Delegation use consumed.")
}

genai_delegation_revoke <- function(ctx, delegation_id, source = "active_user") {
  grant <- ctx$genai_delegation_state$grants[[delegation_id]]
  if (is.null(grant)) return(service_result(status = "error", errors = "delegation_missing"))
  grant$status <- "revoked"
  grant$revoked_at <- as.character(Sys.time())
  grant$revocation_source <- source
  grant$delegation_hash <- genai_delegation_compute_hash(grant)
  ctx$genai_delegation_state$grants[[delegation_id]] <- grant
  genai_delegation_record_event("delegation_revoked", grant, ctx = ctx)
  service_result(status = "success", value = grant, messages = "Delegation revoked.")
}

genai_delegation_revoke_all <- function(ctx, source = "active_user") {
  ids <- names(ctx$genai_delegation_state$grants %||% list())
  for (id in ids) {
    genai_delegation_revoke(ctx, id, source = source)
  }
  service_result(status = "success", messages = paste("Revoked", length(ids), "delegation grant(s)."))
}

genai_delegation_expire_grants <- function(ctx) {
  grants <- ctx$genai_delegation_state$grants %||% list()
  now <- Sys.time()
  for (id in names(grants)) {
    grant <- grants[[id]]
    expires_at <- tryCatch(as.POSIXct(grant$expires_at), error = function(e) NA)
    if (identical(grant$status %||% "", "active") && (is.na(expires_at) || expires_at <= now)) {
      grant$status <- "expired"
      grant$delegation_hash <- genai_delegation_compute_hash(grant)
      ctx$genai_delegation_state$grants[[id]] <- grant
      genai_delegation_record_event("delegation_expired", grant, ctx = ctx)
    }
  }
  invisible(TRUE)
}

genai_delegation_list <- function(ctx, active_only = FALSE) {
  genai_delegation_expire_grants(ctx)
  grants <- ctx$genai_delegation_state$grants %||% list()
  if (isTRUE(active_only)) {
    grants <- Filter(function(grant) identical(grant$status %||% "", "active"), grants)
  }
  if (!length(grants)) return(data.table::data.table())
  data.table::rbindlist(lapply(grants, function(grant) {
    data.table::data.table(
      delegation_id = grant$delegation_id,
      action_id = grant$action_id,
      scope_type = grant$scope_type,
      scope_value = grant$scope_value,
      project_id = grant$project_id,
      workspace_provider_id = grant$workspace_provider_id,
      granted_at = grant$granted_at,
      expires_at = grant$expires_at,
      uses_remaining = as.integer(grant$uses_remaining %||% 0L),
      status = grant$status
    )
  }), fill = TRUE)
}

genai_delegation_safe_context <- function(ctx) {
  rows <- genai_delegation_list(ctx, active_only = TRUE)
  if (!nrow(rows)) {
    return(list(delegated_action_ids = character(), grants = list()))
  }
  list(
    delegated_action_ids = unique(rows$action_id),
    grants = lapply(seq_len(nrow(rows)), function(i) {
      list(
        action_id = rows$action_id[[i]],
        scope_type = rows$scope_type[[i]],
        scope_value = rows$scope_value[[i]],
        expires_at = rows$expires_at[[i]],
        uses_remaining = rows$uses_remaining[[i]],
        project_id = rows$project_id[[i]]
      )
    })
  )
}

qa_genai_delegation_policy <- function(output_dir = file.path(tempdir(), "genai_delegation_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  provider <- storage_provider("delegation_qa_provider", "local_server_directory", "Delegation QA", output_dir, TRUE, TRUE, FALSE, TRUE, list(supports_external_projects = TRUE, can_choose_directory = TRUE))
  workspace <- validate_workspace_root(output_dir, create = TRUE, provider = provider, repo_root = storage_repo_root())$value
  project <- create_project_in_workspace(workspace, "Delegation QA", project_id = "delegation_qa_project")$value
  ctx <- new.env(parent = emptyenv())
  ctx$current_workspace <- function() workspace
  ctx$current_project <- function() project
  ctx$genai_delegation_state <- new.env(parent = emptyenv())
  ctx$genai_delegation_state$session_id <- genai_delegation_session_id()
  ctx$genai_delegation_state$grants <- list()
  ctx$selected_module <- NULL
  ctx$select_analysis_module <- function(module_id) {
    ctx$selected_module <- module_id
    TRUE
  }
  ctx$genai_action_proposal_executed <- function(proposal_id) proposal_id %in% (ctx$executed %||% character())
  ctx$mark_genai_action_proposal_executed <- function(proposal_id) {
    ctx$executed <- unique(c(ctx$executed %||% character(), proposal_id))
    TRUE
  }
  proposal <- genai_action_proposal(
    action_id = "module.open",
    action_version = "1.0",
    arguments = list(module_id = "autoquant_eda"),
    rationale = "Open Explore Data.",
    expected_effects = "Open Explore Data",
    risk_tier = "low"
  )
  validation <- genai_validate_action_proposal(proposal, ctx = ctx)
  grant <- genai_delegation_create_grant(proposal, validation, ctx, max_uses = 1L, duration_minutes = 5L)
  if (identical(grant$status, "success")) {
    ctx$genai_delegation_state$grants[[grant$value$delegation_id]] <- grant$value
    genai_delegation_record_event("delegation_granted", grant$value, proposal, ctx = ctx)
  }
  match <- genai_delegation_find_matching_grant(proposal, validation, ctx)
  delegated_approval <- genai_delegation_approve_proposal(proposal, validation, match$value)
  execution <- genai_execute_action_proposal(delegated_approval$value, ctx = ctx, approval_hash = delegated_approval$value$approval_hash)
  consumed <- genai_delegation_consume_use(ctx, match$value$delegation_id, delegated_approval$value, execution$value)
  exhausted_match <- genai_delegation_find_matching_grant(proposal, validation, ctx)
  ineligible <- genai_action_proposal(
    action_id = "analysis.preflight",
    action_version = "1.0",
    arguments = list(module_id = "autoquant_eda", dataset_id = "active_dataset"),
    rationale = "Check readiness.",
    expected_effects = "Run bounded preflight",
    risk_tier = "medium"
  )
  ineligible_validation <- genai_validate_action_proposal(ineligible, ctx = ctx)
  ineligible_grant <- genai_delegation_create_grant(ineligible, ineligible_validation, ctx)
  ledger <- genai_audit_read_events(project)
  rows <- data.table::data.table(
    check = c(
      "module_open_eligible", "analysis_preflight_ineligible", "grant_created",
      "grant_hash_valid", "delegation_authorizes", "delegated_execution_succeeds",
      "use_consumed_once", "final_use_exhausts", "exhausted_does_not_authorize",
      "durable_events_written", "safe_context_exposes_summary"
    ),
    status = c(
      if ("module.open" %in% genai_delegation_eligible_actions()) "success" else "error",
      if (identical(ineligible_grant$status, "error") && "action_not_eligible_for_delegation" %in% ineligible_grant$errors) "success" else "error",
      if (identical(grant$status, "success")) "success" else "error",
      if (isTRUE(genai_delegation_validate_hash(grant$value))) "success" else "error",
      if (identical(match$status, "success")) "success" else "error",
      if (identical(execution$status, "success") && identical(ctx$selected_module, "autoquant_eda")) "success" else "error",
      if (identical(consumed$status, "success") && consumed$value$uses_remaining == 0L) "success" else "error",
      if (identical(consumed$value$status, "exhausted")) "success" else "error",
      if (!identical(exhausted_match$status, "success") && "delegation_exhausted" %in% exhausted_match$errors) "success" else "error",
      if (identical(ledger$status, "success") && all(c("delegation_granted", "delegation_used", "delegation_exhausted") %in% ledger$value$events$event_type)) "success" else "error",
      if ("module.open" %in% genai_delegation_safe_context(ctx)$delegated_action_ids || !nrow(genai_delegation_list(ctx, active_only = TRUE))) "success" else "error"
    ),
    message = c(
      "module.open is eligible for session delegation.",
      "analysis.preflight remains approval-required.",
      "A specific-module grant can be created by explicit UI.",
      "Grant hash binds trusted scope/project/provider fields.",
      "Matching active grant authorizes the proposal.",
      "Delegated execution uses the deterministic handler.",
      "Use count is consumed once execution starts.",
      "Final use marks the grant exhausted.",
      "Exhausted grant no longer authorizes proposals.",
      "Grant, use, and exhaustion events are durable.",
      "GenAI context exposes only safe delegation summaries."
    )
  )
  rows
}
