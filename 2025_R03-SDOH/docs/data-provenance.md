# SDOH data provenance

Participant-level source and analytic data are maintained in access-controlled
storage outside this public repository.

The authoritative private analytic source is the reviewed, direct-identifier-free
709-participant dataset. Public analysis code receives its path through
`SDOH_SOURCE_DATA`.

The current one-command pipeline:

1. read only the reviewed private analytic source;
2. require the project-specific `study_id` as the participant join key;
3. reject Qualtrics `ResponseId`, exact date of birth, contact fields, vendor
   identifiers, and other direct survey/platform identifiers;
4. keep current/childhood ZIP and intermediate ZCTA linkage inside the
   controlled private GIS-linkage environment;
5. download only fixed national public context sources, never sending a
   participant-derived ZIP/ZCTA list to a remote service; and
6. write row-level derivatives only to `SDOH_PRIVATE_DERIVATIVES_DIR`.

Current analyses read the private `analysis-master.csv` generated beneath
`SDOH_PRIVATE_DERIVATIVES_DIR`. No source workbook or row-level derivative is
read from a public path.

The public repository contains code, documentation, previously reviewed
aggregate figures, a metadata-only analytic variable dictionary, and three
aggregate coefficient/formula references. It does not contain an approved
public participant dataset.

Any future public participant dataset requires a separate disclosure-risk review
as described in `public-data-release.md`.
