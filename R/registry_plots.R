# Source of truth for plot mappings and available UI options.
plot_registry <- list(
  Area = list(
    mappings = c("XVar", "YVar"),
    optional_mappings = c("GroupVar"),
    options = c(
      "Theme", "AutoAggregate", "AggMethod",
      "title.text", "title.subtext",
      "ShowLabels", "MouseScroll", "legend.show",
      "xAxis.title", "yAxis.title", "xAxis.axisLabel.rotate"
    )
  ),
  Line = list(
    mappings = c("XVar", "YVar"),
    optional_mappings = c("GroupVar"),
    options = c(
      "Theme", "AutoAggregate", "AggMethod",
      "title.text", "title.subtext",
      "ShowLabels", "MouseScroll", "legend.show",
      "xAxis.title", "yAxis.title", "xAxis.axisLabel.rotate"
    )
  ),
  Bar = list(
    mappings = c("XVar", "YVar"),
    optional_mappings = c("GroupVar"),
    options = c(
      "Theme", "AutoAggregate", "AggMethod",
      "title.text", "title.subtext",
      "ShowLabels", "MouseScroll", "legend.show",
      "xAxis.title", "yAxis.title", "xAxis.axisLabel.rotate"
    )
  ),
  Scatter = list(
    mappings = c("XVar", "YVar"),
    optional_mappings = c("GroupVar"),
    options = c(
      "Theme", "title.text", "title.subtext",
      "ShowLabels", "MouseScroll", "legend.show",
      "xAxis.title", "yAxis.title"
    )
  ),
  Histogram = list(
    mappings = c("XVar"),
    optional_mappings = c("GroupVar"),
    options = c(
      "Theme", "title.text", "title.subtext",

      "MouseScroll", "legend.show",
      "xAxis.title", "yAxis.title", "xAxis.axisLabel.rotate"
    )
  ),
  Density = list(
    mappings = c("XVar"),
    optional_mappings = c("GroupVar"),
    options = c(
      "Theme", "title.text", "title.subtext",

      "MouseScroll", "legend.show",
      "xAxis.title", "yAxis.title"
    )
  ),
  Pie = list(
    mappings = c("XVar", "YVar"),
    optional_mappings = character(),
    options = c(
      "Theme", "AutoAggregate", "AggMethod",
      "title.text", "title.subtext",
      "ShowLabels", "legend.show"
    )
  ),
  Donut = list(
    mappings = c("XVar", "YVar"),
    optional_mappings = character(),
    options = c(
      "Theme", "AutoAggregate", "AggMethod",
      "title.text", "title.subtext",
      "ShowLabels", "legend.show"
    )
  ),
  HeatMap = list(
    mappings = c("XVar", "YVar", "ZVar"),
    optional_mappings = character(),
    options = c(
      "Theme", "AutoAggregate", "AggMethod",
      "title.text", "title.subtext",
      "xAxis.title", "yAxis.title"
    )
  ),
  CorrMatrix = list(
    mappings = c("CorrVars"),
    optional_mappings = character(),
    options = c(
      "Theme", "title.text", "title.subtext",
      "ShowLabels"
    )
  )
)

plot_types <- names(plot_registry)
