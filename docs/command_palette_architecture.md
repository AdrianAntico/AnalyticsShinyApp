# Command Palette Architecture

## Philosophy

The Global Command Palette is the keyboard-first action surface for Analytics Workstation.

Mission Control answers:

```text
What is happening?
```

Artifact Studio answers:

```text
What evidence do I have?
```

The Command Palette answers:

```text
What do you want to do next?
```

The palette is not ordinary search. It is the future universal entry point for navigation, analysis execution, artifact access, reporting, QA, and AI-assisted actions.

## Phase 1 Scope

Phase 1 implements:

- global launcher
- `Ctrl+Shift+P`
- `Ctrl+K`
- Escape to close
- arrow-key selection
- Enter execution
- mouse execution
- fuzzy filtering
- session-local recent commands
- centralized command registry
- navigation command dispatch

Phase 1 does not implement:

- AI planning
- command execution plans
- analysis execution
- workflow graph behavior
- story builder actions
- artifact compare actions

## Registry

Commands are registered centrally with:

```r
register_command(
  registry,
  id,
  title,
  category,
  keywords,
  icon,
  action,
  enabled
)
```

The current command fields are:

| Field | Purpose |
| --- | --- |
| `id` | Stable command identifier |
| `title` | User-facing command text |
| `category` | Navigation, Analysis, Artifacts, Reports, Project, Developer, QA |
| `keywords` | Search aliases and fuzzy matching hints |
| `icon` | Compact visual command mark |
| `action` | Structured action payload |
| `enabled` | Whether the command can currently run |

Future modules should register commands rather than hard-coding palette rows.

## Search

`command_search()` supports forgiving matching:

- direct text match
- category match
- keyword match
- simple fuzzy character-order match

Examples:

| Query | Expected match |
| --- | --- |
| `miss` | Open Mission Control |
| `art` | Open Artifact Studio |
| `coll` | Open Collector |
| `eda` | Generate EDA |
| `shap` | Run SHAP |

## Keyboard Behavior

Keyboard contract:

| Shortcut | Behavior |
| --- | --- |
| `Ctrl+Shift+P` | Open palette |
| `Ctrl+K` | Open palette |
| `Esc` | Close palette |
| `Up` / `Down` | Move selection |
| `Enter` | Execute selected command |

The input receives focus immediately when the palette opens.

## Rendering

The palette is a custom dark HTML/CSS/JavaScript component mounted at the app shell level.

Shiny is used for:

- command dispatch
- command action handling
- navigation
- future command state

The palette does not use a stock Shiny modal.

## Current Navigation Commands

Phase 1 registers navigation-oriented commands for:

- Mission Control
- Artifact Studio
- Project
- Data
- Workflow
- Analysis Modules
- EDA module entry
- Model Readiness module entry
- SHAP module entry
- Code Runner
- Reports / Layout
- Export
- Collector
- QA
- Project Settings

Analysis commands currently navigate to the relevant surface. They do not execute modules yet.

## Future AI Integration

The architecture should naturally support commands such as:

- Run SHAP
- Generate Report
- Open latest artifact
- Compare Run 7 vs Run 8
- Show readiness warnings
- Brief me on production risks

Future AI commands should use the same registry, but may add:

- preview-before-commit
- required inputs
- safety checks
- plan summaries
- artifact references
- command execution records

The registry should remain the shared command contract so new modules can participate without rewriting the palette.
