.normalize_table_theme <- function(theme = c("auto", "light", "dark", "pimp")) {
  theme <- match.arg(theme)
  if (identical(theme, "auto")) {
    return(getOption("aq.theme", "dark"))
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
    color = "#E2E8F0",
    backgroundColor = "#0B1326",
    borderColor = "rgba(148, 163, 184, 0.22)",
    stripedColor = "rgba(30, 41, 59, 0.78)",
    highlightColor = "rgba(59, 130, 246, 0.18)",
    rowSelectedStyle = list(
      backgroundColor = "rgba(37, 99, 235, 0.28)",
      boxShadow = "inset 3px 0 0 #60A5FA"
    ),
    cellPadding = "9px 12px",
    style = list(
      fontFamily = "-apple-system, BlinkMacSystemFont, Segoe UI, Inter, Helvetica, Arial, sans-serif",
      fontSize = "13px",
      border = "1px solid rgba(148, 163, 184, 0.22)",
      borderRadius = "8px",
      overflow = "hidden",
      boxShadow = "0 16px 42px rgba(0, 0, 0, 0.28)"
    ),
    tableStyle = list(
      borderCollapse = "separate",
      borderSpacing = "0"
    ),
    headerStyle = list(
      background = "#0F1B33",
      color = "#F8FAFC",
      borderColor = "rgba(148, 163, 184, 0.28)",
      fontWeight = "600"
    ),
    rowStyle = list(
      backgroundColor = "#0B1326"
    ),
    searchInputStyle = list(
      width = "100%",
      backgroundColor = "#111C33",
      color = "#E2E8F0",
      border = "1px solid rgba(148, 163, 184, 0.34)",
      borderRadius = "8px",
      padding = "8px 12px",
      outline = "none"
    ),
    filterInputStyle = list(
      backgroundColor = "#111C33",
      color = "#E2E8F0",
      border = "1px solid rgba(148, 163, 184, 0.34)",
      borderRadius = "8px",
      padding = "5px 8px",
      outline = "none"
    ),
    selectStyle = list(
      backgroundColor = "#111C33",
      color = "#E2E8F0",
      border = "1px solid #60A5FA",
      borderRadius = "8px",
      padding = "6px 10px",
      height = "34px",
      fontSize = "13px",
      fontWeight = "700",
      cursor = "pointer",
      outline = "none"
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
