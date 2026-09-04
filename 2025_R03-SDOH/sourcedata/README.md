# Private SDOH source data

Participant-level SDOH source data are maintained in access-controlled private
storage and are intentionally not committed to this repository.

This includes raw Qualtrics or panel exports, exact dates of birth, addresses,
full current or childhood ZIPs, contact/recontact fields, vendor identifiers,
crosswalks, and local de-identified analytic workbooks.

The scoring code reads the private analytic source from the `SDOH_SOURCE_DATA`
environment variable and writes row-level outputs only to the ignored private
directory selected by `SDOH_PRIVATE_DERIVATIVES_DIR`.
