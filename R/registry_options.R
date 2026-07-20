theme_choices <- c(
  "dark", "auritus", "azul", "bee-inspired", "blue", "caravan", "carp",
  "chalk", "cool", "dark-blue", "dark-bold", "dark-digerati",
  "dark-fresh-cut", "dark-mushroom", "eduardo", "essos", "forest",
  "fresh-cut", "fruit", "gray", "green", "halloween", "helianthus",
  "infographic", "inspired", "jazz", "london", "macarons", "macarons2",
  "mint", "purple-passion", "red", "red-velvet", "roma", "royal",
  "sakura", "v5", "walden", "wef", "weforum"
)

# Source of truth for rendering flat AutoPlots option controls.
option_registry <- list(
  Theme = list(
    input_id = "theme",
    label = "Theme",
    type = "select",
    choices = theme_choices,
    default = "dark"
  ),
  AutoAggregate = list(
    input_id = "auto_aggregate",
    label = "Data grain",
    type = "grain",
    choices = c("Raw rows" = "raw", "Already summarized" = "preaggregated"),
    default = "raw"
  ),
  AggMethod = list(
    input_id = "agg_method",
    label = "Aggregation Method",
    type = "select",
    choices = c("mean", "sum", "median", "sd", "min", "max", "count"),
    default = "mean"
  ),
  `title.text` = list(
    input_id = "title_text",
    label = "Chart Title",
    type = "text",
    default = ""
  ),
  `title.subtext` = list(
    input_id = "title_subtext",
    label = "Chart Subtitle",
    type = "text",
    default = ""
  ),
  ShowLabels = list(
    input_id = "show_labels",
    label = "Show Labels",
    type = "checkbox",
    default = FALSE
  ),
  MouseScroll = list(
    input_id = "mouse_scroll",
    label = "Enable Mouse Zoom",
    type = "checkbox",
    default = FALSE
  ),
  `legend.show` = list(
    input_id = "legend_show",
    label = "Show Legend",
    type = "checkbox",
    default = TRUE
  ),
  `xAxis.title` = list(
    input_id = "x_axis_title",
    label = "X-Axis Title",
    type = "text",
    default = ""
  ),
  `yAxis.title` = list(
    input_id = "y_axis_title",
    label = "Y-Axis Title",
    type = "text",
    default = ""
  ),
  `xAxis.axisLabel.rotate` = list(
    input_id = "x_axis_rotate",
    label = "Rotate X-Axis Labels",
    type = "numeric",
    default = NA
  )
)
option_control <- function(option_name, ns = identity, value = NULL) {
  opt <- option_registry[[option_name]]
  if (is.null(opt)) {
    return(NULL)
  }

  control_value <- value %||% opt$default

  if (identical(option_name, "AutoAggregate")) {
    return(tags$div(
      class = "aq-plot-grain-control",
      tags$div(
        class = "aq-plot-grain-copy",
        tags$span("Data grain"),
        tags$small("Most datasets are raw rows; summarize only when needed.")
      ),
      radioButtons(
        ns(opt$input_id),
        label = NULL,
        choices = opt$choices,
        selected = if (identical(control_value, "preaggregated") || isTRUE(control_value)) {
          "preaggregated"
        } else {
          "raw"
        },
        inline = TRUE
      )
    ))
  }

  switch(
    opt$type,
    select = selectInput(ns(opt$input_id), opt$label, choices = opt$choices, selected = control_value),
    text = textInput(ns(opt$input_id), opt$label, value = control_value %||% ""),
    checkbox = checkboxInput(ns(opt$input_id), opt$label, value = isTRUE(control_value)),
    numeric = numericInput(ns(opt$input_id), opt$label, value = control_value),
    NULL
  )
}

option_value <- function(input, option_name) {
  opt <- option_registry[[option_name]]
  if (is.null(opt)) {
    return(NULL)
  }

  value <- input[[opt$input_id]]
  if (identical(opt$type, "grain")) {
    return(selected_value(value))
  }

  switch(
    opt$type,
    checkbox = logical_value(value),
    numeric = numeric_or_null(value),
    selected_value(value)
  )
}

add_option_arg <- function(args, option_name, value) {
  if (identical(option_name, "AutoAggregate")) {
    args$PreAgg <- identical(value, "preaggregated") || isTRUE(value)
    return(args)
  }

  if (identical(option_name, "AggMethod")) {
    args$AggMethod <- value
    return(args)
  }

  args[[option_name]] <- value
  args
}

