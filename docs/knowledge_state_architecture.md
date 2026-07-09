# Knowledge State Architecture

## Purpose

Knowledge State is the missing architectural layer above Evidence Routing.

Evidence Routing asks which evidence should be used for a task.

Knowledge State asks what the project already knows, what remains uncertain, what assumptions are being carried, what evidence supports each conclusion, and what evidence would most improve decision readiness.

This is not another routing system. It does not choose screenshots, table previews, JSON summaries, or context strategies. It determines what still needs to be learned. Context Optimization and Evidence Routing determine how to learn it efficiently.

## Core Philosophy

Evidence exists to reduce uncertainty.

Knowledge is evidence that has survived reasoning.

An artifact is not automatically knowledge. A table, plot, diagnostic, or recommendation becomes part of knowledge only when it has been interpreted, connected to a question or hypothesis, assigned confidence, and related to supporting or contradicting evidence.

The system should therefore distinguish:

- evidence that exists
- knowledge currently believed
- assumptions currently being carried
- unknowns still unresolved
- hypotheses not yet tested
- findings that have been validated
- decisions that are ready or not ready
- future evidence that would most improve confidence

## Architectural Position

The updated reasoning stack is:

```text
Project
-> Artifacts
-> Evidence
-> Knowledge State
-> Context Optimization
-> Evidence Routing
-> Context Strategy
-> GenAI
-> Observability
-> Learning
```

Knowledge State sits above Evidence Routing because it determines the analytical need.

Context Optimization sits below Knowledge State because it determines how to satisfy that need under constraints.

Evidence Routing sits below Context Optimization because it selects concrete evidence artifacts and components for the current task.

## Definitions

### Knowledge

Knowledge is a project-level conclusion, belief, or understanding supported by evidence and accompanied by confidence, assumptions, provenance, and known limitations.

Knowledge is not raw evidence. Knowledge is evidence that has survived interpretation.

### Evidence

Evidence is an artifact or artifact component used to support, weaken, test, or contradict a finding, hypothesis, recommendation, or decision.

### Unknown

An Unknown is a question, variable, relationship, risk, or condition whose truth is not currently established by available evidence.

### Assumption

An Assumption is a statement currently treated as true or acceptable for reasoning, despite incomplete validation.

Assumptions should be visible because decisions may depend on them.

### Hypothesis

A Hypothesis is a plausible but unvalidated claim that requires evidence.

Hypotheses are not findings. They are candidates for testing.

### Validated Finding

A Validated Finding is a claim supported by sufficient evidence for the current decision context.

Validation is contextual. A finding may be validated enough for exploration but not for a critical decision.

### Open Question

An Open Question is an explicit unresolved analytical question that should guide evidence acquisition.

Open Questions are the operational form of unknowns.

### Decision

A Decision is a potential or actual action that depends on knowledge, assumptions, confidence, risk, and decision readiness.

### Confidence

Confidence is the degree of support a knowledge claim currently has, given available evidence, contradictions, assumptions, and decision context.

This is evidence confidence. It is not model probability unless explicitly tied to a model output.

### Decision Readiness

Decision Readiness is the degree to which available knowledge is sufficient to support a decision.

It is not model confidence. It is evidence confidence.

Recommended levels:

- Insufficient Evidence
- Preliminary
- Reasonable
- High Confidence
- Critical Decision Ready

### Knowledge Gap

A Knowledge Gap is the difference between what is currently known and what must be known to reach the desired decision readiness.

### Evidence Sufficiency

Evidence Sufficiency is the state where additional evidence is unlikely to change the conclusion enough to justify its cost for the current decision context.

Evidence Sufficiency is evaluated relative to a question or decision.

### Contradiction

A Contradiction is evidence or a finding that conflicts with another finding, assumption, hypothesis, or recommendation.

Contradictions should be preserved, not averaged away.

### Supporting Evidence

Supporting Evidence increases confidence in a finding or decision.

### Weak Evidence

Weak Evidence provides limited support because of low quality, limited sample size, indirect relevance, missing diagnostics, low trustworthiness, or unresolved assumptions.

### Strong Evidence

Strong Evidence provides high support because it is relevant, trustworthy, validated, reproducible, and aligned with other evidence.

### Negative Evidence

Negative Evidence is evidence that a pattern, relationship, hypothesis, or expected artifact is absent or unsupported.

Examples include no detected interaction, no leakage found, no material drift, or a failed hypothesis.

Negative Evidence is still evidence.

### Missing Evidence

Missing Evidence is evidence expected or required for a question that is not currently available.

Missing evidence should be explicit because it affects confidence and readiness.

### Future Evidence

Future Evidence is evidence that could be generated, collected, or requested to reduce uncertainty or increase decision readiness.

## Knowledge State Questions

For any project, Knowledge State should eventually answer:

- What do we know?
- What do we believe?
- What are we assuming?
- What remains unknown?
- What evidence supports each conclusion?
- What evidence contradicts each conclusion?
- How confident are we?
- What evidence would increase confidence?
- What evidence would change the conclusion?
- What decisions are currently supported?
- What decisions are not ready?
- What is the next highest-value question?

## Knowledge State Object

A future Knowledge State object may contain:

```text
project_id
run_ids
timestamp
business_questions
findings
hypotheses
assumptions
unknowns
open_questions
decisions
decision_readiness
confidence
supporting_evidence
contradicting_evidence
weak_evidence
missing_evidence
future_evidence
knowledge_gaps
recommended_next_questions
```

The object should be reconstructable from artifacts, manifests, user questions, module outputs, diagnostics, recommendations, and future reasoning traces.

## Knowledge Graph

Knowledge State can eventually be represented as a Knowledge Graph.

Potential nodes:

- Artifacts
- Variables
- Models
- Features
- Findings
- Hypotheses
- Business Questions
- Experiments
- Recommendations
- Decisions
- Assumptions
- Unknowns
- Evidence Gaps

Potential edges:

- supports
- contradicts
- requires
- derived_from
- explains
- tests
- depends_on
- supersedes
- weakens
- strengthens
- suggests
- resolves

Example:

```text
Artifact: SHAP Dependence - Creative A
  supports -> Finding: Creative A has nonlinear response
  derived_from -> Model: CatBoost Run 003
  explains -> Recommendation: Test lower-frequency creative refresh

Finding: Creative C unstable over time
  supports -> Knowledge Gap: Need channel-level stability check
  requires -> Future Evidence: Time SHAP by channel

Assumption: Audience mix is stable
  contradicted_by -> Artifact: Segment Drift Diagnostic
```

## Decision Readiness

Decision Readiness describes whether current knowledge is sufficient for action.

### Insufficient Evidence

Available evidence does not support a reliable conclusion.

Typical state:

- major missing evidence
- unresolved contradictions
- low trustworthiness
- unclear assumptions
- no validated findings

### Preliminary

Evidence suggests a possible direction but is not enough for confident action.

Typical state:

- early signals
- weak or partial evidence
- important unknowns remain
- suitable for exploration

### Reasonable

Evidence supports a practical working decision, but important caveats remain.

Typical state:

- multiple supporting artifacts
- manageable uncertainty
- some assumptions explicit
- suitable for ordinary analytical next steps

### High Confidence

Evidence is strong, consistent, and sufficient for meaningful action.

Typical state:

- validated findings
- contradictions addressed
- diagnostics acceptable
- assumptions limited or tested

### Critical Decision Ready

Evidence is sufficient for high-stakes action.

Typical state:

- strong evidence
- high trustworthiness
- low unresolved contradiction
- sensitivity or robustness checks complete
- limitations explicit
- decision impact justifies evidence cost

## Relationship To Existing Architecture

### Artifact Model

Artifacts provide the raw evidence objects from which Knowledge State is built.

Knowledge State does not replace artifacts. It interprets them.

### Project Artifact Collector

The Collector preserves project memory. Knowledge State reasons over that memory.

The Collector answers what evidence exists. Knowledge State answers what that evidence means and what it leaves unresolved.

### Artifact Quality Policy

Artifact Quality contributes to confidence but does not equal confidence.

A complete artifact may still be weak evidence. An incomplete artifact may still be useful if its limitations are known.

### Producer Semantics

Producer Semantics help Knowledge State understand the role of an artifact: ranking, diagnostic, distribution, relationship, recommendation, interaction, or prediction.

### Information Encoding

Information Encoding determines how knowledge and evidence are represented for a consumer.

Knowledge State determines what needs to be communicated or learned.

### Evidence Routing

Evidence Routing selects evidence for a task.

Knowledge State determines the task need: a gap, unknown, hypothesis, contradiction, or decision-readiness target.

### Context Optimization

Context Optimization determines how to satisfy the knowledge need efficiently.

Knowledge State can ask: "What evidence would most improve confidence?" Context Optimization decides the lowest-cost, highest-value way to acquire or represent that evidence.

### Marginal Information Gain

MIG evaluates the expected value of additional evidence relative to cost.

Knowledge State supplies the current uncertainty, assumptions, contradictions, and decision-readiness gap needed to estimate MIG.

### GenAI

GenAI can help summarize, synthesize, and reason over Knowledge State, but it should not be the only source of Knowledge State.

Deterministic facts, artifacts, diagnostics, and manifests should populate as much as possible before probabilistic reasoning.

### Observability And Learning

Future observations may update knowledge, confidence, assumptions, routing, and recommendations.

Learning should be explicit and traceable. The system should record what changed and why.

## Example: Creative Attribute Testing

Question:

Which creative attributes should we test?

Possible Knowledge State:

```text
Known:
- Creative A is consistently important across recent model runs.
- Creative B appears nonlinear.
- Creative C is unstable over time.

Assumptions:
- Audience mix is stable enough for aggregate interpretation.
- Current model captures the main creative-response patterns.

Unknown:
- Whether Creative A interacts with audience segment.
- Whether Creative B's nonlinear pattern is stable by channel.
- Whether Creative C instability is caused by time, channel, or sparse data.

Supporting Evidence:
- SHAP importance ranking for Creative A.
- SHAP dependence artifact for Creative B.
- Time-sliced importance artifact for Creative C.

Weak Evidence:
- Segment summaries are sparse for some audience groups.
- Interaction artifacts were not generated.

Missing Evidence:
- SHAP interaction for Creative A by audience.
- Time SHAP for Creative C.
- Channel-level segment summaries.

Future Evidence:
- Generate SHAP interaction diagnostics.
- Generate channel-stratified summaries.
- Run stability check by time window.

Decision Readiness:
Reasonable, but not High Confidence.

Next Highest-Value Question:
Does Creative A's effect differ materially by audience segment?
```

This example shows the distinction between evidence and knowledge. The SHAP plot exists as evidence. The claim "Creative A is consistently important" is knowledge only if supported, contextualized, and assigned confidence. The unknown "interaction with audience" becomes a knowledge gap. The requested SHAP interaction becomes future evidence.

## Future Learning

Do not implement learning yet.

Future observations may update:

- knowledge claims
- confidence levels
- assumptions
- unknowns
- evidence sufficiency
- decision readiness
- routing priorities
- recommendations

Examples:

- A later run contradicts a previous feature-importance finding.
- A new diagnostic weakens confidence in a prior recommendation.
- A manual reviewer rates an LLM summary as inaccurate.
- A context strategy repeatedly performs well for a plot family.
- A missing evidence item is generated and resolves an open question.

Learning should remain transparent.

The system should record:

- previous knowledge state
- new evidence
- update reason
- confidence change
- affected decisions
- remaining unknowns

## Non-Goals

Knowledge State does not implement autonomous action.

Knowledge State does not replace Evidence Routing.

Knowledge State does not replace Context Optimization.

Knowledge State does not require a graph database today.

Knowledge State does not claim certainty where evidence is weak.

Knowledge State does not make GenAI the source of truth.

## Acceptance Contract

Analytics Workstation should now distinguish:

- Evidence: what exists to support reasoning.
- Knowledge: what is currently believed from evidence.
- Unknowns: what remains unresolved.
- Assumptions: what is being carried without full validation.
- Decision Readiness: whether evidence supports action.
- Future Evidence: what would most improve confidence.

This layer completes the conceptual bridge between artifact-centered evidence and intelligent analytical reasoning.
