#!/usr/bin/env Rscript

repo_root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  stop("Run scripts/preflight_release.R from the repository root.", call. = FALSE)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

configure_pandoc <- function() {
  if (requireNamespace("rmarkdown", quietly = TRUE)) {
    found <- rmarkdown::find_pandoc()
    if (!is.null(found$dir) && nzchar(found$dir) && dir.exists(found$dir)) {
      return(found$dir)
    }
  }

  candidates <- c(
    Sys.getenv("RSTUDIO_PANDOC", unset = NA_character_),
    Sys.getenv("QUARTO_PANDOC", unset = NA_character_),
    "C:/Users/Bizon/AppData/Local/Pandoc",
    "C:/Program Files/Positron/bin/pandoc",
    "C:/Program Files/Positron/resources/app/quarto/bin/tools",
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools"
  )
  candidates <- unique(candidates[!is.na(candidates) & nzchar(candidates)])
  candidates <- candidates[
    file.exists(file.path(candidates, "pandoc.exe")) |
      file.exists(file.path(candidates, "pandoc"))
  ]

  if (length(candidates)) {
    Sys.setenv(RSTUDIO_PANDOC = normalizePath(candidates[[1]], winslash = "/", mustWork = TRUE))
    return(Sys.getenv("RSTUDIO_PANDOC"))
  }

  NA_character_
}

configure_pandoc()

record <- data.frame(
  check = character(),
  status = character(),
  message = character(),
  stringsAsFactors = FALSE
)

add <- function(check, status, message) {
  record[nrow(record) + 1L, ] <<- list(check, status, message)
  message(sprintf("[%s] %s - %s", toupper(status), check, message))
}

run_step <- function(check, expr, required = TRUE) {
  tryCatch({
    value <- force(expr)
    if (isTRUE(value) || is.null(value)) {
      add(check, "success", "Completed.")
    } else {
      add(check, if (required) "error" else "warning", as.character(value)[1])
    }
  }, error = function(e) {
    add(check, if (required) "error" else "warning", conditionMessage(e))
  })
}

qa_success <- function(x) {
  if (is.null(x)) return(FALSE)
  if (is.data.frame(x) && "status" %in% names(x)) return(!any(x$status %in% "error"))
  FALSE
}

run_step("source_app", {
  app_env <<- new.env(parent = globalenv())
  source("app.R", local = app_env)
  TRUE
})

run_step("devtools_check", {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    "devtools is unavailable."
  } else {
    result <- devtools::check(document = FALSE, manual = FALSE, error_on = "never", quiet = TRUE)
    if (length(result$errors)) paste("devtools::check errors:", paste(result$errors, collapse = "; ")) else TRUE
  }
})

run_step("testthat", {
  if (!requireNamespace("testthat", quietly = TRUE)) {
    "testthat is unavailable."
  } else {
    result <- testthat::test_dir("tests/testthat", reporter = "summary")
    if (length(result$failed)) paste("testthat failures:", length(result$failed)) else TRUE
  }
})

for (qa_name in c(
  "qa_package_distribution",
  "qa_electron_distribution",
  "qa_build_week_demo",
  "qa_report_browser",
  "qa_agent_operation_runtime"
)) {
  run_step(qa_name, {
    if (!exists(qa_name, envir = app_env, mode = "function")) {
      return(paste("Missing QA helper:", qa_name))
    }
    qa <- get(qa_name, envir = app_env)()
    if (qa_success(qa)) TRUE else paste("QA reported errors in", qa_name)
  })
}

run_step("pkgdown_build_site", {
  if (!requireNamespace("pkgdown", quietly = TRUE)) {
    "pkgdown is unavailable."
  } else {
    source(file.path("scripts", "build_pkgdown_site.R"), local = TRUE)
    TRUE
  }
})

run_step("release_files", {
  required <- file.path("release", c(
    "AnalyticsShinyApp_1.0.0.tar.gz",
    "AnalyticsWorkstation-1.0.0-buildweek.zip",
    "SHA256.txt",
    "ReleaseNotes.md"
  ))
  missing <- required[!file.exists(required)]
  if (length(missing)) paste("Missing release files:", paste(missing, collapse = ", ")) else TRUE
})

run_step("release_checksums", {
  checksum_file <- file.path("release", "SHA256.txt")
  if (!file.exists(checksum_file)) {
    "SHA256.txt is missing."
  } else {
    lines <- readLines(checksum_file, warn = FALSE)
    artifacts <- file.path("release", c("AnalyticsShinyApp_1.0.0.tar.gz", "AnalyticsWorkstation-1.0.0-buildweek.zip"))
    missing <- artifacts[!file.exists(artifacts)]
    if (length(missing)) {
      paste("Cannot verify missing artifacts:", paste(missing, collapse = ", "))
    } else {
      expected_names <- basename(artifacts)
      if (!all(vapply(expected_names, function(name) any(grepl(name, lines, fixed = TRUE)), logical(1)))) {
        "SHA256.txt does not list every release artifact."
      } else {
        TRUE
      }
    }
  }
})

run_step("readme_media", {
  required <- file.path("docs", "media", c(
    "hero.png",
    "investigation.png",
    "belief_revision.gif",
    "claim_verification.png",
    "integrity_review.png",
    "architecture.png",
    "demo.webm",
    "demo_first_frame.png",
    "demo_final_frame.png"
  ))
  missing <- required[!file.exists(required)]
  if (length(missing)) paste("Missing README/demo media:", paste(missing, collapse = ", ")) else TRUE
})

run_step("demo_frame_style", {
  if (!requireNamespace("png", quietly = TRUE)) {
    "png is unavailable."
  } else {
    frame <- file.path("docs", "media", "demo_first_frame.png")
    if (!file.exists(frame)) {
      "demo_first_frame.png is missing."
    } else {
      img <- png::readPNG(frame)
      sample <- img[seq(1, dim(img)[1], length.out = min(30, dim(img)[1])), seq(1, dim(img)[2], length.out = min(30, dim(img)[2])), 1:3]
      mean_rgb <- mean(sample)
      if (is.na(mean_rgb) || mean_rgb > 0.92) {
        "First frame appears browser-default or mostly white."
      } else {
        TRUE
      }
    }
  }
})

run_step("public_markdown_no_developer_paths", {
  public_files <- c(
    "README.md",
    "CONTRIBUTING.md",
    "NEWS.md",
    "docs/windows_installation.md",
    "docs/troubleshooting_installation.md",
    "docs/pkgdown_site.md",
    "docs/public_release_audit.md",
    "docs/media/README.md"
  )
  public_files <- public_files[file.exists(public_files)]
  text <- paste(vapply(public_files, function(file) paste(readLines(file, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
  forbidden <- c("C:/Users/", "C:\\Users\\", ".codex", "Documents/GitHub", "AppData/Local/Temp")
  hits <- forbidden[vapply(forbidden, grepl, logical(1), x = text, fixed = TRUE)]
  if (length(hits)) paste("Public markdown contains developer-local path markers:", paste(hits, collapse = ", ")) else TRUE
})

run_step("git_diff_check", {
  git <- Sys.which("git")
  if (!nzchar(git)) {
    "git is unavailable."
  } else {
    status <- system2(git, c("diff", "--check"), stdout = TRUE, stderr = TRUE)
    code <- attr(status, "status") %||% 0L
    if (!identical(as.integer(code), 0L)) paste(status, collapse = "\n") else TRUE
  }
})

write.csv(record, file.path("release", "preflight_release_results.csv"), row.names = FALSE)

errors <- record[record$status == "error", , drop = FALSE]
if (nrow(errors)) {
  print(record)
  stop(nrow(errors), " release preflight check(s) failed.", call. = FALSE)
}

message("Release preflight completed successfully.")
