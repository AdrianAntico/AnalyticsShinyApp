#!/usr/bin/env Rscript

message("Installing Analytics Workstation dependencies for:")
message(R.version.string)
message("Library paths:")
message(paste(" -", .libPaths(), collapse = "\n"))

repo_root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  stop("Run this script from the AnalyticsShinyApp repository root.", call. = FALSE)
}

cran_repo <- Sys.getenv("ANALYTICS_CRAN_REPO", unset = "https://cloud.r-project.org")
first_party_remotes <- c(
  AutoPlots = "AdrianAntico/AutoPlots",
  AutoQuant = "AdrianAntico/AutoQuant",
  AutoNLS = "AdrianAntico/AutoNLS",
  Rodeo = "AdrianAntico/Rodeo"
)
first_party <- names(first_party_remotes)
fields <- read.dcf(file.path(repo_root, "DESCRIPTION"))[1, ]

description_field <- function(name) {
  if (name %in% names(fields)) {
    return(fields[[name]])
  }

  NA_character_
}

split_packages <- function(value) {
  if (is.na(value) || !nzchar(value)) {
    return(character())
  }

  value <- gsub("\\([^)]*\\)", "", value)
  trimws(unlist(strsplit(value, ","), use.names = FALSE))
}

declared <- unique(c(
  split_packages(description_field("Depends")),
  split_packages(description_field("Imports")),
  split_packages(description_field("Suggests")),
  split_packages(description_field("LinkingTo"))
))
declared <- setdiff(declared, c("", "R", first_party))

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", repos = cran_repo, dependencies = TRUE)
}

cran_missing <- declared[!vapply(declared, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(cran_missing)) {
  message("Installing CRAN dependencies and their recursive dependencies:")
  message(paste(" -", cran_missing, collapse = "\n"))
  install.packages(cran_missing, repos = cran_repo, dependencies = TRUE)
} else {
  message("All declared CRAN dependencies are already available.")
}

parent <- normalizePath(file.path(repo_root, ".."), winslash = "/", mustWork = TRUE)
first_party_paths <- stats::setNames(file.path(parent, first_party), first_party)
available_repos <- first_party_paths[file.exists(first_party_paths)]

if (length(available_repos)) {
  message("Installing first-party ecosystem packages with recursive dependencies:")
  for (pkg in names(available_repos)) {
    message(" - ", pkg, " from ", available_repos[[pkg]])
    remotes::install_local(
      available_repos[[pkg]],
      dependencies = TRUE,
      upgrade = "never",
      quiet = FALSE
    )
  }
}

remaining_first_party <- first_party[
  !vapply(first_party, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]
remote_first_party <- setdiff(remaining_first_party, names(available_repos))

if (length(remote_first_party)) {
  message("Installing first-party packages from GitHub because sibling repositories were not available:")
  for (pkg in remote_first_party) {
    remote <- first_party_remotes[[pkg]]
    message(" - ", pkg, " from ", remote)
    remotes::install_github(
      remote,
      dependencies = TRUE,
      upgrade = "never",
      quiet = FALSE
    )
  }
}

final_packages <- unique(c(first_party, declared))
availability <- data.frame(
  package = final_packages,
  available = vapply(final_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1)),
  stringsAsFactors = FALSE
)

print(availability[order(availability$package), ], row.names = FALSE)

missing <- availability$package[!availability$available]
if (length(missing)) {
  stop(
    "Dependency installation completed, but packages are still unavailable: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

message("Analytics Workstation dependency installation is complete.")
