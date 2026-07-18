# Build Week Demo Plan

The Build Week demo should show Analytics Workstation executing a bounded analytical investigation at machine speed while presenting the process at human speed.

## Demo Objective

Identify likely drivers of funnel conversion, assess whether evidence is sufficient, route evidence into a semantic report, and let the viewer inspect why a claim should be believed.

The demo must not hard-code business conclusions. It should use a real or deterministic synthetic funnel dataset that satisfies the dataset manifest.

## Demo Flow

1. Open Analytics Workstation.
2. Start Agent Operations.
3. Select Presentation pace.
4. Run the funnel driver campaign.
5. Watch dataset contract validation.
6. Watch EDA and Regression Model Insights run as deterministic service steps.
7. Pause at the SHAP approval gate.
8. Approve SHAP for the full demo, or reject it to show bounded degradation.
9. Watch evidence accumulate.
10. Open the campaign report in Report Browser.
11. Select the campaign process finding and ask: "Why should I believe this?"
12. Show claim, evidence ids, method, diagnostic status, limitations, and provenance.

## What the Demo Proves

- The agent does not drive the app with screen coordinates.
- The agent uses governed semantic actions.
- Every action is recorded.
- Every decision trace is human-readable.
- Optional high-cost steps require approval.
- Rejected approval gates produce a reduced but valid report.
- Replay does not rerun analysis.
- Report Browser can consume campaign-level ReportContracts.

## Dataset Contract

The first campaign expects funnel-style fields such as:

- event_date
- channel
- impressions
- clicks
- conversions
- spend
- optional segment fields such as region and customer_segment
- target candidates such as conversion_rate, cvr, or conversions

The current implementation includes a deterministic fixture for QA and demo plumbing. The final showcase dataset should be selected separately and should not be embedded into the framework as a business conclusion.

## Recording Guidance

Use Presentation pace for the investor-style recording.

The desired feel is:

```text
Machine-speed execution
presented at human speed
with visible governance
and traceable evidence.
```

Do not mark a recording as demo-ready unless:

- dataset contract validation is visible;
- the SHAP approval gate is visible;
- the campaign report validates;
- the "Why should I believe this?" path works;
- replay can be shown without rerunning analysis;
- no developer-only errors appear.

## Deferred

Deferred intentionally:

- autonomous free-form task execution;
- generalized browser automation;
- LLM-dependent campaign planning;
- final showcase dataset selection;
- production agent permissions beyond bounded demo actions.

