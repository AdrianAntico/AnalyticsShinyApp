# Public / Private IP Boundary

AutoQuant is a public open-source repository and must remain public.

AnalyticsShinyApp is currently private and is the canonical home of the integrated Analytics Workstation product architecture.

This policy governs where code, schemas, examples, documentation, design notes, and future plans belong.

## Classification Rule

Before adding or moving material, classify it as one of:

1. Public portable capability
   - Generic analytics methods.
   - Reusable contracts.
   - Package APIs.
   - Package-level validation.
   - Methodology documentation required by independent AutoQuant users.
   - Copyable examples for implemented public behavior.

2. Public compatibility surface
   - Minimal interfaces required for interoperability with downstream systems.
   - Stable schemas needed by consumers.
   - Compatibility wrappers required to keep public package behavior usable.

3. Private product intelligence
   - Integrated Decision Management architecture.
   - Enterprise lever orchestration.
   - AI operator behavior.
   - Knowledge Compilation Runtime.
   - Source-selection policy.
   - Curated knowledge units.
   - Runtime bundles.
   - Conflict-resolution logic.
   - Context compiler and task router.
   - Model-tier routing.
   - Token optimization.
   - Organizational memory.
   - Workflow and approval UX.
   - Synthetic curricula and evaluation corpus.
   - Commercialization strategy.
   - Customer-specific integration and deployment.
   - Future roadmap and forward-looking build prompts.

Categories 1 and 2 may live in AutoQuant when needed.

Category 3 belongs in AnalyticsShinyApp or another explicitly private repository.

When uncertain, do not publish the material to AutoQuant. Flag it for review.

## Documentation Rule

Use this test:

> Does this primarily explain a portable AutoQuant API that an independent package user needs?

If yes, it may belong in AutoQuant.

If no, it belongs in AnalyticsShinyApp or another private repository.

AutoQuant documentation should explain implemented public APIs, portable methodology, current limitations, and accurate examples. It should not become the canonical source for the full integrated platform philosophy, proprietary orchestration, future product architecture, or commercial roadmap.

## Lever Management Rule

AutoQuant may publicly contain:

- generic lever schema;
- variable-to-lever mappings;
- controllability and range fields;
- portable validation;
- generic evidence and valuation interfaces;
- public API examples.

AnalyticsShinyApp privately owns the integrated Lever Management System:

- strategic alignment;
- objective/strategy/tactic orchestration;
- causal evidence linkage;
- valuation linkage;
- workflow and approval behavior;
- authority and governance;
- monitoring and learning;
- AI operation of lever workflows;
- cross-module product behavior.

AutoQuant defines portable lever primitives. AnalyticsShinyApp defines the Lever Management System.

## Knowledge Compilation Rule

AutoQuant may expose artifact contracts that are useful to compile.

Keep private:

- source-selection policy;
- curated knowledge units;
- bundle contents;
- conflict-resolution logic;
- context-routing rules;
- operator cards;
- token optimization;
- competency corpus;
- free-versus-paid model strategy;
- deployment-specific prompts and runtime behavior.

The concept of compilable analytical contracts can be discussed publicly. The operational compiler and intelligence assets remain private.

## Roadmap Rule

Do not place forward-looking build prompts, unimplemented architecture, detailed sequencing, commercialization strategy, or long-range product roadmap material in AutoQuant.

Public docs should primarily describe:

- implemented behavior;
- stable contracts;
- current limitations;
- accurate examples.

Future invention work belongs in the private app repository.

## Reporting Requirement

For every changed or created file crossing repository boundaries, report:

- public/private classification;
- repository selected;
- reason;
- whether the content exposes product orchestration or future roadmap;
- whether a narrower public interface would suffice.

## Current Phase Classification

| File | Repository | Classification | Reason | Product orchestration or roadmap exposed? | Narrower public interface sufficient? |
|---|---|---|---|---|---|
| `AutoQuant/R/epistemic_integrity.R` | AutoQuant | Public portable capability | Defines generic intervention provenance, claim records, deterministic findings, quality gates, adjudication records, artifact envelope, and QA as reusable contracts. | No | No. These are the narrow public contracts needed by downstream systems. |
| `AutoQuant/NAMESPACE` | AutoQuant | Public compatibility surface | Exports the public portable epistemic API. | No | No. Exports are required for package users and the private app consumer. |
| `AutoQuant/R/qa_package.R` | AutoQuant | Public compatibility surface | Adds package-level validation for implemented portable contracts. | No | No. Public QA should cover public exports. |
| `AnalyticsShinyApp/R/epistemic_integrity_workspace.R` | AnalyticsShinyApp | Private product intelligence | Integrates portable contracts into app project state, artifacts, and private workflow surfaces. | Yes, privately | Not for AutoQuant. |
| `AnalyticsShinyApp/R/knowledge_compilation_runtime.R` | AnalyticsShinyApp | Private product intelligence | Owns source registry, curated units, runtime bundles, task routing, and context compilation. | Yes, privately | AutoQuant should only expose compile-friendly contracts. |
| `AnalyticsShinyApp/docs/epistemic_integrity_phase1.md` | AnalyticsShinyApp | Private product intelligence | Documents integration, runtime linkage, and deferred product boundaries. | Yes, privately | A narrower AutoQuant API doc could be added later if needed, without product orchestration. |
| `AnalyticsShinyApp/docs/public_private_ip_boundary.md` | AnalyticsShinyApp | Private product intelligence | Defines repository placement policy and product IP boundary. | Yes, privately | No public equivalent needed. |
