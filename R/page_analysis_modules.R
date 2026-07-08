page_analysis_modules_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Analysis Modules",
    ui_page(
      title = "Analysis Modules",
      tags$div(
        class = "aq-export-layout",
        ui_card(
          title = "Module Settings",
          selectInput(
            ns("analysis_module_id"),
            "Module",
            choices = c(
              "AutoQuant EDA" = "autoquant_eda",
              "AutoQuant Model Readiness" = "autoquant_model_readiness",
              "AutoQuant Regression Model Insights" = "autoquant_regression_model_insights",
              "AutoQuant Binary Classification Model Insights" = "autoquant_binary_model_insights",
              "AutoQuant Regression SHAP Analysis" = "autoquant_regression_shap_analysis",
              "AutoQuant Binary Classification SHAP Analysis" = "autoquant_binary_shap_analysis",
              "AutoQuant CatBoost Builder" = "autoquant_catboost_builder",
              "AutoQuant Multiclass SHAP Analysis" = "autoquant_multiclass_shap_analysis"
            ),
            selected = "autoquant_eda"
          ),
          uiOutput(ns("analysis_module_settings")),
          ui_action_row(
            actionButton(ns("run_analysis_module"), "Run Module", class = "btn-primary")
          )
        ),
        ui_card(
          title = "Run Status",
          uiOutput(ns("analysis_module_status")),
          uiOutput(ns("catboost_handoff_panel")),
          ui_code_panel(
            "Generated Code",
            verbatimTextOutput(ns("analysis_module_code")),
            collapsed = FALSE
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

    output$analysis_module_settings <- renderUI({
      module_id <- selected_value(input$analysis_module_id) %||% "autoquant_eda"
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      choices <- if (is.null(data)) character() else names(data)
      numeric_choices <- if (is.null(data)) {
        character()
      } else {
        names(data)[vapply(data, is.numeric, logical(1))]
      }

      if (identical(module_id, "autoquant_model_readiness")) {
        return(tagList(
          selectInput(
            session$ns("assessment_problem_type"),
            "Problem Type",
            choices = c("Regression", "Binary Classification"),
            selected = "Regression"
          ),
          selectInput(
            session$ns("actual_var"),
            "Actual",
            choices = choices,
            selected = if ("y" %in% choices) "y" else character()
          ),
          selectInput(
            session$ns("prediction_var"),
            "Prediction / Score",
            choices = numeric_choices,
            selected = if ("yhat" %in% numeric_choices) "yhat" else if ("p" %in% numeric_choices) "p" else character()
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
            selected = if ("Date" %in% choices) "Date" else ""
          ),
          selectInput(
            session$ns("assessment_group_var"),
            "Group",
            choices = c("(none)" = "", choices),
            selected = if ("Channel" %in% choices) "Channel" else ""
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

      if (identical(module_id, "autoquant_regression_model_insights")) {
        return(tagList(
          selectInput(
            session$ns("rmi_target_column"),
            "Target",
            choices = numeric_choices,
            selected = if ("y" %in% numeric_choices) "y" else character()
          ),
          selectInput(
            session$ns("rmi_prediction_column"),
            "Prediction",
            choices = numeric_choices,
            selected = if ("Predict" %in% numeric_choices) "Predict" else if ("yhat" %in% numeric_choices) "yhat" else character()
          ),
          selectInput(
            session$ns("rmi_feature_columns"),
            "Feature Columns",
            choices = choices,
            selected = setdiff(numeric_choices, c("y", "Predict", "yhat", "p")),
            multiple = TRUE
          ),
          selectInput(
            session$ns("rmi_segment_vars"),
            "Segment Vars",
            choices = c("(none)" = "", choices),
            selected = if ("segment" %in% choices) "segment" else if ("Channel" %in% choices) "Channel" else "",
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
            selected = if ("date" %in% choices) "date" else if ("Date" %in% choices) "Date" else ""
          ),
          textInput(session$ns("rmi_algo"), "Algo", value = "external_predictions"),
          selectInput(
            session$ns("rmi_theme"),
            "Theme",
            choices = c("light", "dark", "pimp"),
            selected = "dark"
          ),
          numericInput(session$ns("rmi_sample_size"), "Sample Size", value = 100000, min = 1, step = 1),
          numericInput(session$ns("rmi_max_pdp_features"), "Max PDP Features", value = 10, min = 1, step = 1),
          checkboxInput(session$ns("rmi_generate_calibration_pdp"), "Generate Calibration PDP", value = FALSE),
          checkboxInput(session$ns("rmi_generate_uplift_pdp"), "Generate Uplift PDP", value = FALSE),
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
            selected = if ("target" %in% choices) "target" else if ("y" %in% choices) "y" else character()
          )),
          bmi_input("PredictionColumnName", selectInput(
            session$ns("bmi_prediction_column"),
            "Prediction / Score",
            choices = numeric_choices,
            selected = if ("p1" %in% numeric_choices) "p1" else if ("p" %in% numeric_choices) "p" else character()
          )),
          bmi_input("FeatureColumnNames", selectInput(
            session$ns("bmi_feature_columns"),
            "Feature Columns",
            choices = choices,
            selected = setdiff(choices, c("target", "y", "p1", "p", "Predict", "yhat")),
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
          bmi_input("UtilityTP", numericInput(session$ns("bmi_utility_tp"), "Utility TP", value = 1, step = 1)),
          bmi_input("UtilityTN", numericInput(session$ns("bmi_utility_tn"), "Utility TN", value = 0, step = 1)),
          bmi_input("UtilityFP", numericInput(session$ns("bmi_utility_fp"), "Utility FP", value = -1, step = 1)),
          bmi_input("UtilityFN", numericInput(session$ns("bmi_utility_fn"), "Utility FN", value = -5, step = 1)),
          bmi_input("Beta", numericInput(session$ns("bmi_beta"), "F-Beta Beta", value = 1, min = 0.01, step = 0.1)),
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
            selected = if ("y" %in% numeric_choices) "y" else ""
          ),
          selectInput(
            session$ns("rshap_prediction_col"),
            "Prediction",
            choices = c("(infer Predict)" = "", numeric_choices),
            selected = if ("Predict" %in% numeric_choices) "Predict" else ""
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
            selected = if ("Date" %in% choices) "Date" else if ("date" %in% choices) "date" else ""
          ),
          selectInput(
            session$ns("rshap_date_aggregation"),
            "Date Aggregation",
            choices = c("day", "week", "month"),
            selected = "month"
          ),
          selectInput(
            session$ns("rshap_by_vars"),
            "ByVars",
            choices = choices,
            selected = by_defaults,
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
          numericInput(session$ns("rshap_max_byvars"), "Max ByVars", value = 3, min = 1, step = 1),
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
          checkboxInput(session$ns("rshap_include_effect_curves"), "Include AutoNLS Effect Curves", value = TRUE),
          selectInput(
            session$ns("rshap_effect_curve_backend"),
            "Effect Curve Backend",
            choices = c("none", "autonls"),
            selected = "none"
          ),
          textInput(session$ns("rshap_effect_curve_models"), "Effect Curve Models", value = "stable"),
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
            selected = if ("Target" %in% target_choices) "Target" else if ("target" %in% target_choices) "target" else ""
          ),
          selectInput(
            session$ns("bshap_prediction_col"),
            "Prediction Probability",
            choices = c("(infer Predict)" = "", prediction_choices),
            selected = if ("Predict" %in% prediction_choices) "Predict" else if ("prediction" %in% prediction_choices) "prediction" else ""
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
            selected = if ("Date" %in% choices) "Date" else if ("date" %in% choices) "date" else ""
          ),
          selectInput(
            session$ns("bshap_date_aggregation"),
            "Date Aggregation",
            choices = c("day", "week", "month"),
            selected = "month"
          ),
          selectInput(
            session$ns("bshap_by_vars"),
            "ByVars",
            choices = choices,
            selected = by_defaults,
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
          numericInput(session$ns("bshap_max_byvars"), "Max ByVars", value = 3, min = 1, step = 1),
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
          checkboxInput(session$ns("bshap_include_effect_curves"), "Include AutoNLS Effect Curves", value = TRUE),
          selectInput(
            session$ns("bshap_effect_curve_backend"),
            "Effect Curve Backend",
            choices = c("none", "autonls"),
            selected = "none"
          ),
          textInput(session$ns("bshap_effect_curve_models"), "Effect Curve Models", value = "stable"),
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
        target_default <- if ("Revenue" %in% choices) {
          "Revenue"
        } else if ("Target" %in% choices) {
          "Target"
        } else if (length(choices)) {
          choices[[1]]
        } else {
          ""
        }
        feature_defaults <- setdiff(choices, c(target_default))
        by_defaults <- intersect(c("Channel", "Region", "CustomerTier", "segment", "Segment"), choices)

        return(tagList(
          selectInput(
            session$ns("catboost_problem_type"),
            "Problem Type",
            choices = c("Regression" = "regression", "Binary Classification" = "binary"),
            selected = "regression"
          ),
          selectInput(
            session$ns("catboost_target_col"),
            "Target",
            choices = choices,
            selected = target_default
          ),
          selectInput(
            session$ns("catboost_feature_cols"),
            "Feature Columns",
            choices = choices,
            selected = feature_defaults,
            multiple = TRUE
          ),
          textInput(session$ns("catboost_positive_class"), "Positive Class", value = "Yes"),
          selectInput(
            session$ns("catboost_date_var"),
            "Date",
            choices = c("(none)" = "", choices),
            selected = if ("Date" %in% choices) "Date" else if ("date" %in% choices) "date" else ""
          ),
          selectInput(
            session$ns("catboost_by_vars"),
            "ByVars",
            choices = choices,
            selected = by_defaults,
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
        textInput(session$ns("eda_data_name"), "DataName", value = "Uploaded Data"),
        selectInput(
          session$ns("eda_univariate_vars"),
          "UnivariateVars",
          choices = choices,
          selected = intersect(c("Spend", "Revenue", "Clicks", "Channel"), choices),
          multiple = TRUE
        ),
        selectInput(
          session$ns("eda_corr_vars"),
          "CorrVars",
          choices = numeric_choices,
          selected = intersect(c("Spend", "Revenue", "Clicks"), numeric_choices),
          multiple = TRUE
        ),
        selectInput(
          session$ns("eda_trend_vars"),
          "TrendVars",
          choices = numeric_choices,
          selected = intersect("Revenue", numeric_choices),
          multiple = TRUE
        ),
        selectInput(
          session$ns("eda_trend_date_var"),
          "TrendDateVar",
          choices = c("(none)" = "", choices),
          selected = if ("Date" %in% choices) "Date" else ""
        ),
        selectInput(
          session$ns("eda_trend_group_var"),
          "TrendGroupVar",
          choices = c("(none)" = "", choices),
          selected = if ("Channel" %in% choices) "Channel" else ""
        ),
        selectInput(
          session$ns("eda_target_var"),
          "TargetVar",
          choices = c("(none)" = "", choices),
          selected = ""
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
        theme = selected_value(input$assessment_theme) %||% "light",
        max_rows = as.integer(input$assessment_max_rows %||% 1000L),
        max_groups = as.integer(input$assessment_max_groups %||% 25L)
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
        theme = selected_value(input$rmi_theme) %||% "light",
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
        theme = selected_value(input$bmi_theme) %||% "light"
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
      if (identical(module_id, "autoquant_model_readiness")) {
        return(model_readiness_config())
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
        return(catboost_builder_config())
      }
      if (identical(module_id, "autoquant_multiclass_shap_analysis")) {
        return(shap_scaffold_config(module_id))
      }

      eda_config()
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
        details
      )
    })

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
