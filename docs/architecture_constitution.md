# Architecture Constitution

## Guiding Principle

Every feature must help the user create, improve, organize, explain, export, or reuse analytical report artifacts.

The Analytics Shiny App ecosystem exists to turn data work into durable analytical artifacts. New work should strengthen that path instead of broadening the product into an everything-app.

## Product Center

AnalyticsShinyApp is the central product and coordination repo. It owns the local-first Shiny/Electron user experience, shared state, module orchestration, artifact library, report plans, layouts, exports, project save/load, workflow launch surfaces, and Code Runner integration.

AnalyticsShinyApp does not own plotting internals, analytical algorithms, feature-engineering kernels, benchmark evidence, or Electron packaging mechanics.

## Repository Boundaries

| repo | owns | does not own |
| --- | --- | --- |
| AnalyticsShinyApp | product shell, app UI, state, artifact normalization, report plans, workflow UX, project persistence, app exports, Code Runner UX | AutoPlots internals, AutoQuant algorithms, package training/scoring kernels, benchmark strategy |
| AutoQuant | analytics/artifact generators, analytical report rendering, model diagnostics, SHAP/model insights/model readiness/CatBoost artifacts | app state, Shiny page logic, Artifact Library mutation, Electron runtime |
| AutoPlots | high-level plot functions, themes, widget/display helpers, plot styling contracts | app-specific workflows, analytics decisions, AutoQuant report logic |
| Rodeo | R feature engineering and model prep APIs, scoring-safe specs, R-side feature artifacts | Shiny workflow UI, Python feature engineering, benchmark ownership |
| PolarsFE | Python/Polars feature engineering and model prep APIs, scoring-safe specs, Python-side feature artifacts | R feature engineering, Shiny workflow UI, benchmark ownership |
| Benchmarks | performance harnesses, benchmark outputs, implementation evidence, decision reports | production package APIs, app features |
| shinyelectron | Electron packaging, R process launch, dependency install/source handling, runtime lifecycle | Shiny app behavior, analytics behavior, package internals |

## Contract First

Shared contracts are architectural law:

- services return `service_result()`
- analysis modules are artifact generators
- artifacts are created with `create_artifact()`
- report plans reference artifact IDs, not raw objects
- display/layout pages compose artifacts but do not run analytics
- generated code calls exported package APIs
- AutoPlots is called through high-level functions
- Code Runner is the only execution system

When a new feature does not fit an existing contract, update the contract deliberately before implementation.

## API Philosophy

Pre-product compatibility is less important than product clarity. Breaking changes are acceptable before monetizable product fit when they:

- reduce public API complexity
- align with artifact-first architecture
- make workflows easier to copy, paste, and modify
- remove legacy confusion
- clarify package boundaries

Prefer:

- fewer public functions
- flat, explicit parameters
- one obvious path per task
- generator-first workflows
- examples users can copy, paste, and modify at work
- stable output contracts
- internal helper complexity hidden from users

Avoid:

- clever nested config objects unless needed
- too many tiny public helpers
- forcing users to learn package internals
- preserving old APIs solely because they exist
- exposing implementation details as user-facing choices

Legacy paths may remain during transition, but legacy does not shape the future.

## QA As Law

QA helpers are part of the architecture, not optional polish. A feature is not complete until it has targeted QA at the layer it changes.

Expected QA levels:

- package generator QA in AutoQuant, Rodeo, or PolarsFE
- app adapter QA in AnalyticsShinyApp
- report plan/artifact/rendering QA when artifacts are added
- project save/load QA when state is persisted
- Electron smoke tests when dependency/runtime behavior changes
- benchmark evidence when performance claims guide implementation

Warnings are acceptable only when they are structured, expected, and documented.

## Naming Rules

Use names that describe lifecycle and responsibility:

- `Model Readiness` is pre-model diagnostics.
- `Model Assessment` is post-model evaluation of an already trained/scored model.
- `Model Insights` explains model behavior.
- `SHAP Insights` explains prediction-surface behavior from SHAP columns.
- `CatBoost Builder` trains/scores CatBoost models and returns artifacts/scored outputs.
- `Feature Engineering` creates features.
- `Model Prep` creates partitions, folds, and leakage-safe model data.

Module IDs should be stable, lowercase, and explicit, such as `autoquant_regression_shap_analysis` or `autoquant_catboost_builder`.

## Boundary Rules

Do not:

- modify AutoPlots from AnalyticsShinyApp
- call echarts4r directly from AnalyticsShinyApp
- source internal AutoPlots or AutoQuant files from app code
- add a second code execution system
- let modules mutate Layout/Display state directly
- create module-specific export systems
- store module plot artifacts as fake Plot Builder configs
- reimplement AutoQuant logic in the app
- use DT as the core table framework
- let GenAI or custom code bypass permissions/policies

## Workflow Rule

Workflow actions are user-triggered unless explicitly designed otherwise.

Workflow pages may orient, summarize, draft, and deep-link. They must not silently run modules, execute code, mutate report layouts, or chain downstream actions automatically.

Custom code hooks must use the existing Code Runner architecture. They may create draft requests, but they must not auto-run and must not bypass local trusted execution controls.

## Documentation Rule

Every architecture-affecting change should update the nearest relevant document:

- repo boundary changes: `repo_contracts.md`
- workflow changes: `workflow_architecture.md`
- module changes: `analysis_module_architecture.md` and `analysis_modules_status.md`
- artifact/report changes: `report_plan_architecture.md` or artifact UX docs
- Code Runner changes: `code_runner_architecture.md`
- platform/runtime changes: Electron smoke docs
- priorities: `product_backlog.md` and `product_backlog.csv`

Docs should explain the decision, boundary, QA expectation, and deferred scope.

## Deferred Areas

The following remain intentionally deferred:

- multiclass SHAP
- Spark benchmarks
- Model-Based Features redesign
- broad model registry
- automatic workflow execution
- drag/drop report canvas as a primary report system
- GenAI Agent Mode

Deferred means not now. It does not mean forgotten.
