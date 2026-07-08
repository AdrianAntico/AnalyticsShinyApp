artifact_studio_demo_data <- function(n = 160L, seed = 42L) {
  set.seed(seed)
  segment <- sample(c("Enterprise", "SMB", "Consumer"), n, replace = TRUE, prob = c(0.24, 0.38, 0.38))
  region <- sample(c("West", "East", "Central", "South"), n, replace = TRUE)

  data <- data.table::data.table(
    id = sprintf("demo_%03d", seq_len(n)),
    date = seq.Date(as.Date("2025-01-01"), by = "day", length.out = n),
    segment = segment,
    region = region,
    age = pmax(18, round(stats::rnorm(n, 42, 11))),
    tenure = round(stats::runif(n, 0, 8), 2),
    spend = round(stats::rgamma(n, shape = 5, scale = 20), 2),
    support_tickets = stats::rpois(n, lambda = ifelse(segment == "Enterprise", 3.2, 1.8))
  )

  data[, risk_score := round(
    0.35 * scale(age)[, 1] -
      0.55 * scale(tenure)[, 1] +
      0.18 * support_tickets +
      ifelse(segment == "Enterprise", 1.5, 0) +
      stats::rnorm(.N, 0, 0.55),
    3
  )]
  data[, target := round(
    120 +
      0.8 * spend -
      5.5 * tenure +
      ifelse(region == "West", 12, 0) +
      ifelse(segment == "Enterprise", 18, 0) +
      9 * risk_score +
      stats::rnorm(.N, 0, 16),
    2
  )]
  data[, prediction := round(target + stats::rnorm(.N, 0, 18), 2)]

  shap_noise <- function(sd = 0.05) stats::rnorm(n, 0, sd)
  data[, Shap_age := round(0.35 * scale(age)[, 1] + shap_noise(), 4)]
  data[, Shap_tenure := round(-0.55 * scale(tenure)[, 1] + shap_noise(), 4)]
  data[, Shap_spend := round(0.8 * scale(spend)[, 1] + shap_noise(), 4)]
  data[, Shap_risk_score := round(scale(risk_score)[, 1] + shap_noise(), 4)]
  data[, Shap_support_tickets := round(0.2 * scale(support_tickets)[, 1] + shap_noise(), 4)]

  data
}

artifact_studio_demo_configs <- function() {
  list(
    autoquant_eda = list(
      DataName = "Artifact Studio Demo",
      UnivariateVars = c("target", "prediction", "age", "tenure", "spend", "segment", "region", "support_tickets"),
      CorrVars = c("target", "prediction", "age", "tenure", "spend", "risk_score", "support_tickets"),
      TrendVars = c("target", "prediction"),
      TrendDateVar = "date",
      TrendGroupVar = "segment",
      TargetVar = "target",
      Theme = "dark",
      MaxCategoricalLevels = 12L,
      MaxDiscreteNumericLevels = 15L,
      MaxCorrelationPairsToPlot = 18L
    ),
    autoquant_model_readiness = list(
      model_name = "Artifact Studio Demo Model",
      problem_type = "Regression",
      actual_var = "target",
      prediction_var = "prediction",
      date_var = "date",
      group_var = "segment",
      theme = "dark",
      max_rows = 1000L,
      max_groups = 12L,
      run_gam_diagnostics = FALSE
    ),
    autoquant_regression_shap_analysis = list(
      data_name = "Artifact Studio Demo",
      model_name = "Artifact Studio Demo Model",
      target_col = "target",
      prediction_col = "prediction",
      feature_cols = c("age", "tenure", "spend", "risk_score", "support_tickets"),
      shap_prefix = "Shap_",
      id_cols = "id",
      DateVar = "date",
      ByVars = c("segment"),
      selected_features = c("age", "tenure", "spend", "risk_score", "support_tickets"),
      top_n = 5L,
      max_dependence_rows = 120L,
      max_segment_levels = 8L,
      include_dependence = TRUE,
      include_segments = TRUE,
      include_time = TRUE,
      include_local = TRUE,
      include_interactions = FALSE,
      include_effect_curves = TRUE,
      effect_curve_backend = "none",
      effect_curve_sample_size = 120L,
      effect_curve_max_features = 4L,
      effect_curve_validation_fraction = 0.2,
      auto_plots_theme = "dark",
      effect_curve_theme = "dark",
      max_dependence_plots = 4L,
      max_segment_plots = 2L,
      max_time_plots = 2L,
      max_local_plots = 3L
    )
  )
}

.artifact_studio_demo_empty_named_list <- function() {
  stats::setNames(list(), character())
}

.artifact_studio_demo_select_artifacts <- function(artifacts, max_artifacts = 12L) {
  if (is.null(artifacts) || !length(artifacts)) {
    return(list())
  }

  summary <- artifact_summary(artifacts)
  selected <- character()
  type_limits <- c(
    plot = 3L,
    table = 3L,
    text = 2L,
    narrative = 2L,
    diagnostic = 1L,
    recommendation = 1L
  )
  for (type in names(type_limits)) {
    ids <- summary$artifact_id[summary$artifact_type == type]
    selected <- unique(c(selected, utils::head(ids, type_limits[[type]])))
  }

  remaining <- setdiff(summary$artifact_id[order(summary$order, summary$artifact_id)], selected)
  selected <- utils::head(c(selected, remaining), max_artifacts)
  artifacts[selected]
}

.artifact_studio_demo_module_result <- function(module_id, result, max_artifacts = 12L) {
  selected <- .artifact_studio_demo_select_artifacts(result$artifacts %||% list(), max_artifacts = max_artifacts)
  result$artifacts <- selected
  result$metadata$artifacts <- selected
  result$metadata$artifact_count <- length(selected)
  counts <- module_artifact_counts(selected)
  result$metadata$plot_count <- counts$plot_count
  result$metadata$table_count <- counts$table_count
  result$metadata$text_count <- counts$text_count
  result$metadata$n_artifacts <- counts$artifact_count
  result$metadata$artifact_counts <- list(
    plot = counts$plot_count,
    table = counts$table_count,
    text = counts$text_count
  )
  result$metadata$demo_seed_module_id <- module_id
  result
}

.artifact_studio_demo_report_plans <- function(results) {
  plans <- unlist(lapply(results, function(result) {
    result$metadata$report_plans %||% list()
  }), recursive = FALSE)

  if (is.null(plans) || !length(plans)) {
    return(.artifact_studio_demo_empty_named_list())
  }
  plans
}

.artifact_studio_demo_attach_thumbnails <- function(artifacts, screenshot_index = list()) {
  if (is.null(artifacts) || !length(artifacts) || !length(screenshot_index)) {
    return(artifacts %||% list())
  }

  lapply(artifacts, function(artifact) {
    screenshot <- screenshot_index[[artifact$artifact_id %||% ""]]
    if (identical(artifact$artifact_type, "plot") &&
        is.list(screenshot) &&
        identical(screenshot$status %||% "", "success") &&
        file.exists(screenshot$file %||% "")) {
      artifact$metadata$thumbnail_path <- normalizePath(screenshot$file, winslash = "/", mustWork = TRUE)
      artifact$metadata$screenshot_path <- artifact$metadata$thumbnail_path
      artifact$metadata$screenshot_helper <- screenshot$helper %||% "AutoQuant::ObjectToPNG"
    }
    artifact
  })
}

create_artifact_studio_demo_project <- function(
  output_dir = file.path("exports", "artifact_studio_demo"),
  project_id = "artifact_studio_demo",
  project_name = "Artifact Studio Demo",
  seed = 42L,
  n = 160L,
  max_artifacts_per_module = 12L,
  write_collector = TRUE
) {
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  data_dir <- file.path(output_dir, "data")
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

  data <- artifact_studio_demo_data(n = n, seed = seed)
  data_path <- file.path(data_dir, "artifact_studio_demo_data.csv")
  data.table::fwrite(data, data_path)
  data_path <- normalizePath(data_path, winslash = "/", mustWork = TRUE)

  configs <- artifact_studio_demo_configs()
  run_module <- function(module_id) {
    result <- run_analysis_module(module_id, data = data, config = configs[[module_id]])
    .artifact_studio_demo_module_result(module_id, result, max_artifacts = max_artifacts_per_module)
  }

  module_ids <- c(
    "autoquant_eda",
    "autoquant_model_readiness",
    "autoquant_regression_shap_analysis"
  )
  results <- stats::setNames(lapply(module_ids, run_module), module_ids)

  artifacts <- unlist(lapply(results, function(result) result$artifacts %||% list()), recursive = FALSE, use.names = FALSE)
  names(artifacts) <- vapply(artifacts, function(artifact) artifact$artifact_id %||% "", character(1))
  plans <- .artifact_studio_demo_report_plans(results)
  collector <- create_project_artifact_collector(
    project_id = project_id,
    project_name = project_name,
    output_dir = file.path(output_dir, "project_artifact_collector")
  )

  append_results <- list()
  for (module_id in module_ids) {
    append_result <- project_collector_append_result(
      collector = collector,
      result = results[[module_id]],
      project_id = project_id,
      project_name = project_name,
      module_id = module_id,
      write = FALSE
    )
    append_results[[module_id]] <- append_result
    collector <- append_result$value %||% collector
  }

  write_result <- if (isTRUE(write_collector)) {
    project_collector_write(collector)
  } else {
    service_result(status = "success", value = collector, messages = "Collector write skipped by request.")
  }

  artifacts <- .artifact_studio_demo_attach_thumbnails(
    artifacts,
    screenshot_index = write_result$metadata$screenshot_index %||% list()
  )

  project_state <- list(
    app_version = APP_VERSION,
    saved_at = Sys.time(),
    data_path = data_path,
    data_name = basename(data_path),
    original_data_path = data_path,
    plot_configs = .artifact_studio_demo_empty_named_list(),
    plot_code = .artifact_studio_demo_empty_named_list(),
    plot_metadata = .artifact_studio_demo_empty_named_list(),
    module_artifacts = artifacts,
    text_artifacts = .artifact_studio_demo_empty_named_list(),
    table_artifacts = .artifact_studio_demo_empty_named_list(),
    report_plans = plans,
    active_plan_id = if (length(plans)) names(plans)[[1]] else NULL,
    project_collector = project_collector_manifest(collector),
    code_run_records = .artifact_studio_demo_empty_named_list(),
    code_run_requests = .artifact_studio_demo_empty_named_list(),
    code_run_results = .artifact_studio_demo_empty_named_list(),
    code_runner_policy = create_code_execution_policy(),
    layout_type = "Grid",
    layout_cols = 2L,
    export_dir = output_dir,
    export_name = "artifact_studio_demo_report",
    current_plot_type = NULL,
    current_mappings = list(),
    current_options = list(),
    section_names = unique(vapply(artifacts, function(artifact) artifact$section %||% "Analysis", character(1))),
    selected_theme = "dark"
  )

  project_path <- save_project_state(project_state, file.path(output_dir, "artifact_studio_demo_project.rds"))
  summary <- artifact_summary(artifacts)
  screenshot_files <- list.files(collector$screenshot_directory, pattern = "\\.png$", full.names = TRUE)
  table_files <- list.files(collector$table_directory, pattern = "\\.(csv|json)$", full.names = TRUE)

  service_result(
    status = if (identical(write_result$status, "success") && length(artifacts)) "success" else "warning",
    value = list(
      project_id = project_id,
      project_name = project_name,
      data = data,
      data_path = data_path,
      project_path = project_path,
      output_dir = output_dir,
      results = results,
      artifacts = artifacts,
      artifact_summary = summary,
      report_plans = plans,
      collector = collector,
      collector_write = write_result,
      append_results = append_results,
      screenshot_files = normalizePath(screenshot_files, winslash = "/", mustWork = FALSE),
      table_files = normalizePath(table_files, winslash = "/", mustWork = FALSE)
    ),
    messages = sprintf(
      "Created Artifact Studio demo with %s artifacts across %s modules.",
      length(artifacts),
      length(module_ids)
    ),
    warnings = c(
      unlist(lapply(results, function(result) result$warnings %||% character()), use.names = FALSE),
      write_result$warnings %||% character()
    ),
    errors = c(
      unlist(lapply(results, function(result) result$errors %||% character()), use.names = FALSE),
      write_result$errors %||% character()
    ),
    metadata = list(
      project_id = project_id,
      project_name = project_name,
      module_ids = module_ids,
      artifact_count = length(artifacts),
      plot_count = sum(summary$artifact_type == "plot"),
      table_count = sum(summary$artifact_type == "table"),
      text_count = sum(summary$artifact_type %in% c("text", "narrative")),
      collector_docx = collector$collector_docx,
      collector_manifest = collector$manifest_file,
      screenshot_count = length(screenshot_files),
      table_sidecar_count = length(table_files),
      project_path = project_path,
      output_dir = output_dir
    )
  )
}

qa_artifact_studio_demo_seed <- function(output_dir = file.path(tempdir(), "artifact_studio_demo_seed_qa")) {
  demo <- create_artifact_studio_demo_project(
    output_dir = output_dir,
    n = 120L,
    max_artifacts_per_module = 8L,
    write_collector = TRUE
  )
  value <- demo$value %||% list()
  artifacts <- value$artifacts %||% list()
  summary <- value$artifact_summary %||% artifact_summary(artifacts)
  collector <- value$collector
  write <- value$collector_write %||% list(status = "error")
  screenshot_files <- value$screenshot_files %||% character()
  table_files <- value$table_files %||% character()
  first_artifact <- artifacts[[1]]
  first_quality <- if (!is.null(first_artifact)) assess_artifact_quality(first_artifact, render_target = "llm_docx") else NULL
  plot_artifacts <- artifacts[vapply(artifacts, function(artifact) identical(artifact$artifact_type, "plot"), logical(1))]
  first_plot <- if (length(plot_artifacts)) plot_artifacts[[1]] else NULL
  first_plot_quality <- if (!is.null(first_plot)) assess_artifact_quality(first_plot, render_target = "llm_docx") else NULL
  first_plot_card <- if (!is.null(first_plot)) {
    paste(as.character(ui_artifact_studio_card(first_plot, first_plot_quality)), collapse = " ")
  } else {
    ""
  }
  fallback_plot_card <- if (!is.null(first_plot)) {
    fallback_plot <- first_plot
    fallback_plot$metadata$thumbnail_path <- NULL
    fallback_plot$metadata$screenshot_path <- NULL
    fallback_plot$metadata$collector_screenshot_path <- NULL
    paste(as.character(ui_artifact_studio_card(fallback_plot, first_plot_quality)), collapse = " ")
  } else {
    ""
  }
  saved_project <- if (file.exists(value$project_path %||% "")) readRDS(value$project_path) else list()
  saved_collector <- saved_project$project_collector %||% data.table::data.table()

  rows <- list(
    data.table::data.table(
      check = "demo_created",
      status = if (identical(demo$status, "success")) "success" else "error",
      message = demo$messages %||% "Demo helper completed."
    ),
    data.table::data.table(
      check = "artifacts_exist",
      status = if (length(artifacts) >= 12L && nrow(summary) == length(artifacts)) "success" else "error",
      message = paste("Artifacts:", length(artifacts))
    ),
    data.table::data.table(
      check = "artifact_type_mix",
      status = if (all(c("plot", "table") %in% summary$artifact_type) && any(summary$artifact_type %in% c("text", "narrative"))) "success" else "error",
      message = paste("Types:", paste(sort(unique(summary$artifact_type)), collapse = ", "))
    ),
    data.table::data.table(
      check = "gallery_populated_cards",
      status = if (length(artifacts) > 0L && grepl("aq-studio-card", paste(as.character(ui_artifact_studio_card(first_artifact, first_quality)), collapse = " "), fixed = TRUE)) "success" else "error",
      message = "Artifact Studio card markup renders for a real demo artifact."
    ),
    data.table::data.table(
      check = "inspector_metadata",
      status = if (!is.null(first_artifact$metadata$module_run_id) && !is.null(first_artifact$metadata$artifact_importance)) "success" else "error",
      message = paste("First artifact:", first_artifact$artifact_id %||% "none")
    ),
    data.table::data.table(
      check = "filmstrip_entries",
      status = if (grepl("aq-artifact-filmstrip-item", paste(as.character(ui_artifact_filmstrip(artifacts)), collapse = " "), fixed = TRUE)) "success" else "error",
      message = paste("Filmstrip artifacts:", length(artifacts))
    ),
    data.table::data.table(
      check = "collector_bundles",
      status = if (inherits(collector, "project_artifact_collector") && length(collector$bundles) >= 3L) "success" else "error",
      message = paste("Bundles:", length(collector$bundles %||% list()))
    ),
    data.table::data.table(
      check = "collector_write",
      status = if (identical(write$status, "success") && file.exists(collector$collector_docx) && file.exists(collector$manifest_file)) "success" else "error",
      message = paste("Collector:", collector$collector_docx %||% "missing")
    ),
    data.table::data.table(
      check = "screenshots_exist",
      status = if (length(screenshot_files) > 0L && all(file.exists(screenshot_files))) "success" else "error",
      message = paste("Screenshots:", length(screenshot_files))
    ),
    data.table::data.table(
      check = "plot_thumbnails_attached",
      status = if (length(plot_artifacts) > 0L && all(vapply(plot_artifacts, function(artifact) file.exists(artifact$metadata$thumbnail_path %||% ""), logical(1)))) "success" else "error",
      message = paste("Plot thumbnails:", length(plot_artifacts))
    ),
    data.table::data.table(
      check = "plot_thumbnail_card_render",
      status = if (grepl("<img", first_plot_card, fixed = TRUE) && grepl("data:image/", first_plot_card, fixed = TRUE)) "success" else "error",
      message = "Plot card renders existing collector screenshot thumbnail."
    ),
    data.table::data.table(
      check = "thumbnail_fallback",
      status = if (!grepl("<img", fallback_plot_card, fixed = TRUE) && grepl("aq-studio-card-icon", fallback_plot_card, fixed = TRUE)) "success" else "error",
      message = "Missing screenshot paths fall back to semantic icon treatment."
    ),
    data.table::data.table(
      check = "table_sidecars_exist",
      status = if (length(table_files) > 0L && all(file.exists(table_files))) "success" else "error",
      message = paste("Table sidecars:", length(table_files))
    ),
    data.table::data.table(
      check = "saved_collector_restore_payload",
      status = if (data.table::is.data.table(saved_collector) && nrow(saved_collector) >= 3L && file.exists(value$collector$manifest_file) && file.exists(value$collector$collector_docx)) "success" else "error",
      message = "Saved project contains collector manifest/docx references for UI restore."
    ),
    data.table::data.table(
      check = "loadable_project",
      status = if (file.exists(value$project_path %||% "")) "success" else "error",
      message = paste("Project:", value$project_path %||% "missing")
    )
  )

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
