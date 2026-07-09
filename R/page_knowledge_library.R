knowledge_library_safe_id <- function(path) {
  gsub("[^A-Za-z0-9_]+", "_", path %||% "document")
}

knowledge_library_repo_root <- function() {
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

knowledge_library_relpath <- function(path, root = knowledge_library_repo_root()) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root <- normalizePath(root, winslash = "/", mustWork = FALSE)
  sub(paste0("^", gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", root), "/?"), "", path)
}

knowledge_library_title_from_path <- function(path) {
  lines <- tryCatch(readLines(path, warn = FALSE, encoding = "UTF-8", n = 40L), error = function(e) character())
  heading <- grep("^#\\s+", lines, value = TRUE)
  if (length(heading)) {
    return(trimws(sub("^#\\s+", "", heading[[1]])))
  }
  tools::toTitleCase(gsub("[-_]+", " ", tools::file_path_sans_ext(basename(path))))
}

knowledge_library_read_markdown <- function(path) {
  if (is.null(path) || !file.exists(path)) {
    return("# Document unavailable\n\nThe selected document could not be found.")
  }
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

knowledge_library_markdown_html <- function(markdown_text) {
  if (requireNamespace("commonmark", quietly = TRUE)) {
    return(knowledge_library_add_heading_ids(commonmark::markdown_html(markdown_text, extensions = TRUE)))
  }
  escaped <- htmltools::htmlEscape(markdown_text)
  escaped <- gsub("^### (.*)$", "<h3>\\1</h3>", escaped, perl = TRUE)
  escaped <- gsub("^## (.*)$", "<h2>\\1</h2>", escaped, perl = TRUE)
  escaped <- gsub("^# (.*)$", "<h1>\\1</h1>", escaped, perl = TRUE)
  knowledge_library_add_heading_ids(paste("<pre>", escaped, "</pre>"))
}

knowledge_library_heading_slug <- function(label, index = 1L) {
  slug <- tolower(gsub("[^A-Za-z0-9]+", "-", label))
  slug <- gsub("(^-+|-+$)", "", slug)
  if (!nzchar(slug)) {
    slug <- paste0("section-", index)
  }
  slug
}

knowledge_library_heading_rows <- function(markdown_text, max_headings = 40L) {
  lines <- unlist(strsplit(markdown_text, "\n", fixed = TRUE))
  headings <- grep("^#{1,3}\\s+", lines, value = TRUE)
  if (!length(headings)) {
    return(data.table::data.table(level = integer(), label = character(), slug = character()))
  }
  headings <- utils::head(headings, max_headings)
  labels <- trimws(sub("^#{1,3}\\s+", "", headings))
  levels <- nchar(sub("^(#+).*", "\\1", headings))
  slugs <- knowledge_library_unique_slugs(labels)
  data.table::data.table(level = levels, label = labels, slug = slugs)
}

knowledge_library_unique_slugs <- function(labels) {
  seen <- character()
  vapply(seq_along(labels), function(index) {
    base <- knowledge_library_heading_slug(labels[[index]], index)
    slug <- base
    if (slug %in% seen) {
      suffix <- 2L
      while (paste0(base, "-", suffix) %in% seen) {
        suffix <- suffix + 1L
      }
      slug <- paste0(base, "-", suffix)
    }
    seen <<- c(seen, slug)
    slug
  }, character(1))
}

knowledge_library_add_heading_ids <- function(html) {
  matches <- gregexpr("<h([1-3])>(.*?)</h\\1>", html, perl = TRUE)[[1]]
  if (identical(matches[[1]], -1L)) {
    return(html)
  }
  pieces <- regmatches(html, list(matches))[[1]]
  labels <- gsub("<[^>]+>", "", sub("<h[1-3]>(.*?)</h[1-3]>", "\\1", pieces, perl = TRUE))
  slugs <- knowledge_library_unique_slugs(labels)
  replacements <- vapply(seq_along(pieces), function(index) {
    piece <- pieces[[index]]
    level <- sub("<h([1-3])>.*", "\\1", piece, perl = TRUE)
    slug <- slugs[[index]]
    sub(paste0("<h", level, ">"), paste0("<h", level, " id=\"", slug, "\">"), piece, fixed = TRUE)
  }, character(1))
  regmatches(html, list(matches)) <- list(replacements)
  html
}

knowledge_library_word_count <- function(text) {
  words <- unlist(strsplit(gsub("[^A-Za-z0-9']+", " ", text), "\\s+"))
  sum(nzchar(words))
}

knowledge_library_section_toc <- function(markdown_text) {
  headings <- knowledge_library_heading_rows(markdown_text)
  if (!nrow(headings)) {
    return(ui_empty_state("No table of contents.", "This document does not contain Markdown headings."))
  }
  tags$ol(
    class = "aq-library-toc-list",
    lapply(seq_len(nrow(headings)), function(index) {
      tags$li(
        class = paste0("aq-library-toc-level-", headings$level[[index]]),
        tags$a(href = paste0("#", headings$slug[[index]]), headings$label[[index]])
      )
    })
  )
}

knowledge_library_discover_documents <- function(root = knowledge_library_repo_root()) {
  existing <- function(paths) paths[file.exists(paths)]
  md_files <- function(path, recursive = FALSE) {
    if (!dir.exists(path)) {
      return(character())
    }
    list.files(path, pattern = "\\.md$", recursive = recursive, full.names = TRUE)
  }
  docs_md <- md_files(file.path(root, "docs"), recursive = TRUE)
  book_md <- md_files(file.path(root, "book", "source"), recursive = TRUE)
  source_chapters <- md_files(file.path(root, "book", "source", "chapters"), recursive = TRUE)
  source_packs <- md_files(file.path(root, "book", "source", "source_packs"), recursive = TRUE)

  category_paths <- list(
    Welcome = existing(c(
      file.path(root, "docs", "vision", "product_vision.md"),
      file.path(root, "book", "source", "philosophy_manifesto.md"),
      file.path(root, "docs", "architecture_synthesis.md")
    )),
    Book = unique(c(
      existing(c(
        file.path(root, "book", "source", "README.md"),
        file.path(root, "book", "source", "part_01_foundations.md"),
        file.path(root, "book", "source", "full_book_v0_overcomplete.md")
      )),
      source_chapters,
      setdiff(book_md, source_packs)
    )),
    Architecture = unique(c(
      docs_md[grepl("architecture|policy|strategy|routing|optimization|encoding|collector|artifact|genai|execution|guide|knowledge_library", basename(docs_md), ignore.case = TRUE)],
      existing(c(file.path(root, "docs", "architecture_synthesis.md"), file.path(root, "docs", "book_compiler_plan.md")))
    )),
    Concepts = existing(c(
      file.path(root, "book", "source", "concept_ontology.md"),
      file.path(root, "book", "source", "concept_dependency_graph.md"),
      file.path(root, "book", "source", "concept_relationship_matrix.md"),
      file.path(root, "book", "source", "concept_clusters.md"),
      file.path(root, "book", "source", "architecture_causality.md"),
      file.path(root, "book", "source", "analytical_intelligence_loop.md")
    )),
    Research = unique(c(
      md_files(file.path(root, "docs", "research"), recursive = TRUE),
      docs_md[grepl("research|calibration|experiment|study|sprint|audit", basename(docs_md), ignore.case = TRUE)]
    )),
    Experiments = unique(c(
      docs_md[grepl("experiment|study|qa|validation|smoke|plot_sizing|genai", basename(docs_md), ignore.case = TRUE)],
      md_files(file.path(root, "exports", "genai_experiments"), recursive = TRUE)
    )),
    Timeline = unique(c(
      existing(c(
        file.path(root, "book", "source", "architecture_causality.md"),
        file.path(root, "book", "source", "closed_loop_validation.md")
      )),
      source_packs[grepl("chronology|ledger|sequence|inventory", basename(source_packs), ignore.case = TRUE)]
    )),
    Roadmap = unique(c(
      md_files(file.path(root, "docs", "roadmap"), recursive = TRUE),
      docs_md[grepl("roadmap|backlog", basename(docs_md), ignore.case = TRUE)],
      file.path(root, "book", "source", "chapter_mapping.md")
    )),
    `Open Questions` = unique(c(
      book_md[grepl("open_questions|future|gaps|limitations", basename(book_md), ignore.case = TRUE)],
      docs_md[grepl("open|future|gap|limitation", basename(docs_md), ignore.case = TRUE)]
    ))
  )

  rows <- lapply(names(category_paths), function(category) {
    paths <- unique(normalizePath(category_paths[[category]], winslash = "/", mustWork = FALSE))
    paths <- paths[file.exists(paths)]
    if (!length(paths)) {
      return(NULL)
    }
    data.table::data.table(
      category = category,
      path = paths,
      relpath = vapply(paths, knowledge_library_relpath, character(1), root = root),
      title = vapply(paths, knowledge_library_title_from_path, character(1)),
      words = vapply(paths, function(path) knowledge_library_word_count(knowledge_library_read_markdown(path)), integer(1)),
      modified = as.character(file.info(paths)$mtime)
    )
  })
  docs <- data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
  if (!nrow(docs)) {
    return(data.table::data.table(category = character(), path = character(), relpath = character(), title = character(), words = integer(), modified = character()))
  }
  docs <- unique(docs, by = c("category", "path"))
  docs[order(match(category, names(category_paths)), title)]
}

knowledge_library_book_stats <- function(docs = knowledge_library_discover_documents(), root = knowledge_library_repo_root()) {
  book_docs <- docs[category == "Book"]
  ontology_path <- file.path(root, "book", "source", "concept_ontology.md")
  concept_count <- if (file.exists(ontology_path)) {
    sum(grepl("^###\\s+[0-9]+\\.", readLines(ontology_path, warn = FALSE, encoding = "UTF-8")))
  } else {
    0L
  }
  arch_docs <- docs[category == "Architecture"]
  total_words <- sum(book_docs$words %||% 0L, na.rm = TRUE)
  fmt_date <- function(value) {
    if (is.null(value) || length(value) == 0L || is.na(value) || !nzchar(value)) {
      return("unknown")
    }
    substr(as.character(value), 1, 10)
  }
  data.table::data.table(
    metric = c("Book Version", "Source Chapters", "Words", "Estimated Pages", "Concept Count", "Architecture Version", "Ontology Version"),
    value = c(
      APP_VERSION %||% "0.1.0",
      as.character(nrow(book_docs)),
      format(total_words, big.mark = ","),
      as.character(ceiling(total_words / 300)),
      as.character(concept_count),
      if (nrow(arch_docs)) fmt_date(max(arch_docs$modified, na.rm = TRUE)) else "unknown",
      if (file.exists(ontology_path)) fmt_date(file.info(ontology_path)$mtime) else "unknown"
    )
  )
}

knowledge_library_context <- function(document, docs) {
  if (is.null(document) || !nrow(document)) {
    return(list(
      concepts = character(),
      chapters = character(),
      architecture = character(),
      open_questions = character(),
      future_work = "Select a document to see related context.",
      implementation_status = "Not selected"
    ))
  }
  text <- paste(document$title[[1]], document$relpath[[1]], sep = " ")
  concepts <- c("Artifact", "Evidence", "Collector", "Knowledge State", "Evidence Routing", "Context Optimization", "Guide", "Knowledge Library")
  concepts <- concepts[vapply(concepts, function(concept) grepl(tolower(concept), tolower(text), fixed = TRUE), logical(1))]
  if (!length(concepts)) {
    concepts <- c("Analytics Workstation", "Evidence", "Knowledge")
  }
  list(
    concepts = concepts,
    chapters = utils::head(docs[category == "Book"]$title, 6L),
    architecture = utils::head(docs[category == "Architecture"]$title, 6L),
    open_questions = utils::head(docs[category == "Open Questions"]$title, 5L),
    future_work = "Concept graph, semantic search, Guide suggestions, version history, notes, and annotations are reserved for later phases.",
    implementation_status = "Phase 1 reader: repository-backed, read-only, no search, no editing, no generated PDF."
  )
}

ui_knowledge_context_list <- function(title, items, empty = "No related items yet.") {
  ui_inspector_section(
    title,
    if (length(items)) {
      tags$ul(class = "aq-library-context-list", lapply(items, tags$li))
    } else {
      ui_empty_state(empty)
    },
    collapsed = FALSE
  )
}

page_knowledge_library_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Knowledge Library",
    tags$div(
      class = "aq-page aq-library-workspace-page",
      ui_section_header(
        title = "Knowledge Library",
        subtitle = "Read, navigate, and review the living institutional memory of Analytics Workstation.",
        eyebrow = "Library",
        actions = ui_action_row(
          actionButton(ns("refresh_library"), "Refresh Library", class = "btn-secondary"),
          downloadButton(ns("download_markdown"), "Download Markdown", class = "btn-secondary")
        )
      ),
      tags$div(
        class = "aq-library-page",
        tags$aside(
          class = "aq-library-navigator",
          ui_card(
            title = "Knowledge Navigator",
            subtitle = "Repository-backed source material.",
            uiOutput(ns("book_status")),
            selectInput(ns("library_category"), "Section", choices = character()),
            selectInput(ns("library_document"), "Document", choices = character()),
            textInput(ns("library_search_placeholder"), "Search", value = "", placeholder = "Search arrives in a future phase"),
            ui_action_row(
              actionButton(ns("continue_reading"), "Continue Reading", class = "btn-primary btn-sm"),
              actionButton(ns("refresh_library_secondary"), "Refresh", class = "btn-secondary btn-sm")
            ),
            ui_disclosure(
              "Recently Viewed",
              uiOutput(ns("recently_viewed")),
              level = "common",
              open = TRUE
            )
          ),
          ui_card(
            title = "Author Mode",
            subtitle = "Local source actions.",
            ui_action_row(
              actionButton(ns("open_source_file"), "Open Source File", class = "btn-secondary btn-sm"),
              actionButton(ns("open_chapter_folder"), "Open Folder", class = "btn-secondary btn-sm"),
              actionButton(ns("reveal_in_explorer"), "Reveal", class = "btn-secondary btn-sm")
            ),
            ui_callout("Download Book", "Placeholder. PDF/DOCX/EPUB generation remains in the Book Compiler roadmap.", status = "info")
          )
        ),
        tags$main(
          class = "aq-library-reader-shell",
          uiOutput(ns("current_reading")),
          uiOutput(ns("document_reader"))
        ),
        tags$aside(
          class = "aq-library-context-panel",
          uiOutput(ns("context_panel"))
        )
      )
    )
  )
}

page_knowledge_library_server <- function(id, ctx = NULL) {
  moduleServer(id, function(input, output, session) {
    docs <- reactiveVal(knowledge_library_discover_documents())
    last_opened <- reactiveVal(NULL)
    recent <- reactiveVal(character())

    selected_document_path <- function(default = NULL) {
      document <- selected_document()
      if (!nrow(document) || is.null(document$path) || !length(document$path) || is.na(document$path[[1]]) || !nzchar(document$path[[1]])) {
        return(default)
      }
      document$path[[1]]
    }

    refresh_docs <- function() {
      docs(knowledge_library_discover_documents())
    }

    observe({
      categories <- unique(docs()$category)
      if (length(categories)) {
        updateSelectInput(session, "library_category", choices = categories, selected = selected_value(input$library_category) %||% categories[[1]])
      }
    })

    observeEvent(input$library_category, {
      choices <- docs()[category == input$library_category]
      if (!nrow(choices)) {
        updateSelectInput(session, "library_document", choices = character(), selected = character())
        return(invisible(NULL))
      }
      choice_values <- stats::setNames(choices$path, choices$title)
      selected <- selected_value(input$library_document)
      if (is.null(selected) || !selected %in% choices$path) {
        selected <- choices$path[[1]]
      }
      updateSelectInput(session, "library_document", choices = choice_values, selected = selected)
    }, ignoreInit = FALSE)

    selected_document <- reactive({
      library_docs <- docs()
      selected <- selected_value(input$library_document)
      if (is.null(selected) || !nzchar(selected) || !nrow(library_docs)) {
        return(library_docs[0])
      }
      row <- library_docs[path == selected]
      if (!nrow(row)) {
        row <- library_docs[1]
      }
      row
    })

    observeEvent(input$library_document, {
      selected <- selected_value(input$library_document)
      if (!is.null(selected) && nzchar(selected)) {
        last_opened(selected)
        recent(unique(utils::head(c(selected, recent()), 8L)))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$refresh_library, refresh_docs(), ignoreInit = TRUE)
    observeEvent(input$refresh_library_secondary, refresh_docs(), ignoreInit = TRUE)

    observeEvent(input$continue_reading, {
      last <- last_opened()
      if (!is.null(last) && file.exists(last)) {
        rows <- docs()[path == last]
        category <- if (nrow(rows)) rows$category[[1]] else input$library_category
        updateSelectInput(session, "library_category", selected = category)
        updateSelectInput(session, "library_document", selected = last)
      }
    }, ignoreInit = TRUE)

    open_path <- function(path) {
      if (is.null(path) || !file.exists(path)) {
        return(invisible(FALSE))
      }
      tryCatch({
        if (.Platform$OS.type == "windows") {
          shell.exec(normalizePath(path, winslash = "\\", mustWork = TRUE))
        } else {
          utils::browseURL(normalizePath(path, winslash = "/", mustWork = TRUE))
        }
        TRUE
      }, error = function(e) FALSE)
    }

    observeEvent(input$open_source_file, open_path(selected_document_path()), ignoreInit = TRUE)
    observeEvent(input$open_chapter_folder, {
      path <- selected_document_path()
      if (!is.null(path)) {
        open_path(dirname(path))
      }
    }, ignoreInit = TRUE)
    observeEvent(input$reveal_in_explorer, {
      path <- selected_document_path()
      if (!is.null(path) && file.exists(path)) {
        tryCatch({
          if (.Platform$OS.type == "windows") {
            system2("explorer", paste0("/select,", shQuote(normalizePath(path, winslash = "\\", mustWork = TRUE))), wait = FALSE)
          } else {
            utils::browseURL(dirname(normalizePath(path, winslash = "/", mustWork = TRUE)))
          }
        }, error = function(e) invisible(FALSE))
      }
    }, ignoreInit = TRUE)

    output$download_markdown <- downloadHandler(
      filename = function() basename(selected_document_path("knowledge_library.md")),
      content = function(file) {
        path <- selected_document_path()
        if (is.null(path) || !file.exists(path)) {
          writeLines("# Document unavailable", file)
        } else {
          file.copy(path, file, overwrite = TRUE)
        }
      }
    )

    output$book_status <- renderUI({
      stats <- knowledge_library_book_stats(docs())
      tags$div(
        class = "aq-library-status-grid",
        lapply(seq_len(nrow(stats)), function(index) {
          ui_stat_tile(stats$metric[[index]], stats$value[[index]], status = if (index <= 2L) "info" else "neutral")
        })
      )
    })

    output$current_reading <- renderUI({
      document <- selected_document()
      if (!nrow(document)) {
        return(ui_empty_state("No document selected.", "Refresh the Library or check that repository Markdown files exist."))
      }
      ui_card(
        class = "aq-library-current-reading",
        tags$div(
          class = "aq-library-current-heading",
          tags$div(
            tags$p(class = "aq-section-eyebrow", document$category[[1]]),
            tags$h3(document$title[[1]]),
            tags$p(class = "aq-library-current-path", document$relpath[[1]])
          ),
          tags$div(
            class = "aq-library-current-actions",
            ui_status_badge(paste(format(document$words[[1]], big.mark = ","), "words"), status = "info"),
            ui_status_badge(paste("modified", substr(document$modified[[1]], 1, 10)), status = "neutral")
          )
        )
      )
    })

    output$document_reader <- renderUI({
      document <- selected_document()
      if (!nrow(document)) {
        return(ui_empty_state("Select a document.", "The reader will render Markdown here."))
      }
      markdown_text <- knowledge_library_read_markdown(document$path[[1]])
      html <- knowledge_library_markdown_html(markdown_text)
      tags$div(
        class = "aq-library-reader-layout",
        tags$nav(
          class = "aq-library-toc",
          tags$h4("Table of Contents"),
          knowledge_library_section_toc(markdown_text)
        ),
        tags$article(class = "aq-library-reader", HTML(html))
      )
    })

    output$context_panel <- renderUI({
      document <- selected_document()
      context <- knowledge_library_context(document, docs())
      ui_card(
        title = "Context Panel",
        subtitle = "Cross-links are deterministic placeholders in Phase 1.",
        class = "aq-library-context-card",
        ui_knowledge_context_list("Related Concepts", context$concepts),
        ui_knowledge_context_list("Related Chapters", context$chapters),
        ui_knowledge_context_list("Architecture Docs", context$architecture),
        ui_knowledge_context_list("Open Questions", context$open_questions),
        ui_callout("Future Work", context$future_work, status = "info"),
        ui_callout("Implementation Status", context$implementation_status, status = "success"),
        ui_callout("Reserved Space", "Knowledge Search, Concept Graph, Guide Integration, GPT Summaries, Version History, Notes, and Annotations.", status = "info")
      )
    })

    output$recently_viewed <- renderUI({
      paths <- recent()
      if (!length(paths)) {
        return(ui_empty_state("No recent documents.", "Open a document to start a local reading trail."))
      }
      rows <- docs()[path %in% paths]
      tags$ul(
        class = "aq-library-recent-list",
        lapply(paths[paths %in% rows$path], function(path) {
          row <- rows[rows$path == path]
          tags$li(row$title[[1]] %||% basename(path))
        })
      )
    })
  })
}

qa_knowledge_library <- function() {
  docs <- knowledge_library_discover_documents()
  stats <- knowledge_library_book_stats(docs)
  first_doc <- docs[1]
  markdown_text <- if (nrow(first_doc)) knowledge_library_read_markdown(first_doc$path[[1]]) else ""
  rendered <- knowledge_library_markdown_html(markdown_text)
  context <- knowledge_library_context(first_doc, docs)
  context_text <- paste(as.character(ui_knowledge_context_list("Related Concepts", context$concepts)), collapse = " ")
  ui_text <- paste(as.character(page_knowledge_library_ui("knowledge_library")), collapse = " ")
  css_text <- if (file.exists(file.path("www", "app.css"))) paste(readLines(file.path("www", "app.css"), warn = FALSE), collapse = " ") else ""
  app_ui_text <- if (file.exists(file.path("R", "app_ui.R"))) paste(readLines(file.path("R", "app_ui.R"), warn = FALSE), collapse = " ") else ""

  data.table::data.table(
    check = c(
      "page_loads",
      "navigation_works",
      "markdown_renders",
      "chapter_discovery",
      "toc_links",
      "toc_scroll_region",
      "timestamps_trimmed",
      "fluid_no_overlap_layout",
      "reader_scroll_region",
      "dark_theme_consistent",
      "book_statistics_display",
      "recent_tracking_supported",
      "context_panel",
      "app_registration"
    ),
    status = c(
      if (grepl("Knowledge Library", ui_text, fixed = TRUE) && grepl("aq-library-page", ui_text, fixed = TRUE)) "success" else "error",
      if (nrow(docs) > 0L && all(c("category", "path", "title") %in% names(docs))) "success" else "error",
      if (nzchar(rendered) && (grepl("<h1|<h2|<p|<pre", rendered) || grepl("<table", rendered))) "success" else "error",
      if (any(docs$category == "Book") && any(grepl("chapter", docs$relpath, ignore.case = TRUE))) "success" else "error",
      if (grepl("href=\"#", paste(as.character(knowledge_library_section_toc(markdown_text)), collapse = " "), fixed = TRUE)) "success" else "error",
      if (grepl(".aq-library-toc-list", css_text, fixed = TRUE) && grepl("max-height: 92px", css_text, fixed = TRUE) && grepl("overflow-y: auto", css_text, fixed = TRUE)) "success" else "error",
      if (!any(grepl("\\.[0-9]{3,}", stats$value))) "success" else "error",
      if (grepl("aq-library-workspace-page", ui_text, fixed = TRUE) && grepl("clamp(240px, 18vw, 320px)", css_text, fixed = TRUE) && grepl("width: 100% !important", css_text, fixed = TRUE)) "success" else "error",
      if (grepl("height: calc(100vh - 250px)", css_text, fixed = TRUE) && grepl(".aq-library-reader", css_text, fixed = TRUE) && grepl("overflow-y: auto", css_text, fixed = TRUE)) "success" else "error",
      if (grepl(".aq-library-page", css_text, fixed = TRUE) && grepl(".aq-library-reader", css_text, fixed = TRUE)) "success" else "error",
      if (nrow(stats) >= 6L && all(c("Words", "Concept Count") %in% stats$metric)) "success" else "error",
      if (grepl("recently_viewed", ui_text, fixed = TRUE) && grepl("Continue Reading", ui_text, fixed = TRUE)) "success" else "error",
      if (grepl("Related Concepts", context_text, fixed = TRUE) && length(context$concepts) > 0L) "success" else "error",
      if (grepl("page_knowledge_library_ui", app_ui_text, fixed = TRUE)) "success" else "error"
    ),
    message = c(
      "Knowledge Library page markup renders.",
      "Document discovery returns navigable repository documents.",
      "Markdown renders to HTML.",
      "Book/source chapter discovery is active.",
      "Table of contents entries are anchor links.",
      "Table of contents is a contained scroll region.",
      "Book status timestamps are trimmed for human reading.",
      "Library layout uses fluid tracks and constrains navigator controls.",
      "Document reader is a contained scroll region.",
      "Library-specific dark workstation classes exist.",
      "Book status metrics are available.",
      "Recent and continue-reading controls are present.",
      "Context panel placeholders render.",
      "Knowledge Library is registered in the app shell."
    )
  )
}
