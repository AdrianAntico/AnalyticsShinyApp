server <- function(input, output, session) {
  ctx <- new.env(parent = environment())

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
  ctx$genai_config <- reactiveVal(genai_default_config(auto_detect_local = TRUE))
  ctx$genai_last_result <- reactiveVal(NULL)
  ctx$evidence_strategy <- reactiveVal("balanced")
  ctx$evidence_strategy_config <- reactiveVal(evidence_strategy_config("balanced"))
  ctx$genai_status <- function(check_availability = FALSE) {
    genai_provider_status(ctx$genai_config(), check_availability = check_availability)
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
  ctx$navigate_to <- function(page) {
    updateTabsetPanel(session, "main_tabs", selected = page)
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
  ctx$get_export_dir <- function() getwd()
  ctx$get_export_name <- function() "autoplots_report"
  ctx$export_name_value <- function() "autoplots_report"
  ctx$set_export_settings <- function(export_dir = NULL, export_name = NULL) invisible(NULL)

  ctx$project_collector_output_dir <- function() {
    export_dir <- tryCatch(selected_value(ctx$get_export_dir()), error = function(e) NULL)
    if (is.null(export_dir) || !nzchar(export_dir)) {
      export_dir <- getwd()
    }
    file.path(export_dir, "project_artifact_collector")
  }
  ctx$project_collector_project_id <- function() {
    raw <- ctx$current_data_name() %||% "analytics_project"
    .project_collector_slug(tools::file_path_sans_ext(basename(raw)))
  }
  ctx$ensure_project_collector <- function() {
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
    collector <- ctx$ensure_project_collector()
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
    list(
      app_version = APP_VERSION,
      saved_at = Sys.time(),
      data_path = data_path,
      data_name = ctx$current_data_name(),
      original_data_path = data_path,
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

  ctx$load_project_state <- function(project_state, preferred_data_path = NULL, export_dir_override = NULL) {
    validation <- validate_project_state(project_state)
    if (!isTRUE(validation$valid)) {
      stop(paste(validation$errors, collapse = " "), call. = FALSE)
    }

    project_state <- validation$repaired_state
    messages <- validation$warnings

    if (!is.null(preferred_data_path) && file.exists(preferred_data_path)) {
      project_state$data_path <- preferred_data_path
      project_state$data_name <- basename(preferred_data_path)
    }

    if (!is.null(export_dir_override)) {
      project_state$export_dir <- export_dir_override
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
      name = project_state$data_name
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
  page_knowledge_library_server("knowledge_library", ctx)
  page_mission_control_server("mission_control", ctx)
  page_data_server("data", ctx)
  page_plot_builder_server("plot_builder", ctx)
  page_workflow_server("workflow", ctx)
  page_analysis_modules_server("analysis_modules", ctx)
  page_code_runner_server("code_runner", ctx)
  page_layouts_server("layouts", ctx)
  page_export_server("export", ctx)
  page_artifact_library_server("artifact_library", ctx)
  page_project_server("project", ctx)
}
