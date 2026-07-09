# Analytical Intelligence Loop

This document constructs the canonical closed-loop analytical operating model from Ontology v1. It does not introduce a new architectural layer. It validates how the existing concepts connect into a complete reasoning cycle.

## Executive Result

Ontology v1 can express the complete analytical lifecycle without requiring a new top-level concept.

The loop is not merely:

```text
Question -> Evidence -> Answer
```

The canonical loop is:

```text
Business Question
-> Knowledge State
-> Knowledge Gaps / Open Questions
-> Decision Readiness Target
-> Evidence Sufficiency Assessment
-> Context Optimization
-> Evidence Routing
-> Context Strategy
-> GenAI / Deterministic Reasoning
-> Finding / Recommendation / Decision
-> Artifact / Collector Update
-> Observability
-> Learning
-> Updated Knowledge State
```

The loop can be executed with or without GenAI. GenAI is an optional reasoning participant, not the owner of the loop.

## Canonical Loop

### 1. Business Question

Purpose: Establish the analytical intent.

Inputs:

- user question
- project context
- workflow stage
- decision stakes
- audience
- constraints

Outputs:

- target question
- decision context
- desired decision readiness
- likely evidence needs

Responsible ontology concepts:

- Project
- Knowledge State
- Evidence Strategy
- Decision Readiness
- Command Palette or Mission Control as possible entry surfaces

Notes:

Business Question does not need to become a new top-level concept because it already fits inside Knowledge State as an input node and future Knowledge Graph node.

### 2. Knowledge State

Purpose: Determine what is already known, believed, assumed, unknown, contradicted, and decision-ready.

Inputs:

- collector manifest
- artifact inventory
- previous findings
- diagnostics
- recommendations
- assumptions
- open questions
- decisions
- observations

Outputs:

- known findings
- assumptions
- unknowns
- contradictions
- knowledge gaps
- decision readiness
- future evidence candidates

Responsible ontology concepts:

- Knowledge State
- Knowledge
- Unknown
- Assumption
- Hypothesis
- Validated Finding
- Open Question
- Decision Readiness
- Knowledge Gap
- Contradiction
- Future Evidence

### 3. Knowledge Gaps And Open Questions

Purpose: Convert uncertainty into actionable analytical needs.

Inputs:

- Knowledge State
- desired decision readiness
- decision criticality
- known contradictions
- missing evidence

Outputs:

- ranked open questions
- future evidence candidates
- evidence sufficiency assessment

Responsible ontology concepts:

- Knowledge Gap
- Open Question
- Future Evidence
- Evidence Sufficiency
- Marginal Information Gain

### 4. Evidence Sufficiency

Purpose: Decide whether current evidence is enough for the question and decision context.

Inputs:

- current evidence
- quality
- trustworthiness
- contradictions
- assumptions
- decision readiness target

Outputs:

- sufficient evidence
- insufficient evidence
- preliminary answer
- request for future evidence
- next highest-value question

Responsible ontology concepts:

- Evidence Sufficiency
- Decision Readiness
- Trustworthiness
- Artifact Quality
- Marginal Information Gain

### 5. Context Optimization

Purpose: Determine the efficient way to satisfy the knowledge need under constraints.

Inputs:

- knowledge gap
- evidence sufficiency status
- provider capability
- token/latency/privacy constraints
- evidence strategy
- decision criticality

Outputs:

- optimization profile
- routing thresholds
- strategy constraints
- context budget
- allowable representations

Responsible ontology concepts:

- Context Optimization
- Evidence Strategy
- Marginal Information Gain
- Provider Capability
- Information Encoding

Important ordering clarification:

Context Optimization should remain above Evidence Routing in the operational stack when a knowledge need already exists, because it determines the constraints and objective for evidence selection. Evidence Routing then selects concrete evidence under that policy.

### 6. Evidence Routing

Purpose: Select concrete evidence artifacts and components.

Inputs:

- artifact inventory
- collector manifest
- artifact quality
- producer semantics
- analytical intent
- table policy
- trustworthiness indicators
- optimization profile
- knowledge gap

Outputs:

- Evidence Plan
- included artifacts
- excluded artifacts
- mention-only artifacts
- missing evidence
- deep-dive candidates
- reasons

Responsible ontology concepts:

- Evidence Routing
- Evidence Plan
- Artifact
- Evidence
- Producer Semantics
- Artifact Quality
- Table Policy

### 7. Context Strategy

Purpose: Represent selected evidence for the chosen consumer or provider.

Inputs:

- Evidence Plan
- render consumer
- provider capability
- artifact components
- information encoding options
- context budget

Outputs:

- context package
- included components
- screenshot/table/json choices
- downgrade reasons
- token estimates

Responsible ontology concepts:

- Context Strategy
- Information Encoding
- Consumer Encoding
- Render Target
- LLM Encoding
- Human Encoding

Ordering clarification:

Evidence Routing selects what evidence should be used. Context Strategy determines how each selected evidence item is represented. Context Optimization governs both through constraints and objective.

### 8. Reasoning

Purpose: Produce an answer, synthesis, recommendation, explanation, or decision support.

Inputs:

- deterministic facts
- context package
- evidence plan
- knowledge state summary
- user question

Outputs:

- finding
- recommendation
- explanation
- decision readiness update
- uncertainty statement
- future evidence request

Responsible ontology concepts:

- Deterministic Knowledge
- Probabilistic Reasoning
- GenAI Service
- Provider Adapter
- Knowledge State

Important constraint:

GenAI should not be the only reasoning path. Deterministic reasoning should answer deterministic questions directly.

### 9. Decision Or Analytical Action

Purpose: Use the reasoning result to support action or further inquiry.

Inputs:

- answer
- confidence
- decision readiness
- recommendations
- limitations
- open questions

Outputs:

- decision
- no-go
- request for more evidence
- next analysis
- report/brief

Responsible ontology concepts:

- Decision
- Decision Readiness
- Recommendation
- Future Evidence
- Mission Control
- Delivery

### 10. Artifact And Collector Update

Purpose: Preserve new evidence and project memory.

Inputs:

- generated artifacts
- reasoning outputs
- diagnostics
- recommendations
- report outputs
- telemetry references

Outputs:

- updated artifact inventory
- updated collector manifest
- updated project memory
- new evidence for future reasoning

Responsible ontology concepts:

- Artifact
- Artifact Bundle
- Project Artifact Collector
- Collector Manifest
- Render Target
- Artifact Quality

Clarification:

Reasoning outputs may become artifacts when they are preserved as narratives, diagnostics, recommendations, or project briefs.

### 11. Observability

Purpose: Record what happened and why.

Inputs:

- evidence plan
- context strategy
- provider/model
- included components
- token estimates
- latency
- success/failure
- user rating
- manual scores
- QA status

Outputs:

- telemetry
- audit trail
- learning inputs
- validation signals

Responsible ontology concepts:

- Observability
- GenAI Telemetry
- Routing Observability
- QA Contract
- Collector Manifest

### 12. Learning

Purpose: Refine future estimates and policies from observed outcomes.

Inputs:

- telemetry
- manual scores
- user ratings
- repeated experiment results
- QA outcomes
- contradicted findings
- corrected assumptions

Outputs:

- calibrated routing
- improved context strategies
- updated confidence
- refined evidence priorities
- updated Knowledge State

Responsible ontology concepts:

- Learning
- Observability
- Context Optimization
- Evidence Routing
- Knowledge State

Constraint:

Learning is future work and should remain transparent. No silent mutation.

### 13. Updated Knowledge State

Purpose: Close the loop.

Inputs:

- new evidence
- decisions
- observations
- contradictions
- learning outputs

Outputs:

- updated knowns
- updated assumptions
- updated unknowns
- updated decision readiness
- updated future evidence
- new open questions

Responsible ontology concepts:

- Knowledge State
- Knowledge
- Unknown
- Assumption
- Decision Readiness
- Future Evidence

## Closed Loop Summary

The loop closes because every reasoning act can update Knowledge State.

The system does not end at a report, answer, or generated artifact. It ends when project understanding is updated and made available for the next question.

## Minimal Loop Without GenAI

```text
Business Question
-> Knowledge State
-> Evidence Sufficiency
-> Deterministic Facts
-> Decision / Finding
-> Collector / Observability
-> Updated Knowledge State
```

This validates that the architecture is not dependent on AI execution.

## Full AI-Assisted Loop

```text
Business Question
-> Knowledge State
-> Knowledge Gap
-> Context Optimization
-> Evidence Routing
-> Context Strategy
-> GenAI
-> Synthesis / Recommendation
-> Observability
-> Learning
-> Updated Knowledge State
```

This validates that GenAI has a governed position inside the analytical loop.

