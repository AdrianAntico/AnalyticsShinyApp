# Build Week Talking Points

Use these for interviews, README follow-ups, judging questions, or demo narration. Answer only the question asked.

## What is Analytics Workstation?

Analytics Workstation is an evidence-governed AI investigation platform. It helps move from a business objective to a recommendation by preserving the investigation path: uncertainty, competing explanations, evidence, belief revision, claim verification, integrity review, and decision readiness.

## What problem does it solve?

Analytical reasoning is often scattered across dashboards, notebooks, reports, model outputs, chat transcripts, and memory. When a recommendation matters, people need to know why it was reached, what evidence supports it, what weakens it, and what uncertainty remains.

## Why not just build a dashboard?

A dashboard shows outputs. Analytics Workstation preserves the investigation behind the output. It keeps competing explanations, evidence, belief changes, claims, limitations, and readiness visible.

## Why not just use ChatGPT?

ChatGPT can explain text it receives. Analytics Workstation builds and preserves structured evidence before asking AI to synthesize. The AI operates inside bounded contracts instead of receiving arbitrary authority over the project.

## Why GPT-5.6?

GPT-5.6 is used for synthesis tasks: framing the investigation, explaining belief changes, evolving recommendations, verifying claims, and summarizing integrity review. Deterministic analytics still compute the evidence.

## Why Codex?

Codex accelerated implementation, QA, documentation, and UI iteration. The project used that speed to explore architectural and product questions that would have been too expensive to test manually at the same pace.

## Did AI build the whole project?

No. Codex was an engineering collaborator. The product direction, constraints, review, taste, and acceptance decisions came from human judgment. The repository shows many corrections, reversals, and hard boundaries.

## What is a governed investigation?

A governed investigation records the objective, uncertainty, competing explanations, selected evidence path, analytical outputs, belief revisions, recommendation changes, claim verification, and decision readiness. It is not just a final answer.

## Why evidence?

Because a recommendation is only useful if people can inspect what supports it, what weakens it, and what assumptions it depends on. Evidence turns a fluent answer into something reviewable.

## Why belief revision?

Real analysis often changes what we believe. Analytics Workstation records that change instead of hiding it. A recommendation that changes because evidence changed is treated as a strength, not a failure.

## Why claim verification?

Claim verification answers "Why should I believe this?" It traces the final recommendation back through the initial belief, evidence discovered, belief updates, diagnostics, methodology, limitations, and remaining uncertainty.

## Why integrity review?

Integrity review is the final skeptical check. The system searches for reasons its own recommendation could be wrong, including contradictory evidence, evidence gaps, assumptions, sensitivity, generalizability limits, and decision robustness.

## What does the Build Week demo prove?

It proves a bounded vertical slice: a deterministic dataset can move through preflight, governed investigation, evidence collection, belief revision, recommendation evolution, claim verification, integrity review, ReportContract generation, Report Browser display, and replay.

## What does it not prove?

It does not prove general autonomous analysis, universal model quality, commercial readiness for every domain, or that every AI-generated recommendation is trustworthy. The Build Week path is intentionally bounded.

## What changed during development?

The product moved from output generation toward investigation preservation. AI-assisted implementation reduced the cost of building, which made architecture, judgment, governance, product taste, and evidence discipline more important.

## What was the biggest lesson?

When implementation gets cheaper, the hard part does not disappear. It moves. The difficult questions become what should exist, what should be deterministic, where AI should be bounded, and when a claim deserves trust.

## How would you improve it next?

First, validate the live GPT-5.6 path and final recording. Then test the investigation model on real customer-style data, simplify the first-run product path, and decide the smallest commercial workflow that preserves the evidence-governed core.

## Is this a product or an experiment?

Both. The software is a product artifact. The repository is also a documented experiment in AI-assisted software development and evidence-governed analytical design.

## What should judges remember?

Analytics Workstation does not ask users to trust an AI answer. It preserves the investigation, verifies the claim, and challenges the recommendation before asking for trust.
