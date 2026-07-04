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
              "AutoQuant Model Assessment" = "autoquant_model_assessment"
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

    module_config <- function(module_id) {
      if (identical(module_id, "autoquant_model_assessment")) {
        return(model_assessment_config())
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
      tags$div(
        ui_status_badge(result$status, status = status),
        tags$p(class = "aq-export-message", service_result_message(result))
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
