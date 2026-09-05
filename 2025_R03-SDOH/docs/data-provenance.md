# SDOH data provenance

Participant-level source and analytic data are maintained in access-controlled
storage outside this public repository.

The authoritative private analytic source is the reviewed, direct-identifier-free
709-participant dataset. Public analysis code receives its path through
`SDOH_SOURCE_DATA`.

The scoring workflow must:

1. read only the reviewed private analytic source;
2. require the project-specific `study_id` as the participant join key;
3. reject Qualtrics `ResponseId`, exact date of birth, contact fields, vendor
   identifiers, and other direct survey/platform identifiers;
4. keep full current/childhood ZIP and address-level information within the
   controlled GIS-linkage environment; and
5. write row-level derivatives only to `SDOH_PRIVATE_DERIVATIVES_DIR`.

Exploratory analyses read private analysis-ready derivatives through explicitly
configured private paths such as `SDOH_PRIVATE_MASTER`.

The public repository contains code, documentation, aggregate figures, and a
metadata-only analytic variable dictionary. It does not contain an approved
public participant dataset.

Any future public participant dataset requires a separate disclosure-risk review
as described in `public-data-release.md`.
