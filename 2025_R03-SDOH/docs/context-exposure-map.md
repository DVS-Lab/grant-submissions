# Context exposure map

This metadata-only dictionary contains no participant geography or values.
Current ZIP is the participant-link field; ZIP is normalized and crosswalked to
2022 UDS ZCTA where a ZCTA-based source is required. ZIP and ZCTA never enter
the general analysis master.

| Project variable | Construct | Source / release | Source → link geography | Procedure / units | Direction and role | Major caveat |
|---|---|---|---|---|---|---|
| `sdi_zcta`; `z_sdi` | Social deprivation | Robert Graham Center SDI; ACS 2015–2019 | ZCTA → current ZIP-derived ZCTA | Direct ZCTA match; score 0–100 | Higher = greater deprivation; **primary** | ZIP/ZCTA context, not address/block-group context |
| `pm25_2012_2022_zcta`; `z_pm25` | Long-term fine-particulate exposure | ACAG V5.NA.05 annual North America grids, 2012–2022 | 0.01° grid → 2020 Census ZCTA | Latitude-corrected polygon/grid area-weighted mean; µg/m³ | Higher = more PM2.5; **primary** | Area weighted, not population weighted; North America grid does not cover every linked ZCTA |
| `pm25_recent_mean`; `z_pm25_recent` | Recent fine-particulate exposure | Same ACAG source, 2018–2022 | Same | Mean annual µg/m³ | Higher = more PM2.5; secondary | Use only as a targeted window sensitivity |
| `pm25_variability`; `z_pm25_variability` | Interannual PM2.5 variability | Same ACAG source, 2012–2022 | Same | SD of 11 annual ZCTA means; µg/m³ | Higher = more annual variability; secondary | Not a substitute for the primary long-term mean |
| `socialcap_economic_connectedness`; `ec_zip`; `z_economic_connectedness` | Cross-SES friendship | Opportunity Insights Social Capital Atlas, 2022 | ZIP → current ZIP | Direct ZIP match | Twice the share of high-SES friends among low-SES users; higher = greater connectedness; **primary social-capital indicator** | Facebook-based research measure; coverage is not universal |
| `socialcap_high_ses_exposure`; `exposure_grp_mem_zip`; `z_high_ses_exposure` | Exposure to high-SES people | Opportunity Insights, 2022 | ZIP → current ZIP | Direct ZIP match | Twice the high-SES share in low-SES users' groups; higher = more exposure; secondary | Very highly correlated with economic connectedness in this sample |
| `socialcap_friending_bias`; `z_friending_bias` | Within-group friending bias | Opportunity Insights, 2022 | ZIP → current ZIP | Direct ZIP match | One minus connectedness divided by exposure; higher = more friending bias; secondary | Interpret jointly with exposure and connectedness definitions |
| `socialcap_cohesiveness`; `z_cohesiveness` | Network clustering | Opportunity Insights, 2022 | ZIP → current ZIP | Direct ZIP match | Higher = more clustering/cohesiveness; secondary | Network construct, not a general clinical support scale |
| `socialcap_support_ratio`; `z_support_ratio` | Mutual-friend support structure | Opportunity Insights, 2022 | ZIP → current ZIP | Direct ZIP match | Higher = more within-ZIP friendships sharing a mutual friend; secondary | Facebook-network measure |
| `socialcap_volunteering`; `z_volunteering` | Volunteering/civic engagement | Opportunity Insights, 2022 | ZIP → current ZIP | Direct ZIP match | Higher = greater volunteering-group participation; secondary | Platform-derived estimate |
| `socialcap_civic_organizations`; `z_civic_organizations` | Civic organizations | Opportunity Insights, 2022 | ZIP → current ZIP | Public-good pages per 1,000 users | Higher = more civic organizations; secondary | Platform-derived estimate |
| `gini_zcta`; `gini`; `z_gini` | Neighborhood income inequality | ACS 2024 five-year B19083 | ZCTA → current ZIP-derived ZCTA | Direct ZCTA estimate; 0–1 | Higher = more inequality; **primary** | Neighborhood inequality is distinct from individual household income |
| `ruca_primary`; `z_ruca` | Geography-based rurality | USDA ERS 2020 RUCA ZIP release | ZIP → current ZIP | Direct ZIP code 1–10 | Higher generally = more rural; **primary** | RUCA is commuting-based and need not agree with self-report |
| `ruca_category` | RUCA class | USDA ERS 2020 | ZIP → current ZIP | Official primary-code groups: metropolitan 1–3, micropolitan 4–6, small town 7–9, rural 10 | Descriptive primary rurality category | Not relabeled as urban/suburban/rural |
| `risk_low_social_capital` | Low connectedness risk | Project transform | Participant-linked context | Negative of `z_economic_connectedness` | Higher = lower connectedness; composite component | Explicit reversal; source variable is retained |
| `env_burden_simple` | Preliminary environmental burden | Project composite | Participant-linked context | Equal-weight mean of `z_sdi`, `z_pm25`, `z_gini`, and low connectedness; requires ≥3 | Higher = more burden; exploratory secondary | Does not include ADI or crime and does not replace individual exposures |
| `adi_zcta_proxy` | ADI sensitivity | Not generated | Would require block group → ZCTA | Preferred population-weighted aggregation | Exploratory only | ZIP/ZCTA is not an intended Neighborhood Atlas geography; credentialed data and defensible weights required |
| crime/disorder | Neighborhood crime/disorder | No linked source | — | Source audit only | Conceptually core, unavailable | No consistent national contemporary ZIP/ZCTA product identified |

Standardized variables are calculated within the N=709 linked analysis sample.
They do not alter the direction of the raw source measure unless the variable is
explicitly named as a risk-oriented reversal.
