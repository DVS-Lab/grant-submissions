# SDOH data provenance

Participant-level source and analytic data are maintained in access-controlled
storage outside this public repository.

The authoritative private analytic source is the single reviewed,
direct-identifier-free `QualtricsData_SDOH_DEIDENTIFIED.xlsx` workbook (709
participants, one worksheet). Its default ignored location is documented in
`reproducibility.md`; `SDOH_SOURCE_DATA` is an optional path override.

The current one-command pipeline:

1. read only the reviewed private analytic source;
2. require the project-specific `study_id` as the participant join key;
3. reject Qualtrics `ResponseId`, exact date of birth, contact fields, vendor
   identifiers, and other direct survey/platform identifiers;
4. keep direct current-ZIP linkage for ZIP-native Social Capital Atlas/RUCA and
   current/childhood ZIP-to-ZCTA linkage for SDI/Gini/PM2.5 inside the controlled
   private GIS-linkage environment;
5. download only fixed, checksummed national public context sources from
   `config/reproducibility-sources.json`, never sending a
   participant-derived ZIP/ZCTA list to a remote service; and
6. write row-level derivatives only to `SDOH_PRIVATE_DERIVATIVES_DIR`; and
7. write private `run-provenance.json` with the workbook checksum, Git SHA,
   runtime/package versions, public-source checksums, and cache actions.

Current analyses read the private `analysis-master.csv` generated beneath
`SDOH_PRIVATE_DERIVATIVES_DIR`. No source workbook or row-level derivative is
read from a public path.

The public repository contains code, documentation, previously reviewed
aggregate figures, a metadata-only analytic variable dictionary, and three
aggregate coefficient/formula references. It does not contain an approved
public participant dataset.

Any future public participant dataset requires a separate disclosure-risk review
as described in `public-data-release.md`.
