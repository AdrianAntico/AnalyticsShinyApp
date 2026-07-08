page_code_runner_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Code Runner",
    ui_page(
      title = "Code Runner",
      subtitle = "Trusted local execution prototype for manually entered R code.",
      tags$div(
        class = "aq-export-layout",
        ui_card(
          title = "Code Workspace",
          ui_empty_state(
            "Trusted local execution is off by default.",
            "Enable trusted local execution in the policy panel to run code. This is not sandboxed."
          ),
          textInput(ns("code_run_label"), "Label", value = "Untitled Code Run"),
          selectInput(
            ns("code_run_source"),
            "Source",
            choices = c("Manual" = "manual", "GenAI" = "genai", "Module" = "module", "Rerun" = "rerun"),
            selected = "manual"
          ),
          textAreaInput(
            ns("code_editor_text"),
            "Code",
            value = "",
            rows = 12,
            width = "100%",
            placeholder = "Write R code to save as a tracked request. It will not be executed."
          ),
          selectInput(ns("selected_run_id"), "Selected Run", choices = character()),
          ui_action_row(
            actionButton(ns("save_draft_run"), "Save Draft Run", class = "btn-primary"),
            actionButton(ns("run_code"), "Run Code", class = "btn-success"),
            actionButton(ns("duplicate_run"), "Duplicate Run", class = "btn-secondary"),
            actionButton(ns("rerun_selected"), "Rerun Selected", class = "btn-success"),
            actionButton(ns("mark_approved"), "Mark Approved", class = "btn-secondary"),
            actionButton(ns("mark_rejected"), "Mark Rejected", class = "btn-secondary"),
            actionButton(ns("clear_editor"), "Clear Editor", class = "btn-secondary")
          ),
          textOutput(ns("code_runner_message"))
        ),
        ui_card(
          title = "Execution Policy",
          checkboxInput(ns("policy_enabled"), "Code Execution Enabled", value = FALSE),
          selectInput(
            ns("policy_mode"),
            "Execution Mode",
            choices = code_execution_modes(),
            selected = "disabled"
          ),
          checkboxInput(ns("policy_allow_manual"), "Allow Manual Code", value = FALSE),
          checkboxInput(ns("policy_allow_genai"), "Allow GenAI Code", value = FALSE),
          checkboxInput(ns("policy_require_genai_approval"), "Require Approval For GenAI Code", value = TRUE),
          checkboxInput(ns("policy_file_read"), "Allow File Read", value = FALSE),
          checkboxInput(ns("policy_file_write"), "Allow File Write", value = FALSE),
          checkboxInput(ns("policy_network"), "Allow Network", value = FALSE),
          checkboxInput(ns("policy_package_install"), "Allow Package Install", value = FALSE),
          checkboxInput(ns("policy_system_calls"), "Allow System Calls", value = FALSE),
          numericInput(ns("policy_max_runtime"), "Max Runtime Seconds", value = 30, min = 1, step = 1),
          numericInput(ns("policy_max_memory"), "Max Memory MB", value = 1024, min = 1, step = 1),
          ui_action_row(
            actionButton(ns("update_policy"), "Update Policy", class = "btn-secondary")
          ),
          uiOutput(ns("policy_status"))
        )
      ),
      ui_card(
        title = "Code History",
        uiOutput(ns("code_history"))
      ),
      ui_card(
        title = "Run Details",
        textInput(ns("selected_run_label"), "Run Label", value = ""),
        textAreaInput(ns("selected_run_notes"), "Notes", value = "", rows = 3, width = "100%"),
        ui_action_row(
          actionButton(ns("update_run_metadata"), "Update Run Label / Notes", class = "btn-secondary")
        ),
        uiOutput(ns("run_details")),
        ui_action_row(
          actionButton(ns("preview_run_details"), "Preview Run Details", class = "btn-secondary"),
          actionButton(ns("create_artifact_from_output"), "Create Artifact from Output", class = "btn-primary")
        )
      )
    )
  )
}

page_code_runner_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    local_message <- reactiveVal("")
    preview_run_id <- reactiveVal(NULL)

    current_policy_from_inputs <- function() {
      create_code_execution_policy(
        code_execution_enabled = isTRUE(input$policy_enabled),
        execution_mode = selected_value(input$policy_mode) %||% "disabled",
        allow_manual_code = isTRUE(input$policy_allow_manual),
        allow_genai_code = isTRUE(input$policy_allow_genai),
        require_approval_for_genai_code = isTRUE(input$policy_require_genai_approval),
        allow_file_read = isTRUE(input$policy_file_read),
        allow_file_write = isTRUE(input$policy_file_write),
        allow_network = isTRUE(input$policy_network),
        allow_package_install = isTRUE(input$policy_package_install),
        allow_system_calls = isTRUE(input$policy_system_calls),
        max_runtime_seconds = input$policy_max_runtime %||% 30,
        max_memory_mb = input$policy_max_memory %||% 1024
      )
    }

    refresh_run_choices <- function(selected = NULL) {
      choices <- names(ctx$code_runner_state$records)
      updateSelectInput(
        session,
        "selected_run_id",
        choices = choices,
        selected = selected %||% isolate(input$selected_run_id) %||% if (length(choices)) choices[[1]] else character()
      )
    }

    trusted_execution_enabled <- function(policy = ctx$code_runner_state$policy) {
      isTRUE(policy$code_execution_enabled) &&
        identical(policy$execution_mode, "local_trusted") &&
        isTRUE(policy$allow_manual_code)
    }

    selected_or_new_run_id <- function() {
      selected <- selected_value(input$selected_run_id)
      if (!is.null(selected) && selected %in% names(ctx$code_runner_state$requests)) {
        return(selected)
      }

      ctx$next_code_run_id()
    }

    build_editor_request <- function(status = "draft") {
      policy <- ctx$code_runner_state$policy
      source <- selected_value(input$code_run_source) %||% "manual"
      run_id <- selected_or_new_run_id()
      create_code_run_request(
        run_id = run_id,
        label = selected_value(input$code_run_label) %||% run_id,
        code = input$code_editor_text %||% "",
        source = source,
        execution_mode = policy$execution_mode,
        requested_outputs = character(),
        context = list(data_name = ctx$current_data_name()),
        requires_approval = identical(source, "genai") && isTRUE(policy$require_approval_for_genai_code),
        status = status
      )
    }

    run_request_with_policy <- function(request) {
      policy <- ctx$code_runner_state$policy
      if (!trusted_execution_enabled(policy)) {
        return(service_result(
          status = "error",
          errors = "Enable trusted local execution in the policy panel to run code.",
          value = create_code_run_result(run_id = request$run_id, status = "error", errors = "Enable trusted local execution in the policy panel to run code.")
        ))
      }
      if (!identical(request$source, "manual") && !identical(request$source, "rerun")) {
        return(service_result(
          status = "error",
          errors = "Only manually entered code and reruns can execute in this prototype.",
          value = create_code_run_result(run_id = request$run_id, status = "error", errors = "Only manually entered code and reruns can execute in this prototype.")
        ))
      }

      ctx$code_runner_state$requests[[request$run_id]] <- request
      upsert_code_record(request, status = "running")
      refresh_run_choices(selected = request$run_id)
      result <- run_code_local_trusted(
        request = request,
        data_context = list(data = tryCatch(ctx$uploaded_data(), error = function(e) NULL)),
        artifact_context = list(artifacts = ctx$all_artifacts()),
        policy = policy
      )

      code_result <- result$value
      if (inherits(code_result, "aq_code_run_result")) {
        ctx$code_runner_state$results[[request$run_id]] <- code_result
        request$status <- code_result$status
        request$updated_at <- Sys.time()
        ctx$code_runner_state$requests[[request$run_id]] <- request
        record <- upsert_code_record(request, status = code_result$status, result = code_result)
        record$metadata <- record$metadata %||% list()
        record$metadata$parent_run_id <- request$context$parent_run_id %||% NULL
        ctx$code_runner_state$records[[request$run_id]] <- record
      }

      preview_run_id(request$run_id)
      result
    }

    upsert_code_record <- function(request, status = request$status, result = NULL) {
      existing <- ctx$code_runner_state$records[[request$run_id]]
      if (is.null(existing)) {
        existing <- create_code_tracker_record(
          run_id = request$run_id,
          label = request$label,
          code = request$code,
          source = request$source,
          status = status,
          data_name = request$context$data_name,
          metadata = list(context = request$context %||% list())
        )
      }

      existing$label <- request$label
      existing$code <- request$code
      existing$code_hash <- code_hash_value(request$code)
      existing$source <- request$source
      existing$status <- status
      existing$data_name <- request$context$data_name
      existing$metadata <- existing$metadata %||% list()
      existing$metadata$context <- request$context %||% existing$metadata$context %||% list()
      if (isTRUE(request$context$custom_code_hook)) {
        existing$metadata$custom_code_hook <- TRUE
        existing$metadata$workflow_stage <- request$context$workflow_stage %||% NA_character_
        existing$metadata$hook_timing <- request$context$hook_timing %||% NA_character_
      }
      if (!is.null(result)) {
        existing$started_at <- result$started_at
        existing$ended_at <- result$ended_at
        existing$runtime_seconds <- result$runtime_seconds
        existing$warnings_summary <- result$warnings %||% character()
        existing$errors_summary <- result$errors %||% character()
        existing$artifact_ids <- result$artifact_ids %||% existing$artifact_ids %||% character()
      }

      ctx$code_runner_state$records[[existing$run_id]] <- existing
      ctx$code_runner_state$selected_run_id <- existing$run_id
      existing
    }

    observe({
      refresh_run_choices()
    })

    observeEvent(input$selected_run_id, {
      run_id <- selected_value(input$selected_run_id)
      record <- ctx$code_runner_state$records[[run_id]]
      if (is.null(record)) {
        return(invisible(NULL))
      }
      updateTextInput(session, "selected_run_label", value = record$label %||% "")
      updateTextAreaInput(session, "selected_run_notes", value = record$metadata$notes %||% "")
    }, ignoreInit = TRUE)

    output$code_runner_message <- renderText({
      ctx$code_runner_message() %||% local_message()
    })

    output$policy_status <- renderUI({
      validation <- validate_code_execution_policy(ctx$code_runner_state$policy)
      status <- if (identical(validation$status, "success")) "success" else "error"
      tags$div(
        ui_status_badge(validation$status, status = status),
        tags$p(class = "aq-export-message", service_result_message(validation)),
        if (!trusted_execution_enabled()) {
          tags$p(class = "aq-export-message", "Enable trusted local execution in the policy panel to run code.")
        } else {
          tags$p(class = "aq-export-message", "Trusted local execution is enabled for manual code. This is not sandboxed.")
        }
      )
    })

    observeEvent(input$update_policy, {
      policy <- current_policy_from_inputs()
      validation <- validate_code_execution_policy(policy)
      if (identical(validation$status, "success")) {
        ctx$code_runner_state$policy <- policy
      }
      ctx$code_runner_message(service_result_message(validation))
    }, ignoreInit = TRUE)

    observeEvent(input$save_draft_run, {
      request <- build_editor_request(status = "draft")
      validation <- validate_code_run_request(request, ctx$code_runner_state$policy)
      if (!identical(validation$status, "success")) {
        ctx$code_runner_message(service_result_message(validation))
        return(invisible(NULL))
      }

      ctx$add_code_run_request(request)
      record <- upsert_code_record(request, status = "draft")
      ctx$add_code_tracker_record(record)
      refresh_run_choices(selected = request$run_id)
      ctx$code_runner_message(paste("Saved draft code run:", request$label))
    }, ignoreInit = TRUE)

    observeEvent(input$run_code, {
      policy <- ctx$code_runner_state$policy
      if (!trusted_execution_enabled(policy)) {
        ctx$code_runner_message("Enable trusted local execution in the policy panel to run code.")
        return(invisible(NULL))
      }

      request <- build_editor_request(status = "running")
      if (!identical(request$source, "manual")) {
        ctx$code_runner_message("Only manually entered code can run in this prototype.")
        return(invisible(NULL))
      }

      result <- run_request_with_policy(request)
      ctx$code_runner_message(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$duplicate_run, {
      run_id <- selected_value(input$selected_run_id)
      original <- ctx$code_runner_state$requests[[run_id]]
      if (is.null(original)) {
        ctx$code_runner_message("Select a code run to duplicate.")
        return(invisible(NULL))
      }

      duplicate <- duplicate_code_run_request(
        request = original,
        run_id = ctx$next_code_run_id(),
        label = paste0(original$label %||% run_id, " Copy"),
        source = "rerun",
        status = "draft",
        parent_run_id = run_id
      )
      ctx$add_code_run_request(duplicate)
      record <- create_code_tracker_record(
        run_id = duplicate$run_id,
        label = duplicate$label,
        code = duplicate$code,
        source = duplicate$source,
        status = "draft",
        data_name = duplicate$context$data_name,
        metadata = list(parent_run_id = run_id)
      )
      ctx$add_code_tracker_record(record)
      updateTextInput(session, "code_run_label", value = duplicate$label)
      updateSelectInput(session, "code_run_source", selected = duplicate$source)
      updateTextAreaInput(session, "code_editor_text", value = paste(duplicate$code, collapse = "\n"))
      refresh_run_choices(selected = duplicate$run_id)
      preview_run_id(duplicate$run_id)
      ctx$code_runner_message(paste("Duplicated code run:", duplicate$label))
    }, ignoreInit = TRUE)

    observeEvent(input$rerun_selected, {
      run_id <- selected_value(input$selected_run_id)
      original <- ctx$code_runner_state$requests[[run_id]]
      if (is.null(original)) {
        ctx$code_runner_message("Select a code run to rerun.")
        return(invisible(NULL))
      }

      rerun_request <- duplicate_code_run_request(
        request = original,
        run_id = ctx$next_code_run_id(),
        label = paste0(original$label %||% run_id, " Rerun"),
        source = "rerun",
        status = "running",
        parent_run_id = run_id
      )
      result <- run_request_with_policy(rerun_request)
      ctx$code_runner_message(service_result_message(result))
    }, ignoreInit = TRUE)

    update_selected_status <- function(status) {
      run_id <- selected_value(input$selected_run_id)
      if (is.null(run_id)) {
        ctx$code_runner_message("Select a code run first.")
        return(invisible(FALSE))
      }

      if (!run_id %in% names(ctx$code_runner_state$requests)) {
        ctx$code_runner_message(paste("Code run request was not found:", run_id))
        return(invisible(FALSE))
      }

      request <- ctx$code_runner_state$requests[[run_id]]
      request$status <- status
      request$updated_at <- Sys.time()
      ctx$code_runner_state$requests[[run_id]] <- request

      record <- ctx$code_runner_state$records[[run_id]]
      if (!is.null(record)) {
        record$status <- status
        ctx$code_runner_state$records[[run_id]] <- record
      }

      ctx$code_runner_message(paste("Marked code run", run_id, "as", status))
      invisible(TRUE)
    }

    observeEvent(input$mark_approved, {
      update_selected_status("approved")
    }, ignoreInit = TRUE)

    observeEvent(input$update_run_metadata, {
      run_id <- selected_value(input$selected_run_id)
      if (is.null(run_id)) {
        ctx$code_runner_message("Select a code run first.")
        return(invisible(NULL))
      }
      record <- ctx$code_runner_state$records[[run_id]]
      request <- ctx$code_runner_state$requests[[run_id]]
      if (is.null(record)) {
        ctx$code_runner_message(paste("Code tracker record was not found:", run_id))
        return(invisible(NULL))
      }

      record <- update_code_tracker_record_metadata(
        record,
        label = selected_value(input$selected_run_label),
        notes = input$selected_run_notes %||% ""
      )
      ctx$code_runner_state$records[[run_id]] <- record
      if (!is.null(request)) {
        request$label <- record$label
        request$updated_at <- Sys.time()
        ctx$code_runner_state$requests[[run_id]] <- request
      }
      ctx$code_runner_message(paste("Updated code run metadata:", record$label))
    }, ignoreInit = TRUE)

    observeEvent(input$mark_rejected, {
      update_selected_status("rejected")
    }, ignoreInit = TRUE)

    observeEvent(input$clear_editor, {
      updateTextInput(session, "code_run_label", value = "Untitled Code Run")
      updateTextAreaInput(session, "code_editor_text", value = "")
      ctx$code_runner_message("Editor cleared.")
    }, ignoreInit = TRUE)

    output$code_history <- renderUI({
      summary <- ctx$code_tracker_summary()
      if (!nrow(summary)) {
        return(ui_empty_state("No code runs have been saved yet."))
      }

      render_table(summary, engine = "html", page_size = 10, searchable = FALSE, sortable = FALSE)
    })

    observeEvent(input$preview_run_details, {
      preview_run_id(selected_value(input$selected_run_id))
    }, ignoreInit = TRUE)

    output$run_details <- renderUI({
      run_id <- preview_run_id() %||% selected_value(input$selected_run_id)
      if (is.null(run_id)) {
        return(ui_empty_state("Select a code run to preview it."))
      }

      record <- ctx$code_runner_state$records[[run_id]]
      request <- ctx$code_runner_state$requests[[run_id]]
      if (is.null(record) && is.null(request)) {
        return(ui_empty_state("Code run was not found."))
      }

      code_text <- if (!is.null(record)) record$code else request$code
      result <- ctx$code_runner_state$results[[run_id]]
      status <- (record$status %||% request$status) %||% ""
      status_type <- switch(
        status,
        success = "success",
        warning = "warning",
        error = "error",
        rejected = "error",
        cancelled = "warning",
        running = "info",
        approved = "info",
        draft = "neutral",
        "neutral"
      )
      tags$div(
        class = "aq-code-run-details",
        ui_status_badge(status, status = status_type),
        tags$dl(
          tags$dt("Run ID"), tags$dd(run_id),
          tags$dt("Label"), tags$dd((record$label %||% request$label) %||% ""),
          tags$dt("Source"), tags$dd((record$source %||% request$source) %||% ""),
          tags$dt("Status"), tags$dd(status),
          tags$dt("Code Hash"), tags$dd(record$code_hash %||% ""),
          tags$dt("Runtime Seconds"), tags$dd(as.character(round(record$runtime_seconds %||% result$runtime_seconds %||% NA_real_, 4))),
          tags$dt("Parent Run ID"), tags$dd(record$metadata$parent_run_id %||% request$context$parent_run_id %||% ""),
          tags$dt("Notes"), tags$dd(record$metadata$notes %||% ""),
          tags$dt("Artifacts"), tags$dd(render_code_run_artifact_links(record$artifact_ids %||% character(), ctx$all_artifacts())),
          tags$dt("Warnings"), tags$dd(paste(record$warnings_summary %||% character(), collapse = " ")),
          tags$dt("Errors"), tags$dd(paste(record$errors_summary %||% character(), collapse = " "))
        ),
        render_code_run_result_preview(result),
        ui_code_panel(
          "Code Text",
          tags$pre(class = "aq-code-run-code", code_text %||% ""),
          collapsed = FALSE
        )
      )
    })

    observeEvent(input$create_artifact_from_output, {
      run_id <- selected_value(input$selected_run_id)
      if (is.null(run_id)) {
        ctx$code_runner_message("Select a code run first.")
        return(invisible(NULL))
      }

      result <- ctx$code_runner_state$results[[run_id]]
      record <- ctx$code_runner_state$records[[run_id]]
      if (is.null(result) || is.null(record)) {
        ctx$code_runner_message("Run output is not available for artifact conversion.")
        return(invisible(NULL))
      }

      candidates <- code_output_to_artifact_candidates(result$value, record)
      if (!length(candidates)) {
        ctx$code_runner_message("This code output cannot be converted into an artifact yet.")
        return(invisible(NULL))
      }

      added <- ctx$add_artifacts(candidates)
      artifact_ids <- names(candidates)
      record$artifact_ids <- unique(c(record$artifact_ids %||% character(), artifact_ids))
      ctx$code_runner_state$records[[run_id]] <- record
      result$artifact_ids <- unique(c(result$artifact_ids %||% character(), artifact_ids))
      result$artifacts <- c(result$artifacts %||% list(), candidates)
      ctx$code_runner_state$results[[run_id]] <- result
      ctx$code_runner_message(paste("Created", added, "artifact(s) from code output."))
    }, ignoreInit = TRUE)
  })
}

render_code_run_artifact_links <- function(artifact_ids, artifacts = list()) {
  if (!length(artifact_ids)) {
    return("No linked artifacts.")
  }

  tags$ul(lapply(artifact_ids, function(artifact_id) {
    artifact <- artifacts[[artifact_id]]
    label <- if (is.null(artifact)) artifact_id else paste0(artifact_id, " - ", artifact$label %||% artifact_id)
    tags$li(label)
  }))
}

render_code_run_value <- function(value) {
  if (is.null(value)) {
    return(ui_empty_state("No returned value."))
  }

  if (data.table::is.data.table(value) || is.data.frame(value)) {
    return(render_table(data.table::as.data.table(utils::head(value, 25L)), engine = "html"))
  }

  if (inherits(value, "htmlwidget")) {
    return(htmltools::tagList(value))
  }

  if (is.character(value)) {
    return(tags$pre(paste(value, collapse = "\n")))
  }

  if (is.numeric(value) || is.logical(value)) {
    return(render_table(data.table::data.table(value = as.character(value)), engine = "html"))
  }

  tags$pre(.code_runner_value_summary(value))
}

render_code_run_result_preview <- function(result) {
  if (is.null(result)) {
    return(ui_empty_state("No run result has been captured yet."))
  }

  tags$div(
    class = "aq-code-run-result",
    tags$h3(class = "aq-card-title", "Run Output"),
    tags$dl(
      tags$dt("Status"), tags$dd(result$status %||% ""),
      tags$dt("Runtime Seconds"), tags$dd(as.character(round(result$runtime_seconds %||% NA_real_, 4))),
      tags$dt("Printed Output"), tags$dd(tags$pre(paste(result$logs %||% character(), collapse = "\n"))),
      tags$dt("Warnings"), tags$dd(tags$pre(paste(result$warnings %||% character(), collapse = "\n"))),
      tags$dt("Errors"), tags$dd(tags$pre(paste(result$errors %||% character(), collapse = "\n")))
    ),
    tags$h3(class = "aq-card-title", "Returned Value"),
    render_code_run_value(result$value)
  )
}

qa_code_runner_ui_state <- function() {
  state <- new.env(parent = emptyenv())
  state$policy <- create_code_execution_policy()
  state$requests <- list()
  state$results <- list()
  state$records <- list()
  state$selected_run_id <- NULL

  request <- create_code_run_request(
    run_id = "code_run_ui_001",
    label = "UI State QA",
    code = "head(data)",
    source = "manual",
    execution_mode = state$policy$execution_mode,
    status = "draft"
  )
  request_validation <- validate_code_run_request(request, state$policy)
  state$requests[[request$run_id]] <- request

  record <- create_code_tracker_record(
    run_id = request$run_id,
    label = request$label,
    code = request$code,
    source = request$source,
    status = request$status
  )
  state$records[[record$run_id]] <- record

  summary <- code_tracker_summary(state$records)
  policy <- create_code_execution_policy(
    code_execution_enabled = TRUE,
    execution_mode = "local_trusted",
    allow_manual_code = TRUE
  )
  run_request <- create_code_run_request(
    run_id = "code_run_ui_002",
    label = "UI Run QA",
    code = "1 + 1",
    source = "manual",
    execution_mode = "local_trusted",
    status = "running"
  )
  run_result <- run_code_local_trusted(run_request, policy = policy)
  data.table::data.table(
    check = c("request_valid", "record_added", "summary_rows", "local_trusted_service_available"),
    status = c(
      request_validation$status,
      if (length(state$records) == 1L) "success" else "error",
      if (nrow(summary) == 1L) "success" else "error",
      run_result$status
    ),
    message = c(
      service_result_message(request_validation),
      paste("Records:", length(state$records)),
      paste("Summary rows:", nrow(summary)),
      service_result_message(run_result)
    )
  )
}
