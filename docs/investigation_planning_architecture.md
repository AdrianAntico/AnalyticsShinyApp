# Investigation Planning Architecture

## Purpose

Investigation Planning is the reasoning layer that transforms a business question into an analytical plan.

It sits between Business Question, Knowledge State, and the evidence stack.

It is not Evidence Routing. Evidence Routing selects concrete evidence artifacts and components.

It is not Context Optimization. Context Optimization decides how to satisfy evidence needs efficiently under constraints.

It is not Agentic Lab. No execution or autonomy is implied.

Investigation Planning answers:

- What are we trying to learn?
- What hypotheses should be considered?
- What evidence is required?
- What analyses or artifacts are needed?
- What evidence already exists?
- What gaps remain?
- When should the investigation stop?
- What would make the investigation decision-ready?

## Core Philosophy

A business question rarely maps directly to artifacts.

The correct transformation is:

```text
Business Question
-> Knowledge State
-> Hypotheses
-> Knowledge Gaps
-> Investigation Plan
-> Evidence Requirements
-> Evidence Routing
-> Reasoning
-> Decision
```

The Investigation Plan should become the first analytical artifact created after a question is asked.

This matters because analytical work is not merely evidence retrieval. Analysts do not jump from "Which creative attributes should we test?" directly to "retrieve SHAP plot." They form hypotheses, identify knowns and unknowns, decide what evidence would discriminate among possibilities, choose stopping criteria, and only then gather or route evidence.

## Architectural Position

The updated analytical intelligence loop is:

```text
Business Question
-> Knowledge State
-> Investigation Plan
-> Knowledge Gap
-> Evidence Sufficiency
-> Context Optimization
-> Evidence Routing
-> Evidence Plan
-> Context Strategy
-> Reasoning
-> Decision
-> Observability
-> Learning
-> Updated Knowledge State
```

Investigation Planning orchestrates the middle. It turns Knowledge State into a plan for evidence acquisition and reasoning.

## Core Concepts

### Investigation

An Investigation is a bounded analytical effort to answer a business question, test hypotheses, reduce uncertainty, and determine whether a decision is ready.

### Investigation Plan

An Investigation Plan is the structured plan for an investigation. It records the question, known facts, unknowns, competing hypotheses, evidence requirements, required analyses, required artifacts, risks, stopping criteria, decision criteria, expected cost, expected time, and alternative paths.

### Hypothesis

A Hypothesis is a plausible explanation or claim to be tested. It already exists in Knowledge State, but Investigation Planning operationalizes it.

### Alternative Hypothesis

An Alternative Hypothesis is a competing explanation or claim that could also explain the current evidence.

Alternative hypotheses matter because investigations should avoid confirming the first plausible story.

### Evidence Requirement

An Evidence Requirement is a statement of what evidence is needed to test a hypothesis, resolve an unknown, or reach a decision-readiness threshold.

Evidence Requirements are abstract needs. Evidence Routing later maps them to concrete artifacts or artifact components.

### Required Analysis

Required Analysis is an analysis that must be run to produce needed evidence.

Examples:

- SHAP interaction analysis
- segment stability check
- calibration analysis
- drift analysis
- missingness summary
- residual diagnostics

### Required Artifact

A Required Artifact is an artifact type or specific artifact needed by the investigation.

Examples:

- SHAP importance table
- SHAP dependence plot
- segment summary table
- calibration curve
- model readiness diagnostic
- collector manifest summary

### Stopping Criterion

A Stopping Criterion defines when the investigation should stop gathering evidence.

Examples:

- decision readiness reached
- marginal information gain below threshold
- contradiction resolved
- budget exhausted
- required evidence unavailable

### Decision Criterion

A Decision Criterion defines what must be true before a decision can be made.

Examples:

- at least Reasonable decision readiness
- no unresolved critical diagnostics
- top creative candidates stable across segment and time
- calibration acceptable for deployment
- no evidence of leakage

### Evidence Escalation

Evidence Escalation is the planned movement from cheaper or weaker evidence to deeper, more expensive, or higher-confidence evidence when current evidence is insufficient.

Examples:

- from caption/metadata to table preview
- from table preview to full table
- from existing SHAP importance to new SHAP interaction analysis
- from aggregate summary to segment-level analysis
- from preliminary model diagnostics to full model assessment

### Investigation Confidence

Investigation Confidence is the current confidence that the investigation can answer the business question at the requested decision-readiness level.

It is related to Decision Readiness but belongs to the investigation process.

### Investigation Completion

Investigation Completion is the state where the investigation has met its stopping criterion, reached a decision criterion, or explicitly ended because evidence is unavailable or cost exceeds value.

### Investigation Failure

Investigation Failure occurs when the investigation cannot answer the question because of missing evidence, contradictory evidence, insufficient data, unavailable analyses, unacceptable uncertainty, or blocked execution.

Failure should become a documented outcome, not disappear.

## Investigation Plan Contract

Every Investigation Plan should be able to record:

```text
question
project_id
run_scope
investigation_strategy
investigation_state
known_facts
unknowns
assumptions
competing_hypotheses
evidence_requirements
required_analyses
required_artifacts
artifacts_already_available
evidence_gaps
potential_risks
stopping_criteria
decision_criteria
expected_confidence
expected_cost
expected_time
alternative_paths
evidence_escalation_plan
```

This structure should be readable by humans and future AI agents.

## Investigation States

Recommended states:

- Not Started
- Planning
- Collecting Evidence
- Reasoning
- Decision Ready
- Needs More Evidence
- Blocked
- Completed
- Archived

### Not Started

A question exists, but no investigation plan has been created.

### Planning

The system or analyst is identifying known facts, hypotheses, evidence requirements, and criteria.

### Collecting Evidence

The investigation is gathering existing evidence or requesting required analysis.

### Reasoning

The investigation has enough evidence for synthesis, comparison, explanation, or decision-readiness evaluation.

### Decision Ready

The investigation has reached the required decision criterion.

### Needs More Evidence

The current evidence is insufficient, but the next evidence requirements are known.

### Blocked

The investigation cannot proceed because required evidence, data, provider capability, module support, or user input is unavailable.

### Completed

The investigation has ended with a decision, finding, recommendation, or explicit failure.

### Archived

The investigation is preserved for history but no longer active.

## Investigation Strategies

Investigation strategy changes depth, confidence thresholds, evidence budget, and stopping criteria.

### Quick

Purpose: produce a fast preliminary answer.

Behavior:

- use existing evidence first
- avoid expensive analysis
- accept lower confidence
- surface caveats prominently

### Balanced

Purpose: produce a practical answer with reasonable evidence.

Behavior:

- combine existing artifacts with targeted missing evidence
- use moderate confidence threshold
- balance cost and certainty

### Thorough

Purpose: produce a well-supported answer.

Behavior:

- seek multiple supporting evidence types
- investigate contradictions
- require diagnostics and quality checks

### Critical Decision

Purpose: support high-stakes action.

Behavior:

- require high decision readiness
- escalate evidence aggressively
- include contradictions, weak evidence, missing evidence, and assumptions
- cost is secondary to confidence

### Scientific

Purpose: test hypotheses rigorously.

Behavior:

- emphasize alternative hypotheses
- require explicit assumptions
- prefer reproducibility and falsifiability
- document negative evidence

### Executive

Purpose: support leadership decision-making.

Behavior:

- emphasize decision criteria, risk, recommendations, confidence, and caveats
- compress technical detail
- retain evidence traceability

## Relationship To Knowledge State

Knowledge State answers what is known, unknown, assumed, contradicted, and decision-ready.

Investigation Planning uses Knowledge State to create a plan.

Knowledge State supplies:

- known facts
- assumptions
- unknowns
- validated findings
- open questions
- decision readiness
- future evidence

Investigation Planning returns:

- hypotheses
- required evidence
- stopping criteria
- decision criteria
- investigation confidence
- evidence escalation plan

## Relationship To Evidence Routing

Evidence Routing should not receive a vague business question when an Investigation Plan is available.

It should receive Evidence Requirements and Required Artifacts.

Example:

```text
Business Question:
Which creative attributes should we test?

Evidence Requirement:
Identify consistently important creative attributes and validate stability across audience/channel/time.

Evidence Routing:
Select SHAP importance, dependence, interaction diagnostics, segment summaries, and time stability artifacts.
```

Investigation Planning says what evidence is required.

Evidence Routing finds or selects that evidence.

## Relationship To Context Optimization

Investigation Planning determines what evidence would increase confidence.

Context Optimization determines how to acquire or represent that evidence efficiently.

Example:

- Investigation Plan says SHAP interaction is needed.
- Context Optimization checks provider/model/token/time constraints.
- Evidence Routing determines whether interaction artifacts exist.
- Context Strategy decides whether to use screenshot, table preview, JSON, or diagnostics.

## Relationship To Marginal Information Gain

Investigation Planning uses MIG to prioritize future evidence.

The question is:

What evidence would increase confidence the most?

Context Optimization asks:

How can we obtain or represent that evidence at acceptable cost?

Evidence Escalation uses MIG to decide when to move from cheap evidence to deeper evidence.

## Example: Creative Attribute Testing

Question:

Which creative attributes should we test?

Investigation Strategy:

Balanced.

Known Facts:

- Creative A appears important in existing model outputs.
- Creative B appears nonlinear.
- Creative C may be unstable over time.

Unknowns:

- Whether Creative A interacts with audience.
- Whether Creative B's nonlinear effect is stable by channel.
- Whether Creative C instability is signal or sparse data.

Competing Hypotheses:

- H1: Creative A is a broadly reliable test candidate.
- H2: Creative A only matters for specific audience segments.
- H3: Creative B has a nonlinear saturation effect worth testing.
- H4: Creative C appears unstable because data are sparse.

Evidence Requirements:

- feature importance ranking
- dependence behavior
- interaction with audience or channel
- stability over time
- segment-level summaries

Required Artifacts:

- SHAP importance table
- SHAP dependence plots
- SHAP interaction diagnostics or interaction artifacts
- time-sliced importance summary
- segment summary table

Artifacts Already Available:

- SHAP importance
- SHAP dependence for Creative A and Creative B

Evidence Gaps:

- SHAP interaction unavailable
- channel-level stability not generated
- segment summaries sparse

Potential Risks:

- misleading aggregate effects
- sparse segment data
- model instability

Stopping Criteria:

- at least two candidate creative attributes reach Reasonable decision readiness
- or interaction/stability evidence remains unavailable and investigation is marked blocked

Decision Criteria:

- candidate has consistent importance
- effect direction or shape is interpretable
- no unresolved critical diagnostic
- segment/time instability is understood or acceptable

Expected Confidence:

Reasonable.

Expected Cost:

Moderate.

Expected Time:

One focused analysis pass.

Alternative Paths:

- if SHAP interaction unavailable, use segment summaries and dependence stratification
- if segment data sparse, recommend targeted data collection before decision

Decision Ready?

No. Continue collecting targeted evidence.

## Failure Behavior

Investigation failure should be explicit.

Examples:

- required artifacts do not exist
- required module is unavailable
- data are too sparse
- contradictions cannot be resolved
- provider lacks vision capability
- token budget prevents required evidence
- decision criteria cannot be met

Failure output should include:

- failed requirement
- reason
- severity
- evidence attempted
- missing evidence
- recommendation
- whether decision readiness is blocked

## Non-Goals

Investigation Planning does not execute analyses.

Investigation Planning does not replace Evidence Routing.

Investigation Planning does not choose context strategy directly.

Investigation Planning does not implement Agentic Lab.

Investigation Planning does not create autonomous action.

Investigation Planning does not require a new UI immediately.

## Acceptance Contract

Analytics Workstation should now distinguish:

- a business question
- a knowledge state
- an investigation plan
- an evidence requirement
- an evidence plan
- a context strategy
- a reasoning result
- a decision

This makes the analytical intelligence loop executable by humans now and by future AI agents later.

