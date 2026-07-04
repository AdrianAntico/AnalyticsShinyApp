.normalize_table_theme <- function(theme = c("auto", "light", "dark", "pimp")) {
  theme <- match.arg(theme)
  if (identical(theme, "auto")) {
    return(getOption("aq.theme", "light"))
  }

  theme
}

get_reactable_theme <- function(theme = c("auto", "light", "dark", "pimp")) {
  theme <- .normalize_table_theme(theme)
  if (!requireNamespace("reactable", quietly = TRUE)) {
    return(NULL)
  }

  switch(
    theme,
    dark = reactable_theme_dark(),
    pimp = reactable_theme_pimp(),
    reactable_theme_light()
  )
}

reactable_theme_light <- function() {
  reactable::reactableTheme(
    color = "#334155",
    backgroundColor = "#ffffff",
    borderColor = "#d8dee8",
    stripedColor = "#f8fafc",
    highlightColor = "#eef4ff",
    cellPadding = "8px 10px",
    headerStyle = list(
      background = "#f8fafc",
      color = "#334155",
      borderColor = "#d8dee8",
      fontWeight = "600"
    ),
    searchInputStyle = list(
      background = "#ffffff",
      color = "#111827",
      borderColor = "#cbd5e1"
    )
  )
}

reactable_theme_dark <- function() {
  reactable::reactableTheme(
    color = "#e5e7eb",
    backgroundColor = "#111827",
    borderColor = "#334155",
    stripedColor = "#1f2937",
    highlightColor = "#1e3a5f",
    cellPadding = "8px 10px",
    headerStyle = list(
      background = "#1f2937",
      color = "#f8fafc",
      borderColor = "#334155",
      fontWeight = "600"
    ),
    searchInputStyle = list(
      background = "#0b1220",
      color = "#f8fafc",
      borderColor = "#475569"
    )
  )
}

reactable_theme_pimp <- function() {
  reactable::reactableTheme(
    color = "#f8fafc",
    backgroundColor = "#0f172a",
    borderColor = "#7c3aed",
    stripedColor = "#1e293b",
    highlightColor = "#164e63",
    cellPadding = "8px 10px",
    headerStyle = list(
      background = "#32105f",
      color = "#a5f3fc",
      borderColor = "#22d3ee",
      fontWeight = "700"
    ),
    searchInputStyle = list(
      background = "#f8fafc",
      color = "#111827",
      borderColor = "#67e8f9"
    )
  )
}
