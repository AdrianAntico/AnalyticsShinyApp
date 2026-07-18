# Build Week Demo Guide

Analytics Workstation now has a focused Build Week demonstration surface under:

```text
More -> Build Week Demo
```

The goal is not to show every capability. The goal is to show one memorable governed investigation from objective to evidence-backed claim.

The canonical demo uses a deterministic 80-row synthetic mystery dataset:

- `data/build_week_demo.csv`
- `data/build_week_demo_ground_truth.csv`

The ground truth file is for development and QA only. The demo path does not load it.

## Setup

Run the app:

```r
shiny::runApp(".")
```

For a live OpenAI path:

```powershell
$env:OPENAI_API_KEY="sk-..."
$env:ANALYTICS_GENAI_PROVIDER="openai"
$env:ANALYTICS_GENAI_MODEL="gpt-5.6"
```

For local rehearsal, choose `Mock rehearsal` in the page. This uses the same app contracts without provider calls.

Regenerate and validate the dataset:

```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" scripts\generate_build_week_demo_data.R
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" scripts\validate_build_week_demo_data.R
```

## Walkthrough

1. Open `More -> Build Week Demo`.
2. Review or edit the user objective.
3. Select `OpenAI GPT-5.6` or `Mock rehearsal`.
4. Click `Run Preflight`.
5. Confirm provider, dataset contract, analytics services, report browser, agent runtime, cursor targets, and replay checks are visible.
6. Click `Launch Demo`.
7. Confirm the campaign reaches `completed`.
8. Click `Why should I believe this?`.
9. Open `Report Browser` and select `Agent Campaign`.
10. Review initial belief, evidence discovered, belief revisions, final conclusion, evidence ids, diagnostics, methodology, limitations, and recommendations.
11. Click `Replay` to inspect the recorded state without rerunning analysis.
12. Click `Reset` before a fresh recording.

## What the Demo Proves

- GPT-5.6 is represented through the provider-agnostic GenAI contract.
- Missing provider setup is visible and nonfatal.
- The demo dataset is deterministic and contains recoverable hidden mechanisms: Search saturation, Social-by-audience interaction, operational delay threshold, creative fatigue, competitor pressure, and regional baseline differences.
- The analytical operator follows a bounded action path.
- Higher-cost SHAP analysis remains behind an approval gate.
- The campaign records a governed inquiry path: observation, uncertainty, competing explanations, candidate investigations, selected investigation, evidence collected, belief update, decision impact, remaining uncertainty, and stopping rule.
- Recommendations evolve as evidence is collected rather than appearing as a single unexplained answer.
- The campaign produces a validated semantic `ReportContract`.
- The Report Browser consumes the same contract rather than a special demo rendering.
- The final claim is traceable to initial belief, evidence, belief revisions, diagnostics, methodology, and limitations.

For a timed narration, use `docs/build_week_demo_walkthrough.md`.

## Expected User Journey

The demo should feel like an investigation, not a feature tour.

The viewer should experience this sequence:

```text
Objective
-> Observation
-> Uncertainty
-> Competing Explanations
-> Selected Investigation
-> Evidence
-> Belief Revision
-> Recommendation Evolution
-> Claim Verification
-> Integrity Review
-> Decision Readiness
-> Why Should I Believe This?
```

The presenter should avoid explaining the internal architecture first. Let the screen establish the path, then narrate what changed.

## Recommended Presenter Pacing

Use a calm pace. The product is stronger when it appears governed and deliberate.

Suggested timing:

- 0:00-0:20: State the business objective and point to the investigation path.
- 0:20-0:40: Run preflight and say that readiness is checked before the system acts.
- 0:40-1:20: Launch the demo and let the inquiry record fill in.
- 1:20-1:45: Pause on competing explanations and selected investigation.
- 1:45-2:15: Emphasize evidence collection and belief revision.
- 2:15-2:40: Show recommendation evolution.
- 2:40-3:20: Click `Why should I believe this?` and walk the claim dossier, including the integrity review.
- 3:20-3:50: Open the Report Browser and show that the investigation persists as a readable record.

## Ideal Screen Sequence

For a three-minute recording:

1. Home or shell, then open Build Week Demo.
2. Build Week objective and investigation path.
3. Preflight checks.
4. Completed inquiry record.
5. Replay or Step Replay only if it clarifies the timeline.
6. Claim verification dossier.
7. Investigation Integrity Review and Decision Readiness.
8. Report Browser with `Agent Campaign` selected.
9. Final verbal close: the workstation turns uncertainty into evidence-backed recommendation, then challenges its own conclusion before asking for trust.

## Judge Talking Points

Use investigation language:

- "The system begins with uncertainty, not a dashboard."
- "It compares explanations before choosing the next investigation."
- "Evidence changes the working belief."
- "Recommendations evolve as evidence arrives."
- "The final claim is traceable to diagnostics, methodology, and limitations."
- "The workstation actively searches for reasons its own recommendation could be wrong."
- "Rejected or unresolved explanations stay visible instead of disappearing."
- "Decision readiness is evidence confidence, not model confidence."
- "The AI is bounded by governed actions; it is not free-form automation."
- "The report is not generated prose alone. It is a readable surface over structured evidence."

Avoid leading with implementation language such as provider abstraction, ReportContract, runtime bundle, cursor target, or service contract unless a technical judge asks.

## Readiness Checklist

Before recording:

- Preflight shows no unexplained errors.
- The selected provider is intentional: OpenAI for live run, Mock rehearsal for deterministic recording.
- The investigation path is visible before launch.
- Empty states are polished and do not look broken.
- Replay does not appear static or confusing.
- Claim verification shows initial belief, evidence, belief updates, final recommendation, diagnostics, methodology, limitations, and remaining uncertainty.
- Investigation Integrity Review shows evidence strength, alternative explanations, contradictory evidence, gaps, assumptions, sensitivity, robustness, and decision readiness.
- Report Browser shows the campaign report as one connected investigation.
- No hidden architecture explanation is required for the viewer to understand the narrative.

## Investigation Integrity Review

The integrity review is the final skeptical check before the recommendation is treated as decision-relevant.

It should answer one question:

```text
How confident should I be that this recommendation deserves action?
```

The review does not run a second investigation and does not invent new evidence. It reuses the completed campaign record and asks whether the recommendation survived:

- competing explanations;
- contradictory evidence;
- evidence gaps;
- explicit assumptions;
- sensitivity to reasonable modeling choices;
- limits of generalizability;
- decision robustness.

The presenter should frame this as the workstation applying its own standards to itself:

> The system does not ask us to trust the answer because it generated it. It shows why the answer is credible, what could still be wrong, and whether the evidence is ready for action.

## Troubleshooting

### OpenAI says API key missing

Set `OPENAI_API_KEY` or paste a key in the Build Week Demo page for the current session.

### Provider unavailable

Use `Mock rehearsal` to validate the product path without network access.

### No Agent Campaign report appears

Run `Launch Demo` first. The campaign report is session state generated by the demo.

### Replay seems static

Replay intentionally inspects the recorded campaign state. It should not rerun EDA, regression, or SHAP.

## Current Limits

This is a demonstration completion path, not a general autonomous analyst. It deliberately avoids arbitrary action execution, broad task planning, and new report renderers.
