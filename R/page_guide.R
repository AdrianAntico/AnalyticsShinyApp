guide_artifact_module_ids <- function(artifacts) {
  if (!length(artifacts)) {
    return(character())
  }
  unique(vapply(artifacts, function(artifact) {
    metadata <- artifact$metadata %||% list()
    metadata$module_id %||% artifact$source_module %||% ""
  }, character(1)))
}

guide_state_from_context <- function(ctx = NULL, overrides = list()) {
  get_value <- function(name, expr, default) {
    if (!is.null(overrides[[name]])) {
      return(overrides[[name]])
    }
    if (is.null(ctx)) {
      return(default)
    }
    tryCatch(expr, error = function(e) default)
  }

  data <- get_value("data", ctx$project_data(), NULL)
  data_info <- get_value("data_info", ctx$project_data_info(), list(path = NULL, name = NULL))
  artifacts <- get_value("artifacts", ctx$all_artifacts(), list())
  collector <- get_value("collector", ctx$project_collector_summary(), data.table::data.table())
  workflow <- get_value("workflow", workflow_state_summary(ctx), workflow_state_summary(NULL))
  plans <- get_value("plans", ctx$report_plan_state$plans, list())
  async <- get_value("async", async_job_status_counts(refresh = FALSE), list(total = 0L, running = 0L, completed = 0L, failed = 0L, latest_status = "unavailable"))
  genai <- get_value("genai", ctx$genai_status(check_availability = FALSE), genai_provider_status(genai_config(provider = "none")))
  evidence_strategy <- get_value("evidence_strategy", ctx$evidence_strategy_config(), evidence_strategy_config("balanced"))
  execution_policy <- get_value("execution_policy", ctx$code_runner_state$policy, create_code_execution_policy())

  module_ids <- guide_artifact_module_ids(artifacts)
  collector_artifacts <- if (nrow(collector)) collector$artifact_count[[1]] %||% 0L else 0L
  collector_ready <- nrow(collector) && collector_artifacts > 0L && identical(collector$manifest_status[[1]] %||% "", "ready")
  project_exists <- !is.null(data) || length(artifacts) > 0L || collector_artifacts > 0L || length(plans) > 0L
  collector_project_name <- if (nrow(collector) && "project_name" %in% names(collector)) {
    collector$project_name[[1]]
  } else {
    NULL
  }
  project_name <- data_info$name %||% collector_project_name

  knowledge_state <- if (!project_exists) {
    "Not started"
  } else if (is.null(data) && length(artifacts) > 0L) {
    "Evidence restored"
  } else if (!is.null(data) && !length(artifacts)) {
    "Data known, evidence missing"
  } else if (length(artifacts) && !collector_ready) {
    "Evidence generated, memory incomplete"
  } else if (collector_ready) {
    "Evidence preserved"
  } else {
    "Project active"
  }

  decision_readiness <- if (!project_exists || (!length(artifacts) && collector_artifacts == 0L)) {
    "Insufficient Evidence"
  } else if (length(artifacts) < 5L || !collector_ready) {
    "Preliminary"
  } else if (collector_ready && length(artifacts) >= 5L) {
    "Reasonable"
  } else {
    "Unknown"
  }

  list(
    project_exists = project_exists,
    project_name = project_name %||% "No project loaded",
    data = data,
    data_info = data_info,
    artifacts = artifacts,
    artifact_count = length(artifacts),
    module_ids = module_ids,
    collector = collector,
    collector_artifacts = collector_artifacts,
    collector_ready = collector_ready,
    workflow = workflow,
    plans = plans,
    plan_count = length(plans),
    async = async,
    genai = genai,
    evidence_strategy = evidence_strategy,
    execution_policy = execution_policy,
    knowledge_state = knowledge_state,
    decision_readiness = decision_readiness
  )
}

guide_has_module <- function(state, module_id) {
  module_id %in% state$module_ids
}

guide_recommendation <- function(state) {
  if (!isTRUE(state$project_exists)) {
    return(list(
      title = "Start with a project",
      action = "Load data or open an existing project.",
      reason = "No project state is loaded, so the workstation has no evidence, collector memory, or Knowledge State to reason over.",
      benefit = "Creates the project context needed for Explore Data, Model Readiness, artifacts, and recommendations.",
      cost = "Low",
      confidence = "High",
      target = "Project"
    ))
  }

  if (is.null(state$data) && state$artifact_count == 0L) {
    return(list(
      title = "Restore analytical context",
      action = "Open an existing project or load data.",
      reason = "The workstation does not have active data or artifacts available in memory.",
      benefit = "Restores the project world so evidence can be generated or inspected.",
      cost = "Low",
      confidence = "High",
      target = "Project"
    ))
  }

  if (!is.null(state$data) && state$artifact_count == 0L) {
    return(list(
      title = "Run Explore Data",
      action = "Generate foundational Explore Data artifacts.",
      reason = "Data are loaded, but no foundational evidence exists yet. Explore Data establishes distributions, missingness, correlations, and early diagnostics.",
      benefit = "Creates the first evidence layer for the project.",
      cost = "Low",
      confidence = "High",
      target = "Analysis Modules"
    ))
  }

  if (!guide_has_module(state, "autoquant_model_readiness") && state$artifact_count > 0L) {
    return(list(
      title = "Run Model Readiness",
      action = "Check whether the data are suitable for modeling.",
      reason = "Evidence exists, but readiness diagnostics have not been generated. Target analysis, leakage, collider risk, drift, balance, and missingness should be checked before modeling.",
      benefit = "Reduces the chance of building a model on untrustworthy data.",
      cost = "Low to medium",
      confidence = "High",
      target = "Analysis Modules"
    ))
  }

  if ((guide_has_module(state, "autoquant_regression_model_insights") || guide_has_module(state, "autoquant_binary_model_insights")) &&
      !guide_has_module(state, "autoquant_regression_shap_analysis") &&
      !guide_has_module(state, "autoquant_binary_shap_analysis")) {
    return(list(
      title = "Generate SHAP Analysis",
      action = "Add feature-level explanation artifacts.",
      reason = "Model insight artifacts exist, but SHAP evidence is missing. SHAP usually has high expected information gain for understanding feature importance and local effect behavior.",
      benefit = "Improves interpretability and helps explain model behavior.",
      cost = "Medium",
      confidence = "Medium",
      target = "Analysis Modules"
    ))
  }

  if (state$artifact_count > 0L && !isTRUE(state$collector_ready)) {
    return(list(
      title = "Preserve evidence in the Collector",
      action = "Review collector status and append generated module artifacts.",
      reason = "Artifacts exist, but collector memory is not fully ready. The project should preserve evidence before reporting or AI-oriented review.",
      benefit = "Makes evidence durable and ready for reports, LLM DOCX, and future knowledge workflows.",
      cost = "Low",
      confidence = "High",
      target = "Project"
    ))
  }

  if (state$artifact_count > 0L) {
    return(list(
      title = "Review Artifact Studio",
      action = "Inspect the generated evidence.",
      reason = "The project contains artifacts. The next useful move is to inspect quality, diagnostics, recommendations, and backing assets before deciding what to report or investigate next.",
      benefit = "Turns generated output into understood evidence.",
      cost = "Low",
      confidence = "High",
      target = "Artifact Studio"
    ))
  }

  list(
    title = "Review Mission Control",
    action = "Inspect project health and workflow state.",
    reason = "The deterministic Guide did not detect a more specific next step.",
    benefit = "Mission Control will surface operational gaps, warnings, and readiness indicators.",
    cost = "Low",
    confidence = "Medium",
    target = "Mission Control"
  )
}

guide_status <- function(value) {
  switch(
    value,
    good = "success",
    attention = "warning",
    missing = "error",
    unknown = "neutral",
    "neutral"
  )
}

guide_health_rows <- function(state) {
  genai_value <- state$genai$value %||% list()
  data.table::data.table(
    area = c("Data", "Artifacts", "Collector", "Knowledge", "GenAI", "Async Jobs"),
    status = c(
      if (is.null(state$data)) "Missing" else "Good",
      if (state$artifact_count > 0L) "Good" else "Missing",
      if (isTRUE(state$collector_ready)) "Good" else if (state$artifact_count > 0L) "Needs Attention" else "Missing",
      if (state$decision_readiness %in% c("Reasonable", "High Confidence")) "Good" else if (state$project_exists) "Needs Attention" else "Missing",
      if (isTRUE(genai_value$available)) "Good" else if (isTRUE(genai_value$configured)) "Needs Attention" else "Missing",
      if ((state$async$running %||% 0L) > 0L) "Good" else if (identical(state$async$latest_status %||% "", "unavailable")) "Unknown" else "Good"
    ),
    detail = c(
      if (is.null(state$data)) "Load data or open a project." else paste(nrow(state$data), "rows x", ncol(state$data), "columns"),
      paste(state$artifact_count, "artifact(s) in memory."),
      if (isTRUE(state$collector_ready)) paste(state$collector_artifacts, "artifact(s) preserved.") else "Collector memory is not fully ready.",
      paste(state$knowledge_state, "-", state$decision_readiness),
      state$genai$metadata$diagnostic_reason %||% "not_checked",
      paste("running:", state$async$running %||% 0L, "failed:", state$async$failed %||% 0L)
    )
  )
}

ui_guide_action_card <- function(title, message, when = NULL, action = NULL, status = "info") {
  tags$article(
    class = .aq_class("aq-guide-action-card", paste0("aq-guide-action-card-", status)),
    tags$div(
      class = "aq-guide-action-card-copy",
      tags$strong(title),
      tags$p(message),
      if (!is.null(when)) tags$span(class = "aq-guide-action-card-when", when)
    ),
    if (!is.null(action)) tags$div(class = "aq-guide-action-card-action", action)
  )
}

ui_guide_learn_item <- function(title, message, href = "#") {
  tags$a(
    class = "aq-guide-learn-item",
    href = href,
    tags$strong(title),
    tags$span(message)
  )
}

ui_guide_recommendation <- function(recommendation) {
  ui_card(
    title = "Recommended Next Step",
    subtitle = "Deterministic guidance based on the current workspace state.",
    class = "aq-guide-recommendation-card",
    tags$div(
      class = "aq-guide-recommendation",
      tags$p(class = "aq-guide-recommendation-label", recommendation$title),
      tags$h3(recommendation$action),
      tags$p(recommendation$reason),
      tags$div(
        class = "aq-guide-recommendation-facts",
        ui_stat_tile("Benefit", recommendation$benefit, status = "info"),
        ui_stat_tile("Cost", recommendation$cost, status = "neutral"),
        ui_stat_tile("Confidence", recommendation$confidence, status = "success")
      )
    )
  )
}

home_concept_choices <- function() {
  c(
    "The Edge of the Known" = "edge_known",
    "Wake the Instrument" = "wake_instrument",
    "Boundary Conditions" = "boundary_conditions"
  )
}

home_concept_copy <- function(concept) {
  switch(
    concept,
    edge_known = list(
      name = "The Edge of the Known",
      eyebrow = "Analytics Workstation",
      title = "The edge of the known.",
      sentence = "Evidence begins at the boundary."
    ),
    wake_instrument = list(
      name = "Wake the Instrument",
      eyebrow = "Arrival Ritual",
      title = "Wake the instrument.",
      sentence = "Serious work can still feel like entering a room built by someone who cared."
    ),
    boundary_conditions = list(
      name = "Boundary Conditions",
      eyebrow = "Observatory Mode",
      title = "Prepare to think.",
      sentence = "A quiet threshold before the project becomes practical again."
    ),
    list(name = "The Edge of the Known", eyebrow = "Analytics Workstation", title = "The edge of the known.", sentence = "Evidence begins at the boundary.")
  )
}

ui_home_art <- function(id, kind, state = NULL) {
  data_points <- paste(
    c(
      state$artifact_count %||% 0L,
      state$collector_artifacts %||% 0L,
      if (isTRUE(state$collector_ready)) 1L else 0L,
      state$plan_count %||% 0L
    ),
    collapse = ","
  )
  tags$div(
    id = id,
    class = .aq_class("aq-home-art", paste0("aq-home-art-", kind)),
    `data-kind` = kind,
    `data-points` = data_points,
    tags$canvas(class = "aq-home-canvas", `aria-hidden` = "true"),
    if (requireNamespace("echarts4r", quietly = TRUE)) {
      echarts4r::echarts4rOutput(paste0(id, "_chart"), width = "100%", height = "100%")
    },
    tags$div(class = "aq-home-art-fallback", "Analytical field")
  )
}

home_art_point <- function(x, y) {
  list(round(x, 3), round(y, 3))
}

home_art_segment <- function(x1, y1, x2, y2, value = 1) {
  list(coords = list(home_art_point(x1, y1), home_art_point(x2, y2)), value = value)
}

home_art_polyline <- function(x, y, value = 1) {
  list(coords = Map(home_art_point, x, y), value = value)
}

home_art_normalize <- function(x, min_value = 8, max_value = 92) {
  rng <- range(x, finite = TRUE)
  if (!is.finite(diff(rng)) || isTRUE(all.equal(diff(rng), 0))) {
    return(rep((min_value + max_value) / 2, length(x)))
  }
  min_value + ((x - rng[1]) / diff(rng)) * (max_value - min_value)
}

home_art_edge_lines <- function(state) {
  artifacts <- max(1, state$artifact_count %||% 0L)
  collector <- max(1, state$collector_artifacts %||% 0L)
  phase <- log1p(artifacts + collector) / 9
  families <- list()

  for (j in seq_len(9)) {
    theta <- seq(-2.45, 2.45, length.out = 120)
    bend <- (j - 5) * 0.18
    r <- tanh(seq(0.12, 2.7, length.out = length(theta)))
    x <- 50 + 43 * r * cos(theta + bend + phase)
    y <- 50 + 43 * r * sin(theta * (0.88 + j * 0.012) - bend)
    families[[length(families) + 1L]] <- home_art_polyline(x, y, value = j)
  }

  for (j in seq_len(11)) {
    theta <- seq(0, 2 * pi, length.out = 180)
    radius <- 8 + j * 3.55
    wobble <- 1 + 0.04 * sin(theta * (j + 2) + phase)
    x <- 50 + radius * wobble * cos(theta + phase / 2)
    y <- 50 + radius * wobble * sin(theta)
    families[[length(families) + 1L]] <- home_art_polyline(x, y, value = 10 + j)
  }

  families
}

home_art_instrument_lines <- function(state) {
  n <- 3200L
  sigma <- 10
  rho <- 28 + min(8, log1p(state$artifact_count %||% 0L))
  beta <- 8 / 3
  dt <- 0.006
  x <- y <- z <- numeric(n)
  x[1] <- 0.1
  y[1] <- 0
  z[1] <- 0

  for (i in 2:n) {
    x[i] <- x[i - 1] + sigma * (y[i - 1] - x[i - 1]) * dt
    y[i] <- y[i - 1] + (x[i - 1] * (rho - z[i - 1]) - y[i - 1]) * dt
    z[i] <- z[i - 1] + (x[i - 1] * y[i - 1] - beta * z[i - 1]) * dt
  }

  keep <- seq(350, n, by = 2)
  px <- home_art_normalize(x[keep] + z[keep] * 0.08, 14, 86)
  py <- home_art_normalize(y[keep] - z[keep] * 0.11, 10, 90)
  chunks <- split(seq_along(px), ceiling(seq_along(px) / 360))
  lapply(seq_along(chunks), function(i) {
    idx <- chunks[[i]]
    home_art_polyline(px[idx], py[idx], value = i)
  })
}

home_art_boundary_lines <- function(state) {
  collector_ready <- if (isTRUE(state$collector_ready)) 1 else 0
  drift <- log1p(max(1, state$plan_count %||% 0L)) / 7
  xs <- seq(8, 92, length.out = 33)
  ys <- seq(12, 88, length.out = 25)
  grid <- expand.grid(x = xs, y = ys, KEEP.OUT.ATTRS = FALSE)

  lapply(seq_len(nrow(grid)), function(i) {
    x <- grid$x[i]
    y <- grid$y[i]
    cx <- (x - 50) / 22
    cy <- (y - 50) / 22
    angle <- atan2(cy, cx) + sin(cx * 1.9 + drift) * 0.65 - cos(cy * 2.3) * 0.55
    len <- 1.35 + 2.45 / (1 + cx^2 + cy^2) + collector_ready * 0.45
    home_art_segment(
      x - cos(angle) * len,
      y - sin(angle) * len,
      x + cos(angle) * len,
      y + sin(angle) * len,
      value = len
    )
  })
}

home_art_particles <- function(kind, state) {
  if (identical(kind, "instrument")) {
    theta <- seq(0, 8 * pi, length.out = 90)
    radius <- seq(4, 36, length.out = length(theta))
    return(Map(function(x, y) list(value = home_art_point(x, y)), 50 + cos(theta) * radius, 50 + sin(theta) * radius))
  }

  n <- if (identical(kind, "boundary")) 144L else 180L
  k <- seq_len(n)
  theta <- k * pi * (3 - sqrt(5))
  radius <- sqrt(k / n) * 43
  Map(function(x, y) list(value = home_art_point(x, y)), 50 + cos(theta) * radius, 50 + sin(theta) * radius)
}

home_art_options <- function(kind, state) {
  colors <- switch(
    kind,
    instrument = c("#23d3ee", "#4da3ff", "#ff2bd6", "#78d957"),
    boundary = c("#78d957", "#23d3ee", "#4da3ff", "#ffffff"),
    c("#4da3ff", "#23d3ee", "#78d957", "#ffffff")
  )
  line_data <- switch(
    kind,
    instrument = home_art_instrument_lines(state),
    boundary = home_art_boundary_lines(state),
    home_art_edge_lines(state)
  )
  particle_data <- home_art_particles(kind, state)

  list(
    animation = TRUE,
    backgroundColor = "transparent",
    tooltip = list(show = FALSE),
    grid = list(left = 0, right = 0, top = 0, bottom = 0),
    xAxis = list(type = "value", min = 0, max = 100, show = FALSE),
    yAxis = list(type = "value", min = 0, max = 100, show = FALSE),
    color = colors,
    series = list(
      list(
        name = "Field",
        type = "lines",
        coordinateSystem = "cartesian2d",
        polyline = !identical(kind, "boundary"),
        data = line_data,
        silent = TRUE,
        blendMode = "lighter",
        lineStyle = list(
          width = if (identical(kind, "boundary")) 1.35 else 1.8,
          opacity = if (identical(kind, "boundary")) 0.42 else 0.58,
          curveness = 0.28,
          color = colors[[1]]
        ),
        effect = list(
          show = TRUE,
          period = if (identical(kind, "instrument")) 8 else 11,
          trailLength = if (identical(kind, "boundary")) 0.42 else 0.18,
          symbol = "circle",
          symbolSize = if (identical(kind, "boundary")) 2.2 else 3.5,
          color = colors[[2]]
        )
      ),
      list(
        name = "Boundary",
        type = "effectScatter",
        coordinateSystem = "cartesian2d",
        data = particle_data,
        silent = TRUE,
        rippleEffect = list(
          period = 7,
          scale = if (identical(kind, "edge")) 3.8 else 2.4,
          brushType = "stroke"
        ),
        symbolSize = if (identical(kind, "instrument")) 4 else 3,
        itemStyle = list(color = colors[[3]], opacity = 0.82)
      )
    )
  )
}

home_blank_flow_data <- function(kind, state) {
  grid_step <- if (identical(kind, "boundary")) 0.095 else 0.075
  vals <- expand.grid(
    x = seq(-1.25, 1.25, by = grid_step),
    y = seq(-1.25, 1.25, by = grid_step),
    KEEP.OUT.ATTRS = FALSE
  )
  artifacts <- log1p(max(1, state$artifact_count %||% 0L))
  collector <- log1p(max(1, state$collector_artifacts %||% 0L))
  plans <- log1p(max(1, state$plan_count %||% 0L))
  r2 <- vals$x^2 + vals$y^2
  theta <- atan2(vals$y, vals$x)

  if (identical(kind, "instrument")) {
    mu <- 12 + artifacts
    vals$sx <- vals$y + sin(vals$x * 5 + collector) * 0.22
    vals$sy <- -1 * (mu * (1 - vals$x^2) * vals$y - vals$x) / 12 +
      cos(vals$y * 4 - plans) * 0.18
    vals$color <- abs(vals$sx) + abs(vals$sy) + r2
    return(vals)
  }

  if (identical(kind, "boundary")) {
    vals$sx <- sin(vals$y * 3.8 + theta + plans) + vals$x * (0.55 - r2)
    vals$sy <- cos(vals$x * 3.3 - theta + collector) - vals$y * (0.55 - r2)
    vals$color <- sqrt(vals$sx^2 + vals$sy^2) + abs(sin(theta * 5))
    return(vals)
  }

  edge <- pmax(0.08, abs(1 - r2))
  vals$sx <- (-vals$y / edge) + 0.35 * sin(theta * 4 + artifacts)
  vals$sy <- (vals$x / edge) + 0.35 * cos(theta * 3 - collector)
  vals$sx[r2 > 1.55] <- vals$sx[r2 > 1.55] * 0.25
  vals$sy[r2 > 1.55] <- vals$sy[r2 > 1.55] * 0.25
  vals$color <- 1 / edge + abs(sin(theta * 7))
  vals
}

home_blank_flow_palette <- function(kind) {
  switch(
    kind,
    instrument = c("#020712", "#0b2030", "#23d3ee", "#ff2bd6", "#ffffff"),
    boundary = c("#04110d", "#0f4434", "#78d957", "#23d3ee", "#ffffff"),
    c("#020712", "#0b1d37", "#4da3ff", "#23d3ee", "#78d957", "#ffffff")
  )
}

home_art_echart <- function(kind, state) {
  if (!exists("e_flow_gl", envir = asNamespace("echarts4r"))) {
    return(echarts4r::e_charts(data.frame(x = 0, y = 0), x) |>
      echarts4r::e_list(home_art_options(kind, state)))
  }

  vals <- home_blank_flow_data(kind, state)
  palette <- home_blank_flow_palette(kind)
  density <- if (identical(kind, "instrument")) 96 else if (identical(kind, "boundary")) 82 else 112
  particle_size <- if (identical(kind, "instrument")) 4 else if (identical(kind, "boundary")) 3 else 5
  color_min <- unname(min(vals$color, na.rm = TRUE))
  color_max <- unname(quantile(vals$color, probs = 0.96, na.rm = TRUE))

  vals |>
    echarts4r::e_charts(x) |>
    echarts4r::e_flow_gl(
      y,
      sx,
      sy,
      color,
      particleSize = particle_size,
      particleDensity = density,
      itemStyle = list(opacity = 0.86)
    ) |>
    echarts4r::e_visual_map(
      min = color_min,
      max = color_max,
      dimension = 4,
      scale = echarts4r::e_scale,
      show = FALSE,
      inRange = list(color = palette)
    ) |>
    echarts4r::e_theme(name = "dark") |>
    echarts4r::e_x_axis(min = -1.25, max = 1.25, splitLine = list(show = FALSE), show = FALSE) |>
    echarts4r::e_y_axis(min = -1.25, max = 1.25, splitLine = list(show = FALSE), show = FALSE)
}

ui_home_action <- function(label, id, primary = FALSE) {
  actionButton(
    id,
    label,
    class = if (isTRUE(primary)) "btn-primary aq-home-action" else "btn-secondary aq-home-action"
  )
}

ui_home_concept_selector <- function(ns) {
  tags$div(
    class = "aq-home-concept-panel",
    tags$div(
      class = "aq-home-concept-selector",
      tags$span("Prototype"),
      selectInput(
        ns("home_concept"),
        label = NULL,
        choices = home_concept_choices(),
        selected = "edge_known",
        width = "260px",
        selectize = FALSE
      )
    )
  )
}

ui_home_concept <- function(concept, state, recommendation, ns) {
  copy <- home_concept_copy(concept)
  resume_label <- if (isTRUE(state$project_exists)) "Resume" else "Begin"

  if (identical(concept, "edge_known")) {
    return(tags$section(
      class = "aq-home-arrival aq-home-ritual aq-home-arrival-edge",
      ui_home_art(ns("home_art"), "edge", state),
      tags$div(
        class = "aq-home-ritual-copy",
        tags$p(class = "aq-home-eyebrow", copy$eyebrow),
        tags$h2(copy$title),
        tags$p(copy$sentence),
        tags$div(
          class = "aq-home-actions",
          ui_home_action(resume_label, ns("home_resume"), primary = TRUE),
          ui_home_action("Open", ns("home_open_project")),
          ui_home_action("New", ns("home_start_project"))
        )
      )
    ))
  }

  if (identical(concept, "wake_instrument")) {
    return(tags$section(
      class = "aq-home-arrival aq-home-ritual aq-home-arrival-instrument",
      ui_home_art(ns("home_art"), "instrument", state),
      tags$div(
        class = "aq-home-ritual-copy aq-home-ritual-copy-center",
        tags$p(class = "aq-home-eyebrow", copy$eyebrow),
        tags$h2(copy$title),
        tags$p(copy$sentence),
        tags$div(
          class = "aq-home-actions aq-home-actions-centered",
          ui_home_action("Wake", ns("home_resume"), primary = TRUE),
          ui_home_action("Open", ns("home_open_project")),
          ui_home_action("New", ns("home_start_project"))
        )
      )
    ))
  }

  tags$section(
    class = "aq-home-arrival aq-home-ritual aq-home-arrival-boundary",
    ui_home_art(ns("home_art"), "boundary", state),
    tags$div(
      class = "aq-home-ritual-copy aq-home-ritual-copy-bottom",
      tags$p(class = "aq-home-eyebrow", copy$eyebrow),
      tags$h2(copy$title),
      tags$p(copy$sentence),
      tags$div(
        class = "aq-home-actions",
        ui_home_action("Resume", ns("home_resume"), primary = TRUE),
        ui_home_action("Open Project", ns("home_open_project")),
        ui_home_action("Start New", ns("home_start_project"))
      )
    )
  )
}

guide_flow_steps <- function() {
  list(
    questions = list(
      title = "Business Questions",
      label = "Business Questions",
      message = "Start with the decision, opportunity, or uncertainty that makes the analysis worth doing.",
      action = "Plan the investigation before choosing modules.",
      target = "Workflow"
    ),
    knowledge = list(
      title = "Knowledge",
      label = "Knowledge",
      message = "Capture what is known, unknown, assumed, and decision-ready as evidence accumulates.",
      action = "Review current workspace state and knowledge gaps.",
      target = "Project"
    ),
    evidence = list(
      title = "Evidence",
      label = "Evidence",
      message = "Generate and inspect artifacts that support, weaken, or clarify analytical claims.",
      action = "Open Artifact Studio to inspect evidence objects.",
      target = "Artifact Studio"
    ),
    decisions = list(
      title = "Decisions",
      label = "Decisions",
      message = "Use evidence, uncertainty, and recommendations to support a governed decision.",
      action = "Open the decision workspace when alternatives are ready.",
      target = "Decision Management"
    )
  )
}

page_guide_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Guide",
    ui_page(
      title = NULL,
      subtitle = NULL,
      eyebrow = NULL,
      tags$div(
        class = "aq-guide-page",
        tags$script(HTML("
          (function() {
            if (window.aqHomeTournamentLoaded) return;
            window.aqHomeTournamentLoaded = true;

            function cssVar(name, fallback) {
              var value = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
              return value || fallback;
            }

            function drawField(canvas, kind, points) {
              if (!canvas || !canvas.getContext) return;
              var wrapper = canvas.closest('.aq-home-art');
              var rect = wrapper.getBoundingClientRect();
              var dpr = window.devicePixelRatio || 1;
              var width = Math.max(320, Math.round(rect.width));
              var height = Math.max(220, Math.round(rect.height));
              canvas.width = width * dpr;
              canvas.height = height * dpr;
              canvas.style.width = width + 'px';
              canvas.style.height = height + 'px';
              var ctx = canvas.getContext('2d');
              ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
              ctx.clearRect(0, 0, width, height);

              var primary = cssVar('--aq-primary', '#4da3ff');
              var accent = cssVar('--aq-accent', '#78d957');
              var text = cssVar('--aq-text', '#e8f0ff');
              var danger = cssVar('--aq-danger', '#ff5c7a');
              var muted = cssVar('--aq-muted', '#93a8c8');
              var total = points.reduce(function(sum, value) { return sum + Math.abs(value || 0); }, 0) || 1;
              var drift = (points[0] || 0) / total;
              var memory = (points[1] || 0) / total;
              var ready = points[2] || 0;

              ctx.globalCompositeOperation = 'source-over';
              var bg = ctx.createRadialGradient(width * .5, height * .5, 20, width * .5, height * .5, Math.max(width, height) * .65);
              bg.addColorStop(0, 'rgba(77, 163, 255, 0.12)');
              bg.addColorStop(1, 'rgba(0, 0, 0, 0)');
              ctx.fillStyle = bg;
              ctx.fillRect(0, 0, width, height);

              var rows = kind === 'boundary' ? 42 : 30;
              var cols = kind === 'edge' ? 54 : 46;
              var t = Date.now() / 1600;
              var reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
              if (reduced) t = 0;
              for (var y = 0; y < rows; y++) {
                for (var x = 0; x < cols; x++) {
                  var px = (x + .5) / cols * width;
                  var py = (y + .5) / rows * height;
                  var nx = (px / width - .5) * 2;
                  var ny = (py / height - .5) * 2;
                  var angle;
                  var mag;
                  if (kind === 'instrument') {
                    angle = Math.atan2(ny + memory, nx - drift) + Math.sin(nx * 6 + t) * .7;
                    mag = .35 + Math.abs(Math.sin((nx + ny) * 5 + ready)) * .75;
                  } else if (kind === 'boundary') {
                    angle = Math.atan2(ny, nx) + Math.sin(Math.sqrt(nx * nx + ny * ny) * 9 - t) * 1.7;
                    mag = .2 + (1 - Math.min(1, Math.sqrt(nx * nx + ny * ny))) * 1.5;
                  } else {
                    angle = Math.atan2(ny, nx) + Math.sin((nx * nx - ny * ny) * 7 + t) * 1.2;
                    mag = .35 + Math.abs(Math.sin(nx * 4) * Math.cos(ny * 4));
                  }
                  var len = Math.max(4, Math.min(18, mag * 12));
                  var hue = (x / cols + y / rows) / 2;
                  ctx.strokeStyle = hue > .66 ? accent : hue > .38 ? primary : (kind === 'instrument' ? danger : muted);
                  ctx.globalAlpha = kind === 'edge' ? .42 : .34 + mag * .24;
                  ctx.lineWidth = kind === 'boundary' ? 1.4 : 1;
                  ctx.beginPath();
                  ctx.moveTo(px - Math.cos(angle) * len, py - Math.sin(angle) * len);
                  ctx.lineTo(px + Math.cos(angle) * len, py + Math.sin(angle) * len);
                  ctx.stroke();
                }
              }

              if (kind === 'edge' || kind === 'boundary') {
                ctx.globalAlpha = .7;
                ctx.strokeStyle = primary;
                ctx.lineWidth = 1.2;
                for (var r = 0; r < 5; r++) {
                  ctx.beginPath();
                  ctx.ellipse(width / 2, height / 2, width * (.12 + r * .08), height * (.08 + r * .05), r * .22, 0, Math.PI * 2);
                  ctx.stroke();
                }
              }
              ctx.globalAlpha = 1;
            }

            function checkHomeWidget(node, attempt) {
              attempt = attempt || 1;
              var widget = node.querySelector('.html-widget');
              var hasEchartsCanvas = !!(widget && widget.querySelector('canvas'));
              if (hasEchartsCanvas || attempt >= 12) {
                node.classList.toggle('aq-home-art-use-fallback', !hasEchartsCanvas);
                return;
              }
              window.setTimeout(function() { checkHomeWidget(node, attempt + 1); }, 150);
            }

            function initHomeFields(root) {
              (root || document).querySelectorAll('.aq-home-art').forEach(function(node) {
                var canvas = node.querySelector('.aq-home-canvas');
                var points = (node.getAttribute('data-points') || '0,0,0,0').split(',').map(function(value) { return Number(value) || 0; });
                drawField(canvas, node.getAttribute('data-kind') || 'poincare', points);
                checkHomeWidget(node, 1);
              });
            }

            function homeConceptDetails(value) {
              var concepts = {
                edge_known: {
                  arrivalClass: 'aq-home-arrival-edge',
                  artClass: 'aq-home-art-edge',
                  kind: 'edge',
                  eyebrow: 'Analytics Workstation',
                  title: 'The edge of the known.',
                  sentence: 'Evidence begins at the boundary.',
                  buttons: ['Begin', 'Open', 'New']
                },
                wake_instrument: {
                  arrivalClass: 'aq-home-arrival-instrument',
                  artClass: 'aq-home-art-instrument',
                  kind: 'instrument',
                  eyebrow: 'Arrival Ritual',
                  title: 'Wake the instrument.',
                  sentence: 'Serious work can still feel like entering a room built by someone who cared.',
                  buttons: ['Wake', 'Open', 'New']
                },
                boundary_conditions: {
                  arrivalClass: 'aq-home-arrival-boundary',
                  artClass: 'aq-home-art-boundary',
                  kind: 'boundary',
                  eyebrow: 'Observatory Mode',
                  title: 'Prepare to think.',
                  sentence: 'A quiet threshold before the project becomes practical again.',
                  buttons: ['Resume', 'Open Project', 'Start New']
                }
              };
              return concepts[value] || concepts.edge_known;
            }

            function applyHomeConcept(value) {
              var details = homeConceptDetails(value);
              var arrival = document.querySelector('.aq-home-arrival');
              var art = document.querySelector('.aq-home-art');
              if (!arrival || !art) return;
              arrival.classList.remove('aq-home-arrival-edge', 'aq-home-arrival-instrument', 'aq-home-arrival-boundary');
              arrival.classList.add(details.arrivalClass);
              art.classList.remove('aq-home-art-edge', 'aq-home-art-instrument', 'aq-home-art-boundary');
              art.classList.add(details.artClass);
              art.setAttribute('data-kind', details.kind);
              var copy = document.querySelector('.aq-home-ritual-copy');
              if (copy) {
                var eyebrow = copy.querySelector('.aq-home-eyebrow');
                var title = copy.querySelector('h2');
                var sentence = copy.querySelector('p:not(.aq-home-eyebrow)');
                if (eyebrow) eyebrow.textContent = details.eyebrow;
                if (title) title.textContent = details.title;
                if (sentence) sentence.textContent = details.sentence;
                copy.classList.toggle('aq-home-ritual-copy-center', value === 'wake_instrument');
                copy.classList.toggle('aq-home-ritual-copy-bottom', value === 'boundary_conditions');
              }
              document.querySelectorAll('.aq-home-action').forEach(function(button, index) {
                if (details.buttons[index]) button.textContent = details.buttons[index];
              });
              initHomeFields(arrival);
            }

            var lastHomeConceptValue = null;
            function syncHomeConcept() {
              var control = document.querySelector('select[id$=\"home_concept\"]');
              if (!control || !window.Shiny || !Shiny.setInputValue) return;
              if (control.value === lastHomeConceptValue) return;
              lastHomeConceptValue = control.value;
              applyHomeConcept(control.value);
              Shiny.setInputValue(control.id, control.value, { priority: 'event' });
            }

            document.addEventListener('DOMContentLoaded', function() {
              initHomeFields(document);
              window.setTimeout(syncHomeConcept, 50);
            });
            document.addEventListener('shiny:value', function(event) {
              window.setTimeout(function() { initHomeFields(document); }, 40);
            });
            document.addEventListener('change', function(event) {
              var control = event.target.closest('select[id$=\"home_concept\"]');
              if (!control || !window.Shiny || !Shiny.setInputValue) return;
              lastHomeConceptValue = null;
              syncHomeConcept();
            });
            document.addEventListener('input', function(event) {
              if (event.target.closest('select[id$=\"home_concept\"]')) {
                lastHomeConceptValue = null;
                syncHomeConcept();
              }
            });
            window.addEventListener('resize', function() { window.setTimeout(function() { initHomeFields(document); }, 80); });
            new MutationObserver(function(mutations) {
              mutations.forEach(function(mutation) {
                mutation.addedNodes.forEach(function(node) {
                  if (node.nodeType === 1) initHomeFields(node);
                });
              });
              window.setTimeout(syncHomeConcept, 20);
            }).observe(document.documentElement, { childList: true, subtree: true });
            window.setInterval(syncHomeConcept, 500);
          })();
        ")),
        tags$div(
          class = "aq-home-arrival-frame",
          ui_home_concept_selector(ns),
          ui_home_concept("edge_known", list(), NULL, ns)
        ),
        ui_split_panel(
          main = tagList(
            uiOutput(ns("current_workspace")),
            uiOutput(ns("recommended_next_step")),
            ui_card(
              title = "Primary Actions",
              subtitle = "Start from intent, not modules.",
              uiOutput(ns("primary_actions"))
            ),
            uiOutput(ns("current_investigation")),
            ui_card(
              title = "Learn the Workstation",
              subtitle = "Short paths into the architecture. These are stable reference hooks for the future Knowledge Library.",
              tags$div(
                class = "aq-guide-learn-grid",
                ui_guide_learn_item("How Analytics Workstation Works", "Project -> evidence -> collector -> decisions.", "#guide-how-it-works"),
                ui_guide_learn_item("Analytical Intelligence Loop", "Question -> plan -> evidence -> reasoning -> learning.", "#guide-intelligence-loop"),
                ui_guide_learn_item("Artifacts as Evidence", "Generated outputs become inspectable evidence.", "#guide-artifacts"),
                ui_guide_learn_item("Knowledge State", "Knowns, unknowns, assumptions, and readiness.", "#guide-knowledge-state"),
                ui_guide_learn_item("Evidence Routing", "Choose evidence before asking GenAI to reason.", "#guide-evidence-routing"),
                ui_guide_learn_item("Context Optimization", "Use the best context for the lowest cost.", "#guide-context-optimization"),
                ui_guide_learn_item("Execution Modes", "Manual, guided, assisted, autonomous, research.", "#guide-execution-modes"),
                ui_guide_learn_item("Knowledge Library", "The future authoritative reference surface.", "#guide-knowledge-library"),
                ui_guide_learn_item("Book", "The long-form argument for AI-native analytical systems.", "#guide-book")
              )
            )
          ),
          side_content = tags$aside(
            class = "aq-guide-panel",
            uiOutput(ns("guide_panel")),
            uiOutput(ns("workspace_health"))
          )
        )
      )
    )
  )
}

page_guide_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    guide_state <- reactive(guide_state_from_context(ctx))
    guide_next <- reactive(guide_recommendation(guide_state()))
    selected_home_concept <- reactive(input$home_concept %||% "edge_known")
    flow_steps <- guide_flow_steps()
    selected_flow_step <- reactiveVal("questions")

    if (requireNamespace("echarts4r", quietly = TRUE)) {
      output$home_art_chart <- echarts4r::renderEcharts4r({
        kind <- switch(
          selected_home_concept(),
          wake_instrument = "instrument",
          boundary_conditions = "boundary",
          "edge"
        )
        home_art_echart(kind, guide_state())
      })
    }

    observeEvent(input$open_project, ctx$navigate_to("Project"), ignoreInit = TRUE)
    observeEvent(input$open_mission_control, ctx$navigate_to("Mission Control"), ignoreInit = TRUE)
    observeEvent(input$load_data, ctx$navigate_to("Data"), ignoreInit = TRUE)
    observeEvent(input$open_existing_project, ctx$navigate_to("Project"), ignoreInit = TRUE)
    observeEvent(input$resume_investigation, ctx$navigate_to("Workflow"), ignoreInit = TRUE)
    observeEvent(input$ask_business_question, ctx$navigate_to("Workflow"), ignoreInit = TRUE)
    observeEvent(input$open_artifact_studio, ctx$navigate_to("Artifact Studio"), ignoreInit = TRUE)
    observeEvent(input$review_mission_control, ctx$navigate_to("Mission Control"), ignoreInit = TRUE)
    observeEvent(input$read_knowledge_library, ctx$navigate_to("Knowledge Library"), ignoreInit = TRUE)
    observeEvent(input$run_recommended, ctx$navigate_to(guide_next()$target %||% "Mission Control"), ignoreInit = TRUE)
    observeEvent(input$home_resume, ctx$navigate_to("Project"), ignoreInit = TRUE)
    observeEvent(input$home_open_project, ctx$navigate_to("Project"), ignoreInit = TRUE)
    observeEvent(input$home_start_project, ctx$navigate_to("Project"), ignoreInit = TRUE)
    observeEvent(input$home_open_artifacts, ctx$navigate_to("Artifact Studio"), ignoreInit = TRUE)
    observeEvent(input$home_delivery, ctx$navigate_to("Export"), ignoreInit = TRUE)
    observeEvent(input$home_recommended, ctx$navigate_to(guide_next()$target %||% "Mission Control"), ignoreInit = TRUE)
    observeEvent(input$home_decisions, ctx$navigate_to("Decision Management"), ignoreInit = TRUE)
    observeEvent(input$home_question, ctx$navigate_to("Workflow"), ignoreInit = TRUE)
    observeEvent(input$home_library, ctx$navigate_to("Knowledge Library"), ignoreInit = TRUE)
    observeEvent(input$go_flow_step, {
      step <- flow_steps[[selected_flow_step()]]
      ctx$navigate_to(step$target %||% "Workflow")
    }, ignoreInit = TRUE)

    lapply(names(flow_steps), function(step_id) {
      observeEvent(input[[paste0("flow_", step_id)]], {
        selected_flow_step(step_id)
      }, ignoreInit = TRUE)
    })

    output$flow_steps <- renderUI({
      step_id <- selected_flow_step()
      tagList(lapply(names(flow_steps), function(candidate) {
        actionButton(
          session$ns(paste0("flow_", candidate)),
          flow_steps[[candidate]]$label,
          class = .aq_class(
            "btn-link",
            "aq-guide-flow-step",
            if (identical(candidate, step_id)) "aq-guide-flow-step-active" else NULL
          )
        )
      }))
    })

    output$flow_detail <- renderUI({
      step_id <- selected_flow_step()
      step <- flow_steps[[step_id]] %||% flow_steps$questions
      tags$article(
        class = "aq-guide-flow-detail",
        tags$div(
          tags$p(class = "aq-guide-flow-detail-label", "Selected step"),
          tags$h3(step$title),
          tags$p(step$message),
          tags$span(class = "aq-guide-flow-next", step$action)
        ),
        actionButton(session$ns("go_flow_step"), "Go there", class = "btn-secondary btn-sm")
      )
    })

    output$current_workspace <- renderUI({
      state <- guide_state()
      strategy_label <- state$evidence_strategy$strategy_label %||% state$evidence_strategy$strategy_id %||% "Balanced"
      execution_mode <- state$execution_policy$execution_mode %||% "disabled"
      collector_status <- if (isTRUE(state$collector_ready)) "Ready" else if (state$collector_artifacts > 0L) "Partial" else "Missing"
      running_jobs <- state$async$running %||% 0L

      ui_card(
        title = "Current Workspace",
        subtitle = if (state$project_exists) "The Guide reads this state before recommending a next step." else "No project loaded. Start from one of the actions below.",
        ui_stat_grid(
          ui_stat_tile("Project", state$project_name, status = if (state$project_exists) "success" else "neutral"),
          ui_stat_tile("Knowledge State", state$knowledge_state, status = if (state$project_exists) "info" else "neutral"),
          ui_stat_tile("Decision Readiness", state$decision_readiness, status = if (state$decision_readiness == "Reasonable") "success" else "warning"),
          ui_stat_tile("Execution Mode", execution_mode, status = if (identical(execution_mode, "disabled")) "neutral" else "info"),
          ui_stat_tile("Evidence Strategy", strategy_label, status = "info"),
          ui_stat_tile("Collector", collector_status, status = if (isTRUE(state$collector_ready)) "success" else "warning"),
          ui_stat_tile("Running Jobs", running_jobs, status = if (running_jobs > 0L) "info" else "neutral"),
          ui_stat_tile("Current Recommendation", guide_next()$title, status = "success")
        )
      )
    })

    output$recommended_next_step <- renderUI({
      tagList(
        ui_guide_recommendation(guide_next()),
        ui_action_row(actionButton(session$ns("run_recommended"), "Go to Recommended Surface", class = "btn-primary"))
      )
    })

    output$primary_actions <- renderUI({
      ns <- session$ns
      tags$div(
        class = "aq-guide-action-grid",
        ui_guide_action_card("Load Data", "Bring a dataset into the project world.", "Use when you are starting from raw data.", actionButton(ns("load_data"), "Open Data", class = "btn-primary btn-sm"), "success"),
        ui_guide_action_card("Open Existing Project", "Restore a saved workstation state.", "Use when evidence, collector files, or project settings already exist.", actionButton(ns("open_existing_project"), "Open Project", class = "btn-secondary btn-sm"), "info"),
        ui_guide_action_card("Resume Investigation", "Continue from workflow state and available evidence.", "Use when a project already has a question or partial evidence.", actionButton(ns("resume_investigation"), "Open Workflow", class = "btn-secondary btn-sm"), "info"),
        ui_guide_action_card("Ask a Business Question", "Start from the decision you are trying to make.", "Use when you know the decision before the analysis path.", actionButton(ns("ask_business_question"), "Plan Investigation", class = "btn-secondary btn-sm"), "warning"),
        ui_guide_action_card("Explore Artifact Studio", "Inspect evidence, thumbnails, diagnostics, recommendations, and sidecars.", "Use when artifacts already exist.", actionButton(ns("open_artifact_studio"), "Open Studio", class = "btn-secondary btn-sm"), "success"),
        ui_guide_action_card("Review Mission Control", "Check operational health, warnings, collector status, and readiness.", "Use when you need project state at a glance.", actionButton(ns("review_mission_control"), "Review", class = "btn-secondary btn-sm"), "info"),
        ui_guide_action_card("Read the Knowledge Library", "Learn concepts, architecture, research, and the evolving book.", "Use when you want the authoritative reference layer.", actionButton(ns("read_knowledge_library"), "Open Library", class = "btn-secondary btn-sm"), "info")
      )
    })

    output$current_investigation <- renderUI({
      state <- guide_state()
      known <- if (!state$project_exists) {
        "No project state is loaded."
      } else if (is.null(state$data)) {
        "Project evidence may exist, but no active dataset is loaded."
      } else {
        paste("Dataset loaded with", nrow(state$data), "rows and", ncol(state$data), "columns.")
      }
      unknown <- if (state$artifact_count == 0L) {
        "Distributions, readiness, model behavior, and recommendations are unknown."
      } else if (!guide_has_module(state, "autoquant_model_readiness")) {
        "Model readiness is unknown."
      } else if (!guide_has_module(state, "autoquant_regression_shap_analysis") && !guide_has_module(state, "autoquant_binary_shap_analysis")) {
        "Feature-level SHAP evidence may still be missing."
      } else {
        "Remaining unknowns depend on the business decision and artifact diagnostics."
      }
      evidence_needed <- guide_next()$action

      ui_card(
        title = "Current Investigation",
        subtitle = "A deterministic sketch of knowns, unknowns, evidence needed, and readiness.",
        tags$div(
          class = "aq-guide-investigation-grid",
          ui_callout("Known", known, status = if (state$project_exists) "success" else "info"),
          ui_callout("Unknown", unknown, status = "warning"),
          ui_callout("Evidence Needed", evidence_needed, status = "info"),
          ui_callout("Decision Readiness", state$decision_readiness, status = if (state$decision_readiness == "Reasonable") "success" else "warning")
        )
      )
    })

    output$guide_panel <- renderUI({
      state <- guide_state()
      recommendation <- guide_next()
      genai_status <- state$genai$metadata$display_name %||% "No GenAI Provider"
      genai_reason <- state$genai$metadata$diagnostic_reason %||% "not_configured"
      ui_card(
        title = "Guide Panel",
        subtitle = "Contextual mentoring without chat or autonomous action.",
        class = "aq-guide-side-card",
        ui_callout("Did you know?", "The workstation treats artifacts as evidence, not disposable output.", status = "info"),
        ui_callout("Why this recommendation?", recommendation$reason, status = "success"),
        ui_callout("Current Execution Mode", state$execution_policy$execution_mode %||% "disabled", status = "info"),
        ui_callout("Current Evidence Strategy", state$evidence_strategy$strategy_label %||% "Balanced", status = "info"),
        ui_callout("Next Suggested Action", recommendation$action, status = "success"),
        ui_callout("Architecture Tip", "The Guide teaches in context. The future Knowledge Library will preserve the authoritative references.", status = "info"),
        ui_callout("Guide AI", paste(genai_status, "-", genai_reason, ". The Guide remains deterministic when GenAI is unavailable."), status = if (identical(genai_reason, "available")) "success" else "warning")
      )
    })

    output$workspace_health <- renderUI({
      rows <- guide_health_rows(guide_state())
      ui_card(
        title = "Workspace Health",
        subtitle = "Good, needs attention, missing, or unknown.",
        class = "aq-guide-side-card",
        tags$div(
          class = "aq-guide-health-list",
          lapply(seq_len(nrow(rows)), function(index) {
            status <- rows$status[[index]]
            status_key <- switch(status, Good = "good", `Needs Attention` = "attention", Missing = "missing", Unknown = "unknown", "unknown")
            tags$article(
              class = .aq_class("aq-guide-health-item", paste0("aq-guide-health-item-", status_key)),
              tags$div(tags$strong(rows$area[[index]]), tags$p(rows$detail[[index]])),
              ui_status_badge(status, status = guide_status(status_key))
            )
          })
        )
      )
    })
  })
}

qa_guide_page <- function() {
  empty_state <- guide_state_from_context(overrides = list())
  empty_rec <- guide_recommendation(empty_state)
  loaded_state <- guide_state_from_context(overrides = list(
    data = data.frame(x = 1:5, y = c(2, 4, 3, 5, 6)),
    data_info = list(path = "demo.csv", name = "Demo Project")
  ))
  loaded_rec <- guide_recommendation(loaded_state)
  artifact_state <- guide_state_from_context(overrides = list(
    data = data.frame(x = 1:5, y = c(2, 4, 3, 5, 6)),
    data_info = list(path = "demo.csv", name = "Demo Project"),
    artifacts = list(list(artifact_id = "a1", artifact_type = "plot", source_module = "autoquant_eda", metadata = list(module_id = "autoquant_eda")))
  ))
  artifact_rec <- guide_recommendation(artifact_state)
  ui_text <- paste(as.character(page_guide_ui("guide")), collapse = " ")
  guide_source <- if (file.exists(file.path("R", "page_guide.R"))) {
    paste(readLines(file.path("R", "page_guide.R"), warn = FALSE), collapse = " ")
  } else {
    ""
  }
  panel_text <- paste(as.character(ui_guide_recommendation(empty_rec)), collapse = " ")
  app_ui_text <- if (file.exists(file.path("R", "app_ui.R"))) {
    paste(readLines(file.path("R", "app_ui.R"), warn = FALSE), collapse = " ")
  } else {
    ""
  }
  command_ids <- names(command_registry())
  css_text <- if (file.exists(file.path("www", "app.css"))) {
    paste(readLines(file.path("www", "app.css"), warn = FALSE), collapse = " ")
  } else {
    ""
  }

  data.table::data.table(
    check = c(
      "page_loads",
      "links_exist",
      "no_project_state",
      "loaded_project_state",
      "deterministic_recommendation_no_project",
      "deterministic_recommendation_loaded_data",
      "deterministic_recommendation_artifacts",
      "guide_panel_renders",
      "home_art_stable_render_binding",
      "default_landing",
      "command_palette_registration",
      "dark_theme_consistency"
    ),
    status = c(
      if (grepl("aq-home-arrival-frame", ui_text, fixed = TRUE) && grepl("aq-guide-page", ui_text, fixed = TRUE)) "success" else "error",
      if (grepl("href=\"#guide-artifacts\"", ui_text, fixed = TRUE) && grepl("Knowledge Library", ui_text, fixed = TRUE)) "success" else "error",
      if (!isTRUE(empty_state$project_exists) && identical(empty_state$decision_readiness, "Insufficient Evidence")) "success" else "error",
      if (isTRUE(loaded_state$project_exists) && identical(loaded_state$project_name, "Demo Project")) "success" else "error",
      if (identical(empty_rec$title, "Start with a project")) "success" else "error",
      if (identical(loaded_rec$title, "Run Explore Data")) "success" else "error",
      if (identical(artifact_rec$title, "Run Model Readiness")) "success" else "error",
      if (grepl("Recommended Next Step", panel_text, fixed = TRUE)) "success" else "error",
      if (grepl("ui_home_art(ns(\"home_art\")", guide_source, fixed = TRUE) &&
          grepl("ui_home_concept_selector", guide_source, fixed = TRUE) &&
          grepl("aq-home-arrival-frame", guide_source, fixed = TRUE) &&
          grepl("output$home_art_chart", guide_source, fixed = TRUE) &&
          grepl("applyHomeConcept", ui_text, fixed = TRUE) &&
          grepl("MutationObserver", ui_text, fixed = TRUE) &&
          grepl("Shiny.setInputValue(control.id, control.value", ui_text, fixed = TRUE)) "success" else "error",
      if (regexpr("page_guide_ui", app_ui_text, fixed = TRUE)[[1]] > 0L && regexpr("page_guide_ui", app_ui_text, fixed = TRUE)[[1]] < regexpr("page_mission_control_ui", app_ui_text, fixed = TRUE)[[1]]) "success" else "error",
      if ("open_guide" %in% command_ids) "success" else "error",
      if (grepl("aq-home-arrival-frame", ui_text, fixed = TRUE) && grepl(".aq-home-arrival", css_text, fixed = TRUE)) "success" else "error"
    ),
    message = c(
      "Guide page markup is available.",
      "Learn-workstation reference anchors and Knowledge Library placeholder exist.",
      "No-project state degrades gracefully.",
      "Loaded project state is summarized.",
      "No-project recommendation asks user to start with project context.",
      "Loaded data without artifacts recommends Explore Data.",
      "Artifacts without readiness recommend Model Readiness.",
      "Recommendation panel renders.",
      "Home arrival art uses one stable render binding, a persistent selector, and initializes when inserted.",
      "Guide is registered before Mission Control as the default landing tab.",
      "Command palette can open the Guide.",
      "Guide-specific dark workstation classes are present."
    )
  )
}
