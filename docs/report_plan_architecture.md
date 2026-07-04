# Report Plan Architecture

## Purpose

Report Plans provide curated report sequences for large sets of module-generated artifacts. They let a module such as AutoQuant EDA recommend a readable report without forcing the user to manually arrange every artifact from scratch.

## Core Model

The Artifact Library stores all artifacts.

A Report Plan stores references to selected artifact IDs. It does not own artifact objects and does not delete artifacts. A plan may define:

- layout type
- column count
- ordered sections
- ordered artifact IDs within each section
- rationale and module metadata

Applying a plan updates the active display/layout state. In the current interim implementation, this means updating artifact `visible`, `section`, and `order` fields carefully. Artifacts not included in the plan remain available in the Artifact Library.

## Module Responsibilities

Modules may return one or more recommended plans in addition to artifacts.

Modules may recommend:

- selected artifact IDs
- section names
- artifact order
- layout type
- display columns
- rationale

Modules may not:

- delete artifacts
- export reports directly
- bypass artifact validation
- bypass `service_result`
- own final report composition

## Display Responsibilities

The Display/Layout page owns final report composition.

Users can:

- preview a plan
- apply a plan
- edit artifact metadata afterward
- hide/show artifacts afterward
- change layout mode and columns afterward

Applying a plan is a starting point, not a lock.

## Artifact Library vs Active Plan

The Artifact Library remains the complete inventory of plots, text blocks, tables, and future analytical artifacts. A Report Plan is only a curated view over that inventory.

Plan operations must not delete artifacts. Removing an artifact from a plan only removes the artifact ID from that plan. Removing a section from a plan removes the section grouping only; the artifacts remain in the Artifact Library.

The active plan is the plan most recently applied to the Layouts page. It controls the current report composition, but users can continue editing plans or artifact metadata afterward.

## Validation Rules

Report plan validation should check:

- `plan_id`, `label`, and `source_module` are non-empty character values
- `layout_type` is one of `grid`, `sections`, `carousel`, or `canvas`
- `cols` is a positive integer
- `sections` is a list
- `status` is one of `draft`, `recommended`, `applied`, or `archived`
- duplicate plan IDs in a plan collection are repaired with stable suffixes where safe
- duplicate artifact IDs inside a section are repaired where safe
- empty sections produce warnings
- missing artifact references produce warnings
- hidden artifact references produce warnings

Invalid structural values block apply. Recoverable issues should be repaired when safe and shown as warnings so users can decide whether to keep editing or apply the plan.

## Missing Artifact Behavior

A plan may reference an artifact ID that is no longer present in the Artifact Library, especially after a project is edited or an artifact is removed. Missing references should not delete the plan. Preview should show a warning and identify the missing artifact ID.

Applying a plan with missing references may proceed if the plan is otherwise structurally valid. Existing artifacts are arranged normally, and missing references remain a warning for the user to resolve.

Hidden artifacts referenced by a plan should also warn. The plan can still be applied, because applying a plan is allowed to make selected artifacts visible in the active report layout.

## Preview, Apply, Edit Lifecycle

Preview Plan shows plan metadata, validation status, section names, artifact labels, artifact type badges, and any missing or hidden references. Preview does not mutate layout state.

Apply Plan validates the selected plan first. Invalid plans are blocked with friendly messages. Plans with warnings may be applied, but warnings should remain visible to the user. A successful apply updates the active layout state and records `active_plan_id`.

Plan editing should stay separated from artifact editing. Users may rename plans, change layout metadata, reorder sections, move artifacts between plan sections, remove artifacts from a plan, or duplicate/archive plans without mutating the Artifact Library.

## AutoQuant EDA Direction

AutoQuant EDA can generate many artifacts. The app should normalize those outputs into standard artifacts and then create recommended report plans that reference the generated artifact IDs.

The first supported plan is:

- `autoquant_eda_recommended`
- label: `Recommended EDA Report`
- layout: `sections`
- columns: `2`

Recommended sections may include:

- Data Overview
- Missingness
- Univariate Analysis
- Correlation Diagnostics
- Trend Analysis
- Target Analysis
- Drift / Risk Flags
- Appendix

Only sections with matching artifacts should be included.
