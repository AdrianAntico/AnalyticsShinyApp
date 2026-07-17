analysis_context_from_data <- function(data) {
  empty <- list(
    has_data = FALSE,
    rows = 0L,
    columns = 0L,
    target = NA_character_,
    prediction = NA_character_,
    date = NA_character_,
    group = NA_character_,
    features = character(),
    shap_columns = character(),
    problem_hint = "Unknown"
  )
  if (is.null(data) || !length(data)) {
    return(empty)
  }

  choices <- names(data)
  numeric_choices <- choices[vapply(data, is.numeric, logical(1))]
  pick <- function(candidates, pool = choices) {
    matched <- pool[tolower(pool) %in% tolower(candidates)]
    if (length(matched)) matched[[1]] else NA_character_
  }

  target <- pick(c("target", "y", "revenue", "sales", "conversions", "conversion"))
  prediction <- pick(c("prediction", "predict", "yhat", "score", "p", "p1", "probability"), numeric_choices)
  date <- pick(c("date", "event_date", "ds", "month", "week"))
  group <- pick(c("channel", "segment", "customer_segment", "region", "group", "cohort"))
  shap_columns <- choices[startsWith(choices, "Shap_")]
  reserved <- unique(stats::na.omit(c(target, prediction, date, group, shap_columns, "predicted_class", "PredictedClass")))
  features <- setdiff(choices, reserved)
  problem_hint <- "Regression"
  if (!is.na(target) && target %in% choices) {
    target_values <- unique(stats::na.omit(data[[target]]))
    if (length(target_values) <= 2L) {
      problem_hint <- "Binary Classification"
    }
  }
  if (!is.na(prediction) && grepl("^(p|p1|prob|probability|score)$", prediction, ignore.case = TRUE)) {
    problem_hint <- "Binary Classification"
  }

  list(
    has_data = TRUE,
    rows = nrow(data),
    columns = ncol(data),
    target = target,
    prediction = prediction,
    date = date,
    group = group,
    features = features,
    shap_columns = shap_columns,
    problem_hint = problem_hint
  )
}

analysis_context_value <- function(context, field, fallback = character()) {
  value <- context[[field]] %||% fallback
  if (!length(value) || is.na(value[[1]]) || !nzchar(value[[1]])) {
    return(fallback)
  }
  value[[1]]
}

analysis_context_panel <- function(context, module_id = NULL) {
  if (!isTRUE(context$has_data)) {
    return(ui_callout(
      "No dataset loaded",
      "Load data before running analysis modules. Once data are available, common target, prediction, date, group, and feature choices are reused as visible defaults.",
      status = "warning"
    ))
  }
  module_label <- module_display_label(module_id %||% "autoquant_eda")
  tags$div(
    class = "aq-analysis-context-panel",
    ui_callout(
      paste("Context for", module_label),
      paste(
        context$rows, "rows x", context$columns, "columns.",
        "Target:", analysis_context_value(context, "target", "not detected"),
        "| Prediction:", analysis_context_value(context, "prediction", "not detected"),
        "| Date:", analysis_context_value(context, "date", "not detected"),
        "| Group:", analysis_context_value(context, "group", "not detected")
      ),
      status = "info"
    )
  )
}

analysis_module_next_action <- function(module_id, result = NULL) {
  module_id <- normalize_module_id(module_id %||% "autoquant_eda")
  if (!is.null(result) && !identical(result$status, "success")) {
    return(list(
      title = "Resolve run issues",
      message = "Review the run message and warnings before continuing to the next analytical stage.",
      status = if (identical(result$status, "error")) "error" else "warning",
      next_module = NA_character_,
      button_label = NA_character_
    ))
  }

  next_map <- list(
    autoquant_eda = list(
      title = "Next: Model Readiness",
      message = "Explore Data created foundational evidence. Continue with Model Readiness to review target suitability, leakage risk, drift, and modeling recommendations.",
      next_module = "autoquant_model_readiness"
    ),
    autoquant_model_readiness = list(
      title = "Next: Feature Engineering / Model Preparation",
      message = "Readiness evidence is available. Prepare a deterministic modeling dataset before training so transformations, exclusions, and splits are visible and reproducible.",
      next_module = "feature_engineering_model_prep"
    ),
    feature_engineering_model_prep = list(
      title = "Next: CatBoost Builder",
      message = "Prepared modeling data and lineage artifacts are available. Continue to CatBoost Builder when you are ready to train against the prepared feature set.",
      next_module = "autoquant_catboost_builder"
    ),
    autoquant_catboost_builder = list(
      title = "Next: Downstream model evidence",
      message = "CatBoost can hand off scored output to Model Assessment, Model Insights, and SHAP when the required columns are available.",
      next_module = NA_character_
    ),
    model_assessment = list(
      title = "Next: Model Insights",
      message = "Post-model performance evidence is available. Continue with Model Insights to inspect behavior, effects, and diagnostics.",
      next_module = "autoquant_regression_model_insights"
    ),
    autoquant_regression_model_insights = list(
      title = "Next: Regression SHAP Insights",
      message = "Model behavior evidence is available. Continue with SHAP when precomputed SHAP columns exist or a CatBoost handoff produced them.",
      next_module = "autoquant_regression_shap_analysis"
    ),
    autoquant_binary_model_insights = list(
      title = "Next: Binary SHAP Insights",
      message = "Classification behavior evidence is available. Continue with SHAP when precomputed SHAP columns exist or a CatBoost handoff produced them.",
      next_module = "autoquant_binary_shap_analysis"
    ),
    autoquant_regression_shap_analysis = list(
      title = "Next: Review artifacts and reports",
      message = "Prediction-surface evidence is available. Inspect the artifacts, then curate reporting through Layout or Export.",
      next_module = NA_character_
    ),
    autoquant_binary_shap_analysis = list(
      title = "Next: Review artifacts and reports",
      message = "Prediction-surface evidence is available. Inspect the artifacts, then curate reporting through Layout or Export.",
      next_module = NA_character_
    )
  )
  item <- next_map[[module_id]] %||% list(
    title = "Next: Review artifacts",
    message = "Inspect generated artifacts and continue through Workflow when ready.",
    next_module = NA_character_
  )
  item$status <- "success"
  item$button_label <- if (!is.na(item$next_module %||% NA_character_)) {
    paste("Open", module_display_label(item$next_module))
  } else {
    NA_character_
  }
  item
}

page_analysis_modules_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Analysis Modules",
    ui_page(
      title = "Analysis Modules",
      subtitle = "Run one analytical stage against the current dataset and preserve the result as project evidence.",
      eyebrow = "Analysis",
      ui_object_spine(
        object = "Analysis Run",
        intent = "Choose the next analytical operator, run it against the current project data, and inspect the generated evidence contract.",
        state = "Ready when data and required columns are available.",
        next_action = "Select a user-facing module, review detected context, then run it.",
        depth = "Generated code and handoff details remain visible as technical depth."
      ),
      tags$section(
        class = "aq-analysis-runway",
        ui_card(
          title = "Run the Next Analysis",
          subtitle = "Pick the analytical move that answers the next project question.",
          class = "aq-analysis-command-card",
          tags$div(
            class = "aq-analysis-command-grid",
            tags$div(
              class = "aq-analysis-module-picker",
              selectInput(
                ns("analysis_module_id"),
                "Analysis",
                choices = stats::setNames(
                  c(
                    "autoquant_eda",
                    "model_assessment",
                    "autoquant_model_readiness",
                    "feature_engineering_model_prep",
                    "autoquant_regression_model_insights",
                    "autoquant_binary_model_insights",
                    "autoquant_regression_shap_analysis",
                    "autoquant_binary_shap_analysis",
                    "autoquant_catboost_builder",
                    "autoquant_multiclass_shap_analysis"
                  ),
                  vapply(
                    c(
                      "autoquant_eda",
                      "model_assessment",
                      "autoquant_model_readiness",
                      "feature_engineering_model_prep",
                      "autoquant_regression_model_insights",
                      "autoquant_binary_model_insights",
                      "autoquant_regression_shap_analysis",
                      "autoquant_binary_shap_analysis",
                      "autoquant_catboost_builder",
                      "autoquant_multiclass_shap_analysis"
                    ),
                    module_display_label,
                    character(1)
                  )
                ),
                selected = "autoquant_eda"
              ),
              uiOutput(ns("analysis_context_panel"))
            ),
            tags$div(
              class = "aq-analysis-run-controls",
              uiOutput(ns("analysis_module_status")),
              ui_action_row(
                actionButton(ns("run_analysis_module"), "Run Analysis", class = "btn-primary")
              )
            )
          )
        ),
        ui_card(
          title = "Analysis Details",
          class = "aq-analysis-detail-card",
          uiOutput(ns("analysis_module_settings")),
          uiOutput(ns("catboost_handoff_panel")),
          ui_disclosure(
            "Reproducible Code",
            ui_code_panel(
              "Generated Code",
              verbatimTextOutput(ns("analysis_module_code")),
              collapsed = FALSE
            ),
            level = "developer",
            open = FALSE
          )
        )
      )
    )
  )
}

page_analysis_modules_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    module_result <- reactiveVal(NULL)
    handoff_result <- reactiveVal(NULL)

    output$analysis_context_panel <- renderUI({
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      analysis_context_panel(
        analysis_context_from_data(data),
        selected_value(input$analysis_module_id) %||% "autoquant_eda"
      )
    })

    output$analysis_module_settings <- renderUI({
      module_id <- selected_value(input$analysis_module_id) %||% "autoquant_eda"
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      context <- analysis_context_from_data(data)
      choices <- if (is.null(data)) character() else names(data)
      numeric_choices <- if (is.null(data)) {
        character()
      } else {
        names(data)[vapply(data, is.numeric, logical(1))]
      }
      target_default <- analysis_context_value(context, "target", character())
      prediction_default <- analysis_context_value(context, "prediction", character())
      date_default <- analysis_context_value(context, "date", "")
      group_default <- analysis_context_value(context, "group", "")
      feature_defaults <- context$features %||% character()

      if (identical(module_id, "autoquant_model_readiness") || identical(module_id, "model_assessment")) {
        return(tagList(
          selectInput(
            session$ns("assessment_problem_type"),
            "Problem Type",
            choices = c("Regression", "Binary Classification"),
            selected = context$problem_hint %||% "Regression"
          ),
          selectInput(
            session$ns("actual_var"),
            "Actual",
            choices = choices,
            selected = target_default
          ),
          selectInput(
            session$ns("prediction_var"),
            "Prediction / Score",
            choices = numeric_choices,
            selected = prediction_default
          ),
          selectInput(
            session$ns("predicted_class_var"),
            "Predicted Class",
            choices = c("(none)" = "", choices),
            selected = if ("predicted_class" %in% choices) "predicted_class" else ""
          ),
          textInput(session$ns("positive_class"), "Positive Class", value = "1"),
          selectInput(
            session$ns("assessment_date_var"),
            "Date",
            choices = c("(none)" = "", choices),
            selected = date_default
          ),
          selectInput(
            session$ns("assessment_group_var"),
            "Group",
            choices = c("(none)" = "", choices),
            selected = group_default
          ),
          textInput(session$ns("model_name"), "Model Name", value = "Model"),
          textInput(session$ns("artifact_section"), "Artifact Section", value = "Model Readiness"),
          selectInput(
            session$ns("assessment_theme"),
            "Theme",
            choices = c("light", "dark", "pimp"),
            selected = "dark"
          ),
          numericInput(session$ns("assessment_max_rows"), "Max Rows", value = 1000, min = 1, step = 1),
          numericInput(session$ns("assessment_max_groups"), "Max Groups", value = 25, min = 1, step = 1)
        ))
      }

      if (identical(module_id, "feature_engineering_model_prep")) {
        return(tagList(
          selectInput(
            session$ns("prep_include_columns"),
            "Columns to Keep",
            choices = choices,
            selected = choices,
            multiple = TRUE
          ),
          selectInput(
            session$ns("prep_exclude_columns"),
            "Columns to Exclude",
            choices = choices,
            selected = character(),
            multiple = TRUE
          ),
          selectInput(
            session$ns("prep_target_col"),
            "Target Column",
            choices = c("(none)" = "", choices),
            selected = target_default
          ),
          selectInput(
            session$ns("prep_date_col"),
            "Date Column",
            choices = c("(none)" = "", choices),
            selected = date_default
          ),
          selectInput(
            session$ns("prep_group_cols"),
            "Group Columns",
            choices = choices,
            selected = group_default[group_default %in% choices],
            multiple = TRUE
          ),
          selectInput(
            session$ns("prep_missing_method"),
            "Missing Value Handling",
            choices = c(
              "Leave as-is" = "none",
              "Median / Mode" = "median_mode",
              "Zero / Unknown" = "zero_unknown",
              "Drop rows with missing values" = "drop_rows"
            ),
            selected = "median_mode"
          ),
          checkboxInput(session$ns("prep_drop_constant"), "Remove constant columns", value = TRUE),
          checkboxInput(session$ns("prep_drop_near_zero_variance"), "Remove near-zero variance numeric columns", value = TRUE),
          numericInput(session$ns("prep_nzv_threshold"), "Near-Zero Variance Threshold", value = 0.95, min = 0.50, max = 1, step = 0.01),
          checkboxInput(session$ns("prep_drop_duplicate_columns"), "Remove duplicate columns", value = TRUE),
          checkboxInput(session$ns("prep_add_date_features"), "Add basic date features", value = TRUE),
          checkboxInput(session$ns("prep_categorical_as_factor"), "Convert text categories to factors", value = TRUE),
          checkboxInput(session$ns("prep_create_validation_split"), "Create validation split column", value = FALSE),
          numericInput(session$ns("prep_validation_fraction"), "Validation Fraction", value = 0.20, min = 0.01, max = 0.80, step = 0.01),
          numericInput(session$ns("prep_split_seed"), "Split Seed", value = 20260711, min = 1, step = 1),
          textInput(session$ns("prep_prepared_data_name"), "Prepared Dataset Name", value = "Prepared Modeling Data")
        ))
      }

      if (identical(module_id, "autoquant_regression_model_insights")) {
        return(tagList(
          selectInput(
            session$ns("rmi_target_column"),
            "Target",
            choices = numeric_choices,
            selected = if (target_default %in% numeric_choices) target_default else character()
          ),
          selectInput(
            session$ns("rmi_prediction_column"),
            "Prediction",
            choices = numeric_choices,
            selected = if (prediction_default %in% numeric_choices) prediction_default else character()
          ),
          selectInput(
            session$ns("rmi_feature_columns"),
            "Feature Columns",
            choices = choices,
            selected = intersect(feature_defaults, numeric_choices),
            multiple = TRUE
          ),
          selectInput(
            session$ns("rmi_segment_vars"),
            "Segment Vars",
            choices = c("(none)" = "", choices),
            selected = group_default,
            multiple = TRUE
          ),
          selectInput(
            session$ns("rmi_by_vars"),
            "By Vars",
            choices = c("(none)" = "", choices),
            selected = "",
            multiple = TRUE
          ),
          selectInput(
            session$ns("rmi_date_var"),
            "Date",
            choices = c("(none)" = "", choices),
            selected = date_default
          ),
          textInput(session$ns("rmi_algo"), "Algo", value = "external_predictions"),
          selectInput(
            session$ns("rmi_theme"),
            "Theme",
            choices = c("light", "dark", "pimp"),
            selected = "dark"
          ),
          numericInput(session$ns("rmi_sample_size"), "Sample Size", value = 100000, min = 1, step = 1),
          numericInput(session$ns("rmi_max_pdp_features"), "Max Feature Effect Plots", value = 10, min = 1, step = 1),
          checkboxInput(session$ns("rmi_generate_calibration_pdp"), "Generate Calibration Effects", value = FALSE),
          checkboxInput(session$ns("rmi_generate_uplift_pdp"), "Generate Uplift Effects", value = FALSE),
          checkboxInput(session$ns("rmi_generate_stratified_effects"), "Generate Stratified Effects", value = FALSE),
          checkboxInput(session$ns("rmi_detect_simpsons_paradox"), "Detect Simpsons Paradox", value = FALSE)
        ))
      }

      if (identical(module_id, "autoquant_binary_model_insights")) {
        bmi_input <- function(arg, control) {
          if (.autoquant_bmi_supports_arg(arg)) control else NULL
        }

        controls <- list(
          bmi_input("TargetColumnName", selectInput(
            session$ns("bmi_target_column"),
            "Target",
            choices = choices,
            selected = target_default
          )),
          bmi_input("PredictionColumnName", selectInput(
            session$ns("bmi_prediction_column"),
            "Prediction / Score",
            choices = numeric_choices,
            selected = if (prediction_default %in% numeric_choices) prediction_default else character()
          )),
          bmi_input("FeatureColumnNames", selectInput(
            session$ns("bmi_feature_columns"),
            "Feature Columns",
            choices = choices,
            selected = feature_defaults,
            multiple = TRUE
          )),
          bmi_input("PositiveClass", textInput(session$ns("bmi_positive_class"), "Positive Class", value = "1")),
          bmi_input("ModelID", textInput(session$ns("bmi_model_id"), "Model ID", value = "Binary Model")),
          bmi_input("SourcePath", textInput(session$ns("bmi_source_path"), "Source Path", value = "")),
          bmi_input("Theme", selectInput(
            session$ns("bmi_theme"),
            "Theme",
            choices = c("light", "dark", "pimp"),
            selected = "dark"
          )),
          bmi_input("SampleSize", numericInput(session$ns("bmi_sample_size"), "Sample Size", value = 100000, min = 1, step = 1)),
          bmi_input("Threshold", numericInput(session$ns("bmi_threshold"), "Threshold", value = 0.5, min = 0, max = 1, step = 0.01)),
          bmi_input("OptimizeMetric", selectInput(
            session$ns("bmi_optimize_metric"),
            "Optimize Metric",
            choices = .autoquant_bmi_optimize_metrics(),
            selected = "Utility"
          )),
          bmi_input("UtilityTP", numericInput(session$ns("bmi_utility_tp"), "Benefit: Correct Positive", value = 1, step = 1)),
          bmi_input("UtilityTN", numericInput(session$ns("bmi_utility_tn"), "Benefit: Correct Negative", value = 0, step = 1)),
          bmi_input("UtilityFP", numericInput(session$ns("bmi_utility_fp"), "Cost: False Positive", value = -1, step = 1)),
          bmi_input("UtilityFN", numericInput(session$ns("bmi_utility_fn"), "Cost: False Negative", value = -5, step = 1)),
          bmi_input("Beta", numericInput(session$ns("bmi_beta"), "F-Beta Weight", value = 1, min = 0.01, step = 0.1)),
          bmi_input("TrainDataInclude", checkboxInput(session$ns("bmi_train_data_include"), "Include Train Data", value = FALSE))
        )

        return(do.call(tagList, Filter(Negate(is.null), controls)))
      }

      if (identical(module_id, "autoquant_regression_shap_analysis")) {
        shap_cols <- choices[startsWith(choices, "Shap_")]
        shap_features <- sub("^Shap_", "", shap_cols)
        source_features <- intersect(shap_features, choices)
        if (!length(source_features)) {
          source_features <- setdiff(choices, c("y", "Predict", "prediction", "yhat", shap_cols))
        }
        id_defaults <- choices[grepl("(^id|id$|_id|IDCol)", choices, ignore.case = TRUE)]
        by_defaults <- intersect(c("Factor_1", "Channel", "segment", "Segment"), choices)

        return(tagList(
          textInput(session$ns("rshap_data_name"), "Data Name", value = "Uploaded Data"),
          selectInput(
            session$ns("rshap_target_col"),
            "Target",
            choices = c("(optional)" = "", numeric_choices),
            selected = if (target_default %in% numeric_choices) target_default else ""
          ),
          selectInput(
            session$ns("rshap_prediction_col"),
            "Prediction",
            choices = c("(infer Predict)" = "", numeric_choices),
            selected = if (prediction_default %in% numeric_choices) prediction_default else ""
          ),
          textInput(session$ns("rshap_shap_prefix"), "SHAP Prefix", value = "Shap_"),
          selectInput(
            session$ns("rshap_feature_cols"),
            "Feature Columns",
            choices = choices,
            selected = source_features,
            multiple = TRUE
          ),
          selectInput(
            session$ns("rshap_selected_features"),
            "Selected Features",
            choices = source_features,
            selected = head(source_features, 10L),
            multiple = TRUE
          ),
          selectInput(
            session$ns("rshap_date_var"),
            "Date",
            choices = c("(none)" = "", choices),
            selected = date_default
          ),
          selectInput(
            session$ns("rshap_date_aggregation"),
            "Date Aggregation",
            choices = c("day", "week", "month"),
            selected = "month"
          ),
          selectInput(
            session$ns("rshap_by_vars"),
            "Segment Columns",
            choices = choices,
            selected = unique(c(group_default[group_default %in% choices], by_defaults)),
            multiple = TRUE
          ),
          selectInput(
            session$ns("rshap_id_cols"),
            "ID Columns",
            choices = choices,
            selected = id_defaults,
            multiple = TRUE
          ),
          textInput(session$ns("rshap_local_row_ids"), "Local Row IDs", value = "1,2"),
          numericInput(session$ns("rshap_top_n"), "Top N", value = 20, min = 1, step = 1),
          numericInput(session$ns("rshap_max_dependence_rows"), "Max Dependence Rows", value = 5000, min = 1, step = 1),
          numericInput(session$ns("rshap_max_segment_levels"), "Max Segment Levels", value = 20, min = 1, step = 1),
          numericInput(session$ns("rshap_max_byvars"), "Max Segment Columns", value = 3, min = 1, step = 1),
          numericInput(session$ns("rshap_max_interaction_pairs"), "Max Interaction Pairs", value = 20, min = 1, step = 1),
          numericInput(session$ns("rshap_max_interaction_surface_plots"), "Max Interaction Surface Plots", value = 10, min = 1, step = 1),
          numericInput(session$ns("rshap_numeric_interaction_bins"), "Numeric Interaction Bins", value = 5, min = 2, step = 1),
          numericInput(session$ns("rshap_min_interaction_cell_n"), "Min Interaction Cell N", value = 5, min = 1, step = 1),
          checkboxInput(session$ns("rshap_include_dependence"), "Include Dependence", value = TRUE),
          checkboxInput(session$ns("rshap_include_segments"), "Include Segments", value = TRUE),
          checkboxInput(session$ns("rshap_include_time"), "Include Time", value = TRUE),
          checkboxInput(session$ns("rshap_include_local"), "Include Local Explanations", value = FALSE),
          checkboxInput(session$ns("rshap_include_interactions"), "Include Interactions", value = TRUE),
          checkboxInput(session$ns("rshap_include_plots"), "Include Plots", value = TRUE),
          checkboxInput(session$ns("rshap_include_effect_curves"), "Include Fitted Effect Curves", value = TRUE),
          selectInput(
            session$ns("rshap_effect_curve_backend"),
            "Effect Curve Method",
            choices = c("none", "autonls"),
            selected = "none"
          ),
          textInput(session$ns("rshap_effect_curve_models"), "Effect Curve Families", value = "stable"),
          numericInput(session$ns("rshap_effect_curve_sample_size"), "Effect Curve Sample Size", value = 50000, min = 10, step = 1000),
          numericInput(session$ns("rshap_effect_curve_max_features"), "Effect Curve Max Features", value = 20, min = 1, step = 1),
          numericInput(session$ns("rshap_effect_curve_validation_fraction"), "Effect Curve Validation Fraction", value = 0.20, min = 0, max = 0.5, step = 0.05),
          numericInput(session$ns("rshap_max_feature_effect_plots"), "Max Feature Effect Plots", value = 5, min = 1, step = 1),
          numericInput(session$ns("rshap_max_dependence_plots"), "Max Dependence Plots", value = 5, min = 1, step = 1),
          numericInput(session$ns("rshap_max_segment_plots"), "Max Segment Plots", value = 5, min = 1, step = 1),
          numericInput(session$ns("rshap_max_time_plots"), "Max Time Plots", value = 5, min = 1, step = 1),
          numericInput(session$ns("rshap_max_local_plots"), "Max Local Plots", value = 5, min = 1, step = 1)
        ))
      }

      if (identical(module_id, "autoquant_binary_shap_analysis")) {
        shap_cols <- choices[startsWith(choices, "Shap_")]
        shap_features <- sub("^Shap_", "", shap_cols)
        source_features <- intersect(shap_features, choices)
        if (!length(source_features)) {
          source_features <- setdiff(choices, c("Target", "target", "Predict", "prediction", "p", "p1", "PredictedClass", shap_cols))
        }
        id_defaults <- choices[grepl("(^id|id$|_id|IDCol)", choices, ignore.case = TRUE)]
        by_defaults <- intersect(c("Channel", "Region", "CustomerTier", "segment", "Segment"), choices)
        target_choices <- choices
        prediction_choices <- numeric_choices

        return(tagList(
          textInput(session$ns("bshap_data_name"), "Data Name", value = "Uploaded Data"),
          selectInput(
            session$ns("bshap_target_col"),
            "Target",
            choices = c("(required)" = "", target_choices),
            selected = if (target_default %in% target_choices) target_default else ""
          ),
          selectInput(
            session$ns("bshap_prediction_col"),
            "Prediction Probability",
            choices = c("(infer Predict)" = "", prediction_choices),
            selected = if (prediction_default %in% prediction_choices) prediction_default else ""
          ),
          selectInput(
            session$ns("bshap_predicted_class_col"),
            "Predicted Class",
            choices = c("(optional)" = "", target_choices),
            selected = if ("PredictedClass" %in% target_choices) "PredictedClass" else ""
          ),
          textInput(session$ns("bshap_positive_class"), "Positive Class", value = "Yes"),
          selectInput(
            session$ns("bshap_prediction_scale"),
            "Prediction Scale",
            choices = c("probability", "logit", "margin", "unknown"),
            selected = "probability"
          ),
          numericInput(session$ns("bshap_threshold"), "Threshold", value = 0.5, min = 0.001, max = 0.999, step = 0.01),
          textInput(session$ns("bshap_shap_prefix"), "SHAP Prefix", value = "Shap_"),
          selectInput(
            session$ns("bshap_feature_cols"),
            "Feature Columns",
            choices = choices,
            selected = source_features,
            multiple = TRUE
          ),
          selectInput(
            session$ns("bshap_selected_features"),
            "Selected Features",
            choices = source_features,
            selected = head(source_features, 10L),
            multiple = TRUE
          ),
          selectInput(
            session$ns("bshap_date_var"),
            "Date",
            choices = c("(none)" = "", choices),
            selected = date_default
          ),
          selectInput(
            session$ns("bshap_date_aggregation"),
            "Date Aggregation",
            choices = c("day", "week", "month"),
            selected = "month"
          ),
          selectInput(
            session$ns("bshap_by_vars"),
            "Segment Columns",
            choices = choices,
            selected = unique(c(group_default[group_default %in% choices], by_defaults)),
            multiple = TRUE
          ),
          selectInput(
            session$ns("bshap_id_cols"),
            "ID Columns",
            choices = choices,
            selected = id_defaults,
            multiple = TRUE
          ),
          textInput(session$ns("bshap_local_row_ids"), "Local Row IDs", value = "1,2"),
          numericInput(session$ns("bshap_top_n"), "Top N", value = 20, min = 1, step = 1),
          numericInput(session$ns("bshap_max_dependence_rows"), "Max Dependence Rows", value = 5000, min = 1, step = 1),
          numericInput(session$ns("bshap_max_segment_levels"), "Max Segment Levels", value = 20, min = 1, step = 1),
          numericInput(session$ns("bshap_max_byvars"), "Max Segment Columns", value = 3, min = 1, step = 1),
          numericInput(session$ns("bshap_max_interaction_pairs"), "Max Interaction Pairs", value = 20, min = 1, step = 1),
          numericInput(session$ns("bshap_max_interaction_surface_plots"), "Max Interaction Surface Plots", value = 10, min = 1, step = 1),
          numericInput(session$ns("bshap_numeric_interaction_bins"), "Numeric Interaction Bins", value = 5, min = 2, step = 1),
          numericInput(session$ns("bshap_min_interaction_cell_n"), "Min Interaction Cell N", value = 5, min = 1, step = 1),
          checkboxInput(session$ns("bshap_include_threshold_context"), "Include Threshold Context", value = TRUE),
          checkboxInput(session$ns("bshap_include_class_balance"), "Include Class Balance / Outcome Context", value = TRUE),
          checkboxInput(session$ns("bshap_include_dependence"), "Include Dependence", value = TRUE),
          checkboxInput(session$ns("bshap_include_segments"), "Include Segments", value = TRUE),
          checkboxInput(session$ns("bshap_include_time"), "Include Time", value = TRUE),
          checkboxInput(session$ns("bshap_include_local"), "Include Local Explanations", value = FALSE),
          checkboxInput(session$ns("bshap_include_interactions"), "Include Interactions", value = TRUE),
          checkboxInput(session$ns("bshap_include_plots"), "Include Plots", value = TRUE),
          checkboxInput(session$ns("bshap_include_effect_curves"), "Include Fitted Effect Curves", value = TRUE),
          selectInput(
            session$ns("bshap_effect_curve_backend"),
            "Effect Curve Method",
            choices = c("none", "autonls"),
            selected = "none"
          ),
          textInput(session$ns("bshap_effect_curve_models"), "Effect Curve Families", value = "stable"),
          numericInput(session$ns("bshap_effect_curve_sample_size"), "Effect Curve Sample Size", value = 50000, min = 10, step = 1000),
          numericInput(session$ns("bshap_effect_curve_max_features"), "Effect Curve Max Features", value = 20, min = 1, step = 1),
          numericInput(session$ns("bshap_effect_curve_validation_fraction"), "Effect Curve Validation Fraction", value = 0.20, min = 0, max = 0.5, step = 0.05),
          numericInput(session$ns("bshap_max_feature_effect_plots"), "Max Feature Effect Plots", value = 5, min = 1, step = 1),
          numericInput(session$ns("bshap_max_dependence_plots"), "Max Dependence Plots", value = 5, min = 1, step = 1),
          numericInput(session$ns("bshap_max_segment_plots"), "Max Segment Plots", value = 5, min = 1, step = 1),
          numericInput(session$ns("bshap_max_time_plots"), "Max Time Plots", value = 5, min = 1, step = 1),
          numericInput(session$ns("bshap_max_local_plots"), "Max Local Plots", value = 5, min = 1, step = 1)
        ))
      }

      if (identical(module_id, "autoquant_catboost_builder")) {
        catboost_target_default <- if (length(target_default) && target_default %in% choices) {
          target_default
        } else if ("Revenue" %in% choices) {
          "Revenue"
        } else if ("Target" %in% choices) {
          "Target"
        } else if (length(choices)) {
          choices[[1]]
        } else {
          ""
        }
        catboost_feature_defaults <- setdiff(choices, c(catboost_target_default))
        by_defaults <- intersect(c("Channel", "Region", "CustomerTier", "segment", "Segment"), choices)

        return(tagList(
          selectInput(
            session$ns("catboost_problem_type"),
            "Problem Type",
            choices = c("Regression" = "regression", "Binary Classification" = "binary"),
            selected = if (identical(context$problem_hint, "Binary Classification")) "binary" else "regression"
          ),
          selectInput(
            session$ns("catboost_target_col"),
            "Target",
            choices = choices,
            selected = catboost_target_default
          ),
          selectInput(
            session$ns("catboost_feature_cols"),
            "Feature Columns",
            choices = choices,
            selected = catboost_feature_defaults,
            multiple = TRUE
          ),
          textInput(session$ns("catboost_positive_class"), "Positive Class", value = "Yes"),
          selectInput(
            session$ns("catboost_date_var"),
            "Date",
            choices = c("(none)" = "", choices),
            selected = date_default
          ),
          selectInput(
            session$ns("catboost_by_vars"),
            "Segment Columns",
            choices = choices,
            selected = unique(c(group_default[group_default %in% choices], by_defaults)),
            multiple = TRUE
          ),
          numericInput(session$ns("catboost_iterations"), "Iterations", value = 100, min = 1, step = 10),
          numericInput(session$ns("catboost_depth"), "Depth", value = 6, min = 1, max = 16, step = 1),
          numericInput(session$ns("catboost_learning_rate"), "Learning Rate", value = NA, min = 0, step = 0.01),
          numericInput(session$ns("catboost_threshold"), "Threshold", value = 0.5, min = 0, max = 1, step = 0.01),
          checkboxInput(session$ns("catboost_compute_shap"), "Compute SHAP", value = TRUE)
        ))
      }

      if (module_id %in% c(
        "autoquant_multiclass_shap_analysis"
      )) {
        problem_label <- switch(
          module_id,
          autoquant_regression_shap_analysis = "Regression",
          autoquant_binary_shap_analysis = "Binary Classification",
          autoquant_multiclass_shap_analysis = "Multiclass"
        )
        return(tagList(
          ui_empty_state(
            paste(problem_label, "SHAP Analysis is scaffolded."),
            "The full SHAP configuration UI will be added when the AutoQuant generator is available."
          )
        ))
      }

      tagList(
        textInput(session$ns("eda_data_name"), "Dataset Name", value = "Uploaded Data"),
        selectInput(
          session$ns("eda_univariate_vars"),
          "Distribution Columns",
          choices = choices,
          selected = unique(c(
            target_default[target_default %in% choices],
            group_default[group_default %in% choices],
            intersect(c("Spend", "Revenue", "Clicks", "Channel"), choices)
          )),
          multiple = TRUE
        ),
        selectInput(
          session$ns("eda_corr_vars"),
          "Correlation Columns",
          choices = numeric_choices,
          selected = unique(c(
            target_default[target_default %in% numeric_choices],
            intersect(c("Spend", "Revenue", "Clicks"), numeric_choices)
          )),
          multiple = TRUE
        ),
        selectInput(
          session$ns("eda_trend_vars"),
          "Trend Columns",
          choices = numeric_choices,
          selected = unique(c(
            target_default[target_default %in% numeric_choices],
            intersect("Revenue", numeric_choices)
          )),
          multiple = TRUE
        ),
        selectInput(
          session$ns("eda_trend_date_var"),
          "Trend Date Column",
          choices = c("(none)" = "", choices),
          selected = date_default
        ),
        selectInput(
          session$ns("eda_trend_group_var"),
          "Trend Group Column",
          choices = c("(none)" = "", choices),
          selected = group_default
        ),
        selectInput(
          session$ns("eda_target_var"),
          "Target Column",
          choices = c("(none)" = "", choices),
          selected = target_default
        ),
        selectInput(
          session$ns("eda_theme"),
          "Theme",
          choices = c("light", "dark", "pimp"),
          selected = "dark"
        ),
        numericInput(session$ns("eda_max_categorical_levels"), "Max Categorical Levels", value = 25, min = 1, step = 1),
        numericInput(session$ns("eda_max_discrete_numeric_levels"), "Max Discrete Numeric Levels", value = 20, min = 1, step = 1),
        numericInput(session$ns("eda_max_correlation_pairs"), "Max Correlation Pairs To Plot", value = 25, min = 1, step = 1)
      )
    })

    eda_config <- function() {
      list(
        DataName = selected_value(input$eda_data_name) %||% "data",
        UnivariateVars = input$eda_univariate_vars %||% character(),
        CorrVars = input$eda_corr_vars %||% character(),
        TrendVars = input$eda_trend_vars %||% character(),
        TrendDateVar = selected_value(input$eda_trend_date_var),
        TrendGroupVar = selected_value(input$eda_trend_group_var),
        TargetVar = selected_value(input$eda_target_var),
        Theme = selected_value(input$eda_theme) %||% "dark",
        MaxCategoricalLevels = as.integer(input$eda_max_categorical_levels %||% 25L),
        MaxDiscreteNumericLevels = as.integer(input$eda_max_discrete_numeric_levels %||% 20L),
        MaxCorrelationPairsToPlot = as.integer(input$eda_max_correlation_pairs %||% 25L)
      )
    }

    model_readiness_config <- function() {
      list(
        assessment_problem_type = selected_value(input$assessment_problem_type) %||% "Regression",
        actual_var = selected_value(input$actual_var),
        prediction_var = selected_value(input$prediction_var),
        predicted_class_var = selected_value(input$predicted_class_var),
        positive_class = selected_value(input$positive_class),
        date_var = selected_value(input$assessment_date_var),
        group_var = selected_value(input$assessment_group_var),
        model_name = selected_value(input$model_name) %||% "Model",
        artifact_section = selected_value(input$artifact_section) %||% "Model Readiness",
        theme = selected_value(input$assessment_theme) %||% "dark",
        max_rows = as.integer(input$assessment_max_rows %||% 1000L),
        max_groups = as.integer(input$assessment_max_groups %||% 25L)
      )
    }

    feature_preparation_config <- function() {
      list(
        include_columns = feature_prep_clean_choices(input$prep_include_columns),
        exclude_columns = feature_prep_clean_choices(input$prep_exclude_columns),
        target_col = selected_value(input$prep_target_col),
        date_col = selected_value(input$prep_date_col),
        group_cols = feature_prep_clean_choices(input$prep_group_cols),
        missing_method = selected_value(input$prep_missing_method) %||% "median_mode",
        drop_constant = isTRUE(input$prep_drop_constant),
        drop_near_zero_variance = isTRUE(input$prep_drop_near_zero_variance),
        near_zero_variance_threshold = as.numeric(input$prep_nzv_threshold %||% 0.95),
        drop_duplicate_columns = isTRUE(input$prep_drop_duplicate_columns),
        add_date_features = isTRUE(input$prep_add_date_features),
        categorical_as_factor = isTRUE(input$prep_categorical_as_factor),
        create_validation_split = isTRUE(input$prep_create_validation_split),
        validation_fraction = as.numeric(input$prep_validation_fraction %||% 0.20),
        split_seed = as.integer(input$prep_split_seed %||% 20260711L),
        prepared_data_name = selected_value(input$prep_prepared_data_name) %||% "Prepared Modeling Data"
      )
    }

    regression_model_insights_config <- function() {
      clean_choices <- function(value) {
        value <- value %||% character()
        value[nzchar(value)]
      }

      list(
        target_column = selected_value(input$rmi_target_column),
        prediction_column = selected_value(input$rmi_prediction_column),
        feature_columns = clean_choices(input$rmi_feature_columns),
        segment_vars = clean_choices(input$rmi_segment_vars),
        by_vars = clean_choices(input$rmi_by_vars),
        date_var = selected_value(input$rmi_date_var),
        algo = selected_value(input$rmi_algo) %||% "external_predictions",
        theme = selected_value(input$rmi_theme) %||% "dark",
        sample_size = as.integer(input$rmi_sample_size %||% 100000L),
        max_pdp_features = as.integer(input$rmi_max_pdp_features %||% 10L),
        generate_calibration_pdp = isTRUE(input$rmi_generate_calibration_pdp),
        generate_uplift_pdp = isTRUE(input$rmi_generate_uplift_pdp),
        generate_stratified_effects = isTRUE(input$rmi_generate_stratified_effects),
        detect_simpsons_paradox = isTRUE(input$rmi_detect_simpsons_paradox)
      )
    }

    binary_model_insights_config <- function() {
      clean_choices <- function(value) {
        value <- value %||% character()
        value[nzchar(value)]
      }

      list(
        train_data_include = isTRUE(input$bmi_train_data_include),
        feature_columns = clean_choices(input$bmi_feature_columns),
        sample_size = as.integer(input$bmi_sample_size %||% 100000L),
        model_id = selected_value(input$bmi_model_id) %||% "Binary Model",
        source_path = selected_value(input$bmi_source_path),
        prediction_column = selected_value(input$bmi_prediction_column),
        target_column = selected_value(input$bmi_target_column),
        positive_class = selected_value(input$bmi_positive_class),
        threshold = as.numeric(input$bmi_threshold %||% 0.5),
        optimize_metric = selected_value(input$bmi_optimize_metric) %||% "Utility",
        utility_tp = as.numeric(input$bmi_utility_tp %||% 1),
        utility_tn = as.numeric(input$bmi_utility_tn %||% 0),
        utility_fp = as.numeric(input$bmi_utility_fp %||% -1),
        utility_fn = as.numeric(input$bmi_utility_fn %||% -5),
        beta = as.numeric(input$bmi_beta %||% 1),
        theme = selected_value(input$bmi_theme) %||% "dark"
      )
    }

    regression_shap_config <- function() {
      clean_choices <- function(value) {
        value <- value %||% character()
        value <- value[nzchar(value)]
        as.character(value)
      }
      local_row_ids <- suppressWarnings(as.integer(unlist(strsplit(selected_value(input$rshap_local_row_ids) %||% "", "[,\\s]+"))))
      local_row_ids <- local_row_ids[!is.na(local_row_ids) & local_row_ids > 0L]

      create_shap_analysis_config(
        problem_type = "regression",
        data_name = selected_value(input$rshap_data_name) %||% "Uploaded Data",
        target_col = selected_value(input$rshap_target_col),
        prediction_col = selected_value(input$rshap_prediction_col),
        feature_cols = clean_choices(input$rshap_feature_cols),
        shap_prefix = selected_value(input$rshap_shap_prefix) %||% "Shap_",
        id_cols = clean_choices(input$rshap_id_cols),
        prediction_scale = "response",
        DateVar = selected_value(input$rshap_date_var),
        date_aggregation = selected_value(input$rshap_date_aggregation) %||% "month",
        ByVars = clean_choices(input$rshap_by_vars),
        selected_features = clean_choices(input$rshap_selected_features),
        local_row_ids = local_row_ids,
        top_n = as.integer(input$rshap_top_n %||% 20L),
        max_dependence_rows = as.integer(input$rshap_max_dependence_rows %||% 5000L),
        max_segment_levels = as.integer(input$rshap_max_segment_levels %||% 20L),
        max_byvars = as.integer(input$rshap_max_byvars %||% 3L),
        include_dependence = isTRUE(input$rshap_include_dependence),
        include_segments = isTRUE(input$rshap_include_segments),
        include_time = isTRUE(input$rshap_include_time),
        include_local = isTRUE(input$rshap_include_local),
        include_interactions = isTRUE(input$rshap_include_interactions),
        include_plots = isTRUE(input$rshap_include_plots),
        include_effect_curves = isTRUE(input$rshap_include_effect_curves),
        effect_curve_backend = selected_value(input$rshap_effect_curve_backend) %||% "none",
        effect_curve_models = clean_choices(unlist(strsplit(selected_value(input$rshap_effect_curve_models) %||% "stable", "[,[:space:]]+"))),
        effect_curve_sample_size = as.integer(input$rshap_effect_curve_sample_size %||% 50000L),
        effect_curve_max_features = as.integer(input$rshap_effect_curve_max_features %||% 20L),
        effect_curve_validation_fraction = as.numeric(input$rshap_effect_curve_validation_fraction %||% 0.20),
        max_feature_effect_plots = as.integer(input$rshap_max_feature_effect_plots %||% 5L),
        max_dependence_plots = as.integer(input$rshap_max_dependence_plots %||% 5L),
        max_segment_plots = as.integer(input$rshap_max_segment_plots %||% 5L),
        max_time_plots = as.integer(input$rshap_max_time_plots %||% 5L),
        max_local_plots = as.integer(input$rshap_max_local_plots %||% 5L),
        max_interaction_pairs = as.integer(input$rshap_max_interaction_pairs %||% 20L),
        max_interaction_surface_plots = as.integer(input$rshap_max_interaction_surface_plots %||% 10L),
        numeric_interaction_bins = as.integer(input$rshap_numeric_interaction_bins %||% 5L),
        min_interaction_cell_n = as.integer(input$rshap_min_interaction_cell_n %||% 5L)
      )
    }

    binary_shap_config <- function() {
      clean_choices <- function(value) {
        value <- value %||% character()
        value <- value[nzchar(value)]
        as.character(value)
      }
      local_row_ids <- suppressWarnings(as.integer(unlist(strsplit(selected_value(input$bshap_local_row_ids) %||% "", "[,\\s]+"))))
      local_row_ids <- local_row_ids[!is.na(local_row_ids) & local_row_ids > 0L]

      create_shap_analysis_config(
        problem_type = "binary_classification",
        data_name = selected_value(input$bshap_data_name) %||% "Uploaded Data",
        target_col = selected_value(input$bshap_target_col),
        prediction_col = selected_value(input$bshap_prediction_col),
        predicted_class_col = selected_value(input$bshap_predicted_class_col),
        positive_class = selected_value(input$bshap_positive_class),
        prediction_scale = selected_value(input$bshap_prediction_scale) %||% "probability",
        threshold = as.numeric(input$bshap_threshold %||% 0.5),
        feature_cols = clean_choices(input$bshap_feature_cols),
        shap_prefix = selected_value(input$bshap_shap_prefix) %||% "Shap_",
        id_cols = clean_choices(input$bshap_id_cols),
        DateVar = selected_value(input$bshap_date_var),
        date_aggregation = selected_value(input$bshap_date_aggregation) %||% "month",
        ByVars = clean_choices(input$bshap_by_vars),
        selected_features = clean_choices(input$bshap_selected_features),
        local_row_ids = local_row_ids,
        top_n = as.integer(input$bshap_top_n %||% 20L),
        max_dependence_rows = as.integer(input$bshap_max_dependence_rows %||% 5000L),
        max_segment_levels = as.integer(input$bshap_max_segment_levels %||% 20L),
        max_byvars = as.integer(input$bshap_max_byvars %||% 3L),
        include_threshold_context = isTRUE(input$bshap_include_threshold_context),
        include_class_balance = isTRUE(input$bshap_include_class_balance),
        include_dependence = isTRUE(input$bshap_include_dependence),
        include_segments = isTRUE(input$bshap_include_segments),
        include_time = isTRUE(input$bshap_include_time),
        include_local = isTRUE(input$bshap_include_local),
        include_interactions = isTRUE(input$bshap_include_interactions),
        include_plots = isTRUE(input$bshap_include_plots),
        include_effect_curves = isTRUE(input$bshap_include_effect_curves),
        effect_curve_backend = selected_value(input$bshap_effect_curve_backend) %||% "none",
        effect_curve_models = clean_choices(unlist(strsplit(selected_value(input$bshap_effect_curve_models) %||% "stable", "[,[:space:]]+"))),
        effect_curve_sample_size = as.integer(input$bshap_effect_curve_sample_size %||% 50000L),
        effect_curve_max_features = as.integer(input$bshap_effect_curve_max_features %||% 20L),
        effect_curve_validation_fraction = as.numeric(input$bshap_effect_curve_validation_fraction %||% 0.20),
        max_feature_effect_plots = as.integer(input$bshap_max_feature_effect_plots %||% 5L),
        max_dependence_plots = as.integer(input$bshap_max_dependence_plots %||% 5L),
        max_segment_plots = as.integer(input$bshap_max_segment_plots %||% 5L),
        max_time_plots = as.integer(input$bshap_max_time_plots %||% 5L),
        max_local_plots = as.integer(input$bshap_max_local_plots %||% 5L),
        max_interaction_pairs = as.integer(input$bshap_max_interaction_pairs %||% 20L),
        max_interaction_surface_plots = as.integer(input$bshap_max_interaction_surface_plots %||% 10L),
        numeric_interaction_bins = as.integer(input$bshap_numeric_interaction_bins %||% 5L),
        min_interaction_cell_n = as.integer(input$bshap_min_interaction_cell_n %||% 5L)
      )
    }

    catboost_builder_config <- function() {
      clean_choices <- function(value) {
        value <- value %||% character()
        value <- value[nzchar(value)]
        as.character(value)
      }

      normalize_catboost_builder_config(list(
        problem_type = selected_value(input$catboost_problem_type) %||% "regression",
        target_col = selected_value(input$catboost_target_col),
        feature_cols = clean_choices(input$catboost_feature_cols),
        positive_class = selected_value(input$catboost_positive_class),
        DateVar = selected_value(input$catboost_date_var),
        ByVars = clean_choices(input$catboost_by_vars),
        iterations = as.integer(input$catboost_iterations %||% 100L),
        depth = as.integer(input$catboost_depth %||% 6L),
        learning_rate = as.numeric(input$catboost_learning_rate %||% NA_real_),
        threshold = as.numeric(input$catboost_threshold %||% 0.5),
        compute_shap = isTRUE(input$catboost_compute_shap),
        include_plots = TRUE,
        top_n = 20L
      ))
    }

    shap_scaffold_config <- function(module_id) {
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      choices <- if (is.null(data)) character() else names(data)
      numeric_choices <- if (is.null(data)) {
        character()
      } else {
        names(data)[vapply(data, is.numeric, logical(1))]
      }
      problem_type <- switch(
        module_id,
        autoquant_regression_shap_analysis = "regression",
        autoquant_binary_shap_analysis = "binary_classification",
        autoquant_multiclass_shap_analysis = "multiclass",
        "regression"
      )
      target_default <- if (identical(problem_type, "binary_classification")) {
        if ("target" %in% choices) "target" else if ("y" %in% choices) "y" else NULL
      } else {
        if ("y" %in% numeric_choices) "y" else {
          first_numeric <- numeric_choices[1]
          if (is.na(first_numeric)) NULL else first_numeric
        }
      }

      create_shap_analysis_config(
        problem_type = problem_type,
        target_var = target_default,
        feature_vars = setdiff(choices, c(target_default, "prediction", "Predict", "yhat", "p", "p1")),
        prediction_type = if (identical(problem_type, "binary_classification")) "probability" else "response",
        positive_class = if (identical(problem_type, "binary_classification")) "1" else NULL,
        date_var = if ("Date" %in% choices) "Date" else if ("date" %in% choices) "date" else NULL,
        date_aggregation = "month",
        by_vars = intersect(c("Channel", "segment"), choices),
        sample_size = 10000L,
        max_features = 20L,
        max_interaction_pairs = 10L
      )
    }

    module_config <- function(module_id) {
      if (identical(module_id, "model_assessment")) {
        config <- model_readiness_config()
        config$artifact_section <- "Model Assessment"
        return(config)
      }
      if (identical(module_id, "autoquant_model_readiness")) {
        return(model_readiness_config())
      }
      if (identical(module_id, "feature_engineering_model_prep")) {
        return(feature_preparation_config())
      }
      if (identical(module_id, "autoquant_regression_model_insights")) {
        return(regression_model_insights_config())
      }
      if (identical(module_id, "autoquant_binary_model_insights")) {
        return(binary_model_insights_config())
      }
      if (identical(module_id, "autoquant_regression_shap_analysis")) {
        return(regression_shap_config())
      }
      if (identical(module_id, "autoquant_binary_shap_analysis")) {
        return(binary_shap_config())
      }
      if (identical(module_id, "autoquant_catboost_builder")) {
        config <- catboost_builder_config()
        config$modeling_context <- ctx$current_modeling_context()
        return(config)
      }
      if (identical(module_id, "autoquant_multiclass_shap_analysis")) {
        return(shap_scaffold_config(module_id))
      }

      eda_config()
    }

    open_analysis_module <- function(module_id) {
      module_id <- normalize_module_id(module_id)
      updateSelectInput(session, "analysis_module_id", selected = module_id)
      if (is.function(ctx$select_analysis_module)) {
        ctx$select_analysis_module(module_id)
      }
    }

    ctx$genai_registered_analysis_config <- function(module_id) {
      module_id <- normalize_module_id(module_id)
      if (identical(module_id, "model_assessment")) {
        return(module_config("model_assessment"))
      }
      if (identical(module_id, "dataset_profile")) {
        return(genai_registered_analysis_default_config("dataset_profile"))
      }
      module_config(module_id)
    }

    accept_module_result <- function(result) {
      if (identical(result$status, "success") && length(result$artifacts)) {
        ctx$add_artifacts(result$artifacts)
        ctx$add_report_plans(result$metadata$report_plans %||% list())
      }
      module_id <- result$metadata$module_id %||% selected_value(input$analysis_module_id) %||% "unknown_module"
      collector_result <- ctx$append_module_result_to_collector(result, module_id = module_id)
      if (!identical(collector_result$status, "success")) {
        result$warnings <- unique(c(
          result$warnings %||% character(),
          paste("Project Artifact Collector warning:", paste(collector_result$errors %||% collector_result$warnings %||% character(), collapse = " | "))
        ))
      }
      invisible(result)
    }

    current_catboost_handoff <- reactive({
      result <- module_result()
      if (is.null(result) ||
          !identical(result$metadata$module_id, "autoquant_catboost_builder") ||
          is.null(result$metadata$catboost_handoff)) {
        return(NULL)
      }
      result$metadata$catboost_handoff
    })

    current_prepared_dataset_artifact_id <- reactive({
      result <- module_result()
      if (is.null(result) ||
          !identical(result$metadata$module_id, "feature_engineering_model_prep") ||
          !identical(result$status, "success")) {
        return(NA_character_)
      }
      feature_preparation_prepared_artifact_id(result)
    })

    run_catboost_handoff_action <- function(module_id) {
      handoff <- current_catboost_handoff()
      if (is.null(handoff)) {
        result <- service_result(
          status = "error",
          errors = "Run CatBoost Builder successfully before using downstream handoff actions.",
          metadata = list(
            error_code = "CATBOOST_HANDOFF_MISSING",
            module_id = module_id
          )
        )
      } else {
        result <- run_catboost_downstream_handoff(handoff, module_id)
      }
      handoff_result(result)
      accept_module_result(result)
      invisible(result)
    }

    observeEvent(input$run_analysis_module, {
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      module_id <- selected_value(input$analysis_module_id) %||% "autoquant_eda"
      result <- run_analysis_module(
        module_id = module_id,
        data = data,
        config = module_config(module_id)
      )
      module_result(result)
      handoff_result(NULL)
      accept_module_result(result)
    }, ignoreInit = TRUE)

    observeEvent(input$run_catboost_model_assessment, {
      run_catboost_handoff_action("model_assessment")
    }, ignoreInit = TRUE)

    observeEvent(input$run_catboost_model_insights, {
      handoff <- current_catboost_handoff()
      if (is.null(handoff)) {
        run_catboost_handoff_action("autoquant_regression_model_insights")
        return(invisible(NULL))
      }
      problem_type <- .autoquant_catboost_problem_type(handoff$problem_type %||% "regression")
      module_id <- if (identical(problem_type, "binary")) {
        "autoquant_binary_model_insights"
      } else {
        "autoquant_regression_model_insights"
      }
      run_catboost_handoff_action(module_id)
    }, ignoreInit = TRUE)

    observeEvent(input$run_catboost_shap_analysis, {
      handoff <- current_catboost_handoff()
      if (is.null(handoff)) {
        run_catboost_handoff_action("autoquant_regression_shap_analysis")
        return(invisible(NULL))
      }
      problem_type <- .autoquant_catboost_problem_type(handoff$problem_type %||% "regression")
      module_id <- if (identical(problem_type, "binary")) {
        "autoquant_binary_shap_analysis"
      } else {
        "autoquant_regression_shap_analysis"
      }
      run_catboost_handoff_action(module_id)
    }, ignoreInit = TRUE)

    output$analysis_module_status <- renderUI({
      result <- module_result()
      if (is.null(result)) {
        return(ui_empty_state("No analysis module has been run yet."))
      }

      module_id <- result$metadata$module_id %||% selected_value(input$analysis_module_id) %||% "unknown_module"
      next_action <- analysis_module_next_action(module_id, result)
      next_action_ui <- ui_callout(
        next_action$title,
        next_action$message,
        status = next_action$status,
        actions = if (!is.na(next_action$next_module %||% NA_character_)) {
          actionButton(session$ns("open_next_analysis_module"), next_action$button_label, class = "btn-secondary btn-sm")
        } else {
          NULL
        }
      )

      status <- if (identical(result$status, "success")) "success" else if (identical(result$status, "error")) "error" else "warning"
      summary <- analysis_module_status_table(result)
      details <- NULL
      if (nrow(summary) && identical(result$status, "success")) {
        details <- tags$dl(
          class = "aq-module-run-summary",
          tags$dt("Artifacts"),
          tags$dd(summary$artifact_count[[1]]),
          tags$dt("Plots"),
          tags$dd(summary$plot_count[[1]]),
          tags$dt("Tables"),
          tags$dd(summary$table_count[[1]]),
          tags$dt("Text"),
          tags$dd(summary$text_count[[1]]),
          tags$dt("Report Plans"),
          tags$dd(summary$report_plan_count[[1]])
        )
      }

      tags$div(
        ui_status_badge(result$status, status = status),
        tags$p(class = "aq-export-message", service_result_message(result)),
        details,
        next_action_ui,
        if (identical(result$status, "success")) {
          tags$div(
            if (identical(module_id, "feature_engineering_model_prep")) {
              ui_callout(
                "Prepared dataset handoff",
                "Use the prepared dataset as the active modeling dataset before training. The source dataset is not mutated.",
                status = "success",
                actions = ui_action_row(
                  actionButton(session$ns("activate_prepared_dataset"), "Use Prepared Dataset", class = "btn-primary btn-sm"),
                  actionButton(session$ns("activate_prepared_dataset_and_open_catboost"), "Use and Open CatBoost", class = "btn-secondary btn-sm"),
                  actionButton(session$ns("revert_to_source_dataset"), "Revert to Source Data", class = "btn-secondary btn-sm")
                )
              )
            },
            ui_action_row(
              actionButton(session$ns("open_artifact_studio_after_run"), "Inspect in Artifact Studio", class = "btn-primary btn-sm"),
              actionButton(session$ns("open_export_after_run"), "Open Export", class = "btn-secondary btn-sm"),
              actionButton(session$ns("open_mission_control_after_run"), "Return to Mission Control", class = "btn-secondary btn-sm")
            )
          )
        }
      )
    })

    observeEvent(input$open_next_analysis_module, {
      result <- module_result()
      if (is.null(result)) {
        return(invisible(NULL))
      }
      module_id <- result$metadata$module_id %||% selected_value(input$analysis_module_id) %||% "autoquant_eda"
      next_action <- analysis_module_next_action(module_id, result)
      if (!is.na(next_action$next_module %||% NA_character_)) {
        open_analysis_module(next_action$next_module)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$activate_prepared_dataset, {
      artifact_id <- current_prepared_dataset_artifact_id()
      if (is.na(artifact_id) || !nzchar(artifact_id)) {
        showNotification("No prepared dataset artifact is available to activate.", type = "error")
        return(invisible(NULL))
      }
      result <- ctx$activate_prepared_dataset_artifact(artifact_id)
      showNotification(service_result_message(result), type = if (identical(result$status, "success")) "message" else "error")
    }, ignoreInit = TRUE)

    observeEvent(input$activate_prepared_dataset_and_open_catboost, {
      artifact_id <- current_prepared_dataset_artifact_id()
      if (is.na(artifact_id) || !nzchar(artifact_id)) {
        showNotification("No prepared dataset artifact is available to activate.", type = "error")
        return(invisible(NULL))
      }
      result <- ctx$activate_prepared_dataset_artifact(artifact_id)
      showNotification(service_result_message(result), type = if (identical(result$status, "success")) "message" else "error")
      if (identical(result$status, "success")) {
        open_analysis_module("autoquant_catboost_builder")
      }
    }, ignoreInit = TRUE)

    observeEvent(input$revert_to_source_dataset, {
      result <- ctx$revert_to_source_dataset()
      showNotification(service_result_message(result), type = if (identical(result$status, "success")) "message" else "error")
    }, ignoreInit = TRUE)

    observeEvent(input$open_artifact_studio_after_run, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Artifact Studio")
    }, ignoreInit = TRUE)

    observeEvent(input$open_export_after_run, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Export")
    }, ignoreInit = TRUE)

    observeEvent(input$open_mission_control_after_run, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Mission Control")
    }, ignoreInit = TRUE)

    output$catboost_handoff_panel <- renderUI({
      handoff <- current_catboost_handoff()
      if (is.null(handoff)) {
        return(NULL)
      }

      validation <- validate_catboost_handoff(handoff)
      available <- validation$metadata$available_downstream_modules %||% character()
      problem_type <- .autoquant_catboost_problem_type(handoff$problem_type %||% "regression")
      summary <- handoff$scored_data_summary %||% data.table::data.table(
        rows = 0L,
        cols = 0L,
        shap_cols = 0L
      )
      run_result <- handoff_result()
      run_status <- NULL
      if (!is.null(run_result)) {
        run_status <- tags$div(
          class = "aq-control-group",
          ui_status_badge(run_result$status, status = if (identical(run_result$status, "success")) "success" else if (identical(run_result$status, "error")) "error" else "warning"),
          tags$p(class = "aq-export-message", service_result_message(run_result))
        )
      }

      action_buttons <- list()
      if ("model_assessment" %in% available) {
        action_buttons <- c(action_buttons, list(
          actionButton(session$ns("run_catboost_model_assessment"), "Run Model Assessment", class = "btn-secondary")
        ))
      }
      if (any(c("autoquant_regression_model_insights", "autoquant_binary_model_insights") %in% available)) {
        insights_label <- if (identical(problem_type, "binary")) {
          "Run Binary Model Insights"
        } else {
          "Run Regression Model Insights"
        }
        action_buttons <- c(action_buttons, list(
          actionButton(session$ns("run_catboost_model_insights"), insights_label, class = "btn-secondary")
        ))
      }
      if (any(c("autoquant_regression_shap_analysis", "autoquant_binary_shap_analysis") %in% available)) {
        shap_label <- if (identical(problem_type, "binary")) {
          "Run Binary SHAP"
        } else {
          "Run Regression SHAP"
        }
        action_buttons <- c(action_buttons, list(
          actionButton(session$ns("run_catboost_shap_analysis"), shap_label, class = "btn-success")
        ))
      }

      warnings <- validation$warnings %||% character()
      warning_ui <- if (length(warnings)) {
        tags$ul(class = "aq-muted-list", lapply(warnings, tags$li))
      } else {
        NULL
      }

      tags$div(
        class = "aq-catboost-handoff-panel",
        ui_section_header(
          "CatBoost Downstream Handoff",
          "Run downstream modules from the scored CatBoost output when you choose."
        ),
        tags$dl(
          class = "aq-module-run-summary",
          tags$dt("Problem Type"),
          tags$dd(if (identical(problem_type, "binary")) "Binary Classification" else "Regression"),
          tags$dt("Scored Rows"),
          tags$dd(summary$rows[[1]] %||% 0L),
          tags$dt("Scored Columns"),
          tags$dd(summary$cols[[1]] %||% 0L),
          tags$dt("SHAP Columns"),
          tags$dd(summary$shap_cols[[1]] %||% 0L),
          tags$dt("Available Actions"),
          tags$dd(if (length(available)) paste(vapply(available, .catboost_downstream_module_label, character(1)), collapse = ", ") else "None")
        ),
        warning_ui,
        if (length(action_buttons)) {
          do.call(ui_action_row, action_buttons)
        } else {
          ui_empty_state("No downstream actions are available for this CatBoost output.")
        },
        run_status
      )
    })

    output$analysis_module_code <- renderText({
      result <- module_result()
      if (is.null(result) || is.null(result$code)) {
        return("")
      }

      result$code
    })
  })
}

qa_analytical_workflow_integration <- function() {
  sample_data <- data.frame(
    event_date = as.Date("2026-01-01") + 0:5,
    channel = rep(c("Search", "Social"), 3),
    spend = c(10, 20, 15, 18, 22, 19),
    revenue = c(100, 150, 130, 170, 180, 160),
    prediction = c(98, 148, 129, 169, 181, 159),
    Shap_spend = c(1, 2, 1, 3, 2, 1)
  )
  context <- analysis_context_from_data(sample_data)
  eda_next <- analysis_module_next_action("autoquant_eda")
  readiness_next <- analysis_module_next_action("autoquant_model_readiness")
  preparation_next <- analysis_module_next_action("feature_engineering_model_prep")
  failed_next <- analysis_module_next_action(
    "autoquant_eda",
    service_result(status = "error", errors = "qa failure")
  )
  page <- paste(readLines("R/page_analysis_modules.R", warn = FALSE), collapse = "\n")

  data.table::data.table(
    check = c(
      "context_detects_dataset",
      "context_detects_target",
      "context_detects_prediction",
      "context_detects_date_group",
      "context_detects_shap_columns",
      "context_panel_rendered",
      "next_action_eda_to_readiness",
      "next_action_readiness_to_feature_preparation",
      "next_action_feature_preparation_to_catboost",
      "feature_preparation_activation_buttons_wired",
      "source_dataset_revert_action_wired",
      "prepared_dataset_context_activation_wired",
      "failure_next_action_blocks_progression",
      "open_next_module_action_wired",
      "dark_theme_fallbacks_consistent"
    ),
    status = c(
      if (isTRUE(context$has_data) && identical(context$rows, 6L) && identical(context$columns, 6L)) "success" else "error",
      if (identical(context$target, "revenue")) "success" else "error",
      if (identical(context$prediction, "prediction")) "success" else "error",
      if (identical(context$date, "event_date") && identical(context$group, "channel")) "success" else "error",
      if (identical(context$shap_columns, "Shap_spend")) "success" else "error",
      if (grepl("analysis_context_panel", page, fixed = TRUE) && grepl("Context for", page, fixed = TRUE)) "success" else "error",
      if (identical(eda_next$next_module, "autoquant_model_readiness")) "success" else "error",
      if (identical(readiness_next$next_module, "feature_engineering_model_prep")) "success" else "error",
      if (identical(preparation_next$next_module, "autoquant_catboost_builder")) "success" else "error",
      if (grepl("activate_prepared_dataset", page, fixed = TRUE) &&
          grepl("Use Prepared Dataset", page, fixed = TRUE) &&
          grepl("Use and Open CatBoost", page, fixed = TRUE)) "success" else "error",
      if (grepl("revert_to_source_dataset", page, fixed = TRUE) &&
          grepl("Revert to Source Data", page, fixed = TRUE)) "success" else "error",
      if (grepl("current_prepared_dataset_artifact_id", page, fixed = TRUE) &&
          grepl("ctx$activate_prepared_dataset_artifact", page, fixed = TRUE)) "success" else "error",
      if (identical(failed_next$status, "error") && is.na(failed_next$next_module)) "success" else "error",
      if (grepl("open_next_analysis_module", page, fixed = TRUE) && grepl("open_analysis_module <- function", page, fixed = TRUE)) "success" else "error",
      if (all(grepl('theme = selected_value\\(input\\$(assessment_theme|rmi_theme|bmi_theme)\\) %\\|\\|% "dark"', page))) "success" else "error"
    ),
    message = c(
      "Dataset context captures rows and columns.",
      "Dataset context detects a reusable target column.",
      "Dataset context detects a reusable prediction column.",
      "Dataset context detects reusable date and group columns.",
      "Dataset context detects SHAP columns for downstream interpretation.",
      "Analysis Modules renders a visible context-preservation panel.",
      "Explore Data naturally leads to Model Readiness.",
      "Model Readiness naturally leads to Feature Engineering / Model Preparation.",
      "Feature Engineering / Model Preparation naturally leads to CatBoost Builder.",
      "Feature Preparation exposes explicit prepared-dataset activation actions.",
      "Feature Preparation exposes an explicit source-dataset revert action.",
      "Prepared dataset activation is wired through app context instead of silent dataset mutation.",
      "Failed runs recommend resolving issues instead of continuing blindly.",
      "The next-module action is wired without adding a workflow engine.",
      "Module theme fallbacks match the visible dark-first defaults."
    )
  )
}
