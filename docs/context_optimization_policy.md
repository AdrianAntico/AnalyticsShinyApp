# Context Optimization Policy

Analytics Workstation treats context as an architectural resource.

Tokens, latency, attention, reasoning, and privacy all have cost. The objective is not to minimize tokens. The objective is to maximize analytical information transfer while minimizing unnecessary cost.

## Core Principle

Never spend probabilistic intelligence on deterministic knowledge.

Deterministic reasoning should always execute first. Only uncertainty should consume probabilistic reasoning.

## Governing Hierarchy

Every future GenAI feature should respect this order:

```text
Deterministic reasoning
-> Evidence Routing
-> Optional Local GenAI
-> Optional Paid GenAI
-> Final Reasoning
-> Observability
-> Future Learning
```

The system should become more efficient over time, not more magical.

## Layer 1: Deterministic Knowledge

The workstation should compute known facts before any LLM is involved.

Examples:

- constant variables
- near-zero variance
- missingness
- sparse groups
- correlation
- artifact quality
- screenshot availability
- render target
- producer metadata
- collector metadata
- routing profile
- provider capabilities
- context size estimation
- token estimation
- image capability
- safety limits

These checks should never require GenAI.

## Layer 2: Evidence Routing

Evidence Routing uses deterministic information to estimate:

- task relevance
- trustworthiness
- novelty
- expected insight gain
- expected context cost

It then assigns routing levels and builds Evidence Plans.

This remains deterministic and explainable. The evidence plan should answer:

- why was this artifact included?
- why was this artifact excluded?
- why was this artifact downgraded?
- why was this context strategy chosen?
- what evidence is missing?

## Layer 3: Probabilistic Routing

Probabilistic routing is optional.

It may be used only when deterministic routing cannot confidently choose between evidence candidates.

Appropriate uses:

- redundant artifact detection
- semantic overlap
- evidence prioritization
- artifact usefulness estimation
- routing uncertainty

The goal is to reduce the evidence search space, not answer the user's analytical question.

Local/private providers should be preferred when available. Paid providers are never required for deterministic routing.

## Layer 4: Probabilistic Reasoning

Only after evidence has been selected should a model reason over the optimized evidence bundle.

This is the expensive step. Everything before this step should reduce its workload.

## Layer 5: Learning and Observability

The workstation should observe outcomes without automatically mutating production behavior.

Record:

- Evidence Plans
- routing decisions
- included artifacts
- excluded artifacts
- context strategies
- provider and model
- estimated and reported token usage
- latency
- manual scores
- user feedback
- follow-up behavior
- hallucination flags
- answer acceptance

Future policy changes may be informed by these observations, but production behavior should remain inspectable and explicitly changed.

## Optimization Objective

Maximize expected analytical information transfer subject to:

- token budget
- latency budget
- privacy constraints
- provider capabilities
- accuracy preference
- routing profile

The target is information transferred, not tokens minimized.

## Optimization Profiles

Supported profile concepts include:

- conservative
- balanced
- accuracy first
- token saver
- vision first
- local private
- critical decision

Profiles may influence:

- maximum tokens
- maximum images
- maximum tables
- maximum latency
- preferred providers
- routing aggressiveness
- deep-dive thresholds
- redundancy tolerance

These preferences influence routing. They should not change the architecture.

## Evidence Strategy UX

Evidence Strategy is the user-facing configuration layer over Context Optimization.

Business-friendly strategies such as Efficient, Balanced, Thorough, Critical Decision, and Cost Is Irrelevant map to technical routing settings including token budget, artifact limits, image/table limits, redundancy tolerance, provider constraints, and deep-dive thresholds.

Balanced is the default. Advanced users can override technical settings, but overrides remain attached to the strategy and are recorded for observability.

## Execution Mode / Delegation Policy

Execution Mode is orthogonal to Context Optimization.

Context Optimization determines how to satisfy a knowledge need efficiently under constraints. Execution Mode determines who is allowed to advance the loop after those recommendations are produced.

Examples:

- Manual mode presents optimized options for user selection.
- Guided mode recommends the optimized next step and asks approval.
- Assisted mode may execute routine optimized steps but pauses at major gates.
- Autonomous mode may proceed only inside explicit cost, privacy, provider, and safety policy.
- Research / Step-by-Step mode exposes the optimization rationale and tradeoffs.

Execution Mode must not bypass context safety rules. Paid provider usage, full table inclusion, expensive calls, and promotion of GenAI output into Knowledge State remain gated by policy.

## Context Strategy Evaluation

Every artifact should be evaluated for:

- expected utility
- expected cost
- expected novelty
- expected trust
- expected insight gain
- expected redundancy

Strategy selection must remain explainable.

## Relationship To Existing Architecture

Context Optimization governs:

- Artifact Model
- Information Encoding Policy
- Project Artifact Collector
- Render Targets
- Artifact Quality Policy
- Table Artifact Architecture
- Producer Semantics
- Evidence Routing Policy
- GenAI Context Strategy Research
- GenAI Service Contract

It does not replace these layers. It orders them.

## Information Encoding

Information Encoding sits upstream of Evidence Routing.

The same analytical artifact can be encoded for different consumers before routing decides what to include. LLM encoding may favor analytical density, compact annotations, reference lines, and composite views, while human encoding may favor spacing, interactivity, and progressive disclosure.

Better encoding should reduce downstream context cost by transferring more analytical information per artifact.

## Non-Goals

This policy does not implement:

- Agentic Lab
- autonomous actions
- autonomous learning
- automatic policy mutation
- automatic paid-provider escalation
- full dataset transmission by default

## QA Contract

`qa_context_optimization_policy()` verifies:

- deterministic rules execute first
- Evidence Routing remains deterministic
- probabilistic routing is optional
- paid GenAI is never required for deterministic reasoning
- routing profiles influence optimization
- observability fields exist
- policy ordering is respected
- evidence plans remain explainable

## Future Direction

Begin conservative.

Prefer explicit deterministic rules.

Use probabilistic routing only when uncertainty remains.

Repeated successful probabilistic decisions may later become deterministic rules. Repeated failures may reduce confidence. Any future learning loop should make Analytics Workstation more efficient and more transparent, not less inspectable.
