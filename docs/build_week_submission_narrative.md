# Build Week Submission Narrative

Analytics Workstation is an evidence-governed AI investigation platform.

The project began from a practical need: build a local analytical workstation that could load data, run analysis modules, generate artifacts, inspect evidence, and produce reports. During development, the center of the product moved. Charts, reports, dashboards, and AI summaries were useful, but none of them fully preserved the reasoning path behind an analytical recommendation.

The product therefore evolved around a different object: the investigation.

In the Build Week demonstration, Analytics Workstation investigates a deterministic synthetic enrollment-growth dataset. It starts with uncertainty, keeps competing explanations visible, collects deterministic evidence, revises its belief as evidence accumulates, evolves its recommendation, verifies the final claim, and performs an integrity review before declaring decision readiness.

GPT-5.6 is used where probabilistic synthesis is useful: framing the investigation, explaining belief changes, evolving recommendation language, verifying claims, and summarizing the integrity review. It is not used to invent evidence or replace deterministic analytics. Data generation, EDA, regression, SHAP evidence, validation, replay, report-contract construction, and QA remain deterministic services.

The development process became part of the project. AI-assisted implementation made many coding steps cheaper. Instead of spending that savings only on more features, the project repeatedly spent it on harder questions about evidence, governance, representation, trust, product experience, dependency reliability, and release packaging.

That observation should remain bounded. Analytics Workstation does not prove that AI makes software engineering automatic. The repository suggests something more specific: when implementation becomes cheaper, judgment becomes more visible. The hard questions become what should exist, what should remain deterministic, where AI should be bounded, which claims are supported, and when a recommendation deserves trust.

The Build Week release is not a finished general autonomous analyst. It is a focused product demonstration of a different pattern for AI analytics:

```text
investigate first
preserve the evidence
verify the claim
challenge the recommendation
then decide whether it deserves trust
```

Analytics Workstation is software that investigates before it recommends.
