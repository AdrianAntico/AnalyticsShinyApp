ui_shell_route <- function(label, target, class = NULL, icon = NULL) {
  tags$button(
    type = "button",
    class = .aq_class("aq-shell-route", class),
    `data-target` = target,
    if (!is.null(icon)) tags$span(class = "aq-shell-route-icon", icon),
    tags$span(class = "aq-shell-route-label", label)
  )
}

ui_shell_menu <- function(label, workspace, items) {
  tags$details(
    class = "aq-shell-menu",
    `data-workspace` = workspace,
    tags$summary(
      class = "aq-shell-menu-summary",
      tags$span(label)
    ),
    tags$div(
      class = "aq-shell-menu-panel",
      lapply(items, function(item) {
        if (isTRUE(item$disabled)) {
          tags$div(
            class = "aq-shell-menu-item aq-shell-menu-item-disabled",
            tags$span(class = "aq-shell-menu-item-label", item$label),
            tags$small(item$reason %||% "Not available in this build.")
          )
        } else {
          ui_shell_route(item$label, item$target, class = "aq-shell-menu-item")
        }
      })
    )
  )
}

ui_workspace_overview_tab <- function(title, subtitle, eyebrow, actions = NULL) {
  tabPanel(
    title,
    ui_page(
      title = title,
      subtitle = subtitle,
      eyebrow = eyebrow,
      ui_card(
        title = paste(title, "Workspace"),
        subtitle = "Use the shell menu above to move through this workspace without leaving the current product map.",
        ui_empty_state(
          paste(title, "overview"),
          "This shell landing keeps the workspace stable while existing pages continue to own their detailed workflows."
        ),
        if (!is.null(actions)) do.call(ui_action_row, actions)
      )
    )
  )
}

build_app_ui <- function() {
  css_file <- file.path("www", "app.css")
  css_version <- if (file.exists(css_file)) {
    as.integer(file.info(css_file)$mtime)
  } else {
    APP_VERSION
  }
  fluidPage(
    tags$head(
      tags$title("Analytics Workstation"),
      tags$link(rel = "icon", type = "image/svg+xml", href = paste0("brand/analytics-workstation-mark.svg?v=", css_version)),
      tags$link(rel = "stylesheet", type = "text/css", href = paste0("app.css?v=", css_version))
    ),
    ui_app_shell(
      theme = "dark",
      tags$script(HTML("
        (function() {
          var routeWorkspace = {
            'Guide': 'home',
            'Project': 'project',
            'Data': 'data',
            'Analysis': 'analysis',
            'Workflow': 'analysis',
            'Analysis Modules': 'analysis',
            'Plots': 'analysis',
            'Evidence': 'evidence',
            'Artifact Studio': 'evidence',
            'Evidence Review': 'evidence',
            'Mission Control': 'evidence',
            'Decisions': 'decisions',
            'Decision Management': 'decisions',
            'Semantic Intelligence': 'decisions',
            'Causal Intelligence': 'decisions',
            'Delivery': 'delivery',
            'Layout': 'delivery',
            'Export': 'delivery',
            'AI Runtime': 'ai',
            'Knowledge Library': 'library',
            'Code Runner': 'more',
            'Product Experience': 'more'
          };

          var routeTabValue = {
            'Evidence Review': 'evidence_review',
            'Decision Management': 'decision_management',
            'Semantic Intelligence': 'semantic_intelligence',
            'AI Runtime': 'ai_runtime',
            'Product Experience': 'product_experience'
          };

          function currentTabLabel() {
            var active = document.querySelector('.aq-main-tabset > .tabbable > .nav-tabs li.active a');
            return active ? active.textContent.trim() : 'Guide';
          }

          function setShellActive(target) {
            var workspace = routeWorkspace[target] || routeWorkspace[currentTabLabel()] || '';
            document.querySelectorAll('.aq-shell-route, .aq-shell-menu').forEach(function(node) {
              node.classList.remove('aq-shell-active');
            });
            document.querySelectorAll('.aq-shell-route[data-target=\"' + target + '\"]').forEach(function(node) {
              node.classList.add('aq-shell-active');
            });
            if (workspace) {
              document.querySelectorAll('.aq-shell-menu[data-workspace=\"' + workspace + '\"]').forEach(function(node) {
                node.classList.add('aq-shell-active');
              });
            }
          }

          function activateExistingTab(target) {
            var value = routeTabValue[target] || target;
            var selector = '.aq-main-tabset > .tabbable > .nav-tabs a[data-value=\"' + value + '\"]';
            var tab = document.querySelector(selector);
            if (tab) tab.click();
          }

          document.addEventListener('click', function(event) {
            var route = event.target.closest('.aq-shell-route[data-target]');
            if (!route) return;
            event.preventDefault();
            var target = route.getAttribute('data-target');
            setShellActive(target);
            activateExistingTab(target);
            document.querySelectorAll('.aq-shell-menu[open]').forEach(function(menu) {
              menu.removeAttribute('open');
            });
            if (window.Shiny && Shiny.setInputValue) {
              Shiny.setInputValue('shell_nav_target', target, { priority: 'event' });
            }
          });

          document.addEventListener('toggle', function(event) {
            var openedMenu = event.target.closest('.aq-shell-menu');
            if (!openedMenu || !openedMenu.open) return;
            document.querySelectorAll('.aq-shell-menu[open]').forEach(function(menu) {
              if (menu !== openedMenu) menu.removeAttribute('open');
            });
          }, true);

          document.addEventListener('shown.bs.tab', function() {
            window.setTimeout(function() { setShellActive(currentTabLabel()); }, 0);
          });

          document.addEventListener('DOMContentLoaded', function() {
            window.setTimeout(function() { setShellActive(currentTabLabel()); }, 300);
          });
        })();
      ")),
      tags$header(
        class = "aq-workstation-header",
        ui_shell_route(
          label = tags$div(
            class = "aq-brand-wordmark",
            tags$span(class = "aq-brand-name", "Analytics"),
            tags$span(class = "aq-brand-subtitle", "Workstation")
          ),
          target = "Guide",
          class = "aq-brand-lockup",
          icon = tags$img(
            class = "aq-brand-mark",
            src = paste0("brand/analytics-workstation-mark.svg?v=", css_version),
            alt = ""
          )
        ),
        tags$nav(
          class = "aq-shell-primary-nav",
          `aria-label` = "Primary workspaces",
          ui_shell_route("Project", "Project", class = "aq-shell-primary-link"),
          ui_shell_route("Data", "Data", class = "aq-shell-primary-link"),
          ui_shell_menu("Analysis", "analysis", list(
            list(label = "Overview", target = "Analysis"),
            list(label = "Workflow", target = "Workflow"),
            list(label = "Analysis Modules", target = "Analysis Modules"),
            list(label = "Plots", target = "Plots")
          )),
          ui_shell_menu("Evidence", "evidence", list(
            list(label = "Overview", target = "Evidence"),
            list(label = "Artifact Studio", target = "Artifact Studio"),
            list(label = "Evidence Review", target = "Evidence Review"),
            list(label = "Mission Control", target = "Mission Control")
          )),
          ui_shell_menu("Decisions", "decisions", list(
            list(label = "Overview", target = "Decisions"),
            list(label = "Decision Management", target = "Decision Management"),
            list(label = "Semantic Intelligence", target = "Semantic Intelligence"),
            list(label = "Causal Intelligence", target = "Causal Intelligence")
          )),
          ui_shell_menu("Delivery", "delivery", list(
            list(label = "Overview", target = "Delivery"),
            list(label = "Layout", target = "Layout"),
            list(label = "Export", target = "Export")
          ))
        ),
        tags$div(
          class = "aq-workstation-utilities",
          ui_command_palette("command_palette"),
          ui_shell_route("AI", "AI Runtime", class = "aq-shell-utility-link"),
          ui_shell_route("Library", "Knowledge Library", class = "aq-shell-utility-link"),
          tags$details(
            class = "aq-shell-menu aq-shell-utility-menu",
            `data-workspace` = "more",
            tags$summary(class = "aq-shell-menu-summary", tags$span("More")),
            tags$div(
              class = "aq-shell-menu-panel aq-shell-menu-panel-right",
              tags$div(class = "aq-shell-menu-theme", ui_theme_switcher(theme = "dark")),
              ui_shell_route("Code Runner", "Code Runner", class = "aq-shell-menu-item"),
              ui_shell_route("Product Experience", "Product Experience", class = "aq-shell-menu-item"),
              tags$div(class = "aq-shell-menu-divider"),
              tags$div(class = "aq-shell-menu-item aq-shell-menu-item-disabled", tags$span(class = "aq-shell-menu-item-label", "Settings"), tags$small("Reserved for app configuration.")),
              tags$div(class = "aq-shell-menu-item aq-shell-menu-item-disabled", tags$span(class = "aq-shell-menu-item-label", "Developer / QA"), tags$small("Use Code Runner for the current QA surface.")),
              tags$div(class = "aq-shell-menu-item aq-shell-menu-item-disabled", tags$span(class = "aq-shell-menu-item-label", "System Diagnostics"), tags$small("Reserved for a future diagnostics surface."))
            )
          )
        )
      ),
      ui_global_ai_assistant("global_ai"),
      tags$div(
        class = "aq-main-tabset",
        tabsetPanel(
          id = "main_tabs",
          page_guide_ui("guide"),
          page_project_ui("project"),
          page_data_ui("data"),
          ui_workspace_overview_tab(
            "Analysis",
            "Run analytical work through workflow stages, modules, and plot construction.",
            "Workspace",
            actions = list(
              ui_shell_route("Open Workflow", "Workflow", class = "btn-secondary"),
              ui_shell_route("Open Modules", "Analysis Modules", class = "btn-primary"),
              ui_shell_route("Open Plots", "Plots", class = "btn-secondary")
            )
          ),
          page_workflow_ui("workflow"),
          page_analysis_modules_ui("analysis_modules"),
          page_plot_builder_ui("plot_builder"),
          ui_workspace_overview_tab(
            "Evidence",
            "Inspect artifacts, reviews, mission status, and the evidence base behind decisions.",
            "Workspace",
            actions = list(
              ui_shell_route("Open Artifact Studio", "Artifact Studio", class = "btn-primary"),
              ui_shell_route("Open Evidence Review", "Evidence Review", class = "btn-secondary"),
              ui_shell_route("Open Mission Control", "Mission Control", class = "btn-secondary")
            )
          ),
          page_artifact_library_ui("artifact_library"),
          page_evidence_review_ui("evidence_review"),
          page_mission_control_ui("mission_control"),
          ui_workspace_overview_tab(
            "Decisions",
            "Author decision contexts, semantic intent, causal questions, and governed decision evidence.",
            "Workspace",
            actions = list(
              ui_shell_route("Open Decision Management", "Decision Management", class = "btn-primary"),
              ui_shell_route("Open Semantic Intelligence", "Semantic Intelligence", class = "btn-secondary"),
              ui_shell_route("Open Causal Intelligence", "Causal Intelligence", class = "btn-secondary")
            )
          ),
          page_decision_management_ui("decision_management"),
          page_semantic_intelligence_ui("semantic_intelligence"),
          page_causal_intelligence_ui("causal_intelligence"),
          ui_workspace_overview_tab(
            "Delivery",
            "Compose, package, and export project evidence for human and downstream consumers.",
            "Workspace",
            actions = list(
              ui_shell_route("Open Layout", "Layout", class = "btn-primary"),
              ui_shell_route("Open Export", "Export", class = "btn-secondary")
            )
          ),
          page_layouts_ui("layouts"),
          page_export_ui("export"),
          page_knowledge_library_ui("knowledge_library"),
          page_ai_runtime_ui("ai_runtime"),
          page_code_runner_ui("code_runner"),
          page_product_experience_ui("product_experience")
        )
      )
    )
  )
}
