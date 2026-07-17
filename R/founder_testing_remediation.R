qa_founder_testing_remediation <- function() {
  read_file <- function(path) {
    if (!file.exists(path)) {
      return("")
    }
    paste(readLines(path, warn = FALSE), collapse = "\n")
  }

  has_all <- function(text, patterns) {
    all(vapply(patterns, function(pattern) grepl(pattern, text, fixed = TRUE), logical(1)))
  }

  project_page <- read_file(file.path("R", "page_project.R"))
  ui_components <- read_file(file.path("R", "ui_components.R"))
  storage <- read_file(file.path("R", "storage_architecture.R"))
  css <- read_file(file.path("www", "app.css"))

  normalized_windows_path <- tryCatch(
    storage_normalize_path("C:\\Users\\YourName\\Documents\\GitHub", must_work = FALSE),
    error = function(e) NA_character_
  )
  quoted_project_path <- tryCatch(
    normalize_project_load_path("\"C:\\Users\\YourName\\Documents\\GitHub\\demo_project.rds\""),
    error = function(e) NA_character_
  )

  checks <- data.table::data.table(
    check = c(
      "windows_backslash_workspace_paths",
      "quoted_windows_project_paths",
      "project_object_context_present",
      "project_tabs_removed",
      "chapter_pagination_present",
      "persistent_context_facts",
      "location_merged_into_lifecycle",
      "lifecycle_actions_grouped",
      "lifecycle_intent_first",
      "create_requires_valid_destination",
      "project_name_required_before_create",
      "open_autodiscovers_project_file",
      "single_primary_project_path",
      "project_file_demoted",
      "location_default_initialized_once",
      "provider_choices_explained",
      "provider_cards_are_controls",
      "project_is_primary_setup_object",
      "workspace_feedback_present",
      "recent_activity_promoted",
      "systems_are_compacted",
      "modeling_context_reframed",
      "collector_user_language",
      "genai_duplicate_guard",
      "genai_busy_feedback",
      "genai_escape_cleanup",
      "project_status_labels",
      "responsive_object_chapters",
      "choice_explainer_styles"
    ),
    status = c(
      if (is.character(normalized_windows_path) && grepl("/", normalized_windows_path, fixed = TRUE) && !grepl("\\\\", normalized_windows_path)) "success" else "error",
      if (is.character(quoted_project_path) && grepl("demo_project.rds$", quoted_project_path) && !grepl("\"", quoted_project_path, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c("project_persistent_context", "aq-project-object-context", "The Project", "project_chapter_surface"))) "success" else "error",
      if (!grepl("tabsetPanel", project_page, fixed = TRUE) && !grepl("project_intent", project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c("Project Chapters", "Lifecycle", "Current Project", "Activity", "Administration"))) "success" else "error",
      if (has_all(project_page, c("Project Location", "Dataset", "Evidence", "Next Action", "Recent Activity"))) "success" else "error",
      if (has_all(project_page, c("Project Location", "workspace_provider", "workspace_root", "lifecycle_create_state")) &&
          !grepl('value = "location"', project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c("Create Project", "Open Project", "Save Project", "Close Project", "Project is open"))) "success" else "error",
      if (has_all(project_page, c("lifecycle_intent", "Create New Project", "Open Existing Project", "1. Choose what you are doing"))) "success" else "error",
      if (has_all(project_page, c("lifecycle_create_state", "Confirm the Project Location.", "Confirm Project Location", "lifecycle_button(\"create_project\"", "enabled = isTRUE(create_state$ready) && !busy"))) "success" else "error",
      if (grepl('textInput(ns("project_name"), "Project Name", value = input$project_name %||% "")', project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c("lifecycle_open_state", "Existing project detected", "file.path(normalized, \"project.rds\")", "Open project file directly"))) "success" else "error",
      if (!grepl("Workspace ready", project_page, fixed = TRUE) && has_all(project_page, c("New project will be created at:", "Project Location", "Project destination"))) "success" else "error",
      if (!grepl('textInput\\(ns\\("project_path"\\), "Project File"', project_page) && grepl("Saved Project File", project_page, fixed = TRUE)) "success" else "error",
      if (!grepl('selected = "local_server_directory"', project_page, fixed = TRUE) &&
          grepl("selected = lifecycle_provider_selection()", project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c("ui_choice_explainer", "Local Folder", "Saved Location", "App-Managed Location", "Choose Location"))) "success" else "error",
      if (has_all(ui_components, c('type = "radio"', "aq-choice-explainer-card", "aq-choice-explainer-copy"))) "success" else "error",
      if (has_all(project_page, c("The Project", "Choose where the project lives", "Project is open", "Chapter 1: Lifecycle"))) "success" else "error",
      if (grepl("Project Location confirmed:", project_page, fixed = TRUE) && grepl("Project destination will be created", project_page, fixed = TRUE)) "success" else "error",
      if (grepl("Chapter 3: Activity", project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c("project_system_detail", "project_system_detail_panel", "Chapter 4: Administration", "technical_signals"))) "success" else "error",
      if (grepl('title = "Modeling Data"', project_page, fixed = TRUE) && !grepl("Active Modeling Context", project_page, fixed = TRUE)) "success" else "error",
      if (has_all(ui_components, c("Project Evidence Memory", "Generated evidence preserved for reports, review, and AI-ready project context."))) "success" else "error",
      if (grepl("recently_completed", project_page, fixed = TRUE) && grepl("genai_project_busy", project_page, fixed = TRUE)) "success" else "error",
      if (grepl("is running. Please wait before requesting another AI response.", project_page, fixed = TRUE)) "success" else "error",
      if (grepl("gsub(\"\\\\\\\\([[:punct:]])\"", project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c("File Location", "Evidence Memory", "Evidence Document", "Evidence Index")) && !grepl("Workspace provider", project_page, fixed = TRUE)) "success" else "error",
      if (grepl("aq-project-reference", project_page, fixed = TRUE) && grepl(".aq-project-object-context", css, fixed = TRUE) && grepl(".aq-project-chapter-surface", css, fixed = TRUE)) "success" else "error",
      if (has_all(css, c(".aq-choice-explainer", ".aq-choice-explainer-grid", ".aq-choice-explainer-card")))
        "success" else "error"
    ),
    message = c(
      "Workspace paths with Windows backslashes normalize through the storage path helper.",
      "Quoted Windows project paths are stripped and normalized before loading.",
      "Project page keeps one persistent project object summary visible above chapter changes.",
      "Project page no longer fragments the experience into internal tabs.",
      "Project page uses chapter pagination rather than a long stacked scroll model.",
      "Persistent context keeps location, data, evidence, next action, and recent activity visible.",
      "Project location is merged into project setup and management instead of being its own destination.",
      "Create, open, save, and close live together in the Lifecycle chapter.",
      "Lifecycle starts with create/open intent before any action is shown.",
      "Create Project remains disabled until location is confirmed and name resolves to a valid destination.",
      "Project Name starts blank so a confirmed location alone cannot create a project.",
      "Open Existing Project discovers project.rds from a selected project folder.",
      "The primary lifecycle flow shows one user-facing Project Location instead of competing path concepts.",
      "Project File is demoted from primary UI into an advanced saved-file disclosure.",
      "Project setup initializes location selection through one canonical provider contract.",
      "Opaque provider names are replaced with explained user-facing options.",
      "Provider explanation cards are the actual radio selection controls.",
      "The Project card appears before storage details in the setup hierarchy.",
      "Lifecycle confirms the selected Project Location before deriving and creating the destination.",
      "Recent Activity is promoted into the primary Project setup flow.",
      "Operational, AI, and technical systems are compacted behind one selected detail surface.",
      "The harmful Active Modeling Context copy is replaced by a simpler Modeling Data disclosure.",
      "Collector copy is reframed as project evidence memory on user-facing surfaces.",
      "Project-level GenAI actions guard against repeat clicks and queued duplicate requests.",
      "Project-level GenAI actions show an in-progress state while a request is running.",
      "Project-level GenAI result text removes common escaped punctuation artifacts.",
      "Project status table labels avoid internal workspace/provider/manifest phrasing.",
      "Project object context and chapters have responsive layout rules.",
      "Provider choice explanations are styled as reusable workstation components."
    ),
    recommendation = c(
      "Keep all future project path inputs routed through storage/project path normalization.",
      "Keep project load/save fields tolerant of pasted Windows paths.",
      "Use this page as the object/chapter reference pattern before sweeping the rest of the app.",
      "Do not reintroduce Project tabs; chapters should paginate one object instead.",
      "Keep chapters as complete mental tasks rather than implementation sections.",
      "Future primary objects should keep persistent context above chapter changes.",
      "Do not split location into a separate destination unless project setup becomes materially more complex.",
      "Avoid reintroducing duplicate lifecycle actions in unrelated regions.",
      "Keep create/open intent explicit so prerequisites stay obvious.",
      "Do not enable Create Project before Project Location confirmation and destination validation pass.",
      "Do not restore a default Project Name in the lifecycle setup flow.",
      "Keep direct project-file loading as advanced recovery rather than the primary open path.",
      "Keep workspace/provider/root details in technical depth unless users need them.",
      "Keep backend save/load file paths in advanced or technical disclosures.",
      "Do not hard-code Local Folder as selected; let the canonical provider selection initialize once.",
      "Avoid returning to an unexplained storage-provider dropdown.",
      "Keep choice cards and selection state visually unified.",
      "Keep workspace mechanics subordinate to project intent.",
      "Consider adding a transient toast after successful creation in a later UI pass.",
      "Continue using Recent Activity as the first place users check for confirmation.",
      "Keep operations as a toolbox that opens one detail at a time.",
      "Only expose lineage details inside advanced inspection surfaces.",
      "Reserve Project Artifact Collector wording for architecture docs and technical disclosures.",
      "If long GenAI calls become common, move them to the async job surface.",
      "Disable buttons in every long-running GenAI action surface.",
      "Prefer upstream response normalization if provider-specific escaping persists.",
      "Keep Manifest terminology hidden unless the user opens technical files.",
      "Retest at narrow, laptop, and ultrawide widths.",
      "Reuse this primitive for future small-choice settings that need explanation."
    )
  )

  checks
}

qa_project_location_selection <- function() {
  read_file <- function(path) {
    if (!file.exists(path)) {
      return("")
    }
    paste(readLines(path, warn = FALSE), collapse = "\n")
  }

  has_all <- function(text, patterns) {
    all(vapply(patterns, function(pattern) grepl(pattern, text, fixed = TRUE), logical(1)))
  }

  project_page <- read_file(file.path("R", "page_project.R"))
  ui_components <- read_file(file.path("R", "ui_components.R"))
  css <- read_file(file.path("www", "app.css"))
  registry <- storage_provider_registry(settings = list())
  choice_html <- as.character(htmltools::renderTags(ui_choice_explainer(
    "qa_location_type",
    "Location Type",
    choices = list(
      list(value = "unavailable", title = "Unavailable", description = "Unavailable option.", enabled = FALSE, unavailable_reason = "Unavailable reason."),
      list(value = "local_server_directory", title = "Local Folder", description = "Enabled option.", enabled = TRUE)
    ),
    selected = "unavailable"
  ))$html)

  data.table::data.table(
    check = c(
      "canonical_location_selection_reactive",
      "hard_coded_local_selection_removed",
      "location_choices_use_provider_availability",
      "unavailable_modes_disabled",
      "unavailable_reasons_visible",
      "provider_controlled_path_readonly",
      "visible_location_status_feedback",
      "local_folder_placeholder_only",
      "placeholder_does_not_enable_confirmation",
      "founder_specific_paths_absent_from_project_ui",
      "saved_project_restore_sets_real_location",
      "saved_location_disabled_without_saved_root",
      "managed_location_disabled_without_managed_root",
      "native_picker_disabled_without_host_picker",
      "choice_component_falls_back_to_enabled_choice",
      "disabled_choice_component_semantics",
      "disabled_choice_component_styles",
      "intent_switch_preserves_location_selection_contract",
      "no_legacy_duplicate_location_mode"
    ),
    status = c(
      if (has_all(project_page, c("lifecycle_provider_selection <- reactive", "lifecycle_location_input <- reactive", "provider_id <- lifecycle_provider_selection()"))) "success" else "error",
      if (!grepl('selected = "local_server_directory"', project_page, fixed = TRUE) && grepl("selected = lifecycle_provider_selection()", project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c("lifecycle_location_choices <- reactive", "lifecycle_provider_available", "storage_provider_registry()"))) "success" else "error",
      if (has_all(ui_components, c("choice$enabled", "disabled = if (!enabled) \"disabled\" else NULL", "aq-choice-explainer-card-disabled"))) "success" else "error",
      if (has_all(project_page, c("No saved Project Location exists yet", "No app-managed location is available in this environment.", "The host folder picker is not available in this environment."))) "success" else "error",
      if (has_all(project_page, c("data-provider-controlled", "readonly = \"readonly\"", "aria-readonly"))) "success" else "error",
      if (has_all(project_page, c("lifecycle_location_status_callout", "No project location selected yet", "Location entered", "Project location confirmed", "No real location value has been provided.", "Next:")) &&
          !grepl("Resolved location:", project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c('placeholder = "C:\\\\Users\\\\YourName\\\\Documents\\\\AnalyticsWorkstationProjects"', 'value = lifecycle_location_value()')) &&
          !grepl("updateTextInput(session, \"workspace_root\", value = workspace_root)", project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c('enabled = identical(location$source, "manual_entry")', "!is.null(location$normalized)", "Confirm Project Location"))) "success" else "error",
      if (!grepl("C:\\\\Users\\\\Bizon", project_page) && !grepl("AnalyticsWorkstationLifecycleQA", project_page, fixed = TRUE)) "success" else "error",
      if (has_all(project_page, c("project_location_confirmed(root_validation$value)", 'updateTextInput(session, "workspace_root", value = root_validation$value)', 'updateRadioButtons(', '"workspace_provider"'))) "success" else "error",
      if (!isTRUE(registry$configured_workspace$available) && is.null(registry$configured_workspace$root_path)) "success" else "warning",
      if (!isTRUE(registry$managed_workspace$available) && is.null(registry$managed_workspace$root_path)) "success" else "warning",
      if (!isTRUE(registry$native_host_directory$selection_supported) && !isTRUE(registry$native_host_directory$capabilities$native_directory_picker)) "success" else "warning",
      if (grepl('value="local_server_directory"', choice_html, fixed = TRUE) && grepl('checked="checked"', choice_html, fixed = TRUE) && !grepl('value="unavailable" checked="checked"', choice_html, fixed = TRUE)) "success" else "error",
      if (grepl('disabled="disabled"', choice_html, fixed = TRUE) && grepl('aria-disabled="true"', choice_html, fixed = TRUE) && grepl("Unavailable reason.", choice_html, fixed = TRUE)) "success" else "error",
      if (has_all(css, c(".aq-choice-explainer-card-disabled", "cursor: not-allowed", ".aq-choice-unavailable-reason"))) "success" else "error",
      if (has_all(project_page, c("lifecycle_intent <- input$lifecycle_intent %||% \"create\"", "selected = lifecycle_provider_selection()", "lifecycle_location_value()"))) "success" else "error",
      if (!grepl("project_location_mode", project_page, fixed = TRUE) && !grepl("location_type", project_page, fixed = TRUE)) "success" else "error"
    ),
    message = c(
      "Project Location type has one canonical reactive selection used by location resolution.",
      "The Project lifecycle no longer hard-codes Local Folder as selected on every render.",
      "Location choices are derived from the storage provider registry and availability.",
      "Unavailable visible options are disabled at the input level.",
      "Unavailable modes explain why they cannot be selected.",
      "Provider-controlled locations are displayed as read-only resolved locations.",
      "The lifecycle distinguishes no selection, entered-but-unconfirmed, and confirmed locations.",
      "Local Folder starts empty and uses neutral example text only as a placeholder.",
      "Placeholder-only state cannot enable Project Location confirmation.",
      "Project Location UI does not contain founder-specific or machine-specific default paths.",
      "Loaded projects restore a real path into the input and confirmed location state.",
      "In this runtime no saved Project Location is configured unless the settings file provides one.",
      "In this runtime no app-managed location is configured unless deployment provides one.",
      "In this runtime the host folder picker is unavailable unless explicitly provided.",
      "The choice component falls back to an enabled option when asked to select a disabled option.",
      "Disabled choice cards emit disabled input semantics and visible explanation.",
      "Disabled choice cards have explicit workstation styling.",
      "Changing Create/Open intent reuses the same canonical provider selection instead of resetting it.",
      "No duplicate project-location mode state was introduced."
    ),
    recommendation = c(
      "Keep all Project Location behavior routed through lifecycle_provider_selection().",
      "Never pass a literal selected provider to the Project Location choice group.",
      "Update storage provider capability metadata before exposing new location modes.",
      "Do not create selectable-looking cards for unavailable capabilities.",
      "Keep unavailable explanations visible on the card itself.",
      "Do not allow users to type into provider-owned path readouts unless that provider supports editing.",
      "Never use resolved-location language before a real path exists.",
      "Keep example paths in placeholder attributes only, never as input values.",
      "Do not enable confirmation from placeholder or empty Local Folder state.",
      "Use neutral examples in product-facing UI and deterministic temp paths in QA/browser fixtures.",
      "Treat loaded project paths as real state and restore them explicitly.",
      "If users need a default saved location, create it through the workspace settings path.",
      "If deployment provides managed storage, set ANALYTICS_WORKSTATION_MANAGED_WORKSPACE_ROOT.",
      "Only enable Choose Location when a real host picker is wired.",
      "Keep ui_choice_explainer honest for every future card-radio use.",
      "Disabled cards should remain non-interactive in browser validation.",
      "Preserve disabled styling across themes.",
      "Do not use intent changes as a reason to reset valid location choice.",
      "Avoid adding parallel location/provider/card state."
    )
  )
}
