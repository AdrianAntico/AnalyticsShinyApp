# Execution Mode / Delegation Policy Architecture

## Purpose

Execution Mode defines how the analytical intelligence loop is advanced by humans, software, and future AI agents.

It is not a new analytical ontology layer. It is an execution policy over the existing loop.

The loop defines what happens:

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
-> Decision / Finding / Recommendation
-> Collector / Delivery
-> Observability
-> Learning
-> Updated Knowledge State
```

Execution Mode defines who is allowed to move the system from one stage to the next, where approval is required, and what must be recorded.

## Core Distinction

Execution Mode and Evidence Strategy are orthogonal.

Evidence Strategy answers:

```text
How much evidence should be gathered?
```

Execution Mode answers:

```text
Who advances the loop?
```

Examples:

| Evidence Strategy | Execution Mode | Meaning |
| --- | --- | --- |
| Balanced | Guided | Recommended default for business users. The system recommends the next step and asks for approval. |
| Critical Decision | Assisted | High-stakes analysis with broader evidence and human review at major gates. |
| Cost Is Irrelevant | Autonomous | Broad evidence gathering with end-to-end execution and a complete audit trail, only where safe and explicitly permitted. |
| Efficient | Manual | Cheap exploratory learning where the user selects each step. |
| Thorough | Research / Step-by-Step | Methodological review with every intermediate decision visible. |

This distinction prevents two common mistakes:

- treating "thorough" as "autonomous"
- treating "manual" as "low evidence"

A user can request high evidence with human control, or low evidence with automation.

## Execution Modes

### Manual

The system explains options. The user chooses each next step.

Best for:

- learning
- new users
- trust building
- regulated settings
- methodology review

Behavior:

- recommendations are explanatory, not automatic
- every major loop transition requires user action
- evidence plans can be previewed but are not executed without approval
- GenAI calls are user-triggered
- delivery/export is user-triggered

Typical posture:

```text
System: "The next highest-value step is SHAP dependence for the top three features."
User: chooses whether to run it.
```

### Guided

The system recommends the next step and asks approval.

Best for:

- MBA/business users
- routine analytical workflows
- users learning the framework
- standard project progression

Behavior:

- the system selects a recommended next action
- the user sees the rationale
- the user approves or changes the step
- routine defaults are pre-filled
- approval remains explicit

Typical posture:

```text
System: "Model Readiness is incomplete. Run Target Analysis now?"
User: approves.
```

### Assisted

The system performs routine steps but pauses at major decision gates.

Best for:

- analysts
- manager review
- repeatable investigations
- semi-standard workflows

Behavior:

- deterministic checks and routine artifact collection may run automatically
- evidence plans may be built automatically
- low-risk local GenAI summaries may be generated when allowed
- the system pauses before expensive, privacy-sensitive, or decision-changing steps
- findings are not promoted to Knowledge State without policy-compliant review

Typical posture:

```text
System: runs EDA, readiness checks, and artifact collection.
System: pauses before paid provider use or final decision summary.
```

### Autonomous

The system runs the loop end-to-end and returns an audited conclusion.

Best for:

- low-risk tasks
- mature workflows
- trusted local/private environments
- repeated project checks

Behavior:

- the system may plan, route evidence, choose context strategies, reason, and summarize without per-step approval
- all actions remain observable
- safety policies still apply
- provider/privacy constraints still apply
- destructive actions remain out of scope
- GenAI outputs are not silently promoted to validated knowledge unless future promotion policy allows it

Typical posture:

```text
System: runs a bounded investigation and returns a conclusion, evidence basis, caveats, and audit trail.
```

Autonomy must never mean opacity.

### Research / Step-by-Step

The system exposes every intermediate artifact, decision, uncertainty, and rationale.

Best for:

- methodology development
- debugging
- model validation
- book/research work
- QA and calibration

Behavior:

- deterministic facts are visible
- knowledge gaps are visible
- evidence sufficiency reasoning is visible
- evidence plans and exclusions are visible
- context strategies and downgrades are visible
- GenAI prompts/responses/telemetry are visible when generated
- uncertainty and unresolved questions are preserved

Typical posture:

```text
System: "Here is the Knowledge State, the unresolved contradiction, the candidate evidence, the MIG rationale, and the reason this artifact was excluded."
```

Research mode is not merely verbose UI. It is an audit and learning posture.

## Delegation Gates

Delegation gates are loop points where an execution mode may pause for approval, review, or policy enforcement.

Canonical gates:

| Gate | Purpose |
| --- | --- |
| After Knowledge State review | Confirm what the system believes is already known. |
| After Knowledge Gap identification | Confirm the uncertainty being investigated. |
| After Investigation Plan creation | Approve hypotheses, required evidence, stopping conditions, and decision criteria. |
| After Evidence Sufficiency assessment | Decide whether current evidence is enough or more evidence is required. |
| After Evidence Plan creation | Review included/excluded artifacts and routing rationale. |
| Before expensive GenAI call | Prevent unexpected cost or latency. |
| Before full table inclusion | Protect context budget, privacy, and data-safety constraints. |
| Before paid provider usage | Require explicit cost and privacy permission. |
| Before autonomous action | Prevent unreviewed system action outside allowed scope. |
| Before promoting GenAI output to Knowledge State | Ensure probabilistic synthesis is reviewed or validated before becoming project knowledge. |
| Before delivery/export | Confirm the final audience, render target, and caveats. |

Modes differ by which gates require explicit approval.

## Gate Matrix

| Gate | Manual | Guided | Assisted | Autonomous | Research / Step-by-Step |
| --- | --- | --- | --- | --- | --- |
| Knowledge State review | approve | approve | notify | record | inspect |
| Knowledge Gap identification | approve | approve | notify | record | inspect |
| Investigation Plan creation | approve | approve | approve for non-routine | record if bounded | inspect |
| Evidence Sufficiency assessment | approve | approve | pause on uncertainty | record | inspect |
| Evidence Plan creation | approve | approve | approve if high cost/risk | record | inspect |
| Expensive GenAI call | approve | approve | approve | policy-gated | inspect |
| Full table inclusion | approve | approve | approve or safety-gate | safety-gated | inspect |
| Paid provider usage | approve | approve | approve | explicit permission required | inspect |
| Autonomous action | not allowed | not allowed | bounded only | allowed if policy permits | inspect |
| Promote GenAI output to Knowledge State | approve | approve | approve | promotion policy required | inspect |
| Delivery/export | approve | approve | approve | policy-gated | inspect |

The matrix is conceptual. Implementation may simplify it, but future Agentic Lab work should preserve the principle.

## Trust And Audit Requirements

Every execution mode must preserve:

- Knowledge State summary used
- Investigation Plan
- knowledge gaps
- evidence sufficiency assessment
- evidence plan
- included artifacts
- excluded artifacts
- missing evidence
- routing rationale
- context strategy
- information encoding
- provider/model used
- provider capabilities
- estimated and actual costs where available
- token estimates and reported token usage where available
- latency
- findings
- caveats
- confidence
- decision readiness
- user approvals or automated gate decisions
- observability records

The more autonomous the mode, the stronger the audit obligation.

## Safety Rules

Execution Mode must respect the following safety rules:

- Paid GenAI cannot be used unless explicitly allowed.
- Autonomous mode still respects provider, privacy, local-only, and data-safety constraints.
- Full table or full data inclusion must pass table safety thresholds.
- GenAI output cannot automatically become validated knowledge without a confidence and promotion policy.
- Destructive app actions remain out of scope.
- External system actions remain out of scope until a separate action-safety architecture exists.
- All decisions remain observable.
- Missing evidence must be recorded, not hidden.
- Routing downgrades must be recorded.
- User overrides must be recorded.

Execution Mode may reduce clicks. It may not reduce accountability.

## Relationship To Evidence Strategy

Evidence Strategy remains the user-facing policy for evidence depth:

- Efficient
- Balanced
- Thorough
- Critical Decision
- Cost Is Irrelevant

Execution Mode remains the user-facing policy for delegation:

- Manual
- Guided
- Assisted
- Autonomous
- Research / Step-by-Step

Together they define a two-axis control surface:

```text
Evidence Strategy = how much evidence
Execution Mode = who controls progression
```

The default future posture should likely be:

```text
Balanced + Guided
```

This gives business users enough evidence for normal decisions while preserving visible approval.

## Relationship To Investigation Planning

Investigation Planning transforms a business question into:

- hypotheses
- unknowns
- evidence requirements
- required analyses
- required artifacts
- stopping criteria
- decision criteria

Execution Mode controls whether that plan is:

- written for the user to execute manually
- recommended for approval
- partially executed by the system
- executed autonomously under policy
- exposed step-by-step for research

Investigation Planning decides what should be done.

Execution Mode decides who advances it.

## Relationship To Context Optimization

Context Optimization determines the efficient way to satisfy an evidence need under constraints.

Execution Mode does not change the optimization math. It changes when the system must pause before applying the optimization result.

Examples:

- In Manual mode, an optimized evidence plan is presented for user selection.
- In Guided mode, the recommended plan is presented for approval.
- In Assisted mode, the plan may run automatically if low risk.
- In Autonomous mode, the plan may run if within policy bounds.
- In Research mode, the optimization tradeoffs are exposed.

## Relationship To Evidence Routing

Evidence Routing selects concrete evidence and builds an Evidence Plan.

Execution Mode determines whether the Evidence Plan is:

- a recommendation
- an approval item
- a system-executed step
- an audited trace

Routing remains deterministic and explainable where possible.

Execution Mode should never cause evidence routing to become opaque.

## Relationship To Internal Documentation

Future LLM or agent surfaces may use internal documentation to understand how Analytics Workstation works.

Internal docs are part of the system knowledge base, but they do not replace execution policy.

Even when internal docs are available, execution follows:

```text
deterministic rules first
-> Knowledge State
-> Investigation Plan
-> Context Optimization
-> Evidence Routing
-> Context Strategy
-> delegation gates
-> Observability
```

Documentation can inform reasoning. It should not bypass gates.

## UX Implications

Future UI should expose Execution Mode and Evidence Strategy as adjacent but distinct controls.

Suggested simple control:

```text
Execution Mode:
[Manual] [Guided] [Assisted] [Autonomous] [Research]

Evidence Strategy:
[Efficient] [Balanced] [Thorough] [Critical Decision] [Cost Is Irrelevant]
```

Plain-language explanations should accompany each combination.

Examples:

### Balanced + Guided

Recommended default.

The system proposes the next best analytical step and asks for approval.

### Critical Decision + Assisted

High-stakes review.

The system gathers broad evidence and pauses at decision gates.

### Cost Is Irrelevant + Autonomous

Full evidence expansion with audit trail.

Only appropriate when provider, privacy, and safety policies allow it.

### Efficient + Manual

Low-cost exploration.

The user controls every step.

## Non-Goals

This policy does not implement:

- UI controls
- Agentic Lab
- autonomous actions
- tool execution
- paid-provider escalation
- GenAI promotion policy
- action safety
- external side effects

It defines the architecture future implementations should follow.

## Validation Against Ontology v1

Execution Mode does not break the closed loop.

The closed loop already defines:

- what the system knows
- what remains uncertain
- what evidence is needed
- how evidence is routed
- how context is represented
- how reasoning happens
- how results are observed and learned from

Execution Mode only governs control and approval across that loop.

No new top-level ontology concept is required at this stage. The policy should be referenced by Investigation Strategy, Evidence Strategy UX, Context Optimization, Agentic Lab planning, and future action-safety work.

## Success Criteria

The architecture now separates:

- what the loop is
- how much evidence to gather
- who controls execution
- where trust gates exist
- how autonomy remains auditable

Future Agentic Lab work should build on this policy rather than inventing a separate autonomy model.
