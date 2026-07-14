# Knowledge Compilation Runtime Phase 1

Phase 1 implements the smallest complete vertical slice of the Knowledge Compilation Runtime:

```
selected authoritative sources
-> normalized knowledge units
-> validated runtime bundle
-> task routing
-> project-context digest
-> compact AI context package
-> bounded guidance/synthesis
-> deterministic output validation
```

The runtime is deliberately conservative. It compiles curated and deterministic knowledge units only. LLM-assisted extraction is treated as a future candidate-generation mode and is not runtime-eligible until reviewed.

## Architecture Conformance Mapping

| Phase 0 component | Existing reuse | New implementation | Owner repo | File/subsystem | Deferred |
|---|---|---|---|---|---|
| Source Registry | Repository docs, implementation files, storage hashes | `knowledge_source_registry()` | AnalyticsShinyApp | `R/knowledge_compilation_runtime.R` | Automated full-document extraction |
| Canonical Knowledge Units | Architecture docs and action contracts | `knowledge_units_curated()` | AnalyticsShinyApp | `R/knowledge_compilation_runtime.R` | LLM-assisted candidate approval workflow |
| Conflict/Supersession | Epistemic integrity rules | `knowledge_conflict_registry()` | AnalyticsShinyApp | `R/knowledge_compilation_runtime.R` | Rich conflict adjudication UI |
| Dependency Graph | Unit dependency references | `knowledge_dependency_graph()` | AnalyticsShinyApp | `R/knowledge_compilation_runtime.R` | Graph visualization |
| Runtime Bundles | GenAI bounded context, `service_result` | `compile_runtime_bundle()` | AnalyticsShinyApp | `R/knowledge_compilation_runtime.R` | Tier-specific bundle variants |
| Task Routing | GenAI supported actions and page context | `route_knowledge_task()` | AnalyticsShinyApp | `R/knowledge_compilation_runtime.R` | Semantic router |
| Project Context Digest | Existing GenAI project-context design | `compile_project_context_digest()` | AnalyticsShinyApp | `R/knowledge_compilation_runtime.R` | Deep knowledge graph retrieval |
| AI Context Package | GenAI telemetry and prompt wrappers | `build_ai_context_package()` and `genai_compiled_runtime_guidance()` | AnalyticsShinyApp | `R/knowledge_compilation_runtime.R`, `R/genai_service.R` | Automatic strategy optimization |
| Supported Action Boundary | `genai_actions.R` validators/executors | Allowed/prohibited actions inside compiled packages | AnalyticsShinyApp | `R/knowledge_compilation_runtime.R` | No autonomous consequential execution |
| Portable Schemas | AutoQuant artifact, decision workflow, and observational contracts | Registry consumption only | AutoQuant | No Phase 1 code change | Portable compiler only if needed downstream |

## Cross-Repository Impact

The cross-repository impact planner classifies Phase 1 as a workflow/runtime update owned by AnalyticsShinyApp.

Expected ownership:

- AnalyticsShinyApp owns source registry, compiler orchestration, bundle registry, task router, project-context digest, AI context package, token/provenance tracking, diagnostics, and runtime QA.
- AutoQuant remains the source for portable artifact envelopes, decision workflow contracts, and observational planning contracts. Phase 1 consumes these contracts but does not change them.
- AutoPlots and Rodeo are unaffected.

## Runtime Bundles

Initial bundles:

- `artifact_synthesis_core`
- `decision_workflow_guidance`
- `observational_causal_synthesis`
- `claim_governance`
- `epistemic_integrity_explanation`

Bundles are compiled from approved knowledge units only. Each bundle carries:

- schema version
- compiler version
- bundle id/version
- dependency order
- approved knowledge units
- source provenance
- source hashes
- compact policy text
- token estimate
- bundle hash

## Task Taxonomy

Initial supported tasks:

- `explain_workflow_state`
- `recommend_supported_next_action`
- `summarize_observational_plan`
- `extract_supported_claims`
- `explain_epistemic_finding`

Each task declares:

- required bundle
- required context fields
- structured output schema
- allowed actions
- prohibited actions
- escalation conditions
- model-tier compatibility
- context and response budgets

## AI Context Package

`build_ai_context_package()` compiles a task-specific context package containing:

- task code
- audience
- model tier
- bundle id/version
- compact policy content
- project context digest
- output schema
- allowed/prohibited actions
- escalation conditions
- source provenance
- token accounting
- context hash

`genai_compiled_runtime_guidance()` is the first GenAI adapter using this package. It preserves the existing provider abstraction and action proposal validation boundary.

## Output Validation

`validate_compiled_ai_response()` validates structured output fields for the initial task taxonomy and detects prohibited claims such as:

- executed actions
- completed approvals
- proven causal effects without estimator evidence
- motive diagnosis

The validator is deterministic. It does not judge truth; it enforces output shape and boundary conditions.

## Model-Tier Profiles

Phase 1 defines profiles for:

- `deterministic_only`
- `local_free_model`
- `paid_standard_model`
- `frontier_model`
- `human_review_required`

The runtime records tier assumptions but does not yet maintain separate bundle variants per tier. Variants are deferred until competency testing proves they are necessary.

## Operator Cards

Phase 1 includes operator cards for runtime inspection:

- Open Decision Work Queue
- Validate Decision Preconditions
- Run Valuation Analysis
- Generate Observational Plan Summary
- Register Artifact
- Request Human Review

These cards describe allowed tasks, consequence level, confirmation requirements, and runtime status. They do not execute actions by themselves.

## QA

`qa_knowledge_compilation_runtime()` verifies:

- source registry fields and hashes
- knowledge unit schema and source refs
- dependency graph integrity
- runtime bundle compilation
- task routing
- AI context package validation
- structured output validation
- operator cards
- cold-start competency routing
- compression comparison
- cross-repo impact planning

The QA is registered with `qa_analysis_modules_integration()`.

## Phase 1 Boundaries

Phase 1 does not implement:

- full-document autonomous extraction
- unreviewed LLM runtime policy
- exhaustive epistemic taxonomy
- fine-tuning or LoRA
- vector database or semantic search
- autonomous action execution
- observational effect estimation
- portfolio optimization
- MMM
- automatic approval
- identity management
- provider lock-in

The runtime can explain, route, constrain, and package context. It cannot independently approve or execute consequential operations.
