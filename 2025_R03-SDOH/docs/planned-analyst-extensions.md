# Planned analyst extensions

These analyses are intentionally not implemented or run in the infrastructure pipeline. They are reserved for analyst-led scientific work after independent validation.

## A. Neighborhood change and trajectory

Distinguish current neighborhood level from direction of change over two non-overlapping periods, provisionally 2015–2019 and 2020–2024. Candidate changes include comparable deprivation, poverty rate, inflation-adjusted household income, employment/nonemployment, educational composition, vacancy/residential instability, and Gini. A primary form is `outcome ~ current_level + neighborhood_change`, with selected `neighborhood_change × age` and `neighborhood_change × eCog` tests for FEVS, OAFEM, CTB, and—where justified—eCog or depression. Rank-based SDI differences across vintages require especially careful interpretation.

## B. PM2.5 trajectory

Use the existing 2012–2022 annual ZCTA estimates to derive a linear annual slope, an early-versus-late mean contrast, or a justified percent change. Candidate models include `CTB ~ average_PM2.5 + PM2.5_change` and parallel FEVS/OAFEM models. Do not confuse the existing variability measure with a temporal slope.

## C. Moderation follow-ups

Inspect targeted patterns rather than rerunning the entire 216-model grid: SDI × age → FEVS; Gini × age → FEVS; economic connectedness × age → FEVS; PM2.5 × age → CTB; selected context × eCog → OAFEM; and selected loneliness/Need-to-Belong × context effects. Plot effects, inspect influential data and simple slopes, and run only robustness checks tied to a stated ambiguity.

## D. State-level structural sexism (secondary)

For continuity with the original grant concept, a bounded secondary model is `outcome ~ state_sexism * gender + age + individual_SES`, prioritizing FEVS, OAFEM, eCog, and lifetime fraud. Use state-clustered standard errors or a defensible multilevel approach. Race moderation among women is optional only if sample size supports it. Label this secondary rather than the main revised environmental-context story.
