mapping_control <- function(mapping, data, required = TRUE, selected = NULL) {
  choices <- column_choices(data, include_none = !required)
  if (identical(mapping, "CorrVars")) {
    all_choices <- column_choices(data)
    if (is.null(selected)) {
      selected <- names(data)
    }

    selected <- selected[selected %in% all_choices]
    if (!length(selected)) {
      selected <- all_choices
    }

    return(selectInput(
      mapping_input_id(mapping),
      mapping,
      choices = all_choices,
      selected = selected,
      multiple = TRUE
    ))
  }

  if (is.null(selected) || !selected %in% choices) {
    if (!required && "" %in% choices) {
      selected <- ""
    } else {
      selected <- choices[1L]
    }
  }

  selectInput(
    mapping_input_id(mapping),
    mapping,
    choices = choices,
    selected = selected
  )
}

build_app_ui <- function() {
  fluidPage(
  titlePanel("Analytics Shiny App"),
  tabsetPanel(
    id = "main_tabs",
    tabPanel(
      "Project",
      sidebarLayout(
        sidebarPanel(
          textInput(
            "project_path",
            "Project File",
            value = file.path(getwd(), "autoplots_project.rds")
          ),
          actionButton("save_project", "Save Project", class = "btn-primary"),
          actionButton("load_project", "Load Project", class = "btn-secondary"),
          tags$hr(),
          textInput(
            "bundle_dir",
            "Project Bundle Directory",
            value = file.path(getwd(), "autoplots_project")
          ),
          actionButton("save_bundle", "Save Project Bundle", class = "btn-primary"),
          actionButton("load_bundle", "Load Project Bundle", class = "btn-secondary")
        ),
        mainPanel(
          textOutput("project_message")
        )
      )
    ),
    tabPanel(
      "Data",
      sidebarLayout(
        sidebarPanel(
          fileInput("csv_file", "CSV", accept = c(".csv", "text/csv"))
        ),
        mainPanel(
          textOutput("data_summary"),
          tableOutput("data_preview")
        )
      )
    ),
    tabPanel(
      "Plots",
      sidebarLayout(
        sidebarPanel(
          selectInput("plot_type", "PlotType", choices = plot_types),
          uiOutput("mapping_inputs"),
          tags$hr(),
          uiOutput("option_inputs"),
          tags$hr(),
          actionButton("build_plot", "Build / Refresh Plot", class = "btn-primary"),
          actionButton("add_plot", "Add Plot", class = "btn-success"),
          actionButton("remove_last_plot", "Remove Last Plot"),
          helpText("Plot preview updates only when this button is clicked.")
        ),
        mainPanel(
          uiOutput("preview_plot"),
          textOutput("plot_list_message"),
          tags$hr(),
          h4("Current Plot Code"),
          verbatimTextOutput("generated_code"),
          tags$hr(),
          h4("Saved Plots"),
          selectInput("selected_saved_plot", "Saved Plot", choices = character()),
          actionButton("load_saved_plot", "Load Plot for Editing"),
          actionButton("update_saved_plot", "Update Saved Plot"),
          actionButton("duplicate_saved_plot", "Duplicate Plot"),
          selectInput("section_for_plot", "Section", choices = character()),
          textInput("new_section_name", "New Section", value = ""),
          actionButton("assign_plot_section", "Assign Plot to Section"),
          actionButton("move_plot_up", "Move Up"),
          actionButton("move_plot_down", "Move Down"),
          tableOutput("saved_plot_list"),
          h4("All Saved Plots Code"),
          verbatimTextOutput("saved_plots_code")
        )
      )
    ),
    tabPanel(
      "Layout",
      h4("Layout"),
      sidebarLayout(
        sidebarPanel(
          selectInput("layout_type", "Layout", choices = c("Grid", "Sections"), selected = "Grid"),
          numericInput("layout_cols", "Columns", value = 2, min = 1, max = 4, step = 1),
          textInput("section_name", "Section Name", value = "Analysis"),
          actionButton("assign_section", "Assign All Saved Plots to Section")
        ),
        mainPanel(
          uiOutput("saved_layout_preview"),
          tags$hr(),
          h4("Layout Code"),
          verbatimTextOutput("layout_code"),
          tags$hr(),
          h4("Report Code"),
          verbatimTextOutput("report_code")
        )
      )
    ),
    tabPanel(
      "Export",
      h4("Export"),
      sidebarLayout(
        sidebarPanel(
          textInput("export_dir", "Export Directory", value = getwd()),
          textInput("export_name", "File Name", value = "autoplots_report"),
          actionButton("export_html", "Export HTML", class = "btn-primary"),
          actionButton("export_code", "Export R Code", class = "btn-secondary"),
          actionButton("export_all", "Export All", class = "btn-success")
        ),
        mainPanel(
          textOutput("export_message")
        )
      )
    )
  )
  )
}
