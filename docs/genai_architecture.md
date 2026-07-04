# GenAI Architecture

## Purpose

The Analytics Shiny App should support GenAI as an assistant layer for creating, improving, organizing, explaining, and reviewing analytical report artifacts.

GenAI should not be treated as a free-form chatbot bolted onto the side of the app. It should be integrated into the app's artifact-generator and display/report architecture through controlled proposals, validated actions, permission checks, and user approvals.

The long-term goal is to enable workflows such as:

- Recommend useful plots
- Generate titles and captions
- Create text artifacts
- Summarize sections
- Review reports
- Suggest layouts
- Build starter reports
- Assist forecasting/modeling/EDA modules
- Eventually operate in Agent Mode through approved actions

Core safety principle:

GenAI proposes.
The app validates.
Permissions and policies are enforced.
The user approves when required.
The app applies validated actions.

GenAI should never directly mutate application state, execute arbitrary R code, export files, delete artifacts, or access data outside the permissions and policy system.

## Core Principle

GenAI should produce structured proposals and artifacts, not directly mutate app state or execute arbitrary R code.

Standard pattern:

1. App computes structured context.
2. GenAI receives compact context.
3. GenAI returns structured proposal/actions.
4. App validates proposal/actions.
5. App checks user permissions.
6. App checks GenAI policy.
7. App requests user approval when required.
8. App applies validated actions.

Bad pattern:

```text
User prompt -> LLM writes arbitrary R code -> app evals it
```

Good pattern:

```text
User prompt -> LLM returns structured proposal -> app validates -> user approves -> app executes known actions
```

## Relationship To App Architecture

The app follows a separation-of-duties model:

Artifact Generator modules create artifacts.
Display / Report pages arrange and render artifacts.

GenAI can participate in both stages.

## GenAI In Artifact Generator Modules

GenAI can help modules create or improve artifacts.

Examples:

### Plot Builder

- Recommend plots
- Improve plot configuration
- Generate plot titles
- Generate subtitles
- Generate captions
- Explain plot choices

### EDA

- Summarize data profile
- Identify data quality issues
- Suggest follow-up analysis
- Generate EDA narratives

### Forecasting

- Recommend forecast setup
- Explain diagnostics
- Generate forecast summary
- Generate methodology/caveat text
- Suggest scenario comparisons

### Modeling

- Explain performance metrics
- Summarize SHAP/importance
- Flag leakage concerns
- Recommend model diagnostics

### GenAI Narrative

- Create executive summaries
- Create section summaries
- Create methodology notes
- Create caveats

In this stage, GenAI helps create or improve artifacts such as:

- Plot artifacts
- Text artifacts
- Table artifacts
- Forecast summaries
- Modeling narratives
- Methodology notes
- Caveat blocks

## GenAI In Display / Report Layer

GenAI can also help organize and review the final report.

Examples:

- Select artifacts for report
- Detect redundant artifacts
- Group artifacts into sections
- Recommend report ordering
- Suggest layout mode
- Write section summaries
- Generate executive summary
- Critique report completeness
- Suggest missing analyses
- Identify inconsistent aggregation choices

In this stage, GenAI acts more like a report designer, reviewer, or co-analyst.

## GenAI Must Produce Proposals

GenAI should not directly alter saved artifacts, layout, project state, exports, or module outputs.

Instead, it should return a proposal object.

A proposal is a structured plan containing one or more proposed actions.

Example proposal object:

```r
genai_proposal <- list(
  proposal_id = "proposal_001",
  proposal_type = "starter_report",
  title = "Suggested Marketing Performance Report",
  summary = "Create a starter report with revenue trends, channel comparisons, and spend efficiency.",
  actions = list(
    list(
      action_id = "action_001",
      action_type = "create_artifact",
      parameters = list(
        artifact_type = "plot",
        source_module = "plot_builder",
        config = list(
          plot_type = "Line",
          mappings = list(
            XVar = "Date",
            YVar = "Revenue",
            GroupVar = "Channel"
          ),
          options = list(
            PreAgg = FALSE,
            AggMethod = "sum"
          )
        )
      ),
      rationale = "Date is temporal, Revenue is numeric, and Channel is a low-cardinality grouping variable.",
      validation_status = "pending",
      requires_user_confirmation = TRUE
    ),
    list(
      action_id = "action_002",
      action_type = "create_artifact",
      parameters = list(
        artifact_type = "text",
        source_module = "genai_narrative",
        label = "Executive Summary",
        content = "Revenue trends and channel performance should be reviewed together to assess growth and efficiency.",
        section = "Overview"
      ),
      rationale = "The report benefits from a high-level summary before the visual analysis.",
      validation_status = "pending",
      requires_user_confirmation = TRUE
    ),
    list(
      action_id = "action_003",
      action_type = "set_layout",
      parameters = list(
        layout_type = "sections",
        sections = list(
          "Overview" = c("executive_summary"),
          "Performance" = c("revenue_trend", "revenue_by_channel")
        )
      ),
      rationale = "A sectioned report is easier to read than a flat plot list.",
      validation_status = "pending",
      requires_user_confirmation = TRUE
    )
  ),
  rationale = list(
    "The dataset appears to contain date, channel, revenue, and spend fields.",
    "Trend and categorical comparison plots are suitable first-pass artifacts."
  ),
  warnings = character(),
  required_user_approval = TRUE,
  status = "draft",
  created_at = Sys.time()
)
```

## Proposal Object

A GenAI proposal should contain:

- `proposal_id`
- `proposal_type`
- `title`
- `summary`
- `actions`
- `rationale`
- `warnings`
- `required_user_approval`
- `status`
- `created_at`

Suggested statuses:

- `draft`
- `validated`
- `partially_valid`
- `rejected`
- `approved`
- `applied`
- `failed`

A proposal should be inspectable before execution.

The user should be able to approve or reject the whole proposal, and eventually approve or reject individual actions.

## Action Schema

Each proposal contains one or more actions.

An action should contain:

- `action_id`
- `action_type`
- `target_id`, if applicable
- `parameters`
- `rationale`
- `validation_status`
- `requires_user_confirmation`

Possible action types:

- `recommend_plots`
- `generate_titles`
- `generate_captions`
- `explain_artifact`
- `review_report`
- `create_artifact`
- `update_artifact`
- `remove_artifact`
- `duplicate_artifact`
- `assign_section`
- `reorder_artifacts`
- `set_layout`
- `run_module`
- `run_eda`
- `run_forecasting`
- `run_modeling`
- `generate_narrative`
- `export_report`
- `overwrite_project`
- `use_raw_data`

Each action type should eventually have:

- schema
- validator
- executor
- risk level
- default policy
- permission requirement
- approval requirement
- audit behavior

The app should only execute actions known to the action registry.

Unknown actions should be rejected.

## Context Sent To GenAI

GenAI should receive compact structured context, not arbitrary app internals.

Possible context objects:

- `data_profile`
- `artifact_summary`
- `layout_summary`
- `available_plot_types`
- `available_modules`
- `available_actions`
- `genai_policy`
- `user_prompt`

## Data Profile

The app should compute deterministic data facts before calling GenAI.

Example:

```r
data_profile <- list(
  n_rows = 100000,
  n_cols = 12,
  columns = list(
    Date = list(
      type = "date",
      n_unique = 365,
      missing_pct = 0
    ),
    Channel = list(
      type = "categorical",
      n_unique = 5,
      missing_pct = 0.01
    ),
    Revenue = list(
      type = "numeric",
      missing_pct = 0.02,
      min = 0,
      max = 12000
    ),
    Spend = list(
      type = "numeric",
      missing_pct = 0,
      min = 0,
      max = 5000
    )
  )
)
```

## Artifact Summary

GenAI does not need full artifact objects. It usually only needs summaries.

Example:

```r
artifact_summary <- data.table::data.table(
  artifact_id = c("a1", "a2", "a3"),
  artifact_type = c("plot", "plot", "text"),
  source_module = c("plot_builder", "plot_builder", "genai_narrative"),
  label = c("Revenue trend", "Revenue by channel", "Executive summary"),
  section = c("Performance", "Performance", "Overview"),
  order = c(2L, 3L, 1L),
  status = c("ready", "ready", "draft")
)
```

## Layout Summary

Example:

```r
layout_summary <- list(
  layout_type = "sections",
  layout_cols = 2,
  sections = list(
    "Overview" = c("a3"),
    "Performance" = c("a1", "a2")
  )
)
```

## Available Actions

Example:

```r
available_actions <- c(
  "recommend_plots",
  "generate_titles",
  "generate_captions",
  "create_artifact",
  "assign_section",
  "reorder_artifacts",
  "set_layout",
  "review_report"
)
```

## Data Sharing Modes

The app should support multiple GenAI data sharing modes:

- `no_data`
- `profile_only`
- `sample_data`
- `raw_data`

### no_data

GenAI receives no dataset-derived information.

It may only see:

- available modules
- available actions
- generic app state
- user prompt

Useful for:

- explaining app functionality
- generic report planning
- workflow suggestions

### profile_only

GenAI receives deterministic metadata and summaries about the dataset.

It may see:

- column names
- column types
- missingness
- cardinality
- basic numeric summaries
- date ranges
- artifact summaries
- layout summaries

This should be the default.

Useful for:

- plot recommendations
- section planning
- data quality summaries
- report review
- starter report proposals

### sample_data

GenAI receives a small sampled dataset in addition to profile information.

Useful for:

- better semantic interpretation
- example value inspection
- categorical label understanding

This should require explicit permission and policy approval.

### raw_data

GenAI may receive the full dataset or large portions of it.

This should be disabled or approval-only by default.

Raw data mode should require explicit user permission, GenAI policy allowance, and clear user approval.

## GenAI Settings Page

The app should eventually include a GenAI Settings page.

The settings page should control:

- Provider settings
- Data sharing mode
- Allowed actions
- Approval requirements
- Audit/logging
- Cost/token limits

## Provider Settings

Possible settings:

- GenAI enabled
- LLM provider
- Model
- API key source
- Temperature
- Max tokens
- Timeout
- Retry behavior
- Fallback model

Potential provider options:

- OpenAI
- Anthropic
- Google
- Azure OpenAI
- Local model
- Disabled

Start with the first provider actually supported by the app.

## Data Sharing Settings

The user should be able to select the permitted data sharing mode:

- `no_data`
- `profile_only`
- `sample_data`
- `raw_data`

Default:

`profile_only`

If the user's role does not allow a given data mode, the option should be hidden or disabled.

## Action Policy Values

Each GenAI action should have one policy value:

- `disabled`
- `approval`
- `auto`

Meaning:

### disabled

GenAI may not perform or propose this action for execution.

### approval

GenAI may propose this action, but the user must approve before execution.

### auto

GenAI may propose and the app may execute this action automatically after validation, provided permissions allow it.

Some actions should never be auto by default.

## Action Registry Metadata

Each GenAI action should be registered with metadata.

Example:

```r
genai_action_registry <- list(
  recommend_plots = list(
    action_type = "recommend_plots",
    label = "Recommend plots",
    description = "Suggest plot configurations based on the current data profile.",
    risk_level = "low",
    default_policy = "auto",
    destructive = FALSE,
    external_side_effect = FALSE,
    requires_data_mode = "profile_only"
  ),
  create_artifact = list(
    action_type = "create_artifact",
    label = "Create artifact",
    description = "Create a new plot, text, table, metric, or other report artifact.",
    risk_level = "medium",
    default_policy = "approval",
    destructive = FALSE,
    external_side_effect = FALSE,
    requires_data_mode = "profile_only"
  ),
  export_report = list(
    action_type = "export_report",
    label = "Export report",
    description = "Export the current report to a file.",
    risk_level = "high",
    default_policy = "approval",
    destructive = FALSE,
    external_side_effect = TRUE,
    requires_data_mode = "no_data"
  ),
  delete_artifact = list(
    action_type = "delete_artifact",
    label = "Delete artifact",
    description = "Remove an artifact from the project.",
    risk_level = "high",
    default_policy = "disabled",
    destructive = TRUE,
    external_side_effect = FALSE,
    requires_data_mode = "no_data"
  ),
  use_raw_data = list(
    action_type = "use_raw_data",
    label = "Use raw data",
    description = "Allow GenAI to access raw row-level data.",
    risk_level = "high",
    default_policy = "disabled",
    destructive = FALSE,
    external_side_effect = TRUE,
    requires_data_mode = "raw_data"
  )
)
```

Action metadata should include:

- `action_type`
- `label`
- `description`
- `risk_level`: low, medium, high
- `default_policy`
- `destructive`: `TRUE`/`FALSE`
- `external_side_effect`: `TRUE`/`FALSE`
- `requires_data_mode`, if applicable
- `required_permission`, if applicable

## Suggested Default Policies

### Low-risk automatic by default

- `recommend_plots`
- `generate_titles`
- `generate_captions`
- `explain_artifact`
- `review_report`
- `suggest_layout`

### Approval required by default

- `create_artifact`
- `update_artifact`
- `assign_section`
- `reorder_artifacts`
- `set_layout`
- `run_eda`
- `run_forecasting`
- `run_modeling`
- `generate_narrative`
- `export_report`

### Disabled or approval-only by default

- `delete_artifact`
- `overwrite_project`
- `use_raw_data`
- `send_report`
- `share_report`

Destructive actions should not be automatic by default.

External side effects should require approval.

## GenAI Policy Object

The app should store GenAI policy as a structured object.

Example:

```r
genai_policy <- list(
  enabled = TRUE,
  provider = "openai",
  model = "selected_model",
  data_mode = "profile_only",
  action_policy = list(
    recommend_plots = "auto",
    generate_titles = "auto",
    generate_captions = "auto",
    explain_artifact = "auto",
    review_report = "auto",
    create_artifact = "approval",
    update_artifact = "approval",
    assign_section = "approval",
    reorder_artifacts = "approval",
    set_layout = "approval",
    run_eda = "approval",
    run_forecasting = "approval",
    run_modeling = "approval",
    generate_narrative = "approval",
    export_report = "approval",
    delete_artifact = "disabled",
    overwrite_project = "disabled",
    use_raw_data = "disabled"
  ),
  audit_log_enabled = TRUE,
  max_tokens_per_call = 8000,
  max_cost_per_session = NA_real_
)
```

Project files may store GenAI settings and policies, but loaded project policies must not override user permissions.

## Permission Gate

GenAI availability is subject to user permissions before GenAI policy is evaluated.

There are three major gates:

1. User permission gate
2. GenAI settings/policy gate
3. Action approval gate

The app should enforce this order:

1. User permission gate
2. GenAI enabled/settings gate
3. Data sharing mode gate
4. Action policy gate
5. User approval gate
6. Validated action execution

User permissions are higher priority than GenAI policy.

Example:

If `action_policy$recommend_plots = "auto"` but the user lacks `can_use_genai`, the action is blocked.

Example:

If `action_policy$use_raw_data = "approval"` but the user lacks `can_use_raw_data_genai`, the action is blocked even if the user approves.

## Permission Contract

The future app permission system should expose a generic permission check.

Example:

```r
can_user <- function(user, permission, context = list()) {
  # Return TRUE/FALSE or structured permission_result
}
```

A structured result may be preferable:

```r
permission_result <- list(
  allowed = TRUE,
  permission = "can_use_genai",
  reason = NULL,
  metadata = list()
)
```

On denial:

```r
permission_result <- list(
  allowed = FALSE,
  permission = "can_use_genai",
  reason = "GenAI is not enabled for this user's role.",
  metadata = list(
    role = "viewer"
  )
)
```

## GenAI-Related Permissions

Possible permissions:

- `can_use_genai`
- `can_view_genai_settings`
- `can_modify_genai_settings`
- `can_use_profile_only_genai`
- `can_use_sample_data_genai`
- `can_use_raw_data_genai`
- `can_generate_genai_text`
- `can_create_genai_artifacts`
- `can_update_genai_artifacts`
- `can_delete_genai_artifacts`
- `can_run_genai_agent`
- `can_run_genai_eda`
- `can_run_genai_forecasting`
- `can_run_genai_modeling`
- `can_export_with_genai`
- `can_delete_with_genai`
- `can_view_genai_audit_log`

## Permission And Policy Relationship

Permissions determine what the user is allowed to do.

GenAI policy determines how allowed GenAI actions behave.

Approval determines whether a specific proposed action is applied.

Permissions decide what the user may do.
GenAI policy decides how allowed GenAI actions behave.
Approval decides whether a specific proposed action is applied.

A user cannot enable GenAI capabilities for themselves through project state or GenAI settings if their role/permission contract does not allow it.

## UI Behavior For Permission Failures

If a user lacks GenAI permissions:

- Hide GenAI actions
- Or show disabled controls with explanation

Examples:

- GenAI is disabled for your role.
- Raw data mode is not available for your role.
- You do not have permission to modify GenAI settings.
- You do not have permission to run GenAI Agent Mode.

The GenAI Settings page should be one of:

- hidden
- read-only
- partially disabled

depending on the user's permissions.

Proposals requiring blocked permissions should show:

```text
Not allowed for this user or role.
```

If permission is denied, the app should not send data, profiles, prompts, or context to GenAI.

## Service Behavior

Every GenAI service should check permissions before:

- building GenAI context
- sending prompts
- generating proposals
- validating actions that require restricted data
- applying actions

If permission fails, the service should return a standard `service_result`.

Example:

```r
service_result(
  status = "error",
  errors = "GenAI is not enabled for this user's role.",
  metadata = list(
    error_code = "PERMISSION_DENIED",
    permission = "can_use_genai"
  )
)
```

Or:

```r
service_result(
  status = "needs_input",
  messages = "This action requires approval before execution.",
  metadata = list(
    required_approval = TRUE,
    action_type = "create_artifact"
  )
)
```

## Approval UX

When GenAI returns a proposal, the app should show a review panel.

Example:

```text
Proposed Actions

1. Create Line plot: Revenue over Date by Channel
   Risk: Medium
   Policy: Approval required
   Reason: Date + numeric Revenue + low-cardinality Channel is suitable for trend analysis.
   Approve / Reject

2. Create Bar plot: Revenue by Category
   Risk: Medium
   Policy: Approval required
   Reason: Category is categorical and Revenue is numeric.
   Approve / Reject

3. Generate Executive Summary
   Risk: Medium
   Policy: Approval required
   Reason: Summarizes the generated findings.
   Approve / Reject

Approve All Allowed Actions / Reject Proposal
```

If an action is disabled:

```text
This proposal includes a disabled action: export_report. Enable this action in GenAI Settings to proceed.
```

If an action is blocked by permissions:

```text
This action is not allowed for your role: use_raw_data.
```

The approval panel should display:

- proposed action
- rationale
- risk level
- policy status
- permission status
- required data mode
- approve/reject controls

## Project State Rules

Project files may store:

- GenAI provider settings
- selected model
- data mode preference
- action policy
- audit log settings
- proposal history, if enabled

But project files must not grant permissions.

Current user permissions always override loaded project settings.

Example:

A project was saved with raw_data mode enabled.
A different user loads the project.
That user lacks `can_use_raw_data_genai`.
The app must disable raw_data mode for that user.

Core rule:

Loading a project must not become a privilege escalation path.

## Audit Logging

GenAI actions should eventually support audit logging.

Potential audit events:

- GenAI prompt sent
- GenAI response received
- Proposal generated
- Proposal approved
- Proposal rejected
- Action executed
- Action blocked by policy
- Action blocked by permission
- Raw data access requested
- Raw data access denied
- Export proposed
- Export executed

Audit records may include:

- timestamp
- user_id
- session_id
- proposal_id
- action_id
- action_type
- permission_status
- policy_status
- approval_status
- data_mode
- model/provider
- token usage
- cost estimate
- result status

Denied GenAI attempts may optionally be logged if audit logging is enabled.

## Agent Mode

A future Agent Mode could allow GenAI to build reports by proposing sequences of validated actions.

Example user prompt:

```text
Build me a forecasting report for Revenue by month and explain the risks.
```

GenAI may propose:

1. Run Forecasting module using Date and Revenue.
2. Create forecast plot artifact.
3. Create actual-vs-fitted plot artifact.
4. Create backtest accuracy table artifact.
5. Create forecast caveats text artifact.
6. Assign artifacts to Forecast section.
7. Set section layout.
8. Generate executive summary.

The app should then:

1. Validate each action.
2. Check permissions.
3. Check GenAI policy.
4. Request approval for required actions.
5. Execute approved actions.
6. Report failures clearly.

Agent Mode should not bypass the proposal/action architecture.

Even in Agent Mode:

GenAI proposes.
The app validates.
The user approves when required.
The app executes.

## Relationship To service_result

GenAI services should return standard `service_result` objects.

Example successful proposal generation:

```r
service_result(
  status = "success",
  value = genai_proposal,
  messages = "Generated a starter report proposal.",
  metadata = list(
    service = "genai",
    proposal_type = "starter_report"
  )
)
```

Example validation failure:

```r
service_result(
  status = "error",
  errors = "The GenAI response did not match the expected proposal schema.",
  metadata = list(
    error_code = "GENAI_SCHEMA_INVALID",
    service = "genai"
  )
)
```

Example permission failure:

```r
service_result(
  status = "error",
  errors = "You do not have permission to use GenAI.",
  metadata = list(
    error_code = "PERMISSION_DENIED",
    permission = "can_use_genai"
  )
)
```

## Safety Rules

GenAI must follow these rules:

- No arbitrary eval.
- No direct state mutation.
- No direct file export without confirmation.
- No destructive actions without confirmation.
- No raw data access unless explicitly enabled and permitted.
- No project setting may override user permissions.
- No unknown actions may be executed.
- All returned proposals/actions must be validated.
- All approval-required actions must wait for user approval.
- All disabled actions must be blocked.

Default data mode should be:

`profile_only`

Default behavior should favor:

- recommendations
- summaries
- proposals
- review

over automatic app mutation.

## Implementation Phases

### Phase A: Low-risk GenAI Assist

- data_profile
- plot recommendations
- title generation
- caption generation
- plot explanation
- report review

Characteristics:

- profile-only mode
- mostly automatic
- low risk
- no state mutation unless user saves result

### Phase B: Text And Narrative Artifacts

- manual/AI text artifacts
- section summaries
- executive summaries
- methodology notes
- caveats

Characteristics:

- creates artifacts
- approval required
- saved in artifact library

### Phase C: Layout And Report Proposals

- section grouping
- artifact ordering
- layout suggestions
- starter report generator
- redundancy detection

Characteristics:

- proposal/action architecture
- approval required
- display layer integration

### Phase D: Module Assistance

- EDA assistant
- forecasting assistant
- modeling assistant
- target analysis assistant

Characteristics:

- GenAI assists inside artifact generator modules
- module returns artifacts
- module-specific validation remains deterministic

### Phase E: Agent Mode

- multi-step report building
- run modules
- create artifacts
- arrange layout
- generate summaries
- review report

Characteristics:

- validated action sequences
- permission gate
- policy gate
- approval gate
- audit logging

## Future Files

When implementation begins, possible flat R files:

- `R/genai_context.R`
- `R/genai_proposal.R`
- `R/genai_actions.R`
- `R/genai_policy.R`
- `R/genai_permissions.R`
- `R/service_genai.R`
- `R/registry_genai_actions.R`

Keep `R/` flat.

Do not create:

- `R/genai/`
- `R/services/`
- `R/registries/`

## Core Summary

The app should support GenAI as:

- artifact generator
- report designer
- proposal/action planner
- reviewer
- assistant inside analytical modules

But never as:

- unvalidated state mutator
- arbitrary code executor
- permission bypass
- silent raw data consumer
- automatic destructive actor

The governing model is:

Permissions decide what the user may do.
GenAI policy decides how allowed GenAI actions behave.
Approval decides whether a specific proposed action is applied.
The app validates and executes.
