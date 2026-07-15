# Observational Causal Intelligence

Analytics Workstation supports observational causal-study planning when randomized assignment is unavailable.

This layer first records whether observational estimation is supportable, which design families are eligible, what assumptions remain, and when the system should recommend an experiment instead. The governed Phase 2 adjustment estimator and Phase 3 Difference-in-Differences estimator can then run only after readiness evidence passes and the design is frozen.

## Workbench Scope

The Causal Intelligence workspace includes an Observational Study Design section for:

- decision-linked observational study context;
- treatment and comparison definition;
- treatment-assignment mechanism documentation;
- target-trial framing;
- candidate confounder and prohibited-variable lists;
- temporal eligibility;
- treatment variation;
- assignment-model diagnostics for overlap only;
- baseline balance;
- selection and missingness;
- unmeasured-confounding risk;
- falsification planning;
- design eligibility;
- readiness classification;
- canonical planning artifact registration.

## Guardrails

The workbench is planning-only. GenAI and reports may summarize, explain, and draft questions, but may not:

- declare ignorability;
- invent confounders;
- remove variables from the approved adjustment set;
- claim balance proves no unmeasured confounding;
- estimate observational effects without an approved readiness plan;
- suppress experiment recommendations.

## Mission Control

Mission Control reports observational causal states such as:

- assignment mechanism unknown;
- observational plan stale;
- severe overlap concern;
- no credible support;
- experiment preferred;
- observational design plan ready.

## Artifact Contract

Registered planning artifacts use the canonical artifact system and are labeled as `observational_causal_planning_artifact` in the source AutoQuant contract. They preserve permitted/prohibited claims, readiness, overlap state, lineage, and a `no_effect_estimated` flag.

Governed effect artifacts are labeled as `observational_effect_artifact`. They preserve the frozen design hash, propensity diagnostics, matching diagnostics, weight diagnostics, independent balance evidence, AIPW estimates, assumptions, sensitivity reminders, permitted claims, and prohibited claims. They require human review and do not authorize causal overreach.

Governed Difference-in-Differences artifacts are labeled as `did_effect_artifact`. They preserve intervention timing, pre-period diagnostics, parallel-trends assessment, composition stability, classic two-group DiD estimates, sensitivity reminders, assumptions, and claim governance. Parallel trends are presented as diagnostic support, never proof.

## Cross-Method Causal Review

Randomized ITT, governed AIPW, and governed DiD evidence now normalize into a shared app-side causal-effect vocabulary for review, reporting, valuation, and AI explanation. The shared vocabulary preserves estimand, population, effect scale, outcome, timing, treatment/intervention, comparison, assumptions, diagnostics, sensitivity, applicability, permitted claims, prohibited claims, review status, and lineage.

This alignment supports cross-method review without naive averaging. If estimands, populations, time horizons, outcomes, treatment definitions, comparisons, or effect scales differ, the evidence is classified as methodologically incomparable until reconciled.

See `docs/causal_intelligence_hardening_phase1.md` for the aggregate QA timeout diagnosis and the cross-method contract boundary.

## Future Estimator Phases

Synthetic control, regression discontinuity, IV, staggered DiD, event studies, generalized TWFE, mediation, and heterogeneous treatment effects remain future estimator phases. The next causal work should harden the implemented randomized, AIPW, and DiD paths before adding another estimator family.
