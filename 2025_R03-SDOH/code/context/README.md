# ZIP/ZCTA context pipeline

This directory implements ignored private linkage from participant-reported current ZIP to public context measures. `00_prepare_context_sources.R` downloads checksum-verified entries from the public `config/reproducibility-sources.json` authority; scripts `01`–`08` validate ZIP, match ZIP-native Social Capital Atlas and RUCA directly to participant current ZIP, crosswalk to ZCTA for SDI, fixed-vintage ACS Gini, and ACAG PM2.5, and record the crime-source decision; `09_build_context_master.R` removes geographic identifiers, standardizes exposures, creates the exploratory burden composite, and audits correlations; `10_validate_context.R` produces aggregate coverage/range checks and the private realized source manifest.

Current ZIP is the primary linkage. Childhood ZIP is processed only to report feasibility. Contemporary context estimates must not be described as historical childhood exposure.

Social Capital Atlas values use direct normalized current-ZIP matching only;
an unmatched ZIP remains missing and is not replaced with a crosswalked ZCTA.
RUCA is also ZIP-native. SDI and Gini are ZCTA sources, and PM2.5 is aggregated
to ZCTA geometry.

Participant ZIP and ZCTA appear only in `private-data/derived/zip-*-private.csv`. They never enter `analysis-master.csv` or public outputs.

PM2.5 uses annual ACAG V5.NA.05 North America grids for 2012–2022 and
latitude-adjusted polygon/grid overlap weights against 2020 Census ZCTAs. This
is an area-weighted estimate, not a centroid or population-weighted estimate.
The Python helper downloads only fixed national public files; the participant
ZCTA list is read locally after downloads finish and is never transmitted.

No ADI proxy is fabricated: Neighborhood Atlas validates block-group use and
the required credentialed file plus defensible population weights were not
available. No crime value is fabricated: the focused audit found no consistent
national contemporary ZIP/ZCTA measure.
