# ZIP/ZCTA context pipeline

This directory implements the ignored private linkage from participant-reported current ZIP to public ZIP/ZCTA context measures. `00_prepare_context_sources.R` caches tabular sources; scripts `01`–`08` validate/link ZIP/ZCTA, Social Capital Atlas, SDI, ACS Gini, ACAG PM2.5, RUCA, and the crime-source decision; `09_build_context_master.R` removes geographic identifiers, standardizes exposures, creates the prespecified exploratory burden composite, and audits correlations; `10_validate_context.R` produces aggregate coverage/range checks and the private SHA256 source manifest.

Current ZIP is the primary linkage. Childhood ZIP is processed only to report feasibility. Contemporary context estimates must not be described as historical childhood exposure.

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
