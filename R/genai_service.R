genai_capabilities <- function(...) {
  requested <- unique(as.character(c(...)))
  all_capabilities <- c(
    "chat", "generate", "structured_json", "embeddings", "vision", "streaming",
    "tool_calling", "local", "remote", "free", "paid", "offline",
    "privacy_preserving"
  )
  stats::setNames(all_capabilities %in% requested, all_capabilities)
}

genai_provider_contract <- function(
  provider_id,
  display_name,
  default_base_url = NULL,
  default_model = NULL,
  capabilities = genai_capabilities(),
  adapter = list()
) {
  list(
    provider_id = provider_id,
    display_name = display_name,
    default_base_url = default_base_url,
    default_model = default_model,
    capabilities = capabilities,
    adapter = adapter
  )
}

genai_provider_registry <- function() {
  providers <- list()
  providers$none <- genai_provider_contract(
    "none",
    "No GenAI Provider",
    capabilities = genai_capabilities()
  )
  providers$mock <- genai_provider_contract(
    "mock",
    "Mock GenAI Provider",
    default_base_url = "mock://local",
    default_model = "mock-model",
    capabilities = genai_capabilities("chat", "generate", "structured_json", "vision", "local", "free", "offline", "privacy_preserving"),
    adapter = list(
      available = function(config) service_result(
        status = "success",
        value = TRUE,
        messages = "Mock GenAI provider is available.",
        metadata = list(provider = "mock", model = config$model %||% "mock-model")
      ),
      list_models = function(config) service_result(
        status = "success",
        value = data.table::data.table(model = config$model %||% "mock-model"),
        messages = "Mock model list returned."
      ),
      chat = function(messages, config, response_format = NULL) {
        prompt <- paste(vapply(messages, function(message) message$content %||% "", character(1)), collapse = "\n")
        genai_normalize_response(
          list(message = list(content = paste("Mock response:", substr(prompt, 1L, 240L)))),
          provider_id = "mock",
          model = config$model %||% "mock-model"
        )
      },
      generate = function(prompt, config, response_format = NULL, images = NULL) {
        genai_normalize_response(
          list(response = paste("Mock response:", substr(prompt %||% "", 1L, 240L), "| images:", length(images %||% character()))),
          provider_id = "mock",
          model = config$model %||% "mock-model"
        )
      }
    )
  )
  providers$ollama <- genai_provider_contract(
    "ollama",
    "Ollama",
    default_base_url = "http://127.0.0.1:11434",
    default_model = "llama3.1",
    capabilities = genai_capabilities("chat", "generate", "structured_json", "embeddings", "vision", "streaming", "local", "free", "offline", "privacy_preserving"),
    adapter = list(
      available = genai_ollama_available,
      list_models = genai_ollama_list_models,
      chat = genai_ollama_chat,
      generate = genai_ollama_generate
    )
  )
  providers$lm_studio <- genai_provider_contract(
    "lm_studio",
    "LM Studio",
    default_base_url = "http://127.0.0.1:1234/v1",
    capabilities = genai_capabilities("chat", "generate", "structured_json", "streaming", "local", "free", "offline", "privacy_preserving"),
    adapter = list(
      available = genai_openai_compatible_available,
      list_models = genai_openai_compatible_list_models,
      chat = genai_openai_compatible_chat
    )
  )
  providers$llama_cpp <- genai_provider_contract(
    "llama_cpp",
    "llama.cpp Server",
    default_base_url = "http://127.0.0.1:8080",
    capabilities = genai_capabilities("chat", "generate", "streaming", "local", "free", "offline", "privacy_preserving"),
    adapter = list(
      available = genai_llama_cpp_available,
      list_models = genai_stub_list_models,
      generate = genai_llama_cpp_generate
    )
  )
  providers$openai_compatible <- genai_provider_contract(
    "openai_compatible",
    "OpenAI-Compatible Endpoint",
    default_base_url = "http://127.0.0.1:1234/v1",
    capabilities = genai_capabilities("chat", "generate", "structured_json", "streaming", "local", "remote", "free", "paid"),
    adapter = list(
      available = genai_openai_compatible_available,
      list_models = genai_openai_compatible_list_models,
      chat = genai_openai_compatible_chat
    )
  )
  providers
}

genai_provider <- function(provider_id = NULL, registry = genai_provider_registry()) {
  provider_id <- provider_id %||% "none"
  registry[[provider_id]] %||% registry$none
}

genai_config <- function(
  provider = Sys.getenv("ANALYTICS_GENAI_PROVIDER", unset = "none"),
  base_url = Sys.getenv("ANALYTICS_GENAI_BASE_URL", unset = ""),
  model = Sys.getenv("ANALYTICS_GENAI_MODEL", unset = ""),
  temperature = as.numeric(Sys.getenv("ANALYTICS_GENAI_TEMPERATURE", unset = "0.2")),
  max_tokens = as.integer(Sys.getenv("ANALYTICS_GENAI_MAX_TOKENS", unset = "800")),
  timeout = as.integer(Sys.getenv("ANALYTICS_GENAI_TIMEOUT", unset = "20")),
  stream = identical(tolower(Sys.getenv("ANALYTICS_GENAI_STREAM", unset = "false")), "true"),
  vision_enabled = identical(tolower(Sys.getenv("ANALYTICS_GENAI_VISION_ENABLED", unset = "false")), "true"),
  max_image_bytes = as.integer(Sys.getenv("ANALYTICS_GENAI_MAX_IMAGE_BYTES", unset = "2500000")),
  max_image_count = as.integer(Sys.getenv("ANALYTICS_GENAI_MAX_IMAGE_COUNT", unset = "1"))
) {
  provider <- if (!nzchar(provider %||% "")) "none" else provider
  contract <- genai_provider(provider)
  list(
    provider = contract$provider_id,
    display_name = contract$display_name,
    base_url = if (nzchar(base_url %||% "")) base_url else contract$default_base_url,
    model = if (nzchar(model %||% "")) model else contract$default_model,
    temperature = temperature %||% 0.2,
    max_tokens = max_tokens %||% 800L,
    timeout = timeout %||% 20L,
    stream = isTRUE(stream),
    vision_enabled = isTRUE(vision_enabled),
    max_image_bytes = max_image_bytes %||% 2500000L,
    max_image_count = max_image_count %||% 1L
  )
}

genai_configured <- function(config = genai_config()) {
  !is.null(config$provider) && !identical(config$provider, "none")
}

genai_env_configured <- function() {
  provider <- Sys.getenv("ANALYTICS_GENAI_PROVIDER", unset = "")
  nzchar(provider)
}

genai_default_config <- function(auto_detect_local = TRUE) {
  if (genai_env_configured()) {
    config <- genai_config()
    config$config_source <- "environment"
    return(config)
  }

  if (isTRUE(auto_detect_local)) {
    ollama_config <- genai_config(provider = "ollama")
    availability <- tryCatch(
      genai_ollama_available(ollama_config),
      error = function(e) service_result(status = "warning", value = FALSE, warnings = conditionMessage(e), metadata = list(available = FALSE))
    )
    if (isTRUE(availability$value) || isTRUE(availability$metadata$available)) {
      models <- tryCatch(genai_ollama_list_models(ollama_config), error = function(e) NULL)
      if (is.list(models) && identical(models$status, "success") && data.table::is.data.table(models$value) && nrow(models$value)) {
        available_models <- models$value$model
        if (!ollama_config$model %in% available_models) {
          ollama_config$model <- available_models[[1]]
        }
      }
      ollama_config$config_source <- "auto_detect_ollama"
      return(ollama_config)
    }
  }

  config <- genai_config(provider = "none")
  config$config_source <- "default_none"
  config
}

genai_normalize_capabilities <- function(provider_or_capabilities) {
  capabilities <- if (is.list(provider_or_capabilities) && !is.null(provider_or_capabilities$capabilities)) {
    provider_or_capabilities$capabilities
  } else {
    provider_or_capabilities
  }
  normalized <- genai_capabilities(names(capabilities)[as.logical(capabilities)])
  normalized[names(capabilities)] <- as.logical(capabilities)
  normalized
}

genai_http_available <- function() {
  requireNamespace("httr2", quietly = TRUE) || requireNamespace("httr", quietly = TRUE)
}

genai_to_json <- function(x, auto_unbox = TRUE) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required to serialize GenAI provider requests.", call. = FALSE)
  }
  jsonlite::toJSON(x, auto_unbox = auto_unbox, null = "null", dataframe = "rows")
}

genai_from_json <- function(text) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required to parse GenAI provider responses.", call. = FALSE)
  }
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

genai_http_get_json <- function(url, timeout = 20L) {
  if (requireNamespace("httr2", quietly = TRUE)) {
    response <- httr2::request(url) |>
      httr2::req_timeout(timeout) |>
      httr2::req_perform()
    return(httr2::resp_body_json(response, simplifyVector = FALSE))
  }
  if (requireNamespace("httr", quietly = TRUE)) {
    response <- httr::GET(url, httr::timeout(timeout))
    httr::stop_for_status(response)
    return(genai_from_json(httr::content(response, as = "text", encoding = "UTF-8")))
  }
  stop("No HTTP client is available. Install httr2 or httr to call GenAI providers.", call. = FALSE)
}

genai_http_post_json <- function(url, body, timeout = 20L) {
  if (requireNamespace("httr2", quietly = TRUE)) {
    response <- httr2::request(url) |>
      httr2::req_timeout(timeout) |>
      httr2::req_body_json(body, auto_unbox = TRUE) |>
      httr2::req_perform()
    return(httr2::resp_body_json(response, simplifyVector = FALSE))
  }
  if (requireNamespace("httr", quietly = TRUE)) {
    response <- httr::POST(url, httr::timeout(timeout), body = genai_to_json(body), httr::content_type_json())
    httr::stop_for_status(response)
    return(genai_from_json(httr::content(response, as = "text", encoding = "UTF-8")))
  }
  stop("No HTTP client is available. Install httr2 or httr to call GenAI providers.", call. = FALSE)
}

genai_endpoint <- function(config, path) {
  base_url <- sub("/+$", "", config$base_url %||% "")
  paste0(base_url, path)
}

genai_ollama_chat_payload <- function(messages, config = genai_config(provider = "ollama"), response_format = NULL) {
  payload <- list(
    model = config$model %||% "llama3.1",
    messages = messages,
    stream = isTRUE(config$stream),
    options = list(
      temperature = config$temperature %||% 0.2,
      num_predict = config$max_tokens %||% 800L
    )
  )
  if (identical(response_format, "json")) {
    payload$format <- "json"
  }
  payload
}

genai_ollama_generate_payload <- function(prompt, config = genai_config(provider = "ollama"), response_format = NULL, images = NULL) {
  payload <- list(
    model = config$model %||% "llama3.1",
    prompt = prompt %||% "",
    stream = isTRUE(config$stream),
    options = list(
      temperature = config$temperature %||% 0.2,
      num_predict = config$max_tokens %||% 800L
    )
  )
  if (identical(response_format, "json")) {
    payload$format <- "json"
  }
  if (length(images %||% character())) {
    payload$images <- I(as.character(images))
  }
  payload
}

genai_normalize_response <- function(raw, provider_id = NULL, model = NULL) {
  text <- raw$message$content %||% raw$response %||% raw$choices[[1]]$message$content %||% raw$content %||% ""
  reported_input_tokens <- raw$prompt_eval_count %||% raw$usage$prompt_tokens %||% raw$timings$prompt_n %||% NA_integer_
  reported_output_tokens <- raw$eval_count %||% raw$usage$completion_tokens %||% raw$timings$predicted_n %||% NA_integer_
  service_result(
    status = "success",
    value = list(
      text = text,
      raw = raw
    ),
    messages = "GenAI provider returned a normalized response.",
    metadata = list(
      provider = provider_id,
      model = model,
      response_length = nchar(text %||% ""),
      reported_input_tokens = reported_input_tokens,
      reported_output_tokens = reported_output_tokens
    )
  )
}

genai_ollama_available <- function(config = genai_config(provider = "ollama")) {
  if (!genai_http_available()) {
    return(service_result(status = "warning", warnings = "No HTTP client is available. Install httr2 or httr to call Ollama.", metadata = list(provider = "ollama", available = FALSE)))
  }
  tryCatch({
    genai_http_get_json(genai_endpoint(config, "/api/tags"), timeout = min(config$timeout %||% 20L, 3L))
    service_result(status = "success", value = TRUE, messages = "Ollama is available.", metadata = list(provider = "ollama", available = TRUE))
  }, error = function(e) {
    service_result(status = "warning", value = FALSE, warnings = paste("Ollama unavailable:", conditionMessage(e)), metadata = list(provider = "ollama", available = FALSE))
  })
}

genai_ollama_list_models <- function(config = genai_config(provider = "ollama")) {
  tryCatch({
    raw <- genai_http_get_json(genai_endpoint(config, "/api/tags"), timeout = config$timeout %||% 20L)
    models <- raw$models %||% list()
    service_result(
      status = "success",
      value = data.table::rbindlist(lapply(models, function(model) data.table::data.table(model = model$name %||% "")), fill = TRUE),
      messages = "Ollama model list returned."
    )
  }, error = function(e) service_result(status = "warning", warnings = conditionMessage(e), metadata = list(provider = "ollama")))
}

genai_ollama_chat <- function(messages, config = genai_config(provider = "ollama"), response_format = NULL) {
  tryCatch({
    raw <- genai_http_post_json(
      genai_endpoint(config, "/api/chat"),
      genai_ollama_chat_payload(messages, config, response_format),
      timeout = config$timeout %||% 20L
    )
    genai_normalize_response(raw, provider_id = "ollama", model = config$model)
  }, error = function(e) service_result(status = "error", errors = conditionMessage(e), metadata = list(provider = "ollama", error_code = "GENAI_CHAT_FAILED")))
}

genai_ollama_generate <- function(prompt, config = genai_config(provider = "ollama"), response_format = NULL, images = NULL) {
  tryCatch({
    raw <- genai_http_post_json(
      genai_endpoint(config, "/api/generate"),
      genai_ollama_generate_payload(prompt, config, response_format, images = images),
      timeout = config$timeout %||% 20L
    )
    genai_normalize_response(raw, provider_id = "ollama", model = config$model)
  }, error = function(e) service_result(status = "error", errors = conditionMessage(e), metadata = list(provider = "ollama", error_code = "GENAI_GENERATE_FAILED")))
}

genai_openai_chat_payload <- function(messages, config = genai_config(provider = "openai_compatible"), response_format = NULL) {
  payload <- list(
    model = config$model %||% "local-model",
    messages = messages,
    temperature = config$temperature %||% 0.2,
    max_tokens = config$max_tokens %||% 800L,
    stream = isTRUE(config$stream)
  )
  if (identical(response_format, "json")) {
    payload$response_format <- list(type = "json_object")
  }
  payload
}

genai_openai_compatible_available <- function(config = genai_config(provider = "openai_compatible")) {
  if (!genai_http_available()) {
    return(service_result(status = "warning", warnings = "No HTTP client is available. Install httr2 or httr for OpenAI-compatible endpoints.", metadata = list(available = FALSE)))
  }
  tryCatch({
    genai_http_get_json(genai_endpoint(config, "/models"), timeout = min(config$timeout %||% 20L, 3L))
    service_result(status = "success", value = TRUE, messages = "OpenAI-compatible endpoint is available.", metadata = list(available = TRUE))
  }, error = function(e) service_result(status = "warning", value = FALSE, warnings = paste("Endpoint unavailable:", conditionMessage(e)), metadata = list(available = FALSE)))
}

genai_openai_compatible_list_models <- function(config = genai_config(provider = "openai_compatible")) {
  tryCatch({
    raw <- genai_http_get_json(genai_endpoint(config, "/models"), timeout = config$timeout %||% 20L)
    models <- raw$data %||% list()
    service_result(
      status = "success",
      value = data.table::rbindlist(lapply(models, function(model) data.table::data.table(model = model$id %||% "")), fill = TRUE),
      messages = "OpenAI-compatible model list returned."
    )
  }, error = function(e) service_result(status = "warning", warnings = conditionMessage(e)))
}

genai_openai_compatible_chat <- function(messages, config = genai_config(provider = "openai_compatible"), response_format = NULL) {
  tryCatch({
    raw <- genai_http_post_json(
      genai_endpoint(config, "/chat/completions"),
      genai_openai_chat_payload(messages, config, response_format),
      timeout = config$timeout %||% 20L
    )
    genai_normalize_response(raw, provider_id = config$provider, model = config$model)
  }, error = function(e) service_result(status = "error", errors = conditionMessage(e), metadata = list(provider = config$provider, error_code = "GENAI_CHAT_FAILED")))
}

genai_llama_cpp_available <- function(config = genai_config(provider = "llama_cpp")) {
  if (!genai_http_available()) {
    return(service_result(status = "warning", warnings = "No HTTP client is available. Install httr2 or httr for llama.cpp server.", metadata = list(provider = "llama_cpp", available = FALSE)))
  }
  tryCatch({
    genai_http_get_json(genai_endpoint(config, "/health"), timeout = min(config$timeout %||% 20L, 3L))
    service_result(status = "success", value = TRUE, messages = "llama.cpp server is available.", metadata = list(provider = "llama_cpp", available = TRUE))
  }, error = function(e) service_result(status = "warning", value = FALSE, warnings = paste("llama.cpp unavailable:", conditionMessage(e)), metadata = list(provider = "llama_cpp", available = FALSE)))
}

genai_llama_cpp_generate <- function(prompt, config = genai_config(provider = "llama_cpp"), response_format = NULL) {
  body <- list(prompt = prompt %||% "", temperature = config$temperature %||% 0.2, n_predict = config$max_tokens %||% 800L, stream = isTRUE(config$stream))
  tryCatch({
    raw <- genai_http_post_json(genai_endpoint(config, "/completion"), body, timeout = config$timeout %||% 20L)
    genai_normalize_response(raw, provider_id = "llama_cpp", model = config$model)
  }, error = function(e) service_result(status = "error", errors = conditionMessage(e), metadata = list(provider = "llama_cpp", error_code = "GENAI_GENERATE_FAILED")))
}

genai_stub_list_models <- function(config = genai_config()) {
  service_result(status = "warning", warnings = "Model listing is not implemented for this provider adapter.", metadata = list(provider = config$provider %||% "unknown"))
}

genai_provider_status <- function(config = genai_config(), check_availability = FALSE) {
  contract <- genai_provider(config$provider)
  capabilities <- genai_normalize_capabilities(contract)
  if (!genai_configured(config)) {
    return(service_result(
      status = "needs_input",
      value = list(available = FALSE, configured = FALSE, capabilities = capabilities),
      messages = "No GenAI provider configured. Set ANALYTICS_GENAI_PROVIDER=ollama or allow local auto-detection.",
      metadata = list(
        provider = "none",
        display_name = "No GenAI Provider",
        model = NA_character_,
        local = FALSE,
        privacy_preserving = FALSE,
        config_source = config$config_source %||% "default_none",
        diagnostic_reason = "not_configured"
      )
    ))
  }

  availability <- if (isTRUE(check_availability) && is.function(contract$adapter$available)) {
    contract$adapter$available(config)
  } else {
    service_result(status = "warning", value = NA, warnings = "Availability not checked.", metadata = list(available = NA))
  }
  available <- isTRUE(availability$value) || isTRUE(availability$metadata$available)
  availability_checked <- isTRUE(check_availability)
  diagnostic_reason <- if (!availability_checked) {
    "not_checked"
  } else if (!genai_http_available()) {
    "package_missing"
  } else if (isTRUE(available)) {
    "available"
  } else if (identical(contract$provider_id, "ollama")) {
    "endpoint_unreachable_or_ollama_not_running"
  } else {
    "endpoint_unreachable"
  }
  service_result(
    status = if (isTRUE(available)) "success" else availability$status,
    value = list(available = available, configured = TRUE, availability_checked = availability_checked, capabilities = capabilities),
    messages = availability$messages,
    warnings = availability$warnings,
    errors = availability$errors,
    metadata = list(
      provider = contract$provider_id,
      display_name = contract$display_name,
      base_url = config$base_url,
      model = config$model,
      local = isTRUE(capabilities[["local"]]),
      privacy_preserving = isTRUE(capabilities[["privacy_preserving"]]),
      config_source = config$config_source %||% if (genai_env_configured()) "environment" else "manual_or_default",
      diagnostic_reason = diagnostic_reason
    )
  )
}

genai_available <- function(provider = NULL, config = NULL) {
  config <- config %||% genai_config(provider = provider %||% Sys.getenv("ANALYTICS_GENAI_PROVIDER", unset = "none"))
  genai_provider_status(config, check_availability = TRUE)
}

genai_list_models <- function(provider = NULL, config = NULL) {
  config <- config %||% genai_config(provider = provider %||% Sys.getenv("ANALYTICS_GENAI_PROVIDER", unset = "none"))
  contract <- genai_provider(config$provider)
  if (!genai_configured(config)) {
    return(service_result(
      status = "needs_input",
      errors = "No GenAI provider is configured.",
      metadata = list(error_code = "GENAI_PROVIDER_NOT_CONFIGURED")
    ))
  }
  if (!is.function(contract$adapter$list_models)) {
    return(service_result(
      status = "warning",
      warnings = paste("Provider does not expose model listing:", contract$display_name),
      metadata = list(provider = contract$provider_id)
    ))
  }
  tryCatch(
    contract$adapter$list_models(config),
    error = function(e) service_result(
      status = "error",
      errors = conditionMessage(e),
      metadata = list(error_code = "GENAI_LIST_MODELS_FAILED", provider = contract$provider_id)
    )
  )
}

genai_provider_diagnostics <- function(config = genai_default_config(auto_detect_local = TRUE)) {
  required_packages <- c("httr2", "jsonlite", "curl", "httr", "mirai")
  required_available <- stats::setNames(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE), required_packages)
  detection_errors <- character()
  availability <- tryCatch(
    genai_provider_status(config, check_availability = TRUE),
    error = function(e) {
      detection_errors <<- c(detection_errors, conditionMessage(e))
      service_result(status = "error", value = list(available = FALSE, configured = genai_configured(config), capabilities = genai_capabilities()), errors = conditionMessage(e))
    }
  )
  ollama_config <- genai_config(provider = "ollama")
  ollama_availability <- tryCatch(
    genai_ollama_available(ollama_config),
    error = function(e) {
      detection_errors <<- c(detection_errors, paste("Ollama availability:", conditionMessage(e)))
      service_result(status = "warning", value = FALSE, warnings = conditionMessage(e), metadata = list(available = FALSE))
    }
  )
  ollama_models <- tryCatch(
    genai_ollama_list_models(ollama_config),
    error = function(e) {
      detection_errors <<- c(detection_errors, paste("Ollama models:", conditionMessage(e)))
      service_result(status = "warning", value = data.table::data.table(), warnings = conditionMessage(e))
    }
  )
  missing <- character()
  if (!genai_configured(config)) missing <- c(missing, "provider")
  if (genai_configured(config) && !nzchar(config$model %||% "")) missing <- c(missing, "model")
  if (genai_configured(config) && !nzchar(config$base_url %||% "")) missing <- c(missing, "base_url")
  capabilities <- availability$value$capabilities %||% genai_capabilities()
  service_result(
    status = if (identical(availability$status, "error")) "error" else if (genai_configured(config)) "success" else "needs_input",
    value = list(
      provider_configured = genai_configured(config),
      provider = config$provider %||% "none",
      model = config$model %||% NA_character_,
      base_url = config$base_url %||% NA_character_,
      availability = availability$value$available %||% FALSE,
      availability_status = availability$status,
      capabilities = capabilities,
      R.version.string = R.version.string,
      libPaths = .libPaths(),
      required_packages_available = required_available,
      ollama_reachable = isTRUE(ollama_availability$value) || isTRUE(ollama_availability$metadata$available),
      ollama_models = if (data.table::is.data.table(ollama_models$value)) ollama_models$value$model else character(),
      config_source = config$config_source %||% if (genai_env_configured()) "environment" else "manual_or_default",
      missing_config_fields = missing,
      detection_errors = detection_errors,
      env_vars = list(
        ANALYTICS_GENAI_PROVIDER = Sys.getenv("ANALYTICS_GENAI_PROVIDER", unset = NA_character_),
        ANALYTICS_GENAI_BASE_URL = Sys.getenv("ANALYTICS_GENAI_BASE_URL", unset = NA_character_),
        ANALYTICS_GENAI_MODEL = Sys.getenv("ANALYTICS_GENAI_MODEL", unset = NA_character_)
      )
    ),
    messages = c(
      paste("Provider:", config$provider %||% "none"),
      paste("Model:", config$model %||% "not configured"),
      paste("Config source:", config$config_source %||% "unknown")
    ),
    warnings = c(availability$warnings %||% character(), ollama_availability$warnings %||% character(), ollama_models$warnings %||% character()),
    errors = availability$errors %||% character(),
    metadata = list(
      provider = config$provider %||% "none",
      model = config$model %||% NA_character_,
      base_url = config$base_url %||% NA_character_,
      config_source = config$config_source %||% "unknown",
      diagnostic_reason = availability$metadata$diagnostic_reason %||% NA_character_
    )
  )
}

genai_chat <- function(messages, config = genai_config(), response_format = NULL) {
  contract <- genai_provider(config$provider)
  if (!genai_configured(config)) {
    return(service_result(status = "needs_input", errors = "No GenAI provider is configured.", metadata = list(error_code = "GENAI_PROVIDER_NOT_CONFIGURED")))
  }
  if (!isTRUE(contract$capabilities[["chat"]]) || !is.function(contract$adapter$chat)) {
    return(service_result(status = "error", errors = paste("Provider does not support chat:", contract$display_name), metadata = list(error_code = "GENAI_CHAT_UNSUPPORTED", provider = contract$provider_id)))
  }
  tryCatch(
    contract$adapter$chat(messages = messages, config = config, response_format = response_format),
    error = function(e) service_result(status = "error", errors = conditionMessage(e), metadata = list(error_code = "GENAI_CHAT_FAILED", provider = contract$provider_id))
  )
}

genai_generate <- function(prompt, config = genai_config(), response_format = NULL, images = NULL) {
  contract <- genai_provider(config$provider)
  if (!genai_configured(config)) {
    return(service_result(status = "needs_input", errors = "No GenAI provider is configured.", metadata = list(error_code = "GENAI_PROVIDER_NOT_CONFIGURED")))
  }
  if (is.function(contract$adapter$generate)) {
    return(tryCatch(
      contract$adapter$generate(prompt = prompt, config = config, response_format = response_format, images = images),
      error = function(e) service_result(status = "error", errors = conditionMessage(e), metadata = list(error_code = "GENAI_GENERATE_FAILED", provider = contract$provider_id))
    ))
  }
  genai_chat(list(list(role = "user", content = prompt)), config = config, response_format = response_format)
}

genai_context_components <- function(...) {
  requested <- unique(as.character(c(...)))
  all_components <- c(
    "screenshot", "caption", "metadata", "diagnostics", "recommendations",
    "table_preview", "full_table", "json_summary", "sidecar_reference"
  )
  stats::setNames(all_components %in% requested, all_components)
}

genai_context_strategy_registry <- function() {
  list(
    screenshot_only = list(
      context_strategy = "screenshot_only",
      label = "Screenshot Only",
      included_components = genai_context_components("screenshot"),
      purpose = "Test whether visual evidence alone is enough for artifact interpretation."
    ),
    caption_metadata = list(
      context_strategy = "caption_metadata",
      label = "Caption + Metadata Only",
      included_components = genai_context_components("caption", "metadata"),
      purpose = "Low-token semantic summary without visual or table payloads."
    ),
    screenshot_caption = list(
      context_strategy = "screenshot_caption",
      label = "Screenshot + Caption",
      included_components = genai_context_components("screenshot", "caption"),
      purpose = "Visual evidence plus concise semantic label."
    ),
    table_preview_only = list(
      context_strategy = "table_preview_only",
      label = "Table Preview Only",
      included_components = genai_context_components("table_preview"),
      purpose = "Compact tabular evidence for table artifacts."
    ),
    full_table = list(
      context_strategy = "full_table",
      label = "Full Table",
      included_components = genai_context_components("full_table"),
      purpose = "High-cost complete tabular context for controlled experiments."
    ),
    screenshot_caption_preview = list(
      context_strategy = "screenshot_caption_preview",
      label = "Screenshot + Caption + Preview Table",
      included_components = genai_context_components("screenshot", "caption", "table_preview"),
      purpose = "Hybrid visual and compact structured context."
    ),
    structured_json_summary = list(
      context_strategy = "structured_json_summary",
      label = "Structured JSON Summary",
      included_components = genai_context_components("json_summary", "metadata", "diagnostics", "recommendations", "sidecar_reference"),
      purpose = "Machine-readable project/artifact summary with sidecar references."
    ),
    balanced = list(
      context_strategy = "balanced",
      label = "Balanced",
      included_components = genai_context_components("caption", "metadata", "diagnostics", "recommendations", "table_preview", "json_summary", "sidecar_reference"),
      purpose = "Default balanced context for read-only assistance."
    )
  )
}

genai_context_strategy <- function(strategy = "balanced") {
  registry <- genai_context_strategy_registry()
  registry[[strategy]] %||% registry$balanced
}

genai_strategy_requests_image_payload <- function(strategy) {
  strategy %in% c("screenshot_only", "screenshot_caption", "screenshot_caption_preview")
}

genai_model_looks_vision_capable <- function(config = genai_config()) {
  model <- tolower(config$model %||% "")
  if (identical(config$provider, "mock") && isTRUE(config$vision_enabled)) {
    return(TRUE)
  }
  grepl("vision|llava|bakllava|minicpm|moondream|qwen2[-_.:]?vl|qwen[-_.:]?vl|pixtral|gemma3", model)
}

genai_image_format <- function(path) {
  ext <- tolower(tools::file_ext(path %||% ""))
  if (ext %in% c("jpg", "jpeg")) "jpeg" else if (ext %in% c("webp", "png")) ext else ext %||% ""
}

genai_base64_image <- function(path, max_image_bytes = 2500000L) {
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    return(list(status = "error", payload = NULL, bytes = 0L, format = NA_character_, reason = "missing_image_file"))
  }
  info <- file.info(path)
  bytes <- as.integer(info$size %||% 0L)
  if (is.na(bytes) || bytes <= 0L) {
    return(list(status = "error", payload = NULL, bytes = 0L, format = genai_image_format(path), reason = "empty_image_file"))
  }
  if (bytes > max_image_bytes) {
    return(list(status = "warning", payload = NULL, bytes = bytes, format = genai_image_format(path), reason = "image_exceeds_max_bytes"))
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    return(list(status = "error", payload = NULL, bytes = bytes, format = genai_image_format(path), reason = "jsonlite_unavailable_for_base64"))
  }
  raw <- readBin(path, what = "raw", n = bytes)
  list(status = "success", payload = jsonlite::base64_enc(raw), bytes = bytes, format = genai_image_format(path), reason = "")
}

genai_vision_payload <- function(artifact, strategy, config = genai_config()) {
  provider <- genai_provider(config$provider)
  requests_image <- genai_strategy_requests_image_payload(strategy)
  declared <- isTRUE(provider$capabilities[["vision"]])
  detected <- genai_model_looks_vision_capable(config)
  verified <- isTRUE(config$vision_enabled) && declared && detected
  metadata <- artifact$metadata %||% list()
  screenshot_path <- metadata$screenshot_path %||% metadata$thumbnail_path %||% NULL
  telemetry <- list(
    image_payload_used = FALSE,
    image_payload_count = 0L,
    image_payload_bytes = 0L,
    image_payload_format = NA_character_,
    image_reference_only = FALSE,
    vision_model_detected = detected,
    vision_capability_declared = declared,
    vision_capability_verified = verified,
    vision_downgrade_reason = NA_character_
  )
  if (!requests_image) {
    telemetry$vision_downgrade_reason <- "strategy_does_not_request_image_payload"
    return(list(images = NULL, telemetry = telemetry))
  }
  if (!isTRUE(verified)) {
    telemetry$image_reference_only <- !is.null(screenshot_path) && nzchar(screenshot_path %||% "")
    telemetry$vision_downgrade_reason <- if (!isTRUE(config$vision_enabled)) {
      "vision_disabled_in_config"
    } else if (!declared) {
      "provider_does_not_declare_vision"
    } else {
      "selected_model_not_detected_as_vision_capable"
    }
    return(list(images = NULL, telemetry = telemetry))
  }
  encoded <- genai_base64_image(screenshot_path, max_image_bytes = config$max_image_bytes %||% 2500000L)
  if (!identical(encoded$status, "success")) {
    telemetry$image_reference_only <- !is.null(screenshot_path) && nzchar(screenshot_path %||% "")
    telemetry$image_payload_bytes <- encoded$bytes
    telemetry$image_payload_format <- encoded$format
    telemetry$vision_downgrade_reason <- encoded$reason
    return(list(images = NULL, telemetry = telemetry))
  }
  telemetry$image_payload_used <- TRUE
  telemetry$image_payload_count <- 1L
  telemetry$image_payload_bytes <- encoded$bytes
  telemetry$image_payload_format <- encoded$format
  telemetry$image_reference_only <- FALSE
  telemetry$vision_downgrade_reason <- ""
  list(images = list(encoded$payload), telemetry = telemetry)
}

genai_estimate_tokens <- function(text) {
  text <- paste(as.character(text %||% ""), collapse = "\n")
  if (!nzchar(text)) {
    return(0L)
  }
  as.integer(ceiling(nchar(text, type = "chars") / 4))
}

genai_table_preview <- function(table, max_rows = 12L, max_cols = 8L) {
  if (is.null(table)) {
    return(NULL)
  }
  data <- tryCatch(data.table::as.data.table(table), error = function(e) NULL)
  if (is.null(data)) {
    return(NULL)
  }
  data <- data[seq_len(min(nrow(data), max_rows))]
  keep_cols <- utils::head(names(data), max_cols)
  data[, ..keep_cols]
}

genai_build_artifact_context <- function(artifact, strategy = "balanced") {
  spec <- genai_context_strategy(strategy)
  components <- spec$included_components
  base <- genai_artifact_context(artifact)
  metadata <- artifact$metadata %||% list()
  context <- list(
    context_strategy = spec$context_strategy,
    artifact_id = base$artifact_id,
    artifact_type = base$type
  )
  if (isTRUE(components[["caption"]])) {
    context$caption <- base$caption
    context$title <- base$title
  }
  if (isTRUE(components[["metadata"]])) {
    context$metadata <- base[c("artifact_id", "title", "module", "section", "type", "intent", "importance")]
  }
  if (isTRUE(components[["diagnostics"]])) {
    context$diagnostics <- base$diagnostics
  }
  if (isTRUE(components[["recommendations"]])) {
    context$recommendations <- base$recommendations
  }
  if (isTRUE(components[["screenshot"]])) {
    context$screenshot <- base$sidecars$screenshot %||% metadata$screenshot_path %||% metadata$thumbnail_path %||% NULL
  }
  table_data <- artifact$table %||% artifact$data %||% artifact$value$table %||% metadata$table_preview %||% NULL
  if (isTRUE(components[["table_preview"]])) {
    context$table_preview <- genai_table_preview(table_data)
  }
  if (isTRUE(components[["full_table"]])) {
    context$full_table <- table_data
  }
  if (isTRUE(components[["json_summary"]])) {
    context$json_summary <- list(
      label = base$title,
      module = base$module,
      section = base$section,
      type = base$type,
      quality = metadata$quality %||% metadata$artifact_completeness %||% NULL
    )
  }
  if (isTRUE(components[["sidecar_reference"]])) {
    context$sidecar_reference <- base$sidecars
  }
  attr(context, "included_components") <- components
  context
}

genai_build_project_context <- function(ctx, strategy = "balanced", max_artifacts = 30L) {
  spec <- genai_context_strategy(strategy)
  components <- spec$included_components
  base <- genai_project_context(ctx, max_artifacts = max_artifacts)
  artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
  reports <- tryCatch(repair_report_plan_collection(ctx$report_plan_state$plans %||% list()), error = function(e) list())
  dataset_resolution <- tryCatch(genai_resolve_dataset(genai_dataset_id(ctx), ctx = ctx), error = function(e) NULL)
  context <- list(
    context_strategy = spec$context_strategy,
    data = base$data,
    artifact_count = base$artifact_count,
    collector = base$collector
  )
  if (!is.null(dataset_resolution)) {
    context$trusted_dataset <- list(
      dataset_id = dataset_resolution$value$dataset_id,
      display_name = dataset_resolution$value$display_name,
      active_project_id = dataset_resolution$value$active_project_id,
      dataset_version = dataset_resolution$value$dataset_version,
      schema_version = dataset_resolution$value$schema_version,
      availability = dataset_resolution$value$availability,
      row_count = dataset_resolution$value$row_count,
      column_count = dataset_resolution$value$column_count
    )
  }
  context$registered_modules <- lapply(get_module_registry(), function(module) {
    list(
      module_id = module$module_id,
      display_name = module$label,
      module_category = module$category,
      module_status = module$status,
      preflight_supported = genai_module_preflight_supported(module)
    )
  })
  context$artifacts <- lapply(utils::head(artifacts, max_artifacts), function(artifact) {
    genai_build_artifact_context(artifact, strategy = strategy)
  })
  context$reports <- lapply(reports, function(report) {
    metadata <- report$metadata %||% list()
    list(
      report_id = report$plan_id,
      display_name = report$label %||% report$plan_id,
      report_type = report$layout_type %||% "sections",
      report_status = report$status %||% "draft",
      render_status = metadata$render_status %||% metadata$preview_status %||% "preview_available",
      brief_relevance = report$description %||% paste("Curated report plan from", report$source_module %||% "unknown module"),
      evidence_refs = paste(report_plan_artifact_ids(report), collapse = ", ")
    )
  })
  if (!isTRUE(components[["full_table"]])) {
    context$note <- "Full raw data and full tables are omitted by default."
  }
  attr(context, "included_components") <- components
  context
}

genai_telemetry_record <- function(
  call_type,
  context_strategy,
  included_components,
  estimated_input_tokens,
  reported_input_tokens = NA_integer_,
  estimated_output_tokens = NA_integer_,
  reported_output_tokens = NA_integer_,
  latency_ms = NA_real_,
  provider = NA_character_,
  model = NA_character_,
  status = NA_character_,
  output_quality_score = NA_real_,
  accuracy_score = NA_real_,
  user_rating = NA_real_,
  image_payload_used = FALSE,
  image_payload_count = 0L,
  image_payload_bytes = 0L,
  image_payload_format = NA_character_,
  image_reference_only = FALSE,
  vision_model_detected = FALSE,
  vision_capability_declared = FALSE,
  vision_capability_verified = FALSE,
  vision_downgrade_reason = NA_character_
) {
  list(
    telemetry_id = paste0("genai_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(99999L, 1L)),
    timestamp = Sys.time(),
    call_type = call_type,
    context_strategy = context_strategy,
    included_components = as.list(as.logical(included_components)),
    estimated_input_tokens = as.integer(estimated_input_tokens %||% NA_integer_),
    reported_input_tokens = suppressWarnings(as.integer(reported_input_tokens %||% NA_integer_)),
    estimated_output_tokens = suppressWarnings(as.integer(estimated_output_tokens %||% NA_integer_)),
    reported_output_tokens = suppressWarnings(as.integer(reported_output_tokens %||% NA_integer_)),
    total_estimated_tokens = suppressWarnings(as.integer((estimated_input_tokens %||% 0L) + (estimated_output_tokens %||% 0L))),
    latency_ms = suppressWarnings(as.numeric(latency_ms %||% NA_real_)),
    provider = provider %||% NA_character_,
    model = model %||% NA_character_,
    status = status %||% NA_character_,
    output_quality_score = output_quality_score,
    accuracy_score = accuracy_score,
    user_rating = user_rating,
    image_payload_used = isTRUE(image_payload_used),
    image_payload_count = suppressWarnings(as.integer(image_payload_count %||% 0L)),
    image_payload_bytes = suppressWarnings(as.integer(image_payload_bytes %||% 0L)),
    image_payload_format = image_payload_format %||% NA_character_,
    image_reference_only = isTRUE(image_reference_only),
    vision_model_detected = isTRUE(vision_model_detected),
    vision_capability_declared = isTRUE(vision_capability_declared),
    vision_capability_verified = isTRUE(vision_capability_verified),
    vision_downgrade_reason = vision_downgrade_reason %||% NA_character_
  )
}

genai_attach_telemetry <- function(result, telemetry) {
  result$metadata$telemetry <- telemetry
  result$metadata$context_strategy <- telemetry$context_strategy
  result$metadata$included_components <- telemetry$included_components
  result$metadata$estimated_input_tokens <- telemetry$estimated_input_tokens
  result$metadata$reported_input_tokens <- telemetry$reported_input_tokens
  result$metadata$estimated_output_tokens <- telemetry$estimated_output_tokens
  result$metadata$reported_output_tokens <- telemetry$reported_output_tokens
  result$metadata$total_estimated_tokens <- telemetry$total_estimated_tokens
  result$metadata$latency_ms <- telemetry$latency_ms
  result$metadata$output_quality_score <- telemetry$output_quality_score
  result$metadata$accuracy_score <- telemetry$accuracy_score
  result$metadata$user_rating <- telemetry$user_rating
  result$metadata$image_payload_used <- telemetry$image_payload_used
  result$metadata$image_payload_count <- telemetry$image_payload_count
  result$metadata$image_payload_bytes <- telemetry$image_payload_bytes
  result$metadata$image_payload_format <- telemetry$image_payload_format
  result$metadata$image_reference_only <- telemetry$image_reference_only
  result$metadata$vision_model_detected <- telemetry$vision_model_detected
  result$metadata$vision_capability_declared <- telemetry$vision_capability_declared
  result$metadata$vision_capability_verified <- telemetry$vision_capability_verified
  result$metadata$vision_downgrade_reason <- telemetry$vision_downgrade_reason
  result
}

genai_generate_with_telemetry <- function(
  prompt,
  config = genai_config(),
  response_format = NULL,
  context_strategy = "balanced",
  included_components = genai_context_strategy(context_strategy)$included_components,
  call_type = "generate",
  images = NULL,
  image_telemetry = list()
) {
  start <- proc.time()[["elapsed"]]
  estimated_tokens <- genai_estimate_tokens(prompt)
  result <- genai_generate(prompt, config = config, response_format = response_format, images = images)
  latency_ms <- round((proc.time()[["elapsed"]] - start) * 1000, 1)
  estimated_output_tokens <- genai_estimate_tokens(result$value$text %||% "")
  telemetry <- genai_telemetry_record(
    call_type = call_type,
    context_strategy = context_strategy,
    included_components = included_components,
    estimated_input_tokens = estimated_tokens,
    reported_input_tokens = result$metadata$reported_input_tokens %||% NA_integer_,
    estimated_output_tokens = estimated_output_tokens,
    reported_output_tokens = result$metadata$reported_output_tokens %||% NA_integer_,
    latency_ms = latency_ms,
    provider = result$metadata$provider %||% config$provider,
    model = result$metadata$model %||% config$model,
    status = result$status,
    image_payload_used = image_telemetry$image_payload_used %||% FALSE,
    image_payload_count = image_telemetry$image_payload_count %||% 0L,
    image_payload_bytes = image_telemetry$image_payload_bytes %||% 0L,
    image_payload_format = image_telemetry$image_payload_format %||% NA_character_,
    image_reference_only = image_telemetry$image_reference_only %||% FALSE,
    vision_model_detected = image_telemetry$vision_model_detected %||% FALSE,
    vision_capability_declared = image_telemetry$vision_capability_declared %||% FALSE,
    vision_capability_verified = image_telemetry$vision_capability_verified %||% FALSE,
    vision_downgrade_reason = image_telemetry$vision_downgrade_reason %||% NA_character_
  )
  genai_attach_telemetry(result, telemetry)
}

genai_chat_with_telemetry <- function(
  messages,
  config = genai_config(),
  response_format = NULL,
  context_strategy = "balanced",
  included_components = genai_context_strategy(context_strategy)$included_components,
  call_type = "chat"
) {
  prompt_text <- paste(vapply(messages, function(message) message$content %||% "", character(1)), collapse = "\n")
  start <- proc.time()[["elapsed"]]
  result <- genai_chat(messages, config = config, response_format = response_format)
  latency_ms <- round((proc.time()[["elapsed"]] - start) * 1000, 1)
  estimated_output_tokens <- genai_estimate_tokens(result$value$text %||% "")
  telemetry <- genai_telemetry_record(
    call_type = call_type,
    context_strategy = context_strategy,
    included_components = included_components,
    estimated_input_tokens = genai_estimate_tokens(prompt_text),
    reported_input_tokens = result$metadata$reported_input_tokens %||% NA_integer_,
    estimated_output_tokens = estimated_output_tokens,
    reported_output_tokens = result$metadata$reported_output_tokens %||% NA_integer_,
    latency_ms = latency_ms,
    provider = result$metadata$provider %||% config$provider,
    model = result$metadata$model %||% config$model,
    status = result$status
  )
  genai_attach_telemetry(result, telemetry)
}

genai_artifact_context <- function(artifact) {
  if (is.null(artifact)) {
    return(list())
  }
  metadata <- artifact$metadata %||% list()
  list(
    artifact_id = artifact$artifact_id %||% "",
    title = artifact$label %||% artifact$artifact_id %||% "",
    module = artifact$source_module %||% "",
    section = artifact$section %||% "",
    type = artifact$artifact_type %||% "",
    caption = metadata$caption %||% artifact_caption(artifact, "llm_docx"),
    intent = metadata$analytical_intent %||% "",
    importance = metadata$artifact_importance %||% "",
    diagnostics = utils::head(as.character(metadata$diagnostics %||% metadata$warnings %||% character()), 12L),
    recommendations = utils::head(as.character(metadata$recommendations %||% character()), 12L),
    sidecars = list(
      csv = metadata$csv_path %||% metadata$table_csv_path %||% NULL,
      json = metadata$json_path %||% metadata$table_json_path %||% NULL,
      screenshot = metadata$screenshot_path %||% metadata$thumbnail_path %||% NULL
    )
  )
}

genai_project_context <- function(ctx, max_artifacts = 30L) {
  artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
  collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
  data_info <- tryCatch(ctx$project_data_info(), error = function(e) list(path = NULL, name = NULL))
  artifact_rows <- lapply(utils::head(artifacts, max_artifacts), genai_artifact_context)
  list(
    data = list(name = data_info$name %||% "", path = data_info$path %||% ""),
    artifact_count = length(artifacts),
    collector = if (nrow(collector)) as.list(collector[1]) else list(status = "not_created"),
    artifacts = artifact_rows
  )
}

genai_context_json <- function(context) {
  tryCatch(genai_to_json(context), error = function(e) paste(capture.output(str(context, max.level = 3)), collapse = "\n"))
}

genai_summarize_artifact <- function(artifact, config = genai_config(), context_strategy = "balanced") {
  context <- genai_build_artifact_context(artifact, strategy = context_strategy)
  included_components <- attr(context, "included_components") %||% genai_context_strategy(context_strategy)$included_components
  prompt <- paste(
    "Summarize this Analytics Workstation artifact for an analyst.",
    "Use the available metadata only. Do not invent data values.",
    "Return concise sections: What this is, Why it matters, Trust/quality caveats, Suggested next action.",
    genai_context_json(context),
    sep = "\n\n"
  )
  genai_generate_with_telemetry(
    prompt,
    config = config,
    context_strategy = context_strategy,
    included_components = included_components,
    call_type = "summarize_artifact"
  )
}

genai_brief_project <- function(ctx, config = genai_config(), context_strategy = "balanced") {
  context <- genai_build_project_context(ctx, strategy = context_strategy)
  included_components <- attr(context, "included_components") %||% genai_context_strategy(context_strategy)$included_components
  prompt <- paste(
    "Brief the current Analytics Workstation project from metadata, collector summary, artifact captions, diagnostics, and recommendations.",
    "Do not request or infer full raw data. Keep it concise and decision-oriented.",
    genai_context_json(context),
    sep = "\n\n"
  )
  genai_generate_with_telemetry(
    prompt,
    config = config,
    context_strategy = context_strategy,
    included_components = included_components,
    call_type = "brief_project"
  )
}

genai_explain_alerts <- function(alerts, config = genai_config(), context_strategy = "structured_json_summary") {
  included_components <- genai_context_strategy(context_strategy)$included_components
  prompt <- paste(
    "Explain these Mission Control alerts for an analyst. Clarify why each matters and what to inspect next. Do not execute actions.",
    genai_context_json(alerts),
    sep = "\n\n"
  )
  result <- genai_generate_with_telemetry(
    prompt,
    config = config,
    context_strategy = context_strategy,
    included_components = included_components,
    call_type = "explain_alerts"
  )
  genai_attach_action_proposal(result)
}

genai_suggest_next_action <- function(ctx, config = genai_config(), context_strategy = "balanced") {
  context <- genai_build_project_context(ctx, strategy = context_strategy)
  included_components <- attr(context, "included_components") %||% genai_context_strategy(context_strategy)$included_components
  prompt <- paste(
    "Suggest the next analytical action for this project using only project metadata, collector status, artifact quality, diagnostics, and recommendations.",
    "Do not execute anything. Provide one recommended next step and two alternatives.",
    "If and only if opening a registered module, inspecting one listed artifact, opening one listed existing report, or running a bounded preflight on the trusted active dataset is the single safest next step, you may include one JSON action proposal in a fenced ```json block under key action_proposal.",
    "Supported action_ids are module.open, artifact.inspect, report.open, and analysis.preflight. module.open arguments may contain only module_id. artifact.inspect arguments may contain only artifact_id from the listed artifact metadata. report.open arguments may contain only report_id from the listed report metadata. analysis.preflight arguments may contain only module_id from registered_modules and dataset_id from trusted_dataset.",
    "Do not invent artifact ids, report ids, dataset ids, filesystem locations, URLs, project ids, callbacks, function names, target variables, predictor lists, formulas, sampling sizes, timeouts, rendering parameters, persistence, state mutations, code execution, report generation, report rendering, artifact saving, or chained actions.",
    genai_context_json(context),
    sep = "\n\n"
  )
  result <- genai_generate_with_telemetry(
    prompt,
    config = config,
    context_strategy = context_strategy,
    included_components = included_components,
    call_type = "suggest_next_action"
  )
  genai_attach_action_proposal(result)
}

genai_question_registry <- function() {
  list(
    summarize = "Summarize the main analytical takeaways.",
    limitations = "What limitations or caveats should be considered when interpreting this artifact?",
    key_findings = "What are the key analytical findings from this artifact?",
    next_action = "What should be investigated next?",
    exact_values = "Report exact values where possible and explain uncertainty.",
    production_risk = "Would this artifact raise any concern for production use?",
    explain_for_executive = "Explain this artifact for an executive audience in concise business language.",
    explain_for_data_scientist = "Explain this artifact for a data scientist, including methodological caveats.",
    identify_risks = "Identify analytical, data quality, modeling, or interpretation risks visible in this artifact.",
    suggest_next_action = "Suggest the next analytical action based on this artifact."
  )
}

genai_question_prompt <- function(question_type = "summarize") {
  registry <- genai_question_registry()
  registry[[question_type]] %||% registry$summarize
}

genai_experiment_id <- function(prefix = "genai_experiment") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
}

genai_load_experiment_project <- function(project) {
  if (is.character(project) && length(project) == 1L) {
    return(readRDS(normalize_project_load_path(project)))
  }
  project
}

genai_project_artifacts <- function(project) {
  artifacts <- project$module_artifacts %||% project$artifacts %||% list()
  if (!is.list(artifacts)) list() else artifacts
}

genai_project_collector_artifact_dir <- function(project, project_path = NULL) {
  collector <- project$project_collector %||% data.table::data.table()
  if (data.table::is.data.table(collector) && nrow(collector) && "artifact_directory" %in% names(collector)) {
    path <- collector$artifact_directory[[1]]
    if (nzchar(path %||% "")) return(path)
  }
  if (is.list(collector) && !is.null(collector$artifact_directory)) {
    path <- collector$artifact_directory[[1]]
    if (nzchar(path %||% "")) return(path)
  }
  if (!is.null(project_path)) {
    return(file.path(dirname(normalize_project_load_path(project_path)), "project_artifact_collector", "artifacts"))
  }
  NULL
}

genai_find_artifact_sidecar <- function(artifact, collector_artifact_dir = NULL, ext = "csv") {
  artifact_id <- artifact$artifact_id %||% ""
  if (!nzchar(artifact_id) || is.null(collector_artifact_dir) || !dir.exists(collector_artifact_dir)) {
    return(NULL)
  }
  candidates <- list.files(
    collector_artifact_dir,
    pattern = paste0("\\.", ext, "$"),
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )
  matches <- candidates[grepl(artifact_id, basename(candidates), fixed = TRUE)]
  if (length(matches)) matches[[1]] else NULL
}

genai_prepare_experiment_artifact <- function(artifact, collector_artifact_dir = NULL, max_table_rows_to_load = 1000L) {
  metadata <- artifact$metadata %||% list()
  csv_path <- metadata$table_csv_path %||% metadata$csv_path %||% genai_find_artifact_sidecar(artifact, collector_artifact_dir, "csv")
  json_path <- metadata$table_json_path %||% metadata$json_path %||% genai_find_artifact_sidecar(artifact, collector_artifact_dir, "json")
  screenshot_path <- metadata$screenshot_path %||% metadata$thumbnail_path %||% genai_find_artifact_sidecar(artifact, collector_artifact_dir, "png")
  artifact$metadata <- metadata
  artifact$metadata$table_csv_path <- csv_path
  artifact$metadata$table_json_path <- json_path
  artifact$metadata$screenshot_path <- screenshot_path
  if (is.null(artifact$table) && !is.null(csv_path) && file.exists(csv_path) && requireNamespace("data.table", quietly = TRUE)) {
    table_data <- tryCatch(data.table::fread(csv_path, nrows = max_table_rows_to_load), error = function(e) NULL)
    if (!is.null(table_data)) {
      artifact$table <- table_data
      artifact$metadata$table_rows_loaded <- nrow(table_data)
      artifact$metadata$table_load_capped <- nrow(table_data) >= max_table_rows_to_load
    }
  }
  artifact
}

genai_artifact_table_dimensions <- function(artifact) {
  table_data <- artifact$table %||% artifact$data %||% artifact$value$table %||% artifact$metadata$table_preview %||% NULL
  if (is.null(table_data)) {
    return(list(rows = NA_integer_, columns = NA_integer_))
  }
  frame <- as.data.frame(table_data)
  list(rows = nrow(frame), columns = ncol(frame))
}

genai_infer_artifact_family <- function(artifact) {
  metadata <- artifact$metadata %||% list()
  explicit <- metadata$artifact_family %||% metadata$plot_family %||% metadata$table_family %||% NULL
  if (!is.null(explicit) && nzchar(explicit)) {
    return(list(artifact_family = explicit, policy_source = "explicit"))
  }
  text <- tolower(paste(
    artifact$artifact_id %||% "",
    artifact$artifact_type %||% artifact$type %||% "",
    artifact$label %||% artifact$title %||% "",
    artifact$source_module %||% "",
    artifact$section %||% "",
    metadata$analytical_intent %||% "",
    collapse = " "
  ))
  family <- if (grepl("shap.*effect|effect:", text)) {
    "shap_dependence"
  } else if (grepl("shap.*importance|global shap|importance", text)) {
    "shap_importance"
  } else if (grepl("interaction", text)) {
    "shap_interaction"
  } else if (grepl("correlation", text) && grepl("plot|matrix|heatmap", text)) {
    "correlation_matrix"
  } else if (grepl("correlation", text)) {
    "table_correlation"
  } else if (grepl("histogram|distribution", text)) {
    "histogram"
  } else if (grepl("trend|time", text)) {
    "trend"
  } else if (grepl("scatter", text)) {
    "scatter"
  } else if (grepl("heatmap", text)) {
    "heatmap"
  } else if (grepl("metric|threshold|roc|auc|rmse|mae", text)) {
    "table_metrics"
  } else if (grepl("diagnostic|qa|config|readiness", text)) {
    "table_diagnostics"
  } else if (grepl("ranking|importance|top", text)) {
    "table_ranking"
  } else if (identical(artifact$artifact_type %||% artifact$type %||% "", "table")) {
    "table_diagnostics"
  } else if (identical(artifact$artifact_type %||% artifact$type %||% "", "text")) {
    "narrative"
  } else {
    "unknown"
  }
  list(artifact_family = family, policy_source = if (identical(family, "unknown")) "unknown" else "inferred")
}

genai_context_provenance <- function(artifact) {
  metadata <- artifact$metadata %||% list()
  upstream <- metadata$upstream_ai %||% list()
  list(
    caption_source = metadata$caption_source %||% "deterministic",
    metadata_source = metadata$metadata_source %||% "deterministic",
    diagnostics_source = metadata$diagnostics_source %||% if (length(metadata$diagnostics %||% metadata$warnings %||% character())) "deterministic" else "unknown",
    recommendations_source = metadata$recommendations_source %||% if (length(metadata$recommendations %||% character())) "deterministic" else "unknown",
    narrative_source = metadata$narrative_source %||% "unknown",
    table_preview_source = metadata$table_preview_source %||% if (!is.null(metadata$table_csv_path %||% metadata$csv_path %||% artifact$table)) "deterministic" else "unknown",
    json_summary_source = metadata$json_summary_source %||% "deterministic",
    screenshot_source = metadata$screenshot_source %||% if (!is.null(metadata$screenshot_path %||% metadata$thumbnail_path)) "deterministic" else "unknown",
    upstream_ai_used = isTRUE(upstream$used %||% metadata$upstream_ai_used %||% FALSE),
    upstream_ai_provider = upstream$provider %||% metadata$upstream_ai_provider %||% NA_character_,
    upstream_ai_model = upstream$model %||% metadata$upstream_ai_model %||% NA_character_,
    upstream_ai_tokens = upstream$tokens %||% metadata$upstream_ai_tokens %||% NA_integer_,
    upstream_ai_prompt_type = upstream$prompt_type %||% metadata$upstream_ai_prompt_type %||% NA_character_
  )
}

genai_question_applicability <- function(artifact_family, question_type) {
  if (identical(question_type, "exact_values")) {
    return(artifact_family %in% c("table_ranking", "table_metrics", "table_diagnostics", "table_correlation", "correlation_matrix", "heatmap"))
  }
  TRUE
}

genai_scoring_schema <- function() {
  list(
    correctness_score = NA_real_,
    completeness_score = NA_real_,
    usefulness_score = NA_real_,
    hallucination_score = NA_real_,
    missed_key_points = NA_character_,
    overclaiming_score = NA_real_,
    exact_value_accuracy = NA_real_,
    reviewer_notes = NA_character_
  )
}

genai_resolve_context_strategy <- function(artifact, requested_strategy, max_full_table_rows = 50L, max_full_table_cols = 20L) {
  notes <- character()
  used <- requested_strategy
  if (identical(requested_strategy, "full_table")) {
    dims <- genai_artifact_table_dimensions(artifact)
    too_large <- is.na(dims$rows) || is.na(dims$columns) || dims$rows > max_full_table_rows || dims$columns > max_full_table_cols
    if (isTRUE(too_large)) {
      used <- "table_preview_only"
      notes <- c(notes, sprintf(
        "full_table downgraded to table_preview_only because table dimensions were %s rows x %s columns; safety threshold is %s rows x %s columns.",
        dims$rows %||% "unknown", dims$columns %||% "unknown", max_full_table_rows, max_full_table_cols
      ))
    }
  }
  list(context_strategy_used = used, notes = notes)
}

genai_sample_experiment_artifacts <- function(
  artifacts,
  artifact_ids = "sample",
  artifact_types = c("plot", "table"),
  max_artifacts_per_type = 1L,
  sampling = c("first", "highest_quality", "warning", "critical_importance")
) {
  sampling <- match.arg(sampling)
  if (!identical(artifact_ids, "sample")) {
    ids <- as.character(artifact_ids)
    return(Filter(function(artifact) artifact$artifact_id %in% ids, artifacts))
  }
  selected <- list()
  for (type in artifact_types) {
    typed <- Filter(function(artifact) identical(artifact$artifact_type %||% artifact$type %||% "", type), artifacts)
    if (identical(sampling, "highest_quality")) {
      typed <- typed[order(vapply(typed, function(artifact) {
        metadata <- artifact$metadata %||% list()
        as.numeric(metadata$artifact_completeness %||% metadata$quality_score %||% 0)
      }, numeric(1)), decreasing = TRUE)]
    } else if (identical(sampling, "warning")) {
      typed <- Filter(function(artifact) length((artifact$metadata %||% list())$warnings %||% artifact$warnings %||% character()) > 0L, typed)
    } else if (identical(sampling, "critical_importance")) {
      typed <- Filter(function(artifact) identical((artifact$metadata %||% list())$artifact_importance %||% artifact$importance %||% "", "critical"), typed)
    }
    selected <- c(selected, utils::head(typed, max_artifacts_per_type))
  }
  selected
}

build_genai_experiment_grid <- function(
  project,
  artifact_ids = "sample",
  artifact_types = c("plot", "table"),
  context_strategies = c("caption_metadata", "balanced"),
  question_types = "summarize",
  provider = "ollama",
  model = NULL,
  vision_enabled = FALSE,
  max_image_bytes = 2500000L,
  max_image_count = 1L,
  max_artifacts_per_type = 1L,
  sampling = "first",
  project_path = NULL
) {
  loaded_project <- genai_load_experiment_project(project)
  selected <- genai_sample_experiment_artifacts(
    genai_project_artifacts(loaded_project),
    artifact_ids = artifact_ids,
    artifact_types = artifact_types,
    max_artifacts_per_type = max_artifacts_per_type,
    sampling = sampling
  )
  rows <- list()
  for (artifact in selected) {
    for (strategy in context_strategies) {
      for (question_type in question_types) {
        rows[[length(rows) + 1L]] <- data.table::data.table(
          artifact_id = artifact$artifact_id %||% "",
          artifact_type = artifact$artifact_type %||% artifact$type %||% "",
          artifact_title = artifact$label %||% artifact$title %||% artifact$artifact_id %||% "",
          question_type = question_type,
          provider = provider,
          model = model %||% NA_character_,
          context_strategy_requested = strategy
        )
      }
    }
  }
  grid <- data.table::rbindlist(rows, fill = TRUE)
  attr(grid, "project") <- loaded_project
  attr(grid, "project_path") <- project_path
  grid
}

genai_experiment_prompt <- function(artifact, question_type, context_strategy) {
  context <- genai_build_artifact_context(artifact, strategy = context_strategy)
  included_components <- attr(context, "included_components") %||% genai_context_strategy(context_strategy)$included_components
  prompt <- paste(
    "You are reviewing one Analytics Workstation artifact.",
    "Use only the provided artifact context. Do not invent values not present in the context.",
    genai_question_prompt(question_type),
    genai_context_json(context),
    sep = "\n\n"
  )
  list(prompt = prompt, context = context, included_components = included_components)
}

score_genai_experiment_result <- function(result) {
  text <- result$value$text %||% ""
  list(
    estimated_output_tokens = genai_estimate_tokens(text),
    response_excerpt = substr(gsub("[\r\n]+", " ", text), 1L, 600L),
    output_quality_score = NA_real_,
    accuracy_score = NA_real_,
    user_rating = NA_real_,
    reviewer_notes = NA_character_
  )
}

genai_experiment_result_row <- function(
  experiment_id,
  run_id,
  artifact,
  question_type,
  provider,
  model,
  strategy_requested,
  strategy_used,
  included_components,
  result,
  full_response_path = NA_character_,
  repeat_id = 1L,
  question_applicable = TRUE,
  notes = character()
) {
  telemetry <- result$metadata$telemetry %||% list()
  scores <- score_genai_experiment_result(result)
  family <- genai_infer_artifact_family(artifact)
  provenance <- genai_context_provenance(artifact)
  scoring <- genai_scoring_schema()
  data.table::data.table(
    experiment_id = experiment_id,
    run_id = run_id,
    repeat_id = repeat_id,
    timestamp = as.character(Sys.time()),
    artifact_id = artifact$artifact_id %||% "",
    artifact_type = artifact$artifact_type %||% artifact$type %||% "",
    artifact_family = family$artifact_family,
    artifact_family_policy_source = family$policy_source,
    artifact_title = artifact$label %||% artifact$title %||% artifact$artifact_id %||% "",
    question_type = question_type,
    question_applicable = isTRUE(question_applicable),
    provider = telemetry$provider %||% provider,
    model = telemetry$model %||% model %||% NA_character_,
    context_strategy_requested = strategy_requested,
    context_strategy_used = strategy_used,
    included_components = paste(names(included_components)[as.logical(included_components)], collapse = "|"),
    estimated_input_tokens = telemetry$estimated_input_tokens %||% NA_integer_,
    reported_input_tokens = telemetry$reported_input_tokens %||% NA_integer_,
    estimated_output_tokens = telemetry$estimated_output_tokens %||% scores$estimated_output_tokens,
    reported_output_tokens = telemetry$reported_output_tokens %||% NA_integer_,
    total_estimated_tokens = telemetry$total_estimated_tokens %||% NA_integer_,
    latency_ms = telemetry$latency_ms %||% NA_real_,
    image_payload_used = telemetry$image_payload_used %||% FALSE,
    image_payload_count = telemetry$image_payload_count %||% 0L,
    image_payload_bytes = telemetry$image_payload_bytes %||% 0L,
    image_payload_format = telemetry$image_payload_format %||% NA_character_,
    image_reference_only = telemetry$image_reference_only %||% FALSE,
    vision_model_detected = telemetry$vision_model_detected %||% FALSE,
    vision_capability_declared = telemetry$vision_capability_declared %||% FALSE,
    vision_capability_verified = telemetry$vision_capability_verified %||% FALSE,
    vision_downgrade_reason = telemetry$vision_downgrade_reason %||% NA_character_,
    success = identical(result$status, "success"),
    error = paste(result$errors %||% character(), collapse = "; "),
    response_excerpt = scores$response_excerpt,
    full_response_path = full_response_path,
    output_quality_score = scores$output_quality_score,
    accuracy_score = scores$accuracy_score,
    user_rating = scores$user_rating,
    correctness_score = scoring$correctness_score,
    completeness_score = scoring$completeness_score,
    usefulness_score = scoring$usefulness_score,
    hallucination_score = scoring$hallucination_score,
    missed_key_points = scoring$missed_key_points,
    overclaiming_score = scoring$overclaiming_score,
    exact_value_accuracy = scoring$exact_value_accuracy,
    reviewer_notes = scores$reviewer_notes,
    caption_source = provenance$caption_source,
    metadata_source = provenance$metadata_source,
    diagnostics_source = provenance$diagnostics_source,
    recommendations_source = provenance$recommendations_source,
    narrative_source = provenance$narrative_source,
    table_preview_source = provenance$table_preview_source,
    json_summary_source = provenance$json_summary_source,
    screenshot_source = provenance$screenshot_source,
    upstream_ai_used = provenance$upstream_ai_used,
    upstream_ai_provider = provenance$upstream_ai_provider,
    upstream_ai_model = provenance$upstream_ai_model,
    upstream_ai_tokens = provenance$upstream_ai_tokens,
    upstream_ai_prompt_type = provenance$upstream_ai_prompt_type,
    notes = paste(notes, collapse = "; ")
  )
}

write_genai_experiment_results <- function(results, responses, output_dir = file.path("exports", "genai_experiments"), experiment_id = NULL) {
  experiment_id <- experiment_id %||% genai_experiment_id()
  experiment_dir <- file.path(output_dir, experiment_id)
  dir.create(experiment_dir, recursive = TRUE, showWarnings = FALSE)
  results_path <- file.path(experiment_dir, "results.csv")
  responses_path <- file.path(experiment_dir, "responses.json")
  summary_path <- file.path(experiment_dir, "summary.md")
  data.table::fwrite(results, results_path)
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    writeLines(jsonlite::toJSON(responses, auto_unbox = TRUE, pretty = TRUE, null = "null"), responses_path, useBytes = TRUE)
  } else {
    writeLines("[]", responses_path, useBytes = TRUE)
  }
  success_count <- sum(as.logical(results$success), na.rm = TRUE)
  failure_count <- nrow(results) - success_count
  latency <- suppressWarnings(mean(as.numeric(results$latency_ms), na.rm = TRUE))
  strategy_tokens <- if (nrow(results)) {
    aggregate(total_estimated_tokens ~ context_strategy_used, data = results, FUN = function(x) round(mean(x, na.rm = TRUE), 1))
  } else {
    data.frame()
  }
  summary_lines <- c(
    paste0("# GenAI Experiment Summary: ", experiment_id),
    "",
    paste0("- Calls: ", nrow(results)),
    paste0("- Successes: ", success_count),
    paste0("- Failures: ", failure_count),
    paste0("- Average latency ms: ", if (is.finite(latency)) round(latency, 1) else "NA"),
    "",
    "## Token Usage By Strategy",
    if (nrow(strategy_tokens)) paste0("- ", strategy_tokens$context_strategy_used, ": ", strategy_tokens$total_estimated_tokens, " estimated tokens") else "- No calls recorded.",
    "",
    "## Failures By Strategy",
    if (failure_count) paste0("- ", results$context_strategy_used[!results$success], ": ", results$error[!results$success]) else "- None recorded.",
    "",
    "## Rough Observations",
    "- Manual review fields are intentionally blank for later scoring.",
    "- Compare latency, token cost, and reviewer scores by artifact type and context strategy.",
    "",
    "## Recommended Next Experiment",
    "- Repeat with a broader sample of plot and table artifacts, then manually score factual accuracy and usefulness."
  )
  writeLines(summary_lines, summary_path, useBytes = TRUE)
  list(experiment_dir = experiment_dir, results_path = results_path, responses_path = responses_path, summary_path = summary_path)
}

run_genai_artifact_experiment <- function(
  project,
  artifact_ids = "sample",
  artifact_types = c("plot", "table"),
  context_strategies = c("caption_metadata", "balanced"),
  question_types = "summarize",
  provider = "ollama",
  model = NULL,
  vision_enabled = FALSE,
  max_image_bytes = 2500000L,
  max_image_count = 1L,
  max_artifacts_per_type = 1L,
  max_full_table_rows = 50L,
  max_full_table_cols = 20L,
  output_dir = file.path("exports", "genai_experiments"),
  dry_run = FALSE,
  sampling = "first",
  repeat_count = 1L,
  experiment_id = NULL
) {
  experiment_id <- experiment_id %||% genai_experiment_id("artifact_context_experiment")
  run_id <- paste0("run_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  project_path <- if (is.character(project) && length(project) == 1L) normalize_project_load_path(project) else NULL
  loaded_project <- genai_load_experiment_project(project)
  collector_dir <- genai_project_collector_artifact_dir(loaded_project, project_path = project_path)
  artifacts <- genai_project_artifacts(loaded_project)
  grid <- build_genai_experiment_grid(
    loaded_project,
    artifact_ids = artifact_ids,
    artifact_types = artifact_types,
    context_strategies = context_strategies,
    question_types = question_types,
    provider = provider,
    model = model,
    max_artifacts_per_type = max_artifacts_per_type,
    sampling = sampling,
    project_path = project_path
  )
  config <- genai_config(
    provider = provider,
    model = model %||% "",
    vision_enabled = vision_enabled,
    max_image_bytes = max_image_bytes,
    max_image_count = max_image_count
  )
  rows <- list()
  responses <- list()
  for (i in seq_len(nrow(grid))) {
    row <- grid[i]
    artifact <- artifacts[[which(vapply(artifacts, function(x) identical(x$artifact_id, row$artifact_id), logical(1)))[1]]]
    artifact <- genai_prepare_experiment_artifact(artifact, collector_dir)
    resolved <- genai_resolve_context_strategy(
      artifact,
      row$context_strategy_requested,
      max_full_table_rows = max_full_table_rows,
      max_full_table_cols = max_full_table_cols
    )
    prompt_pack <- genai_experiment_prompt(artifact, row$question_type, resolved$context_strategy_used)
    image_payload <- genai_vision_payload(artifact, resolved$context_strategy_used, config = config)
    for (repeat_id in seq_len(max(1L, as.integer(repeat_count)))) {
    if (isTRUE(dry_run)) {
      response_text <- paste("DRY RUN:", row$artifact_title, row$question_type, resolved$context_strategy_used)
      result <- service_result(
        status = "success",
        value = list(text = response_text, raw = list()),
        messages = "Dry-run GenAI experiment row generated.",
        metadata = list(provider = provider, model = model %||% config$model)
      )
      telemetry <- genai_telemetry_record(
        call_type = "genai_artifact_experiment",
        context_strategy = resolved$context_strategy_used,
        included_components = prompt_pack$included_components,
        estimated_input_tokens = genai_estimate_tokens(prompt_pack$prompt),
        estimated_output_tokens = genai_estimate_tokens(response_text),
        latency_ms = 0,
        provider = provider,
        model = model %||% config$model,
        status = "success",
        image_payload_used = image_payload$telemetry$image_payload_used,
        image_payload_count = image_payload$telemetry$image_payload_count,
        image_payload_bytes = image_payload$telemetry$image_payload_bytes,
        image_payload_format = image_payload$telemetry$image_payload_format,
        image_reference_only = image_payload$telemetry$image_reference_only,
        vision_model_detected = image_payload$telemetry$vision_model_detected,
        vision_capability_declared = image_payload$telemetry$vision_capability_declared,
        vision_capability_verified = image_payload$telemetry$vision_capability_verified,
        vision_downgrade_reason = image_payload$telemetry$vision_downgrade_reason
      )
      result <- genai_attach_telemetry(result, telemetry)
    } else {
      result <- genai_generate_with_telemetry(
        prompt_pack$prompt,
        config = config,
        context_strategy = resolved$context_strategy_used,
        included_components = prompt_pack$included_components,
        call_type = "genai_artifact_experiment",
        images = image_payload$images,
        image_telemetry = image_payload$telemetry
      )
    }
    responses[[length(responses) + 1L]] <- list(
      artifact_id = artifact$artifact_id %||% "",
      question_type = row$question_type,
      context_strategy_requested = row$context_strategy_requested,
      context_strategy_used = resolved$context_strategy_used,
      response = result$value$text %||% "",
      status = result$status,
      error = paste(result$errors %||% character(), collapse = "; ")
    )
    rows[[length(rows) + 1L]] <- genai_experiment_result_row(
      experiment_id = experiment_id,
      run_id = run_id,
      artifact = artifact,
      question_type = row$question_type,
      provider = provider,
      model = model %||% config$model,
      strategy_requested = row$context_strategy_requested,
      strategy_used = resolved$context_strategy_used,
      included_components = prompt_pack$included_components,
      result = result,
      full_response_path = NA_character_,
      repeat_id = repeat_id,
      question_applicable = genai_question_applicability(genai_infer_artifact_family(artifact)$artifact_family, row$question_type),
      notes = resolved$notes
    )
    }
  }
  results <- data.table::rbindlist(rows, fill = TRUE)
  paths <- write_genai_experiment_results(results, responses, output_dir = output_dir, experiment_id = experiment_id)
  if (nrow(results)) {
    results[, full_response_path := paths$responses_path]
    data.table::fwrite(results, paths$results_path)
  }
  service_result(
    status = if (nrow(results) && any(!results$success)) "warning" else "success",
    value = list(results = results, responses = responses, paths = paths),
    messages = "GenAI artifact experiment completed.",
    warnings = if (nrow(results) && any(!results$success)) "One or more GenAI experiment calls failed." else character(),
    metadata = list(experiment_id = experiment_id, run_id = run_id, output_dir = paths$experiment_dir)
  )
}

run_genai_project_experiment <- function(
  project,
  context_strategies = c("caption_metadata", "balanced"),
  question_types = c("summarize", "suggest_next_action"),
  provider = "ollama",
  model = NULL,
  output_dir = file.path("exports", "genai_experiments"),
  dry_run = FALSE,
  experiment_id = NULL
) {
  pseudo_artifact <- list(
    artifact_id = "project_context",
    artifact_type = "json",
    label = "Project Context",
    source_module = "project",
    metadata = list(analytical_intent = "Project Brief", artifact_importance = "recommended")
  )
  loaded_project <- genai_load_experiment_project(project)
  loaded_project$module_artifacts <- c(list(pseudo_artifact), genai_project_artifacts(loaded_project))
  run_genai_artifact_experiment(
    loaded_project,
    artifact_ids = "project_context",
    artifact_types = "json",
    context_strategies = context_strategies,
    question_types = question_types,
    provider = provider,
    model = model,
    output_dir = output_dir,
    dry_run = dry_run,
    experiment_id = experiment_id %||% genai_experiment_id("project_context_experiment")
  )
}

run_genai_image_vs_data_experiment <- function(
  project,
  provider = "ollama",
  model = NULL,
  vision_enabled = TRUE,
  max_artifacts_per_type = 1L,
  max_image_bytes = 2500000L,
  max_image_count = 1L,
  max_full_table_rows = 50L,
  max_full_table_cols = 20L,
  output_dir = file.path("exports", "genai_experiments"),
  dry_run = FALSE,
  experiment_id = NULL
) {
  run_genai_artifact_experiment(
    project = project,
    artifact_types = c("plot", "table"),
    context_strategies = c(
      "caption_metadata",
      "screenshot_only",
      "screenshot_caption",
      "screenshot_caption_preview",
      "table_preview_only",
      "full_table",
      "structured_json_summary",
      "balanced"
    ),
    question_types = "summarize",
    provider = provider,
    model = model,
    vision_enabled = vision_enabled,
    max_image_bytes = max_image_bytes,
    max_image_count = max_image_count,
    max_artifacts_per_type = max_artifacts_per_type,
    max_full_table_rows = max_full_table_rows,
    max_full_table_cols = max_full_table_cols,
    output_dir = output_dir,
    dry_run = dry_run,
    experiment_id = experiment_id %||% genai_experiment_id("image_vs_data_experiment")
  )
}

genai_context_strategy_baseline_rules <- function() {
  data.table::data.table(
    rule_id = c(
      "text_model_no_pixels", "vision_requires_payload", "exact_values_structured",
      "tables_preview_before_full", "full_table_guarded", "dense_plots_need_context",
      "heatmap_hybrid", "shap_dependence_visual", "boxplot_quantiles"
    ),
    artifact_family = c("any", "any", "any", "table_diagnostics", "any", "faceted_plot", "heatmap", "shap_dependence", "boxplot"),
    user_constraint = c("vision_required", "vision_required", "exact_values_required", "balanced", "minimize_tokens", "balanced", "balanced", "balanced", "exact_values_required"),
    recommended_strategy = c("screenshot_caption", "screenshot_caption", "structured_json_summary", "table_preview_only", "table_preview_only", "screenshot_caption", "screenshot_caption_preview", "screenshot_caption", "screenshot_caption_preview"),
    fallback_strategy = c("caption_metadata", "caption_metadata", "table_preview_only", "structured_json_summary", "caption_metadata", "structured_json_summary", "structured_json_summary", "structured_json_summary", "table_preview_only"),
    reason = c(
      "Text-only models cannot inspect screenshot pixels.",
      "Vision strategies require image_payload_used TRUE to count as image transfer.",
      "Exact-value questions prefer structured table or JSON context when available.",
      "Table artifacts should usually try previews before full tables.",
      "Full tables are guarded and should not be used globally.",
      "Dense or faceted plots may need visual evidence plus semantic context.",
      "Heatmaps and correlation matrices often need image pattern plus table/JSON support.",
      "SHAP dependence plots often communicate nonlinear shape visually.",
      "Boxplots may need visual distribution plus quantile backing data."
    )
  )
}

genai_derive_study_metrics <- function(results) {
  if (!nrow(results)) return(data.table::data.table())
  score_mean <- function(x) if (all(is.na(x))) NA_real_ else mean(as.numeric(x), na.rm = TRUE)
  results[, .(
    calls = .N,
    success_count = sum(success, na.rm = TRUE),
    failure_rate = mean(!success, na.rm = TRUE),
    avg_latency_ms = round(mean(as.numeric(latency_ms), na.rm = TRUE), 1),
    avg_tokens = round(mean(as.numeric(total_estimated_tokens), na.rm = TRUE), 1),
    image_payload_success_rate = if (any(image_payload_used)) mean(success[image_payload_used], na.rm = TRUE) else NA_real_,
    downgrade_rate = mean(nzchar(vision_downgrade_reason %||% ""), na.rm = TRUE),
    correctness_score = score_mean(correctness_score),
    usefulness_score = score_mean(usefulness_score),
    hallucination_rate = score_mean(hallucination_score),
    quality_per_1k_tokens = if (is.na(score_mean(output_quality_score))) NA_real_ else score_mean(output_quality_score) / (mean(as.numeric(total_estimated_tokens), na.rm = TRUE) / 1000),
    correctness_per_1k_tokens = if (is.na(score_mean(correctness_score))) NA_real_ else score_mean(correctness_score) / (mean(as.numeric(total_estimated_tokens), na.rm = TRUE) / 1000),
    usefulness_per_second = if (is.na(score_mean(usefulness_score))) NA_real_ else score_mean(usefulness_score) / (mean(as.numeric(latency_ms), na.rm = TRUE) / 1000)
  ), by = .(artifact_family, artifact_type, context_strategy_used, question_type, provider, model)]
}

recommend_context_strategy <- function(
  artifact_family = "unknown",
  user_constraint = c("balanced", "minimize_tokens", "maximize_accuracy", "minimize_latency", "local_private", "vision_required", "exact_values_required"),
  provider_capabilities = genai_capabilities(),
  experiment_results = NULL
) {
  user_constraint <- match.arg(user_constraint)
  family <- artifact_family
  constraint <- user_constraint
  evidence_count <- 0L
  if (!is.null(experiment_results) && nrow(experiment_results)) {
    evidence <- experiment_results[artifact_family == family]
    evidence_count <- nrow(evidence)
  }
  rules <- genai_context_strategy_baseline_rules()
  rule <- rules[artifact_family == family & user_constraint == constraint]
  if (!nrow(rule)) rule <- rules[artifact_family == "any" & user_constraint == constraint]
  if (!nrow(rule)) {
    return(list(
      recommended_strategy = "balanced",
      confidence = 0.2,
      reason = "Insufficient family-specific evidence; balanced is a conservative fallback.",
      fallback_strategy = "caption_metadata",
      evidence_count = evidence_count,
      rule_source = "fallback"
    ))
  }
  if (identical(user_constraint, "vision_required") && !isTRUE(provider_capabilities[["vision"]])) {
    return(list(
      recommended_strategy = rule$fallback_strategy[[1]],
      confidence = 0.15,
      reason = "Provider does not declare vision; cannot recommend true screenshot-pixel transfer.",
      fallback_strategy = "caption_metadata",
      evidence_count = evidence_count,
      rule_source = "deterministic_baseline"
    ))
  }
  list(
    recommended_strategy = rule$recommended_strategy[[1]],
    confidence = if (evidence_count >= 10L) 0.45 else 0.25,
    reason = rule$reason[[1]],
    fallback_strategy = rule$fallback_strategy[[1]],
    evidence_count = evidence_count,
    rule_source = "deterministic_baseline"
  )
}

write_genai_context_strategy_study_outputs <- function(results, responses, output_dir, experiment_id) {
  paths <- write_genai_experiment_results(results, responses, output_dir = output_dir, experiment_id = experiment_id)
  metrics <- genai_derive_study_metrics(results)
  recommendations <- unique(results[, .(artifact_family, artifact_type)])
  if (nrow(recommendations)) {
    rec_rows <- lapply(seq_len(nrow(recommendations)), function(i) {
      rec <- recommend_context_strategy(recommendations$artifact_family[[i]], "balanced", experiment_results = results)
      data.table::data.table(
        artifact_family = recommendations$artifact_family[[i]],
        artifact_type = recommendations$artifact_type[[i]],
        recommended_strategy = rec$recommended_strategy,
        confidence = rec$confidence,
        reason = rec$reason,
        fallback_strategy = rec$fallback_strategy,
        evidence_count = rec$evidence_count,
        rule_source = rec$rule_source
      )
    })
    recommendation_table <- data.table::rbindlist(rec_rows, fill = TRUE)
  } else {
    recommendation_table <- data.table::data.table()
  }
  family_path <- file.path(paths$experiment_dir, "family_comparison.md")
  rec_path <- file.path(paths$experiment_dir, "strategy_recommendations.csv")
  open_path <- file.path(paths$experiment_dir, "open_questions.md")
  data.table::fwrite(recommendation_table, rec_path)
  writeLines(c(
    paste0("# Family Comparison: ", experiment_id), "",
    "```", paste(capture.output(print(metrics)), collapse = "\n"), "```"
  ), family_path)
  writeLines(c(
    "# Open Questions", "",
    "- Which artifact families benefit from true image payloads after manual scoring?",
    "- When does structured JSON beat table previews for exact-value questions?",
    "- Which plot families require hybrid screenshot + table preview context?",
    "- How stable are recommendations across repeat runs and providers?"
  ), open_path)
  paths$family_comparison_path <- family_path
  paths$strategy_recommendations_path <- rec_path
  paths$open_questions_path <- open_path
  paths
}

run_genai_context_strategy_study <- function(
  project,
  artifact_families = NULL,
  context_strategies = c("caption_metadata", "screenshot_caption", "table_preview_only", "structured_json_summary", "balanced"),
  question_types = c("summarize", "key_findings", "limitations", "next_action", "exact_values", "production_risk"),
  provider = "ollama",
  model = NULL,
  max_artifacts_per_family = 1L,
  repeat_count = 1L,
  output_dir = file.path("exports", "genai_experiments"),
  dry_run = FALSE,
  vision_required = FALSE,
  max_full_table_rows = 50L,
  max_full_table_cols = 20L,
  experiment_id = NULL
) {
  experiment_id <- experiment_id %||% genai_experiment_id("context_strategy_study")
  loaded_project <- genai_load_experiment_project(project)
  artifacts <- genai_project_artifacts(loaded_project)
  families <- lapply(artifacts, genai_infer_artifact_family)
  family_values <- vapply(families, `[[`, character(1), "artifact_family")
  if (!is.null(artifact_families)) {
    artifacts <- artifacts[family_values %in% artifact_families]
    family_values <- family_values[family_values %in% artifact_families]
  }
  selected <- list()
  for (family in unique(family_values)) {
    idx <- which(family_values == family)
    selected <- c(selected, artifacts[utils::head(idx, max_artifacts_per_family)])
  }
  if (isTRUE(vision_required)) {
    context_strategies <- intersect(context_strategies, c("screenshot_only", "screenshot_caption", "screenshot_caption_preview"))
  }
  study_project <- loaded_project
  study_project$module_artifacts <- selected
  result <- run_genai_artifact_experiment(
    study_project,
    artifact_ids = vapply(selected, function(x) x$artifact_id %||% "", character(1)),
    artifact_types = unique(vapply(selected, function(x) x$artifact_type %||% x$type %||% "", character(1))),
    context_strategies = context_strategies,
    question_types = question_types,
    provider = provider,
    model = model,
    vision_enabled = vision_required,
    max_artifacts_per_type = length(selected),
    max_full_table_rows = max_full_table_rows,
    max_full_table_cols = max_full_table_cols,
    output_dir = output_dir,
    dry_run = dry_run,
    repeat_count = repeat_count,
    experiment_id = experiment_id
  )
  paths <- write_genai_context_strategy_study_outputs(result$value$results, result$value$responses, output_dir, experiment_id)
  result$value$paths <- paths
  result
}

qa_genai_context_strategy_study <- function() {
  plot_artifact <- list(
    artifact_id = "qa_shap_effect_plot",
    artifact_type = "plot",
    label = "SHAP Effect: age",
    source_module = "qa_shap",
    metadata = list(screenshot_path = tempfile(fileext = ".png"), artifact_family = "shap_dependence")
  )
  table_artifact <- list(
    artifact_id = "qa_metrics_table",
    artifact_type = "table",
    label = "Model Metrics",
    source_module = "qa_model",
    table = data.table::data.table(metric = c("rmse", "mae"), value = c(1.2, 0.8)),
    metadata = list()
  )
  project <- list(module_artifacts = list(plot_artifact, table_artifact), project_collector = data.table::data.table())
  family_explicit <- genai_infer_artifact_family(plot_artifact)
  family_inferred <- genai_infer_artifact_family(table_artifact)
  provenance <- genai_context_provenance(table_artifact)
  dry <- run_genai_context_strategy_study(
    project,
    artifact_families = c("shap_dependence", "table_metrics"),
    context_strategies = c("caption_metadata", "full_table", "screenshot_caption"),
    question_types = c("summarize", "exact_values"),
    provider = "none",
    model = "none",
    max_artifacts_per_family = 1L,
    repeat_count = 2L,
    output_dir = file.path(tempdir(), "genai_context_strategy_study_qa"),
    dry_run = TRUE,
    vision_required = FALSE,
    max_full_table_rows = 1L,
    experiment_id = "qa_context_strategy_study"
  )
  results <- dry$value$results
  metrics <- genai_derive_study_metrics(results)
  rec <- recommend_context_strategy("shap_dependence", "balanced", genai_capabilities("vision"), experiment_results = results)
  required_fields <- c(
    "artifact_family", "artifact_family_policy_source", "repeat_id", "question_applicable",
    "caption_source", "metadata_source", "diagnostics_source", "recommendations_source",
    "narrative_source", "table_preview_source", "json_summary_source", "screenshot_source",
    "upstream_ai_used", "upstream_ai_provider", "upstream_ai_model", "upstream_ai_tokens",
    "upstream_ai_prompt_type", "correctness_score", "completeness_score", "usefulness_score",
    "hallucination_score", "missed_key_points", "overclaiming_score", "exact_value_accuracy"
  )
  paths <- dry$value$paths
  service_qa <- qa_genai_service_contract()
  data.table::data.table(
    check = c(
      "artifact_family_explicit",
      "artifact_family_inferred",
      "context_provenance_fields",
      "repeat_id_recorded",
      "scoring_schema_exists",
      "derived_metrics_blank_scores",
      "baseline_rules_exist",
      "recommendation_conservative",
      "vision_required_filters_strategies",
      "text_model_no_image_claim",
      "study_outputs_written",
      "existing_genai_qa_passes"
    ),
    status = c(
      if (identical(family_explicit$artifact_family, "shap_dependence") && identical(family_explicit$policy_source, "explicit")) "success" else "error",
      if (identical(family_inferred$artifact_family, "table_metrics")) "success" else "error",
      if (all(c("caption_source", "upstream_ai_used", "screenshot_source") %in% names(provenance))) "success" else "error",
      if (all(c(1L, 2L) %in% results$repeat_id)) "success" else "error",
      if (all(required_fields %in% names(results))) "success" else "error",
      if ("quality_per_1k_tokens" %in% names(metrics) && all(is.na(metrics$quality_per_1k_tokens))) "success" else "error",
      if (nrow(genai_context_strategy_baseline_rules()) >= 5L) "success" else "error",
      if (is.list(rec) && rec$confidence <= 0.45 && nzchar(rec$reason)) "success" else "error",
      if (all(run_genai_context_strategy_study(project, context_strategies = c("caption_metadata", "screenshot_caption"), question_types = "summarize", provider = "none", dry_run = TRUE, vision_required = TRUE, output_dir = file.path(tempdir(), "genai_context_strategy_vision_qa"))$value$results$context_strategy_requested == "screenshot_caption")) "success" else "error",
      if (!any(run_genai_artifact_experiment(project, artifact_types = "plot", context_strategies = "screenshot_caption", question_types = "summarize", provider = "none", dry_run = TRUE)$value$results$image_payload_used)) "success" else "error",
      if (all(file.exists(c(paths$results_path, paths$responses_path, paths$summary_path, paths$family_comparison_path, paths$strategy_recommendations_path, paths$open_questions_path)))) "success" else "error",
      if (!any(service_qa$status == "error")) "success" else "error"
    ),
    message = c(
      "Explicit artifact_family metadata is honored.",
      "Fallback artifact_family inference classifies metric tables.",
      "Context provenance fields are available.",
      "Repeat IDs are recorded for repeated runs.",
      "Manual scoring schema columns are present.",
      "Derived quality metrics remain NA when scores are blank.",
      "Preliminary deterministic baseline rules are available.",
      "Recommendation stub remains conservative.",
      "Vision-required studies keep only screenshot strategies.",
      "Text-only providers do not claim true image payloads.",
      "Study outputs include CSV, JSON, summary, family comparison, recommendations, and open questions.",
      "Existing GenAI service QA still passes."
    )
  )
}

qa_genai_vision_support <- function() {
  image_path <- tempfile(fileext = ".png")
  writeBin(as.raw(c(
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xde, 0x00, 0x00, 0x00,
    0x0c, 0x49, 0x44, 0x41, 0x54, 0x08, 0x99, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
    0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xdd, 0x8d, 0xb0, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
  )), image_path)
  artifact <- list(
    artifact_id = "qa_vision_plot",
    artifact_type = "plot",
    label = "QA Vision Plot",
    metadata = list(screenshot_path = image_path)
  )
  missing_artifact <- artifact
  missing_artifact$metadata$screenshot_path <- tempfile(fileext = ".png")
  mock_vision_config <- genai_config(provider = "mock", model = "mock-vision", vision_enabled = TRUE, max_image_bytes = 100000L)
  mock_text_config <- genai_config(provider = "mock", model = "mock-model", vision_enabled = FALSE, max_image_bytes = 100000L)
  ollama_payload <- genai_ollama_generate_payload(
    "describe image",
    genai_config(provider = "ollama", model = "llava", vision_enabled = TRUE),
    images = c("abc123")
  )
  payload <- genai_vision_payload(artifact, "screenshot_caption", mock_vision_config)
  text_payload <- genai_vision_payload(artifact, "screenshot_caption", mock_text_config)
  missing_payload <- genai_vision_payload(missing_artifact, "screenshot_caption", mock_vision_config)
  no_image_strategy <- genai_vision_payload(artifact, "caption_metadata", mock_vision_config)
  project <- list(module_artifacts = list(artifact), project_collector = data.table::data.table())
  experiment <- run_genai_artifact_experiment(
    project,
    artifact_types = "plot",
    context_strategies = c("screenshot_caption", "caption_metadata"),
    question_types = "summarize",
    provider = "mock",
    model = "mock-vision",
    vision_enabled = TRUE,
    dry_run = FALSE,
    output_dir = file.path(tempdir(), "genai_vision_qa")
  )
  results <- experiment$value$results
  required_fields <- c(
    "image_payload_used", "image_payload_count", "image_payload_bytes", "image_payload_format",
    "image_reference_only", "vision_model_detected", "vision_capability_declared",
    "vision_capability_verified", "vision_downgrade_reason"
  )
  data.table::data.table(
    check = c(
      "image_payload_fields_exist",
      "ollama_vision_payload_builds",
      "mock_vision_payload_used",
      "text_model_reference_only",
      "missing_image_degrades",
      "text_strategy_no_image_payload",
      "experiment_output_includes_image_telemetry",
      "text_only_experiments_still_pass"
    ),
    status = c(
      if (all(required_fields %in% names(results))) "success" else "error",
      if (identical(as.character(ollama_payload$images)[[1]], "abc123")) "success" else "error",
      if (isTRUE(payload$telemetry$image_payload_used) && payload$telemetry$image_payload_count == 1L) "success" else "error",
      if (!isTRUE(text_payload$telemetry$image_payload_used) && isTRUE(text_payload$telemetry$image_reference_only)) "success" else "error",
      if (!isTRUE(missing_payload$telemetry$image_payload_used) && identical(missing_payload$telemetry$vision_downgrade_reason, "missing_image_file")) "success" else "error",
      if (!isTRUE(no_image_strategy$telemetry$image_payload_used) && identical(no_image_strategy$telemetry$vision_downgrade_reason, "strategy_does_not_request_image_payload")) "success" else "error",
      if (any(results$image_payload_used) && any(!results$image_payload_used)) "success" else "error",
      if (!any(qa_genai_experiment_harness()$status == "error")) "success" else "error"
    ),
    message = c(
      "Experiment results include image-vs-reference telemetry fields.",
      "Ollama generate payload can carry base64 image entries.",
      "Mock vision provider sends an actual image payload when configured.",
      "Text-only configuration records screenshot reference only.",
      "Missing screenshot files downgrade instead of failing.",
      "Text-only strategies do not attach image payloads.",
      "Experiment output distinguishes true image ingestion from text-only rows.",
      "Existing text-only experiment harness still passes."
    )
  )
}

qa_genai_experiment_harness <- function() {
  artifact_plot <- list(
    artifact_id = "qa_plot_artifact",
    artifact_type = "plot",
    label = "QA Plot",
    source_module = "qa",
    metadata = list(
      screenshot_path = tempfile(fileext = ".png"),
      analytical_intent = "Distribution",
      artifact_importance = "recommended",
      artifact_completeness = 80
    )
  )
  artifact_table <- list(
    artifact_id = "qa_table_artifact",
    artifact_type = "table",
    label = "QA Table",
    source_module = "qa",
    table = data.table::data.table(group = LETTERS[1:8], value = seq_len(8), risk = rev(seq_len(8))),
    metadata = list(analytical_intent = "Diagnostic", artifact_importance = "recommended")
  )
  project <- list(module_artifacts = list(artifact_plot, artifact_table), project_collector = data.table::data.table())
  output_dir <- file.path(tempdir(), "genai_experiment_qa")
  grid <- build_genai_experiment_grid(
    project,
    artifact_types = c("plot", "table"),
    context_strategies = c("caption_metadata", "full_table"),
    question_types = c("summarize", "limitations"),
    provider = "mock",
    max_artifacts_per_type = 1L
  )
  dry <- run_genai_artifact_experiment(
    project,
    artifact_types = c("plot", "table"),
    context_strategies = c("caption_metadata", "full_table"),
    question_types = "summarize",
    provider = "none",
    output_dir = output_dir,
    dry_run = TRUE,
    max_full_table_rows = 3L
  )
  mock <- run_genai_artifact_experiment(
    project,
    artifact_types = c("plot", "table"),
    context_strategies = "caption_metadata",
    question_types = "summarize",
    provider = "mock",
    output_dir = output_dir,
    dry_run = FALSE
  )
  unavailable <- run_genai_artifact_experiment(
    project,
    artifact_types = "plot",
    context_strategies = "caption_metadata",
    question_types = "summarize",
    provider = "none",
    output_dir = output_dir,
    dry_run = FALSE
  )
  dry_results <- dry$value$results
  paths <- dry$value$paths
  required_fields <- c(
    "experiment_id", "run_id", "timestamp", "artifact_id", "artifact_type", "artifact_title",
    "question_type", "provider", "model", "context_strategy_requested", "context_strategy_used",
    "included_components", "estimated_input_tokens", "reported_input_tokens", "estimated_output_tokens",
    "reported_output_tokens", "total_estimated_tokens", "latency_ms", "success", "error",
    "response_excerpt", "full_response_path", "output_quality_score", "accuracy_score",
    "user_rating", "image_payload_used", "image_payload_count", "image_payload_bytes",
    "image_payload_format", "image_reference_only", "vision_model_detected",
    "vision_capability_declared", "vision_capability_verified", "vision_downgrade_reason",
    "notes"
  )
  service_qa <- qa_genai_service_contract()
  data.table::data.table(
    check = c(
      "experiment_grid_builds",
      "dry_run_without_provider",
      "mock_provider_runs",
      "unavailable_provider_graceful",
      "full_table_safety_downgrade",
      "results_csv_written",
      "responses_json_written",
      "summary_md_written",
      "telemetry_fields_exist",
      "existing_genai_service_qa_passes"
    ),
    status = c(
      if (nrow(grid) == 8L) "success" else "error",
      if (identical(dry$status, "success") && all(dry_results$success)) "success" else "error",
      if (identical(mock$status, "success") && all(mock$value$results$success)) "success" else "error",
      if (identical(unavailable$status, "warning") && any(!unavailable$value$results$success)) "success" else "error",
      if (any(dry_results$context_strategy_requested == "full_table" & dry_results$context_strategy_used == "table_preview_only")) "success" else "error",
      if (file.exists(paths$results_path)) "success" else "error",
      if (file.exists(paths$responses_path)) "success" else "error",
      if (file.exists(paths$summary_path)) "success" else "error",
      if (all(required_fields %in% names(dry_results))) "success" else "error",
      if (!any(service_qa$status == "error")) "success" else "error"
    ),
    message = c(
      "Experiment grid includes sampled artifacts, strategies, and questions.",
      "Dry run completes without a configured provider.",
      "Mock provider executes through the provider abstraction.",
      "Unavailable provider is captured as row-level failure.",
      "Unsafe full_table requests are downgraded and recorded.",
      paths$results_path,
      paths$responses_path,
      paths$summary_path,
      "Required telemetry columns are present.",
      "GenAI service contract QA still passes."
    )
  )
}

ui_genai_status_panel <- function(status, title = "GenAI Provider", actions = NULL, result = NULL) {
  metadata <- status$metadata %||% list()
  value <- status$value %||% list()
  capabilities <- value$capabilities %||% genai_capabilities()
  capability_labels <- names(capabilities)[as.logical(capabilities)]
  configured <- isTRUE(value$configured)
  available <- isTRUE(value$available)
  availability_checked <- isTRUE(value$availability_checked)
  reason <- metadata$diagnostic_reason %||% if (configured) "not_checked" else "not_configured"
  availability_label <- if (available) {
    "Available"
  } else if (!configured) {
    "Not configured"
  } else if (!availability_checked) {
    "Not checked"
  } else if (identical(reason, "package_missing")) {
    "Package missing"
  } else if (grepl("ollama", reason, fixed = TRUE)) {
    "Ollama offline"
  } else {
    "Unavailable"
  }
  provider_label <- metadata$display_name %||% "None"
  config_source <- metadata$config_source %||% "unknown"
  status_group <- if (available) "success" else if (configured && !availability_checked) "info" else if (configured) "warning" else "neutral"
  diagnostic_text <- switch(
    reason,
    not_configured = "No GenAI provider is configured. Local Ollama can be auto-detected when reachable, or set ANALYTICS_GENAI_PROVIDER explicitly.",
    not_checked = "Provider is configured, but live availability has not been checked on this surface.",
    package_missing = "GenAI HTTP dependencies are missing in this R library path. Install httr2/jsonlite/curl for the current R version.",
    endpoint_unreachable_or_ollama_not_running = "Ollama is configured but not reachable. Start Ollama or check the base URL.",
    endpoint_unreachable = "Provider endpoint is not reachable. Check the base URL, server process, and network access.",
    available = "Provider is configured and reachable.",
    available_last_success = "Provider produced a successful response in this session.",
    available_auto_detected = "Local Ollama was reachable during app startup auto-detection.",
    service_result_message(status)
  )
  ui_card(
    title = title,
    subtitle = "Read-only analytical assistance. GenAI cannot execute app actions.",
    ui_stat_grid(
      ui_stat_tile("Provider", provider_label, status = status_group, detail = config_source),
      ui_stat_tile("Model", metadata$model %||% "Not configured", status = if (configured) "info" else "neutral"),
      ui_stat_tile("Availability", availability_label, status = status_group),
      ui_stat_tile("Privacy", if (isTRUE(metadata$privacy_preserving)) "Local/private" else "Review endpoint", status = if (isTRUE(metadata$privacy_preserving)) "success" else "warning")
    ),
    tags$p(class = "aq-export-message", diagnostic_text),
    tags$div(
      class = "aq-genai-capability-row",
      if (length(capability_labels)) lapply(capability_labels, function(x) ui_status_badge(x, status = "info")) else ui_status_badge("no capabilities", status = "neutral")
    ),
    if (!is.null(actions)) actions,
    if (!is.null(result)) ui_disclosure(
      "Latest GenAI Output",
      tagList(
        if (!is.null(result$metadata$telemetry)) {
          render_table(
            data.table::data.table(
              metric = c("Context strategy", "Estimated input tokens", "Reported input tokens", "Latency ms", "Provider", "Model"),
              value = c(
                result$metadata$telemetry$context_strategy %||% "",
                as.character(result$metadata$telemetry$estimated_input_tokens %||% NA_integer_),
                as.character(result$metadata$telemetry$reported_input_tokens %||% NA_integer_),
                as.character(result$metadata$telemetry$latency_ms %||% NA_real_),
                result$metadata$telemetry$provider %||% "",
                result$metadata$telemetry$model %||% ""
              )
            ),
            engine = "html",
            searchable = FALSE,
            sortable = FALSE
          )
        },
        tags$pre(class = "aq-genai-output", result$value$text %||% service_result_message(result))
      ),
      open = TRUE,
      level = "common"
    )
  )
}

qa_genai_service_contract <- function() {
  genai <- if (file.exists(file.path("R", "genai_service.R"))) paste(readLines(file.path("R", "genai_service.R"), warn = FALSE), collapse = "\n") else ""
  actions <- if (file.exists(file.path("R", "genai_actions.R"))) paste(readLines(file.path("R", "genai_actions.R"), warn = FALSE), collapse = "\n") else ""
  app <- if (file.exists("app.R")) paste(readLines("app.R", warn = FALSE), collapse = "\n") else ""
  app_server <- if (file.exists(file.path("R", "app_server.R"))) paste(readLines(file.path("R", "app_server.R"), warn = FALSE), collapse = "\n") else ""
  mission <- if (file.exists(file.path("R", "page_mission_control.R"))) paste(readLines(file.path("R", "page_mission_control.R"), warn = FALSE), collapse = "\n") else ""
  studio <- if (file.exists(file.path("R", "page_artifact_library.R"))) paste(readLines(file.path("R", "page_artifact_library.R"), warn = FALSE), collapse = "\n") else ""
  project <- if (file.exists(file.path("R", "page_project.R"))) paste(readLines(file.path("R", "page_project.R"), warn = FALSE), collapse = "\n") else ""
  docs <- if (file.exists(file.path("docs", "genai_service_architecture.md"))) paste(readLines(file.path("docs", "genai_service_architecture.md"), warn = FALSE), collapse = "\n") else ""
  research_docs <- if (file.exists(file.path("docs", "genai_context_strategy_research.md"))) paste(readLines(file.path("docs", "genai_context_strategy_research.md"), warn = FALSE), collapse = "\n") else ""
  has <- function(text, patterns) all(vapply(patterns, grepl, logical(1), x = text, fixed = TRUE))

  registry <- genai_provider_registry()
  mock_config <- genai_config(provider = "mock")
  none_status <- genai_provider_status(genai_config(provider = "none"))
  mock_status <- genai_provider_status(mock_config, check_availability = TRUE)
  mock_chat <- genai_chat(list(list(role = "user", content = "Summarize artifact metadata.")), config = mock_config)
  mock_telemetry <- genai_generate_with_telemetry(
    "Summarize artifact metadata.",
    config = mock_config,
    context_strategy = "caption_metadata",
    included_components = genai_context_strategy("caption_metadata")$included_components,
    call_type = "qa"
  )
  unavailable <- genai_chat(list(list(role = "user", content = "x")), config = genai_config(provider = "none"))
  payload <- genai_ollama_chat_payload(
    list(list(role = "user", content = "hello")),
    genai_config(provider = "ollama", model = "llama3.1", temperature = 0.1, max_tokens = 123L)
  )
  normalized <- genai_normalize_response(list(message = list(content = "hello")), provider_id = "mock", model = "mock-model")
  normalized_tokens <- genai_normalize_response(list(response = "hello", prompt_eval_count = 42L), provider_id = "mock", model = "mock-model")
  strategy_names <- names(genai_context_strategy_registry())
  telemetry <- mock_telemetry$metadata$telemetry %||% list()
  telemetry_fields <- c(
    "context_strategy", "included_components", "estimated_input_tokens",
    "reported_input_tokens", "estimated_output_tokens", "reported_output_tokens",
    "total_estimated_tokens", "latency_ms", "provider", "model",
    "output_quality_score", "accuracy_score", "user_rating",
    "image_payload_used", "image_payload_count", "image_payload_bytes",
    "image_payload_format", "image_reference_only", "vision_model_detected",
    "vision_capability_declared", "vision_capability_verified", "vision_downgrade_reason"
  )

  data.table::data.table(
    check = c(
      "provider_abstraction",
      "provider_convenience_wrappers",
      "provider_diagnostics",
      "capability_normalization",
      "app_start_without_provider",
      "unavailable_degrades",
      "mock_provider",
      "ollama_payload",
      "response_normalization",
      "service_result_errors",
      "read_only_use_cases",
      "experiment_harness",
      "vision_support",
      "context_strategy_research",
      "context_policy",
      "context_strategy_registry",
      "action_layer_vertical_slice",
      "telemetry_fields",
      "token_latency_tracking",
      "quality_placeholders",
      "reported_token_normalization",
      "ui_status",
      "documentation"
    ),
    status = c(
      if (all(c("none", "mock", "ollama", "lm_studio", "llama_cpp", "openai_compatible") %in% names(registry))) "success" else "error",
      if (has(genai, c("genai_available <-", "genai_list_models <-", "genai_provider_status"))) "success" else "error",
      if (has(genai, c("genai_provider_diagnostics <-", "required_packages_available", "ollama_reachable", "missing_config_fields"))) "success" else "error",
      if (all(names(genai_capabilities()) %in% names(genai_normalize_capabilities(registry$ollama)))) "success" else "error",
      if (identical(none_status$status, "needs_input") && has(app, "genai_service.R")) "success" else "error",
      if (identical(unavailable$status, "needs_input")) "success" else "error",
      if (identical(mock_status$status, "success") && identical(mock_chat$status, "success")) "success" else "error",
      if (identical(payload$model, "llama3.1") && identical(payload$messages[[1]]$content, "hello") && identical(payload$options$num_predict, 123L)) "success" else "error",
      if (identical(normalized$status, "success") && identical(normalized$value$text, "hello")) "success" else "error",
      if (has(genai, c("tryCatch", "timeout", "service_result(status = \"error\""))) "success" else "error",
      if (has(genai, c("genai_summarize_artifact", "genai_brief_project", "genai_explain_alerts", "genai_suggest_next_action"))) "success" else "error",
      if (has(genai, c("run_genai_artifact_experiment", "build_genai_experiment_grid", "write_genai_experiment_results", "qa_genai_experiment_harness"))) "success" else "error",
      if (has(genai, c("genai_vision_payload", "run_genai_image_vs_data_experiment", "qa_genai_vision_support", "image_payload_used"))) "success" else "error",
      if (has(genai, c("run_genai_context_strategy_study", "recommend_context_strategy", "genai_infer_artifact_family", "genai_context_provenance"))) "success" else "error",
      if (has(genai, c("project metadata", "artifact captions", "Do not execute", "Do not invent")) || has(genai, c("genai_project_context", "genai_artifact_context", "sidecars"))) "success" else "error",
      if (all(c("screenshot_only", "caption_metadata", "screenshot_caption", "table_preview_only", "full_table", "screenshot_caption_preview", "structured_json_summary") %in% strategy_names)) "success" else "error",
      if (has(actions, c("genai_action_registry", "genai_validate_action_proposal", "genai_execute_action_proposal", "module.open"))) "success" else "error",
      if (all(telemetry_fields %in% names(telemetry))) "success" else "error",
      if (!is.na(telemetry$estimated_input_tokens) && !is.na(telemetry$latency_ms)) "success" else "error",
      if (all(c("output_quality_score", "accuracy_score", "user_rating") %in% names(telemetry))) "success" else "error",
      if (identical(normalized_tokens$metadata$reported_input_tokens, 42L)) "success" else "error",
      if (has(app_server, "genai_config") && has(mission, "Explain Alerts") && has(studio, "Summarize Artifact") && has(project, "Brief Project")) "success" else "error",
      if (has(docs, c("GenAI Service Architecture", "Information Transfer Efficiency", "Ollama", "LM Studio", "Agentic Lab")) && has(research_docs, c("GenAI Context Strategy Research", "Artifact Family", "Context Provenance"))) "success" else "error"
    ),
    message = c(
      "Provider registry exposes swappable adapters.",
      "Provider availability and model listing wrappers use the shared abstraction.",
      "Provider diagnostics report runtime, package, Ollama, model, and config status.",
      "Capabilities normalize to the standard contract.",
      "No configured provider is represented as needs_input, not startup failure.",
      "Unavailable or unconfigured providers degrade through service_result.",
      "Mock provider supports deterministic QA.",
      "Ollama chat payload uses the provider contract.",
      "Provider responses normalize to text plus raw payload.",
      "Errors and timeouts are wrapped in service_result-style outputs.",
      "Initial read-only use cases are implemented.",
      "Reusable GenAI artifact experiment harness is implemented.",
      "Local vision-model image-vs-data experiment support is implemented.",
      "Plot-type-aware context strategy research framework is implemented.",
      "Context builders avoid full dataset dumps by default.",
      "Named context strategies support representation comparison experiments.",
      "GenAI action layer exposes registered proposal validation and approved execution.",
      "GenAI results record the required information-transfer telemetry fields.",
      "Estimated token cost and latency are recorded for instrumented calls.",
      "Output quality, accuracy, and user rating placeholders are present.",
      "Reported provider input token counts are normalized when available.",
      "Mission Control, Artifact Studio, and Project Workspace expose GenAI status/actions.",
      "GenAI service and context strategy research documentation exists."
    )
  )
}
