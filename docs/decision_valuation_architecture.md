# Decision Valuation Workspace

Decision Valuation is the Semantic Intelligence layer that translates authored alternatives and analytical evidence into transparent economic tradeoffs.

It sits after the authored decision lifecycle:

```text
Business intent
-> Authored decision context
-> Alternatives
-> Evidence and unit economics
-> Decision valuation
-> Canonical valuation artifact
-> Collector / Mission Control / GenAI context
```

## Responsibilities

The workspace lets an analyst:

- create a valuation context linked to an authored decision,
- map causal, predictive, forecast, assumed, imported, missing, or unsupported evidence to operational impact,
- define action thresholds,
- capture effort and capacity separately from financial cost,
- capture downside and guardrail risk,
- run deterministic alternative economics,
- review governed recommendations,
- register the valuation artifact with the project artifact collector.

## Non-Responsibilities

Phase 1 does not implement:

- enterprise portfolio optimization,
- capital allocation,
- autonomous action selection,
- approval execution,
- observational causal estimation,
- MMM,
- accounting/tax/GL logic,
- stochastic dynamic programming,
- unrestricted Monte Carlo.

## Degradation

If the installed AutoQuant package does not expose the Decision Valuation APIs, the app still starts. The valuation workbench reports the unavailable contract, and Mission Control/GenAI context omit valuation details or mark them unavailable.

## Persistence

The project state stores `decision_valuation_state` alongside semantic workspace, authored decision lifecycle, causal planning, completed-experiment evidence, and randomized ITT state.

## Collector Integration

Registered valuation output is converted into a standard app artifact and submitted through the existing Project Artifact Collector path. The collector remains the project-level owner of final evidence documents.

## GenAI Context

GenAI receives bounded valuation metadata only:

- context count,
- active valuation id,
- cash-flow count,
- impact-mapping count,
- scenario count,
- threshold count,
- valuation status,
- number of alternatives valued,
- missing-input count,
- primary recommendation category,
- artifact count,
- campaign seed summary.

Full economics and source evidence are omitted by default.
