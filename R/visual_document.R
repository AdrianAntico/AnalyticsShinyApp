VISUAL_DOCUMENT_SCHEMA_VERSION <- "0.4.0"
VISUAL_COMPOSITION_SCHEMA_VERSION <- "0.1.0"

if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) if (is.null(x)) y else x
}

visual_null_default <- function(x, y) {
  if (is.null(x)) y else x
}

visual_list_get <- function(x, name, default = NULL) {
  if (!is.list(x) || !name %in% names(x)) {
    return(default)
  }

  x[[name]]
}

visual_value <- function(x, y = NULL) {
  if (is.null(x) || length(x) == 0L) {
    return(y)
  }

  x
}

visual_object_default_label <- function(object_id, object_type = NULL) {
  labels <- c(
    document_root = "Visual Document",
    canvas_001 = "Canvas",
    plot_001 = "Plot",
    title_001 = "Title",
    x_axis_001 = "X-Axis",
    y_axis_001 = "Y-Axis",
    series_001 = "Data Layer",
    boundary_line_001 = "Boundary Line",
    legend_001 = "Legend",
    interaction_001 = "Interaction",
    caption_001 = "Evidence Note",
    heading_001 = "Heading",
    evidence_group_001 = "Evidence Group",
    callout_001 = "Evidence Callout",
    explanation_001 = "Explanation",
    source_001 = "Source",
    recommendation_001 = "Recommendation",
    limitation_001 = "Limitation",
    warning_001 = "Uncertainty",
    references_001 = "References",
    methodology_001 = "Methodology",
    section_001 = "Section",
    divider_001 = "Divider",
    spacer_001 = "Spacer",
    supporting_table_001 = "Supporting Table",
    comparison_panel_001 = "Comparison Panel",
    timeline_001 = "Timeline"
  )

  label <- unname(labels[object_id])
  if (!is.na(label)) {
    return(label)
  }

  tools::toTitleCase(gsub("[_-]+", " ", object_type %||% object_id))
}

visual_property_schema <- function() {
  list(
    `title.text` = list(
      label = "Title",
      type = "text",
      default = "",
      applies_to = c("plot", "title")
    ),
    `title.subtext` = list(
      label = "Subtitle",
      type = "text",
      default = "",
      applies_to = c("plot", "title")
    ),
    `xAxis.title` = list(
      label = "X-axis title",
      type = "text",
      default = "",
      applies_to = c("axis")
    ),
    `yAxis.title` = list(
      label = "Y-axis title",
      type = "text",
      default = "",
      applies_to = c("axis")
    ),
    `xAxis.axisLabel.rotate` = list(
      label = "Rotate X-axis labels",
      type = "numeric",
      default = NA,
      applies_to = c("axis")
    ),
    ShowLabels = list(
      label = "Show labels",
      type = "logical",
      default = FALSE,
      applies_to = c("series")
    ),
    `legend.show` = list(
      label = "Show legend",
      type = "logical",
      default = TRUE,
      applies_to = c("legend")
    ),
    MouseScroll = list(
      label = "Mouse zoom",
      type = "logical",
      default = FALSE,
      applies_to = c("interaction")
    ),
    Theme = list(
      label = "Theme",
      type = "choice",
      default = "dark",
      applies_to = c("plot", "canvas")
    ),
    `series.opacity` = list(
      label = "Layer opacity",
      type = "numeric",
      default = 1,
      applies_to = c("series")
    ),
    `boundary.visible` = list(
      label = "Boundary visible",
      type = "logical",
      default = TRUE,
      applies_to = c("boundary_line")
    ),
    `boundary.lineWidth` = list(
      label = "Boundary weight",
      type = "numeric",
      default = 2,
      applies_to = c("boundary_line")
    ),
    content = list(
      label = "Text content",
      type = "text",
      default = "",
      applies_to = c(
        "text", "callout", "provenance", "group", "section",
        "warning", "limitation", "recommendation", "methodology",
        "reference", "divider", "spacer", "table", "comparison_panel",
        "timeline"
      )
    ),
    `callout.label` = list(
      label = "Callout label",
      type = "text",
      default = "Finding",
      applies_to = c("callout")
    ),
    `callout.value` = list(
      label = "Callout value",
      type = "text",
      default = "",
      applies_to = c("callout")
    ),
    `layout.x` = list(
      label = "X position",
      type = "numeric",
      default = 1,
      applies_to = c("canvas", "plot", "text", "group", "callout", "provenance", "section", "warning", "limitation", "recommendation", "methodology", "reference", "divider", "spacer", "table", "comparison_panel", "timeline")
    ),
    `layout.y` = list(
      label = "Y position",
      type = "numeric",
      default = 1,
      applies_to = c("canvas", "plot", "text", "group", "callout", "provenance", "section", "warning", "limitation", "recommendation", "methodology", "reference", "divider", "spacer", "table", "comparison_panel", "timeline")
    ),
    `layout.width` = list(
      label = "Width",
      type = "numeric",
      default = 12,
      applies_to = c("canvas", "plot", "text", "group", "callout", "provenance", "section", "warning", "limitation", "recommendation", "methodology", "reference", "divider", "spacer", "table", "comparison_panel", "timeline")
    ),
    `layout.height` = list(
      label = "Height",
      type = "numeric",
      default = 2,
      applies_to = c("canvas", "plot", "text", "group", "callout", "provenance", "section", "warning", "limitation", "recommendation", "methodology", "reference", "divider", "spacer", "table", "comparison_panel", "timeline")
    ),
    `layout.z` = list(
      label = "Layer order",
      type = "numeric",
      default = 1,
      applies_to = c("canvas", "plot", "text", "group", "callout", "provenance", "section", "warning", "limitation", "recommendation", "methodology", "reference", "divider", "spacer", "table", "comparison_panel", "timeline")
    )
  )
}

visual_object_registry <- function() {
  list(
    visual_document = list(
      label = "Document",
      editable_properties = c("Theme"),
      allowed_children = c("canvas", "plot", "text", "group", "callout", "provenance", "section", "warning", "limitation", "recommendation", "methodology", "reference", "divider", "spacer", "table", "comparison_panel", "timeline")
    ),
    canvas = list(
      label = "Canvas",
      editable_properties = c("Theme", "layout.width", "layout.height"),
      allowed_children = c("plot", "text", "group", "callout", "provenance", "section", "warning", "limitation", "recommendation", "methodology", "reference", "divider", "spacer", "table", "comparison_panel", "timeline")
    ),
    plot = list(
      label = "Plot",
      editable_properties = c("title.text", "title.subtext", "Theme", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = c("title", "axis", "series", "boundary_line", "legend", "interaction", "text")
    ),
    title = list(
      label = "Title",
      editable_properties = c("title.text", "title.subtext"),
      allowed_children = character()
    ),
    axis = list(
      label = "Axis",
      editable_properties = c("xAxis.title", "yAxis.title", "xAxis.axisLabel.rotate"),
      allowed_children = character()
    ),
    series = list(
      label = "Layer",
      editable_properties = c("ShowLabels", "series.opacity"),
      allowed_children = character()
    ),
    boundary_line = list(
      label = "Boundary",
      editable_properties = c("boundary.visible", "boundary.lineWidth"),
      allowed_children = character()
    ),
    legend = list(
      label = "Legend",
      editable_properties = c("legend.show"),
      allowed_children = character()
    ),
    interaction = list(
      label = "Interaction",
      editable_properties = c("MouseScroll"),
      allowed_children = character()
    ),
    text = list(
      label = "Text",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    group = list(
      label = "Group",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = c("plot", "text", "callout", "provenance", "section", "warning", "limitation", "recommendation", "methodology", "reference", "divider", "spacer", "table", "comparison_panel", "timeline")
    ),
    callout = list(
      label = "Evidence Callout",
      editable_properties = c("callout.label", "callout.value", "content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    provenance = list(
      label = "Provenance",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    section = list(
      label = "Section",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = c("plot", "text", "group", "callout", "provenance", "warning", "limitation", "recommendation", "methodology", "reference", "divider", "spacer", "table", "comparison_panel", "timeline")
    ),
    warning = list(
      label = "Warning",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    limitation = list(
      label = "Limitation",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    recommendation = list(
      label = "Recommendation",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    methodology = list(
      label = "Methodology",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    reference = list(
      label = "References",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    divider = list(
      label = "Divider",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    spacer = list(
      label = "Spacer",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    table = list(
      label = "Table",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    comparison_panel = list(
      label = "Comparison Panel",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    ),
    timeline = list(
      label = "Timeline",
      editable_properties = c("content", "layout.x", "layout.y", "layout.width", "layout.height", "layout.z"),
      allowed_children = character()
    )
  )
}

visual_default_layout <- function(type, role = NULL, order = NULL) {
  order <- as.integer(order %||% 1L)
  defaults <- list(x = 1, y = order, width = 12, height = 2)
  if (identical(type, "canvas")) {
    defaults <- list(x = 1, y = 1, width = 12, height = 12)
  } else if (identical(type, "plot")) {
    defaults <- list(x = 1, y = 3, width = 8, height = 7)
  } else if (identical(role, "headline")) {
    defaults <- list(x = 1, y = 1, width = 12, height = 2)
  } else if (identical(type, "group")) {
    defaults <- list(x = 9, y = 3, width = 4, height = 7)
  } else if (identical(type, "callout")) {
    defaults <- list(x = 1, y = 1, width = 4, height = 2)
  } else if (type %in% c("warning", "limitation", "recommendation", "methodology", "reference", "table", "comparison_panel", "timeline")) {
    defaults <- list(x = 1, y = order, width = 4, height = 2)
  } else if (identical(type, "section")) {
    defaults <- list(x = 1, y = order, width = 12, height = 3)
  } else if (identical(type, "divider")) {
    defaults <- list(x = 1, y = order, width = 12, height = 1)
  } else if (identical(type, "spacer")) {
    defaults <- list(x = 1, y = order, width = 12, height = 1)
  } else if (identical(type, "provenance")) {
    defaults <- list(x = 1, y = 10, width = 12, height = 2)
  }

  c(
    defaults,
    list(
      unit = "grid",
      z = order,
      min_width = 2,
      min_height = 1,
      responsive = list(mode = "stack_on_narrow", priority = order)
    )
  )
}

visual_renderer_adapter <- function(object) {
  type <- object$type %||% "unknown"
  adapters <- c(
    visual_document = "VisualDocumentAdapter",
    canvas = "CanvasLayoutAdapter",
    plot = "AutoPlotsAdapter",
    title = "AutoPlotsAdapter",
    axis = "AutoPlotsAdapter",
    series = "AutoPlotsAdapter",
    boundary_line = "AutoPlotsAdapter",
    legend = "AutoPlotsAdapter",
    interaction = "AutoPlotsAdapter",
    text = "SemanticTextAdapter",
    group = "ObjectGroupAdapter",
    callout = "EvidenceCalloutAdapter",
    provenance = "ProvenanceBlockAdapter",
    section = "SectionAdapter",
    warning = "WarningAdapter",
    limitation = "LimitationAdapter",
    recommendation = "RecommendationAdapter",
    methodology = "MethodologyAdapter",
    reference = "ReferenceAdapter",
    divider = "DividerAdapter",
    spacer = "SpacerAdapter",
    table = "SemanticTableAdapter",
    comparison_panel = "ComparisonPanelAdapter",
    timeline = "TimelineAdapter"
  )

  adapters[[type]] %||% (object$renderer %||% "UnknownAdapter")
}

visual_make_object <- function(
  id,
  type,
  label,
  parent = NULL,
  children = character(),
  renderer = NULL,
  role = NULL,
  properties = list(),
  data_binding = list(),
  evidence_refs = character(),
  extension = list(),
  visible = TRUE,
  locked = FALSE,
  order = NULL,
  layout = NULL
) {
  order <- order %||% 1L
  list(
    id = id,
    type = type,
    label = label,
    parent = parent,
    children = children,
    renderer = renderer,
    role = role,
    visible = isTRUE(visible),
    locked = isTRUE(locked),
    order = order,
    layout = layout %||% visual_default_layout(type, role = role, order = order),
    properties = properties,
    data_binding = data_binding,
    evidence_refs = evidence_refs,
    extension = extension
  )
}

visual_selection_state <- function(document, object_id = NULL, source = "system") {
  object_id <- object_id %||% document$selected_object_id %||% "plot_001"
  object <- document$objects[[object_id]]

  list(
    selected_object_id = object_id,
    object_type = object$type %||% NA_character_,
    parent = object$parent %||% NA_character_,
    source = source,
    revision = document$revision %||% 0L,
    exists = !is.null(object),
    visible = isTRUE(object$visible),
    locked = isTRUE(object$locked),
    last_valid_selection = if (!is.null(object)) object_id else document$selection$last_valid_selection %||% "plot_001"
  )
}

visual_document_create <- function(
  title = "Untitled Visual",
  intent = "analytical_storytelling",
  objects = list(),
  selected_object_id = "plot_001",
  metadata = list()
) {
  document <- list(
    schema_version = VISUAL_DOCUMENT_SCHEMA_VERSION,
    id = paste0("visual_", format(Sys.time(), "%Y%m%d%H%M%S")),
    title = title,
    intent = intent,
    objects = objects,
    selected_object_id = selected_object_id,
    selection = list(),
    revision = 0L,
    history = list(undo = list(), redo = list(), checkpoints = list()),
    authoring = list(proposals = list(), history = list()),
    metadata = metadata
  )

  visual_document_normalize(document)
}

visual_document_from_plot_spec <- function(plot_type, mappings = list(), options = list(), plot_name = NULL) {
  plot_label <- if (exists("plot_type_label", mode = "function")) {
    plot_type_label(plot_type)
  } else {
    tools::toTitleCase(gsub("[_-]+", " ", plot_type))
  }
  layer_label <- if (exists("plot_layer_label", mode = "function")) {
    plot_layer_label(plot_type)
  } else {
    paste(plot_label, "Layer")
  }

  title_text <- options[["title.text"]] %||% plot_label
  title_subtext <- options[["title.subtext"]] %||% ""
  theme <- options$Theme %||% "dark"

  objects <- list(
    document_root = visual_make_object(
      id = "document_root",
      type = "visual_document",
      label = "Visual Document",
      children = "canvas_001",
      properties = list(Theme = theme),
      order = 1L
    ),
    canvas_001 = visual_make_object(
      id = "canvas_001",
      type = "canvas",
      label = "Canvas",
      parent = "document_root",
      children = "plot_001",
      renderer = "AutoPlots",
      properties = list(Theme = theme),
      order = 1L
    ),
    plot_001 = visual_make_object(
      id = "plot_001",
      type = "plot",
      label = plot_label,
      parent = "canvas_001",
      children = c(
        "title_001", "x_axis_001", "y_axis_001", "series_001",
        "boundary_line_001", "legend_001", "interaction_001", "caption_001"
      ),
      renderer = "AutoPlots",
      role = "primary_visualization",
      properties = list(
        `title.text` = title_text,
        `title.subtext` = title_subtext,
        Theme = theme
      ),
      data_binding = mappings,
      evidence_refs = character(),
      order = 1L
    ),
    title_001 = visual_make_object(
      id = "title_001",
      type = "title",
      label = "Title",
      parent = "plot_001",
      renderer = "AutoPlots",
      role = "orientation",
      properties = list(`title.text` = title_text, `title.subtext` = title_subtext),
      order = 1L
    ),
    x_axis_001 = visual_make_object(
      id = "x_axis_001",
      type = "axis",
      label = "X-Axis",
      parent = "plot_001",
      renderer = "AutoPlots",
      role = "horizontal_scale",
      properties = list(
        `xAxis.title` = options[["xAxis.title"]] %||% "",
        `xAxis.axisLabel.rotate` = options[["xAxis.axisLabel.rotate"]] %||% NA
      ),
      data_binding = list(column = mappings$XVar %||% NULL),
      order = 2L
    ),
    y_axis_001 = visual_make_object(
      id = "y_axis_001",
      type = "axis",
      label = "Y-Axis",
      parent = "plot_001",
      renderer = "AutoPlots",
      role = "vertical_scale",
      properties = list(`yAxis.title` = options[["yAxis.title"]] %||% ""),
      data_binding = list(column = mappings$YVar %||% NULL),
      order = 3L
    ),
    series_001 = visual_make_object(
      id = "series_001",
      type = "series",
      label = layer_label,
      parent = "plot_001",
      renderer = "AutoPlots",
      role = "data_marks",
      properties = list(
        ShowLabels = isTRUE(options$ShowLabels),
        `series.opacity` = options[["series.opacity"]] %||% 1
      ),
      data_binding = mappings,
      order = 4L
    ),
    boundary_line_001 = visual_make_object(
      id = "boundary_line_001",
      type = "boundary_line",
      label = "Boundary Line",
      parent = "plot_001",
      renderer = "AutoPlots",
      role = "mark_boundary",
      properties = list(
        `boundary.visible` = TRUE,
        `boundary.lineWidth` = 2
      ),
      order = 5L
    ),
    legend_001 = visual_make_object(
      id = "legend_001",
      type = "legend",
      label = "Legend",
      parent = "plot_001",
      renderer = "AutoPlots",
      role = "series_identification",
      properties = list(`legend.show` = options[["legend.show"]] %||% TRUE),
      order = 6L
    ),
    interaction_001 = visual_make_object(
      id = "interaction_001",
      type = "interaction",
      label = "Interaction",
      parent = "plot_001",
      renderer = "AutoPlots",
      role = "exploration",
      properties = list(MouseScroll = isTRUE(options$MouseScroll)),
      order = 7L
    ),
    caption_001 = visual_make_object(
      id = "caption_001",
      type = "text",
      label = "Evidence Note",
      parent = "plot_001",
      renderer = "ReportContract",
      role = "evidence_caption",
      properties = list(content = paste("Generated from", plot_label, "configuration.")),
      order = 8L
    )
  )

  visual_document_create(
    title = plot_name %||% plot_label,
    intent = "plot_authoring",
    objects = objects,
    selected_object_id = "plot_001",
    metadata = list(plot_type = plot_type, plot_name = plot_name)
  )
}

visual_document_from_plot_config <- function(config, plot_name = NULL) {
  visual_document_from_plot_spec(
    plot_type = config$plot_type,
    mappings = config$mappings %||% list(),
    options = config$options %||% list(),
    plot_name = plot_name
  )
}

visual_document_normalize <- function(document) {
  if (is.null(document$schema_version)) {
    document$schema_version <- VISUAL_DOCUMENT_SCHEMA_VERSION
  }
  if (is.null(document$revision)) {
    document$revision <- 0L
  }
  if (is.null(document$history)) {
    document$history <- list(undo = list(), redo = list(), checkpoints = list())
  }
  document$history$undo <- document$history$undo %||% list()
  document$history$redo <- document$history$redo %||% list()
  document$history$checkpoints <- document$history$checkpoints %||% list()
  document$authoring <- document$authoring %||% list()
  document$authoring$proposals <- document$authoring$proposals %||% list()
  document$authoring$history <- document$authoring$history %||% list()
  document$composition <- document$composition %||% list()
  document$composition$reviews <- document$composition$reviews %||% list()
  document$composition$strategies <- document$composition$strategies %||% list()
  document$composition$branches <- document$composition$branches %||% list()
  document$composition$decisions <- document$composition$decisions %||% list()
  document$composition$history <- document$composition$history %||% list()
  document$composition$active_review_id <- document$composition$active_review_id %||% NULL
  document$composition$active_strategy_id <- document$composition$active_strategy_id %||% NULL
  document$composition$active_branch_id <- document$composition$active_branch_id %||% NULL
  document$composition$schema_version <- document$composition$schema_version %||% VISUAL_COMPOSITION_SCHEMA_VERSION

  object_ids <- names(document$objects)
  for (index in seq_along(object_ids)) {
    object_id <- object_ids[[index]]
    object <- document$objects[[object_id]]
    object$id <- object$id %||% object_id
    object$label <- object$label %||% visual_object_default_label(object_id, object$type)
    object$visible <- if (is.null(object$visible)) TRUE else isTRUE(object$visible)
    object$locked <- if (is.null(object$locked)) FALSE else isTRUE(object$locked)
    object$order <- object$order %||% index
    object$layout <- object$layout %||% visual_default_layout(object$type, object$role, object$order)
    default_layout <- visual_default_layout(object$type, object$role, object$order)
    for (layout_name in names(default_layout)) {
      object$layout[[layout_name]] <- object$layout[[layout_name]] %||% default_layout[[layout_name]]
    }
    object$children <- object$children %||% character()
    object$properties <- object$properties %||% list()
    object$data_binding <- object$data_binding %||% list()
    object$evidence_refs <- object$evidence_refs %||% character()
    object$extension <- object$extension %||% list()
    document$objects[[object_id]] <- object
  }

  selected <- document$selected_object_id %||% document$selection$selected_object_id %||% "plot_001"
  if (!selected %in% names(document$objects)) {
    selected <- "plot_001"
  }
  document$selected_object_id <- selected
  document$selection <- visual_selection_state(document, selected, source = document$selection$source %||% "system")
  document$schema_version <- VISUAL_DOCUMENT_SCHEMA_VERSION
  document
}

visual_document_object_choices <- function(document) {
  document <- visual_document_normalize(document)
  labels <- vapply(document$objects, function(object) {
    prefix <- paste(rep("  ", visual_object_depth(document, object$id)), collapse = "")
    state <- paste0(
      if (isFALSE(object$visible)) " hidden" else "",
      if (isTRUE(object$locked)) " locked" else ""
    )
    paste0(prefix, object$label, state)
  }, character(1))

  stats::setNames(names(document$objects), labels)
}

visual_object_depth <- function(document, object_id) {
  depth <- 0L
  object <- document$objects[[object_id]]
  while (!is.null(object$parent) && object$parent %in% names(document$objects)) {
    depth <- depth + 1L
    object <- document$objects[[object$parent]]
  }
  depth
}

visual_document_find_object <- function(document, object_id) {
  document <- visual_document_normalize(document)
  document$objects[[object_id]]
}

visual_document_select <- function(document, object_id, origin = "user") {
  document <- visual_document_normalize(document)
  if (!object_id %in% names(document$objects)) {
    stop("Cannot select missing visual object: ", object_id, call. = FALSE)
  }

  document$selected_object_id <- object_id
  document$selection <- visual_selection_state(document, object_id, source = origin)
  document
}

visual_object_property_names <- function(document, object_id, mode = "simple") {
  document <- visual_document_normalize(document)
  object <- visual_document_find_object(document, object_id)
  if (is.null(object)) {
    return(character())
  }

  registry <- visual_object_registry()
  object_schema <- registry[[object$type]]
  option_names <- object_schema$editable_properties %||% character()

  if (identical(object$id, "x_axis_001")) {
    option_names <- intersect(option_names, c("xAxis.title", "xAxis.axisLabel.rotate"))
  }
  if (identical(object$id, "y_axis_001")) {
    option_names <- intersect(option_names, "yAxis.title")
  }
  if (!identical(mode, "expert")) {
    option_names <- setdiff(option_names, c("series.opacity", "boundary.lineWidth"))
  }

  option_names
}

visual_inspector_contract <- function(document, object_id, mode = "simple", available_options = character()) {
  document <- visual_document_normalize(document)
  object <- visual_document_find_object(document, object_id)
  if (is.null(object)) {
    stop("Unknown visual object: ", object_id, call. = FALSE)
  }

  option_names <- visual_object_property_names(document, object_id, mode = mode)
  if (length(available_options)) {
    option_names <- intersect(option_names, available_options)
  }

  list(
    object_id = object$id,
    object_type = object$type,
    label = object$label,
    subtitle = paste0(
      visual_object_registry()[[object$type]]$label %||% object$type,
      " object",
      if (isTRUE(object$locked)) " (locked)" else "",
      if (isFALSE(object$visible)) " (hidden)" else ""
    ),
    renderer = object$renderer %||% "none",
    adapter = visual_renderer_adapter(object),
    layout = object$layout %||% visual_default_layout(object$type, object$role, object$order),
    role = object$role %||% "unspecified",
    visible = isTRUE(object$visible),
    locked = isTRUE(object$locked),
    option_names = option_names,
    values = object$properties %||% list(),
    evidence_refs = object$evidence_refs %||% character(),
    selection = document$selection
  )
}

visual_document_assigned_options <- function(document, mode = "expert") {
  document <- visual_document_normalize(document)
  unique(unlist(lapply(names(document$objects), function(object_id) {
    visual_object_property_names(document, object_id, mode = mode)
  }), use.names = FALSE))
}

visual_document_snapshot <- function(document) {
  document <- visual_document_normalize(document)
  document$history <- list(undo = list(), redo = list(), checkpoints = list())
  document
}

visual_document_push_undo <- function(document, before, mutation) {
  entry <- list(
    revision = document$revision %||% 0L,
    mutation = mutation,
    before = visual_document_snapshot(before),
    at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
  document$history$undo <- append(document$history$undo %||% list(), list(entry))
  document$history$redo <- list()
  document$revision <- as.integer(document$revision %||% 0L) + 1L
  document
}

visual_document_assert_child_allowed <- function(document, parent_id, child_type) {
  parent <- document$objects[[parent_id]]
  if (is.null(parent)) {
    stop("Cannot add object to missing parent: ", parent_id, call. = FALSE)
  }
  allowed <- visual_object_registry()[[parent$type]]$allowed_children %||% character()
  if (length(allowed) && !child_type %in% allowed) {
    stop("Cannot add ", child_type, " to ", parent$type, ".", call. = FALSE)
  }
  TRUE
}

visual_document_add_object <- function(document, object, parent_id = NULL, select = TRUE) {
  document <- visual_document_normalize(document)
  object$id <- object$id %||% paste0(object$type, "_", length(document$objects) + 1L)
  if (object$id %in% names(document$objects)) {
    stop("Visual object already exists: ", object$id, call. = FALSE)
  }

  parent_id <- parent_id %||% object$parent
  if (!is.null(parent_id)) {
    visual_document_assert_child_allowed(document, parent_id, object$type)
    object$parent <- parent_id
    siblings <- document$objects[[parent_id]]$children %||% character()
    object$order <- object$order %||% (length(siblings) + 1L)
    document$objects[[parent_id]]$children <- unique(c(siblings, object$id))
  }

  object$layout <- object$layout %||% visual_default_layout(object$type, object$role, object$order)
  document$objects[[object$id]] <- object
  if (isTRUE(select)) {
    document$selected_object_id <- object$id
  }
  visual_document_normalize(document)
}

visual_document_make_explanatory <- function(document, finding = list()) {
  document <- visual_document_normalize(document)
  canvas_id <- if ("canvas_001" %in% names(document$objects)) "canvas_001" else document$selected_object_id
  plot_id <- if ("plot_001" %in% names(document$objects)) "plot_001" else document$selected_object_id
  plot <- document$objects[[plot_id]]
  title <- finding$title %||% plot$properties[["title.text"]] %||% plot$label %||% "What this visual shows"
  statement <- finding$statement %||% "This visual has been promoted from a plot into an explanatory evidence composition."
  evidence_id <- finding$evidence_id %||% paste0(plot_id, "_evidence")

  add_if_missing <- function(document, object) {
    if (object$id %in% names(document$objects)) {
      return(document)
    }
    visual_document_add_object(document, object, parent_id = object$parent, select = FALSE)
  }

  document <- add_if_missing(document, visual_make_object(
    id = "heading_001",
    type = "text",
    label = "Heading",
    parent = canvas_id,
    renderer = "SemanticText",
    role = "headline",
    properties = list(content = title),
    order = 1L,
    layout = list(x = 1, y = 1, width = 12, height = 2, unit = "grid", z = 1L)
  ))
  document <- add_if_missing(document, visual_make_object(
    id = "evidence_group_001",
    type = "group",
    label = "Evidence Group",
    parent = canvas_id,
    children = c("callout_001", "explanation_001"),
    renderer = "ObjectGroup",
    role = "evidence_summary",
    properties = list(content = "Evidence summary"),
    order = 3L,
    layout = list(x = 9, y = 3, width = 4, height = 7, unit = "grid", z = 3L)
  ))
  document <- add_if_missing(document, visual_make_object(
    id = "callout_001",
    type = "callout",
    label = "Evidence Callout",
    parent = "evidence_group_001",
    renderer = "EvidenceCallout",
    role = "highlighted_finding",
    properties = list(
      `callout.label` = "Finding",
      `callout.value` = title,
      content = statement
    ),
    evidence_refs = evidence_id,
    order = 1L,
    layout = list(x = 1, y = 1, width = 4, height = 2, unit = "grid", z = 1L)
  ))
  document <- add_if_missing(document, visual_make_object(
    id = "explanation_001",
    type = "text",
    label = "Explanation",
    parent = "evidence_group_001",
    renderer = "SemanticText",
    role = "interpretation",
    properties = list(content = finding$explanation %||% "Use the plot, finding, and source together before treating this as decision evidence."),
    evidence_refs = evidence_id,
    order = 2L,
    layout = list(x = 1, y = 3, width = 4, height = 3, unit = "grid", z = 2L)
  ))
  document <- add_if_missing(document, visual_make_object(
    id = "source_001",
    type = "provenance",
    label = "Source",
    parent = canvas_id,
    renderer = "ProvenanceBlock",
    role = "source_provenance",
    properties = list(content = finding$source %||% paste("Source object:", plot_id)),
    evidence_refs = evidence_id,
    order = 4L,
    layout = list(x = 1, y = 10, width = 12, height = 2, unit = "grid", z = 4L)
  ))

  canvas_children <- document$objects[[canvas_id]]$children %||% character()
  ordered <- unique(c("heading_001", plot_id, "evidence_group_001", "source_001", canvas_children))
  document$objects[[canvas_id]]$children <- ordered[ordered %in% names(document$objects)]
  document$objects[[plot_id]]$layout <- modifyList(
    visual_default_layout("plot", "primary_visualization", 2L),
    document$objects[[plot_id]]$layout %||% list()
  )
  document$objects[[plot_id]]$layout$x <- 1
  document$objects[[plot_id]]$layout$y <- 3
  document$objects[[plot_id]]$layout$width <- 8
  document$objects[[plot_id]]$layout$height <- 7
  document$objects[[plot_id]]$layout$z <- 2L
  document$selected_object_id <- "heading_001"
  visual_document_normalize(document)
}

visual_document_has_composition <- function(document) {
  document <- visual_document_normalize(document)
  all(c("heading_001", "plot_001", "evidence_group_001", "callout_001", "explanation_001", "source_001") %in% names(document$objects))
}

visual_authoring_operation_registry <- function() {
  list(
    headline = list(label = "Headline", object_type = "text"),
    evidence_callout = list(label = "Evidence Callout", object_type = "callout"),
    summary_paragraph = list(label = "Summary Paragraph", object_type = "text"),
    interpretation = list(label = "Interpretation", object_type = "text"),
    key_finding = list(label = "Key Finding", object_type = "callout"),
    recommendation = list(label = "Recommendation", object_type = "recommendation"),
    warning = list(label = "Warning", object_type = "warning"),
    limitation = list(label = "Limitation", object_type = "limitation"),
    methodology = list(label = "Methodology", object_type = "methodology"),
    provenance = list(label = "Provenance", object_type = "provenance"),
    references = list(label = "References", object_type = "reference"),
    supporting_plot = list(label = "Supporting Plot", object_type = "plot"),
    supporting_table = list(label = "Supporting Table", object_type = "table"),
    comparison_panel = list(label = "Comparison Panel", object_type = "comparison_panel"),
    timeline = list(label = "Timeline", object_type = "timeline"),
    narrative_sequence = list(label = "Narrative Sequence", object_type = "section"),
    container = list(label = "Container", object_type = "group"),
    section = list(label = "Section", object_type = "section"),
    group = list(label = "Group", object_type = "group"),
    spacer = list(label = "Spacer", object_type = "spacer"),
    divider = list(label = "Divider", object_type = "divider")
  )
}

visual_authoring_adapter_contract <- function(object_type) {
  object <- visual_make_object(
    id = paste0(object_type, "_contract"),
    type = object_type,
    label = visual_object_default_label(object_type, object_type)
  )
  list(
    object_type = object_type,
    adapter = visual_renderer_adapter(object),
    methods = c("render", "propose", "validate", "mutate", "serialize", "deserialize", "inspect"),
    operations = c("render", "propose", "validate", "mutate", "serialize", "deserialize", "inspect")
  )
}

visual_authoring_vector <- function(x) {
  x <- x %||% character()
  x <- as.character(unlist(x, use.names = FALSE))
  unique(x[!is.na(x) & nzchar(x)])
}

visual_authoring_evidence_context <- function(evidence = list()) {
  evidence_ids <- visual_authoring_vector(
    evidence$evidence_ids %||% evidence$evidence_id %||% evidence$id
  )
  source_artifacts <- visual_authoring_vector(
    evidence$source_artifacts %||% evidence$source_artifact %||% evidence$artifact_id
  )
  if (!length(evidence_ids) && length(source_artifacts)) {
    evidence_ids <- source_artifacts
  }

  list(
    evidence_ids = evidence_ids,
    source_artifacts = source_artifacts,
    title = evidence$title %||% evidence$finding %||% NULL,
    statement = evidence$statement %||% NULL,
    explanation = evidence$explanation %||% NULL,
    recommendation = evidence$recommendation %||% NULL,
    limitation = evidence$limitation %||% NULL,
    source = evidence$source %||% NULL
  )
}

visual_authoring_object_extension <- function(proposal_id, operation, evidence_context, rationale, confidence) {
  list(
    authoring = list(
      originating_evidence_ids = evidence_context$evidence_ids,
      source_artifacts = evidence_context$source_artifacts,
      generation_rationale = rationale,
      confidence = confidence,
      version = VISUAL_DOCUMENT_SCHEMA_VERSION,
      creation_pathway = "semantic_authoring_engine",
      authoring_operation = operation,
      proposal_id = proposal_id,
      status = "proposed"
    )
  )
}

visual_authoring_has_role <- function(document, roles) {
  any(vapply(document$objects, function(object) {
    identical(object$type, "text") && (object$role %||% "") %in% roles
  }, logical(1)))
}

visual_authoring_missing_components <- function(document, evidence = list()) {
  document <- visual_document_normalize(document)
  ctx <- visual_authoring_evidence_context(evidence)
  objects <- document$objects
  missing <- character()

  if (!visual_authoring_has_role(document, c("headline", "summary_heading"))) {
    missing <- c(missing, "title")
  }
  if (!visual_authoring_has_role(document, c("interpretation", "explanation"))) {
    missing <- c(missing, "interpretation")
  }
  has_evidence <- any(vapply(objects, function(object) {
    length(object$evidence_refs %||% character()) > 0L
  }, logical(1)))
  if (!has_evidence || !length(ctx$evidence_ids)) {
    missing <- c(missing, "supporting_evidence")
  }
  if (!any(vapply(objects, function(object) identical(object$type, "provenance"), logical(1)))) {
    missing <- c(missing, "provenance")
  }
  if (!any(vapply(objects, function(object) identical(object$type, "warning") || identical(object$role, "uncertainty"), logical(1)))) {
    missing <- c(missing, "uncertainty")
  }
  if (!any(vapply(objects, function(object) identical(object$type, "recommendation"), logical(1)))) {
    missing <- c(missing, "recommendations")
  }
  if (!any(vapply(objects, function(object) identical(object$type, "limitation"), logical(1)))) {
    missing <- c(missing, "limitations")
  }
  if (!any(vapply(objects, function(object) identical(object$type, "reference"), logical(1)))) {
    missing <- c(missing, "references")
  }

  unique(missing)
}

visual_authoring_next_object_id <- function(document, preferred_id, type) {
  if (!preferred_id %in% names(document$objects)) {
    return(preferred_id)
  }
  index <- 2L
  repeat {
    candidate <- sprintf("%s_%03d", type, index)
    if (!candidate %in% names(document$objects)) {
      return(candidate)
    }
    index <- index + 1L
  }
}

visual_authoring_new_object <- function(
  document,
  proposal_id,
  operation,
  id,
  type,
  label,
  parent,
  role,
  properties,
  evidence_context,
  rationale,
  confidence,
  order,
  layout = NULL,
  children = character(),
  evidence_refs = NULL
) {
  id <- visual_authoring_next_object_id(document, id, type)
  visual_make_object(
    id = id,
    type = type,
    label = label,
    parent = parent,
    children = children,
    renderer = sub("Adapter$", "", visual_authoring_adapter_contract(type)$adapter),
    role = role,
    properties = properties,
    evidence_refs = evidence_refs %||% evidence_context$evidence_ids,
    extension = visual_authoring_object_extension(
      proposal_id,
      operation,
      evidence_context,
      rationale,
      confidence
    ),
    order = order,
    layout = layout
  )
}

visual_authoring_create_proposal <- function(
  document,
  evidence = list(),
  intent = "explanatory_visual",
  timestamp = NULL,
  confidence = 0.82
) {
  document <- visual_document_normalize(document)
  ctx <- visual_authoring_evidence_context(evidence)
  missing <- visual_authoring_missing_components(document, evidence)
  seed <- paste(c(intent, document$revision, missing, ctx$evidence_ids, names(document$authoring$proposals)), collapse = "_")
  seed <- gsub("[^A-Za-z0-9_]+", "_", seed)
  proposal_id <- paste0("proposal_", substr(seed, 1L, 56L))
  timestamp <- timestamp %||% format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  plot <- document$objects$plot_001 %||% list()
  canvas_id <- if ("canvas_001" %in% names(document$objects)) "canvas_001" else document$selected_object_id
  title <- ctx$title %||% plot$properties[["title.text"]] %||% plot$label %||% "What this visual shows"
  statement <- ctx$statement %||% paste(
    "This",
    tolower(plot$label %||% "visual"),
    "can become a clearer evidence object with interpretation and provenance."
  )
  rationale <- "The document is missing explanatory components required for decision-ready visual evidence."
  new_objects <- list()

  if ("supporting_evidence" %in% missing && !"evidence_group_001" %in% names(document$objects)) {
    new_objects$evidence_group_001 <- visual_authoring_new_object(
      document, proposal_id, "container", "evidence_group_001", "group",
      "Evidence Group", canvas_id, "evidence_summary",
      list(content = "Evidence summary"), ctx, rationale, confidence, 3L,
      layout = list(x = 9, y = 3, width = 4, height = 7, unit = "grid", z = 3L)
    )
  }
  parent_for_evidence <- if ("evidence_group_001" %in% names(document$objects) || "evidence_group_001" %in% names(new_objects)) {
    "evidence_group_001"
  } else {
    canvas_id
  }
  if ("title" %in% missing) {
    new_objects$heading_001 <- visual_authoring_new_object(
      document, proposal_id, "headline", "heading_001", "text",
      "Heading", canvas_id, "headline", list(content = title),
      ctx, rationale, confidence, 1L,
      layout = list(x = 1, y = 1, width = 12, height = 2, unit = "grid", z = 1L)
    )
  }
  if ("supporting_evidence" %in% missing) {
    new_objects$callout_001 <- visual_authoring_new_object(
      document, proposal_id, "evidence_callout", "callout_001", "callout",
      "Evidence Callout", parent_for_evidence, "highlighted_finding",
      list(`callout.label` = "Finding", `callout.value` = title, content = statement),
      ctx, rationale, confidence, 1L,
      layout = list(x = 1, y = 1, width = 4, height = 2, unit = "grid", z = 1L)
    )
  }
  if ("interpretation" %in% missing) {
    new_objects$explanation_001 <- visual_authoring_new_object(
      document, proposal_id, "interpretation", "explanation_001", "text",
      "Explanation", parent_for_evidence, "interpretation",
      list(content = ctx$explanation %||% "Use the visual, highlighted finding, and source together before treating this as decision evidence."),
      ctx, rationale, confidence, 2L,
      layout = list(x = 1, y = 3, width = 4, height = 3, unit = "grid", z = 2L)
    )
  }
  if ("uncertainty" %in% missing) {
    new_objects$warning_001 <- visual_authoring_new_object(
      document, proposal_id, "warning", "warning_001", "warning",
      "Uncertainty", parent_for_evidence, "uncertainty",
      list(content = "Confirm assumptions and inspect segment behavior before acting on this visual."),
      ctx, rationale, confidence, 3L
    )
  }
  if ("recommendations" %in% missing) {
    new_objects$recommendation_001 <- visual_authoring_new_object(
      document, proposal_id, "recommendation", "recommendation_001", "recommendation",
      "Recommendation", parent_for_evidence, "recommendation",
      list(content = ctx$recommendation %||% "Preserve this visual as supporting evidence if it clarifies the analytical claim."),
      ctx, rationale, confidence, 4L
    )
  }
  if ("limitations" %in% missing) {
    new_objects$limitation_001 <- visual_authoring_new_object(
      document, proposal_id, "limitation", "limitation_001", "limitation",
      "Limitation", parent_for_evidence, "limitation",
      list(content = ctx$limitation %||% "The visual explains observed structure; it does not by itself prove causality."),
      ctx, rationale, confidence, 5L
    )
  }
  if ("provenance" %in% missing) {
    new_objects$source_001 <- visual_authoring_new_object(
      document, proposal_id, "provenance", "source_001", "provenance",
      "Source", canvas_id, "source_provenance",
      list(content = ctx$source %||% paste("Source object:", plot$id %||% "plot_001")),
      ctx, rationale, confidence, 4L,
      layout = list(x = 1, y = 10, width = 12, height = 2, unit = "grid", z = 4L)
    )
  }
  if ("references" %in% missing) {
    new_objects$references_001 <- visual_authoring_new_object(
      document, proposal_id, "references", "references_001", "reference",
      "References", canvas_id, "references",
      list(content = paste(c(ctx$evidence_ids, ctx$source_artifacts), collapse = ", ")),
      ctx, rationale, confidence, 5L
    )
  }

  if ("evidence_group_001" %in% names(new_objects)) {
    new_objects$evidence_group_001$children <- intersect(
      c("callout_001", "explanation_001", "warning_001", "recommendation_001", "limitation_001"),
      names(new_objects)
    )
  }

  list(
    id = proposal_id,
    proposal_id = proposal_id,
    timestamp = timestamp,
    intent = intent,
    status = "proposed",
    originating_evidence_ids = ctx$evidence_ids,
    source_artifacts = ctx$source_artifacts,
    rationale = rationale,
    missing_components = missing,
    affected_objects = unique(c(names(new_objects), "plot_001")),
    new_objects = new_objects,
    modified_objects = list(),
    confidence = confidence,
    expected_user_value = "Adds explanation, uncertainty, recommendation, and provenance around the selected visual.",
    rollback_metadata = list(
      base_revision = document$revision,
      existing_object_ids = names(document$objects)
    ),
    object_decisions = stats::setNames(
      lapply(names(new_objects), function(id) list(object_id = id, status = "proposed")),
      names(new_objects)
    )
  )
}

visual_authoring_store_proposal <- function(document, proposal) {
  document <- visual_document_normalize(document)
  document$authoring$proposals[[proposal$proposal_id]] <- proposal
  document$authoring$history <- append(document$authoring$history, list(list(
    type = "proposal_created",
    proposal_id = proposal$proposal_id,
    at = proposal$timestamp
  )))
  visual_document_normalize(document)
}

visual_authoring_get_proposal <- function(document, proposal_id = NULL) {
  document <- visual_document_normalize(document)
  proposals <- document$authoring$proposals %||% list()
  if (!length(proposals)) {
    return(NULL)
  }
  proposal_id <- proposal_id %||% names(proposals)[[length(proposals)]]
  proposals[[proposal_id]]
}

visual_authoring_reject_proposal <- function(document, proposal_id = NULL, reason = NULL) {
  document <- visual_document_normalize(document)
  proposal <- visual_authoring_get_proposal(document, proposal_id)
  if (is.null(proposal)) {
    stop("No semantic authoring proposal is available to reject.", call. = FALSE)
  }
  proposal$status <- "rejected"
  proposal$rejected_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  proposal$rejection_reason <- reason %||% "Rejected by user."
  for (object_id in names(proposal$object_decisions %||% list())) {
    proposal$object_decisions[[object_id]]$status <- "rejected"
  }
  document$authoring$proposals[[proposal$proposal_id]] <- proposal
  document$authoring$history <- append(document$authoring$history, list(list(
    type = "proposal_rejected",
    proposal_id = proposal$proposal_id,
    at = proposal$rejected_at
  )))
  visual_document_normalize(document)
}

visual_authoring_reject_objects <- function(document, proposal_id = NULL, object_ids = character(), reason = NULL) {
  document <- visual_document_normalize(document)
  proposal <- visual_authoring_get_proposal(document, proposal_id)
  if (is.null(proposal)) {
    stop("No semantic authoring proposal is available.", call. = FALSE)
  }
  object_ids <- intersect(object_ids, names(proposal$new_objects %||% list()))
  for (object_id in object_ids) {
    proposal$object_decisions[[object_id]]$status <- "rejected"
    proposal$object_decisions[[object_id]]$reason <- reason %||% "Rejected by user."
  }
  document$authoring$proposals[[proposal$proposal_id]] <- proposal
  document$authoring$history <- append(document$authoring$history, list(list(
    type = "proposal_objects_rejected",
    proposal_id = proposal$proposal_id,
    object_ids = object_ids,
    reason = reason %||% "Rejected by user.",
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )))
  visual_document_normalize(document)
}

visual_authoring_apply_acceptance <- function(document, proposal, object_ids = NULL) {
  document <- visual_document_normalize(document)
  if (is.null(proposal)) {
    stop("No semantic authoring proposal is available to accept.", call. = FALSE)
  }
  requested <- object_ids %||% names(proposal$new_objects %||% list())
  rejected <- names(Filter(function(decision) identical(decision$status, "rejected"), proposal$object_decisions %||% list()))
  requested <- setdiff(intersect(requested, names(proposal$new_objects)), rejected)
  if ("evidence_group_001" %in% names(proposal$new_objects) && length(intersect(requested, proposal$new_objects$evidence_group_001$children))) {
    requested <- unique(c("evidence_group_001", requested))
  }

  for (object_id in requested) {
    object <- proposal$new_objects[[object_id]]
    if (object$id %in% names(document$objects)) {
      proposal$object_decisions[[object_id]]$status <- "skipped_duplicate"
      next
    }
    object$extension$authoring$status <- "accepted"
    document <- visual_document_add_object(document, object, parent_id = object$parent, select = FALSE)
    proposal$object_decisions[[object_id]]$status <- "accepted"
  }
  proposal$status <- if (!length(requested)) {
    "noop"
  } else if (length(setdiff(names(proposal$new_objects), requested)) || length(rejected)) {
    "partially_accepted"
  } else {
    "accepted"
  }
  proposal$accepted_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  document$authoring$proposals[[proposal$proposal_id]] <- proposal
  document$authoring$history <- append(document$authoring$history, list(list(
    type = "proposal_accepted",
    proposal_id = proposal$proposal_id,
    accepted_object_ids = requested,
    at = proposal$accepted_at
  )))
  visual_document_normalize(document)
}

visual_authoring_accept_proposal <- function(document, proposal_id = NULL, object_ids = NULL) {
  visual_document_apply_mutation(
    document,
    list(type = "accept_authoring_proposal", proposal_id = proposal_id, object_ids = object_ids)
  )
}

visual_authoring_proposal_summary <- function(proposal) {
  if (is.null(proposal)) {
    return(data.frame())
  }
  data.frame(
    object_id = names(proposal$new_objects %||% list()),
    object_type = vapply(proposal$new_objects %||% list(), function(object) object$type, character(1)),
    label = vapply(proposal$new_objects %||% list(), function(object) object$label, character(1)),
    status = vapply(proposal$object_decisions %||% list(), function(decision) decision$status %||% "proposed", character(1)),
    stringsAsFactors = FALSE
  )
}

visual_composition_timestamp <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

visual_composition_hash <- function(x) {
  if (requireNamespace("digest", quietly = TRUE)) {
    return(digest::digest(x, algo = "sha256"))
  }
  paste0("hash_", nchar(paste(capture.output(str(x)), collapse = "")))
}

visual_composition_object_text <- function(object) {
  paste(
    object$label %||% "",
    object$properties$content %||% "",
    object$properties$text %||% "",
    object$properties[["title.text"]] %||% "",
    object$properties[["callout.value"]] %||% "",
    collapse = " "
  )
}

visual_composition_evidence_ids <- function(document) {
  document <- visual_document_normalize(document)
  unique(unlist(lapply(document$objects, function(object) {
    c(
      object$evidence_refs %||% character(),
      object$extension$authoring$originating_evidence_ids %||% character(),
      object$extension$composition$originating_evidence_ids %||% character()
    )
  }), use.names = FALSE))
}

visual_composition_claim_classification <- function(text) {
  text <- tolower(text %||% "")
  if (grepl("\\b(recommend|should|next step|act|prioritize)\\b", text)) {
    "recommended"
  } else if (grepl("\\b(may|could|likely|suggest|interpret|implies)\\b", text)) {
    "interpreted"
  } else if (grepl("\\b(uncertain|unknown|gap|limitation|assumption)\\b", text)) {
    "uncertain"
  } else if (grepl("\\b(predicted|calculated|model|metric|score)\\b", text)) {
    "calculated"
  } else if (grepl("\\b(if|hypothesis|would)\\b", text)) {
    "hypothetical"
  } else if (nzchar(text)) {
    "observed"
  } else {
    "inferred"
  }
}

visual_composition_review_dimension_registry <- function() {
  list(
    evidence_coverage = list(
      label = "Evidence Coverage",
      description = "Every strong claim should have visible evidence or provenance.",
      evaluate = function(document) {
        evidence_ids <- visual_composition_evidence_ids(document)
        status <- if (length(evidence_ids)) "covered" else "gap"
        list(status = status, finding = if (length(evidence_ids)) {
          paste(length(evidence_ids), "evidence reference(s) are attached.")
        } else {
          "No evidence references are attached to the composition."
        })
      }
    ),
    narrative_coherence = list(
      label = "Narrative Coherence",
      description = "The document should have an orientation, interpretation, and next-action logic.",
      evaluate = function(document) {
        missing <- visual_authoring_missing_components(document, list())
        core_missing <- intersect(c("title", "interpretation", "recommendations"), missing)
        list(
          status = if (length(core_missing)) "partial" else "coherent",
          finding = if (length(core_missing)) {
            paste("Missing narrative component(s):", paste(core_missing, collapse = ", "))
          } else {
            "Orientation, interpretation, and recommendation components are present."
          }
        )
      }
    ),
    visual_hierarchy = list(
      label = "Visual Hierarchy",
      description = "The composition should make the primary visual and supporting text easy to scan.",
      evaluate = function(document) {
        plot <- document$objects$plot_001
        has_heading <- "heading_001" %in% names(document$objects)
        list(
          status = if (!is.null(plot) && has_heading) "clear" else "weak",
          finding = if (!is.null(plot) && has_heading) {
            "A primary visual and heading are available."
          } else {
            "The composition lacks either a primary visual or clear heading."
          }
        )
      }
    ),
    completeness = list(
      label = "Completeness",
      description = "A complete explanatory visual should include finding, interpretation, provenance, uncertainty, and next action.",
      evaluate = function(document) {
        missing <- visual_authoring_missing_components(document, list())
        list(
          status = if (!length(missing)) "complete" else if (length(missing) <= 2L) "partial" else "incomplete",
          finding = if (length(missing)) paste("Still missing:", paste(missing, collapse = ", ")) else "No required semantic components are missing."
        )
      }
    ),
    redundancy = list(
      label = "Redundancy",
      description = "Repeated labels or duplicated statements should not compete for attention.",
      evaluate = function(document) {
        text <- vapply(document$objects, visual_composition_object_text, character(1))
        text <- trimws(gsub("\\s+", " ", tolower(text[nzchar(trimws(text))])))
        duplicated_text <- unique(text[duplicated(text)])
        list(
          status = if (length(duplicated_text)) "duplicate_risk" else "distinct",
          finding = if (length(duplicated_text)) {
            paste("Duplicate language detected:", paste(utils::head(duplicated_text, 3L), collapse = "; "))
          } else {
            "No obvious duplicate statements were detected."
          }
        )
      }
    ),
    integrity = list(
      label = "Integrity",
      description = "Recommendations and interpretations should not outrun the available evidence.",
      evaluate = function(document) {
        texts <- vapply(document$objects, visual_composition_object_text, character(1))
        classes <- vapply(texts, visual_composition_claim_classification, character(1))
        has_recommendation <- any(classes == "recommended")
        has_uncertainty <- any(classes %in% c("uncertain", "interpreted"))
        list(
          status = if (has_recommendation && !has_uncertainty) "overclaim_risk" else "bounded",
          finding = if (has_recommendation && !has_uncertainty) {
            "A recommendation exists without visible uncertainty or limitation language."
          } else {
            "Claims appear bounded by interpretation, uncertainty, or provenance."
          },
          classifications = classes
        )
      }
    ),
    accessibility_readability = list(
      label = "Accessibility / Readability",
      description = "Readable documents use concise text and avoid dense, unstructured blocks.",
      evaluate = function(document) {
        text <- vapply(document$objects, visual_composition_object_text, character(1))
        long_blocks <- sum(nchar(text) > 220L, na.rm = TRUE)
        list(
          status = if (long_blocks) "dense" else "readable",
          finding = if (long_blocks) {
            paste(long_blocks, "text block(s) may be too dense for presentation.")
          } else {
            "Text blocks are concise enough for a visual document."
          }
        )
      }
    )
  )
}

visual_composition_review_dimension <- function(document, dimension_id) {
  registry <- visual_composition_review_dimension_registry()
  dimension <- registry[[dimension_id]]
  if (is.null(dimension)) {
    stop("Unknown composition review dimension: ", dimension_id, call. = FALSE)
  }
  result <- dimension$evaluate(document)
  list(
    dimension_id = dimension_id,
    label = dimension$label,
    description = dimension$description,
    status = result$status %||% "unknown",
    finding = result$finding %||% "",
    metadata = result[setdiff(names(result), c("status", "finding"))]
  )
}

visual_composition_detect_contradictions <- function(document) {
  texts <- tolower(vapply(document$objects, visual_composition_object_text, character(1)))
  if (any(grepl("\\brecommend|should|act\\b", texts)) && !any(grepl("\\buncertain|limitation|assumption|gap\\b", texts))) {
    return("Recommendation language is present without visible uncertainty, limitation, or assumption language.")
  }
  character()
}

visual_composition_create_review <- function(document, reviewer = "deterministic_composition_reviewer", evidence = list()) {
  document <- visual_document_normalize(document)
  dimensions <- lapply(names(visual_composition_review_dimension_registry()), function(id) {
    visual_composition_review_dimension(document, id)
  })
  names(dimensions) <- names(visual_composition_review_dimension_registry())
  findings <- vapply(dimensions, function(dimension) {
    paste(dimension$label, "-", dimension$finding)
  }, character(1))
  attention_findings <- unlist(lapply(dimensions, function(dimension) {
    if (dimension$status %in% c("gap", "partial", "weak", "incomplete", "duplicate_risk", "overclaim_risk", "dense")) {
      paste(dimension$label, "-", dimension$finding)
    } else {
      character()
    }
  }), use.names = FALSE)
  contradictions <- visual_composition_detect_contradictions(document)
  evidence_ids <- unique(c(visual_composition_evidence_ids(document), evidence$evidence_ids %||% character()))
  review_basis <- list(
    document_id = document$id,
    revision = document$revision,
    dimensions = dimensions,
    findings = findings,
    attention_findings = attention_findings,
    contradictions = contradictions,
    evidence_ids = evidence_ids
  )
  review_id <- paste0("composition_review_", substr(visual_composition_hash(review_basis), 1L, 10L))
  list(
    review_id = review_id,
    document_id = document$id,
    document_revision = document$revision,
    created_at = visual_composition_timestamp(),
    reviewer = reviewer,
    status = if (length(attention_findings) || length(contradictions)) "needs_attention" else "ready",
    dimensions = dimensions,
    findings = findings,
    attention_findings = attention_findings,
    contradictions = contradictions,
    evidence_ids = review_basis$evidence_ids,
    review_signature = visual_composition_hash(review_basis),
    schema_version = VISUAL_COMPOSITION_SCHEMA_VERSION
  )
}

visual_composition_store_review <- function(document, review) {
  document <- visual_document_normalize(document)
  document$composition$reviews[[review$review_id]] <- review
  document$composition$active_review_id <- review$review_id
  document$composition$history <- append(document$composition$history, list(list(
    type = "review_created",
    review_id = review$review_id,
    at = visual_composition_timestamp()
  )))
  visual_document_normalize(document)
}

visual_composition_get_review <- function(document, review_id = NULL) {
  document <- visual_document_normalize(document)
  review_id <- review_id %||% document$composition$active_review_id
  if (is.null(review_id)) return(NULL)
  document$composition$reviews[[review_id]]
}

visual_composition_strategy_registry <- function() {
  list(
    minimal_explanation = list(
      label = "Minimal Explanation",
      intent = "Add only the smallest set of objects needed to explain the current visual.",
      operations = c("add_heading", "add_callout", "add_explanation", "add_source")
    ),
    executive_narrative = list(
      label = "Executive Narrative",
      intent = "Create a concise decision-facing explanation with recommendation and uncertainty.",
      operations = c("add_heading", "add_callout", "add_explanation", "add_recommendation", "add_uncertainty")
    ),
    evidence_forward_analysis = list(
      label = "Evidence-Forward Analysis",
      intent = "Expose evidence, interpretation, limitations, recommendation, and provenance for skeptical review.",
      operations = c("add_heading", "add_callout", "add_explanation", "add_recommendation", "add_uncertainty", "add_limitation", "add_source")
    )
  )
}

visual_composition_allowed_operations <- function() {
  c(
    "add", "update", "remove", "move", "resize", "reorder", "group",
    "ungroup", "update_layout", "update_provenance", "update_narrative",
    "replace"
  )
}

visual_composition_allowed_claim_classifications <- function() {
  c("observed", "calculated", "inferred", "interpreted", "recommended", "uncertain", "hypothetical")
}

visual_composition_object_extension <- function(strategy_id, operation, claim_classification, evidence_ids, rationale) {
  list(
    composition = list(
      creation_pathway = "governed_composition_intelligence",
      strategy_id = strategy_id,
      operation = operation,
      claim_classification = claim_classification,
      originating_evidence_ids = evidence_ids,
      generation_rationale = rationale,
      version = VISUAL_COMPOSITION_SCHEMA_VERSION
    )
  )
}

visual_composition_strategy_objects <- function(strategy_id, evidence, evidence_ids) {
  finding_title <- evidence$title %||% evidence$statement %||% "Explain the visual finding"
  finding_statement <- evidence$statement %||% "This visual has a pattern worth explaining."
  explanation <- evidence$explanation %||% "The visual document combines the chart, interpretation, and provenance so the finding can be reviewed as evidence."
  recommendation <- evidence$recommendation %||% "Use this visual as supporting evidence after reviewing limitations."
  limitation <- evidence$limitation %||% "This visual supports interpretation; it does not prove causality by itself."
  source <- evidence$source %||% "Generated from the current Plot Studio visual document."
  list(
    add_heading = visual_make_object(
      id = paste0(strategy_id, "_heading"), type = "text", label = "Heading", parent = "canvas_001",
      renderer = "SemanticText", role = "headline", properties = list(content = finding_title),
      evidence_refs = evidence_ids,
      extension = visual_composition_object_extension(strategy_id, "add_heading", "observed", evidence_ids, "Orient the visual document around the main finding."),
      order = 20L, layout = list(x = 1, y = 1, width = 12, height = 2, unit = "grid", z = 20L)
    ),
    add_callout = visual_make_object(
      id = paste0(strategy_id, "_callout"), type = "callout", label = "Evidence Callout", parent = "canvas_001",
      renderer = "EvidenceCalloutAdapter", role = "key_finding",
      properties = list(`callout.label` = "Finding", `callout.value` = finding_title, content = finding_statement),
      evidence_refs = evidence_ids,
      extension = visual_composition_object_extension(strategy_id, "add_callout", "interpreted", evidence_ids, "Highlight the central interpretation without changing the plot."),
      order = 21L, layout = list(x = 9, y = 3, width = 4, height = 2, unit = "grid", z = 21L)
    ),
    add_explanation = visual_make_object(
      id = paste0(strategy_id, "_explanation"), type = "text", label = "Interpretation", parent = "canvas_001",
      renderer = "SemanticTextAdapter", role = "interpretation", properties = list(content = explanation),
      evidence_refs = evidence_ids,
      extension = visual_composition_object_extension(strategy_id, "add_explanation", "interpreted", evidence_ids, "Explain what the visible evidence means."),
      order = 22L, layout = list(x = 9, y = 5, width = 4, height = 3, unit = "grid", z = 22L)
    ),
    add_recommendation = visual_make_object(
      id = paste0(strategy_id, "_recommendation"), type = "recommendation", label = "Recommendation", parent = "canvas_001",
      renderer = "RecommendationAdapter", role = "next_action", properties = list(content = recommendation),
      evidence_refs = evidence_ids,
      extension = visual_composition_object_extension(strategy_id, "add_recommendation", "recommended", evidence_ids, "Make the next action explicit and evidence-linked."),
      order = 23L, layout = list(x = 9, y = 8, width = 4, height = 2, unit = "grid", z = 23L)
    ),
    add_uncertainty = visual_make_object(
      id = paste0(strategy_id, "_uncertainty"), type = "warning", label = "Uncertainty", parent = "canvas_001",
      renderer = "WarningAdapter", role = "uncertainty", properties = list(content = evidence$uncertainty %||% "Review uncertainty before treating this as decision-ready."),
      evidence_refs = evidence_ids,
      extension = visual_composition_object_extension(strategy_id, "add_uncertainty", "uncertain", evidence_ids, "Keep limitations visible beside recommendations."),
      order = 24L, layout = list(x = 9, y = 10, width = 4, height = 2, unit = "grid", z = 24L)
    ),
    add_limitation = visual_make_object(
      id = paste0(strategy_id, "_limitation"), type = "limitation", label = "Limitation", parent = "canvas_001",
      renderer = "LimitationAdapter", role = "limitation", properties = list(content = limitation),
      evidence_refs = evidence_ids,
      extension = visual_composition_object_extension(strategy_id, "add_limitation", "uncertain", evidence_ids, "Separate evidence support from methodological limits."),
      order = 25L, layout = list(x = 1, y = 11, width = 8, height = 2, unit = "grid", z = 25L)
    ),
    add_source = visual_make_object(
      id = paste0(strategy_id, "_source"), type = "provenance", label = "Source", parent = "canvas_001",
      renderer = "ProvenanceBlockAdapter", role = "source", properties = list(content = source),
      evidence_refs = evidence_ids,
      extension = visual_composition_object_extension(strategy_id, "add_source", "observed", evidence_ids, "Preserve source and provenance in the visual document."),
      order = 26L, layout = list(x = 1, y = 13, width = 12, height = 2, unit = "grid", z = 26L)
    )
  )
}

visual_composition_mutation <- function(operation, object, strategy_id, evidence_ids, rationale, dependencies = character()) {
  list(
    mutation_id = paste0(operation, "_", substr(visual_composition_hash(list(strategy_id, operation, object$id %||% "")), 1L, 8L)),
    operation = "add",
    semantic_operation = operation,
    object_id = object$id,
    object_type = object$type,
    label = object$label,
    object = object,
    parent_id = object$parent %||% "canvas_001",
    dependencies = dependencies,
    evidence_ids = evidence_ids,
    rationale = rationale,
    claim_classification = object$extension$composition$claim_classification %||% "interpreted",
    reversibility_metadata = list(type = "remove_object", object_id = object$id, parent_id = object$parent %||% "canvas_001")
  )
}

visual_composition_create_strategy <- function(document, review, strategy_id, evidence = list()) {
  registry <- visual_composition_strategy_registry()
  template <- registry[[strategy_id]]
  if (is.null(template)) {
    stop("Unknown composition strategy: ", strategy_id, call. = FALSE)
  }
  evidence_ids <- unique(c(review$evidence_ids %||% character(), evidence$evidence_ids %||% "current_visual_evidence"))
  objects <- visual_composition_strategy_objects(strategy_id, evidence, evidence_ids)
  operations <- template$operations
  plan <- lapply(operations, function(operation) {
    dependencies <- if (operation %in% c("add_explanation", "add_recommendation", "add_uncertainty", "add_limitation", "add_source")) {
      paste0("add_callout_", substr(visual_composition_hash(list(strategy_id, "add_callout", objects$add_callout$id)), 1L, 8L))
    } else {
      character()
    }
    visual_composition_mutation(operation, objects[[operation]], strategy_id, evidence_ids, template$intent, dependencies)
  })
  names(plan) <- vapply(plan, function(mutation) mutation$mutation_id, character(1))
  strategy_basis <- list(review_id = review$review_id, strategy_id = strategy_id, operations = operations, document_revision = document$revision)
  list(
    strategy_id = paste0("composition_strategy_", strategy_id, "_", substr(visual_composition_hash(strategy_basis), 1L, 8L)),
    strategy_key = strategy_id,
    review_id = review$review_id,
    label = template$label,
    intent = template$intent,
    status = "proposed",
    created_at = visual_composition_timestamp(),
    dimensions_addressed = names(review$dimensions %||% list()),
    mutation_plan = plan,
    strategy_signature = visual_composition_hash(strategy_basis),
    schema_version = VISUAL_COMPOSITION_SCHEMA_VERSION
  )
}

visual_composition_generate_strategies <- function(document, review = NULL, evidence = list()) {
  document <- visual_document_normalize(document)
  review <- review %||% visual_composition_get_review(document) %||% visual_composition_create_review(document, evidence = evidence)
  strategies <- lapply(names(visual_composition_strategy_registry()), function(strategy_id) {
    visual_composition_create_strategy(document, review, strategy_id, evidence)
  })
  stats::setNames(strategies, vapply(strategies, function(strategy) strategy$strategy_id, character(1)))
}

visual_composition_store_strategies <- function(document, strategies) {
  document <- visual_document_normalize(document)
  for (strategy in strategies) {
    document$composition$strategies[[strategy$strategy_id]] <- strategy
  }
  if (length(strategies)) {
    document$composition$active_strategy_id <- strategies[[1]]$strategy_id
  }
  document$composition$history <- append(document$composition$history, list(list(
    type = "strategies_generated",
    strategy_ids = vapply(strategies, function(strategy) strategy$strategy_id, character(1)),
    at = visual_composition_timestamp()
  )))
  visual_document_normalize(document)
}

visual_composition_get_strategy <- function(document, strategy_id = NULL) {
  document <- visual_document_normalize(document)
  strategy_id <- strategy_id %||% document$composition$active_strategy_id
  if (is.null(strategy_id)) return(NULL)
  document$composition$strategies[[strategy_id]]
}

visual_composition_validate_dependencies <- function(strategy, mutation_ids = NULL) {
  selected <- mutation_ids %||% names(strategy$mutation_plan %||% list())
  missing <- unlist(lapply(strategy$mutation_plan[selected], function(mutation) {
    setdiff(mutation$dependencies %||% character(), selected)
  }), use.names = FALSE)
  unique(missing)
}

visual_composition_apply_plan_internal <- function(document, strategy, mutation_ids = NULL) {
  document <- visual_document_normalize(document)
  mutation_ids <- mutation_ids %||% names(strategy$mutation_plan %||% list())
  missing_dependencies <- visual_composition_validate_dependencies(strategy, mutation_ids)
  if (length(missing_dependencies)) {
    stop("missing required composition mutation dependencies: ", paste(missing_dependencies, collapse = ", "), call. = FALSE)
  }
  for (mutation_id in mutation_ids) {
    mutation <- strategy$mutation_plan[[mutation_id]]
    if (is.null(mutation) || mutation$object_id %in% names(document$objects)) next
    document <- visual_document_add_object(document, mutation$object, parent_id = mutation$parent_id, select = FALSE)
  }
  visual_document_normalize(document)
}

visual_composition_create_branch <- function(document, strategy_id = NULL, mutation_ids = NULL) {
  document <- visual_document_normalize(document)
  strategy <- visual_composition_get_strategy(document, strategy_id)
  if (is.null(strategy)) {
    stop("No composition strategy is available for preview.", call. = FALSE)
  }
  preview <- visual_composition_apply_plan_internal(visual_document_snapshot(document), strategy, mutation_ids)
  branch_basis <- list(document_id = document$id, strategy_id = strategy$strategy_id, mutation_ids = mutation_ids, revision = document$revision)
  branch_id <- paste0("composition_branch_", substr(visual_composition_hash(branch_basis), 1L, 10L))
  document$composition$branches[[branch_id]] <- list(
    branch_id = branch_id,
    strategy_id = strategy$strategy_id,
    mutation_ids = mutation_ids %||% names(strategy$mutation_plan %||% list()),
    status = "preview",
    created_at = visual_composition_timestamp(),
    preview_document = preview,
    branch_signature = visual_composition_hash(branch_basis),
    schema_version = VISUAL_COMPOSITION_SCHEMA_VERSION
  )
  document$composition$active_branch_id <- branch_id
  document$composition$history <- append(document$composition$history, list(list(
    type = "branch_created",
    branch_id = branch_id,
    strategy_id = strategy$strategy_id,
    at = visual_composition_timestamp()
  )))
  visual_document_normalize(document)
}

visual_composition_compare_strategies <- function(document) {
  document <- visual_document_normalize(document)
  strategies <- document$composition$strategies %||% list()
  if (!length(strategies)) return(data.frame())
  rows <- unlist(lapply(strategies, function(strategy) {
    review <- document$composition$reviews[[strategy$review_id]] %||% list(dimensions = list())
    dimensions <- review$dimensions %||% list()
    lapply(names(dimensions), function(dimension_id) {
      dimension <- dimensions[[dimension_id]]
      data.frame(
        strategy_id = strategy$strategy_id,
        strategy = strategy$label %||% strategy$strategy_id,
        strategy_status = strategy$status %||% "proposed",
        dimension_id = dimension_id,
        dimension = dimension$label %||% dimension_id,
        status = dimension$status %||% "unknown",
        finding = dimension$finding %||% "",
        mutations = length(strategy$mutation_plan %||% list()),
        intent = strategy$intent %||% "",
        stringsAsFactors = FALSE
      )
    })
  }), recursive = FALSE)
  do.call(rbind, rows)
}

visual_composition_accept_strategy <- function(document, strategy_id = NULL, mutation_ids = NULL) {
  visual_document_apply_mutation(document, list(
    type = "accept_composition_strategy",
    strategy_id = strategy_id,
    mutation_ids = mutation_ids
  ))
}

visual_composition_reject_strategy <- function(document, strategy_id = NULL, reason = "Rejected by user") {
  visual_document_apply_mutation(document, list(
    type = "reject_composition_strategy",
    strategy_id = strategy_id,
    reason = reason
  ))
}

visual_document_object_property <- function(document, object_id, property, default = "") {
  object <- document$objects[[object_id]]
  if (is.null(object)) {
    return(default)
  }
  object$properties[[property]] %||% default
}

visual_document_composition_ui <- function(document, plot_ui) {
  document <- visual_document_normalize(document)
  if (!visual_document_has_composition(document)) {
    return(plot_ui)
  }

  heading <- visual_document_object_property(
    document,
    "heading_001",
    "content",
    document$title %||% "Explanatory visual"
  )
  callout_label <- visual_document_object_property(document, "callout_001", "callout.label", "Finding")
  callout_value <- visual_document_object_property(document, "callout_001", "callout.value", heading)
  callout_body <- visual_document_object_property(document, "callout_001", "content", "")
  explanation <- visual_document_object_property(document, "explanation_001", "content", "")
  source <- visual_document_object_property(document, "source_001", "content", "")
  refs <- document$objects$callout_001$evidence_refs %||% character()
  semantic_block <- function(object_id, heading) {
    object <- document$objects[[object_id]]
    if (is.null(object) || isFALSE(object$visible)) {
      return(NULL)
    }
    content <- object$properties$content %||% ""
    if (!nzchar(content)) {
      return(NULL)
    }
    tags$div(
      class = paste(
        "aq-visual-composition-copy",
        paste0("aq-visual-composition-", gsub("_001$", "", object_id))
      ),
      `data-object-id` = object_id,
      tags$h4(heading),
      tags$p(content)
    )
  }

  tags$div(
    class = "aq-visual-composition",
    `data-schema-version` = document$schema_version %||% VISUAL_DOCUMENT_SCHEMA_VERSION,
    tags$div(
      class = "aq-visual-composition-heading",
      `data-object-id` = "heading_001",
      tags$p(class = "aq-plot-kicker", "Explanatory visual"),
      tags$h3(heading),
      tags$p("A visual document keeps the chart, interpretation, evidence, and provenance in one authored composition.")
    ),
    tags$div(
      class = "aq-visual-composition-grid aq-visual-composition-grid-single",
      tags$div(
        class = "aq-visual-composition-plot",
        `data-object-id` = "plot_001",
        plot_ui
      ),
      tags$details(
        class = "aq-visual-composition-evidence-panel",
        `data-object-id` = "evidence_group_001",
        tags$summary(
          tags$span(class = "aq-plot-kicker", "Evidence context"),
          tags$span(
            class = "aq-visual-composition-evidence-summary",
            "Interpretation, uncertainty, recommendation, and provenance"
          ),
          tags$span(class = "aq-visual-composition-evidence-toggle", "Open")
        ),
        tags$div(
          class = "aq-visual-composition-evidence-grid",
          tags$div(
            class = "aq-visual-composition-callout",
            `data-object-id` = "callout_001",
            tags$span(callout_label),
            tags$strong(callout_value),
            tags$p(callout_body)
          ),
          tags$div(
            class = "aq-visual-composition-copy",
            `data-object-id` = "explanation_001",
            tags$h4("Interpretation"),
            tags$p(explanation)
          ),
          semantic_block("warning_001", "Uncertainty"),
          semantic_block("recommendation_001", "Recommendation"),
          semantic_block("limitation_001", "Limitation"),
          semantic_block("references_001", "References"),
          tags$div(
            class = "aq-visual-composition-source",
            `data-object-id` = "source_001",
            tags$h4("Source"),
            tags$p(source),
            if (length(refs)) {
              tags$ul(lapply(refs, tags$li))
            }
          )
        )
      )
    )
  )
}

visual_document_apply_mutation <- function(document, mutation) {
  document <- visual_document_normalize(document)
  mutation$type <- visual_list_get(mutation, "type", "set_property")
  object_id <- visual_list_get(mutation, "object_id") %||%
    visual_list_get(mutation, "parent_id") %||%
    document$selected_object_id

  document_level_mutations <- c("create_composition_branch", "accept_composition_strategy", "reject_composition_strategy")
  if (!mutation$type %in% document_level_mutations && !object_id %in% names(document$objects)) {
    stop("Cannot mutate missing visual object: ", object_id, call. = FALSE)
  }
  object <- document$objects[[object_id]] %||% document$objects[[document$selected_object_id]]
  lock_exempt_mutations <- c(
    "set_lock_state", "select_object", "restore_snapshot",
    "accept_authoring_proposal", "reject_authoring_proposal",
    "reject_authoring_objects", "create_composition_branch",
    "accept_composition_strategy", "reject_composition_strategy"
  )
  if (isTRUE(object$locked) && !mutation$type %in% lock_exempt_mutations) {
    stop("Visual object is locked: ", object$label, call. = FALSE)
  }

  before <- document

  if (identical(mutation$type, "set_property")) {
    property <- visual_list_get(mutation, "property")
    if (is.null(property) || !nzchar(property)) {
      stop("set_property mutation requires property.", call. = FALSE)
    }
    object$properties[[property]] <- visual_list_get(mutation, "value")
    document$objects[[object_id]] <- object
  } else if (identical(mutation$type, "reset_property")) {
    property <- visual_list_get(mutation, "property")
    schema <- visual_property_schema()[[property]]
    object$properties[[property]] <- schema$default
    document$objects[[object_id]] <- object
  } else if (identical(mutation$type, "rename_object")) {
    label <- trimws(visual_list_get(mutation, "label", ""))
    if (!nzchar(label)) {
      stop("rename_object mutation requires a non-empty label.", call. = FALSE)
    }
    object$label <- label
    document$objects[[object_id]] <- object
  } else if (identical(mutation$type, "update_object")) {
    values <- visual_list_get(mutation, "values", list())
    if (!is.list(values)) {
      stop("update_object mutation requires a list of values.", call. = FALSE)
    }
    has_label <- "label" %in% names(mutation)
    if (has_label) {
      label <- trimws(as.character(visual_list_get(mutation, "label", ""))[1])
      if (!nzchar(label)) {
        stop("update_object mutation requires a non-empty label.", call. = FALSE)
      }
      object$label <- label
    }
    if (length(values)) {
      for (property in names(values)) {
        object$properties[[property]] <- values[[property]]
      }
    }
    if (!has_label && !length(values)) {
      stop("update_object mutation requires a label or values.", call. = FALSE)
    }
    document$objects[[object_id]] <- object
    document$selected_object_id <- object_id
  } else if (identical(mutation$type, "set_visibility")) {
    object$visible <- isTRUE(visual_list_get(mutation, "visible"))
    document$objects[[object_id]] <- object
  } else if (identical(mutation$type, "set_lock_state")) {
    object$locked <- isTRUE(visual_list_get(mutation, "locked"))
    document$objects[[object_id]] <- object
  } else if (identical(mutation$type, "set_layout")) {
    layout <- visual_list_get(mutation, "layout", list())
    if (!length(layout)) {
      stop("set_layout mutation requires layout values.", call. = FALSE)
    }
    object$layout <- object$layout %||% visual_default_layout(object$type, object$role, object$order)
    for (layout_name in names(layout)) {
      object$layout[[layout_name]] <- layout[[layout_name]]
    }
    document$objects[[object_id]] <- object
  } else if (identical(mutation$type, "add_object")) {
    new_object <- visual_list_get(mutation, "object")
    if (is.null(new_object)) {
      stop("add_object mutation requires object.", call. = FALSE)
    }
    document <- visual_document_add_object(
      document,
      new_object,
      parent_id = visual_list_get(mutation, "parent_id") %||% new_object$parent,
      select = isTRUE(visual_list_get(mutation, "select", TRUE))
    )
  } else if (identical(mutation$type, "remove_object")) {
    remove_id <- visual_list_get(mutation, "object_id")
    if (is.null(remove_id) || !remove_id %in% names(document$objects)) {
      stop("remove_object mutation requires an existing object_id.", call. = FALSE)
    }
    if (identical(remove_id, "canvas_001") || identical(remove_id, "plot_001")) {
      stop("Cannot remove required visual document object: ", remove_id, call. = FALSE)
    }
    collect_descendants <- function(id) {
      children <- document$objects[[id]]$children %||% character()
      unique(c(id, unlist(lapply(children, collect_descendants), use.names = FALSE)))
    }
    remove_ids <- collect_descendants(remove_id)
    parent_id <- document$objects[[remove_id]]$parent %||% NULL
    if (!is.null(parent_id) && parent_id %in% names(document$objects)) {
      document$objects[[parent_id]]$children <- setdiff(document$objects[[parent_id]]$children %||% character(), remove_ids)
    }
    document$objects[remove_ids] <- NULL
    if (document$selected_object_id %in% remove_ids) {
      document$selected_object_id <- if (!is.null(parent_id) && parent_id %in% names(document$objects)) {
        parent_id
      } else if ("plot_001" %in% names(document$objects)) {
        "plot_001"
      } else {
        names(document$objects)[[1L]]
      }
    }
  } else if (identical(mutation$type, "make_explanatory_visual")) {
    document <- visual_document_make_explanatory(document, finding = visual_list_get(mutation, "finding", list()))
  } else if (identical(mutation$type, "create_composition_branch")) {
    document <- visual_composition_create_branch(
      document,
      strategy_id = visual_list_get(mutation, "strategy_id"),
      mutation_ids = visual_list_get(mutation, "mutation_ids")
    )
  } else if (identical(mutation$type, "accept_composition_strategy")) {
    strategy_id <- visual_list_get(mutation, "strategy_id")
    mutation_ids <- visual_list_get(mutation, "mutation_ids")
    strategy <- visual_composition_get_strategy(document, strategy_id)
    if (is.null(strategy)) {
      stop("No composition strategy is available to accept.", call. = FALSE)
    }
    applied_ids <- mutation_ids %||% names(strategy$mutation_plan %||% list())
    document <- visual_composition_apply_plan_internal(document, strategy, applied_ids)
    strategy$status <- "accepted"
    strategy$accepted_at <- visual_composition_timestamp()
    strategy$accepted_mutation_ids <- applied_ids
    document$composition$strategies[[strategy$strategy_id]] <- strategy
    document$composition$active_strategy_id <- strategy$strategy_id
    document$composition$decisions <- append(document$composition$decisions, list(list(
      type = "strategy_accepted",
      strategy_id = strategy$strategy_id,
      mutation_ids = applied_ids,
      at = strategy$accepted_at
    )))
    document$composition$history <- append(document$composition$history, list(list(
      type = "strategy_accepted",
      strategy_id = strategy$strategy_id,
      mutation_ids = applied_ids,
      at = strategy$accepted_at
    )))
  } else if (identical(mutation$type, "reject_composition_strategy")) {
    strategy_id <- visual_list_get(mutation, "strategy_id")
    strategy <- visual_composition_get_strategy(document, strategy_id)
    if (is.null(strategy)) {
      stop("No composition strategy is available to reject.", call. = FALSE)
    }
    rejected_at <- visual_composition_timestamp()
    strategy$status <- "rejected"
    strategy$rejected_at <- rejected_at
    strategy$rejection_reason <- visual_list_get(mutation, "reason", "Rejected by user")
    document$composition$strategies[[strategy$strategy_id]] <- strategy
    document$composition$decisions <- append(document$composition$decisions, list(list(
      type = "strategy_rejected",
      strategy_id = strategy$strategy_id,
      reason = strategy$rejection_reason,
      at = rejected_at
    )))
    document$composition$history <- append(document$composition$history, list(list(
      type = "strategy_rejected",
      strategy_id = strategy$strategy_id,
      at = rejected_at
    )))
  } else if (identical(mutation$type, "accept_authoring_proposal")) {
    proposal <- visual_authoring_get_proposal(document, visual_list_get(mutation, "proposal_id"))
    document <- visual_authoring_apply_acceptance(document, proposal, visual_list_get(mutation, "object_ids"))
  } else if (identical(mutation$type, "reject_authoring_proposal")) {
    document <- visual_authoring_reject_proposal(
      document,
      visual_list_get(mutation, "proposal_id"),
      visual_list_get(mutation, "reason")
    )
  } else if (identical(mutation$type, "reject_authoring_objects")) {
    document <- visual_authoring_reject_objects(
      document,
      visual_list_get(mutation, "proposal_id"),
      visual_list_get(mutation, "object_ids", character()),
      visual_list_get(mutation, "reason")
    )
  } else if (identical(mutation$type, "reorder_object")) {
    parent_id <- object$parent
    direction <- as.integer(visual_list_get(mutation, "direction", 0L))
    if (!is.null(parent_id) && parent_id %in% names(document$objects) && direction != 0L) {
      siblings <- document$objects[[parent_id]]$children
      index <- match(object_id, siblings)
      swap <- index + direction
      if (!is.na(index) && swap >= 1L && swap <= length(siblings)) {
        siblings[c(index, swap)] <- siblings[c(swap, index)]
        document$objects[[parent_id]]$children <- siblings
        for (i in seq_along(siblings)) {
          document$objects[[siblings[[i]]]]$order <- i
        }
      }
    }
  } else if (identical(mutation$type, "select_object")) {
    return(visual_document_select(document, object_id, origin = visual_list_get(mutation, "source", "user")))
  } else if (identical(mutation$type, "apply_preset")) {
    values <- visual_list_get(mutation, "values", list())
    for (property in names(values)) {
      object$properties[[property]] <- values[[property]]
    }
    document$objects[[object_id]] <- object
  } else if (identical(mutation$type, "restore_snapshot")) {
    snapshot <- visual_list_get(mutation, "snapshot")
    if (is.null(snapshot)) {
      stop("restore_snapshot mutation requires snapshot.", call. = FALSE)
    }
    document <- visual_document_normalize(snapshot)
  } else {
    stop("Unsupported visual mutation type: ", mutation$type, call. = FALSE)
  }

  document <- visual_document_push_undo(document, before, mutation)
  visual_document_select(document, document$selected_object_id %||% object_id, origin = "mutation")
}

visual_document_undo <- function(document) {
  document <- visual_document_normalize(document)
  undo <- document$history$undo %||% list()
  if (!length(undo)) {
    return(document)
  }

  entry <- undo[[length(undo)]]
  current <- visual_document_snapshot(document)
  restored <- visual_document_normalize(entry$before)
  restored$history$undo <- undo[-length(undo)]
  restored$history$redo <- append(document$history$redo %||% list(), list(list(
    mutation = entry$mutation,
    before = current,
    at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )))
  restored$revision <- as.integer(document$revision %||% 0L) + 1L
  visual_document_select(restored, restored$selected_object_id, origin = "undo")
}

visual_document_redo <- function(document) {
  document <- visual_document_normalize(document)
  redo <- document$history$redo %||% list()
  if (!length(redo)) {
    return(document)
  }

  entry <- redo[[length(redo)]]
  document$history$redo <- redo[-length(redo)]
  visual_document_apply_mutation(document, entry$mutation)
}

visual_document_create_checkpoint <- function(document, label = "Checkpoint") {
  document <- visual_document_normalize(document)
  checkpoint_id <- paste0("checkpoint_", length(document$history$checkpoints %||% list()) + 1L)
  document$history$checkpoints[[checkpoint_id]] <- list(
    id = checkpoint_id,
    label = label,
    revision = document$revision,
    snapshot = visual_document_snapshot(document),
    at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
  document
}

visual_document_restore_checkpoint <- function(document, checkpoint_id) {
  document <- visual_document_normalize(document)
  checkpoint <- document$history$checkpoints[[checkpoint_id]]
  checkpoints <- document$history$checkpoints
  if (is.null(checkpoint)) {
    stop("Unknown visual checkpoint: ", checkpoint_id, call. = FALSE)
  }

  restored <- visual_document_apply_mutation(document, list(type = "restore_snapshot", snapshot = checkpoint$snapshot))
  restored$history$checkpoints <- checkpoints
  visual_document_normalize(restored)
}

visual_document_compile_options <- function(document, options = list()) {
  document <- visual_document_normalize(document)
  warnings <- character()

  object_ids <- names(document$objects)
  for (object_id in object_ids) {
    object <- document$objects[[object_id]]
    props <- object$properties %||% list()
    if (isFALSE(object$visible)) {
      if (identical(object_id, "title_001")) {
        props[["title.text"]] <- ""
        props[["title.subtext"]] <- ""
      } else if (identical(object_id, "legend_001")) {
        props[["legend.show"]] <- FALSE
      } else if (identical(object$type, "series")) {
        warnings <- c(warnings, paste(object$label, "visibility is tracked but not yet supported by AutoPlots render arguments."))
      }
    }

    for (property in names(props)) {
      if (property %in% names(visual_property_schema())) {
        options[[property]] <- props[[property]]
      }
    }
  }

  list(options = options, warnings = unique(warnings))
}

visual_document_to_plot_config <- function(document, base_config) {
  document <- visual_document_normalize(document)
  compiled <- visual_document_compile_options(document, base_config$options %||% list())
  base_config$options <- compiled$options
  base_config$visual_document <- visual_document_snapshot(document)
  base_config$visual_compile_warnings <- compiled$warnings
  base_config
}

visual_command_registry <- function() {
  list(
    select_object = list(label = "Select", mutation = "select_object"),
    rename_object = list(label = "Rename", mutation = "rename_object"),
    toggle_visibility = list(label = "Show / Hide", mutation = "set_visibility"),
    toggle_lock = list(label = "Lock / Unlock", mutation = "set_lock_state"),
    set_layout = list(label = "Set Layout", mutation = "set_layout"),
    add_object = list(label = "Add Object", mutation = "add_object"),
    make_explanatory_visual = list(label = "Explain Visual", mutation = "make_explanatory_visual"),
    move_up = list(label = "Move Up", mutation = "reorder_object", direction = -1L),
    move_down = list(label = "Move Down", mutation = "reorder_object", direction = 1L),
    undo = list(label = "Undo", mutation = "undo"),
    redo = list(label = "Redo", mutation = "redo"),
    checkpoint = list(label = "Checkpoint", mutation = "checkpoint")
  )
}

visual_command_available <- function(document, command_id, object_id = NULL) {
  document <- visual_document_normalize(document)
  command <- visual_command_registry()[[command_id]]
  if (is.null(command)) {
    return(FALSE)
  }
  if (command_id %in% c("undo", "redo", "checkpoint", "add_object", "make_explanatory_visual")) {
    return(TRUE)
  }

  object_id <- object_id %||% document$selected_object_id
  object <- document$objects[[object_id]]
  if (is.null(object)) {
    return(FALSE)
  }
  if (isTRUE(object$locked) && !command_id %in% c("select_object", "toggle_lock")) {
    return(FALSE)
  }

  TRUE
}

visual_execute_command <- function(document, command_id, args = list(), source = "user") {
  document <- visual_document_normalize(document)
  command <- visual_command_registry()[[command_id]]
  if (is.null(command)) {
    stop("Unknown visual command: ", command_id, call. = FALSE)
  }
  if (!visual_command_available(document, command_id, args$object_id %||% document$selected_object_id)) {
    stop("Visual command is unavailable: ", command_id, call. = FALSE)
  }

  if (identical(command_id, "undo")) {
    return(visual_document_undo(document))
  }
  if (identical(command_id, "redo")) {
    return(visual_document_redo(document))
  }
  if (identical(command_id, "checkpoint")) {
    return(visual_document_create_checkpoint(document, args$label %||% "Checkpoint"))
  }

  object_id <- args$object_id %||% document$selected_object_id
  if (identical(command_id, "toggle_visibility")) {
    args <- list(type = "set_visibility", object_id = object_id, visible = !isTRUE(document$objects[[object_id]]$visible))
  } else if (identical(command_id, "toggle_lock")) {
    args <- list(type = "set_lock_state", object_id = object_id, locked = !isTRUE(document$objects[[object_id]]$locked))
  } else if (command_id %in% c("move_up", "move_down")) {
    args <- list(type = "reorder_object", object_id = object_id, direction = command$direction)
  } else {
    args$type <- command$mutation
    args$object_id <- object_id
  }
  args$source <- source
  visual_document_apply_mutation(document, args)
}

visual_agent_operation <- function(document, operation, args = list()) {
  allowed <- c(
    "select_object", "rename_object", "toggle_visibility", "toggle_lock",
    "set_layout", "add_object", "make_explanatory_visual",
    "move_up", "move_down", "undo", "redo", "checkpoint"
  )
  if (!operation %in% allowed) {
    stop("Agent operation is not allowed for Visual Studio: ", operation, call. = FALSE)
  }

  visual_execute_command(document, operation, args = args, source = "agent")
}

visual_object_tree_data <- function(document) {
  document <- visual_document_normalize(document)
  data.frame(
    id = names(document$objects),
    label = vapply(document$objects, function(object) object$label %||% object$id, character(1)),
    type = vapply(document$objects, function(object) object$type %||% "unknown", character(1)),
    parent = vapply(document$objects, function(object) object$parent %||% "", character(1)),
    depth = vapply(names(document$objects), function(id) visual_object_depth(document, id), integer(1)),
    visible = vapply(document$objects, function(object) isTRUE(object$visible), logical(1)),
    locked = vapply(document$objects, function(object) isTRUE(object$locked), logical(1)),
    selected = names(document$objects) == document$selected_object_id,
    stringsAsFactors = FALSE
  )
}

visual_component_playground_state <- function() {
  document <- visual_document_from_plot_spec(
    "Area",
    mappings = list(XVar = "date", YVar = "value"),
    options = list(`title.text` = "Playground Plot", Theme = "dark")
  )
  document <- visual_execute_command(document, "checkpoint", list(label = "Initial"))
  list(
    document = document,
    available_commands = names(visual_command_registry()),
    tree = visual_object_tree_data(document)
  )
}

visual_document_serialize <- function(document) {
  visual_document_normalize(document)
}

visual_document_roundtrip <- function(document) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for visual document roundtrip validation.", call. = FALSE)
  }

  jsonlite::fromJSON(
    jsonlite::toJSON(visual_document_serialize(document), auto_unbox = TRUE, null = "null"),
    simplifyVector = FALSE
  )
}

visual_document_validate <- function(document) {
  issues <- character()
  document <- tryCatch(
    visual_document_normalize(document),
    error = function(e) {
      issues <<- c(issues, conditionMessage(e))
      NULL
    }
  )
  if (is.null(document)) {
    return(list(status = "error", issues = issues))
  }

  object_ids <- names(document$objects)
  registry <- visual_object_registry()
  if (!identical(document$schema_version, VISUAL_DOCUMENT_SCHEMA_VERSION)) {
    issues <- c(issues, "schema_version is not current")
  }
  if (anyDuplicated(object_ids)) {
    issues <- c(issues, "object ids must be unique")
  }
  for (object_id in object_ids) {
    object <- document$objects[[object_id]]
    if (is.null(registry[[object$type]])) {
      issues <- c(issues, paste("unknown object type", object$type, "for", object_id))
    }
    if (!is.null(object$parent) && !object$parent %in% object_ids) {
      issues <- c(issues, paste("missing parent", object$parent, "for", object_id))
    }
    missing_children <- setdiff(object$children %||% character(), object_ids)
    if (length(missing_children)) {
      issues <- c(issues, paste("missing child for", object_id, paste(missing_children, collapse = ", ")))
    }
    if (!is.logical(object$visible) || length(object$visible) != 1L) {
      issues <- c(issues, paste("visible must be a scalar logical for", object_id))
    }
    if (!is.logical(object$locked) || length(object$locked) != 1L) {
      issues <- c(issues, paste("locked must be a scalar logical for", object_id))
    }
  }
  if (!document$selected_object_id %in% object_ids) {
    issues <- c(issues, "selected object is missing")
  }
  if (!"caption_001" %in% object_ids || !identical(document$objects$caption_001$type, "text")) {
    issues <- c(issues, "caption_001 text object is required")
  }
  renderer_objects <- vapply(document$objects, function(object) object$renderer %||% "", character(1))
  if (!any(renderer_objects == "AutoPlots")) {
    issues <- c(issues, "at least one object must declare the AutoPlots renderer boundary")
  }
  proposal_required <- c(
    "proposal_id", "timestamp", "status", "rationale",
    "originating_evidence_ids", "rollback_metadata", "object_decisions"
  )
  proposals <- document$authoring$proposals %||% list()
  for (proposal_id in names(proposals)) {
    proposal <- proposals[[proposal_id]]
    missing_fields <- setdiff(proposal_required, names(proposal))
    if (length(missing_fields)) {
      issues <- c(issues, paste("authoring proposal missing fields", proposal_id, paste(missing_fields, collapse = ", ")))
    }
    for (object in proposal$new_objects %||% list()) {
      authoring <- object$extension$authoring %||% list()
      if (!identical(authoring$creation_pathway, "semantic_authoring_engine")) {
        issues <- c(issues, paste("proposal object missing semantic authoring pathway", object$id %||% "<unknown>"))
      }
      if (!identical(authoring$proposal_id %||% NULL, proposal$proposal_id %||% NULL)) {
        issues <- c(issues, paste("proposal object has mismatched proposal id", object$id %||% "<unknown>"))
      }
      if (!nzchar(authoring$generation_rationale %||% "")) {
        issues <- c(issues, paste("proposal object missing generation rationale", object$id %||% "<unknown>"))
      }
      if (!is.numeric(authoring$confidence) || length(authoring$confidence) != 1L) {
        issues <- c(issues, paste("proposal object missing scalar confidence", object$id %||% "<unknown>"))
      }
      if (!nzchar(authoring$version %||% "")) {
        issues <- c(issues, paste("proposal object missing authoring version", object$id %||% "<unknown>"))
      }
    }
  }
  for (object_id in object_ids) {
    authoring <- document$objects[[object_id]]$extension$authoring %||% NULL
    if (is.null(authoring)) {
      next
    }
    if (!identical(authoring$creation_pathway, "semantic_authoring_engine")) {
      issues <- c(issues, paste("authored object missing semantic authoring pathway", object_id))
    }
    if (!nzchar(authoring$proposal_id %||% "")) {
      issues <- c(issues, paste("authored object missing proposal id", object_id))
    }
    if (!nzchar(authoring$generation_rationale %||% "")) {
      issues <- c(issues, paste("authored object missing generation rationale", object_id))
    }
    if (!nzchar(authoring$version %||% "")) {
      issues <- c(issues, paste("authored object missing authoring version", object_id))
    }
  }
  composition <- document$composition %||% list()
  if (!identical(composition$schema_version, VISUAL_COMPOSITION_SCHEMA_VERSION)) {
    issues <- c(issues, "composition schema_version is not current")
  }
  review_registry <- visual_composition_review_dimension_registry()
  review_required <- c("review_id", "document_id", "dimensions", "findings", "evidence_ids", "review_signature", "schema_version")
  for (review_id in names(composition$reviews %||% list())) {
    review <- composition$reviews[[review_id]]
    missing_fields <- setdiff(review_required, names(review))
    if (length(missing_fields)) {
      issues <- c(issues, paste("composition review missing fields", review_id, paste(missing_fields, collapse = ", ")))
    }
    if (!identical(review$schema_version %||% NULL, VISUAL_COMPOSITION_SCHEMA_VERSION)) {
      issues <- c(issues, paste("composition review schema_version is not current", review_id))
    }
    missing_dimensions <- setdiff(names(review_registry), names(review$dimensions %||% list()))
    if (length(missing_dimensions)) {
      issues <- c(issues, paste("composition review missing dimensions", review_id, paste(missing_dimensions, collapse = ", ")))
    }
    for (dimension_id in names(review$dimensions %||% list())) {
      dimension <- review$dimensions[[dimension_id]]
      dimension_required <- c("dimension_id", "label", "status", "finding")
      missing_dimension_fields <- setdiff(dimension_required, names(dimension))
      if (length(missing_dimension_fields)) {
        issues <- c(issues, paste("composition review dimension missing fields", dimension_id, paste(missing_dimension_fields, collapse = ", ")))
      }
    }
  }
  strategy_required <- c("strategy_id", "review_id", "status", "mutation_plan", "strategy_signature", "schema_version")
  allowed_operations <- visual_composition_allowed_operations()
  allowed_claims <- visual_composition_allowed_claim_classifications()
  for (strategy_id in names(composition$strategies %||% list())) {
    strategy <- composition$strategies[[strategy_id]]
    missing_fields <- setdiff(strategy_required, names(strategy))
    if (length(missing_fields)) {
      issues <- c(issues, paste("composition strategy missing fields", strategy_id, paste(missing_fields, collapse = ", ")))
    }
    if (!identical(strategy$schema_version %||% NULL, VISUAL_COMPOSITION_SCHEMA_VERSION)) {
      issues <- c(issues, paste("composition strategy schema_version is not current", strategy_id))
    }
    if (!is.null(strategy$review_id) && length(composition$reviews %||% list()) && !strategy$review_id %in% names(composition$reviews)) {
      issues <- c(issues, paste("composition strategy references missing review", strategy_id))
    }
    for (mutation_id in names(strategy$mutation_plan %||% list())) {
      plan_mutation <- strategy$mutation_plan[[mutation_id]]
      mutation_required <- c(
        "mutation_id", "operation", "semantic_operation", "object_id",
        "rationale", "claim_classification", "reversibility_metadata"
      )
      missing_mutation_fields <- setdiff(mutation_required, names(plan_mutation))
      if (length(missing_mutation_fields)) {
        issues <- c(issues, paste("composition mutation missing fields", mutation_id, paste(missing_mutation_fields, collapse = ", ")))
      }
      mutation_operation <- plan_mutation$operation %||% NA_character_
      mutation_claim <- plan_mutation$claim_classification %||% NA_character_
      if (!mutation_operation %in% allowed_operations) {
        issues <- c(issues, paste("composition mutation has unsupported operation", mutation_id, plan_mutation$operation %||% "<missing>"))
      }
      if (!mutation_claim %in% allowed_claims) {
        issues <- c(issues, paste("composition mutation has unsupported claim classification", mutation_id))
      }
    }
  }
  branch_required <- c("branch_id", "strategy_id", "mutation_ids", "preview_document", "branch_signature", "schema_version")
  for (branch_id in names(composition$branches %||% list())) {
    branch <- composition$branches[[branch_id]]
    missing_fields <- setdiff(branch_required, names(branch))
    if (length(missing_fields)) {
      issues <- c(issues, paste("composition branch missing fields", branch_id, paste(missing_fields, collapse = ", ")))
    }
    if (!identical(branch$schema_version %||% NULL, VISUAL_COMPOSITION_SCHEMA_VERSION)) {
      issues <- c(issues, paste("composition branch schema_version is not current", branch_id))
    }
    if (!is.null(branch$strategy_id) && !branch$strategy_id %in% names(composition$strategies %||% list())) {
      issues <- c(issues, paste("composition branch references missing strategy", branch_id))
    }
    if (!is.list(branch$preview_document) || is.null(branch$preview_document$objects)) {
      issues <- c(issues, paste("composition branch preview_document is invalid", branch_id))
    }
  }
  if (exists("visual_knowledge_validate", mode = "function") && !is.null(document$knowledge_synthesis)) {
    knowledge_validation <- visual_knowledge_validate(document)
    if (!identical(knowledge_validation$status, "success")) {
      issues <- c(issues, paste("knowledge synthesis", knowledge_validation$issues))
    }
  }
  if (exists("visual_domain_memory_validate", mode = "function") && !is.null(document$domain_memory)) {
    memory_validation <- visual_domain_memory_validate(document$domain_memory)
    if (!identical(memory_validation$status, "success")) {
      issues <- c(issues, paste("domain memory", memory_validation$issues))
    }
  }

  list(
    status = if (length(issues)) "error" else "success",
    issues = unique(issues)
  )
}

qa_visual_document_runtime <- function() {
  document <- visual_document_from_plot_spec(
    "Area",
    mappings = list(XVar = "date", YVar = "sales"),
    options = list(`title.text` = "Sales by Date", `legend.show` = TRUE)
  )
  validation <- visual_document_validate(document)
  mutated <- visual_document_apply_mutation(document, list(
    type = "set_property",
    object_id = "title_001",
    property = "title.text",
    value = "Updated Title"
  ))
  undone <- visual_document_undo(mutated)
  redone <- visual_document_redo(undone)
  hidden <- visual_execute_command(redone, "toggle_visibility", list(object_id = "legend_001"))
  checkpointed <- visual_document_create_checkpoint(hidden, "QA checkpoint")
  restored <- visual_document_restore_checkpoint(checkpointed, "checkpoint_1")
  roundtripped <- visual_document_roundtrip(restored)
  contract <- visual_inspector_contract(restored, "series_001", mode = "expert")
  compiled <- visual_document_to_plot_config(restored, list(
    plot_type = "Area",
    mappings = list(XVar = "date", YVar = "sales"),
    options = list()
  ))

  data.frame(
    check = c(
      "valid_document",
      "stable_object_ids",
      "inspector_contract",
      "undo_redo",
      "checkpoint_restore",
      "roundtrip",
      "text_object",
      "compile_to_plot_config"
    ),
    status = c(
      validation$status,
      if (all(c("plot_001", "series_001", "caption_001", "boundary_line_001") %in% names(document$objects))) "success" else "error",
      if (identical(contract$object_id, "series_001") && "ShowLabels" %in% contract$option_names) "success" else "error",
      if (identical(redone$objects$title_001$properties[["title.text"]], "Updated Title")) "success" else "error",
      if (length(restored$history$checkpoints) >= 1L) "success" else "error",
      if (is.list(roundtripped) && !is.null(roundtripped$objects)) "success" else "error",
      if (identical(document$objects$caption_001$type, "text")) "success" else "error",
      if (identical(compiled$options[["title.text"]], "Updated Title")) "success" else "error"
    ),
    stringsAsFactors = FALSE
  )
}

qa_visual_studio_phase2 <- function() {
  playground <- visual_component_playground_state()
  document <- playground$document
  selected <- visual_agent_operation(document, "select_object", list(object_id = "title_001"))
  renamed <- visual_agent_operation(selected, "rename_object", list(object_id = "title_001", label = "Executive Title"))
  locked <- visual_agent_operation(renamed, "toggle_lock", list(object_id = "title_001"))
  blocked <- tryCatch({
    visual_document_apply_mutation(locked, list(
      type = "set_property",
      object_id = "title_001",
      property = "title.text",
      value = "Should fail"
    ))
    FALSE
  }, error = function(e) TRUE)
  unlocked <- visual_agent_operation(locked, "toggle_lock", list(object_id = "title_001"))
  edited <- visual_document_apply_mutation(unlocked, list(
    type = "set_property",
    object_id = "title_001",
    property = "title.text",
    value = "Evidence Trend"
  ))
  config <- visual_document_to_plot_config(edited, list(
    plot_type = "Area",
    mappings = list(XVar = "date", YVar = "value"),
    options = list()
  ))

  data.frame(
    check = c(
      "selection_state",
      "rename_command",
      "locked_mutation_blocked",
      "compile_title",
      "playground_tree"
    ),
    status = c(
      if (identical(selected$selected_object_id, "title_001") && identical(selected$selection$object_type, "title")) "success" else "error",
      if (identical(renamed$objects$title_001$label, "Executive Title")) "success" else "error",
      if (isTRUE(blocked)) "success" else "error",
      if (identical(config$options[["title.text"]], "Evidence Trend")) "success" else "error",
      if (nrow(playground$tree) >= 8L) "success" else "error"
    ),
    stringsAsFactors = FALSE
  )
}

qa_visual_studio_phase3 <- function() {
  document <- visual_document_from_plot_spec(
    "Area",
    mappings = list(XVar = "event_date", YVar = "revenue"),
    options = list(`title.text` = "Revenue over time", Theme = "dark")
  )
  composed <- visual_agent_operation(document, "make_explanatory_visual", list(
    finding = list(
      title = "Revenue pattern needs explanation",
      statement = "Revenue movement has been promoted into an explanatory visual finding.",
      explanation = "The visual document keeps visual evidence, interpretation, and provenance together.",
      evidence_id = "artifact_plot_001",
      source = "AutoPlots area chart from Plot Studio"
    )
  ))
  moved <- visual_agent_operation(composed, "set_layout", list(
    object_id = "callout_001",
    layout = list(x = 9, y = 3, width = 4, height = 2, z = 6L)
  ))
  extra <- visual_make_object(
    id = "supporting_note_001",
    type = "text",
    label = "Supporting Note",
    parent = "canvas_001",
    renderer = "SemanticText",
    role = "supporting_note",
    properties = list(
      content = "A second supporting visual or narrative object can be added through the same object contract."
    ),
    order = 5L,
    layout = list(x = 1, y = 12, width = 12, height = 2, unit = "grid", z = 5L)
  )
  expanded <- visual_agent_operation(moved, "add_object", list(
    object = extra,
    parent_id = "canvas_001",
    select = TRUE
  ))
  selected <- visual_agent_operation(expanded, "select_object", list(object_id = "callout_001"))
  callout_contract <- visual_inspector_contract(selected, "callout_001", mode = "expert")
  group_contract <- visual_inspector_contract(selected, "evidence_group_001", mode = "expert")
  roundtripped <- visual_document_normalize(visual_document_roundtrip(selected))
  config <- visual_document_to_plot_config(roundtripped, list(
    plot_type = "Area",
    mappings = list(XVar = "event_date", YVar = "revenue"),
    options = list()
  ))
  validation <- visual_document_validate(roundtripped)

  data.frame(
    check = c(
      "composition_objects",
      "group_relationship",
      "layout_mutation",
      "adapter_boundaries",
      "callout_inspector",
      "add_object",
      "roundtrip_composition",
      "compile_preserves_document",
      "validation"
    ),
    status = c(
      if (all(c("heading_001", "evidence_group_001", "callout_001", "explanation_001", "source_001") %in% names(selected$objects))) "success" else "error",
      if (all(c("callout_001", "explanation_001") %in% selected$objects$evidence_group_001$children)) "success" else "error",
      if (isTRUE(selected$objects$callout_001$layout$x == 9) && isTRUE(selected$objects$callout_001$layout$z == 6)) "success" else "error",
      if (identical(callout_contract$adapter, "EvidenceCalloutAdapter") && identical(group_contract$adapter, "ObjectGroupAdapter")) "success" else "error",
      if (all(c("content", "callout.label", "callout.value", "layout.x") %in% callout_contract$option_names)) "success" else "error",
      if ("supporting_note_001" %in% names(selected$objects) && identical(selected$selected_object_id, "callout_001")) "success" else "error",
      if (visual_document_has_composition(roundtripped)) "success" else "error",
      if (!is.null(config$visual_document) && "callout_001" %in% names(config$visual_document$objects)) "success" else "error",
      validation$status
    ),
    stringsAsFactors = FALSE
  )
}

qa_semantic_authoring <- function() {
  base_document <- visual_document_from_plot_spec(
    "Area",
    mappings = list(XVar = "event_date", YVar = "revenue"),
    options = list(`title.text` = "Revenue over time", Theme = "dark")
  )
  evidence <- list(
    evidence_ids = "artifact_plot_001",
    source_artifacts = "plot_service_result",
    title = "Revenue pattern needs explanation",
    statement = "Revenue movement has been promoted into a governed visual finding.",
    explanation = "Use the visual, finding, interpretation, and provenance together.",
    recommendation = "Preserve this explanatory visual when it supports the investigation.",
    limitation = "This visual explains observed structure; it does not prove causality.",
    source = "Plot Studio AutoPlots configuration"
  )
  proposal <- visual_authoring_create_proposal(
    base_document,
    evidence,
    timestamp = "2026-07-19 00:00:00"
  )
  stored <- visual_authoring_store_proposal(base_document, proposal)
  rejected <- visual_document_apply_mutation(stored, list(
    type = "reject_authoring_proposal",
    proposal_id = proposal$proposal_id,
    reason = "QA reject"
  ))
  partial_base <- visual_authoring_store_proposal(base_document, proposal)
  partial_doc <- visual_authoring_accept_proposal(
    partial_base,
    proposal$proposal_id,
    c("heading_001", "callout_001", "explanation_001")
  )
  object_reject_base <- visual_authoring_store_proposal(base_document, proposal)
  object_rejected <- visual_document_apply_mutation(object_reject_base, list(
    type = "reject_authoring_objects",
    proposal_id = proposal$proposal_id,
    object_ids = "limitation_001",
    reason = "QA object reject"
  ))
  undone <- visual_document_undo(partial_doc)
  redone <- visual_document_redo(undone)
  full_base <- visual_authoring_store_proposal(base_document, proposal)
  full_doc <- visual_authoring_accept_proposal(full_base, proposal$proposal_id)
  duplicate_doc <- visual_authoring_accept_proposal(full_doc, proposal$proposal_id)
  roundtripped <- visual_document_normalize(visual_document_roundtrip(full_doc))
  validation <- visual_document_validate(roundtripped)
  missing_before <- visual_authoring_missing_components(base_document, evidence)
  missing_after <- visual_authoring_missing_components(full_doc, evidence)
  summary <- visual_authoring_proposal_summary(proposal)
  adapter <- visual_authoring_adapter_contract("recommendation")
  authored <- Filter(function(object) !is.null(object$extension$authoring), full_doc$objects)
  provenance_ok <- length(authored) > 0L && all(vapply(authored, function(object) {
    authoring <- object$extension$authoring
    identical(authoring$creation_pathway, "semantic_authoring_engine") &&
      length(authoring$originating_evidence_ids %||% character()) > 0L &&
      length(authoring$source_artifacts %||% character()) > 0L &&
      nzchar(authoring$generation_rationale %||% "") &&
      is.numeric(authoring$confidence) &&
      nzchar(authoring$version %||% "")
  }, logical(1)))

  data.frame(
    check = c(
      "proposal_created",
      "proposal_stored",
      "proposal_rejected",
      "object_rejected",
      "partial_acceptance",
      "undo_redo_authoring",
      "full_acceptance",
      "duplicate_guard",
      "roundtrip_authoring",
      "provenance",
      "adapter_contract",
      "missing_detection",
      "validation",
      "history_integrity"
    ),
    status = c(
      if (length(proposal$new_objects) >= 6L && identical(proposal$status, "proposed")) "success" else "error",
      if (!is.null(stored$authoring$proposals[[proposal$proposal_id]])) "success" else "error",
      if (identical(rejected$authoring$proposals[[proposal$proposal_id]]$status, "rejected")) "success" else "error",
      if (identical(object_rejected$authoring$proposals[[proposal$proposal_id]]$object_decisions$limitation_001$status, "rejected")) "success" else "error",
      if (all(c("heading_001", "callout_001", "explanation_001") %in% names(partial_doc$objects)) &&
        !("limitation_001" %in% names(partial_doc$objects))) "success" else "error",
      if (!("heading_001" %in% names(undone$objects)) && "heading_001" %in% names(redone$objects)) "success" else "error",
      if (all(names(proposal$new_objects) %in% names(full_doc$objects))) "success" else "error",
      if (length(unique(names(duplicate_doc$objects))) == length(names(duplicate_doc$objects))) "success" else "error",
      if (all(c("proposal_id", "creation_pathway") %in% names(roundtripped$objects$heading_001$extension$authoring))) "success" else "error",
      if (isTRUE(provenance_ok)) "success" else "error",
      if (identical(adapter$adapter, "RecommendationAdapter") &&
        all(c("render", "propose", "validate", "mutate", "serialize", "deserialize", "inspect") %in% adapter$operations)) "success" else "error",
      if (all(c("title", "interpretation", "provenance", "uncertainty", "recommendations", "limitations", "references") %in% missing_before) &&
        length(setdiff(c("title", "interpretation", "provenance", "uncertainty", "recommendations", "limitations", "references"), missing_after)) > 0L) "success" else "error",
      validation$status,
      if (length(full_doc$authoring$history) >= 2L) "success" else "error"
    ),
    stringsAsFactors = FALSE
  )
}

qa_composition_intelligence <- function() {
  base_document <- visual_document_from_plot_spec(
    "Area",
    mappings = list(XVar = "event_date", YVar = "revenue"),
    options = list(`title.text` = "Revenue over time", Theme = "dark")
  )
  evidence <- list(
    evidence_ids = c("artifact_plot_001", "artifact_table_001"),
    source_artifacts = "plot_service_result",
    title = "Revenue pattern needs explanation",
    statement = "Revenue movement should be interpreted with evidence context.",
    explanation = "The visual trend should be connected to a governed finding before decision use.",
    recommendation = "Use the explanatory visual in the investigation summary.",
    limitation = "This visual is descriptive evidence and does not establish causality.",
    source = "Plot Studio AutoPlots configuration"
  )

  old_document <- base_document
  old_document$composition <- NULL
  normalized_old <- visual_document_normalize(old_document)
  review <- visual_composition_create_review(base_document, evidence = evidence)
  reviewed <- visual_composition_store_review(base_document, review)
  strategies <- visual_composition_generate_strategies(reviewed, review, evidence)
  planned <- visual_composition_store_strategies(reviewed, strategies)
  comparison <- visual_composition_compare_strategies(planned)
  strategy <- visual_composition_get_strategy(planned)
  strategy_ids <- names(planned$composition$strategies)
  mutation_ids <- names(strategy$mutation_plan)
  dependent_id <- mutation_ids[vapply(strategy$mutation_plan, function(mutation) {
    length(mutation$dependencies %||% character()) > 0L
  }, logical(1))][[1L]]
  dependency_error <- tryCatch({
    visual_composition_accept_strategy(planned, strategy$strategy_id, dependent_id)
    ""
  }, error = conditionMessage)
  branch <- visual_composition_create_branch(planned, strategy$strategy_id, mutation_ids[1:2])
  branch_id <- branch$composition$active_branch_id
  preview <- branch$composition$branches[[branch_id]]$preview_document
  accepted <- visual_composition_accept_strategy(planned, strategy$strategy_id)
  rejected <- visual_composition_reject_strategy(planned, strategy_ids[[2L]], "QA reject")
  roundtripped <- visual_document_normalize(visual_document_roundtrip(accepted))
  validation <- visual_document_validate(roundtripped)
  duplicated <- visual_document_add_object(
    base_document,
    visual_make_object(
      id = "duplicate_text_001",
      type = "text",
      role = "annotation",
      label = "Title",
      parent = "canvas_001",
      properties = list(text = "Revenue over time")
    ),
    parent_id = "canvas_001",
    select = FALSE
  )
  duplicate_review <- visual_composition_create_review(duplicated)
  contradiction_doc <- visual_document_add_object(
    base_document,
    visual_make_object(
      id = "contradiction_text_001",
      type = "text",
      role = "annotation",
      label = "Contradiction note",
      parent = "canvas_001",
      properties = list(text = "This evidence supports a recommendation and should be acted on now.")
    ),
    parent_id = "canvas_001",
    select = FALSE
  )
  contradiction_review <- visual_composition_create_review(contradiction_doc)
  undone <- visual_document_undo(accepted)
  redone <- visual_document_redo(undone)
  accepted_objects <- Filter(function(object) {
    composition <- object$extension$composition %||% NULL
    !is.null(composition) && identical(composition$creation_pathway, "governed_composition_intelligence")
  }, accepted$objects)
  mutation_classes <- unique(vapply(strategy$mutation_plan, function(mutation) {
    mutation$claim_classification %||% ""
  }, character(1)))
  required_dimensions <- c(
    "evidence_coverage", "narrative_coherence", "visual_hierarchy",
    "completeness", "redundancy", "integrity", "accessibility_readability"
  )
  required_strategy_labels <- c(
    "Minimal Explanation",
    "Executive Narrative",
    "Evidence-Forward Analysis"
  )

  data.frame(
    check = c(
      "old_document_normalizes_composition",
      "dimension_registry_complete",
      "strategy_registry_complete",
      "review_created",
      "review_stored_active",
      "review_dimensions_complete",
      "review_findings_present",
      "review_evidence_ids_present",
      "strategies_generated",
      "strategies_stored_active",
      "required_strategy_labels",
      "mutation_plan_present",
      "mutation_provenance_present",
      "mutation_claim_classes_allowed",
      "strategy_comparison_dimension_rows",
      "preview_branch_created",
      "preview_branch_document_present",
      "preview_does_not_mutate_canonical",
      "preview_adds_objects",
      "dependency_guard_blocks_partial_accept",
      "accept_all_adds_objects",
      "accepted_strategy_status",
      "rejected_strategy_preserved",
      "roundtrip_preserves_composition",
      "validation_success",
      "duplicate_detection",
      "contradiction_detection",
      "undo_redo_after_acceptance",
      "decision_history_recorded",
      "allowed_operation_registry"
    ),
    status = c(
      if (!is.null(normalized_old$composition) && identical(normalized_old$composition$schema_version, VISUAL_COMPOSITION_SCHEMA_VERSION)) "success" else "error",
      if (setequal(names(visual_composition_review_dimension_registry()), required_dimensions)) "success" else "error",
      if (length(visual_composition_strategy_registry()) == 3L) "success" else "error",
      if (nzchar(review$review_id %||% "") && identical(review$schema_version, VISUAL_COMPOSITION_SCHEMA_VERSION)) "success" else "error",
      if (identical(reviewed$composition$active_review_id, review$review_id) &&
        !is.null(reviewed$composition$reviews[[review$review_id]])) "success" else "error",
      if (setequal(names(review$dimensions), required_dimensions)) "success" else "error",
      if (length(review$findings) >= length(required_dimensions)) "success" else "error",
      if (length(review$evidence_ids) > 0L) "success" else "error",
      if (length(strategies) == 3L) "success" else "error",
      if (length(planned$composition$strategies) == 3L &&
        nzchar(planned$composition$active_strategy_id %||% "")) "success" else "error",
      if (all(required_strategy_labels %in% vapply(planned$composition$strategies, function(x) x$label, character(1)))) "success" else "error",
      if (length(strategy$mutation_plan) >= 2L) "success" else "error",
      if (all(vapply(strategy$mutation_plan, function(mutation) {
        nzchar(mutation$rationale %||% "") &&
          length(mutation$evidence_ids %||% character()) > 0L &&
          !is.null(mutation$reversibility_metadata)
      }, logical(1)))) "success" else "error",
      if (all(mutation_classes %in% visual_composition_allowed_claim_classifications())) "success" else "error",
      if (nrow(comparison) == length(required_dimensions) * 3L &&
        all(c("strategy", "dimension", "status", "finding") %in% names(comparison))) "success" else "error",
      if (nzchar(branch_id %||% "") && !is.null(branch$composition$branches[[branch_id]])) "success" else "error",
      if (is.list(preview) && length(preview$objects) > 0L) "success" else "error",
      if (length(planned$objects) == length(base_document$objects)) "success" else "error",
      if (length(preview$objects) > length(planned$objects)) "success" else "error",
      if (grepl("missing required composition mutation dependencies", dependency_error, fixed = TRUE)) "success" else "error",
      if (length(accepted_objects) >= length(strategy$mutation_plan)) "success" else "error",
      if (identical(accepted$composition$strategies[[strategy$strategy_id]]$status, "accepted")) "success" else "error",
      if (identical(rejected$composition$strategies[[strategy_ids[[2L]]]]$status, "rejected") &&
        !is.null(rejected$composition$strategies[[strategy_ids[[2L]]]]$rejection_reason)) "success" else "error",
      if (length(roundtripped$composition$strategies) >= 1L &&
        length(roundtripped$composition$decisions) >= 1L) "success" else "error",
      validation$status,
      if (identical(duplicate_review$dimensions$redundancy$status, "duplicate_risk")) "success" else "error",
      if (length(contradiction_review$contradictions) > 0L) "success" else "error",
      if (length(undone$objects) < length(accepted$objects) && length(redone$objects) == length(accepted$objects)) "success" else "error",
      if (length(accepted$composition$decisions) >= 1L && length(accepted$composition$history) >= 1L) "success" else "error",
      if (all(c("add", "update", "remove", "move", "resize", "reorder", "group", "ungroup", "update_layout", "update_provenance", "update_narrative", "replace") %in% visual_composition_allowed_operations())) "success" else "error"
    ),
    stringsAsFactors = FALSE
  )
}
