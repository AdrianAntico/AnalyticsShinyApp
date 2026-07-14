# Observational Causal Intelligence

Analytics Workstation supports observational causal-study planning when randomized assignment is unavailable.

This layer does not estimate observational treatment effects. It records whether estimation is supportable, which design families are eligible, what assumptions remain, and when the system should recommend an experiment instead.

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
- estimate observational effects;
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

Registered artifacts use the canonical artifact system and are labeled as `observational_causal_planning_artifact` in the source AutoQuant contract. They preserve permitted/prohibited claims, readiness, overlap state, lineage, and a `no_effect_estimated` flag.

## Future Estimator Phases

Matching, weighting, doubly robust estimation, DiD, synthetic control, regression discontinuity, and IV remain future estimator phases. The first estimator should be chosen from actual readiness evidence produced by this planning layer.
