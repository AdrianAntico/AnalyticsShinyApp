# Execution Modes And Delegation

The analytical intelligence loop describes the structure of intelligent analytical work. It says that a business question should be interpreted through Knowledge State, transformed into an Investigation Plan, evaluated for evidence sufficiency, routed through evidence and context policies, reasoned over, preserved in the collector, observed, and eventually learned from.

That loop answers one class of question:

What needs to happen for an analytical system to reason over evidence?

It does not answer another equally important question:

Who is allowed to advance the loop?

That second question becomes unavoidable as soon as the system begins to move from passive evidence browsing toward AI-assisted work. The same architecture can be used by a person who wants to click every step, by a business user who wants recommendations with approval, by an analyst who wants routine work automated, or by a future agent that runs a bounded investigation and returns a fully audited conclusion. Those experiences should not require separate architectures. They should be different execution modes over the same loop.

This is the purpose of Execution Mode / Delegation Policy.

## The Difference Between Evidence And Delegation

The first distinction is simple but important.

Evidence Strategy answers how much evidence should be gathered.

Execution Mode answers who controls the progression of work.

Those two dimensions are orthogonal. A careful analyst might want Critical Decision evidence but Manual execution. A local, low-risk routine check might use Efficient evidence and Autonomous execution. A business stakeholder might want Balanced evidence and Guided execution. A researcher developing the method might want Thorough evidence and Research / Step-by-Step execution.

If these dimensions are mixed together, the product becomes conceptually muddy. "Autonomous" starts to imply "send everything." "Manual" starts to imply "simple." "Critical Decision" starts to imply "let the system run." None of those implications are logically necessary.

The clean separation is:

```text
Evidence Strategy = how much evidence
Execution Mode = who advances the loop
```

This keeps the architecture legible.

## Why Execution Mode Is Not A New Ontology Layer

Execution Mode is not a new kind of evidence. It is not a new routing system. It is not a replacement for Context Optimization. It is not an Agentic Lab.

It is a policy over the loop.

The loop remains:

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

Execution Mode asks, at each transition:

- should the system merely explain the next option?
- should the system recommend the next option and wait?
- should the system perform this routine step?
- should the system pause because cost, privacy, uncertainty, or decision criticality is high?
- should the system continue autonomously because the task is bounded and permitted?
- should every intermediate decision be exposed because the user is in research mode?

That is an execution-control problem. It is not a new analytical object.

## Manual Mode

Manual mode is the most conservative posture.

In Manual mode, the system explains options. The user chooses each next step. The system may identify knowledge gaps, recommend evidence, explain what an artifact means, or show why a decision is not ready, but it does not advance the investigation without the user.

Manual mode is appropriate when the user is learning, when trust is still being established, when the setting is regulated, or when the methodology itself is under review. It is also useful for technical users who want to inspect every step of a new workflow before turning over any responsibility to software.

Manual mode is not primitive. It can still use all of the architecture:

- Knowledge State can summarize what is known.
- Investigation Planning can propose hypotheses and evidence requirements.
- Context Optimization can estimate the cheapest useful evidence plan.
- Evidence Routing can show included and excluded artifacts.
- GenAI can summarize a selected artifact if the user requests it.
- Observability can record choices and outcomes.

The difference is that the user advances the loop.

## Guided Mode

Guided mode is likely the default for business-facing analytical workflows.

In Guided mode, the system recommends the next step and asks for approval. It does not force the user to understand every low-level mechanism, but it also does not disappear into automation.

A typical Guided interaction might look like:

The system reviews the project and sees that the target distribution has been generated, model readiness is incomplete, and the collector contains EDA artifacts but no readiness diagnostics. It recommends running Model Readiness next. It explains that the purpose is to detect leakage, class balance issues, missingness, and target suitability before modeling. The user approves.

Guided mode is valuable because many users do not want a blank canvas. They want to know what to do next. But they also want control. Guided mode turns the architecture into a coach rather than an agent.

This mode fits the product identity well. Analytics Workstation is not merely a dashboard. It is an analytical operating environment. Guided mode lets the environment express judgment while preserving human agency.

## Assisted Mode

Assisted mode is for users who trust the system to handle routine steps but still want gates around important decisions.

In Assisted mode, the system may run deterministic checks, generate obvious artifacts, update the collector, and prepare evidence plans without asking for approval at every step. It pauses when the work crosses a meaningful boundary:

- before an expensive GenAI call
- before paid provider use
- before including a full table
- before final delivery
- before promoting a GenAI-generated synthesis into Knowledge State
- before a conclusion is treated as decision-ready

Assisted mode is probably the natural mode for experienced analysts. It reduces repetitive work while preserving judgment.

The danger of Assisted mode is hidden automation. If the system performs routine work, the user should still be able to see what happened. Every artifact generated, every evidence item included, every routing downgrade, every provider used, and every major decision should remain inspectable.

Assistance should reduce labor, not observability.

## Autonomous Mode

Autonomous mode is the most sensitive execution posture.

In Autonomous mode, the system may run a bounded investigation end-to-end and return an audited conclusion. This is not the same as giving an AI permission to do anything. It is bounded by:

- the business question
- the current Knowledge State
- the Investigation Plan
- evidence strategy
- provider constraints
- privacy constraints
- cost constraints
- data safety thresholds
- delegation gates
- observability requirements

Autonomous mode is appropriate only for low-risk tasks, mature workflows, trusted local/private environments, or repeated checks where the expected behavior is well understood.

Autonomy must never mean opacity. The more responsibility the system takes, the stronger the audit trail must become.

An autonomous investigation should return not just an answer, but the path:

- the Knowledge State used
- the hypotheses considered
- the evidence gathered
- the evidence excluded
- the context strategies selected
- the provider and model used
- the limitations and caveats
- the decision readiness level
- the missing evidence
- the telemetry

Without that path, autonomy becomes theatrical. With that path, autonomy becomes a compressed form of inspectable analytical labor.

## Research / Step-by-Step Mode

Research / Step-by-Step mode is the most transparent posture.

It is designed for methodology development, debugging, model validation, QA, book work, and architecture research. It exposes intermediate decisions that other modes may summarize.

In Research mode, the user should be able to see:

- what the system believes is known
- what remains unknown
- which hypotheses are being considered
- why evidence is sufficient or insufficient
- which artifacts are candidates
- why artifacts are included or excluded
- how marginal information gain is estimated
- what context strategy was selected
- where downgrades occurred
- what GenAI saw
- what GenAI did not see
- why a conclusion is preliminary

Research mode is not simply "show more logs." It is an epistemic mode. It makes the reasoning process available for inspection.

This is especially important because the project is not only building software. It is also developing a theory of AI-native analytical systems. Research mode gives future experiments a place to live.

## Delegation Gates

Delegation gates are the points where execution may pause. They are the control surface that makes delegation safe.

Important gates include:

- after Knowledge State review
- after Knowledge Gap identification
- after Investigation Plan creation
- after Evidence Sufficiency assessment
- after Evidence Plan creation
- before expensive GenAI calls
- before full table inclusion
- before paid provider usage
- before autonomous action
- before promoting GenAI output to Knowledge State
- before delivery or export

Different execution modes use these gates differently.

Manual mode pauses at nearly everything. Guided mode recommends and asks. Assisted mode passes through routine gates but pauses at decision gates. Autonomous mode proceeds when policy permits but records every gate decision. Research mode exposes the gate logic whether or not it pauses.

This gate structure is the difference between principled delegation and a vague "agent mode."

## Promotion To Knowledge State

One gate deserves special emphasis: promotion of GenAI output to Knowledge State.

A GenAI response is not automatically knowledge. It may be a useful synthesis, a draft explanation, a hypothesis, or a recommendation. But Knowledge State is supposed to represent what the project knows, believes, assumes, and still questions. Updating it silently would collapse the difference between reasoning and truth.

The system therefore needs a future promotion policy. That policy may involve human review, deterministic validation, confidence thresholds, contradiction checks, or repeated evidence support. Execution Mode should respect that future policy.

Until then, the architecture should be conservative:

GenAI can produce candidate findings.

Candidate findings can be recorded.

But validated knowledge should require explicit promotion.

## Internal Documentation As System Knowledge

Future LLM or agent features may use internal documentation to understand Analytics Workstation itself. That is useful. The docs explain the artifact model, collector, evidence routing, context optimization, information encoding, knowledge state, and investigation planning.

But internal documentation is not a bypass around execution policy.

Even when an LLM understands the system, the loop still follows:

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

The model may understand the map. It does not therefore get to ignore the road.

## Why This Matters For Agentic Lab

Agentic Lab should not invent a new autonomy model.

It should inherit Execution Mode / Delegation Policy.

This matters because Agentic Lab will be tempting to design as a chat interface with tools. But that would be a regression. The workstation already has a richer architecture:

- artifacts as evidence
- collector as project memory
- Knowledge State as understanding
- Investigation Plans as analytical intent
- Context Optimization as efficient representation
- Evidence Routing as grounding
- Observability as audit

An agent should not float above this. It should operate inside it.

Execution Mode gives Agentic Lab its permission model.

## The Two-Axis Product Control

The eventual product control can be simple:

```text
Execution Mode:
[Manual] [Guided] [Assisted] [Autonomous] [Research]

Evidence Strategy:
[Efficient] [Balanced] [Thorough] [Critical Decision] [Cost Is Irrelevant]
```

The simplicity is important. Business users should not need to reason about every routing threshold. They need to know whether they want speed, balance, thoroughness, critical-decision depth, or unrestricted evidence. They also need to know whether they want to click every step, approve recommendations, delegate routine work, run autonomously, or inspect the whole process.

Those two choices can map to detailed technical behavior while remaining understandable.

This is the same design philosophy that has guided the broader system: expose simple controls first, preserve technical override, and keep the architecture honest underneath.

## Open Questions

Several questions remain unresolved.

First, the exact gate matrix needs product testing. The conceptual gates are clear, but users may expect different pauses in practice. Business users may want more explanation but fewer technical prompts. Analysts may want fewer confirmations but better post-hoc traces. Regulated contexts may require explicit approval at gates that ordinary business contexts can record silently.

Second, autonomous execution needs a bounded-task model. It is not enough to offer an Autonomous button. The system needs to know the scope of the investigation, the allowed modules, the provider constraints, the maximum cost, the allowed data representations, and the stopping conditions.

Third, promotion to Knowledge State remains future work. The architecture can already distinguish candidate findings from validated knowledge, but the operational policy for promotion is not implemented.

Fourth, execution telemetry needs to become durable enough to support learning. If users repeatedly approve certain gates or reject certain recommendations, that should eventually inform default behavior. But learning must remain inspectable and explicit.

## The Architectural Claim

The claim is not that every analysis should become autonomous.

The claim is that analytical systems need a formal way to vary delegation without changing the underlying reasoning architecture.

Manual, Guided, Assisted, Autonomous, and Research modes should all run the same loop. They should differ in who advances it, which gates pause, and how much intermediate reasoning is exposed.

That is how autonomy remains compatible with trust.

That is how AI assistance remains compatible with professional analytical work.

And that is how Analytics Workstation can evolve toward agentic capabilities without becoming a black box.
