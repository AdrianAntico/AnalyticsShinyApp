# Package QA Surface Contract

Analytics Workstation validates sibling packages through stable installed-package QA entry points. The cross-repository orchestrator should call these aggregate functions instead of depending on implementation-specific `qa_*` helpers.

## Public Installed QA Contracts

| Package | Stable public QA entry point | Purpose |
| --- | --- | --- |
| `Rodeo` | `qa_rodeo_package()` | Validates feature engineering, fit/apply transformation contracts, model preparation, and model-prep artifact generation. |
| `AutoQuant` | `qa_autoquant_package()` | Validates artifact schemas, SHAP interaction guards, AutoNLS SHAP backend compatibility, regression SHAP artifact generation, binary model insights artifacts, and CatBoost Builder artifacts. |
| `AutoPlots` | `qa_autoplots_package()` | Validates representative production rendering contracts, including `ImportancePareto()` and resizable display helpers. |

These functions are the preferred package QA surface for installed validation, package refresh, and cross-repository compatibility checks.

## Internal Installed QA

Implementation-specific helpers may remain callable inside a package namespace when an aggregate QA function needs them. Examples include granular Rodeo transformation checks, AutoPlots rendering checks, and AutoQuant regression SHAP checks.

Internal installed QA helpers should not be added directly to the cross-repository manifest unless a package has no stable aggregate entry point yet. When they are used, the manifest must mark them with `qa_scope = "internal"` so the dependency is explicit.

## Repository-Only QA

Repository-only QA includes development fixtures, dot-prefixed helpers, exploratory checks, and tests that require source-tree-only files. These checks may be useful during package development, but they are not part of the installed package contract and should not be treated as consumer-facing API.

## Compatibility

Some packages may retain older granular exported QA helpers for compatibility. Those helpers are not the preferred contract. New cross-repository validation should use the aggregate public entry point unless a task explicitly requires a lower-level package-owned diagnostic.

## Rules For Future Work

- Add one stable aggregate installed QA function per package.
- Keep implementation-specific QA internal unless there is a clear consumer need.
- Do not infer public API from function names beginning with `qa_`.
- Validate package changes from a fresh isolated install, not only from source.
- Update `config/cross_repo_workspace.json` when the package QA contract changes.
