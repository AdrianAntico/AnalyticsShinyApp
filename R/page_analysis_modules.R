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
            choices = c("AutoQuant EDA" = "autoquant_eda"),
            selected = "autoquant_eda"
          ),
          textInput(ns("eda_data_name"), "DataName", value = "Uploaded Data"),
          uiOutput(ns("eda_column_inputs")),
          selectInput(
            ns("eda_theme"),
            "Theme",
            choices = c("light", "dark", "pimp"),
            selected = "light"
          ),
          numericInput(ns("eda_max_categorical_levels"), "Max Categorical Levels", value = 25, min = 1, step = 1),
          numericInput(ns("eda_max_discrete_numeric_levels"), "Max Discrete Numeric Levels", value = 20, min = 1, step = 1),
          numericInput(ns("eda_max_correlation_pairs"), "Max Correlation Pairs To Plot", value = 25, min = 1, step = 1),
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

    output$eda_column_inputs <- renderUI({
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      choices <- if (is.null(data)) character() else names(data)
      numeric_choices <- if (is.null(data)) {
        character()
      } else {
        names(data)[vapply(data, is.numeric, logical(1))]
      }

      tagList(
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
        )
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

    observeEvent(input$run_analysis_module, {
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      result <- run_analysis_module(
        module_id = selected_value(input$analysis_module_id) %||% "autoquant_eda",
        data = data,
        config = eda_config()
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
