# Knowledge State

Knowledge State is the layer that allows an evidence-centered analytical system to ask a higher-order question:

What do we know now?

The system already has artifacts. It has a collector. It has render targets, information encodings, evidence routing, context optimization, GenAI provider abstraction, observability, and the beginnings of learning infrastructure. Those layers make evidence available, representable, routable, and measurable.

But evidence is not yet knowledge.

Evidence is what supports reasoning. Knowledge is what survives reasoning. A plot is evidence. A table is evidence. A diagnostic is evidence. A recommendation is evidence. But the project-level understanding that "Creative A is consistently important," "Creative B appears nonlinear," or "the current model is not ready for high-stakes decisions" is knowledge only when evidence has been interpreted, connected, qualified, and assigned confidence.

Knowledge State is the architecture for that distinction.

## Why Evidence Is Not Enough

An evidence-centered system can preserve a large number of artifacts and still not know what it knows.

It may know that a SHAP importance plot exists. It may know that a calibration table exists. It may know that a target distribution exists. It may know that interaction diagnostics were skipped. But unless those artifacts are connected to findings, assumptions, unknowns, and decisions, the system only has an evidence inventory.

An evidence inventory answers:

- What artifacts exist?
- Which module produced them?
- What run do they belong to?
- What components are available?
- What quality metadata do they carry?

Knowledge State answers:

- What conclusions are currently supported?
- What assumptions are we relying on?
- What remains unknown?
- What evidence supports each conclusion?
- What evidence contradicts each conclusion?
- How confident are we?
- What evidence would improve confidence?
- Is the project ready for a decision?

The distinction matters because intelligent analytical reasoning is not only retrieval. It is uncertainty management.

## The Central Principle

Evidence exists to reduce uncertainty.

Knowledge is evidence that has survived reasoning.

This does not mean knowledge is permanent. It can be revised. It can be contradicted. It can be weakened by new diagnostics or strengthened by new runs. But knowledge has a different status from raw evidence. It is an interpreted state of the project.

The system should therefore preserve both:

- the evidence itself
- the current knowledge state derived from that evidence

The evidence remains inspectable. The knowledge remains challengeable.

## What Knowledge State Contains

A Knowledge State should contain several types of objects.

Knowledge: claims currently supported by evidence.

Unknowns: unresolved questions or relationships.

Assumptions: statements being treated as true despite incomplete validation.

Hypotheses: plausible claims that require testing.

Validated Findings: claims supported enough for a given decision context.

Open Questions: operational questions that should guide future evidence acquisition.

Decisions: potential or actual actions affected by the state of knowledge.

Confidence: evidence confidence, not merely model probability.

Decision Readiness: whether available evidence is sufficient for action.

Knowledge Gaps: differences between what is known and what must be known.

Contradictions: evidence or findings that conflict.

Supporting Evidence: evidence that increases confidence.

Weak Evidence: evidence that provides limited support.

Strong Evidence: evidence that provides high support.

Negative Evidence: evidence that an expected pattern or risk was not found.

Missing Evidence: evidence expected but unavailable.

Future Evidence: evidence that could reduce uncertainty.

These objects turn a project from a container of artifacts into a reasoning state.

## Decision Readiness

Decision Readiness is one of the most important concepts in Knowledge State.

It is not model confidence. It is not p-value confidence. It is not an LLM confidence score.

It is evidence confidence for action.

Suggested levels:

Insufficient Evidence: available evidence does not support a reliable conclusion.

Preliminary: evidence suggests a direction but important uncertainty remains.

Reasonable: evidence supports a practical working decision with known caveats.

High Confidence: evidence is strong, consistent, and sufficient for meaningful action.

Critical Decision Ready: evidence is strong enough for high-stakes action, with contradictions addressed, assumptions tested, and limitations explicit.

The same finding can have different readiness depending on the decision. A pattern may be reasonable enough for exploration but not ready for budget allocation. A model may be acceptable for internal triage but not for production deployment. A creative insight may justify a small test but not a major strategic shift.

Decision Readiness keeps the system honest about context.

## Knowledge State Above Routing

Knowledge State sits above Evidence Routing.

Evidence Routing asks:

Which artifacts or components should be used for this task?

Knowledge State asks:

What task matters now?

That difference is crucial.

If the project already knows enough to answer a question, routing may only need to gather supporting evidence for communication. If the project has a contradiction, routing may need evidence that explains the conflict. If the project has low decision readiness, routing may need evidence that reduces the most important uncertainty. If the project has a missing interaction artifact, routing may need diagnostics or future evidence requests.

Knowledge State determines the need.

Context Optimization determines how to satisfy the need efficiently.

Evidence Routing selects the concrete evidence.

Context Strategy represents the evidence for a provider or consumer.

GenAI reasons over the prepared context.

## Knowledge Graph

Knowledge State naturally points toward a future Knowledge Graph.

Artifacts, variables, models, features, findings, hypotheses, business questions, experiments, recommendations, decisions, assumptions, and unknowns can all become nodes.

Edges can describe relationships:

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
- resolves

The graph does not need to exist as infrastructure immediately. The concept matters first. The system should behave as though these relationships are meaningful even before a graph database exists.

## Example

Suppose the business question is:

Which creative attributes should we test?

The artifact inventory may contain:

- SHAP importance plot
- SHAP dependence plot for Creative A
- SHAP dependence plot for Creative B
- time-sliced importance table
- segment summary table
- interaction diagnostics

Evidence Routing can select some of these. But Knowledge State frames the reasoning:

Known:

- Creative A is consistently important.
- Creative B appears nonlinear.
- Creative C is unstable over time.

Assumptions:

- audience mix is stable enough for aggregate interpretation
- model captures the major creative-response patterns

Unknown:

- interaction with audience
- stability by channel
- whether Creative C instability is signal or sparse data

Evidence Needed:

- SHAP interaction
- time SHAP
- segment summaries

Decision Readiness:

Reasonable but not High Confidence.

Next highest-value question:

Does Creative A's effect differ materially by audience segment?

This is not just a better summary. It is a different architectural layer. It converts artifacts into a state of understanding.

## Relationship To Marginal Information Gain

Marginal Information Gain asks what additional evidence is worth its cost.

Knowledge State supplies the context for that question.

If confidence is low, contradictions are unresolved, and decision impact is high, additional evidence has higher expected value. If confidence is already high and the next artifact is redundant, marginal gain is low. If missing evidence would directly resolve the main unknown, marginal gain is high.

Without Knowledge State, MIG can only compare artifacts locally.

With Knowledge State, MIG can compare evidence against what the project actually needs to know.

## Relationship To GenAI

GenAI can help construct, explain, and update Knowledge State, but it should not be the only source of it.

Deterministic facts should come from deterministic systems:

- artifact inventory
- collector manifests
- module statuses
- diagnostics
- metadata
- table schemas
- available sidecars
- quality scores

Probabilistic reasoning can help synthesize:

- what findings mean
- which contradictions matter
- what assumptions are risky
- what evidence would increase confidence
- what question should be asked next

The future system should combine both.

## Learning

Knowledge State also creates a place for future learning.

When new evidence arrives, the system can update:

- findings
- assumptions
- confidence
- decision readiness
- open questions
- future evidence recommendations

But learning should not be silent.

The system should record what changed, why it changed, what evidence caused the update, and what uncertainty remains.

This preserves the project's ability to explain itself.

## Closing

Analytics Workstation began by learning how to preserve evidence.

Knowledge State is the next layer: learning how to preserve understanding.

Evidence tells the system what exists.

Knowledge tells the system what follows.

Unknowns tell the system what remains.

Decision Readiness tells the system whether action is justified.

Future Evidence tells the system what to learn next.

This is the missing bridge between artifact-centered architecture and intelligent analytical reasoning.
