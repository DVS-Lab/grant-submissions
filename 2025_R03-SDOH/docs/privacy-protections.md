# Public repository privacy protections

Public SDOH files are structured to preserve analysis code, documentation, and
aggregate results without publishing participant-level source or analytic data.

## Public file protections

- Participant-level SDOH CSVs are excluded from the public tree.
- The public analytic variable dictionary contains metadata only and omits exact
  date-of-birth and full-ZIP fields.
- Scoring code skips exact date of birth during import and uses an explicit list
  of demographic fields needed for analysis.
- Row-level scoring outputs are written to an ignored private directory rather
  than the public `derivatives` directory.
- Exploratory analysis scripts receive their participant-level input through the
  `SDOH_PRIVATE_MASTER` environment variable instead of a repository data path.
- Root ignore rules cover raw survey exports, participant source files,
  crosswalks, contact fields, private-data directories, and local de-identified
  workbooks.
- The public `sourcedata` and `derivatives` documentation states which materials
  must remain private and which disclosure-reviewed outputs may be published.

Aggregate SDOH figures were retained because they do not display participant
identifiers. The ABCD code, documentation, and aggregate figures did not require
privacy-related alteration.

Any future public participant dataset must follow the separate review described
in `public-data-release.md` and use an arbitrary project-specific `study_id`
rather than a survey or panel identifier.
