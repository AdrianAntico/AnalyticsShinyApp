# Investigation Planning

Investigation Planning is the architecture for turning a business question into analytical work.

A business question is rarely precise enough to route directly to evidence. It may sound simple: Which creative attributes should we test? Should this model be deployed? What are the biggest model risks? Where should we spend another hour analyzing? But each of these questions hides hypotheses, assumptions, unknowns, required analyses, decision criteria, and stopping conditions.

The system already knows how to preserve evidence. It knows how to represent artifacts, collect them, route them, encode them, and reason over them. With Knowledge State, it can distinguish what is known from what remains uncertain.

Investigation Planning is the next step. It asks how analytical work should proceed.

## The Basic Transformation

The transformation is:

```text
Question
-> Hypotheses
-> Knowledge Gaps
-> Investigation Plan
-> Evidence Requirements
-> Evidence Routing
-> Reasoning
-> Decision
```

This is not a new routing layer. Routing selects evidence. Investigation Planning decides what evidence should be needed in the first place.

## Why It Matters

Without Investigation Planning, the system risks treating every question as a retrieval problem.

Question: "Which creative attributes should we test?"

Naive response:

- retrieve SHAP importance
- summarize top features

Better response:

- identify candidate hypotheses
- check what is already known
- identify unknowns
- determine whether importance alone is sufficient
- require dependence, interactions, stability, and segment summaries when appropriate
- define decision criteria
- stop only when evidence supports a test recommendation

The second response is what analysts actually do. It is not just retrieval. It is investigation.

## Investigation As First Artifact

The Investigation Plan should become the first analytical artifact created after a question is asked.

This plan should be durable, inspectable, and revisable. It should record the reasoning path before evidence is collected. This prevents the system from hiding its analytical strategy.

An Investigation Plan should include:

- question
- known facts
- unknowns
- assumptions
- competing hypotheses
- evidence requirements
- required analyses
- required artifacts
- artifacts already available
- evidence gaps
- risks
- stopping criteria
- decision criteria
- expected confidence
- expected cost
- expected time
- alternative paths

This is valuable for humans and future AI agents. A human analyst can inspect the plan before spending time. An AI agent can use the plan as a bounded task contract. Mission Control can display investigation state. Artifact Studio can show the plan as a narrative/control artifact. The collector can preserve it as part of project memory.

## Investigation Strategies

Not every investigation should be equally deep.

A Quick investigation may use only available evidence and produce a preliminary answer with caveats.

A Balanced investigation may combine existing evidence with targeted missing artifacts.

A Thorough investigation may require multiple evidence types and contradiction checks.

A Critical Decision investigation may escalate aggressively until decision readiness is high.

A Scientific investigation may emphasize alternative hypotheses, falsifiability, negative evidence, and reproducibility.

An Executive investigation may emphasize decision criteria, risk, recommendation, and confidence while preserving traceability.

These strategies are not context strategies. They do not decide screenshot versus table preview. They define analytical posture.

## Evidence Requirements

Evidence Requirements are the central output of Investigation Planning.

An Evidence Requirement is not yet an artifact. It is a need.

For example:

- establish feature importance
- inspect nonlinear behavior
- test interaction with audience
- check stability over time
- validate model calibration
- rule out leakage
- confirm missingness is acceptable
- compare performance across segments

Evidence Routing later maps these needs to artifacts.

This separation matters. If an artifact is missing, the requirement remains. The system can then request future evidence or mark the investigation blocked. Without Evidence Requirements, missing artifacts simply disappear from the context.

## Stopping And Decision Criteria

Analytical work needs stopping rules.

Without stopping criteria, an investigation can collect evidence forever. Without decision criteria, it can produce evidence without knowing whether action is justified.

Stopping criteria may include:

- decision readiness reached
- marginal information gain below threshold
- contradiction resolved
- evidence budget exhausted
- required analysis unavailable
- confidence target impossible with current data

Decision criteria may include:

- no unresolved critical diagnostics
- finding stable across key segments
- model calibration acceptable
- no material leakage
- candidate attributes have interpretable effects
- evidence supports at least Reasonable decision readiness

These criteria make the investigation honest. They make it possible to say "continue," "stop," "blocked," or "decision ready."

## Evidence Escalation

Investigations often proceed in layers.

Start with cheap evidence. If it is sufficient, stop. If not, escalate.

Example:

1. Use existing captions and metadata.
2. Add table previews.
3. Add screenshots.
4. Add full tables if safe.
5. Generate missing diagnostics.
6. Run deeper module analysis.
7. Request new data or human input.

Evidence Escalation is how Investigation Planning connects to Marginal Information Gain. Each escalation should justify itself by expected confidence gain.

## Relationship To Knowledge State

Knowledge State says:

- what is known
- what is assumed
- what is unknown
- what evidence exists
- what readiness level has been reached

Investigation Planning says:

- what hypotheses should be tested
- what evidence is required
- what analysis should be run
- when to stop
- what decision criteria apply

Knowledge State is the current map.

Investigation Planning is the route.

## Relationship To Evidence Routing

Evidence Routing should receive a plan, not a vague question.

If the investigation requires "test stability over time," routing can look for time-sliced importance artifacts, temporal diagnostics, trend plots, or future required analysis.

If the investigation requires "rule out leakage," routing can select leakage diagnostics, readiness recommendations, and relevant metadata.

If the required evidence is missing, routing can report missing evidence instead of returning an incomplete answer.

## Relationship To Future AI Agents

Investigation Planning is not Agentic Lab, but it is a prerequisite for safe agentic analysis.

An agent should not improvise analytical work invisibly. It should produce or follow an Investigation Plan. The plan should show hypotheses, evidence requirements, stopping criteria, and risks. The user should be able to inspect it before execution.

This enables preview-before-commit without implementing autonomy now.

## Example

Question:

Which creative attributes should we test?

Investigation Plan:

Known:

- Creative A appears important.
- Creative B appears nonlinear.
- Creative C may be unstable.

Hypotheses:

- Creative A is broadly useful.
- Creative A only works for a specific audience.
- Creative B has saturation behavior worth testing.
- Creative C is unstable because of sparse data.

Evidence Needed:

- SHAP importance
- SHAP dependence
- interactions
- segment summaries
- time stability

Artifacts Available:

- SHAP importance
- dependence for Creative A
- dependence for Creative B

Evidence Missing:

- interaction artifacts
- channel-level stability
- robust segment summaries

Decision Ready?

No.

Next step:

Collect targeted interaction and stability evidence, or mark confidence as Reasonable at best if those analyses are unavailable.

## Validation Against Ontology v1

Investigation Planning integrates cleanly.

It does not break Knowledge State. It uses Knowledge State.

It does not replace Evidence Routing. It produces requirements for routing.

It does not replace Context Optimization. It identifies confidence needs; optimization decides efficient acquisition or representation.

It does not replace MIG. It uses MIG to prioritize evidence escalation.

It does not require Agentic Lab. It can be used by humans now and future agents later.

## Closing

Business users ask questions.

Analysts conduct investigations.

Analytics Workstation should model that process explicitly.

The Investigation Plan is the bridge between curiosity and evidence. It makes analytical intent inspectable before the system retrieves, generates, summarizes, or reasons.

