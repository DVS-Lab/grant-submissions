# Future public-data release

No participant-level SDOH dataset is currently approved for release from this
repository. A future release should be constructed deliberately from the private
analytic source and reviewed before publication.

At minimum, the release process should:

- create a random, project-specific `study_id` and keep its crosswalk private;
- exclude exact DOB, Qualtrics/panel/vendor IDs, contact fields, addresses, IPs,
  exact timestamps, and full current or childhood ZIPs;
- generalize age, geography, and sparse demographic categories as needed;
- assess combinations of quasi-identifiers and small cells, not fields in
  isolation;
- document exclusions, scoring versions, missingness, and sample attrition;
- verify that figures and tables satisfy the project's disclosure threshold; and
- obtain the required data-steward/IRB review before committing release files.

The consent to public de-identified sharing supports a carefully prepared future
release following this review process.
