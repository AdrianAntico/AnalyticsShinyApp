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
    label = "Already summarized",
    type = "checkbox",
    default = TRUE
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
option_control <- function(option_name, ns = identity) {
  opt <- option_registry[[option_name]]
  if (is.null(opt)) {
    return(NULL)
  }

  if (identical(option_name, "AutoAggregate")) {
    return(tags$div(
      class = "aq-plot-grain-control",
      checkboxInput(
        ns(opt$input_id),
        label = tagList(
          tags$span("Already summarized"),
          tags$small("One plotted value per X/group.")
        ),
        value = opt$default
      )
    ))
  }

  switch(
    opt$type,
    select = selectInput(ns(opt$input_id), opt$label, choices = opt$choices, selected = opt$default),
    text = textInput(ns(opt$input_id), opt$label, value = opt$default),
    checkbox = checkboxInput(ns(opt$input_id), opt$label, value = opt$default),
    numeric = numericInput(ns(opt$input_id), opt$label, value = opt$default),
    NULL
  )
}

option_value <- function(input, option_name) {
  opt <- option_registry[[option_name]]
  if (is.null(opt)) {
    return(NULL)
  }

  value <- input[[opt$input_id]]
  switch(
    opt$type,
    checkbox = logical_value(value),
    numeric = numeric_or_null(value),
    selected_value(value)
  )
}

add_option_arg <- function(args, option_name, value) {
  if (identical(option_name, "AutoAggregate")) {
    args$PreAgg <- isTRUE(value)
    return(args)
  }

  if (identical(option_name, "AggMethod")) {
    args$AggMethod <- value
    return(args)
  }

  args[[option_name]] <- value
  args
}

