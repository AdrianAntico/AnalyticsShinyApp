# AutoPlots Composite View Architecture Audit

Status: design reconnaissance only  
Scope: AutoPlots architecture audit for future composite analytical views  
Date: 2026-07-08

## Prototype 1 Implementation Note

`ImportancePareto()` has been implemented in AutoPlots as the first composite analytical view prototype.

Implementation choices:

- added a named public function instead of adding overlay flags to `VariableImportance()` or `Bar()`
- kept the prototype isolated in `R/composite_importance_pareto.R`
- added small unexported helpers for importance-table normalization and cutoff-line composition
- reused existing AutoPlots helpers where they fit:
  - `e_bar_full()`
  - `e_grid_full()`
  - `e_x_axis_full()`
  - `e_y_axis_full()`
  - `e_tooltip_full()`
  - `e_title_full()`
  - `e_legend_full()`
  - `e_toolbox_full()`
- used raw `echarts4r::e_line_()` only for the cumulative contribution line because the current `e_line_full()` helper does not expose a series display name
- used raw `echarts4r::e_mark_line()` only for the optional cumulative cutoff/reference line
- preserved existing public plot APIs unchanged

The prototype follows the recommended hybrid approach: named public composite at the top, small internal helpers underneath, and direct echarts4r calls only where current helpers do not express the required composite behavior.

## Executive Summary

AutoPlots already has the right raw materials for composite analytical views:

- simple high-level public plot functions such as `Bar()`, `Histogram()`, `Scatter()`, `Box()`, `Line()`, `VariableImportance()`, and `ShapImportance()`
- lower-level `e_*_full()` echarts4r wrappers in `R/revised_echarts4r_functions.R`
- centralized theme defaults in `R/theme_helpers.R`
- existing precedents for overlays, multi-series plots, smoothing, and model-curve visualizations
- reusable internal data-preparation helpers in `R/PlotFunctions_NEW.R`

The safest future architecture is a hybrid:

1. Add new dedicated public composite functions for named analytical idioms.
2. Build them on unexported internal composition helpers.
3. Reuse existing high-level prep logic and `e_*_full()` helpers internally.
4. Avoid broad overlay flags on existing simple functions unless the overlay is already a natural part of that plot family.
5. Defer any general composite grammar until several named composites prove the internal shape.

In short:

```text
Simple Public API
        |
Named Composite Functions
        |
Internal Composition Helpers
        |
Existing Prep + e_*_full() + Theme Defaults
        |
echarts4r
```

This keeps the AutoPlots philosophy intact: simple defaults for users, sophisticated composition inside the package.

## Files Reviewed

Primary AutoPlots files:

- `R/PlotFunctions_NEW.R`
- `R/PlotFunctions.R`
- `R/revised_echarts4r_functions.R`
- `R/theme_helpers.R`
- `R/display_plots.R`
- `R/display_plots_theme_inferred.R`
- `R/AccessoryFunctions.R`
- `NAMESPACE`

Note: the requested `revised_charts_functions.R` appears to correspond to the local file `R/revised_echarts4r_functions.R`.

## Current Architecture Summary

### Public Plot APIs

`R/PlotFunctions_NEW.R` contains the current high-level plotting functions. These functions expose user-facing chart APIs and typically handle:

- input validation
- data preparation
- aggregation
- grouping
- theme default application
- echarts4r chart construction
- tooltips
- axes
- legends
- data zoom
- toolbox controls

Representative public APIs include:

- `Bar()`
- `Histogram()`
- `Density()`
- `Scatter()`
- `Box()`
- `Line()`
- `Area()`
- `HeatMap()`
- `CorrMatrix()`
- `VariableImportance()`
- `ShapImportance()`
- `ROC()`
- `Lift()`
- `Gains()`

The `NAMESPACE` also still exports legacy `Plot.*` functions. These are compatibility surfaces and should not be the foundation for new composite view design.

### Existing Low-Level Helpers

`R/revised_echarts4r_functions.R` provides many `e_*_full()` helpers. These wrap echarts4r calls while exposing richer option sets.

Relevant helpers include:

- `e_area_full()`
- `e_bar_full()`
- `e_boxplot_full()`
- `e_density_full()`
- `e_heatmap_full()`
- `e_line_full()`
- `e_grid_full()`
- `e_x_axis_full()`
- `e_y_axis_full()`
- `e_tooltip_full()`
- `e_title_full()`
- `e_legend_full()`
- `e_toolbox_full()`
- `e_data_zoom_slider_full()`

These helpers are useful implementation primitives, but they are too low-level to become the user-facing composite API. Their strength is internal consistency, not public simplicity.

### Shared Theme Logic

`R/theme_helpers.R` centralizes theme behavior through functions such as:

- `get_theme_defaults_common()`
- `get_theme_defaults_plot()`
- `set_null_defaults()`
- `apply_theme_defaults()`

Most modern plot functions call `apply_theme_defaults(Theme, plot_type = ..., grouped = ..., env = environment())`.

This is an important extension point for future consumer-aware encodings:

- human
- LLM
- thumbnail
- presentation
- executive
- developer

Encoding policies should build on this layer rather than adding many one-off visual arguments to every composite function.

### Layout and Display Helpers

`R/display_plots.R` and `R/display_plots_theme_inferred.R` provide helpers for rendering multiple plots in grids, tabs, and sections. These are useful for report layout, but they are not a substitute for true composite chart construction.

Composite analytical views should combine multiple analytical signals inside a coherent chart object, not merely place independent charts next to each other.

## Existing Composite and Overlay Precedents

AutoPlots already contains several useful precedents.

### Scatter Smoothing

`Scatter()` supports `AddGLM`, which adds a model fit overlay through echarts4r. This is a strong precedent for relationship-plus-trend plots.

Lesson: overlays can be appropriate when they are intrinsic to the plot family and do not create a broad parameter explosion.

### Line, Area, and Sequence Plots

Sequence-oriented functions use shared internal preparation helpers such as:

- `.ap_normalize_sequence_vars()`
- `.ap_validate_sequence_inputs()`
- `.ap_melt_sequence_yvars()`
- `.ap_prep_sequence_plot_data()`

`Line()` also supports multi-series behavior and dual-axis-like use cases through arguments such as `DualYVar`.

Lesson: shared data-prep helpers are a good pattern for future composites.

### Variable Importance

`VariableImportance()` is a thin wrapper around `Bar()` with coordinate flipping.

Lesson: named analytical functions can reuse simpler chart primitives while preserving a purpose-built public API.

### Model Curves

Model-curve functions such as ROC, lift, gains, calibration, partial dependence, and residual plots already encode analytical intent above the raw chart type.

Lesson: AutoPlots is already comfortable with functions that represent analytical concepts, not just chart geometries.

### Probability Reference Lines

Legacy probability plotting uses line charts with a reference or normal line overlay.

Lesson: reference lines are an established analytical overlay pattern, but the modern implementation should avoid depending on legacy `Plot.*` APIs.

## Centralized vs Manual Assembly

The architecture is mixed.

Centralized:

- theme defaults
- `e_*_full()` option wrappers
- many internal data-preparation helpers
- display/grid layout helpers

Manual:

- many high-level functions directly call raw `echarts4r::e_charts_()`
- many functions manually assemble series, axes, tooltip, legend, data zoom, and toolbox behavior
- composite-like behavior is implemented locally rather than through a shared composition layer

This is manageable today, but future composites could become brittle if each one manually assembles overlays, secondary axes, legends, and tooltip behavior.

## Architecture Options

### Option 1: New Dedicated Public Functions

Examples:

- `ImportancePareto()`
- `HistogramDensity()`
- `ScatterSmooth()`
- `BoxPlotSummary()`
- `ShapDependenceBinned()`

Strengths:

- preserves simple API philosophy
- avoids breaking existing functions
- gives each composite a clear analytical purpose
- easier to document
- easier to tune for human vs LLM encodings
- avoids adding dozens of optional arguments to existing functions

Weaknesses:

- can increase the number of exported functions
- risks inconsistent implementations if internal helpers are not introduced
- may duplicate data-prep logic unless carefully designed

Assessment: best public API strategy for the first wave.

### Option 2: Optional Overlays on Existing Functions

Examples:

- `Bar(..., AddLine = TRUE)`
- `Histogram(..., AddDensity = TRUE)`
- `Box(..., AddMean = TRUE)`
- `Scatter(..., AddSmooth = TRUE)`

Strengths:

- keeps function count smaller
- discoverable for users already using existing functions
- natural where overlay is intrinsic to the family

Weaknesses:

- high risk of parameter explosion
- existing functions already have large argument surfaces
- overlay-specific arguments can crowd simple use cases
- complex interactions with grouping, faceting, dual axes, legends, tooltips, and data zoom
- harder to express analytical intent

Assessment: use sparingly. This is reasonable only where the overlay is already a mature, natural extension of a plot family, such as `Scatter(AddGLM = TRUE)`.

### Option 3: Internal Composition Helpers

Examples:

- `.ap_compose_chart()`
- `.ap_add_line_overlay()`
- `.ap_add_reference_line()`
- `.ap_add_cumulative_series()`
- `.ap_add_density_overlay()`
- `.ap_add_binned_summary_line()`
- `.ap_apply_composite_axes()`
- `.ap_apply_composite_tooltip()`
- `.ap_apply_encoding_defaults()`

Strengths:

- prevents one-off composite hacks
- allows dedicated public functions to share implementation
- centralizes tooltip, legend, data zoom, and axis behavior
- supports future consumer-aware encodings
- improves testability

Weaknesses:

- requires careful design before it pays off
- too much abstraction too early could slow simple prototypes

Assessment: strongly recommended as the implementation foundation.

### Option 4: Small Composite Grammar Layer

Conceptually:

```r
compose_chart(data) |>
  add_bar(...) |>
  add_line(...) |>
  add_reference_line(...) |>
  apply_encoding("llm")
```

Strengths:

- powerful and extensible
- clean for advanced composition
- could support many future composites

Weaknesses:

- substantial new architecture
- risks duplicating echarts4r
- risks exposing too much implementation detail
- may conflict with AutoPlots' simple API philosophy
- premature before the first composites establish repeated needs

Assessment: promising long term, but not the right first move.

### Option 5: Hybrid Approach

Use:

- dedicated public functions for named analytical composites
- internal composition helpers for shared implementation
- limited overlay flags only where already natural
- no public grammar layer until proven necessary

Assessment: recommended.

## Recommended Approach

Adopt a hybrid architecture.

### Public Layer

Expose a small set of named composite analytical functions only after prototypes are validated.

Examples:

```r
ImportancePareto(data, x, y, ...)
HistogramDensity(data, x, ...)
ScatterSmooth(data, x, y, ...)
BoxPlotSummary(data, x, y, ...)
ShapDependenceBinned(data, feature, shap_value, ...)
```

These names communicate analytical purpose. They also avoid overloading existing chart APIs with a long list of optional overlay arguments.

### Internal Layer

Add unexported composition helpers in AutoPlots when implementation begins.

Candidate helpers:

```r
.ap_composite_base()
.ap_add_bar_series()
.ap_add_line_series()
.ap_add_density_series()
.ap_add_reference_line()
.ap_add_cumulative_line()
.ap_add_binned_mean_line()
.ap_apply_composite_axes()
.ap_apply_composite_tooltip()
.ap_apply_composite_legend()
.ap_apply_encoding_defaults()
```

These should reuse:

- existing `.ap_prep_*` helpers
- `apply_theme_defaults()`
- `e_*_full()` helpers
- raw echarts4r only when the existing wrappers do not cover a required composite feature

### Encoding Layer

Future composite functions should be compatible with consumer-aware information encoding.

The public API should avoid dozens of visual arguments. Prefer a compact future argument such as:

```r
Encoding = c("human", "llm", "thumbnail", "presentation", "executive", "developer")
```

or a similarly constrained policy object.

The encoding should control defaults such as:

- label density
- reference-line visibility
- annotation density
- legend compactness
- tooltip detail
- margins
- data-to-pixel ratio
- thumbnail simplification

This aligns with the Information Encoding Policy: the analytical artifact remains the same, while its encoding changes by consumer.

## Key Risks

### Parameter Explosion

AutoPlots high-level functions already expose many styling and echarts option arguments. Adding many overlay toggles would make simple functions harder to use and harder to maintain.

Mitigation: prefer named composite functions and internal helpers.

### One-Off echarts4r Hacks

Composite views can easily become ad hoc raw echarts4r code.

Mitigation: introduce small internal composition helpers before exporting composites.

### Tooltip and Legend Complexity

Composite views often combine different series types and scales. Tooltips and legends can become confusing.

Mitigation: centralize composite tooltip and legend behavior.

### Axis and Scale Complexity

Bar plus line, histogram plus density, and importance plus cumulative contribution may require secondary axes or normalized scales.

Mitigation: treat axis coordination as an internal helper responsibility, not a per-function one-off.

### Human vs LLM Encoding Drift

LLM-oriented charts may need more labels, denser annotations, and less whitespace. Human-oriented charts may need more breathing room and interaction.

Mitigation: add consumer-aware encoding as a policy layer, not scattered arguments.

### Compatibility with Existing APIs

Existing public APIs should remain stable.

Mitigation: add new composite functions rather than changing existing defaults.

## Candidate Prototype Ranking

### 1. `ImportancePareto()`

Purpose: combine variable importance ranking with cumulative contribution.

Information compressed:

- top drivers
- concentration of importance
- long-tail contribution
- practical cutoff points

Existing support:

- `VariableImportance()` already wraps `Bar()`
- `Bar()` and `e_bar_full()` provide the main ranking display
- cumulative contribution can be computed from the same table

Likely raw echarts4r needs:

- line overlay
- potentially secondary y-axis
- coordinated tooltip

Difficulty: low to medium

Why first:

- high analytical value
- clear visual idiom
- strong LLM usefulness
- small data-prep burden
- natural candidate for both human and LLM encodings

### 2. `HistogramDensity()`

Purpose: combine binned frequency with distribution shape.

Information compressed:

- volume/count distribution
- smoothed shape
- skewness
- modality
- tail behavior

Existing support:

- `Histogram()` exists
- `Density()` exists
- both share distribution-oriented intent

Likely raw echarts4r needs:

- density line or area overlay
- scale coordination
- tooltip harmonization

Difficulty: medium

Why second:

- common analytical need
- useful for EDA and model diagnostics
- reveals more than either histogram or density alone

### 3. `ScatterSmooth()`

Purpose: combine point-level relationship evidence with a fitted or smoothed trend.

Information compressed:

- raw relationship
- trend direction
- nonlinearity or fitted relationship
- outliers

Existing support:

- `Scatter()` already supports `AddGLM`
- `echarts4r::e_glm` is already used

Likely raw echarts4r needs:

- minimal if existing `AddGLM` behavior is reused
- more if supporting LOESS, GAM, binned mean, or confidence bands

Difficulty: low for GLM, medium for richer smoothers

Why third:

- existing precedent makes it safe
- public function can clarify the analytical intent without changing `Scatter()`

### 4. `BoxPlotSummary()`

Purpose: combine grouped distribution with mean, reference, sample size, or other summary markers.

Information compressed:

- median and spread
- outliers
- group comparison
- mean/reference signal
- sample-size context

Existing support:

- `Box()` exists
- `e_boxplot_full()` exists

Likely raw echarts4r needs:

- mean/reference overlay
- markLine or custom line series
- tooltip augmentation

Difficulty: medium

Why fourth:

- valuable but more sensitive to grouped data structure and axis coordination

### 5. `ShapDependenceBinned()`

Purpose: combine SHAP dependence scatter with a binned mean or trend line.

Information compressed:

- local contribution variation
- nonlinear effect shape
- global direction
- sparse regions
- feature value regimes

Existing support:

- `Scatter()` can render point relationships
- `Line()` can render binned summaries
- `ShapImportance()` exists, indicating SHAP-specific plotting support

Likely raw echarts4r needs:

- scatter plus binned line overlay
- optional coloring by interacting feature
- compact LLM encoding variants

Difficulty: medium to high

Why later:

- extremely valuable, but SHAP dependence semantics need a stable producer contract
- easiest to get wrong as a one-off

## Additional Composite Candidates

### Bar + Line

Useful for rate-over-volume displays and category contribution plus trend. This should wait until axis coordination and tooltip helpers exist.

### Trend + Anomaly or Reference Bands

Useful for monitoring and time-series diagnostics. Likely needs `markLine`, `markArea`, or custom polygon/area overlays.

### Scatter + Marginals

High value but more complex. It likely needs grid layout, multiple axes, linked scales, and careful sizing. This should be a later prototype.

### SHAP Importance + Cumulative Contribution

Likely similar to `ImportancePareto()`. This may become a variant or wrapper once importance table semantics are standardized.

## API Sketches Only

These sketches are intentionally not implementation commitments.

```r
ImportancePareto(
  data,
  feature_col,
  importance_col,
  top_n = 25,
  Encoding = "human",
  Theme = NULL
)
```

```r
HistogramDensity(
  data,
  x,
  bins = NULL,
  density = c("scaled", "secondary_axis"),
  Encoding = "human",
  Theme = NULL
)
```

```r
ScatterSmooth(
  data,
  x,
  y,
  smooth = c("glm", "loess", "none"),
  Encoding = "human",
  Theme = NULL
)
```

```r
BoxPlotSummary(
  data,
  x,
  y,
  summary = c("mean", "reference", "n"),
  Encoding = "human",
  Theme = NULL
)
```

```r
ShapDependenceBinned(
  data,
  feature_col,
  shap_col,
  color_col = NULL,
  bins = 20,
  Encoding = "human",
  Theme = NULL
)
```

## Implementation Sequence

No production code should change as part of this audit.

Recommended future sequence:

1. Define unexported composite helper conventions.
2. Create a small internal prototype branch for `ImportancePareto()` or `ScatterSmooth()`.
3. Validate theme, tooltip, legend, data zoom, and screenshot behavior.
4. Add composite examples to plot sizing/gallery QA.
5. Add human vs LLM encoding snapshots.
6. Add one exported named composite function only after the internal helper shape is stable.
7. Repeat with `HistogramDensity()`.
8. Defer a public composite grammar until at least three composites share enough implementation structure to justify it.

## QA Recommendations for Future Work

Future composite implementation should include checks that:

- new examples use modern public APIs, not legacy `Plot.*` functions
- application code does not call raw echarts4r directly for production artifacts
- screenshots are generated through the production screenshot helper
- human and LLM encodings are both rendered
- tooltips remain coherent with mixed series
- legends do not misrepresent overlaid analytical signals
- secondary axes are labeled clearly
- data zoom does not hide required context
- thumbnails remain recognizable
- Word/LLM artifact screenshots are readable at static sizes

## Final Recommendation

Use a hybrid architecture:

- named public composite analytical functions for clear user-facing APIs
- unexported composition helpers for reuse and maintainability
- existing `e_*_full()` helpers as internal building blocks
- theme and future encoding policies as centralized default providers
- raw echarts4r only where the current helpers cannot express the needed series or option

Do not implement composites as broad optional overlays on every existing function. That path would eventually turn simple plot APIs into configuration surfaces. AutoPlots should remain simple at the top and composable underneath.
