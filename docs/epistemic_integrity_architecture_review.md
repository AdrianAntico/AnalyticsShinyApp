# Epistemic Integrity Architecture Review

Status: architectural review only
Scope: cross-repository review before implementation
Date: 2026-07-13

## Executive Summary

Epistemic Integrity should become a cross-cutting governance layer, but it should not duplicate the existing evidence, decision, causal, valuation, GenAI, or audit systems. The current ecosystem already has a strong substrate:

- artifacts preserve analytical evidence;
- the Project Artifact Collector preserves project memory;
- Artifact Quality records component completeness and graceful degradation;
- Semantic Intelligence links business intent, variables, recommendations, decisions, authority, and coverage;
- Decision Valuation records evidence-to-impact translation and source classes;
- Decision Workflow separates recommendation, review, approval, implementation, and outcome;
- Causal Intelligence already uses readiness gates, prohibited claims, authority checks, and design-specific validity constraints;
- GenAI actions are bounded by proposal, validation, approval, execution, audit, and read-only/approval policies;
- ledgers and cross-system invariants provide append-only records, lifecycle checks, and hash-chain validation.

The gap is not generic governance. The gap is explicit governance of reasoning vulnerability and human intervention provenance.

The proposed Epistemic Integrity layer should sit above evidence production and before high-stakes reasoning, causal inference, valuation, claims, and decisions. It should answer:

- Where did a human assertion enter the system?
- Was the assertion treated as evidence, assumption, review, approval, override, narrative, or decision?
- Which claims depend on computation, observed evidence, expert judgment, GenAI text, assumptions, or organizational authority?
- Which reasoning risks are present?
- Which risks are signal-only warnings versus integrity gates?
- What contradictory evidence exists?
- What alternative explanations remain unexamined?
- What language is permitted by the evidence?
- What language is prohibited?
- What review would reduce vulnerability?

Implementation should be additive and contract-driven. AutoQuant should own portable epistemic contracts, taxonomies, deterministic assessments, and package QA. AnalyticsShinyApp should own project-level capture, workbench exposure, Mission Control surfacing, Evidence Inbox routing, report integration, review workflows, and sensitive-access presentation.

This review recommends proceeding, but only with explicit reuse of the existing architecture.

## Required First Step Outcome

The brief required architectural review before implementation. This document is that review. No new runtime behavior, estimation, optimization, UI, or GenAI autonomy should be introduced until the reuse boundaries below are accepted.

## Existing Architecture Inventory

### Artifact Model and Project Collector

Existing protection:

- Standard artifact bundles carry project id, run id, module id, artifact type, warnings, diagnostics, metadata, and created time.
- The collector validates bundles and artifacts before appending.
- Collector status distinguishes success, warning, error, skipped, not requested, and empty.
- Screenshot and table backing paths are produced through centralized production paths.

Epistemic relevance:

- Artifacts already provide the durable evidence object.
- Bundle warnings/errors/diagnostics can hold epistemic diagnostics.
- Collector manifest can record epistemic review artifacts without creating a second memory system.

Gap:

- Artifacts do not yet distinguish computed evidence, human assertion, assumption, override, narrative, claim, review, approval, or decision as epistemic source classes.
- Collector append success does not imply reasoning integrity.

Reuse recommendation:

- Reuse artifact bundles and collector manifests.
- Add epistemic integrity artifacts as standard artifacts, not as a separate storage system.

### Artifact Quality Policy

Existing protection:

- Captions, metadata, diagnostics, recommendations, screenshots, tables, table previews, sorting policy, backing data, and JSON all have component status.
- Completeness scoring is informational and does not hard-fail the collector.
- Missing components degrade gracefully and are recorded.

Epistemic relevance:

- Completeness is one ingredient in trustworthiness.
- Diagnostics and recommendations are natural carriers for reasoning caveats.

Gap:

- Artifact quality is not the same as claim validity.
- A complete artifact can still be misinterpreted, overclaimed, cherry-picked, or contradicted.

Reuse recommendation:

- Keep Artifact Quality focused on component completeness.
- Add Epistemic Integrity as a separate assessment layer that can consume quality status but does not redefine it.

### Table Artifact Architecture

Existing protection:

- Tables can preserve backing CSV/JSON sidecars, preview policies, sort policies, metadata, and render-target metadata.
- SHAP, importance, risk, diagnostic, ranking, threshold, lift, gain, calibration, and residual tables can use explicit producer policies.

Epistemic relevance:

- Tables often carry the evidence behind a claim.
- Multiple table orderings prevent a single default sort from hiding adverse evidence.

Gap:

- Table policies do not yet record whether a table supports, contradicts, weakens, or fails to address a claim.
- Preview selection can still bias interpretation unless claim governance records why a slice was selected.

Reuse recommendation:

- Use table artifacts as evidence sources.
- Add claim-evidence mappings and contradictory-evidence mappings above table policy.

### Semantic Intelligence

Existing protection:

- Business intent can represent mission, objective, strategy, tactic, lever, KPI, guardrail, constraint, risk, assumption, recommendation, decision, authority, and coverage.
- Variable semantics separate business role, operational eligibility, analytical role, causal role, temporal role, measurement role, and decision role.
- Relationships are deterministic and validated.

Epistemic relevance:

- This is the bridge from organizational intent to analytical evidence.
- Assumptions, risks, recommendations, decisions, authority, and coverage are already modeled.

Gap:

- A human-authored assumption is not yet governed as an epistemic assertion with source, review, uncertainty, contradictory evidence, and claim dependency.
- Authority is modeled for workflow, but authority is not the same as truth.

Reuse recommendation:

- Reuse business intent and variable semantics as upstream context.
- Add human assertion provenance and claim governance that can reference business intent IDs without changing those contracts.

### Decision Management

Existing protection:

- Decision contexts preserve alternatives, criteria, financial impacts, uncertainty, optionality, recommendations, decisions, and outcomes.
- Recommendation levels include proceed, pilot, defer, collect more evidence, reject, insufficient information, and no authorized action available.
- Decisions are distinct from recommendations and outcomes.

Epistemic relevance:

- Decisions are where claims become consequential.
- Uncertainty and optionality provide natural hooks for epistemic risk.

Gap:

- Decision recommendations do not yet require a structured claim-strength assessment.
- Narrative language around a recommendation is not yet checked against evidence strength.

Reuse recommendation:

- Add claim governance before decision recommendation finalization.
- Preserve decision contracts as the downstream consumer of epistemic status.

### Decision Valuation

Existing protection:

- Evidence-to-impact mappings preserve source artifact, evidence type, estimand or prediction, effect scale, effect value, source type, confidence, assumptions, validity range, applicability limitations, and guardrail status.
- Source types include directly observed, experimentally estimated, causally estimated, predictively modeled, forecast, scenario assumption, expert judgment, imported financial input, LLM suggestion, missing, and unsupported.
- Valuation does not approve, optimize, allocate budget, or execute.

Epistemic relevance:

- This is one of the strongest existing substrates for epistemic classification.
- Expert judgment and LLM suggestion are already distinguished from observed or estimated evidence.

Gap:

- Source-type confidence is input-level; it is not yet calibrated over time by judgment class, domain, or realized outcomes.
- A valuation can still combine weak assumptions into strong narrative language if claim governance is absent.

Reuse recommendation:

- Reuse decision valuation source types.
- Extend with judgment calibration records and claim-language constraints.

### Decision Workflow

Existing protection:

- Decision Workflow defines stages, legal transitions, review readiness, frozen evidence packages, review requests, approvals, implementation, monitoring, outcome review, and closure.
- Recommendation, decision, implementation, and outcome are separate facts.
- Evidence packages can be frozen before review.

Epistemic relevance:

- Human review and approval already have a lifecycle.
- Frozen evidence packages are natural checkpoints for epistemic review.

Gap:

- Review does not yet distinguish analytical review, epistemic review, causal review, narrative review, and authority approval as separate integrity functions.
- Human edits, overrides, suppressions, and narrative interventions are not yet first-class events.

Reuse recommendation:

- Reuse Decision Workflow stages and evidence packages.
- Add epistemic review artifacts and human intervention events as attached evidence, not as a new workflow engine.

### Causal Intelligence

Existing protection:

- Causal planning separates questions, estimands, roles, graph assumptions, adjustment guidance, design eligibility, and planning artifacts.
- Experimental design preserves approval gates, validity threats, balance/power/timing/measurement plans, and information value.
- Completed-experiment evidence preserves assignment, treatment delivery, compliance, outcomes, guardrails, exclusions, deviations, and readiness.
- Randomized ITT estimation uses readiness gates, authority/coverage approval, stale-record checks, planned-analysis checks, invalid covariate checks, missing outcome policy, and prohibited claims.
- Observational planning is explicitly planning-only and does not estimate effects.

Epistemic relevance:

- Causal Intelligence already treats claim validity as gated.
- It already has the right philosophy: do not estimate before readiness.

Gap:

- Causal risk is only one family of reasoning risk.
- Observational causal estimation would be especially vulnerable to human choices around treatment definition, adjustment sets, exclusions, timing, and narrative framing.
- Human-originated causal assumptions need provenance and review before estimation.

Reuse recommendation:

- Treat Epistemic Integrity as a prerequisite to future observational effect estimation.
- Use causal readiness/prohibited-claims patterns as a template for broader claim governance.

### GenAI Service, Actions, and Audit Ledger

Existing protection:

- GenAI provider layer is optional, local-first, and provider-agnostic.
- GenAI action layer uses registered actions, proposals, validation, approval, execution status, risk tiers, delegation, persistence, and audit events.
- Audit events sanitize prohibited fields, reject raw prompts/responses/credentials/absolute paths, hash events, and record policy decisions.
- Cross-system invariants already verify lifecycle status, schema versions, append-only docs, registered actions, trusted storage, and deterministic replay.

Epistemic relevance:

- GenAI can assist with explanation, summaries, candidate alternatives, and balanced narratives.
- GenAI must remain bounded and audited.

Gap:

- GenAI is not yet explicitly constrained by epistemic role: summarize vs claim vs recommend vs critique vs judge.
- GenAI should not infer intent, accuse misconduct, diagnose dishonesty, fabricate interventions, suppress contradictory evidence, or silently upgrade weak evidence to strong claims.

Reuse recommendation:

- Reuse the action/policy/audit system for any GenAI involvement.
- Add epistemic GenAI guardrails as policy checks, not as provider-specific logic.

### Improvement, Remediation, Campaign, and Knowledge Systems

Existing protection:

- Improvement ledger and remediation plans preserve durable issues, plans, steps, events, outcomes, replay, and state transitions.
- Analytical campaigns support evidence-driven improvement, learning quality, uncertainty reduction, campaign closure, knowledge promotion, cross-campaign validation, supersession, applicability, utility, and transfer outcomes.

Epistemic relevance:

- These systems already treat findings as governed, inspectable, and revisable.
- Cross-campaign supersession is closely related to contradictory evidence and knowledge revision.

Gap:

- There is no explicit epistemic finding type that says "this reasoning is vulnerable" or "this claim exceeds evidence."
- Learning utility is not yet tied to human judgment calibration or reasoning taxonomy.

Reuse recommendation:

- Reuse finding/improvement/campaign ledgers for remediation of epistemic risks.
- Avoid creating a separate issue system.

## Reuse Matrix

| Epistemic concern | Existing substrate | Repository | Current protection | Limitation | Reuse recommendation |
|---|---|---:|---|---|---|
| Evidence identity | Artifact Model, Collector | AnalyticsShinyApp | Durable artifacts, bundles, manifests | Does not classify human assertion or claim dependency | Reuse as storage and provenance anchor |
| Artifact completeness | Artifact Quality Policy | AnalyticsShinyApp | Component status, completeness score, graceful degradation | Completeness is not truth | Consume quality as one input to epistemic risk |
| Table evidence | Table Artifact Architecture | AnalyticsShinyApp | Backing data, previews, sort policy, sidecars | Does not map support/contradiction to claims | Add claim-evidence mappings |
| Business intent | Business Intent | AutoQuant | Mission/objective/strategy/tactic/KPI/risk/assumption/decision relationships | Assumptions not governed as epistemic assertions | Reference intent IDs from epistemic records |
| Variable role ambiguity | Variable Semantics | AutoQuant | Business, operational, analytical, causal, temporal roles | Does not score reasoning misuse | Reuse roles for statistical/causal reasoning checks |
| Decision alternatives | Decision Management | AutoQuant | Alternatives, uncertainty, optionality, recommendations, outcomes | Recommendation language not claim-governed | Gate recommendations through claim governance |
| Evidence-to-impact translation | Decision Valuation | AutoQuant | Source types, confidence, assumptions, validity range, guardrails | No longitudinal human judgment calibration | Extend with calibration records |
| Review and approval | Decision Workflow | AutoQuant, AnalyticsShinyApp | Frozen evidence packages, review requests, approvals, lifecycle | Review type does not yet capture epistemic review | Add epistemic review as review artifact/check |
| Human intervention | Partial in workflow/audit | Both | Reviews, approvals, GenAI audit events | Edits/overrides/narrative interventions not first-class | Add human intervention event contract |
| Contradictory evidence | Partial in campaigns/supersession | AnalyticsShinyApp | Knowledge promotion and supersession concepts | Not claim-level | Add claim support/contradiction maps |
| Causal overclaiming | Causal Intelligence | AutoQuant | Readiness gates, prohibited claims, authority, design checks | Causal only; not general reasoning integrity | Reuse pattern for all claim governance |
| Statistical reasoning failures | Partial in model/causal diagnostics | AutoQuant | Metrics, diagnostics, readiness | No unified taxonomy | Add reasoning taxonomy and assessment records |
| Abductive reasoning | Missing | None | None | Alternative explanations not formally scored | Add dedicated abductive assessment contract |
| Informal fallacies | Missing | None | None | No structured detection or review | Add taxonomy as signal/review layer |
| Cognitive bias exposure | Missing | None | None | Risk of overreach, cherry-picking, confirmation bias | Add exposure flags without diagnosing people |
| Organizational pressure | Missing | None | Authority exists | Authority can be mistaken for truth | Add organizational epistemic threat flags |
| GenAI epistemic boundaries | GenAI service/action/audit | AnalyticsShinyApp | Registered actions, audit, no raw payload logs | Not role-specific for claims/reasoning | Add epistemic policy gates |
| Sensitive actor data | Partial storage/audit sanitization | AnalyticsShinyApp | Path/payload sanitization | No dedicated sensitive review model | Store minimal role/source metadata; avoid employee scoring |
| Pattern-level exposure | Campaign/ledger systems | AnalyticsShinyApp | Event histories, campaign learning | No epistemic aggregation | Aggregate risks by class, not by personality or motive |
| System-level exposure | Mission Control, QA, cross-system invariants | AnalyticsShinyApp | Health/status, invariants | No epistemic health center | Surface counts and gates in Mission Control |

## Existing Protections That Should Not Be Rebuilt

Do not rebuild:

- artifact storage;
- collector manifests;
- table sidecars;
- screenshot/export pipelines;
- decision workflow lifecycle;
- approval workflows;
- GenAI action registry;
- GenAI audit ledger;
- remediation/improvement ledgers;
- causal readiness gates;
- decision valuation source-type handling;
- business intent and variable semantics.

Epistemic Integrity should reuse these and add missing meaning.

## Missing Concepts

The following concepts are not sufficiently represented today:

### Human Assertion

A human statement should be recorded as evidence with source, context, confidence, class, review status, and dependencies. It should not silently become fact.

Suggested fields:

- assertion_id;
- assertion_text;
- assertion_class;
- source_role;
- source_context;
- entered_by;
- entered_at;
- evidence_refs;
- confidence_expression;
- uncertainty_expression;
- status;
- review_required;
- sensitivity;
- downstream_claim_refs.

### Human Intervention Event

A human intervention is an event that changes the reasoning surface. It may be benign, necessary, risky, or invalid.

Examples:

- assumption entered;
- treatment definition edited;
- exclusion rule changed;
- adjustment variable added or removed;
- narrative wording changed;
- contradictory evidence dismissed;
- recommendation overridden;
- approval granted despite unresolved evidence;
- GenAI draft accepted;
- report language softened or strengthened.

### Claim Record

A claim is a statement the system may communicate or use for decisions.

Suggested classes:

- descriptive claim;
- predictive claim;
- causal claim;
- valuation claim;
- recommendation claim;
- decision-readiness claim;
- narrative claim;
- uncertainty claim.

Each claim should record evidence support, contradictory evidence, permitted language, prohibited language, claim strength, review status, and materiality.

### Reasoning Risk Assessment

Reasoning risk should be assessed separately from artifact quality.

Assessment dimensions:

- logic;
- evidence completeness;
- statistical integrity;
- causal integrity;
- abductive quality;
- alternative coverage;
- cognitive-bias exposure;
- rhetorical fidelity;
- human-intervention exposure;
- organizational-pressure exposure;
- conflict-of-interest exposure;
- review independence;
- provenance completeness;
- recommendation legitimacy.

### Abductive Assessment

Abductive reasoning is not a fallacy by default. It is inference to a plausible explanation under uncertainty. The system should distinguish:

- best explanation;
- alternative explanations;
- missing discriminating evidence;
- explanatory scope;
- parsimony;
- coherence with known evidence;
- evidence that would falsify the explanation;
- confidence appropriate to the evidence.

### Bayesian Evidence Update Record

The system should preserve transparent evidence updating without pretending to have opaque omniscience.

Suggested fields:

- prior belief or prior state;
- new evidence;
- evidence class;
- direction of update;
- magnitude of update;
- rationale;
- posterior state;
- remaining uncertainty;
- evidence that would reverse the update.

### Judgment Calibration Record

Human judgment calibration should be specific and outcome-based. It must not become a universal trust score.

Allowed:

- calibration by judgment class;
- calibration by domain;
- calibration by realized outcomes;
- calibration by review context;
- aggregate advisory calibration.

Prohibited:

- hidden trust scores;
- employee scoring;
- personality inference;
- motive inference;
- surveillance.

## Recommended Additive Contracts

The following contracts should be considered for a future implementation phase. They are listed here for boundary-setting only.

| Contract | Owning repo | Purpose | Reuses |
|---|---|---|---|
| `aq_epistemic_source_classification()` | AutoQuant | Classify observed, computed, assumed, asserted, reviewed, approved, GenAI-suggested, imported, missing, unsupported | Decision Valuation source types |
| `aq_human_assertion()` | AutoQuant | Capture human assertions as evidence | Business Intent, Artifact Model |
| `aq_human_intervention_event()` | AutoQuant | Capture edits, overrides, narrative changes, exclusions, assumption changes, approvals | Decision Workflow, GenAI Audit |
| `aq_epistemic_claim()` | AutoQuant | Govern claims, language, support, contradiction, materiality | Causal prohibited-claim pattern |
| `aq_reasoning_risk_assessment()` | AutoQuant | Assess reasoning integrity dimensions | Artifact Quality, Causal readiness |
| `aq_abductive_assessment()` | AutoQuant | Evaluate explanations and alternatives | Investigation Planning, Evidence Routing |
| `aq_evidence_update_record()` | AutoQuant | Record transparent Bayesian-style updates | Knowledge State, Campaign Learning |
| `aq_judgment_calibration_record()` | AutoQuant | Record outcome-based calibration without person scoring | Decision Workflow outcomes |
| `epistemic_integrity_workspace` | AnalyticsShinyApp | UI/workbench integration | Mission Control, Evidence Inbox |
| `qa_epistemic_integrity_framework()` | Both | Deterministic QA | Existing QA conventions |

## Risk Flag Vocabulary

The requested flags fit naturally as internal assessment statuses:

- `signal_only`;
- `low_epistemic_exposure`;
- `moderate_review_required`;
- `high_material_risk`;
- `critical_integrity_gate`;
- `reviewed`;
- `resolved`;
- `false_positive`;
- `disputed`.

Recommended interpretation:

- `signal_only`: visible but nonblocking;
- `low_epistemic_exposure`: record and monitor;
- `moderate_review_required`: require human review before high-stakes use;
- `high_material_risk`: block recommendations or causal/valuation claims until review;
- `critical_integrity_gate`: block downstream claim, recommendation, or estimation;
- `reviewed`: review completed;
- `resolved`: issue has a documented resolution;
- `false_positive`: explicitly dismissed with rationale;
- `disputed`: unresolved disagreement remains.

## Reasoning Taxonomy Fit

The requested taxonomy should be represented as assessment families, not as accusations.

### Formal Logic

Examples:

- contradiction;
- circular reasoning;
- invalid implication;
- equivocation of terms;
- inconsistent premises.

Use:

- primarily deterministic checks when structured claims exist.

### Informal Fallacies

Examples:

- overgeneralization;
- false dichotomy;
- appeal to authority;
- post hoc reasoning;
- cherry-picking;
- moving goalposts.

Use:

- signal and review prompts, not automatic accusations.

### Cognitive Bias Exposure

Examples:

- confirmation-bias exposure;
- anchoring exposure;
- survivorship-bias exposure;
- availability-bias exposure;
- sunk-cost exposure.

Use:

- exposure language only. Do not diagnose the person.

### Statistical Reasoning Failures

Examples:

- small-sample overclaiming;
- multiple-comparison neglect;
- base-rate neglect;
- regression-to-mean neglect;
- selection bias;
- extrapolation beyond support.

Use:

- deterministic diagnostics where possible.

### Causal Reasoning Failures

Examples:

- treatment timing ambiguity;
- post-treatment adjustment;
- collider adjustment;
- unmeasured confounding;
- reverse causality;
- mediation mistaken for total effect;
- selection-on-outcome.

Use:

- build on Causal Intelligence readiness checks.

### Abductive Reasoning

Examples:

- plausible explanation without discriminating evidence;
- failure to compare alternatives;
- explanatory story outpacing evidence.

Use:

- dedicated abductive assessment contract.

### Organizational Epistemic Threats

Examples:

- authority pressure;
- incentive conflict;
- review independence weakness;
- suppressed contradictory evidence;
- deadline pressure;
- narrative predetermined before evidence.

Use:

- process exposure, not motive accusation.

## Relationship to Observational Causal Intelligence

Epistemic Integrity is especially important before observational effect estimation because observational designs are vulnerable to human choices that strongly affect conclusions:

- treatment definition;
- comparison condition;
- eligibility;
- time zero;
- baseline window;
- outcome window;
- adjustment set;
- overlap remediation;
- exclusion rules;
- sensitivity plan;
- narrative claim language.

Future observational estimation should not proceed unless:

- human-authored assumptions are recorded;
- intervention events are preserved;
- adjustment-set choices have provenance;
- contradictory design evidence is not suppressed;
- claim language is governed;
- unmeasured-confounding risk is visible;
- review status is explicit.

## GenAI Boundaries

GenAI may:

- summarize epistemic diagnostics;
- explain why a risk flag exists;
- suggest alternative explanations;
- draft balanced narrative language;
- propose questions for reviewers;
- compare evidence packages;
- identify missing evidence candidates.

GenAI may not:

- diagnose intent;
- infer dishonesty;
- accuse misconduct;
- assign hidden trust scores;
- score employees;
- fabricate interventions;
- suppress contradictory evidence;
- change findings;
- approve decisions;
- weaken prohibited claim language;
- override governance gates;
- execute analysis or estimation outside registered actions.

## Mission Control and UI Implications

Future UI should surface epistemic integrity without creating a punitive experience.

Recommended displays:

- Epistemic Integrity status in Mission Control;
- Evidence Inbox entries for unresolved epistemic issues;
- claim-level support and contradiction panels;
- human intervention timeline;
- review readiness gates;
- narrative language warnings;
- observational-causal integrity status before estimation;
- report caveats and prohibited language notices.

Avoid:

- person-centered blame;
- trust dashboards by employee;
- accusation language;
- opaque scores;
- constant red alerts for low-risk signals.

## QA Plan

Future QA should verify:

- source classification vocabulary;
- human assertions are not treated as facts;
- human interventions are captured as events;
- event-level, pattern-level, and system-level exposure can be summarized;
- claim records include support, contradiction, strength, permitted language, prohibited language, and review status;
- reasoning taxonomy returns signal/review/gate statuses without accusations;
- abductive assessment preserves alternatives and missing discriminating evidence;
- Bayesian update records remain explainable;
- judgment calibration is class/domain/outcome-specific and not a universal trust score;
- GenAI cannot create, suppress, or approve claims;
- observational causal planning can consume epistemic readiness before estimation;
- reports render diagnostics/caveats without failing;
- Mission Control shows unresolved high-risk gates;
- sensitive actor details are not exposed where not authorized.

## Implementation Sequence Recommendation

### Phase 1A: Review and Boundary Acceptance

This document. No code.

### Phase 1B: Portable AutoQuant Contracts

Implement minimal typed records and deterministic validators:

- source classification;
- human assertion;
- human intervention event;
- claim governance;
- reasoning risk assessment;
- abductive assessment;
- evidence update;
- judgment calibration.

No UI. No estimation. No GenAI autonomy.

### Phase 1C: AnalyticsShinyApp Integration

Wire records into:

- project artifacts;
- collector;
- Evidence Inbox;
- Mission Control;
- Decision Workflow;
- Causal Intelligence pages;
- reports.

### Phase 1D: GenAI Guardrails

Use existing GenAI policy/action/audit system to support read-only explanation and bounded draft language only.

### Phase 1E: QA and Installed Validation

Add deterministic QA in AutoQuant and AnalyticsShinyApp and include in installed validation contracts.

## Open Questions

1. Which actor/source fields should be stored in project files versus redacted or role-only?
2. What is the minimum viable claim-strength vocabulary?
3. Which epistemic flags are warning-only versus hard gates for observational causal estimation?
4. How should conflicting reviews be represented without forcing consensus?
5. Should claim governance attach to all reports or only high-materiality reports?
6. How should pattern-level exposure be aggregated without becoming person-level scoring?
7. What is the correct review process for `false_positive` and `disputed` flags?
8. How should calibration be displayed so it improves learning without creating a hidden trust score?

## Go / No-Go Assessment

Go, with constraints.

The existing architecture is strong enough to support Epistemic Integrity without major redesign. The work should proceed only as an additive layer that reuses artifacts, collector memory, decision workflow, causal readiness, valuation source types, GenAI audit, improvement ledgers, and Mission Control.

Do not implement observational estimators, optimization, autonomous actions, employee scoring, motive inference, or hidden trust scoring as part of this layer.

The immediate product value is making reasoning vulnerability visible before the system makes stronger causal, financial, narrative, or decision claims.

## Phase 1 Implementation Status

Phase 1 is implemented and documented in `docs/epistemic_integrity_phase1.md`.

Implemented:

- portable AutoQuant epistemic integrity contracts;
- structured intervention provenance;
- claim records with claim strength and evidence strength;
- deterministic initial finding detectors;
- claim-to-evidence assessment;
- epistemic quality gates;
- adjudication records;
- canonical epistemic integrity artifact envelope;
- AnalyticsShinyApp wrapper and QA;
- Knowledge Compilation Runtime source registration and Epistemic Runtime bundle linkage.

Deferred constraints remain unchanged: no actor reputation scoring, no hidden credibility scoring, no autonomous adjudication, no automatic approval, and no consequential action execution.
