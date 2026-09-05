# Public repository privacy protections

This public repository preserves analysis code, documentation, and aggregate
results without publishing participant-level source or analytic data.

## Public file protections

- Participant-level SDOH data are prohibited from the public repository.
- Direct identifiers and survey/platform identifiers are removed upstream of the
  analytic workflow.
- Public scoring code requires a project-specific `study_id` and rejects
  Qualtrics `ResponseId` and other prohibited identifier fields.
- Full current/childhood ZIP and address-level information used for GIS linkage
  remain in the controlled private environment.
- Row-level scoring outputs are written only to ignored private locations.
- Root ignore rules block common participant-data formats within the SDOH
  project.
- The public variable dictionary contains metadata only and excludes exact DOB
  and full current/childhood ZIP fields.

Aggregate figures retained in this repository have been reviewed for absence of
participant identifiers. They are not participant-level datasets.

Any future public participant dataset must undergo separate disclosure-risk
review and use a random project-specific `study_id`.
