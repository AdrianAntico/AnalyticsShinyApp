# Build Week Demo Gap Audit

Date: 2026-07-17

## Current Status

The app now has a dedicated Build Week Demo surface that can preflight, launch, replay, reset, and verify a claim for the bounded funnel-driver investigation.

## What Is Strong

- One coherent investigation path exists from objective to campaign ReportContract.
- OpenAI/GPT-5.6 is represented as a swappable GenAI provider, while mock remains available for deterministic QA.
- Missing OpenAI keys are classified as setup requirements, not runtime crashes.
- Approval gating for SHAP remains visible.
- Replay is deterministic and does not rerun analysis.
- Report Browser can display the campaign ReportContract.
- Claim verification resolves the finding-to-evidence path.

## Remaining Gaps Before Submission Recording

1. **Live GPT-5.6 smoke test**  
   The provider contract is implemented, but a real API-key-backed GPT-5.6 run should be checked before any judged recording.

2. **Visual pacing**  
   The current demo route exposes state clearly, but the cursor/timeline animation should be visually inspected in the browser recording path.

3. **Dataset realism**  
   The deterministic funnel fixture is enough for QA. A more compelling synthetic dataset should be selected for the final video if time allows.

4. **Report Browser polish**  
   The campaign report is valid, but investor-facing spacing and section hierarchy should be reviewed in the actual browser.

5. **Screenshot/video validation**  
   Preflight, launch, claim verification, Report Browser, replay, and reset states should be captured before marking the recording as an investor candidate.

## Judge-Style Assessment

- Technological Implementation: 8/10  
  The path uses provider abstraction, governed actions, replay, semantic reports, and traceable claims. A live GPT-5.6 smoke test remains.

- Design: 7/10  
  The surface is usable and coherent. The final recording still needs visual timing and report polish review.

- Potential Impact: 9/10  
  The demo clearly separates AI as an analytical operator from AI as a chatbot.

- Quality of Idea: 9/10  
  The evidence-centered loop is distinctive and well aligned with the app architecture.

## Top Five Improvements Before Final Recording

1. Run and record a real GPT-5.6 provider status check.
2. Use one polished synthetic funnel dataset with business-readable field names.
3. Capture and review the Report Browser campaign view at full-screen resolution.
4. Tune presentation speed so the approval gate and claim trace are understandable in the first minute.
5. Remove or hide any developer-only diagnostics that appear during the canonical recording.

## Current Recommendation

Use `Mock rehearsal` for fast iteration and QA. Switch to `OpenAI GPT-5.6` only for the final live smoke test and judged recording.
