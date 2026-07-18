# Long-Form YouTube Outline

Target runtime: 15 to 20 minutes.

Purpose: explain the project as both software and development experiment without turning the video into a feature tour.

## 1. Opening: The Question

Approximate time: 0:00-1:00

- Open with the question: what changes when implementation is no longer the dominant constraint?
- Show the Analytics Workstation Home screen.
- State the bounded answer from this repository: implementation got cheaper, but judgment became more important.
- Avoid broad claims about the future of all software.

## 2. Why Outputs Were Not Enough

Approximate time: 1:00-2:30

- Contrast dashboards, notebooks, reports, and AI summaries.
- Explain the missing object: the investigation.
- Introduce the trust questions: what evidence supports this, what weakens it, what changed, what remains uncertain?
- Show Figure 2 or the Build Week investigation opening.

## 3. Origins: From Analytics App To Evidence Workstation

Approximate time: 2:30-4:00

- Explain the original substrate: data, plots, AutoPlots, AutoQuant, reports.
- Explain the first major shift: artifacts became evidence.
- Show Artifact Studio or evidence exhibit if available.
- Mention package boundaries briefly: the app orchestrates; AutoQuant and AutoPlots own analytical and plotting internals.

## 4. The Development Experiment

Approximate time: 4:00-6:00

- Introduce the development observation: AI-assisted implementation reduced the cost of trying ideas.
- Explain the consequence: the bottleneck moved toward architecture, judgment, taste, and restraint.
- Give concrete examples: contracts, QA, governance, dependency repair, release packaging.
- Do not claim that AI made engineering automatic.

## 5. The Product Philosophy

Approximate time: 6:00-7:30

- Evidence before conclusions.
- Deterministic knowledge first.
- AI inside contracts.
- Claims must be traceable.
- Challenge conclusions before trust.
- Show `docs/design_principles.md` or the README section if useful.

## 6. Build Week Demo: The Investigation

Approximate time: 7:30-12:30

- Open Build Week Demo.
- Run preflight.
- Launch the investigation.
- Pause on competing explanations.
- Show deterministic evidence collection.
- Show belief revision.
- Show recommendation evolution.
- Click `Why should I believe this?`.
- Show claim verification.
- Show integrity review.
- Close with decision readiness.

## 7. Reporting And Replay

Approximate time: 12:30-14:00

- Open Report Browser.
- Explain ReportContract in one sentence: a semantic report object, not a screenshot or generated prose blob.
- Show that replay inspects recorded state rather than rerunning analytics.
- Emphasize preserved reasoning.

## 8. What GPT-5.6 Does And Does Not Do

Approximate time: 14:00-15:30

- GPT-5.6 supports framing, synthesis, belief narrative, recommendation language, claim verification, and integrity review.
- Deterministic services compute data, EDA, regression, SHAP, validation, replay, report contracts, and QA.
- Explain why this division matters.

## 9. Productization And Release Candidate

Approximate time: 15:30-17:00

- Show installer/release docs briefly.
- Mention version `1.0.0-buildweek`.
- Explain dependency checks, first-party packages, Windows installer, repair/uninstall, and release notes.
- Keep it short. This supports seriousness; it is not the main story.

## 10. Limits And Open Questions

Approximate time: 17:00-18:30

- This is a bounded Build Week demonstration.
- It is not a finished general autonomous analyst.
- Live provider testing, commercial narrowing, real-customer data, and broader evaluation remain future work.
- Open questions are part of the evidence, not an embarrassment.

## 11. Closing

Approximate time: 18:30-20:00

- Return to the central observation.
- The project did not use AI-assisted speed only to build more screens.
- It used that speed to ask what trustworthy analytical software should preserve.
- Close with the product sentence: software that investigates before it recommends.

## Optional B-Roll

- `docs/media/hero.png`
- `docs/media/investigation.png`
- `docs/media/belief_revision.gif`
- `docs/media/claim_verification.png`
- `docs/media/integrity_review.png`
- `docs/media/architecture.png`
- Build Week preflight screen
- Report Browser
- Release notes / installer terminal
