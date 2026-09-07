# Preserved exploratory model screen

The three CSV files in this directory are coefficient/formula-level aggregate
references from an earlier exploratory model screen. They contain no
participant rows, study IDs, ZIPs, contact fields, or direct identifiers.

- `all-models.csv`: 143 rows, 35 unique formulas (16 FEVS and 19 OAFEM).
- `chetty-models.csv`: 79 rows, 22 unique formulas.
- `non-chetty-models.csv`: 64 rows, 16 unique formulas.

The formula set in `all-models.csv` equals the union of the formula sets in the
other two files. The coefficient rows are **not** an exact union: overlapping
formula/term records include different numeric estimates, consistent with
different source variants or analytic samples. The files are therefore kept
as three distinct historical references rather than rewritten into a false
single truth.

These were exploratory models, not preregistered analyses or confirmed
findings. Their value is reconstructing what was tried. The current private
pipeline deduplicates the 35 formulas, classifies availability, reruns every
runnable model, and compares direction descriptively without using a p-value
threshold to label replication.
