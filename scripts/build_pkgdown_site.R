#!/usr/bin/env Rscript

repo_root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  stop("Run scripts/build_pkgdown_site.R from the repository root.", call. = FALSE)
}

if (!requireNamespace("pkgdown", quietly = TRUE)) {
  stop("pkgdown is required to build the public site.", call. = FALSE)
}

pkgdown::build_site()

site_root <- file.path(repo_root, "pkgdown-site")
extra_css_source <- file.path(repo_root, "pkgdown", "extra.css")
extra_css_site <- file.path(site_root, "extra.css")

if (file.exists(extra_css_source)) {
  file.copy(extra_css_source, extra_css_site, overwrite = TRUE)

  html_files <- list.files(site_root, pattern = "\\.html$", full.names = TRUE, recursive = TRUE)
  for (html_file in html_files) {
    html <- paste(readLines(html_file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    if (grepl("extra\\.css", html, fixed = FALSE)) {
      next
    }

    relative_dir <- dirname(sub(
      paste0("^", gsub("\\\\", "/", normalizePath(site_root, winslash = "/", mustWork = TRUE)), "/?"),
      "",
      gsub("\\\\", "/", normalizePath(html_file, winslash = "/", mustWork = TRUE))
    ))
    depth <- if (identical(relative_dir, ".") || !nzchar(relative_dir)) {
      0L
    } else {
      length(strsplit(relative_dir, "/", fixed = TRUE)[[1]])
    }
    css_href <- if (depth == 0L) {
      "extra.css"
    } else {
      paste(c(rep("..", depth), "extra.css"), collapse = "/")
    }
    css_link <- paste0('<link href="', css_href, '" rel="stylesheet">')
    html <- sub("</head>", paste0(css_link, "</head>"), html, fixed = TRUE)
    writeLines(html, html_file, useBytes = TRUE)
  }
}

media_source <- file.path(repo_root, "docs", "media")
site_media <- file.path(repo_root, "pkgdown-site", "docs", "media")

if (dir.exists(media_source)) {
  dir.create(site_media, recursive = TRUE, showWarnings = FALSE)
  media_files <- list.files(media_source, full.names = TRUE, recursive = FALSE)
  if (length(media_files)) {
    file.copy(media_files, site_media, overwrite = TRUE)
  }
}

required <- file.path("pkgdown-site", c(
  "index.html",
  "articles/build-week-demo.html",
  "reference/run_workstation.html",
  "docs/media/hero.png",
  "docs/media/demo.webm"
))

missing <- required[!file.exists(required)]
if (length(missing)) {
  stop(
    "pkgdown build completed, but required public site assets are missing: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

message("pkgdown site is available at pkgdown-site/index.html")
