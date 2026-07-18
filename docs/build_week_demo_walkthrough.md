# Build Week Demo Walkthrough

Purpose: show that Analytics Workstation changes its recommendation when the evidence changes.

Target length: three minutes.

## 0:00 - Launch

Open `More -> Build Week Demo`.

Say:

Analytics Workstation is going to investigate a small but realistic enrollment-growth mystery. The dataset is synthetic and deterministic: 80 weekly rows across regions and audiences. The ground truth is hidden from the demo path.

## 0:20 - Preflight

Click `Run Preflight`.

Say:

Before the system reasons, it checks whether the dataset, provider, runtime, report browser, cursor targets, and replay path are available. The app should not improvise around broken prerequisites.

## 0:40 - Observation

Launch the demo.

Say:

The initial observation is deliberately incomplete: enrollments look weaker than expected, and Search looks suspicious at first glance. A normal report might jump to budget cuts. This workflow records uncertainty first.

## 1:00 - Competing Explanations

Point to the inquiry record.

Say:

The system tracks multiple explanations at once: Search saturation, creative fatigue, operational delay, competitor pressure, and audience mix. These are not hidden thoughts. They are structured investigation state.

## 1:25 - Evidence Collection

Step through EDA and Regression evidence.

Say:

EDA establishes whether the data is usable. Regression provides an initial driver story. Notice the recommendation moves from "do not decide yet" to "do not cut Search yet; test the mechanism."

## 1:50 - SHAP Approval

Point to the approval gate.

Say:

The higher-value explanation step is governed. SHAP is not silently run. It is approved, recorded, and then included in the evidence trail.

## 2:10 - Belief Revision

Use `Step Replay` or the belief revision section.

Say:

This is the core moment: the system changes its mind. The story is no longer "Search is bad." Evidence points to an operational bottleneck after roughly 36 hours, creative fatigue after about six weeks, Social working better for Career Changers, Search saturation at the margin, and competitor pressure in selected regions.

## 2:35 - Recommendation Evolution

Point to the final recommendation.

Say:

The final recommendation is not a generic report summary. It is an evolved decision path: improve operational throughput first, refresh aging creative, target Social by audience, tune saturated Search spend instead of broadly cutting it, and treat competitor pressure separately from channel quality.

## 2:50 - Claim Verification

Click claim verification or open the Report Browser.

Say:

The app can answer, "Why should I believe this?" It shows the initial belief, evidence discovered, belief revisions, final conclusion, evidence path, diagnostics, methodology, limitations, and remaining uncertainty.

## Closing

Say:

The point is not that the AI generated a report. The point is that the system preserved an investigation: observation, competing explanations, evidence, belief revision, recommendation evolution, and an evidence-backed conclusion.

One sentence for judges:

The AI changed its mind because the evidence changed.
