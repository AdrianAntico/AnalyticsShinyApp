.normalize_table_theme <- function(theme = c("auto", "light", "dark", "cyberpunk", "pimp")) {
  theme <- match.arg(theme)
  if (identical(theme, "auto")) {
    return(getOption("aq.theme", "dark"))
  }
  if (identical(theme, "pimp")) {
    return("cyberpunk")
  }

  theme
}

get_reactable_theme <- function(theme = c("auto", "light", "dark", "cyberpunk", "pimp")) {
  theme <- .normalize_table_theme(theme)
  if (!requireNamespace("reactable", quietly = TRUE)) {
    return(NULL)
  }

  switch(
    theme,
    dark = reactable_theme_dark(),
    cyberpunk = reactable_theme_cyberpunk(),
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
  reactable_theme_cyberpunk()
}

reactable_theme_cyberpunk <- function() {
  reactable::reactableTheme(
    color = "#f8fafc",
    backgroundColor = "#0d1124",
    borderColor = "rgba(0, 245, 255, 0.36)",
    stripedColor = "rgba(20, 25, 54, 0.92)",
    highlightColor = "rgba(255, 43, 214, 0.16)",
    cellPadding = "9px 12px",
    style = list(
      fontFamily = "-apple-system, BlinkMacSystemFont, Segoe UI, Inter, Helvetica, Arial, sans-serif",
      fontSize = "13px",
      border = "1px solid rgba(0, 245, 255, 0.28)",
      borderRadius = "8px",
      overflow = "hidden",
      boxShadow = "0 0 0 1px rgba(0, 245, 255, 0.14), 0 18px 42px rgba(255, 43, 214, 0.16)"
    ),
    headerStyle = list(
      background = "#11122f",
      color = "#8cfaff",
      borderColor = "rgba(255, 43, 214, 0.42)",
      fontWeight = "700"
    ),
    searchInputStyle = list(
      backgroundColor = "#070a19",
      color = "#f7fbff",
      border = "1px solid rgba(0, 245, 255, 0.42)",
      borderRadius = "8px",
      padding = "8px 12px",
      outline = "none"
    ),
    filterInputStyle = list(
      backgroundColor = "#070a19",
      color = "#f7fbff",
      border = "1px solid rgba(0, 245, 255, 0.42)",
      borderRadius = "8px",
      padding = "5px 8px",
      outline = "none"
    ),
    selectStyle = list(
      backgroundColor = "#070a19",
      color = "#f7fbff",
      border = "1px solid #00f5ff",
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
