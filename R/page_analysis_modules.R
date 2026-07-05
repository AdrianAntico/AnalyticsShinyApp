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
              "AutoQuant Model Assessment" = "autoquant_model_assessment",
              "AutoQuant Regression Model Insights" = "autoquant_regression_model_insights",
              "AutoQuant Binary Classification Model Insights" = "autoquant_binary_model_insights"
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
          tags$hr(),
          h4("Generated Code"),
          verbatimTextOutput(ns("analysis_module_code"))
        )
      )
    )
  )
}

page_analysis_modules_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    module_result <- reactiveVal(NULL)

    output$analysis_module_settings <- renderUI({
      module_id <- selected_value(input$analysis_module_id) %||% "autoquant_eda"
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      choices <- if (is.null(data)) character() else names(data)
      numeric_choices <- if (is.null(data)) {
        character()
      } else {
        names(data)[vapply(data, is.numeric, logical(1))]
      }

      if (identical(module_id, "autoquant_model_assessment")) {
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
          textInput(session$ns("artifact_section"), "Artifact Section", value = "Model Assessment"),
          selectInput(
            session$ns("assessment_theme"),
            "Theme",
            choices = c("light", "dark", "pimp"),
            selected = "light"
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
            selected = "light"
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
            selected = "light"
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
          selected = "light"
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
        Theme = selected_value(input$eda_theme) %||% "light",
        MaxCategoricalLevels = as.integer(input$eda_max_categorical_levels %||% 25L),
        MaxDiscreteNumericLevels = as.integer(input$eda_max_discrete_numeric_levels %||% 20L),
        MaxCorrelationPairsToPlot = as.integer(input$eda_max_correlation_pairs %||% 25L)
      )
    }

    model_assessment_config <- function() {
      list(
        assessment_problem_type = selected_value(input$assessment_problem_type) %||% "Regression",
        actual_var = selected_value(input$actual_var),
        prediction_var = selected_value(input$prediction_var),
        predicted_class_var = selected_value(input$predicted_class_var),
        positive_class = selected_value(input$positive_class),
        date_var = selected_value(input$assessment_date_var),
        group_var = selected_value(input$assessment_group_var),
        model_name = selected_value(input$model_name) %||% "Model",
        artifact_section = selected_value(input$artifact_section) %||% "Model Assessment",
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

    module_config <- function(module_id) {
      if (identical(module_id, "autoquant_model_assessment")) {
        return(model_assessment_config())
      }
      if (identical(module_id, "autoquant_regression_model_insights")) {
        return(regression_model_insights_config())
      }
      if (identical(module_id, "autoquant_binary_model_insights")) {
        return(binary_model_insights_config())
      }

      eda_config()
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

      if (identical(result$status, "success") && length(result$artifacts)) {
        ctx$add_artifacts(result$artifacts)
        ctx$add_report_plans(result$metadata$report_plans %||% list())
      }
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

    output$analysis_module_code <- renderText({
      result <- module_result()
      if (is.null(result) || is.null(result$code)) {
        return("")
      }

      result$code
    })
  })
}
