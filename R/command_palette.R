register_command <- function(registry, id, title, category, keywords = character(), icon = ">", action = list(), enabled = TRUE) {
  command <- list(
    id = id,
    title = title,
    category = category,
    keywords = keywords %||% character(),
    icon = icon,
    action = action,
    enabled = isTRUE(enabled)
  )
  registry[[id]] <- command
  registry
}

command_registry <- function() {
  registry <- list()
  registry <- register_command(registry, "open_guide", "Open Guide", "Navigation", c("guide", "mentor", "orientation", "start", "home", "next step"), "G", list(type = "navigate", target = "Guide"))
  registry <- register_command(registry, "open_evidence_review", "Open Evidence Review", "Working Context", c("evidence", "review", "decision", "sufficiency", "working context", "next action"), "ER", list(type = "navigate", target = "Evidence Review"))
  registry <- register_command(registry, "open_knowledge_library", "Open Knowledge Library", "Knowledge", c("knowledge", "library", "book", "docs", "ontology", "manifesto", "architecture"), "KL", list(type = "navigate", target = "Knowledge Library"))
  registry <- register_command(registry, "open_mission_control", "Open Mission Control", "Navigation", c("mission", "control", "status", "health", "operations"), "MC", list(type = "navigate", target = "Mission Control"))
  registry <- register_command(registry, "open_ai_runtime", "Open AI Runtime", "Developer", c("ai", "runtime", "compiled", "bundle", "operator", "model tier", "diagnostics"), "AIR", list(type = "navigate", target = "AI Runtime"))
  registry <- register_command(registry, "open_product_experience", "Open Product Experience Lab", "Developer", c("product", "experience", "demo", "scenario", "world", "playwright", "review"), "PX", list(type = "navigate", target = "Product Experience"))
  registry <- register_command(registry, "open_artifact_studio", "Open Artifact Studio", "Artifacts", c("artifact", "studio", "evidence", "gallery", "inspector"), "AS", list(type = "navigate", target = "Artifact Studio"))
  registry <- register_command(registry, "open_project", "Open Project", "Project", c("project", "workspace", "settings", "load", "save"), "P", list(type = "navigate", target = "Project"))
  registry <- register_command(registry, "open_data", "Open Data", "Project", c("data", "upload", "dataset", "source"), "D", list(type = "navigate", target = "Data"))
  registry <- register_command(registry, "open_workflow", "Open Workflow", "Navigation", c("workflow", "lifecycle", "stages", "readiness"), "W", list(type = "navigate", target = "Workflow"))
  registry <- register_command(registry, "open_analysis_modules", "Open Analysis Modules", "Analysis", c("analysis", "modules", "autoquant", "eda", "model readiness", "shap"), "AM", list(type = "navigate", target = "Analysis Modules"))
  registry <- register_command(registry, "open_semantic_intelligence", "Open Semantic Intelligence", "Decisions", c("semantic", "decision", "alternatives", "business intent", "optionality", "evidence"), "SI", list(type = "navigate", target = "Semantic Intelligence"))
  registry <- register_command(registry, "create_decision", "Create Decision", "Decisions", c("decision", "business question", "guided authoring", "context"), "D+", list(type = "navigate", target = "Semantic Intelligence"))
  registry <- register_command(registry, "add_decision_alternative", "Add Decision Alternative", "Decisions", c("alternative", "baseline", "competing alternative", "tradeoff"), "ALT", list(type = "navigate", target = "Semantic Intelligence"))
  registry <- register_command(registry, "attach_decision_evidence", "Attach Decision Evidence", "Decisions", c("evidence", "inbox", "artifact", "causal", "predictive"), "EV", list(type = "navigate", target = "Semantic Intelligence"))
  registry <- register_command(registry, "validate_decision", "Validate Decision", "Decisions", c("validate", "assessment", "blockers", "warnings"), "VAL", list(type = "navigate", target = "Semantic Intelligence"))
  registry <- register_command(registry, "run_decision_valuation", "Run Decision Valuation", "Decisions", c("valuation", "economics", "uncertainty", "recommendation"), "$", list(type = "navigate", target = "Semantic Intelligence"))
  registry <- register_command(registry, "freeze_evidence_package", "Freeze Evidence Package", "Decisions", c("evidence package", "freeze", "review package", "collector"), "PKG", list(type = "navigate", target = "Semantic Intelligence"))
  registry <- register_command(registry, "request_decision_review", "Request Decision Review", "Decisions", c("review", "reviewer", "scope", "deadline"), "REV", list(type = "navigate", target = "Semantic Intelligence"))
  registry <- register_command(registry, "record_decision_approval", "Record Decision Approval", "Decisions", c("approval", "authority", "conditions", "expiration"), "APP", list(type = "navigate", target = "Semantic Intelligence"))
  registry <- register_command(registry, "open_decision_queue", "Open Decision Work Queue", "Decisions", c("decision queue", "work queue", "mission control", "next action"), "DQ", list(type = "navigate", target = "Mission Control"))
  registry <- register_command(registry, "open_causal_intelligence", "Open Causal Intelligence", "Decisions", c("causal", "estimand", "identification", "dag", "adjustment", "intervention"), "CI", list(type = "navigate", target = "Causal Intelligence"))
  registry <- register_command(registry, "generate_eda", "Generate EDA", "Analysis", c("eda", "exploration", "summary", "diagnostics"), "EDA", list(type = "navigate", target = "Analysis Modules"))
  registry <- register_command(registry, "run_model_readiness", "Run Model Readiness", "Analysis", c("target analysis", "readiness", "leakage", "drift"), "MR", list(type = "navigate", target = "Analysis Modules"))
  registry <- register_command(registry, "run_shap", "Run SHAP", "Analysis", c("shap", "interpretability", "importance", "dependence"), "SH", list(type = "navigate", target = "Analysis Modules"))
  registry <- register_command(registry, "open_code_runner", "Open Code Runner", "Developer", c("code", "runner", "custom", "developer", "hooks"), "CR", list(type = "navigate", target = "Code Runner"))
  registry <- register_command(registry, "open_layout", "Open Layout Studio", "Reports", c("layout", "report", "story", "plan"), "LS", list(type = "navigate", target = "Layout"))
  registry <- register_command(registry, "open_reports", "Open Reports", "Reports", c("report", "reports", "layout", "story", "plan"), "R", list(type = "navigate", target = "Layout"))
  registry <- register_command(registry, "open_export", "Open Export", "Reports", c("export", "docx", "html", "download", "render"), "EX", list(type = "navigate", target = "Export"))
  registry <- register_command(registry, "generate_report", "Generate Report", "Reports", c("report", "generate", "export", "render"), "GR", list(type = "navigate", target = "Export"))
  registry <- register_command(registry, "open_collector", "Open Collector", "Project", c("collector", "manifest", "docx", "llm", "memory"), "C", list(type = "navigate", target = "Project"))
  registry <- register_command(registry, "open_qa", "Open QA", "QA", c("qa", "quality", "checks", "validation", "smoke"), "QA", list(type = "navigate", target = "Code Runner"))
  registry <- register_command(registry, "open_project_settings", "Open Project Settings", "Project", c("settings", "project", "bundle", "path"), "PS", list(type = "navigate", target = "Project"))
  registry
}

command_registry_table <- function(registry = command_registry()) {
  data.table::rbindlist(lapply(registry, function(command) {
    data.table::data.table(
      id = command$id,
      title = command$title,
      category = command$category,
      keywords = paste(command$keywords %||% character(), collapse = " "),
      icon = command$icon,
      action_type = command$action$type %||% NA_character_,
      target = command$action$target %||% NA_character_,
      enabled = isTRUE(command$enabled)
    )
  }), use.names = TRUE, fill = TRUE)
}

command_search <- function(query, registry = command_registry()) {
  commands <- command_registry_table(registry)
  commands[, order_index := seq_len(.N)]
  query <- tolower(trimws(query %||% ""))
  if (!nzchar(query)) {
    return(commands[enabled == TRUE][order(order_index)])
  }
  fuzzy_match <- function(text, pattern) {
    text <- tolower(text)
    pattern <- tolower(pattern)
    pos <- 1L
    for (char in strsplit(pattern, "", fixed = TRUE)[[1]]) {
      found <- regexpr(char, substr(text, pos, nchar(text)), fixed = TRUE)[[1]]
      if (found < 0L) return(FALSE)
      pos <- pos + found
    }
    TRUE
  }
  title <- tolower(commands$title)
  category <- tolower(commands$category)
  keywords <- tolower(commands$keywords)
  haystack <- paste(title, category, keywords)
  direct <- grepl(query, haystack, fixed = TRUE)
  fuzzy <- vapply(haystack, fuzzy_match, logical(1), pattern = query)
  commands[, score := data.table::fifelse(
    title == query | title == paste("open", query) | title == paste("run", query) | title == paste("generate", query),
    0L,
    data.table::fifelse(
      startsWith(title, query) | startsWith(title, paste("open", query)),
      5L,
      data.table::fifelse(
        grepl(query, title, fixed = TRUE),
        10L,
        data.table::fifelse(
          grepl(query, category, fixed = TRUE),
          20L,
          data.table::fifelse(
            grepl(query, keywords, fixed = TRUE),
            30L,
            data.table::fifelse(direct, 40L, 90L)
          )
        )
      )
    )
  )]
  commands[enabled == TRUE & (direct | fuzzy)][order(score, order_index)]
}

command_history <- function(history = character(), command_id = NULL, limit = 10L) {
  history <- history %||% character()
  if (!is.null(command_id) && nzchar(command_id)) {
    history <- c(command_id, setdiff(history, command_id))
  }
  utils::head(history, limit)
}

command_palette_item <- function(command, ns) {
  keywords <- paste(command$keywords %||% character(), collapse = " ")
  tags$button(
    type = "button",
    class = "aq-command-item",
    `data-command-id` = command$id,
    `data-command-title` = command$title,
    `data-command-category` = command$category,
    `data-command-keywords` = keywords,
    `data-command-enabled` = if (isTRUE(command$enabled)) "true" else "false",
    tags$span(class = "aq-command-icon", command$icon %||% ">"),
    tags$span(
      class = "aq-command-copy",
      tags$strong(command$title),
      tags$small(paste(command$category, keywords, sep = " | "))
    ),
    tags$kbd("Enter")
  )
}

ui_command_palette <- function(id, commands = command_registry()) {
  ns <- NS(id)
  command_items <- lapply(commands, command_palette_item, ns = ns)
  tags$div(
    id = ns("root"),
    class = "aq-command-palette-root",
    tags$button(
      type = "button",
      id = ns("launcher"),
      class = "aq-command-launcher",
      title = "Open Command Palette (Ctrl+Shift+P)",
      tags$span("Command"),
      tags$kbd("Ctrl+Shift+P")
    ),
    tags$div(
      id = ns("overlay"),
      class = "aq-command-overlay aq-command-overlay-hidden",
      `aria-hidden` = "true",
      tags$div(class = "aq-command-backdrop"),
      tags$section(
        class = "aq-command-panel",
        role = "dialog",
        `aria-modal` = "true",
        `aria-label` = "Global Command Palette",
        tags$header(
          class = "aq-command-header",
          tags$div(
            tags$p(class = "aq-command-eyebrow", "Command"),
            tags$h3("What do you want to do next?")
          ),
          tags$kbd("Esc")
        ),
        tags$input(
          id = ns("query"),
          class = "aq-command-input",
          type = "text",
          autocomplete = "off",
          spellcheck = "false",
          placeholder = "Type a command, page, module, artifact, report, or QA..."
        ),
        tags$div(
          class = "aq-command-body",
          tags$section(
            class = "aq-command-section aq-command-recent-section",
            tags$h4("Recent"),
            tags$div(id = ns("recent"), class = "aq-command-list aq-command-recent-list")
          ),
          tags$section(
            class = "aq-command-section",
            tags$h4("Suggestions"),
            tags$div(id = ns("suggestions"), class = "aq-command-list", command_items),
            tags$p(id = ns("empty"), class = "aq-command-empty", "No commands match this search.")
          )
        ),
        tags$footer(
          class = "aq-command-footer",
          tags$span(tags$kbd("Ctrl"), tags$kbd("Shift"), tags$kbd("P"), "Open"),
          tags$span(tags$kbd("Esc"), "Close"),
          tags$span(tags$kbd("\u2191"), tags$kbd("\u2193"), "Move"),
          tags$span(tags$kbd("Enter"), "Run")
        )
      )
    ),
    tags$script(HTML(sprintf(
      "(function() {
        const root = document.getElementById('%s');
        if (!root || root.dataset.initialized === 'true') return;
        root.dataset.initialized = 'true';
        const overlay = document.getElementById('%s');
        const launcher = document.getElementById('%s');
        const input = document.getElementById('%s');
        const suggestions = document.getElementById('%s');
        const recent = document.getElementById('%s');
        const empty = document.getElementById('%s');
        const executeInput = '%s';
        let activeIndex = 0;
        let recentIds = [];

        function allItems() {
          return Array.from(suggestions.querySelectorAll('.aq-command-item'));
        }

        function visibleItems() {
          return allItems().filter(item => item.style.display !== 'none' && item.dataset.commandEnabled === 'true');
        }

        function fuzzy(text, query) {
          text = (text || '').toLowerCase();
          query = (query || '').toLowerCase().trim();
          if (!query) return true;
          if (text.indexOf(query) >= 0) return true;
          let pos = 0;
          for (const ch of query) {
            pos = text.indexOf(ch, pos);
            if (pos < 0) return false;
            pos += 1;
          }
          return true;
        }

        function setActive(index) {
          const items = visibleItems();
          allItems().forEach(item => item.classList.remove('aq-command-item-active'));
          if (!items.length) {
            activeIndex = 0;
            return;
          }
          activeIndex = Math.max(0, Math.min(index, items.length - 1));
          items[activeIndex].classList.add('aq-command-item-active');
          items[activeIndex].scrollIntoView({ block: 'nearest' });
        }

        function renderRecent() {
          recent.innerHTML = '';
          const ids = recentIds.slice(0, 10);
          if (!ids.length) {
            const note = document.createElement('p');
            note.className = 'aq-command-recent-empty';
            note.textContent = 'No recent commands yet.';
            recent.appendChild(note);
            return;
          }
          ids.forEach(id => {
            const source = suggestions.querySelector('[data-command-id=\"' + CSS.escape(id) + '\"]');
            if (!source) return;
            const clone = source.cloneNode(true);
            clone.classList.remove('aq-command-item-active');
            clone.addEventListener('click', () => execute(id));
            recent.appendChild(clone);
          });
        }

        function scoreCommand(item, query) {
          query = (query || '').toLowerCase().trim();
          if (!query) return Number(item.dataset.commandOrder || 0);
          const title = (item.dataset.commandTitle || '').toLowerCase();
          const category = (item.dataset.commandCategory || '').toLowerCase();
          const keywords = (item.dataset.commandKeywords || '').toLowerCase();
          const haystack = [title, category, keywords].join(' ');
          if (title === query || title === 'open ' + query || title === 'run ' + query || title === 'generate ' + query) return 0;
          if (title.indexOf(query) === 0 || title.indexOf('open ' + query) === 0) return 5;
          if (title.indexOf(query) >= 0) return 10;
          if (category.indexOf(query) >= 0) return 20;
          if (keywords.indexOf(query) >= 0) return 30;
          if (haystack.indexOf(query) >= 0) return 40;
          return 90;
        }

        function filterCommands() {
          const query = input.value || '';
          let shown = 0;
          const ranked = allItems().map((item, index) => ({ item: item, index: index, score: scoreCommand(item, query) }));
          ranked.sort((a, b) => (a.score - b.score) || (a.index - b.index));
          ranked.forEach(entry => suggestions.appendChild(entry.item));
          ranked.forEach(entry => {
            const item = entry.item;
            const text = [item.dataset.commandTitle, item.dataset.commandCategory, item.dataset.commandKeywords].join(' ');
            const match = item.dataset.commandEnabled === 'true' && fuzzy(text, query);
            item.style.display = match ? '' : 'none';
            if (match) shown += 1;
          });
          empty.style.display = shown ? 'none' : 'block';
          setActive(0);
        }

        function openPalette() {
          overlay.classList.remove('aq-command-overlay-hidden');
          overlay.setAttribute('aria-hidden', 'false');
          input.value = '';
          filterCommands();
          renderRecent();
          window.setTimeout(() => input.focus(), 0);
        }

        function closePalette() {
          overlay.classList.add('aq-command-overlay-hidden');
          overlay.setAttribute('aria-hidden', 'true');
        }

        function execute(id) {
          if (!id) {
            const items = visibleItems();
            if (!items.length) return;
            id = items[activeIndex].dataset.commandId;
          }
          recentIds = [id].concat(recentIds.filter(existing => existing !== id)).slice(0, 10);
          if (window.Shiny) {
            Shiny.setInputValue(executeInput, { id: id, nonce: Date.now() }, { priority: 'event' });
          }
          closePalette();
        }

        launcher.addEventListener('click', openPalette);
        overlay.querySelector('.aq-command-backdrop').addEventListener('click', closePalette);
        input.addEventListener('input', filterCommands);
        allItems().forEach(item => item.addEventListener('click', () => execute(item.dataset.commandId)));

        document.addEventListener('keydown', function(event) {
          const isOpen = !overlay.classList.contains('aq-command-overlay-hidden');
          const key = event.key.toLowerCase();
          const openShortcut = (event.ctrlKey && event.shiftKey && key === 'p') || (event.ctrlKey && key === 'k');
          if (openShortcut) {
            event.preventDefault();
            openPalette();
            return;
          }
          if (!isOpen) return;
          if (event.key === 'Escape') {
            event.preventDefault();
            closePalette();
          } else if (event.key === 'ArrowDown') {
            event.preventDefault();
            setActive(activeIndex + 1);
          } else if (event.key === 'ArrowUp') {
            event.preventDefault();
            setActive(activeIndex - 1);
          } else if (event.key === 'Enter') {
            event.preventDefault();
            execute();
          }
        });
        renderRecent();
        filterCommands();
      })();",
      ns("root"),
      ns("overlay"),
      ns("launcher"),
      ns("query"),
      ns("suggestions"),
      ns("recent"),
      ns("empty"),
      ns("execute")
    )))
  )
}

command_palette_server <- function(id, navigation_session = NULL) {
  moduleServer(id, function(input, output, session) {
    recent_commands <- reactiveVal(character())
    commands <- command_registry()
    tab_session <- navigation_session %||% session

    observeEvent(input$execute, {
      command_id <- input$execute$id %||% input$execute
      command <- commands[[command_id]]
      if (is.null(command) || !isTRUE(command$enabled)) {
        return()
      }
      recent_commands(command_history(recent_commands(), command_id))
      action <- command$action %||% list()
      if (identical(action$type, "navigate") && !is.null(action$target)) {
        updateTabsetPanel(tab_session, "main_tabs", selected = action$target)
      }
    }, ignoreInit = TRUE)
  })
}

qa_command_palette <- function() {
  registry <- command_registry_table()
  app <- if (file.exists("app.R")) paste(readLines("app.R", warn = FALSE), collapse = "\n") else ""
  app_ui <- if (file.exists(file.path("R", "app_ui.R"))) paste(readLines(file.path("R", "app_ui.R"), warn = FALSE), collapse = "\n") else ""
  app_server <- if (file.exists(file.path("R", "app_server.R"))) paste(readLines(file.path("R", "app_server.R"), warn = FALSE), collapse = "\n") else ""
  palette <- if (file.exists(file.path("R", "command_palette.R"))) paste(readLines(file.path("R", "command_palette.R"), warn = FALSE), collapse = "\n") else ""
  css <- if (file.exists(file.path("www", "app.css"))) paste(readLines(file.path("www", "app.css"), warn = FALSE), collapse = "\n") else ""
  docs <- if (file.exists(file.path("docs", "command_palette_architecture.md"))) paste(readLines(file.path("docs", "command_palette_architecture.md"), warn = FALSE), collapse = "\n") else ""
  has <- function(text, patterns) all(vapply(patterns, grepl, logical(1), x = text, fixed = TRUE))
  expected <- c("open_mission_control", "open_ai_runtime", "open_product_experience", "open_artifact_studio", "open_project", "open_workflow", "open_analysis_modules", "open_semantic_intelligence", "create_decision", "attach_decision_evidence", "record_decision_approval", "open_decision_queue", "open_causal_intelligence", "open_layout", "open_export", "open_code_runner", "open_collector", "open_qa")

  data.table::data.table(
    check = c(
      "registry",
      "no_duplicate_command_ids",
      "expected_commands",
      "app_registration",
      "open_shortcuts",
      "close_shortcut",
      "keyboard_navigation",
      "search_filter",
      "search_ranking",
      "selection_execution",
      "history",
      "navigation_dispatch",
      "root_navigation_session",
      "styling",
      "suggestions_list_scroll",
      "documentation"
    ),
    status = c(
      if (nrow(registry) >= 10L && all(c("id", "title", "category", "keywords", "action_type", "target", "enabled") %in% names(registry))) "success" else "error",
      if (!anyDuplicated(registry$id)) "success" else "error",
      if (all(expected %in% registry$id)) "success" else "error",
      if (has(app, "command_palette.R") && has(app_ui, "ui_command_palette") && has(app_server, "command_palette_server")) "success" else "error",
      if (has(palette, c("ctrlKey && event.shiftKey && key === 'p'", "ctrlKey && key === 'k'"))) "success" else "error",
      if (has(palette, c("Escape", "closePalette"))) "success" else "error",
      if (has(palette, c("ArrowDown", "ArrowUp", "setActive"))) "success" else "error",
      if (has(palette, c("fuzzy", "filterCommands", "No commands match"))) "success" else "error",
      if (has(palette, c("scoreCommand", "data-command-title", "data-command-category"))) "success" else "error",
      if (has(palette, c("Enter", "Shiny.setInputValue", "executeInput"))) "success" else "error",
      if (has(palette, c("recentIds", "renderRecent", "recent_commands"))) "success" else "error",
      if (has(palette, c("updateTabsetPanel", "navigate", "target"))) "success" else "error",
      if (has(palette, c("navigation_session", "tab_session")) && has(app_server, "navigation_session = session")) "success" else "error",
      if (has(css, c(".aq-command-overlay", ".aq-command-panel", ".aq-command-item-active", ".aq-command-launcher"))) "success" else "error",
      if (has(css, c("grid-template-rows: auto auto minmax(0, 1fr) auto", ".aq-command-section:not(.aq-command-recent-section) .aq-command-list", "overflow-y: auto", "::-webkit-scrollbar-thumb"))) "success" else "error",
      if (has(docs, c("Command Palette", "registry", "Ctrl+Shift+P", "Future AI"))) "success" else "error"
    ),
    message = c(
      "Command registry exposes standard command metadata.",
      "Command ids are unique.",
      "Initial Phase 1 commands are registered.",
      "Command palette is sourced and mounted in app UI/server.",
      "Open shortcuts are wired.",
      "Escape close behavior is wired.",
      "Arrow-key navigation is wired.",
      "Fuzzy search and empty state are wired.",
      "Command search ranks direct page/action matches ahead of broad fuzzy matches.",
      "Enter/mouse execution dispatches to Shiny.",
      "Recent command history is maintained for the session.",
      "Navigation command dispatch is wired.",
      "Navigation uses the root tabset session from the app server.",
      "Command palette CSS selectors are present.",
      "Command palette scrolling is constrained to the suggestions list instead of the whole modal.",
      "Command palette architecture documentation exists."
    )
  )
}
