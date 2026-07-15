server <- function(input, output, session) {
  ctx <- new.env(parent = environment())
  initial_workspace_result <- load_workspace_state()
  initial_workspace <- if (identical(initial_workspace_result$status, "success")) {
    initial_workspace_result$value
  } else {
    initial_workspace_result$value %||% list(workspace_state = "workspace_unconfigured")
  }

  ctx$mapping_state <- reactiveValues(values = list())
  ctx$saved_plots <- reactiveValues(
    plots = list(),
    configs = list(),
    code = list(),
    metadata = list(),
    status = list()
  )
  ctx$saved_module_artifacts <- reactiveValues(artifacts = list())
  ctx$saved_sections <- reactiveValues(sections = list())
  ctx$saved_text_artifacts <- reactiveValues(artifacts = list())
  ctx$saved_table_artifacts <- reactiveValues(artifacts = list())
  ctx$report_plan_state <- reactiveValues(
    plans = list(),
    active_plan_id = NULL
  )
  ctx$code_runner_state <- reactiveValues(
    policy = create_code_execution_policy(),
    requests = list(),
    results = list(),
    records = list(),
    selected_run_id = NULL
  )
  ctx$project_collector_state <- reactiveValues(
    collector = NULL,
    run_index = 0L,
    last_result = NULL,
    last_run_id = NULL,
    restored_summary = NULL,
    message = NULL
  )
  ctx$genai_action_state <- reactiveValues(
    proposal = NULL,
    validation = NULL,
    approved_proposal = NULL,
    execution_result = NULL,
    executed_proposal_ids = character(),
    audit_log = data.table::data.table()
  )
  ctx$feature_experiment_state <- reactiveValues(
    proposals = list(),
    executions = list(),
    experiments = list(),
    adoptions = list()
  )
  ctx$analytical_campaign_state <- reactiveValues(
    campaigns = list()
  )
  ctx$decision_memory_state <- reactiveValues(
    decisions = list(),
    reviews = list(),
    artifacts = list(),
    last_result = NULL,
    message = NULL
  )
  ctx$semantic_workspace <- reactiveVal(semantic_workspace_empty())
  ctx$semantic_decision_state <- reactiveVal(semantic_decision_empty())
  ctx$decision_valuation_state <- reactiveVal(decision_valuation_empty())
  ctx$decision_workflow_state <- reactiveVal(decision_workflow_empty())
  ctx$causal_intelligence_state <- reactiveVal(causal_intelligence_empty())
  ctx$causal_experiment_state <- reactiveVal(causal_experiment_empty())
  ctx$causal_completed_experiment_state <- reactiveVal(causal_completed_experiment_empty())
  ctx$causal_itt_state <- reactiveVal(causal_itt_empty())
  ctx$causal_observational_state <- reactiveVal(causal_observational_empty())
  ctx$ai_draft_state <- reactiveValues(
    store = ai_draft_store_empty(),
    last_result = NULL,
    message = NULL
  )
  ctx$ai_mutation_state <- reactiveValues(
    store = mutation_store_empty(),
    artifact_relationship_drafts = list(),
    last_result = NULL,
    message = NULL
  )
  ctx$genai_delegation_state <- reactiveValues(
    session_id = genai_delegation_session_id(),
    grants = list(),
    selected_delegation_id = NULL
  )
  ctx$genai_preflight_state <- reactiveValues(
    results = list(),
    cancel_requested = FALSE,
    running = FALSE
  )
  ctx$genai_analysis_run_state <- reactiveValues(
    jobs = list(),
    results = list(),
    cancel_requested = FALSE,
    running = FALSE,
    selected_result_id = NULL
  )
  ctx$genai_persistence_locks <- list()
  ctx$workspace_runtime <- reactiveVal(initial_workspace)
  ctx$workspace_status_result <- reactiveVal(initial_workspace_result)
  ctx$active_project <- reactiveVal(NULL)
  ctx$project_lifecycle_state <- reactiveVal("no_project")

  ctx$plot_result <- reactiveVal(NULL)
  ctx$plot_error <- reactiveVal(NULL)
  ctx$plot_config <- reactiveVal(NULL)
  ctx$plot_list_message <- reactiveVal("")
  ctx$text_artifact_message <- reactiveVal("")
  ctx$text_artifact_preview <- reactiveVal(NULL)
  ctx$table_artifact_message <- reactiveVal("")
  ctx$table_artifact_preview <- reactiveVal(NULL)
  ctx$artifact_library_message <- reactiveVal("")
  ctx$export_message <- reactiveVal("")
  ctx$project_message <- reactiveVal("")
  ctx$code_runner_message <- reactiveVal("")
  ctx$project_data <- reactiveVal(NULL)
  ctx$project_data_info <- reactiveVal(list(path = NULL, name = NULL))
  ctx$source_project_data <- reactiveVal(NULL)
  ctx$source_project_data_info <- reactiveVal(list(path = NULL, name = NULL, source = "source_dataset"))
  ctx$active_modeling_context <- reactiveVal(modeling_context_from_source())
  ctx$artifact_studio_selected_artifact_id <- reactiveVal(NULL)
  ctx$selected_report_plan_id <- reactiveVal(NULL)
  ctx$selected_persisted_result_id <- reactiveVal(NULL)
  ctx$genai_config <- reactiveVal(genai_default_config(auto_detect_local = TRUE))
  ctx$genai_last_result <- reactiveVal(NULL)
  ctx$genai_action_policy <- reactiveVal(genai_action_policy("approval_required"))
  ctx$evidence_strategy <- reactiveVal("balanced")
  ctx$evidence_strategy_config <- reactiveVal(evidence_strategy_config("balanced"))
  ctx$workspace_state <- function() {
    workspace <- ctx$workspace_runtime()
    workspace$workspace_state %||% if (identical(ctx$workspace_status_result()$status, "success")) "workspace_ready" else "workspace_unconfigured"
  }
  ctx$workspace_ready <- function() {
    identical(ctx$workspace_status_result()$status, "success")
  }
  ctx$project_state_status <- function() {
    ctx$project_lifecycle_state()
  }
  ctx$project_ready <- function() {
    project <- ctx$active_project()
    identical(ctx$project_lifecycle_state(), "project_ready") &&
      is.list(project) &&
      identical(project$project_state %||% "", "project_ready")
  }
  ctx$decision_memory_summary <- function() {
    decisions <- ctx$decision_memory_state$decisions %||% list()
    reviews <- ctx$decision_memory_state$reviews %||% list()
    artifacts <- ctx$decision_memory_state$artifacts %||% list()
    review_statuses <- vapply(reviews, function(review) {
      if (is.data.frame(review) && "review_status" %in% names(review) && nrow(review)) review$review_status[[1]] else NA_character_
    }, character(1))
    data.table::data.table(
      decision_contexts = length(decisions),
      reviews = length(reviews),
      memory_artifacts = length(artifacts),
      validated_reviews = sum(review_statuses == "validated", na.rm = TRUE),
      negative_reviews = sum(review_statuses %in% c("negative_evidence", "assumption_failed"), na.rm = TRUE),
      awaiting_review = max(length(decisions) - length(reviews), 0L),
      last_status = ctx$decision_memory_state$message %||% "not_started"
    )
  }
  ctx$current_workspace <- function() ctx$workspace_runtime()
  ctx$current_project <- function() ctx$active_project()
  ctx$configure_workspace <- function(path, provider_id = "configured_workspace") {
    result <- configure_workspace_root(path, provider_id = provider_id)
    ctx$workspace_status_result(result)
    if (identical(result$status, "success")) {
      ctx$workspace_runtime(result$value)
      genai_delegation_revoke_all(ctx, source = "provider_change")
    } else {
      ctx$workspace_runtime(result$value %||% list(workspace_state = "workspace_invalid"))
    }
    result
  }
  ctx$create_project <- function(project_name = "Analytics Project") {
    if (!ctx$workspace_ready()) {
      return(storage_error_result(
        "workspace_unconfigured",
        "Choose a workspace directory before creating a project.",
        workspace_state = ctx$workspace_state(),
        project_state = ctx$project_state_status(),
        requested_resource_type = "project"
      ))
    }
    result <- create_project_in_workspace(ctx$current_workspace(), project_name)
    if (identical(result$status, "success")) {
      ctx$active_project(result$value)
      ctx$project_lifecycle_state("project_ready")
      ctx$project_collector_state$collector <- NULL
      ctx$project_collector_state$restored_summary <- NULL
      ctx$selected_persisted_result_id(NULL)
      genai_delegation_revoke_all(ctx, source = "project_change")
      ctx$set_export_settings(
        export_dir = project_report_path(result$value, create_dir = TRUE),
        export_name = safe_path_component(project_name, "analytics_report")
      )
    }
    result
  }
  ctx$close_project <- function() {
    ctx$active_project(NULL)
    ctx$project_lifecycle_state("no_project")
    ctx$project_collector_state$collector <- NULL
    ctx$project_collector_state$restored_summary <- NULL
    ctx$project_collector_state$last_result <- NULL
    ctx$project_collector_state$last_run_id <- NULL
    ctx$selected_persisted_result_id(NULL)
    genai_delegation_revoke_all(ctx, source = "project_close")
    ctx$project_message("Project closed. Persistent writes are blocked until a project is opened or created.")
    TRUE
  }
  ctx$genai_status <- function(check_availability = FALSE) {
    config <- ctx$genai_config()
    status <- genai_provider_status(config, check_availability = check_availability)
    if (!isTRUE(check_availability) && genai_configured(config)) {
      last_result <- ctx$genai_last_result()
      last_metadata <- last_result$metadata %||% list()
      last_telemetry <- last_metadata$telemetry %||% list()
      last_provider <- last_telemetry$provider %||% last_metadata$provider
      last_model <- last_telemetry$model %||% last_metadata$model
      last_success <- identical(last_result$status %||% "", "success") &&
        identical(last_provider %||% config$provider, config$provider) &&
        identical(last_model %||% config$model, config$model)
      auto_detected <- identical(config$config_source %||% "", "auto_detect_ollama")
      if (isTRUE(last_success) || isTRUE(auto_detected)) {
        status$status <- "success"
        status$value$available <- TRUE
        status$value$configured <- TRUE
        status$metadata$diagnostic_reason <- if (isTRUE(last_success)) "available_last_success" else "available_auto_detected"
        status$warnings <- character()
        status$errors <- character()
      }
    }
    status
  }
  ctx$set_genai_action_proposal <- function(proposal) {
    validation <- genai_validate_action_proposal(proposal, policy = ctx$genai_action_policy(), ctx = ctx)
    if (exists("genai_record_durable_audit", mode = "function")) {
      genai_record_durable_audit("proposal_created", proposal, validation = validation, ctx = ctx)
      if (identical(validation$status, "success")) {
        genai_record_durable_audit("proposal_validated", proposal, validation = validation, ctx = ctx)
      } else {
        genai_record_durable_audit("proposal_rejected", proposal, validation = validation, ctx = ctx)
      }
    }
    ctx$genai_action_state$proposal <- proposal
    ctx$genai_action_state$validation <- validation
    ctx$genai_action_state$approved_proposal <- NULL
    ctx$genai_action_state$execution_result <- NULL
    validation
  }
  ctx$genai_action_proposal_executed <- function(proposal_id) {
    proposal_id %in% (ctx$genai_action_state$executed_proposal_ids %||% character())
  }
  ctx$mark_genai_action_proposal_executed <- function(proposal_id) {
    ctx$genai_action_state$executed_proposal_ids <- unique(c(ctx$genai_action_state$executed_proposal_ids %||% character(), proposal_id))
    TRUE
  }
  ctx$genai_delegations <- function(active_only = FALSE) {
    genai_delegation_list(ctx, active_only = active_only)
  }
  ctx$revoke_genai_delegation <- function(delegation_id) {
    genai_delegation_revoke(ctx, delegation_id, source = "active_user")
  }
  ctx$revoke_all_genai_delegations <- function() {
    genai_delegation_revoke_all(ctx, source = "active_user")
  }

  ctx$uploaded_data <- reactive({
    data <- ctx$project_data()
    if (!is.null(data)) {
      return(data)
    }
    req(FALSE)
  })
  ctx$current_data_path <- function() ctx$project_data_info()$path
  ctx$current_data_name <- function() ctx$project_data_info()$name
  ctx$has_upload_or_project_data <- function() !is.null(ctx$project_data())
  ctx$current_dataset_id <- function() ctx$active_modeling_context()$active_dataset_id %||% "active_dataset"
  ctx$current_modeling_context <- function() ctx$active_modeling_context()
  ctx$persist_project_data_if_needed <- function() {
    if (!ctx$project_ready()) {
      return(invisible(NULL))
    }
    data <- tryCatch(ctx$project_data(), error = function(e) NULL)
    source_path <- tryCatch(ctx$current_data_path(), error = function(e) NULL)
    source_name <- tryCatch(ctx$current_data_name(), error = function(e) NULL) %||% "data.csv"
    if (is.null(data) && (is.null(source_path) || !file.exists(source_path))) {
      return(invisible(NULL))
    }
    source_available <- !is.null(source_path) && file.exists(source_path)
    ext <- tolower(tools::file_ext(source_name))
    ext <- if (nzchar(ext) && isTRUE(source_available)) ext else "csv"
    data_name <- paste0("data.", ext)
    target <- project_path(ctx$current_project(), "data", data_name)
    gate <- persistent_write_gate(ctx$current_workspace(), ctx$current_project(), target, "project_data")
    if (!identical(gate$status, "success")) {
      stop(paste(gate$errors, collapse = " "), call. = FALSE)
    }
    if (isTRUE(source_available)) {
      file.copy(source_path, target, overwrite = TRUE)
    } else {
      data.table::fwrite(data, target)
    }
    previous_info <- ctx$project_data_info() %||% list()
    ctx$project_data_info(c(
      previous_info,
      list(path = storage_normalize_path(target, must_work = TRUE), name = data_name)
    ))
    invisible(target)
  }
  ctx$store_genai_preflight_result <- function(result) {
    result_id <- result$preflight_result_id %||% paste0("preflight_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
    result$preflight_result_id <- result_id
    ctx$genai_preflight_state$results[[result_id]] <- result
    result_id
  }
  ctx$request_genai_preflight_cancel <- function() {
    ctx$genai_preflight_state$cancel_requested <- TRUE
    TRUE
  }
  ctx$reset_genai_preflight_cancel <- function() {
    ctx$genai_preflight_state$cancel_requested <- FALSE
    TRUE
  }
  ctx$genai_preflight_cancel_requested <- function() {
    isTRUE(ctx$genai_preflight_state$cancel_requested)
  }
  ctx$store_genai_analysis_job <- function(job) {
    job_id <- job$job_id %||% paste0("job_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
    job$job_id <- job_id
    ctx$genai_analysis_run_state$jobs[[job_id]] <- job
    job_id
  }
  ctx$update_genai_analysis_job <- function(job_id, fields = list()) {
    job <- ctx$genai_analysis_run_state$jobs[[job_id]] %||% list(job_id = job_id)
    for (field in names(fields)) {
      job[[field]] <- fields[[field]]
    }
    ctx$genai_analysis_run_state$jobs[[job_id]] <- job
    job
  }
  ctx$store_genai_analysis_result <- function(result) {
    result_id <- result$temporary_result_id %||% paste0("tmp_result_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
    result$temporary_result_id <- result_id
    ctx$genai_analysis_run_state$results[[result_id]] <- result
    ctx$genai_analysis_run_state$selected_result_id <- result_id
    result_id
  }
  ctx$mark_genai_analysis_result_persisted <- function(temporary_result_id, persisted_result_id, persisted_project_id) {
    result <- ctx$genai_analysis_run_state$results[[temporary_result_id]]
    if (is.null(result)) {
      return(FALSE)
    }
    result$persisted <- TRUE
    result$persisted_result_id <- persisted_result_id
    result$persisted_at <- Sys.time()
    result$persisted_project_id <- persisted_project_id
    ctx$genai_analysis_run_state$results[[temporary_result_id]] <- result
    TRUE
  }
  ctx$request_genai_analysis_cancel <- function() {
    ctx$genai_analysis_run_state$cancel_requested <- TRUE
    TRUE
  }
  ctx$reset_genai_analysis_cancel <- function() {
    ctx$genai_analysis_run_state$cancel_requested <- FALSE
    TRUE
  }
  ctx$genai_analysis_cancel_requested <- function() {
    isTRUE(ctx$genai_analysis_run_state$cancel_requested)
  }
  ctx$navigate_to <- function(page) {
    updateTabsetPanel(session, "main_tabs", selected = page)
  }
  ctx$inspect_artifact <- function(artifact_id) {
    ctx$artifact_studio_selected_artifact_id(artifact_id)
    ctx$navigate_to("Artifact Studio")
    invisible(TRUE)
  }
  ctx$open_report <- function(report_id) {
    ctx$selected_report_plan_id(report_id)
    ctx$navigate_to("Layout")
    invisible(TRUE)
  }
  ctx$inspect_persisted_result <- function(persisted_result_id) {
    resolution <- genai_resolve_persisted_result(persisted_result_id, ctx = ctx)
    if (!identical(resolution$status, "success")) {
      return(resolution)
    }
    ctx$selected_persisted_result_id(resolution$value$persisted_result_id)
    ctx$navigate_to("Project")
    service_result(
      status = "success",
      value = resolution$value,
      messages = paste("Selected persisted result:", resolution$value$display_name)
    )
  }
  ctx$code_tracker_summary <- function() {
    code_tracker_summary(ctx$code_runner_state$records)
  }
  ctx$next_code_run_id <- function() {
    existing <- names(ctx$code_runner_state$requests)
    index <- length(existing) + 1L
    repeat {
      run_id <- paste0("code_run_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", index)
      if (!run_id %in% existing) {
        return(run_id)
      }
      index <- index + 1L
    }
  }
  ctx$add_code_run_request <- function(request) {
    validation <- validate_code_run_request(request, ctx$code_runner_state$policy)
    if (!identical(validation$status, "success")) {
      return(validation)
    }
    ctx$code_runner_state$requests[[request$run_id]] <- request
    ctx$code_runner_state$selected_run_id <- request$run_id
    service_result(
      status = "success",
      value = request,
      messages = paste("Added code run request:", request$label),
      metadata = list(run_id = request$run_id)
    )
  }
  ctx$select_code_run <- function(run_id) {
    ctx$code_runner_state$selected_run_id <- run_id
    updateTabsetPanel(session, "main_tabs", selected = "Code Runner")
  }
  ctx$select_analysis_module <- function(module_id) {
    updateTabsetPanel(session, "main_tabs", selected = "Analysis Modules")
    updateSelectInput(session, "analysis_modules-analysis_module_id", selected = module_id)
  }
  ctx$add_custom_code_hook_request <- function(stage, timing = "standalone", label = NULL, code = "",
                                               requested_outputs = custom_code_hook_output_types(),
                                               context = list()) {
    request <- create_custom_code_hook_request(
      run_id = ctx$next_code_run_id(),
      stage = stage,
      timing = timing,
      label = label,
      code = code,
      requested_outputs = requested_outputs,
      data_name = ctx$current_data_name(),
      context = context,
      status = "draft",
      execution_mode = ctx$code_runner_state$policy$execution_mode %||% "disabled"
    )
    validation <- validate_custom_code_hook_request(request, ctx$code_runner_state$policy)
    if (!identical(validation$status, "success")) {
      return(validation)
    }
    ctx$add_code_run_request(request)
  }
  ctx$add_code_tracker_record <- function(record) {
    ctx$code_runner_state$records[[record$run_id]] <- record
    ctx$code_runner_state$selected_run_id <- record$run_id
    service_result(
      status = "success",
      value = record,
      messages = paste("Added code tracker record:", record$label),
      metadata = list(run_id = record$run_id)
    )
  }
  ctx$layout_cols_value <- function() 2L
  ctx$get_layout_type <- function() "Grid"
  ctx$set_layout_settings <- function(layout_type = NULL, layout_cols = NULL) invisible(NULL)
  ctx$get_export_dir <- function() {
    project <- ctx$active_project()
    if (ctx$project_ready()) {
      return(project_report_path(project, create_dir = TRUE))
    }
    NULL
  }
  ctx$get_export_name <- function() "autoplots_report"
  ctx$export_name_value <- function() "autoplots_report"
  ctx$set_export_settings <- function(export_dir = NULL, export_name = NULL) invisible(NULL)

  ctx$project_collector_output_dir <- function() {
    if (!ctx$project_ready()) {
      stop("No project is open. Current analytical results are temporary and cannot be saved until a project is created or opened.", call. = FALSE)
    }
    project_path(ctx$active_project(), "collector", create_dir = TRUE)
  }
  ctx$project_collector_project_id <- function() {
    project <- ctx$active_project()
    if (is.list(project) && nzchar(project$project_id %||% "")) {
      return(project$project_id)
    }
    raw <- ctx$current_data_name() %||% "analytics_project"
    .project_collector_slug(tools::file_path_sans_ext(basename(raw)))
  }
  ctx$ensure_project_collector <- function() {
    if (!ctx$project_ready()) {
      stop("No project is open. Current analytical results are temporary and cannot be saved until a project is created or opened.", call. = FALSE)
    }
    collector <- ctx$project_collector_state$collector
    if (inherits(collector, "project_artifact_collector")) {
      return(collector)
    }

    collector <- create_project_artifact_collector(
      project_id = ctx$project_collector_project_id(),
      project_name = ctx$current_data_name() %||% "Analytics Project",
      output_dir = ctx$project_collector_output_dir()
    )
    ctx$project_collector_state$collector <- collector
    ctx$project_collector_state$restored_summary <- NULL
    ctx$project_collector_state$message <- "Project Artifact Collector created."
    collector
  }
  ctx$next_project_run_id <- function() {
    current <- suppressWarnings(as.integer(ctx$project_collector_state$run_index %||% 0L))
    current <- if (is.na(current)) 0L else current
    current <- current + 1L
    ctx$project_collector_state$run_index <- current
    sprintf("run_%03d", current)
  }
  ctx$project_collector_implemented_modules <- function() {
    stages <- workflow_stage_registry()
    unique(unlist(lapply(stages, function(stage) {
      if (!stage$status %in% c("implemented", "experimental")) {
        return(character())
      }
      workflow_stage_module_ids(stage)
    }), use.names = FALSE))
  }
  ctx$append_module_result_to_collector <- function(result, module_id, run_id = NULL, record_skipped = TRUE) {
    collector <- tryCatch(ctx$ensure_project_collector(), error = function(e) e)
    if (inherits(collector, "error")) {
      blocked <- storage_error_result(
        "project_required",
        conditionMessage(collector),
        workspace_state = ctx$workspace_state(),
        project_state = ctx$project_state_status(),
        requested_resource_type = "collector"
      )
      ctx$project_collector_state$last_result <- blocked
      ctx$project_collector_state$message <- service_result_message(blocked)
      return(blocked)
    }
    module_id <- normalize_module_id(module_id)
    module <- get_module_definition(module_id)
    run_id <- run_id %||% ctx$next_project_run_id()

    append_result <- project_collector_append_result(
      collector = collector,
      result = result,
      project_id = collector$project_id,
      project_name = collector$project_name,
      run_id = run_id,
      module_id = module_id,
      module_label = module$label %||% module_id,
      write = FALSE
    )
    if (!is.null(append_result$value)) {
      collector <- append_result$value
    }

    if (isTRUE(record_skipped)) {
      skipped_modules <- setdiff(ctx$project_collector_implemented_modules(), module_id)
      for (skipped_module_id in skipped_modules) {
        skipped_module <- get_module_definition(skipped_module_id)
        skipped_bundle <- project_artifact_bundle(
          project_id = collector$project_id,
          project_name = collector$project_name,
          run_id = run_id,
          module_id = skipped_module_id,
          module_label = skipped_module$label %||% skipped_module_id,
          artifacts = list(),
          status = "not_requested",
          warnings = paste("Module was not requested for", run_id)
        )
        skipped_result <- project_collector_append_bundle(collector, skipped_bundle, write = FALSE)
        if (!is.null(skipped_result$value)) {
          collector <- skipped_result$value
        }
      }
    }

    write_result <- project_collector_write(collector)
    ctx$project_collector_state$collector <- collector
    ctx$project_collector_state$last_result <- write_result
    ctx$project_collector_state$last_run_id <- run_id
    ctx$project_collector_state$message <- if (identical(write_result$status, "success")) {
      paste("Project Artifact Collector updated for", run_id)
    } else {
      paste("Project Artifact Collector update failed:", paste(write_result$errors %||% character(), collapse = " | "))
    }
    write_result
  }
  ctx$project_collector_summary <- function() {
    collector <- ctx$project_collector_state$collector
    result <- ctx$project_collector_state$last_result
    restored_summary <- ctx$project_collector_state$restored_summary
    if (!inherits(collector, "project_artifact_collector") &&
        data.table::is.data.table(restored_summary) &&
        nrow(restored_summary)) {
      return(restored_summary)
    }
    manifest_file <- if (inherits(collector, "project_artifact_collector")) collector$manifest_file else NA_character_
    docx_file <- if (inherits(collector, "project_artifact_collector")) collector$collector_docx else NA_character_
    normalize_collector_path <- function(path) {
      if (is.null(path) || is.na(path) || !nzchar(path)) {
        return(NA_character_)
      }
      normalizePath(path, winslash = "/", mustWork = FALSE)
    }
    artifact_count <- if (inherits(collector, "project_artifact_collector")) {
      sum(vapply(collector$bundles, function(bundle) length(bundle$artifacts %||% list()), integer(1)))
    } else {
      0L
    }
    data.table::data.table(
      collector_status = result$status %||% if (inherits(collector, "project_artifact_collector")) "created" else "not_created",
      current_run_id = ctx$project_collector_state$last_run_id %||% NA_character_,
      artifact_count = artifact_count,
      bundle_count = if (inherits(collector, "project_artifact_collector")) length(collector$bundles) else 0L,
      render_target = if (inherits(collector, "project_artifact_collector")) collector$render_target %||% NA_character_ else NA_character_,
      collector_docx = normalize_collector_path(docx_file),
      manifest_status = if (!is.na(manifest_file) && file.exists(manifest_file)) "ready" else "not_written",
      manifest_file = normalize_collector_path(manifest_file)
    )
  }
  ctx$get_current_plot_type <- function() NULL
  ctx$current_plot_options <- function() list()
  ctx$load_config_into_builder <- function(config) invisible(NULL)

  ctx$ordered_plot_names <- function() {
    ordered_plot_names_from_metadata(ctx$saved_plots$metadata)
  }

  ctx$ready_plot_names <- function() {
    plot_names <- ctx$ordered_plot_names()
    plot_names[vapply(plot_names, function(plot_name) {
      identical(ctx$saved_plots$status[[plot_name]]$status, "Ready")
    }, logical(1))]
  }

  ctx$ordered_saved_plots <- function() {
    ordered_list_by_names(ctx$saved_plots$plots, ctx$ready_plot_names())
  }

  ctx$section_plot_names <- function(ready_only = FALSE) {
    metadata <- ctx$saved_plots$metadata
    if (isTRUE(ready_only)) {
      metadata <- ordered_list_by_names(metadata, ctx$ready_plot_names())
    }

    section_plot_names_from_metadata(metadata)
  }

  ctx$section_plot_objects <- function() {
    sections <- ctx$section_plot_names(ready_only = TRUE)
    lapply(sections, function(plot_names) {
      ordered_list_by_names(ctx$saved_plots$plots, plot_names)
    })
  }

  ctx$plot_artifacts <- function() {
    saved_plots_to_artifacts(
      saved_plots = ctx$saved_plots$plots,
      configs = ctx$saved_plots$configs,
      code = ctx$saved_plots$code,
      metadata = ctx$saved_plots$metadata
    )
  }

  ctx$text_artifacts <- function() {
    ctx$saved_text_artifacts$artifacts
  }

  ctx$table_artifacts <- function() {
    ctx$saved_table_artifacts$artifacts
  }

  ctx$module_artifacts <- function() {
    ctx$saved_module_artifacts$artifacts
  }

  ctx$all_artifacts <- function() {
    c(ctx$plot_artifacts(), ctx$module_artifacts(), ctx$text_artifacts(), ctx$table_artifacts())
  }

  ctx$activate_prepared_dataset_artifact <- function(artifact_id) {
    artifacts <- ctx$all_artifacts()
    artifact <- artifacts[[artifact_id]]
    if (is.null(artifact)) {
      return(service_result(
        status = "error",
        errors = sprintf("Prepared dataset artifact '%s' was not found.", artifact_id),
        metadata = list(
          error_code = "PREPARED_DATASET_ARTIFACT_NOT_FOUND",
          artifact_id = artifact_id
        )
      ))
    }

    current_data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
    current_info <- tryCatch(ctx$project_data_info(), error = function(e) list())
    current_context <- tryCatch(ctx$active_modeling_context(), error = function(e) NULL)
    if (!identical((current_context %||% list())$active_dataset_source, "prepared_artifact") &&
        !is.null(current_data)) {
      ctx$source_project_data(data.table::as.data.table(data.table::copy(current_data)))
      ctx$source_project_data_info(c(
        current_info,
        list(source = "source_dataset")
      ))
    }

    activation <- prepared_dataset_activation_result(
      artifact,
      current_dataset_name = tryCatch(ctx$current_data_name(), error = function(e) NULL)
    )
    if (!identical(activation$status, "success")) {
      return(activation)
    }

    ctx$project_data(activation$value$data)
    ctx$project_data_info(activation$value$data_info)
    ctx$active_modeling_context(modeling_context_from_prepared_activation(
      artifact = artifact,
      activation = activation,
      source_info = ctx$source_project_data_info(),
      project = ctx$current_project()
    ))
    ctx$project_message(service_result_message(activation))
    activation
  }

  ctx$revert_to_source_dataset <- function() {
    data <- ctx$source_project_data()
    info <- ctx$source_project_data_info()
    if (is.null(data)) {
      source_path <- info$path %||% NULL
      if (!is.null(source_path) && file.exists(source_path)) {
        data <- read_dataset_file(source_path, name = info$name %||% source_path)
      }
    }
    if (is.null(data)) {
      return(service_result(
        status = "error",
        errors = "The original source dataset is not available in this session. Reload the project source data to revert.",
        metadata = list(error_code = "SOURCE_DATASET_UNAVAILABLE")
      ))
    }
    ctx$project_data(data.table::as.data.table(data.table::copy(data)))
    ctx$project_data_info(c(info, list(source = "source_dataset")))
    ctx$active_modeling_context(modeling_context_from_source(
      data = data,
      data_info = info,
      project = ctx$current_project()
    ))
    result <- service_result(
      status = "success",
      messages = sprintf("Reverted active modeling dataset to '%s'.", info$name %||% "Source Dataset"),
      metadata = list(active_dataset_source = "source_dataset")
    )
    ctx$project_message(service_result_message(result))
    result
  }

  ctx$validate_active_modeling_context <- function() {
    validate_modeling_context(
      ctx$active_modeling_context(),
      artifacts = ctx$all_artifacts(),
      data = tryCatch(ctx$uploaded_data(), error = function(e) NULL),
      project_id = (ctx$current_project() %||% list())$project_id %||% NULL
    )
  }

  ctx$combined_artifact_summary <- function() {
    combined_artifact_summary(
      ctx$plot_artifacts(),
      ctx$text_artifacts(),
      ctx$table_artifacts(),
      ctx$module_artifacts()
    )
  }

  ctx$artifact_order_value <- function(value, fallback = NA_integer_) {
    order <- suppressWarnings(as.integer(value))
    if (is.na(order)) {
      return(fallback)
    }

    order
  }

  ctx$update_plot_artifact_metadata <- function(artifact_id, label, section, order, visible) {
    metadata <- ctx$saved_plots$metadata[[artifact_id]] %||% list()
    metadata$label <- label
    metadata$section_name <- section
    metadata$sort_order <- order
    metadata$visible <- visible
    ctx$saved_plots$metadata[[artifact_id]] <- metadata
  }

  ctx$update_artifact_metadata <- function(artifact_id, label, section, order, visible) {
    if (artifact_id %in% names(ctx$saved_plots$configs)) {
      ctx$update_plot_artifact_metadata(artifact_id, label, section, order, visible)
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_text_artifacts$artifacts)) {
      artifact <- ctx$saved_text_artifacts$artifacts[[artifact_id]]
      artifact$label <- label
      artifact$section <- section
      artifact$order <- order
      artifact$visible <- visible
      artifact$updated_at <- Sys.time()
      ctx$saved_text_artifacts$artifacts[[artifact_id]] <- artifact
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_table_artifacts$artifacts)) {
      artifact <- ctx$saved_table_artifacts$artifacts[[artifact_id]]
      artifact$label <- label
      artifact$section <- section
      artifact$order <- order
      artifact$visible <- visible
      artifact$updated_at <- Sys.time()
      ctx$saved_table_artifacts$artifacts[[artifact_id]] <- artifact
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_module_artifacts$artifacts)) {
      artifact <- ctx$saved_module_artifacts$artifacts[[artifact_id]]
      artifact$label <- label
      artifact$section <- section
      artifact$order <- order
      artifact$visible <- visible
      artifact$updated_at <- Sys.time()
      ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifact
      return(TRUE)
    }

    FALSE
  }

  ctx$remove_artifact_by_id <- function(artifact_id) {
    if (artifact_id %in% names(ctx$saved_plots$plots)) {
      ctx$saved_plots$plots[[artifact_id]] <- NULL
      ctx$saved_plots$configs[[artifact_id]] <- NULL
      ctx$saved_plots$code[[artifact_id]] <- NULL
      ctx$saved_plots$metadata[[artifact_id]] <- NULL
      ctx$saved_plots$status[[artifact_id]] <- NULL
      sections <- ctx$saved_sections$sections
      for (section_name in names(sections)) {
        sections[[section_name]][[artifact_id]] <- NULL
        if (!length(sections[[section_name]])) {
          sections[[section_name]] <- NULL
        }
      }
      ctx$saved_sections$sections <- sections
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_text_artifacts$artifacts)) {
      ctx$saved_text_artifacts$artifacts[[artifact_id]] <- NULL
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_table_artifacts$artifacts)) {
      ctx$saved_table_artifacts$artifacts[[artifact_id]] <- NULL
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_module_artifacts$artifacts)) {
      ctx$saved_module_artifacts$artifacts[[artifact_id]] <- NULL
      return(TRUE)
    }

    FALSE
  }

  ctx$add_artifacts <- function(artifacts) {
    if (is.null(artifacts) || !length(artifacts)) {
      return(invisible(0L))
    }

    added <- 0L
    for (artifact_id in names(artifacts)) {
      artifact <- artifacts[[artifact_id]]
      if (!inherits(artifact, "aq_artifact")) {
        next
      }

      if (identical(artifact$artifact_type, "plot") &&
          identical(artifact$source_module, "plot_builder")) {
        ctx$saved_plots$plots[[artifact$artifact_id]] <- artifact$object
        ctx$saved_plots$configs[[artifact$artifact_id]] <- list(
          plot_type = artifact$metadata$module_id %||% artifact$source_module %||% "module_plot",
          mappings = list(),
          options = list()
        )
        ctx$saved_plots$code[[artifact$artifact_id]] <- artifact$code
        ctx$saved_plots$metadata[[artifact$artifact_id]] <- list(
          label = artifact$label,
          section_name = artifact$section,
          sort_order = artifact$order,
          visible = artifact$visible,
          source_module = artifact$source_module,
          module_config = artifact$config
        )
        ctx$saved_plots$status[[artifact$artifact_id]] <- list(status = "Ready", message = "")
        added <- added + 1L
      } else if (identical(artifact$artifact_type, "plot")) {
        ctx$saved_module_artifacts$artifacts[[artifact$artifact_id]] <- artifact
        added <- added + 1L
      } else if (artifact$artifact_type %in% c("text", "genai_narrative", "narrative", "diagnostic", "recommendation", "json")) {
        ctx$saved_text_artifacts$artifacts[[artifact$artifact_id]] <- artifact
        added <- added + 1L
      } else if (identical(artifact$artifact_type, "table")) {
        ctx$saved_table_artifacts$artifacts[[artifact$artifact_id]] <- artifact
        added <- added + 1L
      } else if (identical(artifact$artifact_type, "metric")) {
        ctx$saved_module_artifacts$artifacts[[artifact$artifact_id]] <- artifact
        added <- added + 1L
      }
    }

    invisible(added)
  }

  ctx$apply_artifact_layout <- function(artifact_ids, sections) {
    planned_ids <- unique(artifact_ids)
    section_lookup <- list()
    order_lookup <- list()
    order_index <- 1L
    for (section in sections) {
      for (artifact_id in section$artifact_ids %||% character()) {
        section_lookup[[artifact_id]] <- section$title
        order_lookup[[artifact_id]] <- order_index
        order_index <- order_index + 1L
      }
    }

    for (artifact_id in names(ctx$saved_plots$metadata)) {
      metadata <- ctx$saved_plots$metadata[[artifact_id]] %||% list()
      metadata$visible <- artifact_id %in% planned_ids
      if (isTRUE(metadata$visible)) {
        metadata$section_name <- section_lookup[[artifact_id]] %||% "Analysis"
        metadata$sort_order <- order_lookup[[artifact_id]] %||% metadata$sort_order %||% NA_integer_
      }
      ctx$saved_plots$metadata[[artifact_id]] <- metadata
    }

    for (artifact_id in names(ctx$saved_text_artifacts$artifacts)) {
      artifact <- ctx$saved_text_artifacts$artifacts[[artifact_id]]
      artifact$visible <- artifact_id %in% planned_ids
      if (isTRUE(artifact$visible)) {
        artifact$section <- section_lookup[[artifact_id]] %||% "Analysis"
        artifact$order <- order_lookup[[artifact_id]] %||% artifact$order %||% NA_integer_
      }
      artifact$updated_at <- Sys.time()
      ctx$saved_text_artifacts$artifacts[[artifact_id]] <- artifact
    }

    for (artifact_id in names(ctx$saved_table_artifacts$artifacts)) {
      artifact <- ctx$saved_table_artifacts$artifacts[[artifact_id]]
      artifact$visible <- artifact_id %in% planned_ids
      if (isTRUE(artifact$visible)) {
        artifact$section <- section_lookup[[artifact_id]] %||% "Analysis"
        artifact$order <- order_lookup[[artifact_id]] %||% artifact$order %||% NA_integer_
      }
      artifact$updated_at <- Sys.time()
      ctx$saved_table_artifacts$artifacts[[artifact_id]] <- artifact
    }

    for (artifact_id in names(ctx$saved_module_artifacts$artifacts)) {
      artifact <- ctx$saved_module_artifacts$artifacts[[artifact_id]]
      artifact$visible <- artifact_id %in% planned_ids
      if (isTRUE(artifact$visible)) {
        artifact$section <- section_lookup[[artifact_id]] %||% "Analysis"
        artifact$order <- order_lookup[[artifact_id]] %||% artifact$order %||% NA_integer_
      }
      artifact$updated_at <- Sys.time()
      ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifact
    }

    invisible(TRUE)
  }

  ctx$report_plan_summary <- function() {
    report_plan_summary(ctx$report_plan_state$plans)
  }

  ctx$add_report_plan <- function(plan) {
    validation <- validate_report_plan(plan, ctx$all_artifacts())
    if (identical(validation$status, "error")) {
      return(validation)
    }
    plan <- validation$value

    ctx$report_plan_state$plans[[plan$plan_id]] <- plan
    service_result(
      status = "success",
      value = plan,
      messages = paste("Added report plan:", plan$label),
      warnings = validation$warnings,
      metadata = list(plan_id = plan$plan_id)
    )
  }

  ctx$add_report_plans <- function(plans) {
    if (is.null(plans) || !length(plans)) {
      return(invisible(0L))
    }

    added <- 0L
    for (plan in plans) {
      result <- ctx$add_report_plan(plan)
      if (!identical(result$status, "error")) {
        added <- added + 1L
      }
    }

    invisible(added)
  }

  ctx$apply_report_plan <- function(plan_id) {
    plan <- ctx$report_plan_state$plans[[plan_id]]
    if (is.null(plan)) {
      return(service_result(
        status = "error",
        errors = paste("Report plan was not found:", plan_id),
        metadata = list(error_code = "REPORT_PLAN_NOT_FOUND")
      ))
    }

    result <- apply_report_plan_to_layout_state(
      plan = plan,
      artifact_state = list(
        all_artifacts = ctx$all_artifacts,
        apply_artifact_layout = ctx$apply_artifact_layout
      ),
      layout_state = list(
        set_layout_settings = ctx$set_layout_settings
      )
    )
    if (!identical(result$status, "error")) {
      applied_plan <- result$value
      applied_plan$status <- "applied"
      applied_plan$updated_at <- Sys.time()
      ctx$report_plan_state$plans[[plan_id]] <- applied_plan
      ctx$report_plan_state$active_plan_id <- plan_id
    }

    result
  }

  ctx$all_report_artifacts <- function() {
    artifacts <- ctx$all_artifacts()
    artifacts <- artifacts[vapply(artifacts, function(artifact) {
      isTRUE(artifact$visible) && identical(artifact$status, "ready")
    }, logical(1))]

    if (!length(artifacts)) {
      return(list())
    }

    summary <- artifact_summary(artifacts)
    ordered_ids <- summary$artifact_id[order(summary$order, summary$artifact_id)]
    ordered_list_by_names(artifacts, ordered_ids)
  }

  ctx$mixed_report_preview <- function() {
    artifacts <- ctx$all_report_artifacts()
    if (!length(artifacts)) {
      return(ui_empty_state(
        "No visible artifacts selected for this layout.",
        "Use the Artifact Library to show artifacts in the report preview."
      ))
    }

    cols <- ctx$layout_cols_value()
    if (identical(ctx$get_layout_type(), "Sections")) {
      summary <- artifact_summary(artifacts)
      section_summary <- summary[
        ,
        list(
          first_order = min(order, na.rm = TRUE),
          artifact_count = .N
        ),
        by = section
      ]
      section_summary[is.infinite(first_order), first_order := NA_integer_]
      section_summary <- section_summary[order(first_order, section)]

      return(tags$div(
        class = "aq-report-sections",
        lapply(seq_len(nrow(section_summary)), function(index) {
          section_name <- section_summary$section[[index]]
          section_ids <- summary$artifact_id[summary$section == section_name]
          subtitle <- sprintf(
            "%s visible %s",
            section_summary$artifact_count[[index]],
            if (identical(section_summary$artifact_count[[index]], 1L)) "artifact" else "artifacts"
          )

          tags$section(
            class = "aq-report-section",
            ui_section_header(section_name, subtitle),
            tags$div(
              class = "aq-report-grid",
              style = paste0("grid-template-columns: repeat(", cols, ", minmax(0, 1fr));"),
              lapply(ordered_list_by_names(artifacts, section_ids), render_artifact, chrome = TRUE)
            )
          )
        })
      ))
    }

    tags$div(
      class = "aq-report-grid",
      style = paste0("grid-template-columns: repeat(", cols, ", minmax(0, 1fr));"),
      lapply(artifacts, render_artifact, chrome = TRUE)
    )
  }

  ctx$next_text_artifact_id <- function() {
    existing <- names(ctx$saved_text_artifacts$artifacts)
    index <- 1L
    repeat {
      artifact_id <- paste0("t", index)
      if (!artifact_id %in% existing) {
        return(artifact_id)
      }
      index <- index + 1L
    }
  }

  ctx$next_table_artifact_id <- function() {
    existing <- names(ctx$saved_table_artifacts$artifacts)
    index <- 1L
    repeat {
      artifact_id <- paste0("tbl", index)
      if (!artifact_id %in% existing) {
        return(artifact_id)
      }
      index <- index + 1L
    }
  }

  ctx$next_artifact_order <- function() {
    summary <- ctx$combined_artifact_summary()
    if (!nrow(summary) || all(is.na(summary$order))) {
      return(1L)
    }

    max(summary$order, na.rm = TRUE) + 1L
  }

  ctx$current_report_code <- function() {
    ready_names <- ctx$ready_plot_names()
    if (!length(ready_names)) {
      stop("No ready saved plots are available. Rebuild or repair saved plots before exporting R code.", call. = FALSE)
    }

    build_report_code(
      saved_code = ordered_list_by_names(ctx$saved_plots$code, ready_names),
      section_plot_names = ctx$section_plot_names(ready_only = TRUE),
      layout_type = ctx$get_layout_type(),
      cols = ctx$layout_cols_value(),
      export_dir = default_value(selected_value(ctx$get_export_dir()), "path/to/output"),
      export_name = default_value(ctx$export_name_value(), "autoplots_report"),
      data_path = default_value(ctx$current_data_path(), "path/to/data.csv")
    )
  }

  ctx$current_report <- reactive({
    if (!length(names(ctx$saved_plots$plots))) {
      return(NULL)
    }

    cols <- ctx$layout_cols_value()

    if (identical(ctx$get_layout_type(), "Sections")) {
      sections <- ctx$section_plot_objects()
      if (!length(names(sections))) {
        return(NULL)
      }

      return(AutoPlots::display_plots_sections(
        sections = sections,
        cols = cols
      ))
    }

    AutoPlots::display_plots_grid(
      plots = ctx$ordered_saved_plots(),
      cols = cols
    )
  })

  ctx$current_project_state <- function() {
    data_path <- ctx$current_data_path()
    project <- ctx$active_project()
    list(
      app_version = APP_VERSION,
      saved_at = Sys.time(),
      project_metadata = project,
      workspace_root = ctx$current_workspace()$workspace_root %||% NA_character_,
      data_path = data_path,
      data_name = ctx$current_data_name(),
      original_data_path = data_path,
      active_modeling_context = ctx$active_modeling_context(),
      feature_experiment_state = list(
        proposals = ctx$feature_experiment_state$proposals,
        executions = ctx$feature_experiment_state$executions,
        experiments = ctx$feature_experiment_state$experiments,
        adoptions = ctx$feature_experiment_state$adoptions
      ),
      analytical_campaign_state = list(
        campaigns = ctx$analytical_campaign_state$campaigns
      ),
      decision_memory_state = list(
        decisions = ctx$decision_memory_state$decisions,
        reviews = ctx$decision_memory_state$reviews,
        artifacts = ctx$decision_memory_state$artifacts,
        last_result = ctx$decision_memory_state$last_result,
        message = ctx$decision_memory_state$message
      ),
      semantic_workspace = ctx$semantic_workspace(),
      semantic_decision_state = ctx$semantic_decision_state(),
      decision_valuation_state = ctx$decision_valuation_state(),
      decision_workflow_state = ctx$decision_workflow_state(),
      causal_intelligence_state = ctx$causal_intelligence_state(),
      causal_experiment_state = ctx$causal_experiment_state(),
      causal_completed_experiment_state = ctx$causal_completed_experiment_state(),
      causal_itt_state = ctx$causal_itt_state(),
      causal_observational_state = ctx$causal_observational_state(),
      ai_draft_store = ctx$ai_draft_state$store,
      ai_mutation_store = ctx$ai_mutation_state$store,
      artifact_relationship_drafts = ctx$ai_mutation_state$artifact_relationship_drafts,
      source_data_info = ctx$source_project_data_info(),
      plot_configs = ctx$saved_plots$configs,
      plot_code = ctx$saved_plots$code,
      plot_metadata = ctx$saved_plots$metadata,
      module_artifacts = ctx$saved_module_artifacts$artifacts,
      text_artifacts = ctx$saved_text_artifacts$artifacts,
      table_artifacts = ctx$saved_table_artifacts$artifacts,
      report_plans = ctx$report_plan_state$plans,
      active_plan_id = ctx$report_plan_state$active_plan_id,
      project_collector = ctx$project_collector_summary(),
      code_run_records = ctx$code_runner_state$records,
      code_run_requests = ctx$code_runner_state$requests,
      code_run_results = lapply(ctx$code_runner_state$results, code_run_result_summary),
      code_runner_policy = ctx$code_runner_state$policy,
      layout_type = ctx$get_layout_type(),
      layout_cols = ctx$layout_cols_value(),
      export_dir = selected_value(ctx$get_export_dir()),
      export_name = ctx$export_name_value(),
      current_plot_type = ctx$get_current_plot_type(),
      current_mappings = ctx$mapping_state$values,
      current_options = ctx$current_plot_options(),
      section_names = names(ctx$section_plot_names()),
      selected_theme = NULL
    )
  }

  ctx$rebuild_saved_plots <- function(data) {
    plots <- list()
    failures <- character()

    for (plot_name in names(ctx$saved_plots$configs)) {
      config <- ctx$saved_plots$configs[[plot_name]]
      compatibility <- plot_config_column_status(config, data = data)
      if (!identical(compatibility$status, "Ready")) {
        ctx$saved_plots$status[[plot_name]] <- compatibility
        failures <- c(failures, paste0(plot_name, ": ", compatibility$message))
        next
      }

      plot <- tryCatch(
        build_autoplots_call_from_config(config, data),
        error = function(e) {
          ctx$saved_plots$status[[plot_name]] <- list(
            status = "Rebuild failed",
            message = conditionMessage(e)
          )
          failures <<- c(failures, paste0(plot_name, ": ", conditionMessage(e)))
          NULL
        }
      )

      if (!is.null(plot)) {
        plots[[plot_name]] <- plot
        ctx$saved_plots$status[[plot_name]] <- list(
          status = "Ready",
          message = compatibility$message
        )
      }
    }

    ctx$saved_plots$plots <- plots
    failures
  }

  ctx$load_project_state <- function(project_state, preferred_data_path = NULL, export_dir_override = NULL, active_project = NULL) {
    validation <- validate_project_state(project_state)
    if (!isTRUE(validation$valid)) {
      stop(paste(validation$errors, collapse = " "), call. = FALSE)
    }

    project_state <- validation$repaired_state
    messages <- validation$warnings
    if (!is.null(active_project)) {
      ctx$active_project(active_project)
      ctx$project_lifecycle_state("project_ready")
      genai_delegation_revoke_all(ctx, source = "project_load")
    } else if (is.list(project_state$project_metadata) &&
               identical(project_state$project_metadata$project_state %||% "", "project_ready")) {
      root_validation <- validate_project_root(project_state$project_metadata$project_root, create = FALSE)
      if (!identical(root_validation$status, "success")) {
        stop(paste(root_validation$errors, collapse = " "), call. = FALSE)
      }
      ctx$active_project(project_state$project_metadata)
      ctx$project_lifecycle_state("project_ready")
      genai_delegation_revoke_all(ctx, source = "project_load")
    }

    if (!is.null(preferred_data_path) && file.exists(preferred_data_path)) {
      project_state$data_path <- preferred_data_path
      project_state$data_name <- basename(preferred_data_path)
    }

    if (!is.null(export_dir_override)) {
      project_state$export_dir <- export_dir_override
    } else if (isTRUE(ctx$project_ready())) {
      project_state$export_dir <- project_report_path(ctx$current_project(), create_dir = TRUE)
    }

    ctx$saved_plots$configs <- project_state$plot_configs
    ctx$saved_plots$code <- project_state$plot_code
    ctx$saved_plots$metadata <- project_state$plot_metadata
    ctx$saved_plots$status <- list()
    ctx$saved_module_artifacts$artifacts <- project_state$module_artifacts %||% list()
    ctx$saved_text_artifacts$artifacts <- project_state$text_artifacts %||% list()
    ctx$saved_table_artifacts$artifacts <- project_state$table_artifacts %||% list()
    ctx$report_plan_state$plans <- repair_report_plan_collection(project_state$report_plans %||% list())
    ctx$report_plan_state$active_plan_id <- project_state$active_plan_id %||% NULL
    ctx$project_collector_state$collector <- NULL
    ctx$project_collector_state$last_result <- NULL
    ctx$project_collector_state$last_run_id <- NULL
    ctx$project_collector_state$restored_summary <- NULL
    ctx$project_collector_state$message <- "Project loaded. Collector will be recreated when the next module runs."
    ctx$code_runner_state$records <- project_state$code_run_records %||% list()
    ctx$code_runner_state$requests <- project_state$code_run_requests %||% list()
    ctx$code_runner_state$results <- project_state$code_run_results %||% list()
    ctx$code_runner_state$policy <- project_state$code_runner_policy %||% project_state$code_execution_policy %||% create_code_execution_policy()

    for (plot_name in names(ctx$saved_plots$configs)) {
      ctx$saved_plots$status[[plot_name]] <- list(
        status = "Needs data",
        message = "Source data is not available."
      )
    }

    ctx$saved_plots$plots <- list()
    ctx$project_data(NULL)
    ctx$project_data_info(list(
      path = project_state$data_path,
      name = project_state$data_name,
      source = (project_state$active_modeling_context %||% list())$active_dataset_source %||% "source_dataset"
    ))
    ctx$source_project_data(NULL)
    ctx$source_project_data_info(project_state$source_data_info %||% list(path = project_state$original_data_path %||% project_state$data_path, name = project_state$data_name, source = "source_dataset"))
    feature_state <- project_state$feature_experiment_state %||% list()
    ctx$feature_experiment_state$proposals <- feature_state$proposals %||% list()
    ctx$feature_experiment_state$executions <- feature_state$executions %||% list()
    ctx$feature_experiment_state$experiments <- feature_state$experiments %||% list()
    ctx$feature_experiment_state$adoptions <- feature_state$adoptions %||% list()
    campaign_state <- project_state$analytical_campaign_state %||% list()
    ctx$analytical_campaign_state$campaigns <- campaign_state$campaigns %||% list()
    decision_memory_state <- project_state$decision_memory_state %||% list()
    ctx$decision_memory_state$decisions <- decision_memory_state$decisions %||% list()
    ctx$decision_memory_state$reviews <- decision_memory_state$reviews %||% list()
    ctx$decision_memory_state$artifacts <- decision_memory_state$artifacts %||% list()
    ctx$decision_memory_state$last_result <- decision_memory_state$last_result %||% NULL
    ctx$decision_memory_state$message <- decision_memory_state$message %||% "Decision memory restored from project state."
    ctx$semantic_workspace(project_state$semantic_workspace %||% semantic_workspace_empty((ctx$current_project() %||% list())$project_id %||% NA_character_))
    ctx$semantic_decision_state(semantic_decision_normalize(project_state$semantic_decision_state %||% semantic_decision_empty((ctx$current_project() %||% list())$project_id %||% NA_character_)))
    ctx$decision_valuation_state(decision_valuation_normalize(project_state$decision_valuation_state %||% decision_valuation_empty((ctx$current_project() %||% list())$project_id %||% NA_character_)))
    ctx$decision_workflow_state(decision_workflow_normalize(project_state$decision_workflow_state %||% decision_workflow_empty((ctx$current_project() %||% list())$project_id %||% NA_character_)))
    ctx$causal_intelligence_state(causal_intelligence_normalize(project_state$causal_intelligence_state %||% causal_intelligence_empty((ctx$current_project() %||% list())$project_id %||% NA_character_)))
    ctx$causal_experiment_state(causal_experiment_normalize(project_state$causal_experiment_state %||% causal_experiment_empty((ctx$current_project() %||% list())$project_id %||% NA_character_)))
    ctx$causal_completed_experiment_state(causal_completed_experiment_normalize(project_state$causal_completed_experiment_state %||% causal_completed_experiment_empty((ctx$current_project() %||% list())$project_id %||% NA_character_)))
    ctx$causal_itt_state(causal_itt_normalize(project_state$causal_itt_state %||% causal_itt_empty((ctx$current_project() %||% list())$project_id %||% NA_character_)))
    ctx$causal_observational_state(causal_observational_normalize(project_state$causal_observational_state %||% causal_observational_empty((ctx$current_project() %||% list())$project_id %||% NA_character_)))
    ctx$ai_draft_state$store <- ai_draft_store_normalize(project_state$ai_draft_store %||% NULL)
    ctx$ai_draft_state$last_result <- NULL
    ctx$ai_draft_state$message <- "AI draft persistence state restored from project state."
    ctx$ai_mutation_state$store <- mutation_store_normalize(project_state$ai_mutation_store %||% NULL)
    ctx$ai_mutation_state$artifact_relationship_drafts <- project_state$artifact_relationship_drafts %||% list()
    ctx$ai_mutation_state$last_result <- NULL
    ctx$ai_mutation_state$message <- "Mutation governance state restored from project state."
    ctx$active_modeling_context(project_state$active_modeling_context %||% modeling_context_from_source(
      data = NULL,
      data_info = list(path = project_state$data_path, name = project_state$data_name),
      project = ctx$current_project()
    ))

    restored_collector <- project_state$project_collector %||% NULL
    if (data.table::is.data.table(restored_collector) && nrow(restored_collector)) {
      manifest_file <- restored_collector$manifest_file[[1]] %||% NA_character_
      docx_file <- restored_collector$collector_docx[[1]] %||% NA_character_
      manifest_ready <- !is.na(manifest_file) && file.exists(manifest_file)
      docx_ready <- !is.na(docx_file) && file.exists(docx_file)
      restored_status <- if (manifest_ready || docx_ready) "restored" else restored_collector$collector_status[[1]] %||% "not_created"
      ctx$project_collector_state$restored_summary <- data.table::data.table(
        collector_status = restored_status,
        current_run_id = restored_collector$run_id[[nrow(restored_collector)]] %||% restored_collector$current_run_id[[1]] %||% NA_character_,
        artifact_count = sum(suppressWarnings(as.integer(restored_collector$artifacts_added %||% restored_collector$artifact_count %||% 0L)), na.rm = TRUE),
        bundle_count = nrow(restored_collector),
        render_target = restored_collector$render_target[[1]] %||% "llm_docx",
        collector_docx = docx_file,
        manifest_status = if (manifest_ready) "ready" else "not_written",
        manifest_file = manifest_file
      )
    }

    if (!is.null(project_state$data_path) && file.exists(project_state$data_path)) {
      data <- tryCatch(
        read_dataset_file(
          project_state$data_path,
          name = project_state$data_name %||% project_state$data_path
        ),
        error = function(e) {
          stop("Failed to reload project data: ", conditionMessage(e), call. = FALSE)
        }
      )
      data_validation <- validate_project_state(project_state, data = data)
      project_state <- data_validation$repaired_state
      ctx$saved_plots$configs <- project_state$plot_configs
      ctx$saved_plots$code <- project_state$plot_code
      ctx$saved_plots$metadata <- project_state$plot_metadata
      messages <- c(messages, data_validation$warnings)
      ctx$project_data(data)
      if (!identical((ctx$active_modeling_context() %||% list())$active_dataset_source, "prepared_artifact")) {
        ctx$active_modeling_context(modeling_context_from_source(
          data = data,
          data_info = ctx$project_data_info(),
          project = ctx$current_project()
        ))
      }
      failures <- ctx$rebuild_saved_plots(data)
      if (length(failures)) {
        messages <- c(
          messages,
          paste(
            "Project loaded, but some plots could not be rebuilt:",
            paste(failures, collapse = " | ")
          )
        )
      } else {
        messages <- c(messages, "Project loaded and saved plots rebuilt.")
      }
    } else {
      messages <- c(
        messages,
        "Project loaded, but source data file was not found. Re-upload the data to rebuild plots."
      )
    }

    ctx$set_layout_settings(
      layout_type = project_state$layout_type,
      layout_cols = project_state$layout_cols
    )
    ctx$set_export_settings(
      export_dir = project_state$export_dir,
      export_name = project_state$export_name
    )

    if (!is.null(project_state$current_plot_type) &&
        project_state$current_plot_type %in% plot_types) {
      current_config <- list(
        plot_type = project_state$current_plot_type,
        mappings = default_value(project_state$current_mappings, list()),
        options = default_value(project_state$current_options, list())
      )
      ctx$load_config_into_builder(current_config)
    }

    list(state = project_state, messages = unique(messages[nzchar(messages)]))
  }

  command_palette_server("command_palette", navigation_session = session)
  global_ai_assistant_server("global_ai", ctx)
  page_guide_server("guide", ctx)
  page_evidence_review_server("evidence_review", ctx)
  page_knowledge_library_server("knowledge_library", ctx)
  page_mission_control_server("mission_control", ctx)
  page_ai_runtime_server("ai_runtime", ctx)
  page_product_experience_server("product_experience", ctx)
  page_data_server("data", ctx)
  page_plot_builder_server("plot_builder", ctx)
  page_workflow_server("workflow", ctx)
  page_analysis_modules_server("analysis_modules", ctx)
  page_semantic_intelligence_server("semantic_intelligence", ctx)
  page_causal_intelligence_server("causal_intelligence", ctx)
  page_code_runner_server("code_runner", ctx)
  page_layouts_server("layouts", ctx)
  page_export_server("export", ctx)
  page_artifact_library_server("artifact_library", ctx)
  page_project_server("project", ctx)
}
