build_week_demo_schema <- function() {
  c(
    "week",
    "region",
    "audience",
    "search_spend",
    "social_spend",
    "creative_age_weeks",
    "processing_delay_hours",
    "competitor_promo",
    "enrollments"
  )
}

build_week_demo_dataset_manifest <- function() {
  create_agent_dataset_manifest(
    dataset_id = "build_week_mystery_dataset",
    display_name = "Build Week Mystery Dataset",
    required_fields = build_week_demo_schema(),
    target_candidates = "enrollments",
    segment_fields = c("region", "audience"),
    time_field = "week",
    notes = "Deterministic 80-row demo dataset with recoverable saturation, interaction, delay, fatigue, competitor, and regional signals."
  )
}

generate_build_week_demo_data <- function(output_dir = "data", seed = 20260717L, write_files = TRUE) {
  set.seed(seed)
  if (isTRUE(write_files)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  design <- expand.grid(
    week_index = seq_len(10L),
    region = c("West", "Southwest", "Midwest", "Northeast"),
    audience = c("Career Changers", "Degree Seekers"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  design <- design[order(design$week_index, design$region, design$audience), ]
  rownames(design) <- NULL
  n <- nrow(design)

  week <- as.Date("2026-01-05") + 7L * (design$week_index - 1L)
  region_demand <- c(West = 10, Southwest = 3, Midwest = -2, Northeast = 6)
  region_delay <- c(West = 5, Southwest = 8, Midwest = -4, Northeast = 1)
  audience_search_shift <- ifelse(design$audience == "Degree Seekers", 8500, -2500)
  audience_social_shift <- ifelse(design$audience == "Career Changers", 7000, -1500)

  competitor_promo <- as.integer(
    (design$region == "West" & design$week_index %in% c(6L, 7L, 8L)) |
      (design$region == "Northeast" & design$week_index %in% c(4L, 5L)) |
      (design$region == "Southwest" & design$week_index %in% c(8L, 9L))
  )

  search_spend <- round(
    28000 + 2600 * design$week_index +
      ifelse(design$region == "West", 11000, 0) +
      ifelse(design$region == "Northeast", 7000, 0) +
      audience_search_shift + rnorm(n, 0, 3200),
    0
  )
  search_spend <- pmin(pmax(search_spend, 12000), 88000)

  social_spend <- round(
    15000 + 1800 * design$week_index +
      ifelse(design$region == "Southwest", 6500, 0) +
      audience_social_shift + rnorm(n, 0, 2600),
    0
  )
  social_spend <- pmax(social_spend, 6000)

  reset_offset <- c(West = 0L, Southwest = 2L, Midwest = 4L, Northeast = 1L)
  audience_offset <- ifelse(design$audience == "Career Changers", 0L, 2L)
  creative_age_weeks <- ((design$week_index + reset_offset[design$region] + audience_offset - 1L) %% 10L) + 1L

  processing_delay_hours <- 26 + region_delay[design$region] +
    0.00004 * search_spend + 3.0 * competitor_promo +
    ifelse(design$week_index %in% c(7L, 8L, 9L), 4, 0) + rnorm(n, 0, 2.4)
  processing_delay_hours <- round(pmax(processing_delay_hours, 14), 1)

  search_effect <- 70 * search_spend / (25000 + search_spend)
  social_base <- 17 * social_spend / (25000 + social_spend)
  social_effect <- social_base * ifelse(design$audience == "Career Changers", 1.55, 0.58)
  delay_over_36 <- pmax(processing_delay_hours - 36, 0)
  delay_effect <- -0.22 * pmax(processing_delay_hours - 24, 0) -
    1.15 * delay_over_36 - 0.055 * delay_over_36^2
  fatigue_over_6 <- pmax(creative_age_weeks - 6, 0)
  creative_effect <- -1.9 * fatigue_over_6 - 0.45 * fatigue_over_6^2
  expected_enrollments <- 22 + unname(region_demand[design$region]) +
    ifelse(design$audience == "Degree Seekers", 5.5, 0) +
    0.65 * design$week_index + search_effect + social_effect +
    delay_effect + creative_effect - 12.0 * competitor_promo
  enrollments <- round(pmax(expected_enrollments + rnorm(n, 0, 3.6 + 0.045 * pmax(expected_enrollments, 0)), 2))

  demo <- data.frame(
    week = week,
    region = factor(design$region, levels = c("West", "Southwest", "Midwest", "Northeast")),
    audience = factor(design$audience, levels = c("Career Changers", "Degree Seekers")),
    search_spend = as.numeric(search_spend),
    social_spend = as.numeric(social_spend),
    creative_age_weeks = as.integer(creative_age_weeks),
    processing_delay_hours = as.numeric(processing_delay_hours),
    competitor_promo = as.integer(competitor_promo),
    enrollments = as.integer(enrollments)
  )

  truth <- data.frame(
    mechanism = c(
      "Search saturation",
      "Social audience interaction",
      "Operational delay threshold",
      "Creative fatigue",
      "Competitor pressure",
      "Regional baseline"
    ),
    hidden_mechanism = c(
      "Search follows a diminishing-return curve, so high spend can look inefficient without implying that Search should be broadly cut.",
      "Social is materially more effective for Career Changers than Degree Seekers.",
      "Enrollment loss accelerates when processing delays exceed roughly 36 hours.",
      "Creative performance begins declining after roughly six weeks.",
      "Selected regional declines are caused by competitor promotions.",
      "Regions differ in demand baseline and operating capacity."
    ),
    expected_investigation = c(
      "Compare linear spend evidence with nonlinear saturation evidence.",
      "Test Social spend by audience rather than using one pooled effect.",
      "Inspect processing delay and threshold behavior before blaming media.",
      "Compare older and newer creative cohorts.",
      "Separate competitor-promo weeks from normal regional performance.",
      "Preserve region as a baseline control."
    ),
    intended_reveal = c(
      "Do not broadly reduce Search spend; tune high-spend marginal allocation.",
      "Target Social investment toward Career Changers.",
      "Improve operational throughput as the largest actionable intervention.",
      "Refresh aging creative.",
      "Treat competitor pressure separately from channel quality.",
      "Do not treat all regions as exchangeable."
    ),
    stringsAsFactors = FALSE
  )

  if (isTRUE(write_files)) {
    write.csv(demo, file.path(output_dir, "build_week_demo.csv"), row.names = FALSE, na = "")
    write.csv(truth, file.path(output_dir, "build_week_demo_ground_truth.csv"), row.names = FALSE, na = "")
  }

  list(data = demo, ground_truth = truth)
}

build_week_demo_data_path <- function() {
  candidates <- c(
    workstation_resource_path("data", "build_week_demo.csv", mustWork = FALSE),
    file.path("tests", "testthat", "data", "build_week_demo.csv"),
    file.path("data", "build_week_demo.csv")
  )
  found <- candidates[file.exists(candidates)]
  if (length(found)) normalizePath(found[[1]], winslash = "/", mustWork = FALSE) else candidates[[1]]
}

build_week_demo_ground_truth_path <- function() {
  candidates <- c(
    file.path("tests", "testthat", "data", "build_week_demo_ground_truth.csv"),
    file.path("data", "build_week_demo_ground_truth.csv")
  )
  found <- candidates[file.exists(candidates)]
  if (length(found)) normalizePath(found[[1]], winslash = "/", mustWork = FALSE) else candidates[[1]]
}

build_week_demo_dataset <- function(write_if_missing = FALSE) {
  path <- build_week_demo_data_path()
  if (!file.exists(path)) {
    generated <- generate_build_week_demo_data(write_files = isTRUE(write_if_missing))
    return(generated$data)
  }
  data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  data$week <- as.Date(data$week)
  data$region <- factor(data$region, levels = c("West", "Southwest", "Midwest", "Northeast"))
  data$audience <- factor(data$audience, levels = c("Career Changers", "Degree Seekers"))
  data$competitor_promo <- as.integer(data$competitor_promo)
  data
}

build_week_demo_signal_summary <- function(data = build_week_demo_dataset()) {
  data <- as.data.frame(data)
  data$search_k <- data$search_spend / 1000
  data$social_k <- data$social_spend / 1000
  data$delay_over_36 <- pmax(data$processing_delay_hours - 36, 0)
  data$fatigue_over_6 <- pmax(data$creative_age_weeks - 6, 0)

  model <- lm(
    enrollments ~ log1p(search_k) + I(log1p(search_k)^2) +
      social_k * audience + processing_delay_hours + delay_over_36 +
      I(delay_over_36^2) + fatigue_over_6 + I(fatigue_over_6^2) +
      competitor_promo + region,
    data = data
  )

  reference <- data[which.min(abs(data$processing_delay_hours - median(data$processing_delay_hours))), , drop = FALSE][1, ]
  pred <- function(row) as.numeric(predict(model, row))
  search_gain <- function(base_search) {
    a <- reference
    b <- reference
    a$search_spend <- base_search
    b$search_spend <- base_search + 10000
    a$search_k <- a$search_spend / 1000
    b$search_k <- b$search_spend / 1000
    pred(b) - pred(a)
  }
  social_gain <- function(audience_value) {
    a <- reference
    b <- reference
    a$audience <- factor(audience_value, levels = levels(data$audience))
    b$audience <- factor(audience_value, levels = levels(data$audience))
    a$social_spend <- 15000
    b$social_spend <- 25000
    a$social_k <- 15
    b$social_k <- 25
    pred(b) - pred(a)
  }
  delay_prediction <- function(hours) {
    z <- reference
    z$processing_delay_hours <- hours
    z$delay_over_36 <- pmax(hours - 36, 0)
    pred(z)
  }
  creative_prediction <- function(age) {
    z <- reference
    z$creative_age_weeks <- age
    z$fatigue_over_6 <- pmax(age - 6, 0)
    pred(z)
  }

  p30 <- delay_prediction(30)
  p36 <- delay_prediction(36)
  p45 <- delay_prediction(45)
  c4 <- creative_prediction(4)
  c6 <- creative_prediction(6)
  c10 <- creative_prediction(10)
  high_delay <- reference
  fixed_delay <- reference
  high_delay$processing_delay_hours <- 48
  high_delay$delay_over_36 <- 12
  fixed_delay$processing_delay_hours <- 30
  fixed_delay$delay_over_36 <- 0

  search_base <- reference
  search_cut <- reference
  search_base$search_spend <- 90000
  search_base$search_k <- 90
  search_cut$search_spend <- 75000
  search_cut$search_k <- 75

  list(
    model = model,
    search_low_gain = search_gain(20000),
    search_high_gain = search_gain(80000),
    search_low_efficiency = mean((data$enrollments / (data$search_spend / 1000))[data$search_spend <= as.numeric(stats::quantile(data$search_spend, 0.33))]),
    search_high_efficiency = mean((data$enrollments / (data$search_spend / 1000))[data$search_spend >= as.numeric(stats::quantile(data$search_spend, 0.66))]),
    social_career_gain = social_gain("Career Changers"),
    social_degree_gain = social_gain("Degree Seekers"),
    delay_30_to_36 = p36 - p30,
    delay_36_to_45 = p45 - p36,
    creative_4_to_6 = c6 - c4,
    creative_6_to_10 = c10 - c6,
    competitor_effect = unname(coef(model)["competitor_promo"]),
    delay_fix_gain = pred(fixed_delay) - pred(high_delay),
    search_cut_change = pred(search_cut) - pred(search_base),
    region_count = length(unique(data$region)),
    rows = nrow(data),
    columns = ncol(data)
  )
}

validate_build_week_demo_data <- function(data = build_week_demo_dataset(write_if_missing = TRUE), write_report = FALSE, output_dir = "validation_output") {
  expected_schema <- build_week_demo_schema()
  checks <- list()
  add <- function(check, status, message, metadata = list()) {
    checks[[length(checks) + 1L]] <<- data.table::data.table(check = check, status = status, message = message, metadata = list(metadata))
  }

  missing <- setdiff(expected_schema, names(data))
  add("schema", if (!length(missing) && identical(names(data), expected_schema)) "success" else "error", if (length(missing)) paste("Missing fields:", paste(missing, collapse = ", ")) else "Canonical schema present.")
  add("row_count", if (nrow(data) == 80L) "success" else "error", paste("Rows:", nrow(data)))
  add("no_missing_values", if (sum(is.na(data)) == 0L) "success" else "error", paste("Missing values:", sum(is.na(data))))
  add("realistic_ranges", if (
    min(data$search_spend) >= 10000 && max(data$search_spend) <= 90000 &&
      min(data$social_spend) >= 5000 && max(data$social_spend) <= 50000 &&
      min(data$processing_delay_hours) >= 14 && max(data$processing_delay_hours) <= 60 &&
      min(data$enrollments) > 0
  ) "success" else "error", "Spend, delay, and enrollment ranges remain realistic.")

  signals <- tryCatch(build_week_demo_signal_summary(data), error = function(e) e)
  if (inherits(signals, "error")) {
    add("recoverable_model", "error", conditionMessage(signals))
  } else {
    add("search_saturation", if (signals$search_low_efficiency > signals$search_high_efficiency * 1.25) "success" else "error", sprintf("Low-spend efficiency %.2f vs high-spend efficiency %.2f enrollments per $1k.", signals$search_low_efficiency, signals$search_high_efficiency))
    add("operational_threshold", if (signals$delay_36_to_45 < signals$delay_30_to_36 - 5) "success" else "error", sprintf("30->36 %.2f; 36->45 %.2f.", signals$delay_30_to_36, signals$delay_36_to_45))
    add("creative_fatigue", if (signals$creative_6_to_10 < -5 && abs(signals$creative_4_to_6) < 3) "success" else "error", sprintf("4->6 %.2f; 6->10 %.2f.", signals$creative_4_to_6, signals$creative_6_to_10))
    add("audience_interaction", if (signals$social_career_gain > signals$social_degree_gain + 2) "success" else "error", sprintf("Career %.2f; Degree %.2f.", signals$social_career_gain, signals$social_degree_gain))
    add("competitor_effect", if (is.finite(signals$competitor_effect) && signals$competitor_effect < -3) "success" else "error", sprintf("Competitor coefficient %.2f.", signals$competitor_effect))
    add("region_effects", if (signals$region_count == 4L && length(grep("^region", names(coef(signals$model)))) >= 3L) "success" else "error", paste("Regions:", signals$region_count))
    add("recommendation_stability", if (signals$delay_fix_gain > abs(signals$search_cut_change) + 8) "success" else "error", sprintf("Delay fix %.2f vs search cut %.2f.", signals$delay_fix_gain, signals$search_cut_change))
    add("signal_noise_balance", if (sd(data$enrollments) >= 8 && sd(residuals(signals$model)) > 1.5) "success" else "error", sprintf("Target SD %.2f; residual SD %.2f.", sd(data$enrollments), sd(residuals(signals$model))))
  }

  result <- data.table::rbindlist(checks, fill = TRUE)
  if (isTRUE(write_report)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    write.csv(result[, c("check", "status", "message"), with = FALSE], file.path(output_dir, "validation_metrics.csv"), row.names = FALSE)
  }
  service_result(
    status = if (any(result$status == "error")) "error" else "success",
    value = result,
    messages = paste(sum(result$status == "success"), "of", nrow(result), "dataset checks passed."),
    metadata = if (inherits(signals, "error")) list() else signals
  )
}
